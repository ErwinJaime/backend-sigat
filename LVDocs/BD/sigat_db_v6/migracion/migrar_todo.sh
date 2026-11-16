#!/bin/bash
# Ejecuta M1..M4 en orden sobre la base indicada (NO ejecuta M5, que es irreversible).
# Uso:  ./migrar_todo.sh "host=... dbname=... user=..."     (cadena de conexión de psql)
# Haga ANTES una copia:  pg_dump -Fc -f respaldo_v5.dump <base>
set -e
cd "$(dirname "$0")"
CONN="${1:?Indique la cadena de conexión de psql}"
for f in M1_preparar.sql M2_instalar_v6.sql M3_copiar_datos.sql M4_verificar.sql; do
  echo "=== $f"; psql "$CONN" -X -v ON_ERROR_STOP=1 -f "$f"
done
echo "Migración lista y verificada. Revise las pruebas de escritorio; cuando acepte: psql \"$CONN\" -v confirmo=SI -f M5_retirar_legado.sql"
