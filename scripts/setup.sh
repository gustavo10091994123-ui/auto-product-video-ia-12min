#!/bin/bash

################################################################################
# AUTO PRODUCT VIDEO IA - SETUP SCRIPT
# Instala todas las dependencias necesarias
################################################################################

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LOG_FILE="${PROJECT_DIR}/setup.log"

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}Auto Product Video IA - Setup${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

# Logging function
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

# Verificar sistema operativo
check_os() {
    log_info "Detectando sistema operativo..."
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
        log_success "Sistema: Linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="mac"
        log_success "Sistema: macOS"
    else
        log_error "Sistema operativo no soportado: $OSTYPE"
        exit 1
    fi
}

# Verificar Bash version
check_bash_version() {
    log_info "Verificando versión de Bash..."
    
    if [[ ${BASH_VERSINFO[0]} -lt 4 ]]; then
        log_error "Se requiere Bash 4.0 o superior (tienes ${BASH_VERSINFO[0]}.${BASH_VERSINFO[1]})"
        exit 1
    fi
    
    log_success "Bash ${BASH_VERSINFO[0]}.${BASH_VERSINFO[1]} verificado"
}

# Instalar dependencias en Linux
install_linux_deps() {
    log_info "Instalando dependencias para Linux..."
    
    if ! command -v apt-get &> /dev/null; then
        log_error "apt-get no encontrado. Se requiere un sistema Debian/Ubuntu"
        exit 1
    fi
    
    log "Actualizando package manager..."
    sudo apt-get update -y
    
    # Dependencias principales
    local deps=(
        "curl"
        "wget"
        "jq"
        "ffmpeg"
        "python3"
        "python3-pip"
        "git"
        "imagemagick"
        "sox"
    )
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            log "Instalando $dep..."
            sudo apt-get install -y "$dep"
        else
            log_success "$dep ya está instalado"
        fi
    done
}

# Instalar dependencias en macOS
install_mac_deps() {
    log_info "Instalando dependencias para macOS..."
    
    if ! command -v brew &> /dev/null; then
        log_warning "Homebrew no encontrado. Instalando..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    
    # Dependencias principales
    local deps=(
        "curl"
        "wget"
        "jq"
        "ffmpeg"
        "python@3.11"
        "git"
        "imagemagick"
        "sox"
    )
    
    for dep in "${deps[@]}"; do
        if ! brew list "$dep" &> /dev/null 2>&1; then
            log "Instalando $dep..."
            brew install "$dep"
        else
            log_success "$dep ya está instalado"
        fi
    done
}

# Instalar dependencias de Python
install_python_deps() {
    log_info "Instalando dependencias de Python..."
    
    local python_deps=(
        "requests==2.31.0"
        "beautifulsoup4==4.12.2"
        "lxml==4.9.3"
        "selenium==4.14.0"
        "openai==1.3.0"
        "google-cloud-translate==3.11.1"
        "python-dotenv==1.0.0"
        "pydub==0.25.1"
    )
    
    for dep in "${python_deps[@]}"; do
        log "Instalando Python: $dep..."
        pip3 install "$dep" 2>/dev/null || pip install "$dep"
    done
    
    log_success "Dependencias de Python instaladas"
}

# Crear estructura de directorios
create_directories() {
    log_info "Creando estructura de directorios..."
    
    local dirs=(
        "${PROJECT_DIR}/data/products/images"
        "${PROJECT_DIR}/data/outputs/videos"
        "${PROJECT_DIR}/data/outputs/subtitles"
        "${PROJECT_DIR}/data/outputs/scripts"
        "${PROJECT_DIR}/data/outputs/narration"
        "${PROJECT_DIR}/data/outputs/logs"
        "${PROJECT_DIR}/config"
        "${PROJECT_DIR}/templates"
        "${PROJECT_DIR}/docs"
    )
    
    for dir in "${dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            log_success "Directorio creado: $dir"
        else
            log "Directorio ya existe: $dir"
        fi
    done
}

# Hacer scripts ejecutables
make_scripts_executable() {
    log_info "Haciendo scripts ejecutables..."
    
    for script in "${PROJECT_DIR}"/scripts/*.sh; do
        if [ -f "$script" ]; then
            chmod +x "$script"
            log_success "Ejecutable: $(basename "$script")"
        fi
    done
}

# Crear archivo .env si no existe
setup_env_file() {
    log_info "Configurando archivo .env..."
    
    if [ ! -f "${PROJECT_DIR}/.env" ]; then
        if [ -f "${PROJECT_DIR}/.env.example" ]; then
            cp "${PROJECT_DIR}/.env.example" "${PROJECT_DIR}/.env"
            log_success "Archivo .env creado. Por favor, edita con tus API keys:"
            log_warning "nano ${PROJECT_DIR}/.env"
        else
            log_error "No se encontró .env.example"
            exit 1
        fi
    else
        log_success "Archivo .env ya existe"
    fi
}

# Verificar herramientas esenciales
verify_tools() {
    log_info "Verificando herramientas esenciales..."
    
    local tools=(
        "curl"
        "jq"
        "ffmpeg"
        "python3"
    )
    
    for tool in "${tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            local version=$("$tool" --version 2>/dev/null | head -n 1)
            log_success "$tool: $version"
        else
            log_error "$tool no encontrado"
            exit 1
        fi
    done
}

# Crear archivo de configuración principal
create_config_file() {
    log_info "Creando archivo de configuración..."
    
    cat > "${PROJECT_DIR}/config/settings.conf" << 'EOF'
# ============================================
# CONFIGURACIÓN PRINCIPAL
# ============================================

# Valores por defecto
export DEFAULT_VIDEO_DURATION=12
export DEFAULT_VIDEO_QUALITY="1080p"
export DEFAULT_SUBTITLE_LANGUAGES="en,ru,zh"
export DEFAULT_OUTPUT_FORMAT="mp4"

# Rutas
export PROJECT_ROOT="${PROJECT_DIR}"
export SCRIPTS_DIR="${PROJECT_DIR}/scripts"
export CONFIG_DIR="${PROJECT_DIR}/config"
export DATA_DIR="${PROJECT_DIR}/data"
export TEMPLATES_DIR="${PROJECT_DIR}/templates"
export DOCS_DIR="${PROJECT_DIR}/docs"

# Logging
export LOG_LEVEL="INFO"
export LOG_DIR="${PROJECT_DIR}/data/outputs/logs"
export ENABLE_DEBUG="false"
EOF
    
    log_success "Archivo de configuración creado"
}

# Resumen de instalación
show_summary() {
    echo ""
    echo -e "${GREEN}================================${NC}"
    echo -e "${GREEN}✓ Instalación completada${NC}"
    echo -e "${GREEN}================================${NC}"
    echo ""
    echo -e "${BLUE}Próximos pasos:${NC}"
    echo ""
    echo "1. Edita el archivo .env con tus API keys:"
    echo -e "   ${YELLOW}nano ${PROJECT_DIR}/.env${NC}"
    echo ""
    echo "2. Obtén las API keys en:"
    echo -e "   ${YELLOW}OpenAI: https://platform.openai.com/api-keys${NC}"
    echo -e "   ${YELLOW}Runway ML: https://app.runwayml.com/${NC}"
    echo -e "   ${YELLOW}ElevenLabs: https://elevenlabs.io/${NC}"
    echo -e "   ${YELLOW}Google Translate: https://cloud.google.com/translate${NC}"
    echo ""
    echo "3. Ejecuta el script principal:"
    echo -e "   ${YELLOW}bash ${PROJECT_DIR}/scripts/main.sh --help${NC}"
    echo ""
    echo "4. Ver documentación:"
    echo -e "   ${YELLOW}cat ${PROJECT_DIR}/README.md${NC}"
    echo ""
    echo -e "${BLUE}Log de instalación:${NC} ${LOG_FILE}"
    echo ""
}

# Main execution
main() {
    check_bash_version
    check_os
    
    if [ "$OS" = "linux" ]; then
        install_linux_deps
    elif [ "$OS" = "mac" ]; then
        install_mac_deps
    fi
    
    install_python_deps
    create_directories
    make_scripts_executable
    setup_env_file
    create_config_file
    verify_tools
    show_summary
    
    log_success "Setup finalizado correctamente"
}

# Ejecutar
main "$@"
