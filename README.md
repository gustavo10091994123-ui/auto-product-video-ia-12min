# Auto Product Video IA - 12 Minutos

Automatización completa para generar videos de productos de ~12 minutos con IA, incluyendo:
- Búsqueda automática de características en Internet
- Generación de narración con IA
- Videos de alta calidad
- Subtítulos en múltiples idiomas (Inglés, Ruso, Chino)

## 🚀 Características

✅ Entrada: Imagen del producto + Modelo oficial
✅ Búsqueda: Web scraping de características y especificaciones
✅ Generación: Videos de ~12 minutos con Runway ML
✅ Narración: Automática con ElevenLabs
✅ Subtítulos: Inglés, Ruso, Chino
✅ Salida: Guardado en dispositivo local (móvil/ordenador)
✅ Automatización: Scripts Bash completamente funcionales

## 📋 Requisitos Previos

- Bash 4.0+
- ffmpeg
- curl
- jq
- Python 3.8+
- API Keys:
  - OpenAI (ChatGPT)
  - Runway ML
  - ElevenLabs
  - Google Translate API (para subtítulos)

## 🔧 Instalación Rápida (3 comandos)

### 1️⃣ Clonar repositorio
```bash
git clone https://github.com/gustavo10091994123-ui/auto-product-video-ia-12min.git
cd auto-product-video-ia-12min
```

### 2️⃣ Instalar dependencias
```bash
bash scripts/setup.sh
```

### 3️⃣ Configurar API Keys (NUEVO: Configurador Interactivo)
```bash
bash scripts/configure_env.sh
```

El script `configure_env.sh` reemplaza el flujo manual anterior (`cp .env.example .env` + `nano .env`). Ahora es:
- ✨ **Interactivo**: Te guía paso a paso
- 🔍 **Validador**: Verifica que las claves sean válidas
- 🧪 **Testea las APIs**: Confirma que funcionan antes de guardar
- 📚 **Con instrucciones**: Te muestra dónde obtener cada API key
- 🔒 **Seguro**: Protege el archivo .env con permisos restrictivos

---

## 📁 Estructura del Proyecto

```
auto-product-video-ia-12min/
├── README.md
├── .env.example
├── .gitignore
├── scripts/
│   ├── setup.sh                 # Instalación de dependencias
│   ├── configure_env.sh         # ⭐ NEW: Configuración interactiva
│   ├── main.sh                  # Script principal orquestador
│   ├── search_product_info.sh   # Web scraping de características
│   ├── generate_script.sh       # Generación de script con ChatGPT
│   ├── generate_video.sh        # Creación de video con Runway ML
│   ├── generate_narration.sh    # Narración con ElevenLabs
│   ├── generate_subtitles.sh    # Generación de subtítulos
│   ├── utils.sh                 # Funciones utilitarias
│   └── cleanup.sh               # Limpieza de archivos temporales
├── config/
│   ├── settings.conf            # Configuración general
│   ├── prompts.conf             # Prompts para ChatGPT
│   └── languages.conf           # Códigos de idiomas
├── data/
│   ├── products/
│   │   ├── images/              # Imágenes de productos
│   │   └── models.txt           # Modelos de productos
│   └── outputs/
│       ├── videos/              # Videos generados
│       ├── subtitles/           # Archivos de subtítulos
│       ├── scripts/             # Scripts generados
│       ├── narration/           # Archivos de audio
│       └── logs/                # Registros de ejecución
├── templates/
│   ├── video_template.json
│   ├── subtitle_template.srt
│   └── script_template.txt
└── docs/
    ├── INSTALLATION.md
    ├── USAGE.md
    ├── API_SETUP.md
    └── TROUBLESHOOTING.md
```

## 🎯 Uso Rápido

### Paso 1: Preparar imagen y modelo
```bash
# Copiar imagen del producto
cp /ruta/a/producto.jpg data/products/images/

# Crear archivo de modelo (opcional - se puede pasar por parámetro)
echo "Samsung Galaxy A53" > data/products/models.txt
```

