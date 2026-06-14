#!/bin/bash

################################################################################
# AUTO PRODUCT VIDEO IA - MAIN ORCHESTRATOR
# Script principal que orquesta todo el pipeline de generación de videos
################################################################################

set -e

# Cargar utilidades
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
source "${SCRIPT_DIR}/utils.sh"

# ============================================
# VARIABLES
# ============================================

PRODUCT_IMAGE=""
PRODUCT_MODEL=""
OUTPUT_DIR=""
LANGUAGES="en,ru,zh"
DURATION=12
VERBOSE=false
DEBUG=false
KEEP_TEMP_FILES=false

# Crear log file
LOG_FILE="${PROJECT_DIR}/data/outputs/logs/$(date +'%Y%m%d_%H%M%S').log"
mkdir -p "$(dirname "$LOG_FILE")"

# ============================================
# FUNCIONES
# ============================================

show_help() {
    cat << EOF
${BLUE}Auto Product Video IA - Generador de Videos${NC}

${YELLOW}Uso:${NC}
    bash scripts/main.sh [opciones]

${YELLOW}Opciones requeridas:${NC}
    -i, --image <archivo>          Imagen del producto (ruta o nombre en data/products/images/)
    -m, --model <modelo>           Modelo oficial del producto (ej: "Samsung Galaxy A53")

${YELLOW}Opciones opcionales:${NC}
    -o, --output <directorio>      Directorio de salida (por defecto: data/outputs/videos/)
    -l, --languages <idiomas>      Idiomas para subtítulos (por defecto: en,ru,zh)
    -d, --duration <minutos>       Duración del video en minutos (por defecto: 12)
    -v, --verbose                  Modo verboso
    --debug                        Modo debug
    --keep-temp                    Mantener archivos temporales
    -h, --help                     Mostrar esta ayuda

${YELLOW}Ejemplos:${NC}
    bash scripts/main.sh -i producto.jpg -m "Samsung Galaxy A53"
    bash scripts/main.sh -i imagen.jpg -m "iPhone 15" -o ~/Descargas/ -l "en,es,ru"
    bash scripts/main.sh -i foto.png -m "Sony WH-1000XM5" -d 15 --verbose

${YELLOW}Idiomas disponibles:${NC}
    en - Inglés
    ru - Ruso
    zh - Chino Simplificado
    es - Español (experimental)
    fr - Francés (experimental)

EOF
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -i|--image)
                PRODUCT_IMAGE="$2"
                shift 2
                ;;
            -m|--model)
                PRODUCT_MODEL="$2"
                shift 2
                ;;
            -o|--output)
                OUTPUT_DIR="$2"
                shift 2
                ;;
            -l|--languages)
                LANGUAGES="$2"
                shift 2
                ;;
            -d|--duration)
                DURATION="$2"
                shift 2
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            --debug)
                DEBUG=true
                VERBOSE=true
                shift
                ;;
            --keep-temp)
                KEEP_TEMP_FILES=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log_error "Opción desconocida: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

validate_inputs() {
    log_info "Validando entradas..."
    
    # Validar imagen
    if [ -z "$PRODUCT_IMAGE" ]; then
        log_error "Imagen no especificada. Usa: -i <archivo>"
        show_help
        exit 1
    fi
    
    # Si no tiene ruta, buscar en data/products/images/
    if [ ! -f "$PRODUCT_IMAGE" ]; then
        if [ -f "${PROJECT_DIR}/data/products/images/${PRODUCT_IMAGE}" ]; then
            PRODUCT_IMAGE="${PROJECT_DIR}/data/products/images/${PRODUCT_IMAGE}"
        else
            log_error "Archivo de imagen no encontrado: $PRODUCT_IMAGE"
            exit 1
        fi
    fi
    
    if ! validate_image_file "$PRODUCT_IMAGE"; then
        exit 1
    fi
    
    log_success "Imagen validada: $PRODUCT_IMAGE"
    
    # Validar modelo
    if [ -z "$PRODUCT_MODEL" ]; then
        log_error "Modelo no especificado. Usa: -m <modelo>"
        show_help
        exit 1
    fi
    
    log_success "Modelo: $PRODUCT_MODEL"
    
    # Validar duración
    if ! [[ "$DURATION" =~ ^[0-9]+$ ]] || [ "$DURATION" -lt 5 ] || [ "$DURATION" -gt 60 ]; then
        log_error "Duración inválida: $DURATION (debe estar entre 5 y 60 minutos)"
        exit 1
    fi
    
    log_success "Duración: ${DURATION} minutos"
    
    # Validar idiomas
    for lang in $(echo "$LANGUAGES" | tr ',' ' '); do
        if ! is_valid_language_code "$lang"; then
            log_warning "Código de idioma no validado completamente: $lang (continuando...)"
        fi
    done
    
    log_success "Idiomas de subtítulos: $LANGUAGES"
}

