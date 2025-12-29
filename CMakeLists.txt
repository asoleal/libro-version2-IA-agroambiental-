cmake_minimum_required(VERSION 3.12)
project(LibroIA)

# --- 1. Configuración del PDF (Modo "In-Source" Seguro) ---
add_custom_target(libro ALL
    # Paso 1: Compilar dentro de 'source' (Igual que manual)
    COMMAND xelatex -interaction=nonstopmode -halt-on-error main.tex
    # Paso 2: Segunda pasada para índices y referencias
    COMMAND xelatex -interaction=nonstopmode -halt-on-error main.tex
    # Paso 3: Mover el PDF resultante a la carpeta 'pdf' visible
    COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_SOURCE_DIR}/pdf
    COMMAND ${CMAKE_COMMAND} -E copy main.pdf ${CMAKE_SOURCE_DIR}/pdf/main.pdf

    # IMPORTANTE: Esto le dice a CMake que trabaje DENTRO de source
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/source

    COMMENT "📖 Compilando PDF (Modo Seguro)..."
)

# --- 2. Configuración de la Web ---
add_custom_target(web
    COMMAND bash ${CMAKE_SOURCE_DIR}/scripts/build_web.sh
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    COMMENT "🌍 Generando Web..."
)