### Paso 2: Ejecutar el pipeline completo
```bash
bash scripts/main.sh \
  --image "producto.jpg" \
  --model "Samsung Galaxy A53" \
  --output "/home/usuario/videos/" \
  --languages "en,ru,zh"
```

### Paso 3: El video estará en tu directorio de salida
```
/home/usuario/videos/
├── samsung-galaxy-a53-12min.mp4
├── samsung-galaxy-a53-en.srt
├── samsung-galaxy-a53-ru.srt
└── samsung-galaxy-a53-zh.srt
```

## 📊 Scripts Disponibles

### setup.sh - Instalación
Instala todas las dependencias del sistema y Python necesarias.

```bash
bash scripts/setup.sh
```

**Lo que hace:**
- ✓ Verifica Bash 4.0+
- ✓ Detecta el SO (Linux/macOS)
- ✓ Instala dependencias de sistema (curl, jq, ffmpeg, etc)
- ✓ Instala dependencias de Python
- ✓ Crea estructura de directorios
- ✓ Hace los scripts ejecutables
- ✓ Configura permisos

---

### configure_env.sh - Configuración Interactiva ⭐ NEW

Script interactivo que reemplaza `cp .env.example .env` + `nano .env`.

```bash
bash scripts/configure_env.sh
```

**Características:**
- 🎯 Interfaz interactiva paso a paso
- 📝 Solicita cada API key una por una
- 🔗 Proporciona enlace directo para obtener cada key
- ✅ Valida el formato de cada key
- 🧪 Prueba cada API antes de guardar
- 📋 Resumen de configuración al final
- 🔒 Protege el archivo .env (permisos 600)
- 📝 Genera log de configuración

**Ejemplo de ejecución:**

```
╔════════════════════════════════════════════════╗
║                                                ║
║  🎬 AUTO PRODUCT VIDEO IA - CONFIGURACIÓN     ║
║     Configurador Interactivo de API Keys      ║
║                                                ║
╚════════════════════════════════════════════════╝

Este script te guiará para configurar todas las API keys necesarias.

Necesitarás:
  ✓ OpenAI API Key (ChatGPT)
  ✓ Runway ML API Key
  ✓ ElevenLabs API Key
  ✓ Google Translate API Key

Tiempo estimado: 5-10 minutos
```

**APIs que configura:**

| # | API | Propósito | Enlace |
|---|-----|----------|--------|
| 1 | OpenAI | Generar scripts con ChatGPT | https://platform.openai.com/api-keys |
| 2 | Runway ML | Generar videos | https://app.runwayml.com/ |
| 3 | ElevenLabs | Narración en audio | https://elevenlabs.io/ |
| 4 | Google Translate | Subtítulos multiidioma | https://cloud.google.com/translate |

---

### main.sh - Script Principal
Orquesta todo el proceso automáticamente.

```bash
bash scripts/main.sh \
  --image "producto.jpg" \
  --model "Modelo Oficial" \
  --output "/ruta/salida" \
  --languages "en,ru,zh" \
  --duration 12 \
  --verbose
```

**Opciones:**
- `--image`: Imagen del producto (requerido)
- `--model`: Modelo oficial (requerido)
- `--output`: Directorio de salida (opcional, por defecto: data/outputs/videos/)
- `--languages`: Idiomas de subtítulos (en,ru,zh)
- `--duration`: Duración en minutos (por defecto: 12)
- `--verbose`: Modo verboso
- `--help`: Mostrar ayuda

### search_product_info.sh - Búsqueda de Información
Busca características, especificaciones, reviews en Internet.

```bash
bash scripts/search_product_info.sh \
  --model "Samsung Galaxy A53" \
  --output "datos.json"
```

### generate_script.sh - Generación de Script
Crea el guión usando ChatGPT.

```bash
bash scripts/generate_script.sh \
  --info "datos.json" \
  --duration 12 \
  --language es
```

### generate_video.sh - Generación de Video
Crea el video con Runway ML.