setup_output_directory() {
    if [ -z "$OUTPUT_DIR" ]; then
        OUTPUT_DIR="${PROJECT_DIR}/data/outputs/videos"
    fi
    
    create_directory "$OUTPUT_DIR"
    log_success "Directorio de salida: $OUTPUT_DIR"
}

load_configuration() {
    log_info "Cargando configuración..."
    
    if ! load_env_file; then
        log_error "No se pudo cargar el archivo .env"
        exit 1
    fi
    
    if ! load_config_file; then
        log_warning "No se pudo cargar config/settings.conf (usando valores por defecto)"
    fi
    
    log_success "Configuración cargada"
}

verify_dependencies() {
    log_info "Verificando dependencias..."
    
    local required_cmds=(
        "curl"
        "ffmpeg"
        "ffprobe"
        "jq"
        "python3"
    )
    
    if ! check_required_commands "${required_cmds[@]}"; then
        log_error "Faltan dependencias. Ejecuta: bash scripts/setup.sh"
        exit 1
    fi
    
    log_success "Todas las dependencias están disponibles"
}

verify_api_keys() {
    log_info "Verificando API keys..."
    
    local missing_keys=0
    
    if [ -z "$OPENAI_API_KEY" ]; then
        log_error "OPENAI_API_KEY no configurada"
        ((missing_keys++))
    else
        log_success "OpenAI API key encontrada"
    fi
    
    if [ -z "$ELEVENLABS_API_KEY" ]; then
        log_error "ELEVENLABS_API_KEY no configurada"
        ((missing_keys++))
    else
        log_success "ElevenLabs API key encontrada"
    fi
    
    if [ -z "$RUNWAY_API_KEY" ]; then
        log_error "RUNWAY_API_KEY no configurada"
        ((missing_keys++))
    else
        log_success "Runway ML API key encontrada"
    fi
    
    if [ $missing_keys -gt 0 ]; then
        log_error "$missing_keys API key(s) falta(n). Edita: .env"
        exit 1
    fi
}

generate_product_name() {
    echo "$PRODUCT_MODEL" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g'
}

# ============================================
# PIPELINE PRINCIPAL
# ============================================

