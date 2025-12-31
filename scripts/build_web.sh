#!/bin/bash

# =====================================================
#   GENERADOR WEB v43 (Regex Mejorado para Entornos)
# =====================================================

# 1. DEFINICIÓN DE RUTAS
PROJECT_ROOT=$(pwd)
SRC_DIR="$PROJECT_ROOT/source"
CHAPTERS_DIR="$SRC_DIR/chapters"
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
echo "   GENERADOR WEB v43"
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
figure img { max-width: 80%; height: auto; box-shadow: 0 4px 8px rgba(0,0,0,0.1); border-radius: 4px; }
figcaption { font-style: italic; color: #666; margin-top: 10px; }
.md-typeset .arithmatex { overflow-x: auto; }

/* Estilos para APPBOX (Mecatrónica) - Opción A: Texto Oscuro */
details.example {
    background-color: #e0f7fa;   /* Cuerpo: Cian muy pálido */
    border: 1px solid #26c6da;   /* Borde: Cian medio */
    border-radius: 5px;
    margin: 1.5em 0;
}

details.example summary {
    background-color: #26c6da;   /* Cabecera: Cian vibrante */
    color: #000000;              /* Texto: NEGRO (Máxima legibilidad) */
    padding: 10px;
    cursor: pointer;
    font-weight: bold;
    border-bottom: 1px solid #0097a7; /* Línea sutil debajo del título */
}
.details-content {
    padding: 15px;
    background: white;
}

/* --- ESTILO TERMINAL DEFINITIVO --- */
pre.terminal-output,
code.terminal-output,
.terminal-output {
    background-color: #f8f9fa;
    color: #212529;
    font-family: 'Consolas', 'Monaco', 'Courier New', monospace;
    font-size: 0.85em;
    padding: 15px;
    border: 1px solid #ddd;
    border-radius: 4px;
    border-left: 5px solid #4caf50; /* Borde verde característico */
    margin: 25px 0;
    display: block;
    white-space: pre;
    overflow-x: auto;
    line-height: 1.45;
}

/* Forzar que el código interno no tenga fondo ni bordes extra */
.terminal-output code {
    background-color: transparent !important;
    padding: 0 !important;
    border: none !important;
    color: inherit !important;
    white-space: pre !important;
}
ENDCSS

# --- 5. MKDOCS.YML ---
cat > "$WEB_ROOT/mkdocs.yml" <<ENDYML
site_name: Libro IA Agroambiental
site_dir: ../docs_html_final
docs_dir: docs
use_directory_urls: false
theme:
  name: material
  language: es
  palette: { scheme: default, primary: teal, accent: indigo }
  features:
    - content.code.copy
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
        echo "  - $cap.md" >> "$WEB_ROOT/mkdocs.yml"
    fi
done

# --- 6. MATHJAX ---
cat > "$DOCS_CONTENT/javascripts/mathjax-config.js" <<ENDJS
window.MathJax = {
  loader: {load: ['[tex]/boldsymbol', '[tex]/ams']},
  tex: { packages: {'[+]': ['boldsymbol', 'ams']}, inlineMath: [["\\(", "\\)"], ["$", "$"]], displayMath: [["\\[", "\\]"], ["$$", "$$"]] },
  options: { processHtmlClass: "arithmatex|imagen-caption" }
};
ENDJS

# --- 7. IMÁGENES ---
echo ">> Copiando imágenes..."
IMAGES_SOURCE="$PROJECT_ROOT/images"
mkdir -p "$DOCS_CONTENT/imagenes"
if [ -d "$IMAGES_SOURCE" ]; then
    cp "$IMAGES_SOURCE"/*.svg "$DOCS_CONTENT/imagenes/" 2>/dev/null || true
fi

# --- 8. PROCESAMIENTO PANDOC ---
echo ">> Transformando LaTeX a Markdown..."
cd "$TEMP_DIR" || exit

# ==========================================================
#  PASO A: PRE-PROCESAMIENTO (CRUCIAL)
# ==========================================================

# 1. Convertimos entornos personalizados a Tokens de texto
sed -i 's/\\begin{alertblock}{\(.*\)}/TOKENINFOSTART \1 TOKENINFOENDTITLE/g' *.tex
sed -i 's/\\end{alertblock}/TOKENINFOSTOP/g' *.tex
sed -i 's/\\begin{appbox}{\(.*\)}/TOKENEXAMPLESTART \1 TOKENEXAMPLEENDTITLE/g' *.tex
sed -i 's/\\end{appbox}/TOKENEXAMPLESTOP/g' *.tex
sed -i 's/\\begin{agrobox}{\(.*\)}/TOKENAGROSTART \1 TOKENAGROENDTITLE/g' *.tex
sed -i 's/\\begin{ingebox}{\(.*\)}/TOKENINGESTART \1 TOKENINGEENDTITLE/g' *.tex
sed -i 's/\\end{ingebox}/TOKENINGESTOP/g' *.tex
sed -i 's/\\end{agrobox}/TOKENAGROSTOP/g' *.tex
sed -i 's/\\begin{lstlisting}.*[Pp]ython.*/\\begin{lstlisting}[language=Python]/g' *.tex

# 2. EL REEMPLAZO "CIRÚRGICO" PARA 'salida'
# Ignoramos tu definición de LaTeX y forzamos un entorno verbatim estándar.
# \s* permite espacios entre {salida} y el corchete opcional [Resultados]
# (?:...)? hace que el argumento opcional sea... opcional.

perl -i -pe 's/\\begin\{salida\}\s*(?:\[.*?\])?/TOKEN_SALIDA_FIX\n\\begin{verbatim}/g' *.tex
perl -i -pe 's/\\end\{salida\}/\\end{verbatim}/g' *.tex

# --- PORTADA ---
if [ -f "$SRC_DIR/intro.md" ]; then
    cp "$SRC_DIR/intro.md" "$DOCS_CONTENT/index.md"
else
    echo "# Bienvenido" > "$DOCS_CONTENT/index.md"
fi

# --- BUCLE DE CAPÍTULOS ---
for archivo in *.tex; do
    nombre=$(basename "$archivo" .tex)
    if [ "$nombre" == "main" ]; then continue; fi
    TARGET="$DOCS_CONTENT/$nombre.md"

    # ==========================================================
    # PASO B: PANDOC
    # ==========================================================
    # Usamos +fenced_code_blocks para que Pandoc prefiera ``` sobre la indentación
    pandoc "$archivo" -f latex -t markdown+fenced_code_blocks --mathjax --wrap=none -o "$TARGET"

    # ==========================================================
    # PASO C: POST-PROCESAMIENTO (Inyección de Clases)
    # ==========================================================

    # Buscamos nuestra marca TOKEN_SALIDA_FIX seguida de un bloque de código.
    # Pandoc puede generar ``` o ~~~.

    # Opción 1: Bloques con ```
    perl -0777 -i -pe 's/TOKEN_SALIDA_FIX\s*\n\s*```/```{.terminal-output}/gs' "$TARGET"

    # Opción 2: Bloques con ~~~
    perl -0777 -i -pe 's/TOKEN_SALIDA_FIX\s*\n\s*~~~/~~~{.terminal-output}/gs' "$TARGET"

    # Limpieza de seguridad: Si quedó algún token suelto (porque el regex falló), bórralo para que no salga en el texto.
    sed -i 's/TOKEN_SALIDA_FIX//g' "$TARGET"

    # 2. Resto de Tokens (Alertas, etc)
    sed -i 's/TOKENINFOSTART \(.*\) TOKENINFOENDTITLE/<div class="admonition warning"><p class="admonition-title">\1<\/p>/g' "$TARGET"
    sed -i 's/TOKENINFOSTOP/<\/div>/g' "$TARGET"
    sed -i 's/TOKENEXAMPLESTART \(.*\) TOKENEXAMPLEENDTITLE/<details class="example"><summary><strong>Aplicación: \1<\/strong><\/summary><div class="details-content">/g' "$TARGET"
    sed -i 's/TOKENEXAMPLESTOP/<\/div><\/details>/g' "$TARGET"
    sed -i 's/TOKENAGROSTART \(.*\) TOKENAGROENDTITLE/<div class="admonition tip"><p class="admonition-title">🌿 \1<\/p>/g' "$TARGET"
    sed -i 's/TOKENAGROSTOP/<\/div>/g' "$TARGET"
    sed -i 's/TOKENINGESTART \(.*\) TOKENINGEENDTITLE/<div class="admonition note"><p class="admonition-title">📘 \1<\/p>/g' "$TARGET"
    sed -i 's/TOKENINGESTOP/<\/div>/g' "$TARGET"

    # 3. Imágenes
    perl -0777 -i -pe 's/!\[(.*?)\]\((.*?)\)\s*(\{.*?\})?/my $alt=$1; my $path=$2; $path =~ s|^.*?\/||; $path =~ s|\.[^.]+$||; "\n<figure markdown=\"span\">\n  ![$alt](imagenes\/$path.svg)\n  <figcaption>$alt<\/figcaption>\n<\/figure>\n"/ge' "$TARGET"
    sed -i 's|src="images/\([^"]*\)\.pdf"|src="imagenes/\1.svg"|g' "$TARGET"
    sed -i 's|src="images/\([^"]*\)\.svg"|src="imagenes/\1.svg"|g' "$TARGET"

    sed -i '/::: titlepage/d' "$TARGET"
done

# --- 9. BUILD ---
echo ">> Compilando sitio MkDocs..."
cd "$WEB_ROOT" && mkdocs build
echo "✅ SITIO LISTO"
