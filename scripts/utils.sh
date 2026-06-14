#!/bin/bash

################################################################################
# AUTO PRODUCT VIDEO IA - UTILITY FUNCTIONS
# Funciones compartidas para todos los scripts
################################################################################

# ============================================
# VARIABLES GLOBALES
# ============================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# ============================================
# FUNCIONES DE LOGGING
# ============================================

log() {
    local timestamp=$(date +'%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] $1"
}

log_info() {
    echo -e "${BLUE}ℹ INFO:${NC} $1"
    log "INFO: $1" >> "${LOG_FILE}"
}

log_success() {
    echo -e "${GREEN}✓ SUCCESS:${NC} $1"
    log "SUCCESS: $1" >> "${LOG_FILE}"
}

log_error() {
    echo -e "${RED}✗ ERROR:${NC} $1"
    log "ERROR: $1" >> "${LOG_FILE}"
}

log_warning() {
    echo -e "${YELLOW}⚠ WARNING:${NC} $1"
    log "WARNING: $1" >> "${LOG_FILE}"
}

log_debug() {
    if [ "$DEBUG" = "true" ] || [ "$VERBOSE" = "true" ]; then
        echo -e "${CYAN}◆ DEBUG:${NC} $1"
        log "DEBUG: $1" >> "${LOG_FILE}"
    fi
}

# ============================================
# FUNCIONES DE VALIDACIÓN
# ============================================

check_required_command() {
    local cmd=$1
    local package_name=${2:-$cmd}
    
    if ! command -v "$cmd" &> /dev/null; then
        log_error "$cmd no encontrado. Instala: $package_name"
        return 1
    fi
    return 0
}

check_required_commands() {
    local missing_commands=0
    
    for cmd in "$@"; do
        if ! check_required_command "$cmd"; then
            ((missing_commands++))
        fi
    done
    
    return $missing_commands
}

check_required_env() {
    local var=$1
    
    if [ -z "${!var}" ]; then
        log_error "Variable de entorno requerida no encontrada: $var"
        return 1
    fi
    return 0
}

check_file_exists() {
    local file=$1
    
    if [ ! -f "$file" ]; then
        log_error "Archivo no encontrado: $file"
        return 1
    fi
    return 0
}

check_directory_exists() {
    local dir=$1
    
    if [ ! -d "$dir" ]; then
        log_error "Directorio no encontrado: $dir"
        return 1
    fi
    return 0
}

# ============================================
# FUNCIONES DE CARGA DE CONFIGURACIÓN
# ============================================

load_env_file() {
    local env_file="${PROJECT_DIR}/.env"
    
    if [ ! -f "$env_file" ]; then
        log_error "Archivo .env no encontrado en $PROJECT_DIR"
        log_info "Copia .env.example a .env y configura tus API keys"
        return 1
    fi
    
    # Cargar variables de .env
    set -a
    source "$env_file"
    set +a
    
    log_success "Archivo .env cargado"
    return 0
}

load_config_file() {
    local config_file="${PROJECT_DIR}/config/settings.conf"
    
    if [ -f "$config_file" ]; then
        source "$config_file"
        log_debug "Archivo de configuración cargado: $config_file"
        return 0
    else
        log_warning "Archivo de configuración no encontrado: $config_file"
        return 1
    fi
}

# ============================================
# FUNCIONES DE DIRECTORIOS
# ============================================

create_directory() {
    local dir=$1
    
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        log_debug "Directorio creado: $dir"
        return 0
    fi
    return 0
}

ensure_directories() {
    create_directory "${PROJECT_DIR}/data/products/images"
    create_directory "${PROJECT_DIR}/data/outputs/videos"
    create_directory "${PROJECT_DIR}/data/outputs/subtitles"
    create_directory "${PROJECT_DIR}/data/outputs/scripts"
    create_directory "${PROJECT_DIR}/data/outputs/narration"
    create_directory "${PROJECT_DIR}/data/outputs/logs"
    create_directory "${PROJECT_DIR}/tmp"
}

# ============================================
# FUNCIONES DE ARCHIVOS
# ============================================

get_file_name() {
    local file=$1
    basename "$file"
}

get_file_extension() {
    local file=$1
    echo "${file##*.}"
}

get_file_name_without_extension() {
    local file=$1
    basename "$file" | sed 's/\.[^.]*$//'
}

generate_temp_file() {
    local prefix=${1:-"temp"}
    local temp_file="${PROJECT_DIR}/tmp/${prefix}_${RANDOM}_$$.tmp"
    touch "$temp_file"
    echo "$temp_file"
}

cleanup_temp_files() {
    if [ ! "$KEEP_TEMP_FILES" = "true" ]; then
        rm -rf "${PROJECT_DIR}/tmp"/*.tmp 2>/dev/null || true
        log_debug "Archivos temporales limpiados"
    fi
}

# ============================================
# FUNCIONES DE VALIDACIÓN DE DATOS
# ============================================

is_valid_url() {
    local url=$1
    local regex="^https?://"
    
    if [[ $url =~ $regex ]]; then
        return 0
    fi
    return 1
}

is_valid_email() {
    local email=$1
    local regex="^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
    
    if [[ $email =~ $regex ]]; then
        return 0
    fi
    return 1
}

is_valid_language_code() {
    local lang=$1
    local valid_langs="en ru zh es fr de it ja ko pt"
    
    for valid_lang in $valid_langs; do
        if [ "$lang" = "$valid_lang" ]; then
            return 0
        fi
    done
    return 1
}

# ============================================
# FUNCIONES DE API
# ============================================

call_openai_api() {
    local prompt=$1
    local model=${OPENAI_MODEL:-"gpt-4"}
    local max_tokens=${2:-2000}
    
    if [ -z "$OPENAI_API_KEY" ]; then
        log_error "OPENAI_API_KEY no configurada"
        return 1
    fi
    
    log_debug "Llamando a OpenAI API con modelo: $model"
    
    local response=$(curl -s -X POST "https://api.openai.com/v1/chat/completions" \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -H "Content-Type: application/json" \
        -d "{
            \"model\": \"$model\",
            \"messages\": [{\"role\": \"user\", \"content\": \"$prompt\"}],
            \"max_tokens\": $max_tokens,
            \"temperature\": ${OPENAI_TEMPERATURE:-0.7}
        }")
    
    echo "$response"
}

call_elevenlabs_api() {
    local text=$1
    local voice_id=${ELEVENLABS_VOICE_ID:-"21m00Tcm4TlvDq8ikWAM"}
    local output_file=$2
    
    if [ -z "$ELEVENLABS_API_KEY" ]; then
        log_error "ELEVENLABS_API_KEY no configurada"
        return 1
    fi
    
    log_debug "Llamando a ElevenLabs API para generar narración"
    
    curl -s -X POST "https://api.elevenlabs.io/v1/text-to-speech/$voice_id" \
        -H "xi-api-key: $ELEVENLABS_API_KEY" \
        -H "Content-Type: application/json" \
        -d "{
            \"text\": \"$text\",
            \"model_id\": \"eleven_monolingual_v1\",
            \"voice_settings\": {
                \"stability\": ${ELEVENLABS_VOICE_STABILITY:-0.5},
                \"similarity_boost\": ${ELEVENLABS_VOICE_SIMILARITY:-0.75}
            }
        }" > "$output_file"
    
    if [ -s "$output_file" ]; then
        log_success "Narración generada: $output_file"
        return 0
    else
        log_error "Error generando narración"
        return 1
    fi
}

# ============================================
# FUNCIONES DE PROCESAMIENTO DE VIDEO
# ============================================

get_video_duration() {
    local video=$1
    ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1:nokey=1 "$video" 2>/dev/null || echo "0"
}

get_video_resolution() {
    local video=$1
    ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 "$video" 2>/dev/null
}

get_video_fps() {
    local video=$1
    ffprobe -v error -select_streams v:0 -show_entries stream=r_frame_rate -of default=noprint_wrappers=1:nokey=1 "$video" 2>/dev/null
}

validate_video_file() {
    local video=$1
    
    if [ ! -f "$video" ]; then
        log_error "Archivo de video no encontrado: $video"
        return 1
    fi
    
    if ! ffprobe -v error "$video" > /dev/null 2>&1; then
        log_error "Archivo de video inválido: $video"
        return 1
    fi
    
    return 0
}

# ============================================
# FUNCIONES DE PROCESAMIENTO DE AUDIO
# ============================================

validate_audio_file() {
    local audio=$1
    
    if [ ! -f "$audio" ]; then
        log_error "Archivo de audio no encontrado: $audio"
        return 1
    fi
    
    if ! ffprobe -v error "$audio" > /dev/null 2>&1; then
        log_error "Archivo de audio inválido: $audio"
        return 1
    fi
    
    return 0
}

get_audio_duration() {
    local audio=$1
    ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$audio" 2>/dev/null || echo "0"
}

# ============================================
# FUNCIONES DE PROCESAMIENTO DE IMÁGENES
# ============================================

validate_image_file() {
    local image=$1
    local supported_formats="jpg jpeg png webp"
    local ext=$(get_file_extension "$image" | tr '[:upper:]' '[:lower:]')
    
    if [ ! -f "$image" ]; then
        log_error "Archivo de imagen no encontrado: $image"
        return 1
    fi
    
    if ! [[ " $supported_formats " =~ " $ext " ]]; then
        log_error "Formato de imagen no soportado: $ext"
        return 1
    fi
    
    return 0
}

get_image_dimensions() {
    local image=$1
    identify -format "%wx%h" "$image" 2>/dev/null || echo "0x0"
}

# ============================================
# FUNCIONES DE RETRIES
# ============================================

retry_command() {
    local max_attempts=${MAX_RETRIES:-3}
    local delay=${RETRY_DELAY:-5}
    local attempt=1
    local exit_code=0
    
    while [ $attempt -le $max_attempts ]; do
        log_debug "Intento $attempt de $max_attempts: $*"
        
        if "$@"; then
            return 0
        fi
        
        exit_code=$?
        
        if [ $attempt -lt $max_attempts ]; then
            log_warning "Comando falló. Reintentando en ${delay}s..."
            sleep "$delay"
        fi
        
        ((attempt++))
    done
    
    log_error "Comando falló después de $max_attempts intentos"
    return $exit_code
}

# ============================================
# FUNCIONES DE PROGRESO
# ============================================

show_progress() {
    local current=$1
    local total=$2
    local width=40
    
    local percentage=$((current * 100 / total))
    local filled=$((width * current / total))
    
    local bar=""
    for ((i=0; i<filled; i++)); do
        bar="${bar}="
    done
    
    for ((i=filled; i<width; i++)); do
        bar="${bar} "
    done
    
    printf "\rProgreso: [%s] %d%%" "$bar" "$percentage"
    
    if [ $current -eq $total ]; then
        echo ""
    fi
}

# ============================================
# FUNCIONES AUXILIARES
# ============================================

pause() {
    local message=${1:-"Presiona Enter para continuar..."}
    read -p "$message" -r
}

confirm() {
    local prompt=$1
    local response
    
    read -p "$prompt (s/n): " -r response
    [[ "$response" =~ ^[Ss]$ ]]
}

sanitize_filename() {
    local filename=$1
    # Reemplazar caracteres especiales
    echo "$filename" | sed 's/[^a-zA-Z0-9._-]/-/g'
}

get_timestamp() {
    date +'%Y%m%d_%H%M%S'
}

# ============================================
# EXPORTAR FUNCIONES (para subshells)
# ============================================

export -f log log_info log_success log_error log_warning log_debug
export -f check_required_command check_file_exists check_directory_exists
export -f create_directory ensure_directories
export -f get_file_name get_file_extension get_file_name_without_extension
export -f sanitize_filename get_timestamp