run_pipeline() {
    local product_name=$(generate_product_name)
    local product_info_file="${PROJECT_DIR}/tmp/${product_name}_info.json"
    local script_file="${OUTPUT_DIR}/${product_name}_script.txt"
    local narration_file="${OUTPUT_DIR}/${product_name}_narration.mp3"
    local video_file="${OUTPUT_DIR}/${product_name}_${DURATION}min.mp4"
    
    log_info "Iniciando pipeline de generación de video..."
    echo ""
    
    # Paso 1: Buscar información del producto
    log_info "[1/5] Buscando información del producto en Internet..."
    if [ -f "${SCRIPT_DIR}/search_product_info.sh" ]; then
        bash "${SCRIPT_DIR}/search_product_info.sh" \
            --model "$PRODUCT_MODEL" \
            --output "$product_info_file" \
            --verbose=$VERBOSE || log_warning "Búsqueda de información completada con advertencias"
    else
        log_warning "Script search_product_info.sh no encontrado"
    fi
    
    echo ""
    
    # Paso 2: Generar script
    log_info "[2/5] Generando script con ChatGPT..."
    if [ -f "${SCRIPT_DIR}/generate_script.sh" ]; then
        bash "${SCRIPT_DIR}/generate_script.sh" \
            --model "$PRODUCT_MODEL" \
            --duration "$DURATION" \
            --info "$product_info_file" \
            --output "$script_file" \
            --verbose=$VERBOSE || log_warning "Generación de script completada con advertencias"
    else
        log_warning "Script generate_script.sh no encontrado"
    fi
    
    echo ""
    
    # Paso 3: Generar narración
    log_info "[3/5] Generando narración con ElevenLabs..."
    if [ -f "${SCRIPT_DIR}/generate_narration.sh" ]; then
        bash "${SCRIPT_DIR}/generate_narration.sh" \
            --script "$script_file" \
            --output "$narration_file" \
            --language "es" \
            --verbose=$VERBOSE || log_warning "Generación de narración completada con advertencias"
    else
        log_warning "Script generate_narration.sh no encontrado"
    fi
    
    echo ""
    
    # Paso 4: Generar video
    log_info "[4/5] Generando video con Runway ML..."
    if [ -f "${SCRIPT_DIR}/generate_video.sh" ]; then
        bash "${SCRIPT_DIR}/generate_video.sh" \
            --image "$PRODUCT_IMAGE" \
            --narration "$narration_file" \
            --script "$script_file" \
            --duration "$DURATION" \
            --output "$video_file" \
            --verbose=$VERBOSE || log_warning "Generación de video completada con advertencias"
    else
        log_warning "Script generate_video.sh no encontrado"
    fi
    
    echo ""
    
    # Paso 5: Generar subtítulos
    log_info "[5/5] Generando subtítulos en $LANGUAGES..."
    if [ -f "${SCRIPT_DIR}/generate_subtitles.sh" ]; then
        bash "${SCRIPT_DIR}/generate_subtitles.sh" \
            --video "$video_file" \
            --script "$script_file" \
            --languages "$LANGUAGES" \
            --output "$OUTPUT_DIR" \
            --verbose=$VERBOSE || log_warning "Generación de subtítulos completada con advertencias"
    else
        log_warning "Script generate_subtitles.sh no encontrado"
    fi
    
    echo ""
    
    show_completion_summary "$product_name" "$video_file"
}

show_completion_summary() {
    local product_name=$1
    local video_file=$2
    
    echo ""
    echo -e "${GREEN}================================${NC}"
    echo -e "${GREEN}✓ Pipeline completado${NC}"
    echo -e "${GREEN}================================${NC}"
    echo ""
    
    if [ -f "$video_file" ]; then
        echo -e "${BLUE}Archivo de video:${NC}"
        echo -e "  ${GREEN}✓${NC} $video_file"
        
        local size=$(du -h "$video_file" | cut -f1)
        echo -e "  Tamaño: $size"
    else
        echo -e "${YELLOW}⚠ Archivo de video no encontrado (verificar logs)${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}Subtítulos generados:${NC}"
    for lang in $(echo "$LANGUAGES" | tr ',' ' '); do
        local subtitle_file="${OUTPUT_DIR}/${product_name}_${lang}.srt"
        if [ -f "$subtitle_file" ]; then
            echo -e "  ${GREEN}✓${NC} $lang: $subtitle_file"
        else
            echo -e "  ${YELLOW}○${NC} $lang: no generado"
        fi
    done
    
    echo ""
    echo -e "${BLUE}Log de ejecución:${NC} $LOG_FILE"
    echo ""
    echo -e "${YELLOW}Próximos pasos:${NC}"
    echo "  1. Reproduce el video: vlc \"$video_file\""
    echo "  2. Verifica los subtítulos en el reproductor"
    echo "  3. Comparte el video en tu red de preferencia"
    echo ""
}

# ============================================
# MAIN
# ============================================

main() {
    log_info "=========================================="
    log_info "Auto Product Video IA - Inicializando..."
    log_info "=========================================="
    echo ""
    
    # Parsear argumentos
    parse_arguments "$@"
    
    # Validar entradas
    validate_inputs
    
    # Configurar directorios
    setup_output_directory
    ensure_directories
    
    # Cargar configuración
    load_configuration
    
    # Verificar dependencias
    verify_dependencies
    
    # Verificar API keys
    verify_api_keys
    
    echo ""
    
    # Ejecutar pipeline
    run_pipeline
    
    # Limpiar temporales
    if [ "$KEEP_TEMP_FILES" != "true" ]; then
        cleanup_temp_files
    fi
    
    log_success "Proceso finalizado exitosamente"
}

# Ejecutar
main "$@"
