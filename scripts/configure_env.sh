#!/bin/bash

################################################################################
# AUTO PRODUCT VIDEO IA - CONFIGURACIÓN INTERACTIVA DE API KEYS
# Script interactivo para configurar y validar todas las API keys
################################################################################

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="${PROJECT_DIR}/.env"
ENV_EXAMPLE="${PROJECT_DIR}/.env.example"
LOG_FILE="${PROJECT_DIR}/config_setup.log"

# Variables para almacenar las claves
OPENAI_API_KEY=""
RUNWAY_API_KEY=""
ELEVENLABS_API_KEY=""
GOOGLE_TRANSLATE_API_KEY=""

# ============================================
# FUNCIONES
# ============================================

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}✓ $1${NC}" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}✗ $1${NC}" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}⚠ $1${NC}" | tee -a "$LOG_FILE"
}

log_info() {
    echo -e "${BLUE}ℹ $1${NC}" | tee -a "$LOG_FILE"
}

log_section() {
    echo ""
    echo -e "${CYAN}══════════════════════════════════════${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}══════════════════════════════════════${NC}"
}

# Función para pausar
pause() {
    read -p "$(echo -e ${YELLOW}Presiona Enter para continuar...${NC})" -r
}

# Función para limpiar entrada
trim() {
    local var="$@"
    var="${var#"${var%%[![:space:]]*}"}"   # Remove leading whitespace
    var="${var%"${var##*[![:space:]]}"}"   # Remove trailing whitespace
    echo "$var"
}

# Validar que una API key no esté vacía
validate_not_empty() {
    local input="$1"
    local field="$2"
    
    if [ -z "$(trim "$input")" ]; then
        log_error "El campo '$field' no puede estar vacío"
        return 1
    fi
    return 0
}

# Validar formato de OpenAI API key
validate_openai_key() {
    local key="$1"
    
    # OpenAI keys comienzan con sk-
    if [[ $key == sk-* ]]; then
        return 0
    fi
    
    log_warning "La API key de OpenAI generalmente comienza con 'sk-'. Verifica que sea correcta."
    return 0
}

# Validar que sea una URL válida
validate_url() {
    local url="$1"
    local regex="^https?://"
    
    if [[ $url =~ $regex ]]; then
        return 0
    fi
    return 1
}

# Probar OpenAI API Key
test_openai_key() {
    local api_key="$1"
    
    log_info "Probando OpenAI API key..."
    
    local response=$(curl -s -X POST "https://api.openai.com/v1/chat/completions" \
        -H "Authorization: Bearer $api_key" \
        -H "Content-Type: application/json" \
        -d '{
            "model": "gpt-4",
            "messages": [{"role": "user", "content": "test"}],
            "max_tokens": 10
        }' 2>/dev/null || echo "")
    
    if echo "$response" | grep -q "error"; then
        local error=$(echo "$response" | grep -o '"message":"[^"]*"' | cut -d'"' -f4)
        log_error "OpenAI API error: $error"
        return 1
    fi
    
    if echo "$response" | grep -q "choices"; then
        log_success "OpenAI API key válida ✓"
        return 0
    fi
    
    log_warning "No se pudo validar completamente, pero continuando..."
    return 0
}

# Probar ElevenLabs API Key
test_elevenlabs_key() {
    local api_key="$1"
    
    log_info "Probando ElevenLabs API key..."
    
    local response=$(curl -s -X GET "https://api.elevenlabs.io/v1/voices" \
        -H "xi-api-key: $api_key" \
        -H "Content-Type: application/json" 2>/dev/null || echo "")
    
    if echo "$response" | grep -q "error"; then
        local error=$(echo "$response" | grep -o '"message":"[^"]*"' | cut -d'"' -f4)
        log_error "ElevenLabs API error: $error"
        return 1
    fi
    
    if echo "$response" | grep -q "voices"; then
        log_success "ElevenLabs API key válida ✓"
        return 0
    fi
    
    log_warning "No se pudo validar completamente, pero continuando..."
    return 0
}

# Probar Google Translate API Key
test_google_translate_key() {
    local api_key="$1"
    
    log_info "Probando Google Translate API key..."
    
    local response=$(curl -s -X GET "https://translation.googleapis.com/language/translate/v2?key=$api_key&q=hello&source=en&target=es" 2>/dev/null || echo "")
    
    if echo "$response" | grep -q "error"; then
        log_error "Google Translate API error"
        return 1
    fi
    
    if echo "$response" | grep -q "translatedText"; then
        log_success "Google Translate API key válida ✓"
        return 0
    fi
    
    log_warning "No se pudo validar completamente, pero continuando..."
    return 0
}

# Mostrar pantalla de bienvenida
show_welcome() {
    clear
    echo -e "${CYAN}"
    cat << 'EOF'
╔════════════════════════════════════════════════╗
║                                                ║
║  🎬 AUTO PRODUCT VIDEO IA - CONFIGURACIÓN     ║
║     Configurador Interactivo de API Keys      ║
║                                                ║
╚════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo ""
    echo "Este script te guiará para configurar todas las API keys necesarias."
    echo ""
    echo "Necesitarás:"
    echo -e "  ${GREEN}✓${NC} OpenAI API Key (ChatGPT)"
    echo -e "  ${GREEN}✓${NC} Runway ML API Key"
    echo -e "  ${GREEN}✓${NC} ElevenLabs API Key"
    echo -e "  ${GREEN}✓${NC} Google Translate API Key"
    echo ""
    echo -e "${YELLOW}Tiempo estimado: 5-10 minutos${NC}"
    echo ""
    pause
}

# Sección: OpenAI Configuration
configure_openai() {
    log_section "1️⃣  CONFIGURACIÓN DE OPENAI (ChatGPT)"
    
    echo "Necesitas una API key de OpenAI para generar los guiones con ChatGPT."
    echo ""
    echo "📌 Pasos para obtener tu API key:"
    echo ""
    echo "  1. Ve a: ${CYAN}https://platform.openai.com/api-keys${NC}"
    echo "  2. Inicia sesión con tu cuenta OpenAI"
    echo "  3. Click en 'Create new secret key'"
    echo "  4. Copia la clave (comenzará con 'sk-')"
    echo "  5. Pégala aquí"
    echo ""
    
    while true; do
        read -p "$(echo -e ${YELLOW}Ingresa tu OpenAI API Key:${NC}) " -r OPENAI_API_KEY
        
        if ! validate_not_empty "$OPENAI_API_KEY" "OpenAI API Key"; then
            continue
        fi
        
        validate_openai_key "$OPENAI_API_KEY"
        
        echo ""
        echo "Tu clave: ${CYAN}${OPENAI_API_KEY:0:10}...${NC}"
        echo ""
        
        read -p "$(echo -e ${YELLOW}¿Es correcta? (s/n): ${NC})" -r response
        
        if [[ $response =~ ^[Ss]$ ]]; then
            # Probar la clave
            if test_openai_key "$OPENAI_API_KEY"; then
                log_success "OpenAI configurada ✓"
                return 0
            else
                echo ""
                log_error "La API key no es válida. Intenta nuevamente."
                echo ""
                OPENAI_API_KEY=""
            fi
        else
            OPENAI_API_KEY=""
        fi
    done
}

# Sección: Runway ML Configuration
configure_runway() {
    log_section "2️⃣  CONFIGURACIÓN DE RUNWAY ML"
    
    echo "Necesitas una API key de Runway ML para generar los videos."
    echo ""
    echo "📌 Pasos para obtener tu API key:"
    echo ""
    echo "  1. Ve a: ${CYAN}https://app.runwayml.com/${NC}"
    echo "  2. Inicia sesión o crea una cuenta"
    echo "  3. Ve a Settings → API Keys"
    echo "  4. Crea una nueva API key"
    echo "  5. Copia la clave y pégala aquí"
    echo ""
    
    while true; do
        read -p "$(echo -e ${YELLOW}Ingresa tu Runway ML API Key:${NC}) " -r RUNWAY_API_KEY
        
        if ! validate_not_empty "$RUNWAY_API_KEY" "Runway ML API Key"; then
            continue
        fi
        
        echo ""
        echo "Tu clave: ${CYAN}${RUNWAY_API_KEY:0:10}...${NC}"
        echo ""
        
        read -p "$(echo -e ${YELLOW}¿Es correcta? (s/n): ${NC})" -r response
        
        if [[ $response =~ ^[Ss]$ ]]; then
            log_success "Runway ML configurada ✓"
            return 0
        else
            RUNWAY_API_KEY=""
        fi
    done
}

# Sección: ElevenLabs Configuration
configure_elevenlabs() {
    log_section "3️⃣  CONFIGURACIÓN DE ELEVENLABS"
    
    echo "Necesitas una API key de ElevenLabs para generar la narración en audio."
    echo ""
    echo "📌 Pasos para obtener tu API key:"
    echo ""
    echo "  1. Ve a: ${CYAN}https://elevenlabs.io/${NC}"
    echo "  2. Crea una cuenta o inicia sesión"
    echo "  3. Ve a tu Profile (icono en la esquina superior derecha)"
    echo "  4. Haz scroll hasta 'API Key'"
    echo "  5. Copia tu API key y pégala aquí"
    echo ""
    
    while true; do
        read -p "$(echo -e ${YELLOW}Ingresa tu ElevenLabs API Key:${NC}) " -r ELEVENLABS_API_KEY
        
        if ! validate_not_empty "$ELEVENLABS_API_KEY" "ElevenLabs API Key"; then
            continue
        fi
        
        echo ""
        echo "Tu clave: ${CYAN}${ELEVENLABS_API_KEY:0:10}...${NC}"
        echo ""
        
        read -p "$(echo -e ${YELLOW}¿Es correcta? (s/n): ${NC})" -r response
        
        if [[ $response =~ ^[Ss]$ ]]; then
            # Probar la clave
            if test_elevenlabs_key "$ELEVENLABS_API_KEY"; then
                log_success "ElevenLabs configurada ✓"
                return 0
            else
                echo ""
                log_error "La API key no es válida. Intenta nuevamente."
                echo ""
                ELEVENLABS_API_KEY=""
            fi
        else
            ELEVENLABS_API_KEY=""
        fi
    done
}

# Sección: Google Translate Configuration
configure_google_translate() {
    log_section "4️⃣  CONFIGURACIÓN DE GOOGLE TRANSLATE"
    
    echo "Necesitas una API key de Google Cloud para generar subtítulos en múltiples idiomas."
    echo ""
    echo "📌 Pasos para obtener tu API key:"
    echo ""
    echo "  1. Ve a: ${CYAN}https://cloud.google.com/translate${NC}"
    echo "  2. Click en 'Go to Console' o crea un nuevo proyecto"
    echo "  3. Ve a 'APIs & Services' → 'Credentials'"
    echo "  4. Click en 'Create Credentials' → 'API Key'"
    echo "  5. Copia la API key y pégala aquí"
    echo ""
    echo "⚠️  IMPORTANTE:"
    echo "    - Asegúrate que Google Cloud Translation API esté habilitada"
    echo "    - Haz clic en 'Enable API' si es necesario"
    echo ""
    
    while true; do
        read -p "$(echo -e ${YELLOW}Ingresa tu Google Translate API Key:${NC}) " -r GOOGLE_TRANSLATE_API_KEY
        
        if ! validate_not_empty "$GOOGLE_TRANSLATE_API_KEY" "Google Translate API Key"; then
            continue
        fi
        
        echo ""
        echo "Tu clave: ${CYAN}${GOOGLE_TRANSLATE_API_KEY:0:10}...${NC}"
        echo ""
        
        read -p "$(echo -e ${YELLOW}¿Es correcta? (s/n): ${NC})" -r response
        
        if [[ $response =~ ^[Ss]$ ]]; then
            # Probar la clave
            if test_google_translate_key "$GOOGLE_TRANSLATE_API_KEY"; then
                log_success "Google Translate configurada ✓"
                return 0
            else
                echo ""
                log_error "La API key no es válida. Intenta nuevamente."
                echo ""
                GOOGLE_TRANSLATE_API_KEY=""
            fi
        else
            GOOGLE_TRANSLATE_API_KEY=""
        fi
    done
}

# Guardar configuración en .env
save_env_file() {
    log_section "💾 GUARDANDO CONFIGURACIÓN"
    
    log_info "Creando archivo .env..."
    
    # Copiar .env.example como base
    if [ -f "$ENV_EXAMPLE" ]; then
        cp "$ENV_EXAMPLE" "$ENV_FILE"
        log_success "Plantilla copiada"
    else
        log_error "No se encontró .env.example"
        return 1
    fi
    
    # Actualizar valores
    log_info "Actualizando API keys..."
    
    # Función auxiliar para actualizar variables en .env (compatible con macOS)
    update_env_var() {
        local var_name="$1"
        local var_value="$2"
        local env_file="$3"
        
        # Escapar caracteres especiales para sed
        local escaped_value=$(printf '%s\n' "$var_value" | sed -e 's/[\/&]/\\&/g')
        
        if grep -q "^${var_name}=" "$env_file"; then
            sed -i.bak "s|^${var_name}=.*|${var_name}=\"${escaped_value}\"|" "$env_file"
            rm -f "${env_file}.bak"
        else
            echo "${var_name}=\"${var_value}\"" >> "$env_file"
        fi
    }
    
    update_env_var "OPENAI_API_KEY" "$OPENAI_API_KEY" "$ENV_FILE"
    update_env_var "RUNWAY_API_KEY" "$RUNWAY_API_KEY" "$ENV_FILE"
    update_env_var "ELEVENLABS_API_KEY" "$ELEVENLABS_API_KEY" "$ENV_FILE"
    update_env_var "GOOGLE_TRANSLATE_API_KEY" "$GOOGLE_TRANSLATE_API_KEY" "$ENV_FILE"
    
    log_success "API keys guardadas en $ENV_FILE"
    
    # Proteger el archivo
    chmod 600 "$ENV_FILE"
    log_success "Permisos del archivo configurados (600 - solo lectura para el propietario)"
}

# Mostrar resumen
show_summary() {
    log_section "✅ ¡CONFIGURACIÓN COMPLETADA!"
    
    echo ""
    echo "Tu archivo .env ha sido creado exitosamente."
    echo ""
    echo "📁 Ubicación: ${CYAN}${ENV_FILE}${NC}"
    echo ""
    echo -e "${GREEN}APIs Configuradas:${NC}"
    echo -e "  ${GREEN}✓${NC} OpenAI (ChatGPT)"
    echo -e "  ${GREEN}✓${NC} Runway ML"
    echo -e "  ${GREEN}✓${NC} ElevenLabs"
    echo -e "  ${GREEN}✓${NC} Google Translate"
    echo ""
    echo "📝 Próximos pasos:"
    echo ""
    echo "  1. Verifica que el archivo .env sea correcto:"
    echo -e "     ${CYAN}cat ${ENV_FILE}${NC}"
    echo ""
    echo "  2. Asegúrate de tener una imagen del producto en:"
    echo -e "     ${CYAN}${PROJECT_DIR}/data/products/images/${NC}"
    echo ""
    echo "  3. Ejecuta el generador de videos:"
    echo -e "     ${CYAN}bash ${PROJECT_DIR}/scripts/main.sh --help${NC}"
    echo ""
    echo "  4. Ejemplo completo:"
    echo -e "     ${CYAN}bash ${PROJECT_DIR}/scripts/main.sh -i producto.jpg -m \"Samsung Galaxy A53\"${NC}"
    echo ""
    
    log_success "¡Listo para generar videos!"
}

# Main
main() {
    # Crear directorio de config si no existe
    mkdir -p "$(dirname "$LOG_FILE")"
    
    log_info "Iniciando configuración..."
    
    # Verificar si .env ya existe
    if [ -f "$ENV_FILE" ]; then
        echo -e "${YELLOW}⚠ El archivo .env ya existe.${NC}"
        echo ""
        read -p "$(echo -e ${YELLOW}¿Deseas reemplazarlo? (s/n): ${NC})" -r response
        
        if ! [[ $response =~ ^[Ss]$ ]]; then
            log_warning "Configuración cancelada"
            exit 0
        fi
    fi
    
    # Mostrar bienvenida
    show_welcome
    
    # Configurar cada API
    configure_openai
    echo ""
    
    configure_runway
    echo ""
    
    configure_elevenlabs
    echo ""
    
    configure_google_translate
    echo ""
    
    # Guardar configuración
    save_env_file
    
    # Mostrar resumen
    show_summary
    
    log_info "Log guardado en: $LOG_FILE"
}

# Ejecutar
main "$@"
