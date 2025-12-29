#!/bin/bash
set -e

# Asegurarnos de estar en la raíz del proyecto
cd "$(dirname "$0")/.."

echo "========================================"
echo "🚀 INICIANDO COMPILACIÓN MAESTRA"
echo "========================================"

# 1. Limpieza
echo "🧹 [1/5] Limpiando build..."
rm -rf build

# 2. Generar figuras (PDF + SVG)
echo "🎨 [2/5] Generando Figuras..."
./scripts/build_figures.sh

# Después de generar figuras, copiar a source/images/
echo "📂 Sincronizando figuras con source/images..."
mkdir -p source/images
cp images/* source/images/

# 3. Configurar CMake
echo "⚙️  [3/5] Configurando CMake..."
cmake -S . -B build -G "Unix Makefiles" > /dev/null

# 4. Compilar PDF
echo "📄 [4/5] Compilando PDF..."
cmake --build build

# 5. Compilar Web (Opcional)
echo "🌐 [5/5] Construyendo Web..."
./scripts/build_web.sh

echo ""
echo "========================================"
echo "✅ ¡ÉXITO!"
echo "📂 PDF: pdf/main.pdf"
echo "🖼️  Figuras: images/*.pdf, images/*.svg"
echo "========================================"
