#!/bin/bash

# =====================================================
#   GENERADOR WEB v24 (ADAPTADO A CLEAN ARCHITECTURE)
# =====================================================

# --- 1. RUTAS DEL PROYECTO ---
SRC_ROOT="source"
CHAPTERS_DIR="$SRC_ROOT/chapters"
IMAGES_DIR="$SRC_ROOT/images"
WEB_DIR="docs"  # Salida final (GitHub Pages standard)
DOCS_CONTENT="$WEB_DIR/docs" # Contenido temporal para MkDocs
TEMP_DIR="build/web_temp"    # Carpeta temporal de trabajo

# --- 2. LISTA DE CAPÍTULOS ---
# Deben coincidir con los nombres de archivo en source/chapters
declare -a ORDEN_CAPITULOS=(
    "01-vectores"
    "02-matrices"
    "03-autovalores"
)

echo "========================================"
echo "   GENERADOR WEB v24: Agro & SVG"
echo "========================================"

# --- 3. LIMPIEZA Y PREPARACIÓN ---
echo ">> Limpiando directorios..."
rm -rf "$TEMP_DIR" "$WEB_DIR"
mkdir -p "$TEMP_DIR"
mkdir -p "$DOCS_CONTENT/stylesheets" "$DOCS_CONTENT/javascripts"
mkdir -p "$DOCS_CONTENT/imagenes"

