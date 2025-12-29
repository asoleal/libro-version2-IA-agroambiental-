#!/bin/bash

# Detener el script si hay cualquier error
set -e

echo "========================================"
echo "🚀 INICIANDO COMPILACIÓN MAESTRA"
echo "========================================"

# 1. Limpieza Profunda
echo "🧹 [1/4] Borrando compilaciones viejas..."
rm -rf build

# 2. Configuración
echo "⚙️  [2/4] Re-configurando CMake..."
cmake -S . -B build > /dev/null

# --- FIX: CREAR CARPETA CHAPTERS EN BUILD ---
# Esto soluciona el error "I can't write on file"
echo "📂 [2.5/4] Creando estructura de directorios..."
mkdir -p build/chapters
# --------------------------------------------

# 3. PDF
echo "📄 [3/4] Construyendo PDF..."
cmake --build build

# 4. Web
echo "🌐 [4/4] Construyendo Web..."
# Nota: La web usa su propio script interno, pero lo lanzamos vía cmake
cmake --build build --target web

echo ""
echo "========================================"
echo "✅ ¡TODO TERMINADO CON ÉXITO!"
echo "📂 PDF:  pdf/main.pdf"
echo "🌍 WEB:  docs_html_final/index.html"
echo "========================================"
