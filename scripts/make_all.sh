#!/bin/bash
set -e

cd "$(dirname "$0")/.."

echo "========================================"
echo "🚀 INICIANDO COMPILACIÓN MAESTRA"
echo "========================================"

# 1. Limpieza
echo "🧹 [1/5] Limpiando build..."
rm -rf build

# 2. Generar figuras (PDF + SVG) → van a ./images/
echo "🎨 [2/5] Generando Figuras..."
./scripts/build_figures.sh

# 3. 🔑 DISTRIBUIR FIGURAS A LOS LUGARES CORRECTOS
echo "📂 [3/5] Sincronizando figuras..."

# → Para LaTeX (compila desde source/)
mkdir -p source/images
cp -f images/* source/images/

# → Para MkDocs: ¡actualizar LA FUENTE del sitio web!
mkdir -p docs/docs/imagenes
cp -f images/*.svg docs/docs/imagenes/   # Solo SVG para web
# (opcional) cp -f images/*.pdf docs/docs/imagenes/  # si usas PDF en web

echo "   → source/images/ y docs/docs/imagenes/ actualizados"

# 4. Configurar y compilar PDF
echo "⚙️  [4/5] Configurando CMake..."
cmake -S . -B build -G "Unix Makefiles" > /dev/null

echo "📄 [4/5] Compilando PDF..."
cmake --build build

# 5. 🌐 Ahora sí: construir web con las figuras ACTUALIZADAS
echo "🌐 [5/5] Construyendo Web..."
./scripts/build_web.sh

echo ""
echo "========================================"
echo "✅ ¡ÉXITO!"
echo "📂 PDF: pdf/main.pdf"
echo "🌐 Web: docs_html_final/index.html (¡con imágenes nuevas!)"
echo "   Actualizar página en github: git subtree push --prefix docs_html_final origin gh-pages"
echo "   Visualización de la página:  https://asoleal.github.io/libro-version2-IA-agroambiental-/index.html"
echo "========================================"
