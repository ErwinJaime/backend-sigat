#!/usr/bin/env bash
# Regenera sql/sigat_bd_completa.sql a partir de los archivos fuente.
# Uso: BD/sigat_db_v6/herramientas/generar_consolidado.sh
# Orden: 01 esquema -> 02 catálogos -> 03 vistas -> 04 funciones.
# 06_validacion.sql NO se incluye: es una verificación opcional con \echo de psql.
set -euo pipefail

cd "$(dirname "$0")/../sql"

SALIDA="sigat_bd_completa.sql"
ARCHIVOS=(
  01_esquema_completo.sql
  02_catalogos_basicos.sql
  03_vistas.sql
  04_funciones.sql
)

TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

{
  cat <<'EOF'
-- =====================================================================
-- SIGAT v6 - BASE DE DATOS COMPLETA (PostgreSQL 16+ + PostGIS)
-- ARCHIVO GENERADO: no editar a mano.
-- Regenerar con: BD/sigat_db_v6/herramientas/generar_consolidado.sh
--
-- Contenido: esquema (74 tablas), catálogos básicos, vistas y funciones.
-- NO contiene datos de demostración ni pruebas automáticas.
--
-- Ejecutar sobre una base vacía:
--   psql -v ON_ERROR_STOP=1 -d <BD> -f sigat_bd_completa.sql
-- Requisitos: PostgreSQL 16+ y PostGIS >= 3.3 (extensiones postgis y btree_gist).
-- =====================================================================
EOF

  for archivo in "${ARCHIVOS[@]}"; do
    if [[ ! -f "$archivo" ]]; then
      echo "ERROR: no existe $archivo" >&2
      exit 1
    fi

    # El archivo consolidado se ejecuta con psql pero no debe depender de \ir ni
    # de comandos interactivos. Se aborta si aparece un comando de psql.
    if grep -qE '^[[:space:]]*\\' "$archivo"; then
      echo "ERROR: $archivo contiene comandos de psql (líneas que empiezan con \\)." >&2
      echo "       Quita esos comandos o agrégalos solo en 00_instalar_todo.sql." >&2
      exit 1
    fi

    printf '\n\n-- #####################################################################\n'
    printf -- '-- ## %s\n' "$archivo"
    printf -- '-- #####################################################################\n\n'
    cat "$archivo"
  done

  printf '\n\n-- =====================================================================\n'
  printf -- '-- FIN DE sigat_bd_completa.sql\n'
  printf -- '-- Verificación opcional: psql -v ON_ERROR_STOP=1 -d <BD> -f 06_validacion.sql\n'
  printf -- '-- =====================================================================\n'
} > "$TMP"

mv "$TMP" "$SALIDA"

echo "Generado $SALIDA: $(wc -l < "$SALIDA") líneas, $(wc -c < "$SALIDA") bytes."