```bash
bash scripts/generate_video.sh \
  --script "script.txt" \
  --image "producto.jpg" \
  --duration 12
```

### generate_narration.sh - Narración Automática
Genera audio con ElevenLabs.

```bash
bash scripts/generate_narration.sh \
  --script "script.txt" \
  --language es \
  --voice "professional"
```

### generate_subtitles.sh - Generación de Subtítulos
Crea subtítulos en múltiples idiomas.

```bash
bash scripts/generate_subtitles.sh \
  --video "video.mp4" \
  --script "script.txt" \
  --languages "en,ru,zh"
```

## 🌐 Idiomas Soportados para Subtítulos

| Idioma | Código | Nombre |
|--------|--------|--------|
| 🇬🇧 Inglés | en | English |
| 🇷🇺 Ruso | ru | Русский |
| 🇨🇳 Chino Simplificado | zh | 中文 |

## ⚙️ Configuración Manual (.env)

Si prefieres configurar manualmente sin el script interactivo:

### .env.example
```bash
# OpenAI API
OPENAI_API_KEY="tu-api-key-aqui"
OPENAI_MODEL="gpt-4"

# Runway ML
RUNWAY_API_KEY="tu-api-key-aqui"
RUNWAY_MODEL="gen3"

# ElevenLabs
ELEVENLABS_API_KEY="tu-api-key-aqui"
ELEVENLABS_VOICE_ID="professional"

# Google Translate
GOOGLE_TRANSLATE_API_KEY="tu-api-key-aqui"

# Configuración General
VIDEO_DURATION=12
VIDEO_QUALITY="1080p"
VIDEO_FORMAT="mp4"
DEFAULT_LANGUAGE="es"
TEMP_DIR="/tmp/product_video_ia"
LOG_LEVEL="INFO"
```

## 🔑 Obtener API Keys

### 1. OpenAI (ChatGPT)
1. Ve a https://platform.openai.com/api-keys
2. Crea una nueva API key
3. Copia en `.env`: `OPENAI_API_KEY`

### 2. Runway ML
1. Ve a https://app.runwayml.com/
2. Obtén tu API key en Settings → API Keys
3. Copia en `.env`: `RUNWAY_API_KEY`

### 3. ElevenLabs
1. Ve a https://elevenlabs.io/
2. Crea cuenta y obtén API key
3. Copia en `.env`: `ELEVENLABS_API_KEY`

### 4. Google Translate API
1. Ve a https://cloud.google.com/translate
2. Configura proyecto y API key
3. Copia en `.env`: `GOOGLE_TRANSLATE_API_KEY`

## 📝 Logs y Debugging

Los logs se guardan automáticamente en `data/outputs/logs/`

```bash
# Ver últimos logs
tail -f data/outputs/logs/latest.log

# Ver logs de una ejecución específica
cat data/outputs/logs/2026-06-14_15-30-45.log

# Ver log de configuración
cat config_setup.log
```

## 🐛 Troubleshooting

Ver [TROUBLESHOOTING.md](./docs/TROUBLESHOOTING.md) para solucionar problemas comunes.

### Problemas Comunes

**"API key no válida"**
- Verifica que hayas copiado la clave completa
- Asegúrate de que la API esté habilitada en tu cuenta
- Regenera la clave en la plataforma correspondiente

**"curl: command not found"**
```bash
# Linux
sudo apt-get install curl

# macOS
brew install curl
```

**"ffmpeg: command not found"**
```bash
# Linux
sudo apt-get install ffmpeg

# macOS
brew install ffmpeg
```

## 📄 Licencia

MIT

## 👨‍💻 Autor

**Gustavo** - [@gustavo10091994123-ui](https://github.com/gustavo10091994123-ui)

## 🤝 Contribuciones

¡Las contribuciones son bienvenidas!

1. Fork el proyecto
2. Crea una rama (`git checkout -b feature/AmazingFeature`)
3. Commit cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📞 Soporte

Si tienes preguntas o problemas, abre un [Issue](https://github.com/gustavo10091994123-ui/auto-product-video-ia-12min/issues)
