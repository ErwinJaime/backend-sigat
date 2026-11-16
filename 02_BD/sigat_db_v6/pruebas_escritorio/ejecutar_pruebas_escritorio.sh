#!/bin/bash
# Carga la base de demostración y corre las pruebas de escritorio.  Uso: ./ejecutar_pruebas_escritorio.sh <cadena de conexión psql>
# ATENCIÓN: usar una base de PRUEBA vacía (instala el esquema y los datos de demo).
set -e
cd "$(dirname "$0")/.."
CONN="${1:?Indique la cadena de conexión de psql (base de prueba)}"
for f in sql/01_esquema_completo.sql sql/02_catalogos_basicos.sql sql/03_vistas.sql sql/04_funciones.sql sql/05_datos_demo.sql; do
  psql "$CONN" -X -q -v ON_ERROR_STOP=1 -f "$f" >/dev/null
done
psql "$CONN" -X -f pruebas_escritorio/PE_ejecutable.sql
