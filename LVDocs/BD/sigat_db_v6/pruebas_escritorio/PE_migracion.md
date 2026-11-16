# Prueba de escritorio de la migración v5 → v6

Hágala **con papel y lápiz sobre una copia** antes de aceptar la migración (antes de `M5`). La idea: elegir unas filas, predecir cómo deben verse en v6 usando el mapa de nombres, y comprobarlo en la base.

## 1. Conteo por tabla (lo que M4 hace solo; aquí se hace a mano en dos tablas)
Anote cuántas filas hay en v5 y compare con v6:
```sql
SELECT 'lote' AS tabla, (SELECT count(*) FROM sigat_v5.lote) AS v5, (SELECT count(*) FROM sigat.lote) AS v6
UNION ALL SELECT 'lectura_trampa', (SELECT count(*) FROM sigat_v5.lectura_trampa), (SELECT count(*) FROM sigat.lectura_trampa);
```
**Esperado:** los dos números de cada fila son iguales.

## 2. Seguir una fila con el mapa de nombres
Elija la lectura de trampa más reciente y compárela columna por columna:

| Concepto | Columna v5 | Columna v6 |
|---|---|---|
| Identificador de la lectura | `lec_id` | `lect_id` |
| Registro lógico (versionado) | `lec_registro_id` | `lect_registro_id` |
| Número de especímenes | `lec_especimenes` | `lect_especimenes` |
| Trampa | `tra_id` | `tram_id` |
| Hora observada | `lec_t_observacion` | `lect_t_observacion` |
| Hora de sincronización (la del servidor, NO debe cambiar) | `lec_t_sincronizacion` | `lect_t_sincronizacion` |

```sql
SELECT o.lec_id, o.lec_especimenes, o.lec_t_sincronizacion, n.lect_id, n.lect_especimenes, n.lect_t_sincronizacion
FROM sigat_v5.lectura_trampa o JOIN sigat.lectura_trampa n ON n.lect_id = o.lec_id
ORDER BY o.lec_t_observacion DESC LIMIT 1;
```
**Esperado:** mismos valores; en especial `t_sincronizacion` idéntica (si fuera «ahora», el disparador no se desactivó en la copia y la migración está mal).
*(Si su v5 usa otros nombres exactos, consulte `sigat_migracion.mapa_columnas`.)*

## 3. Columna calculada
El MTD se recalcula en v6 (`indi_valor = moscas / (trampas × días)`). Tome un registro y haga la cuenta a mano:
```sql
SELECT n.indi_moscas, n.indi_trampas, n.indi_dias_exposicion, n.indi_valor,
       round(n.indi_moscas::numeric / (n.indi_trampas * n.indi_dias_exposicion), 6) AS calculo_a_mano
FROM sigat.indice_mtd n LIMIT 3;
```
**Esperado:** `indi_valor` = `calculo_a_mano`. (Con los datos de demostración: 7 / (3 × 7) = 0,333333.)

## 4. Contadores (identity)
```sql
SELECT (SELECT max(lote_id) FROM sigat.lote) AS maximo,
       (SELECT nextval(pg_get_serial_sequence('sigat.lote','lote_id'))) AS siguiente;
```
**Esperado:** `siguiente` = `maximo` + 1. (Si fuera menor, el próximo alta chocaría con un identificador existente.)

## 5. Las reglas siguen vivas
```sql
UPDATE sigat.cosecha SET cose_observaciones = 'x';            -- esperado: ERROR «es de solo inserción»
DELETE FROM sigat.bitacora_auditoria;                         -- esperado: ERROR
```
Si alguno de los dos se ejecuta sin error, los disparadores quedaron desactivados: **no acepte la migración**.

## 6. Reversión
En una **copia** de la base: ejecute `M_revertir_a_v5.sql` con `-v confirmo=SI`. **Esperado:** el esquema `sigat` vuelve a tener las columnas v5 (`administrador.adm_id` existe) y `sigat_v5` desaparece. Luego puede migrar de nuevo.

## 7. Lista de aceptación (marque a mano)
- [ ] `M4` terminó con «0 diferencias» en las 74 tablas.
- [ ] Las 8 consultas de `06_validacion` dieron 0 filas.
- [ ] Pasos 1–5 de este documento coinciden con lo esperado.
- [ ] Probé la reversión en una copia.
- [ ] Tengo un `pg_dump` de la base v5 guardado fuera del servidor.
- [ ] La aplicación ya usa los nombres v6.
- [ ] Recién entonces: `M5_retirar_legado.sql` (irreversible).

## Resultado de la prueba realizada al generar este paquete
Sobre una réplica v5 con los datos de demostración (61 tablas con datos, 207 filas): M1→M4 sin errores; 0 diferencias en 74 tablas; pasos 4 y 5 verificados; reversión y nueva migración correctas; M5 retiró el esquema viejo. **No** se probó con una base v5 real.
