# Migración v5 → v6

## Qué cambia entre v5 y v6 (y qué NO cambia)
- **Solo nombres de columnas:** prefijo de 3 → 4 letras (`lot_id` → `lote_id`, `lec_especimenes` → `lect_especimenes`…) y fuera el sufijo `_ica` (`esm_codigo_ica` → `espm_codigo`). Son **586 columnas en 74 tablas**; los nombres de tablas no cambian.
- **No cambia ningún dato, tipo ni relación.** Ninguna columna se elimina ni se agrega. Por eso la migración es una copia fiel con un mapa de nombres, y se puede comprobar fila por fila.

## Estrategia (la misma de la migración anterior)
1. El esquema actual `sigat` se **renombra** a `sigat_v5` y queda intacto como respaldo.
2. Se instala el esquema v6 vacío (`sql/01`, `03`, `04`; el `02` no, porque los catálogos se copian de v5 con sus mismos identificadores).
3. Se copian los datos tabla por tabla (padres antes que hijos) con el mapa `sigat_migracion.mapa_columnas`.
4. Se verifica: para cada tabla, conteo igual y `EXCEPT` en los dos sentidos = 0 filas.
5. Cuando se acepta, `M5` retira el esquema viejo. Hasta entonces se puede **volver atrás** con `M_revertir_a_v5.sql`.

| Archivo | Qué hace | ¿Reversible? |
|---|---|---|
| `M1_preparar.sql` | Revisa que la base sea v5, crea `sigat_migracion` con el mapa (586 columnas) y el orden de copia. Se detiene si hay columnas que el mapa no conoce | Sí (no toca datos) |
| `M2_instalar_v6.sql` | Renombra `sigat`→`sigat_v5` e instala v6 vacío (una transacción) | Sí (`M_revertir_a_v5`) |
| `M3_copiar_datos.sql` | Copia los datos (una transacción), reajusta los contadores identity | Sí |
| `M4_verificar.sql` | Compara v5 contra v6 columna por columna + las 8 validaciones de `06` | Solo lectura |
| `M5_retirar_legado.sql` | Borra `sigat_v5` y `sigat_migracion`. Pide `-v confirmo=SI` | **No** (haga `pg_dump` antes) |
| `M_revertir_a_v5.sql` | Descarta v6 y devuelve v5 a su nombre. Lo escrito en v6 después de migrar se pierde. Pide `-v confirmo=SI` | — |
| `migrar_todo.sh` | Ejecuta M1→M4 (nunca M5) | — |

## Cómo ejecutarla
```bash
pg_dump -Fc -f respaldo_v5.dump <su_base>          # copia de seguridad ANTES
cd migracion
./migrar_todo.sh "host=... dbname=... user=..."    # M1..M4, se detiene al primer error
# ... revisar pruebas_escritorio/PE_migracion.md ...
psql "host=... dbname=..." -v confirmo=SI -f M5_retirar_legado.sql     # solo cuando acepte
```
Los scripts usan `\ir` para incluir `../sql/*.sql`; ejecútelos desde la carpeta `migracion/`. El usuario debe ser dueño del esquema y poder `CREATE EXTENSION` (el `01` lo hace).

## Qué hace M3 con las reglas de solo inserción
Las tablas append-only (lecturas, visitas, bitácora…) bloquean UPDATE/DELETE. Para copiar el histórico **tal cual** (con su `t_sincronizacion` original, versiones y bitácora) M3 desactiva solo los disparadores de usuario de las 74 tablas durante la copia y los reactiva antes de terminar. Las llaves foráneas, CHECK y EXCLUDE siguen activos: si un dato viejo no cumple una regla de v6, la copia se detiene diciendo cuál y **no se descarta ni se «arregla» nada**. La única tabla que se refiere a sí misma (`operacion_sync.oper_resuelve_oper_id`) se copia en dos pasadas.

## Qué se probó y qué no (importante)
- **Se probó** sobre una réplica de v5 construida así: instalar v6 con los datos de demostración (61 tablas con datos, 207 filas, incluida una referencia hacia adelante en `operacion_sync`) y renombrar todas las columnas a sus nombres v5. Resultado: M1→M4 sin errores, **0 diferencias en las 74 tablas**, las 8 validaciones en 0 filas, los disparadores de solo inserción activos después de migrar, `M_revertir_a_v5` devuelve la réplica v5 intacta, se pudo migrar de nuevo y `M5` retiró el esquema viejo.
- **No se probó** con la base v5 real (no la tengo) ni con volúmenes grandes. Antes de usarla en una base con datos reales: ensáyela sobre una **copia** (`pg_dump | pg_restore` a otra base) y revise `M4`.
- **No se migran** las vistas, funciones ni disparadores de v5: v6 trae los suyos (`03`, `04` y el `01`). Tampoco los permisos (`GRANT`) ni los roles de base de datos: vuelva a aplicarlos sobre el esquema nuevo.
- La aplicación (celular y servidor) debe estar **detenida** entre M2 y el fin de M3, y después debe usar los nombres v6.
- Durante la migración la base ocupa el doble de espacio (v5 + v6) hasta que se ejecute M5.
