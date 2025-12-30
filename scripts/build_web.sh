#!/bin/bash

# =====================================================
#   GENERADOR WEB v31 (Fix: Navegación Local)
# =====================================================

# 1. DEFINICIÓN DE RUTAS
PROJECT_ROOT=$(pwd)
SRC_DIR="$PROJECT_ROOT/source"
CHAPTERS_DIR="$SRC_DIR/chapters"
IMAGES_DIR="$SRC_DIR/images"

WEB_ROOT="$PROJECT_ROOT/docs"
DOCS_CONTENT="$WEB_ROOT/docs"
TEMP_DIR="$PROJECT_ROOT/build/web_temp"

# 2. LISTA DE CAPÍTULOS
declare -a ORDEN_CAPITULOS=(
    "estructura-datos"
    "operaciones-estructuras"
    "matrices-especiales"
    "sistemas_ecuaciones"
    "regresion_lineal"
)

echo "========================================"
echo "   GENERADOR WEB v31"
echo "========================================"

# --- 3. LIMPIEZA ---
rm -rf "$TEMP_DIR" "$WEB_ROOT"
mkdir -p "$TEMP_DIR"
mkdir -p "$DOCS_CONTENT/stylesheets" "$DOCS_CONTENT/javascripts" "$DOCS_CONTENT/imagenes"

# Copiar capítulos
cp "$CHAPTERS_DIR"/*.tex "$TEMP_DIR/" 2>/dev/null || { echo "❌ Error copiando caps"; exit 1; }

# --- 4. ESTILOS CSS ---
cat > "$DOCS_CONTENT/stylesheets/extra.css" <<ENDCSS
body { font-size: 18px; line-height: 1.6; color: #333; }
figure { display: block; margin: 40px auto; text-align: center; }
figure img { max-width: 100%; box-shadow: 0 4px 8px rgba(0,0,0,0.1); border-radius: 4px; }
figcaption { font-style: italic; color: #666; margin-top: 10px; }
.md-typeset .arithmatex { overflow-x: auto; }
details.example { background-color: #f0f8ff; border: 1px solid #2b506e; border-radius: 5px; margin: 1.5em 0; }
details.example summary { background-color: #2b506e; color: white; padding: 10px; cursor: pointer; font-weight: bold; }
.details-content { padding: 15px; background: white; border-top: 1px solid #ddd; }
ENDCSS

# --- 5. COPIADO DE IMÁGENES ---
echo ">> Copiando imágenes desde $IMAGES_DIR..."
if [ -d "$IMAGES_DIR" ]; then
    cp -r "$IMAGES_DIR/"* "$DOCS_CONTENT/imagenes/" 2>/dev/null || true
else
    echo "⚠️  ERROR: No encuentro la carpeta $IMAGES_DIR."
fi

# --- 6. CONFIGURACIÓN MKDOCS (Aquí está el arreglo) ---
cat > "$WEB_ROOT/mkdocs.yml" <<ENDYML
site_name: Libro IA Agroambiental
site_dir: ../docs_html_final
docs_dir: docs
# ESTA LINEA ARREGLA LA NAVEGACIÓN LOCAL:
use_directory_urls: false
theme:
  name: material
  language: es
  palette: { scheme: default, primary: teal, accent: indigo }
markdown_extensions:
  - pymdownx.arithmatex: { generic: true }
  - pymdownx.highlight: { anchor_linenums: true }
  - pymdownx.superfences
  - admonition
  - pymdownx.details
  - attr_list
  - md_in_html
extra_css: [stylesheets/extra.css]
extra_javascript:
  - https://polyfill.io/v3/polyfill.min.js?features=es6
  - https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js
  - javascripts/mathjax-config.js
nav:
  - Inicio: index.md
ENDYML

for cap in "${ORDEN_CAPITULOS[@]}"; do
    if [ -f "$TEMP_DIR/$cap.tex" ]; then
        # Nota: MkDocs usará el nombre del archivo .md como ruta
        echo "  - $cap.md" >> "$WEB_ROOT/mkdocs.yml"
    fi
done

# --- 7. MATHJAX ---
cat > "$DOCS_CONTENT/javascripts/mathjax-config.js" <<ENDJS
window.MathJax = {
  loader: {load: ['[tex]/boldsymbol', '[tex]/ams']},
  tex: { packages: {'[+]': ['boldsymbol', 'ams']}, inlineMath: [["\\(", "\\)"], ["$", "$"]], displayMath: [["\\[", "\\]"], ["$$", "$$"]] },
  options: { processHtmlClass: "arithmatex|imagen-caption" }
};
ENDJS

# --- 8. CONVERSIÓN PANDOC ---
echo ">> Transformando LaTeX a Markdown..."
cd "$TEMP_DIR" || exit

# Pre-procesado
sed -i 's/\\begin{alertblock}{\(.*\)}/TOKENINFOSTART \1 TOKENINFOENDTITLE/g' *.tex
sed -i 's/\\end{alertblock}/TOKENINFOSTOP/g' *.tex
sed -i 's/\\begin{appbox}{\(.*\)}/TOKENEXAMPLESTART \1 TOKENEXAMPLEENDTITLE/g' *.tex
sed -i 's/\\end{appbox}/TOKENEXAMPLESTOP/g' *.tex
sed -i 's/\\begin{agrobox}{\(.*\)}/TOKENAGROSTART \1 TOKENAGROENDTITLE/g' *.tex
sed -i 's/\\end{agrobox}/TOKENAGROSTOP/g' *.tex
sed -i 's/\\begin{lstlisting}.*[Pp]ython.*/\\begin{lstlisting}[language=Python]/g' *.tex

