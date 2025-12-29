#!/bin/bash
set -e

# Directorios (relativos al script)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/.."
FIG_SRC="$ROOT_DIR/figures_source"
IMG_DST="$ROOT_DIR/images"

mkdir -p "$IMG_DST"

if [ ! -d "$FIG_SRC" ]; then
    echo "⚠️  Carpeta $FIG_SRC no existe. Nada que compilar."
    exit 0
fi

# Contar figuras .tex
TEX_COUNT=$(find "$FIG_SRC" -name "*.tex" | wc -l)
if [ "$TEX_COUNT" -eq 0 ]; then
    echo "⚠️  No hay archivos .tex en $FIG_SRC."
    exit 0
fi

echo "🎨 Compilando $TEX_COUNT figuras desde $FIG_SRC → $IMG_DST"

# Compilar cada figura
for tex_file in "$FIG_SRC"/*.tex; do
    base=$(basename "$tex_file" .tex)
    pdf_file="$IMG_DST/$base.pdf"
    svg_file="$IMG_DST/$base.svg"

    # Compilar solo si el .tex es más reciente que el .pdf (o no existe)
    if [ ! -f "$pdf_file" ] || [ "$tex_file" -nt "$pdf_file" ]; then
        echo "  → Compilando $base..."
        # Usar un directorio temporal
        tmpdir=$(mktemp -d)
        cp "$tex_file" "$tmpdir/"
        # Opcional: si usas un preámbulo común, descomenta:
        # cp "$ROOT_DIR/source/config/paquetes.tex" "$tmpdir/" 2>/dev/null || true

        # Compilar con pdflatex en modo autónomo
        cd "$tmpdir"
        pdflatex -interaction=nonstopmode -halt-on-error "$base.tex" > /dev/null
        cd - > /dev/null

        # Mover PDF
        mv "$tmpdir/$base.pdf" "$pdf_file"

        # Convertir a SVG
        if command -v pdf2svg >/dev/null; then
            pdf2svg "$pdf_file" "$svg_file"
        else
            echo "❌ pdf2svg no encontrado. Instálalo para generar SVG."
            exit 1
        fi

        # Limpiar
        rm -rf "$tmpdir"
    else
        echo "  → $base.pdf está actualizado. Saltando."
    fi
done

echo "✅ Figuras listas en $IMG_DST"