# Copiar capítulos al temporal
cp "$CHAPTERS_DIR"/*.tex "$TEMP_DIR/"

# --- 4. ESTILOS CSS (extra.css) ---
cat > "$DOCS_CONTENT/stylesheets/extra.css" <<EOF
/* Estilos Generales */
body { font-size: 18px; line-height: 1.6; color: #333; }

/* Imágenes Responsivas */
figure { display: block; margin: 40px auto; text-align: center; width: 100%; }
figure img {
    display: block; margin: 0 auto;
    width: 100% !important; max-width: 900px; height: auto;
    box-shadow: 0 8px 16px rgba(0,0,0,0.1);
    border-radius: 6px; background-color: white; padding: 10px;
}
figcaption {
    font-style: italic; font-size: 0.95em; color: #555;
    margin-top: 15px; max-width: 800px; margin-left: auto; margin-right: auto;
}

/* Ajustes Matemáticos y Código */
.md-typeset .arithmatex { overflow-x: auto; }
.admonition.example { margin-bottom: 2em; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }

/* Personalización AgroBox (Verde Teal) */
.md-typeset .admonition.tip { border-color: #009688; }
.md-typeset .admonition.tip .admonition-title { background-color: #009688; color: white; }
EOF

# --- 5. GESTIÓN DE IMÁGENES ---
echo ">> Procesando imágenes desde $IMAGES_DIR..."

if [ -d "$IMAGES_DIR" ]; then
    # Copiar imágenes al destino
    cp -r "$IMAGES_DIR/"* "$DOCS_CONTENT/imagenes/" 2>/dev/null || true

    # Entrar para convertir
    pushd "$DOCS_CONTENT/imagenes" > /dev/null

    # A. PDF a SVG
    if command -v pdf2svg &> /dev/null; then
        find . -type f -name "*.pdf" -exec sh -c 'pdf2svg "{}" "${0%.*}.svg"' {} \;
    fi

    # B. PNG/JPG a SVG (Opcional, consume CPU)
    if command -v magick &> /dev/null; then
        echo "   ... Convirtiendo Rasters a SVG..."
        find . -type f -name "*.png" -exec magick "{}" "${0%.*}.svg" \;
        find . -type f -name "*.jpg" -exec magick "{}" "${0%.*}.svg" \;
    fi
    popd > /dev/null
else
    echo "⚠️  No se encontró carpeta de imágenes en $IMAGES_DIR"
fi

# --- 6. CONFIGURACIÓN MKDOCS (mkdocs.yml) ---
# Nota: Creamos el mkdocs.yml en la raíz de WEB_DIR para que el build funcione allí
cat > "$WEB_DIR/mkdocs.yml" <<EOF
site_name: Libro IA Agroambiental
site_dir: ../docs_html_final # Salida final del HTML estático
docs_dir: docs # Donde están los .md

theme:
  name: material
  language: es
  features: [content.code.copy, navigation.top, navigation.prev, navigation.next]
  palette:
    - scheme: default
      primary: teal
      accent: indigo

markdown_extensions:
  - pymdownx.arithmatex:
      generic: true
  - pymdownx.highlight:
      anchor_linenums: true
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
EOF

# Agregar capítulos dinámicamente al nav
for cap in "${ORDEN_CAPITULOS[@]}"; do
    if [ -f "$TEMP_DIR/$cap.tex" ]; then
       echo "  - $cap.md" >> "$WEB_DIR/mkdocs.yml"
    fi
done

# --- 7. CONFIGURACIÓN MATHJAX ---
cat > "$DOCS_CONTENT/javascripts/mathjax-config.js" <<EOF
window.MathJax = {
  loader: {load: ['[tex]/boldsymbol', '[tex]/ams']},
  tex: {
    packages: {'[+]': ['boldsymbol', 'ams']},
    inlineMath: [["\\(", "\\)"], ["$", "$"]],
    displayMath: [["\\[", "\\]"], ["$$", "$$"]],
    processEscapes: true
  },
  options: {
    processHtmlClass: "arithmatex|imagen-caption|figcaption"
  }
};
EOF

# --- 8. PROCESAMIENTO PANDOC ---
echo ">> Transformando LaTeX a Markdown..."
cd "$TEMP_DIR" || exit

# ================= FASE 1: PRE-PROCESADO =================
# Reemplazos de cajas para que Pandoc no se rompa
sed -i 's/\\begin{alertblock}{\(.*\)}/TOKENINFOSTART \1 TOKENINFOENDTITLE/g' *.tex
sed -i 's/\\end{alertblock}/TOKENINFOSTOP/g' *.tex

sed -i 's/\\begin{tcolorbox}/TOKENWARNINGSTART/g' *.tex
sed -i 's/TOKENWARNINGSTART\[.*\]/TOKENWARNINGSTART/g' *.tex
sed -i 's/\\end{tcolorbox}/TOKENWARNINGSTOP/g' *.tex

sed -i 's/\\begin{appbox}{\(.*\)}/TOKENEXAMPLESTART \1 TOKENEXAMPLEENDTITLE/g' *.tex
sed -i 's/\\end{appbox}/TOKENEXAMPLESTOP/g' *.tex

# SOPORTE AGROBOX
sed -i 's/\\begin{agrobox}{\(.*\)}/TOKENAGROSTART \1 TOKENAGROENDTITLE/g' *.tex
sed -i 's/\\end{agrobox}/TOKENAGROSTOP/g' *.tex

sed -i 's/\\begin{lstlisting}.*[Pp]ython.*/\\begin{lstlisting}[language=Python]/g' *.tex

# ================= FASE 2: CONVERSIÓN PANDOC =================
# Crear index dummy si main.tex no tiene contenido relevante para web
echo "# Bienvenido al Libro de IA Agroambiental" > "../$DOCS_CONTENT/index.md"

for archivo in *.tex; do
    nombre=$(basename "$archivo" .tex)
    # Ignorar main.tex porque es solo un esqueleto, procesamos solo capítulos
    if [ "$nombre" == "main" ]; then continue; fi

    TARGET="../$DOCS_CONTENT/$nombre.md"
    echo "   ... Convirtiendo $nombre"

    pandoc "$archivo" -f latex -t markdown-simple_tables+fenced_code_blocks --mathjax --wrap=none -o "$TARGET"

    # ================= FASE 3: POST-PROCESADO =================

    # Restaurar Cajas
    sed -i 's/TOKENINFOSTART \(.*\) TOKENINFOENDTITLE/<div class="admonition info"><p class="admonition-title">\1<\/p>/g' "$TARGET"
    sed -i 's/TOKENINFOSTOP/<\/div>/g' "$TARGET"

    sed -i 's/TOKENWARNINGSTART/<div class="admonition warning">/g' "$TARGET"
    sed -i 's/TOKENWARNINGSTOP/<\/div>/g' "$TARGET"

    sed -i 's/TOKENEXAMPLESTART \(.*\) TOKENEXAMPLEENDTITLE/<div class="admonition example"><p class="admonition-title">\1<\/p>/g' "$TARGET"
    sed -i 's/TOKENEXAMPLESTOP/<\/div>/g' "$TARGET"

    sed -i 's/TOKENAGROSTART \(.*\) TOKENAGROENDTITLE/<div class="admonition tip"><p class="admonition-title">🌿 \1<\/p>/g' "$TARGET"
    sed -i 's/TOKENAGROSTOP/<\/div>/g' "$TARGET"

    # Arreglar imágenes
    sed -i -E 's/]\((imagenes\/[^).]+)\)/](\1.svg)/g' "$TARGET"
    sed -i 's/\.pdf)/.svg)/g' "$TARGET"
    sed -i 's/\.png)/.svg)/g' "$TARGET"

    # Wrappers de Figuras
    perl -0777 -i -pe 's/!\[(.*?)\]\((.*?)\)\s*(\{.*?\})?/\n<figure markdown="span">\n  ![\1](\2)\3\n  <figcaption class="arithmatex">\1<\/figcaption>\n<\/figure>\n/gs' "$TARGET"

    # Limpieza
    sed -i '/::: titlepage/d' "$TARGET"
done

# Volver a raíz y construir el sitio estático
cd ../..
echo ">> Compilando sitio estático con MkDocs..."
cd "$WEB_DIR" && mkdocs build

echo "✅ ¡Sitio Web generado exitosamente!"
echo "   Puedes verlo abriendo: $WEB_DIR/site/index.html"