echo "# Bienvenido" > "$DOCS_CONTENT/index.md"

for archivo in *.tex; do
    nombre=$(basename "$archivo" .tex)
    if [ "$nombre" == "main" ]; then continue; fi
    TARGET="$DOCS_CONTENT/$nombre.md"

    pandoc "$archivo" -f latex -t markdown-simple_tables+fenced_code_blocks --mathjax --wrap=none -o "$TARGET"

        # Post-Procesado
    sed -i 's/TOKENINFOSTART \(.*\) TOKENINFOENDTITLE/<div class="admonition warning"><p class="admonition-title">\1<\/p>/g' "$TARGET"
    sed -i 's/TOKENINFOSTOP/<\/div>/g' "$TARGET"
    sed -i 's/TOKENEXAMPLESTART \(.*\) TOKENEXAMPLEENDTITLE/<details class="example"><summary><strong>Aplicación: \1<\/strong><\/summary><div class="details-content">/g' "$TARGET"
    sed -i 's/TOKENEXAMPLESTOP/<\/div><\/details>/g' "$TARGET"
    sed -i 's/TOKENAGROSTART \(.*\) TOKENAGROENDTITLE/<div class="admonition tip"><p class="admonition-title">🌿 \1<\/p>/g' "$TARGET"
    sed -i 's/TOKENAGROSTOP/<\/div>/g' "$TARGET"

    # Corrección de imágenes en sintaxis Markdown
    perl -0777 -i -pe 's/!\[(.*?)\]\((.*?)\)\s*(\{.*?\})?/my $alt=$1; my $path=$2; $path =~ s|^.*?\/||; $path =~ s|\.[^.]+$||; "\n<figure markdown=\"span\">\n  ![$alt](imagenes\/$path.svg)\n  <figcaption>$alt<\/figcaption>\n<\/figure>\n"/ge' "$TARGET"

    # Corrección de imágenes en HTML (<embed>, <img>, etc.)
    sed -i 's|src="images/\([^"]*\)\.pdf"|src="imagenes/\1.svg"|g' "$TARGET"
    sed -i 's|src="images/\([^"]*\)\.svg"|src="imagenes/\1.svg"|g' "$TARGET"

    sed -i '/::: titlepage/d' "$TARGET"
done

# --- 9. BUILD ---
echo ">> Compilando sitio MkDocs..."
cd "$WEB_ROOT" && mkdocs build
echo "✅ SITIO LISTO: docs_html_final/index.html"
