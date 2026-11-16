# Entrega SIGAT v6 — Base de Datos + QGIS

---

## Archivos que recibirán

| Archivo | Para qué sirve |
|---|---|
| `BD/sigat_db_v6/sql/sigat_bd_completa.sql` | Esquema completo (74 tablas, catálogos, vistas y funciones). Es el único archivo necesario para crear la base. |
| `QGis/*.geojson` | Capas del levantamiento: predio, lotes, trampas, celdas, entrada y área de trabajo. |
| `QGis/Manual_QGIS_SIGAT.md` | Explicación paso a paso de la carga y del uso en QGIS. |
| `QGis/importar_geojson.sh` | Carga los `.geojson` en una zona de staging (`sigat_import`). |
| `QGis/importar_geojson.sql` | Pasa el staging a las tablas definitivas usando los IDs reales de la base. |

`sigat_bd_completa.sql` se genera desde los archivos fuente con
`BD/sigat_db_v6/herramientas/generar_consolidado.sh`. No se edita a mano.

---

## Cómo cargarlo en su servidor / local

```bash
# Crear la base (si no existe)
createdb -h <HOST> -p <PUERTO> -U <USUARIO> <BD>

# Cargar todo con un solo archivo
psql -h <HOST> -p <PUERTO> -U <USUARIO> -d <BD> \
  -v ON_ERROR_STOP=1 -f BD/sigat_db_v6/sql/sigat_bd_completa.sql

# Verificar que cargó
psql -h <HOST> -p <PUERTO> -U <USUARIO> -d <BD> \
  -c "SELECT count(*) FROM pg_tables WHERE schemaname = 'sigat';"   # 74
psql -h <HOST> -p <PUERTO> -U <USUARIO> -d <BD> \
  -c "SELECT viewname FROM pg_views WHERE schemaname = 'sigat' AND viewname = 'v_geojson_export';"
```

Si la base ya existe, no ejecutes el archivo completo: aplica solo los `ALTER TABLE`
del apartado 4 del manual.

---

## Qué cambió para trabajar con GeoJSON (QGIS)

Se agregaron 4 columnas `jsonb` + 4 columnas `varchar` en las tablas con geometría,
para guardar el GeoJSON importado sin perder la geometría original:

| Tabla | Columna GeoJSON (`jsonb`) | Fuente (`varchar`) |
|---|---|---|
| `lote_geometria` | `lotg_geojson` | `lotg_geojson_fuente` |
| `predio` | `pred_geojson` | `pred_geojson_fuente` |
| `reticula_celda` | `retc_geojson` | `retc_geojson_fuente` |
| `ubicacion_trampa` | `ubic_geojson` | `ubic_geojson_fuente` |

También se creó la vista `v_geojson_export`, que exporta la geometría vigente del
lote en GeoJSON (`ST_AsGeoJSON(lotg_geom, 6)`) junto con los datos del predio,
cultivo, variedad, municipio y Divipola.

---

## Cómo subir los GeoJSON

La carga tiene dos pasos. No se hace con un `ogr2ogr` directo a las tablas finales
porque `lote_geometria` exige versión, vigencia y llave foránea a `lote`, y porque
`pred_geom`/`lotg_geom` son `MultiPolygon`.

```bash
# 1) Cargar las capas a la zona de staging
export PGHOST=<HOST> PGPORT=<PUERTO> PGDATABASE=<BD> PGUSER=<USUARIO>
./QGis/importar_geojson.sh

# 2) Consultar los IDs reales
psql -c "SELECT lote_id, pred_id, lote_codigo FROM sigat.lote ORDER BY lote_id;"

# 3) Pasar a las tablas definitivas (todos los -v son opcionales)
psql -v pred_id=<ID_PREDIO> -v lote_id=<ID_LOTE> \
     -v reti_id=<ID_RETICULA> -v ubic_id=<ID_UBICACION_TRAMPA> \
     -f QGis/importar_geojson.sql
```

| Archivo | Destino | ¿Se guarda? |
|---|---|---|
| `predio.geojson` | `sigat.predio` | Sí |
| `lotes.geojson` | `sigat.lote_geometria` (nueva versión) | Sí |
| `trampas.geojson` | `sigat.ubicacion_trampa` | Sí |
| `celdas.geojson` | `sigat.reticula_celda` | Sí |
| `entrada.geojson` | `sigat_import.entrada` | No: capa auxiliar de QGIS |
| `area_trabajo.geojson` | `sigat_import.area_trabajo` | No: capa auxiliar de QGIS |

Cada carga de lote crea una versión nueva; no sobrescribe la anterior. Eso conserva
el histórico de geometrías.

---

## Manual de QGIS (`QGis/Manual_QGIS_SIGAT.md`)

El manual explica:

- Cómo conectarse con marcadores genéricos (`<HOST>`, `<PUERTO>`, `<BD>`, `<USUARIO>`),
  sin credenciales escritas en los comandos.
- Cómo cargar la estructura y cómo actualizar una base existente.
- Cómo cargar los `.geojson` a staging y pasarlos a las tablas definitivas.
- Cómo usar `ogr2ogr` de forma genérica **solo hacia staging**.
- Cómo validar geometrías y áreas en QGIS.
- Qué reglas respetar para no perder versiones ni romper las restricciones.
- Cómo regenerar `sigat_bd_completa.sql`.
- Los errores más comunes y su solución.

---

## Resumen: qué entregar

1. `BD/sigat_db_v6/sql/sigat_bd_completa.sql` → creación de la base.
2. `QGis/*.geojson` → capas del levantamiento.
3. `QGis/Manual_QGIS_SIGAT.md` → instrucciones.
4. `QGis/importar_geojson.sh` + `QGis/importar_geojson.sql` → carga de las capas.

No se requiere modificar ninguna otra tabla ni vista para que funcione con QGIS.
