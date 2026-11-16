# Table of Contents {#table-of-contents .TOC-Heading}

# SIGAT · Explicación completa de la base de datos

> Documento generado desde la base real (`herramientas/gen_explicacion.py`), por lo que coincide con `sql/01_esquema_completo.sql`. Contiene **74 tablas**, **21 vistas**, **29 funciones**, **310 índices**.

## 1. Qué es esta base y cómo se lee este documento

SIGAT guarda lo necesario para vigilar la **mosca del Mediterráneo (*Ceratitis capitata*)** en cultivos de durazno para exportación: dónde están los predios y lotes, dónde están las trampas, qué se encontró en cada visita y qué concepto resulta de eso. Está pensada para que el técnico trabaje en el campo **sin Internet** y que todo se sincronice después sin duplicar ni perder nada.

Cómo leer cada tabla: - **Para qué sirve**: la explicación en lenguaje corriente (viene del comentario guardado en la propia base). - **Campos**: cada columna con su tipo y su significado. El prefijo de 3 letras (por ejemplo `lec_` en lectura_trampa) evita confundir columnas entre tablas. - **Se relaciona con**: las tablas a las que apunta (llaves foráneas). - **Reglas que la base exige**: restricciones que impiden guardar datos incoherentes. - **Disparadores**: reglas automáticas que se ejecutan al insertar o modificar.

Ideas que se repiten en todo el diseño: 1. **Identificadores**: las listas y entidades «maestras» usan números enteros; los registros que nacen en el celular usan **UUID** (un código único generado en el dispositivo) para poder crearse sin conexión y reenviarse sin duplicarse. 2. **Versionado**: lecturas, aplicaciones, cosechas, etc. no se editan. Corregir = agregar una versión nueva; la anterior queda como historia (solo inserción). 3. **Tres relojes**: *observación* (cuándo ocurrió, lo declara el técnico), *captura* (cuándo se guardó en el celular) y *sincronización* (cuándo llegó al servidor, reloj del servidor, no se puede alterar). 4. **Unidades explícitas**: ningún número va suelto; las columnas indican su unidad (`[ud: ha]`, `[ud: kg]`...). 5. **Nada inventado**: valores que el ICA aún no ha definido (umbral de exportación del MTD, nombres de algunas fenologías, etc.) quedan **vacíos** y se listan como pendientes institucionales. 6. **Los binarios no van en la base**: las fotos y documentos se guardan en un almacén de objetos; la base guarda su registro, hash y referencia. 7. **Calculado en el servidor**: el MTD, el escenario y el concepto los calcula el servidor; la aplicación solo los muestra.

## 2. Mapa de áreas

  ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Área                                                                                       Tablas
  ------------------------------------------------------------------------------------------ ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  1\. Catálogos generales y geográficos                                                      `region`, `departamento`, `municipio`, `rango_departamento`, `centro_acopio`, `estado_registro`, `rol`, `tipo_trampa`, `atrayente`, `especie_cultivo`, `variedad_cultivo`, `fenologia`, `especie_mosca`, `arbol`, `localizacion`, `vigilancia`, `unidad_medida`, `norma`, `escenario_trampeo`, `condicion_trampa`, `producto_fitosanitario`

  2\. Personas, usuarios, roles y permisos                                                   `persona`, `administrador`, `tecnico`, `productor`, `ruta`, `usuario`, `permiso`, `rol_permiso`

  3\. Predios, lotes, retícula y programa de inspección                                      `predio`, `lote`, `lote_geometria`, `reticula`, `reticula_celda`, `usuario_predio`, `programa_inspeccion`, `programa_umbral`, `fenologia_regla`, `paquete_campo`

  4\. Trampas y ubicaciones                                                                  `trampa`, `ubicacion_trampa`

  5\. Sincronización offline y auditoría                                                     `dispositivo`, `operacion_sync`, `recepcion_sync`, `bitacora_auditoria`

  6\. Registros de campo (visitas, lecturas, aplicaciones, cosecha, fenología)               `visita`, `visita_lote`, `lectura_trampa`, `aplicacion_fitosanitaria`, `cosecha`, `etapa_declarada`

  7\. MTD, periodos y concepto de aptitud                                                    `periodo_trampeo`, `indice_mtd`, `indice_mtd_lectura`, `concepto_aptitud`

  8\. Fase 2: plagas, hallazgos, BPA, producción, manejo                                     `plaga_enfermedad`, `severidad`, `hallazgo`, `criterio_bpa`, `programa_criterio_bpa`, `bpa_verificacion`, `estimacion_produccion`, `tipo_manejo`, `manejo_agronomico`

  9\. Archivos e imágenes, planificación, notificaciones y perfil (extensión del frontend)   `archivo_adjunto`, `evidencia`, `imagen_diseno`, `categoria_notificacion`, `perfil_usuario`, `preferencia_notificacion`, `notificacion`, `planificacion`, `planificacion_lote`, `restablecimiento_clave`
  ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## 3. Catálogos generales y geográficos

Son las listas de valores que usa todo lo demás: dónde queda cada cosa (región, departamento, municipio), qué tipos de trampa, atrayente, cultivo, etapa fenológica y especie de mosca existen, y las unidades de medida. Se cargan una vez (la mayoría desde los formatos oficiales del ICA) y casi no cambian. Sirven para que nadie escriba el mismo dato de dos maneras distintas.

### `region`

**Para qué sirve.** Región geográfica agrupadora de departamentos (catálogo conservado).

  ---------------------------------------------------------------------------------------------------------------------
  Campo               Tipo              Obligatorio       Significado
  ------------------- ----------------- ----------------- -------------------------------------------------------------
  `reg_id`            entero            sí                Identificador del registro (clave primaria).

  `reg_descripcion`   texto             sí                Texto descriptivo del valor del catálogo (único, no vacío).
  ---------------------------------------------------------------------------------------------------------------------

**Identificación.** Clave primaria: `reg_id`.

**No se puede repetir:** (`reg_descripcion`).

**Reglas que la base exige:** - `region_descripcion_no_vacia`: `((btrim((reg_descripcion)::text) <> ''::text))`

### `departamento`

**Para qué sirve.** Departamento. dep_codigo = código DANE de 2 dígitos (parte inicial del Divipola, RN-005). Nulo hasta cargar la fuente DANE.

  -------------------------------------------------------------------------------------------------------------------------------
  Campo               Tipo              Obligatorio       Significado
  ------------------- ----------------- ----------------- -----------------------------------------------------------------------
  `dep_id`            entero            sí                Identificador del registro (clave primaria).

  `dep_descripcion`   texto             sí                Texto descriptivo del valor del catálogo (único, no vacío).

  `reg_id`            entero            sí                Referencia a region(reg_id).

  `dep_codigo`        character(2)      no                Código DANE del departamento (2 dígitos). Fuente a cargar desde DANE.
  -------------------------------------------------------------------------------------------------------------------------------

**Identificación.** Clave primaria: `dep_id`.

**Se relaciona con:** `reg_id` → `region`.

**No se puede repetir:** (`dep_codigo`); (`dep_descripcion`).

**Reglas que la base exige:** - `departamento_codigo_formato`: `((dep_codigo ~ '^[0-9]{2}$'::text))` - `departamento_descripcion_no_vacia`: `((btrim((dep_descripcion)::text) <> ''::text))`

### `municipio`

**Para qué sirve.** Municipio. mun_codigo = parte municipal (3 dígitos) del código DANE; el Divipola de 5 dígitos se obtiene con la vista v_municipio_divipola (no se almacena redundante: 3FN).

  ------------------------------------------------------------------------------------------------------------------------
  Campo               Tipo              Obligatorio       Significado
  ------------------- ----------------- ----------------- ----------------------------------------------------------------
  `mun_id`            entero            sí                Identificador del registro (clave primaria).

  `mun_descripcion`   texto             sí                Texto descriptivo del valor del catálogo (único, no vacío).

  `dep_id`            entero            sí                Referencia a departamento(dep_id).

  `mun_codigo`        character(3)      no                Código DANE del municipio dentro del departamento (3 dígitos).
  ------------------------------------------------------------------------------------------------------------------------

**Identificación.** Clave primaria: `mun_id`.

**Se relaciona con:** `dep_id` → `departamento`.

**No se puede repetir:** (`dep_id, mun_codigo`).

**Reglas que la base exige:** - `municipio_codigo_formato`: `((mun_codigo ~ '^[0-9]{3}$'::text))` - `municipio_descripcion_no_vacia`: `((btrim((mun_descripcion)::text) <> ''::text))`

### `rango_departamento`

**Para qué sirve.** Caja envolvente (WGS84, grados) de cada departamento; se usa para validar que las coordenadas de una trampa caen en el departamento del predio. Relación 1:1 con departamento.

  -------------------------------------------------------------------------------------------------------------------
  Campo             Tipo              Obligatorio       Significado
  ----------------- ----------------- ----------------- -------------------------------------------------------------
  `dep_id`          entero            sí                Referencia a departamento(dep_id).

  `rgd_long_min`    decimal           sí                \[ud: grados\] Longitud mínima de la caja del departamento.

  `rgd_long_max`    decimal           sí                \[ud: grados\] Longitud máxima de la caja del departamento.

  `rgd_lat_min`     decimal           sí                \[ud: grados\] Latitud mínima de la caja del departamento.

  `rgd_lat_max`     decimal           sí                \[ud: grados\] Latitud máxima de la caja del departamento.
  -------------------------------------------------------------------------------------------------------------------

**Identificación.** Clave primaria: `dep_id`.

**Se relaciona con:** `dep_id` → `departamento`.

**Reglas que la base exige:** - `rango_departamento_latitud_valida`: `(((rgd_lat_min < rgd_lat_max) AND (rgd_lat_min >= ('-90'::integer)::double precision) AND (rgd_lat_max <= (90)::double precision)))` - `rango_departamento_longitud_valida`: `(((rgd_long_min < rgd_long_max) AND (rgd_long_min >= ('-180'::integer)::double precision) AND (rgd_long_max <= (180)::double precision)))`

### `centro_acopio`

**Para qué sirve.** Centro de acopio

  ---------------------------------------------------------------------------------------------------------------------
  Campo               Tipo              Obligatorio       Significado
  ------------------- ----------------- ----------------- -------------------------------------------------------------
  `cac_id`            entero            sí                Identificador del registro (clave primaria).

  `cac_descripcion`   texto             sí                Texto descriptivo del valor del catálogo (único, no vacío).

  `dep_id`            entero            sí                Referencia a departamento(dep_id).
  ---------------------------------------------------------------------------------------------------------------------

**Identificación.** Clave primaria: `cac_id`.

**Se relaciona con:** `dep_id` → `departamento`.

**No se puede repetir:** (`cac_descripcion`).

**Reglas que la base exige:** - `centro_acopio_descripcion_no_vacia`: `((btrim((cac_descripcion)::text) <> ''::text))`

### `estado_registro`

**Para qué sirve.** Estado de vigencia de un registro maestro (activo/inactivo) usado por usuarios, técnicos, rutas y trampas. Se conserva por compatibilidad; ver informe de normalización (catálogo genérico compartido).

  ---------------------------------------------------------------------------------------------------------------------
  Campo               Tipo              Obligatorio       Significado
  ------------------- ----------------- ----------------- -------------------------------------------------------------
  `est_id`            entero            sí                Identificador del registro (clave primaria).

  `est_descripcion`   texto             sí                Texto descriptivo del valor del catálogo (único, no vacío).
  ---------------------------------------------------------------------------------------------------------------------

**Identificación.** Clave primaria: `est_id`.

**No se puede repetir:** (`est_descripcion`).

**Reglas que la base exige:** - `estado_registro_descripcion_no_vacia`: `((btrim((est_descripcion)::text) <> ''::text))`

### `rol`

**Para qué sirve.** Rol del sistema. Decisión confirmada: solo 4 roles (ADMINISTRADOR, AGRONOMO_SUPERVISOR, TECNICO, PRODUCTOR). rol_ambito: global = rige en todo el sistema (Administrador); predio = rige sobre los predios asignados en usuario_predio (RF-002).

  ----------------------------------------------------------------------------------------------------------------------------------------
  Campo               Tipo              Obligatorio       Significado
  ------------------- ----------------- ----------------- --------------------------------------------------------------------------------
  `rol_id`            entero            sí                Identificador del registro (clave primaria).

  `rol_descripcion`   texto             sí                Texto descriptivo del valor del catálogo (único, no vacío).

  `rol_codigo`        texto             no                Código estable del rol para el código de aplicación (MAYÚSCULAS_Y_GUION_BAJO).

  `rol_ambito`        texto             sí                global (rige en todo el sistema) o predio (rige sobre los predios asignados).
  ----------------------------------------------------------------------------------------------------------------------------------------

**Identificación.** Clave primaria: `rol_id`.

**No se puede repetir:** (`rol_codigo`); (`rol_descripcion`).

**Reglas que la base exige:** - `rol_ambito_valido`: `(((rol_ambito)::text = ANY ((ARRAY['global'::character varying, 'predio'::character varying])::text[])))` - `rol_codigo_formato`: `(((rol_codigo)::text ~ '^[A-Z_]+$'::text))` - `rol_descripcion_no_vacia`: `((btrim((rol_descripcion)::text) <> ''::text))`

### `tipo_trampa`

**Para qué sirve.** Tipo de trampa (Jackson, McPhail). tit_paridad: paridad exigida al número de trampa (RN-005: Jackson impar, McPhail par).

  -----------------------------------------------------------------------------------------------------------------------------------------------
  Campo               Tipo              Obligatorio       Significado
  ------------------- ----------------- ----------------- ---------------------------------------------------------------------------------------
  `tit_id`            entero            sí                Identificador del registro (clave primaria).

  `tit_descripcion`   texto             sí                Texto descriptivo del valor del catálogo (único, no vacío).

  `tit_paridad`       texto             no                impar o par: paridad que debe cumplir el número de trampa (RN-005). Nulo = sin regla.
  -----------------------------------------------------------------------------------------------------------------------------------------------

**Identificación.** Clave primaria: `tit_id`.

**No se puede repetir:** (`tit_descripcion`).

**Reglas que la base exige:** - `tipo_trampa_descripcion_no_vacia`: `((btrim((tit_descripcion)::text) <> ''::text))` - `tipo_trampa_paridad_valida`: `(((tit_paridad)::text = ANY ((ARRAY['impar'::character varying, 'par'::character varying])::text[])))`

### `atrayente`

**Para qué sirve.** Atrayente. Vida útil de campo en semanas (RN-008: plug 4--6; proteico hidrolizado 1--2).

  ---------------------------------------------------------------------------------------------------------------------------------
  Campo                     Tipo              Obligatorio       Significado
  ------------------------- ----------------- ----------------- -------------------------------------------------------------------
  `atr_id`                  entero            sí                Identificador del registro (clave primaria).

  `atr_descripcion`         texto             sí                Texto descriptivo del valor del catálogo (único, no vacío).

  `atr_vida_util_min_sem`   entero corto      no                \[ud: semanas\] Vida útil mínima de campo del atrayente (RN-008).

  `atr_vida_util_max_sem`   entero corto      no                \[ud: semanas\] Vida útil máxima de campo del atrayente (RN-008).
  ---------------------------------------------------------------------------------------------------------------------------------

**Identificación.** Clave primaria: `atr_id`.

**No se puede repetir:** (`atr_descripcion`).

**Reglas que la base exige:** - `atrayente_descripcion_no_vacia`: `((btrim((atr_descripcion)::text) <> ''::text))` - `atrayente_vida_util_valida`: `((((atr_vida_util_min_sem IS NULL) = (atr_vida_util_max_sem IS NULL)) AND ((atr_vida_util_min_sem IS NULL) OR ((atr_vida_util_min_sem > 0) AND (atr_vida_util_min_sem <= atr_vida_util_max_sem)))))`

### `especie_cultivo`

**Para qué sirve.** Especie de cultivo (durazno). Hoy no estaba referenciada; se enlaza con lote y variedad.

  ---------------------------------------------------------------------------------------------------------------------
  Campo               Tipo              Obligatorio       Significado
  ------------------- ----------------- ----------------- -------------------------------------------------------------
  `esc_id`            entero            sí                Identificador del registro (clave primaria).

  `esc_descripcion`   texto             sí                Texto descriptivo del valor del catálogo (único, no vacío).
  ---------------------------------------------------------------------------------------------------------------------

**Identificación.** Clave primaria: `esc_id`.

**No se puede repetir:** (`esc_descripcion`).

**Reglas que la base exige:** - `especie_cultivo_descripcion_no_vacia`: `((btrim((esc_descripcion)::text) <> ''::text))`

### `variedad_cultivo`

**Para qué sirve.** Variedad de una especie de cultivo (RDD-002). Sin valores oficiales en la documentación: se carga por el Administrador (RF-081).

  ---------------------------------------------------------------------------------------------------------------------
  Campo               Tipo              Obligatorio       Significado
  ------------------- ----------------- ----------------- -------------------------------------------------------------
  `var_id`            entero            sí                Identificador del registro (clave primaria).

  `esc_id`            entero            sí                Referencia a especie_cultivo(esc_id).

  `var_descripcion`   texto             sí                Texto descriptivo del valor del catálogo (único, no vacío).
  ---------------------------------------------------------------------------------------------------------------------

**Identificación.** Clave primaria: `var_id`.

**Se relaciona con:** `esc_id` → `especie_cultivo`.

**No se puede repetir:** (`esc_id, var_descripcion`); (`esc_id, var_id`).

**Reglas que la base exige:** - `variedad_cultivo_descripcion_no_vacia`: `((btrim((var_descripcion)::text) <> ''::text))`

### `fenologia`

**Para qué sirve.** Catálogo de etapas fenológicas. Las reglas que derivan la etapa por fecha están en fenologia_regla (RN-012).

  --------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Campo               Tipo              Obligatorio       Significado
  ------------------- ----------------- ----------------- ------------------------------------------------------------------------------------------------------------------
  `fen_id`            entero            sí                Identificador del registro (clave primaria).

  `fen_descripcion`   texto             sí                Texto descriptivo del valor del catálogo (único, no vacío).

  `fen_codigo_ica`    entero corto      no                Código numérico de la etapa fenológica en el formato oficial del ICA (nulo si la etapa no existe en el formato).
  --------------------------------------------------------------------------------------------------------------------------------------------------------------------------

**Identificación.** Clave primaria: `fen_id`.

**No se puede repetir:** (`fen_codigo_ica`); (`fen_descripcion`).

**Reglas que la base exige:** - `fenologia_descripcion_no_vacia`: `((btrim((fen_descripcion)::text) <> ''::text))`

### `especie_mosca`

**Para qué sirve.** Resultado de determinación taxonómica de mosca de la fruta (RN-015). Catálogo con los códigos del formato MF_CAP del ICA (esm_codigo_ica). esm_tipo distingue especie, género sin especie (p. ej. Anastrepha sp.) y los resultados especiales «No captura» y «No Tephritidae», que el ICA registra en el mismo catálogo pero no son especies.

  -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Campo               Tipo              Obligatorio       Significado
  ------------------- ----------------- ----------------- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  `esm_id`            entero            sí                Identificador del registro (clave primaria).

  `esm_descripcion`   texto             sí                Texto descriptivo del valor del catálogo (único, no vacío).

  `esm_codigo_ica`    entero corto      no                Código numérico del catálogo del formato MF_CAP del ICA (1 = Ceratitis capitata, 51 = No captura, 54 = No Tephritidae, 56 = Anastrepha sp.). Nulo para especies agregadas localmente.

  `esm_tipo`          texto             sí                Naturaleza del resultado de determinación: especie, genero_sin_especie, sin_captura o no_tephritidae (códigos del formato MF_CAP del ICA).
  -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

**Identificación.** Clave primaria: `esm_id`.

**No se puede repetir:** (`esm_codigo_ica`); (`esm_descripcion`).

**Reglas que la base exige:** - `especie_mosca_codigo_ica_positivo`: `(((esm_codigo_ica IS NULL) OR (esm_codigo_ica > 0)))` - `especie_mosca_descripcion_no_vacia`: `((btrim((esm_descripcion)::text) <> ''::text))` - `especie_mosca_tipo_valido`: `(((esm_tipo)::text = ANY ((ARRAY['especie'::character varying, 'genero_sin_especie'::character varying, 'sin_captura'::character varying, 'no_tephritidae'::character varying])::text[])))`

### `arbol`

**Para qué sirve.** Árbol/especie hospedera donde se cuelga la trampa (campo del registro de ubicación).

  ---------------------------------------------------------------------------------------------------------------------
  Campo               Tipo              Obligatorio       Significado
  ------------------- ----------------- ----------------- -------------------------------------------------------------
  `arb_id`            entero            sí                Identificador del registro (clave primaria).

  `arb_descripcion`   texto             sí                Texto descriptivo del valor del catálogo (único, no vacío).
  ---------------------------------------------------------------------------------------------------------------------

**Identificación.** Clave primaria: `arb_id`.

**No se puede repetir:** (`arb_descripcion`).

**Reglas que la base exige:** - `arbol_descripcion_no_vacia`: `((btrim((arb_descripcion)::text) <> ''::text))`

### `localizacion`

**Para qué sirve.** Localización de la trampa dentro del árbol/sitio (campo del registro de ubicación).

  -----------------------------------------------------------------------------------------------------------------------------------------------
  Campo               Tipo              Obligatorio       Significado
  ------------------- ----------------- ----------------- ---------------------------------------------------------------------------------------
  `loc_id`            entero            sí                Identificador del registro (clave primaria).

  `loc_descripcion`   texto             sí                Texto descriptivo del valor del catálogo (único, no vacío).

  `loc_codigo_ica`    entero corto      no                Código numérico de la localización de la trampa en el formato oficial MF_UBI del ICA.
  -----------------------------------------------------------------------------------------------------------------------------------------------

**Identificación.** Clave primaria: `loc_id`.

**No se puede repetir:** (`loc_codigo_ica`); (`loc_descripcion`).

**Reglas que la base exige:** - `localizacion_descripcion_no_vacia`: `((btrim((loc_descripcion)::text) <> ''::text))`

### `vigilancia`

**Para qué sirve.** Tipo de vigilancia/muestreo (RN-007: la cadencia depende del tipo de vigilancia; RN-011: el solapamiento se evalúa por lote y tipo de muestreo).

  --------------------------------------------------------------------------------------------------------------------------------------
  Campo               Tipo              Obligatorio       Significado
  ------------------- ----------------- ----------------- ------------------------------------------------------------------------------
  `vig_id`            entero            sí                Identificador del registro (clave primaria).

  `vig_descripcion`   texto             sí                Texto descriptivo del valor del catálogo (único, no vacío).

  `vig_codigo_ica`    entero corto      no                Código numérico del tipo de vigilancia en el formato oficial MF_UBI del ICA.
  --------------------------------------------------------------------------------------------------------------------------------------

**Identificación.** Clave primaria: `vig_id`.

**No se puede repetir:** (`vig_codigo_ica`); (`vig_descripcion`).

**Reglas que la base exige:** - `vigilancia_descripcion_no_vacia`: `((btrim((vig_descripcion)::text) <> ''::text))`

### `unidad_medida`

**Para qué sirve.** RN-017: toda magnitud se almacena con su unidad. Catálogo de unidades (símbolos SI/UCUM).

  ----------------------------------------------------------------------------------------------------------------
  Campo             Tipo              Obligatorio       Significado
  ----------------- ----------------- ----------------- ----------------------------------------------------------
  `uni_id`          entero            sí                Identificador del registro (clave primaria).

  `uni_simbolo`     texto             sí                Símbolo de la unidad (único), p. ej. kg, ha, mL/L.

  `uni_nombre`      texto             sí                Nombre de la unidad.

  `uni_magnitud`    texto             sí                Magnitud: masa, area, volumen, longitud o concentracion.
  ----------------------------------------------------------------------------------------------------------------

**Identificación.** Clave primaria: `uni_id`.

**No se puede repetir:** (`uni_simbolo`).

**Reglas que la base exige:** - `unidad_medida_magnitud_valida`: `(((uni_magnitud)::text = ANY ((ARRAY['masa'::character varying, 'area'::character varying, 'volumen'::character varying, 'longitud'::character varying, 'concentracion'::character varying])::text[])))` - `unidad_medida_nombre_no_vacio`: `(((btrim((uni_nombre)::text) <> ''::text) AND (btrim((uni_simbolo)::text) <> ''::text)))`

### `norma`

**Para qué sirve.** Norma que sustenta un umbral o un concepto de aptitud (RDD-007, RF-024). nor_texto_disponible=false: el equipo aún no dispone del texto (UQQ-004).

  -----------------------------------------------------------------------------------------------------------------------
  Campo                    Tipo              Obligatorio       Significado
  ------------------------ ----------------- ----------------- ----------------------------------------------------------
  `nor_id`                 entero            sí                Identificador del registro (clave primaria).

  `nor_codigo`             texto             sí                Identificador corto único de la norma.

  `nor_titulo`             texto             sí                Título completo de la norma.

  `nor_emisor`             texto             sí                Entidad que expide la norma.

  `nor_anio`               entero corto      no                Año de expedición de la norma.

  `nor_texto_disponible`   sí/no             sí                Falso si el equipo aún no dispone del texto de la norma.
  -----------------------------------------------------------------------------------------------------------------------

**Identificación.** Clave primaria: `nor_id`.

**No se puede repetir:** (`nor_codigo`).

**Reglas que la base exige:** - `norma_anio_valido`: `(((nor_anio >= 1900) AND (nor_anio <= 2200)))` - `norma_textos_no_vacios`: `(((btrim((nor_codigo)::text) <> ''::text) AND (btrim((nor_titulo)::text) <> ''::text) AND (btrim((nor_emisor)::text) <> ''::text)))`

### `escenario_trampeo`

**Para qué sirve.** RN-002: escenarios de trampeo (Tabla 1, OIEA 2005). Los límites por defecto son referencia; el valor aplicable se configura por predio en programa_umbral. NO es el umbral de exportación (UQQ-004).

  ---------------------------------------------------------------------------------------------------------------------------------------------------------------
  Campo                     Tipo              Obligatorio       Significado
  ------------------------- ----------------- ----------------- -------------------------------------------------------------------------------------------------
  `esq_id`                  entero            sí                Identificador del registro (clave primaria).

  `esq_descripcion`         texto             sí                Texto descriptivo del valor del catálogo (único, no vacío).

  `esq_orden`               entero corto      sí                Orden de presentación (de mayor a menor gravedad).

  `esq_mtd_desde_defecto`   número(10,4)      no                \[ud: moscas/trampa/día\] Límite inferior de referencia del escenario.

  `esq_mtd_hasta_defecto`   número(10,4)      no                \[ud: moscas/trampa/día\] Límite superior de referencia; nulo = sin límite superior.

  `esq_fuente`              texto             no                Fuente documental de los límites por defecto (p. ej. Levantamiento RN-002, Tabla 1, OIEA 2005).
  ---------------------------------------------------------------------------------------------------------------------------------------------------------------

**Identificación.** Clave primaria: `esq_id`.

**No se puede repetir:** (`esq_descripcion`); (`esq_orden`).

**Reglas que la base exige:** - `escenario_trampeo_descripcion_no_vacia`: `((btrim((esq_descripcion)::text) <> ''::text))` - `escenario_trampeo_rango_defecto_valido`: `((((esq_mtd_desde_defecto IS NULL) OR (esq_mtd_desde_defecto >= (0)::numeric)) AND ((esq_mtd_hasta_defecto IS NULL) OR (esq_mtd_hasta_defecto >= (0)::numeric)) AND ((esq_mtd_desde_defecto IS NULL) OR (esq_mtd_hasta_defecto IS NULL`

### `condicion_trampa`

**Para qué sirve.** RDD-005: estado físico de la trampa en la lectura. Los valores no vienen del Manual (no disponible); se proponen desde el frontend en el archivo de catálogos propuestos.

  -------------------------------------------------------------------------------------------------------------------------
  Campo               Tipo              Obligatorio       Significado
  ------------------- ----------------- ----------------- -----------------------------------------------------------------
  `con_id`            entero            sí                Identificador del registro (clave primaria).

  `con_descripcion`   texto             sí                Texto descriptivo del valor del catálogo (único, no vacío).

  `con_activa`        sí/no             sí                Falso = valor retirado del catálogo (se conserva por historia).
  -------------------------------------------------------------------------------------------------------------------------

**Identificación.** Clave primaria: `con_id`.

**No se puede repetir:** (`con_descripcion`).

**Reglas que la base exige:** - `condicion_trampa_descripcion_no_vacia`: `((btrim((con_descripcion)::text) <> ''::text))`

### `producto_fitosanitario`

**Para qué sirve.** Catálogo de productos fitosanitarios (RF-081). Sin valores oficiales en la documentación; lo administra el rol Administrador.

  -----------------------------------------------------------------------------------------------------------------------
  Campo                      Tipo              Obligatorio       Significado
  -------------------------- ----------------- ----------------- --------------------------------------------------------
  `pfs_id`                   entero            sí                Identificador del registro (clave primaria).

  `pfs_nombre`               texto             sí                Nombre comercial (único).

  `pfs_ingrediente_activo`   texto             no                Ingrediente activo (opcional).

  `pfs_registro_ica`         texto             no                Número de registro ICA del producto (opcional, único).

  `pfs_activo`               sí/no             sí                Falso = producto retirado del catálogo.
  -----------------------------------------------------------------------------------------------------------------------

**Identificación.** Clave primaria: `pfs_id`.

**No se puede repetir:** (`pfs_nombre`); (`pfs_registro_ica`).

**Reglas que la base exige:** - `producto_fitosanitario_nombre_no_vacio`: `((btrim((pfs_nombre)::text) <> ''::text))`

## 4. Personas, usuarios, roles y permisos

Quién es quién. Una **persona** es el ser humano (cédula, nombre, contacto). Sobre la persona se apoyan sus papeles ---administrador, técnico, productor--- y su **usuario** para ingresar al sistema. Cada usuario tiene uno de los 4 roles confirmados (Administrador, Agrónomo/Supervisor, Técnico, Productor) y, según el rol, ve solo los predios que le corresponden.

### `persona`

**Para qué sirve.** Persona natural (administrador, técnico, agrónomo o productor). per_cc = número de identificación sin dígito de verificación ni separadores (se conserva el nombre por compatibilidad). Datos personales: RNF-014 / Ley 1581 de 2012.

  ---------------------------------------------------------------------------------------------------------------------------------------------------
  Campo             Tipo              Obligatorio       Significado
  ----------------- ----------------- ----------------- ---------------------------------------------------------------------------------------------
  `per_cc`          entero largo      sí                Identificador del registro (clave primaria).

  `per_nombre`      texto             sí                Nombres o razón social.

  `per_apellido`    texto             sí                Apellidos o razón social complementaria.

  `per_telefono`    texto             no                Teléfono: solo dígitos, con + opcional (tipo texto: antes numeric perdía ceros y prefijos).

  `per_direccion`   texto             no                Dirección de contacto (opcional; dato personal).

  `per_correo`      texto             no                Correo electrónico (opcional, único sin distinguir mayúsculas).
  ---------------------------------------------------------------------------------------------------------------------------------------------------

**Identificación.** Clave primaria: `per_cc`.

**Reglas que la base exige:** - `persona_correo_formato`: `(((per_correo)::text ~ '^[^@\s]+@[^@\s]+\.[^@\s]+$'::text))` - `persona_nombre_no_vacio`: `(((btrim((per_nombre)::text) <> ''::text) AND (btrim((per_apellido)::text) <> ''::text)))` - `persona_per_cc_positivo`: `((per_cc > 0))` - `persona_telefono_formato`: `(((per_telefono)::text ~ '^\+?[0-9]{7,15}$'::text))`

**Disparadores:** `trg_aud_persona (fn_auditar)`.

### `administrador`

**Para qué sirve.** Especialización 1:1 de persona: administrador asociado a un centro de acopio. La obligatoriedad del centro de acopio queda como pendiente institucional.

  ----------------------------------------------------------------------------------------------------
  Campo             Tipo              Obligatorio       Significado
  ----------------- ----------------- ----------------- ----------------------------------------------
  `adm_id`          entero            sí                Identificador del registro (clave primaria).

  `per_cc`          entero largo      sí                Referencia a persona(per_cc).

  `cac_id`          entero            sí                Referencia a centro_acopio(cac_id).
  ----------------------------------------------------------------------------------------------------

**Identificación.** Clave primaria: `adm_id`.

**Se relaciona con:** `cac_id` → `centro_acopio`; `per_cc` → `persona`.

**No se puede repetir:** (`per_cc`).

**Disparadores:** `trg_aud_administrador (fn_auditar)`.

### `tecnico`

**Para qué sirve.** Especialización 1:1 de persona: técnico de campo (inspector). adm_id = administrador que lo registró.

  ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Campo                       Tipo              Obligatorio       Significado
  --------------------------- ----------------- ----------------- -----------------------------------------------------------------------------------------------------------------------------------
  `tec_id`                    entero            sí                Identificador del registro (clave primaria).

  `per_cc`                    entero largo      sí                Referencia a persona(per_cc).

  `cac_id`                    entero            sí                Referencia a centro_acopio(cac_id).

  `tec_codigo_ica`            texto             no                Código de recolector del ICA (hoja de recolectores de MF_CAP): Divipola (5 dígitos) + consecutivo de 3 dígitos. Nulo si no tiene.

  `adm_id`                    entero            sí                Referencia a administrador(adm_id).

  `tec_fecha_registro`        fecha             sí                Fecha de registro del técnico.

  `tec_fecha_actualizacion`   fecha             no                Fecha de la última actualización.

  `est_id`                    entero            sí                Referencia a estado_registro(est_id).
  ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

**Identificación.** Clave primaria: `tec_id`.

**Se relaciona con:** `adm_id` → `administrador`; `cac_id` → `centro_acopio`; `est_id` → `estado_registro`; `per_cc` → `persona`.

**No se puede repetir:** (`tec_codigo_ica`); (`per_cc`).

**Reglas que la base exige:** - `tecnico_codigo_ica_formato`: `(((tec_codigo_ica)::text ~ '^[0-9]{1,12}$'::text))` - `tecnico_fechas_validas`: `(((tec_fecha_actualizacion IS NULL) OR (tec_fecha_actualizacion >= tec_fecha_registro)))`

**Disparadores:** `trg_aud_tecnico (fn_auditar)`.

### `productor`

**Para qué sirve.** Especialización 1:1 de persona: productor (propietario/responsable de predios). mun_id = municipio de residencia/domicilio del productor.

  ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Campo                             Tipo              Obligatorio       Significado
  --------------------------------- ----------------- ----------------- --------------------------------------------------------------------------------------------------
  `per_cc`                          entero largo      sí                Referencia a persona(per_cc).

  `prod_fecha_registro`             fecha             sí                Fecha de registro del productor.

  `prod_fecha_actualizacion`        fecha             no                Fecha de la última actualización.

  `prod_tecnico_registro_id`        entero            sí                Identificador lógico del registro: igual en todas sus versiones (el cliente lo genera, UUID v7).

  `prod_tecnico_actualizacion_id`   entero            no                Referencia a tecnico(tec_id).

  `prod_activo`                     sí/no             sí                Verdadero = productor activo.

  `mun_id`                          entero            sí                Referencia a municipio(mun_id).
  ------------------------------------------------------------------------------------------------------------------------------------------------------------------------

**Identificación.** Clave primaria: `per_cc`.

**Se relaciona con:** `mun_id` → `municipio`; `per_cc` → `persona`; `prod_tecnico_actualizacion_id` → `tecnico`; `prod_tecnico_registro_id` → `tecnico`.

**Reglas que la base exige:** - `productor_fechas_validas`: `(((prod_fecha_actualizacion IS NULL) OR (prod_fecha_actualizacion >= prod_fecha_registro)))`

**Disparadores:** `trg_aud_productor (fn_auditar)`.

### `ruta`

**Para qué sirve.** Ruta de inspección de un centro de acopio. rut_codigo = registro de la ruta (formato MF_UBI «Registro de la ruta», p. ej. 602) que forma parte del código de trampa (RN-005); antes residía en ubicacion_trampa.cod_ruta. El «Código Ruta» de 9 dígitos del ICA = Divipola del municipio (5) + registro con 4 dígitos (ver v_ruta_codigo_ica).

  --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Campo                          Tipo              Obligatorio       Significado
  ------------------------------ ----------------- ----------------- -------------------------------------------------------------------------------------------------------------------------
  `rut_id`                       entero            sí                Identificador del registro (clave primaria).

  `rut_nombre`                   texto             sí                Nombre de la ruta (único).

  `cac_id`                       entero            sí                Referencia a centro_acopio(cac_id).

  `mun_id`                       entero            no                Municipio al que pertenece la ruta (aporta los 5 dígitos Divipola del Código Ruta del ICA). Nulo hasta confirmarlo.

  `rut_descripcion`              texto             sí                Descripción libre de la ruta (no es única; el identificador de negocio es el nombre rut_nombre y (cac_id, rut_codigo)).

  `rut_codigo`                   texto             no                Código ICA de la ruta (alfanumérico, hasta 10); único dentro del centro de acopio.

  `rut_fecha_registro`           fecha             sí                Fecha de registro de la ruta.

  `rut_fecha_actualizacion`      fecha             no                Fecha de la última actualización.

  `rut_admin_registro_id`        entero            sí                Identificador lógico del registro: igual en todas sus versiones (el cliente lo genera, UUID v7).

  `rut_admin_actualizacion_id`   entero            no                Referencia a administrador(adm_id).

  `est_id`                       entero            sí                Referencia a estado_registro(est_id).
  --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

**Identificación.** Clave primaria: `rut_id`.

**Se relaciona con:** `cac_id` → `centro_acopio`; `est_id` → `estado_registro`; `mun_id` → `municipio`; `rut_admin_actualizacion_id` → `administrador`; `rut_admin_registro_id` → `administrador`.

**No se puede repetir:** (`cac_id, rut_codigo`); (`rut_nombre`).

**Reglas que la base exige:** - `ruta_codigo_formato`: `(((rut_codigo)::text ~ '^[0-9A-Za-z]{1,10}$'::text))` - `ruta_fechas_validas`: `(((rut_fecha_actualizacion IS NULL) OR (rut_fecha_actualizacion >= rut_fecha_registro)))` - `ruta_nombre_no_vacio`: `((btrim((rut_nombre)::text) <> ''::text))`

**Disparadores:** `trg_aud_ruta (fn_auditar)`.

### `usuario`

**Para qué sirve.** Cuenta de acceso (1:1 con persona). Autenticación intercambiable (RI-008): proveedor local (hash argon2id/bcrypt, nunca texto plano) o externo (solo identificador del IdP; no se guardan credenciales institucionales). rol_id = el rol único del usuario; usuario_predio solo dice a qué predios aplica.

  ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Campo                     Tipo              Obligatorio       Significado
  ------------------------- ----------------- ----------------- -------------------------------------------------------------------------------------------------------------------
  `usu_id`                  entero            sí                Identificador del registro (clave primaria).

  `per_cc`                  entero largo      sí                Referencia a persona(per_cc).

  `usu_usuario`             texto             sí                Nombre de usuario (3--64 caracteres; único sin distinguir mayúsculas).

  `usu_contrasena`          texto             no                Solo HASH (argon2id o bcrypt). Nulo si la cuenta usa proveedor externo o está pendiente de establecer contraseña.

  `usu_proveedor`           texto             sí                local (autenticación propia) o externo (proveedor de identidad institucional, RI-008).

  `usu_sujeto_externo`      texto             no                Identificador del usuario en el proveedor externo (no es una credencial). Obligatorio si usu_proveedor = externo.

  `usu_requiere_reinicio`   sí/no             sí                Verdadero = la cuenta local aún no tiene contraseña y debe establecerla.

  `rol_id`                  entero            sí                Referencia a rol(rol_id).

  `est_id`                  entero            sí                Referencia a estado_registro(est_id).

  `usu_ultimo_acceso`       fecha y hora      no                Último acceso exitoso (para revisión de cuentas inactivas).
  ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

**Identificación.** Clave primaria: `usu_id`.

**Se relaciona con:** `est_id` → `estado_registro`; `per_cc` → `persona`; `rol_id` → `rol`.

**No se puede repetir:** (`per_cc`); (`usu_proveedor, usu_sujeto_externo`).

**Reglas que la base exige:** - `usuario_credencial_coherente`: `(((((usu_proveedor)::text = 'local'::text) AND (usu_sujeto_externo IS NULL) AND ((usu_contrasena IS NOT NULL) OR usu_requiere_reinicio)) OR (((usu_proveedor)::text = 'externo'::text) AND (usu_sujeto_externo IS NOT NULL) AND (usu_c` - `usuario_hash_formato`: `(((usu_contrasena IS NULL) OR ((usu_contrasena)::text ~ '^\$(argon2id\|2[aby])\$'::text)))` - `usuario_proveedor_valido`: `(((usu_proveedor)::text = ANY ((ARRAY['local'::character varying, 'externo'::character varying])::text[])))` - `usuario_usuario_formato`: `(((usu_usuario)::text ~ '^[A-Za-z0-9._@-]{3,64}$'::text))`

**Disparadores:** `trg_aud_usuario (fn_auditar)`.

### `permiso`

**Para qué sirve.** Operación autorizable del sistema (RF-002, RNF-015: la autorización se aplica en el servidor). Formato recurso.accion.

  ---------------------------------------------------------------------------------------------------------------------
  Campo               Tipo              Obligatorio       Significado
  ------------------- ----------------- ----------------- -------------------------------------------------------------
  `prm_id`            entero            sí                Identificador del registro (clave primaria).

  `prm_codigo`        texto             sí                Código recurso.accion del permiso (minúsculas).

  `prm_descripcion`   texto             sí                Texto descriptivo del valor del catálogo (único, no vacío).
  ---------------------------------------------------------------------------------------------------------------------

**Identificación.** Clave primaria: `prm_id`.

**No se puede repetir:** (`prm_codigo`).

**Reglas que la base exige:** - `permiso_codigo_formato`: `(((prm_codigo)::text ~ '^[a-z_]+\.[a-z_]+$'::text))` - `permiso_descripcion_no_vacia`: `((btrim((prm_descripcion)::text) <> ''::text))`

### `rol_permiso`

**Para qué sirve.** Relación N:M rol--permiso. Tabla de intersección pura (BCNF/4NF: sin atributos no clave).

  -------------------------------------------------------------------------------------
  Campo             Tipo              Obligatorio       Significado
  ----------------- ----------------- ----------------- -------------------------------
  `rol_id`          entero            sí                Referencia a rol(rol_id).

  `prm_id`          entero            sí                Referencia a permiso(prm_id).
  -------------------------------------------------------------------------------------

**Identificación.** Clave primaria: `rol_id, prm_id`.

**Se relaciona con:** `prm_id` → `permiso`; `rol_id` → `rol`.

## 5. Predios, lotes, retícula y programa de inspección

El terreno y las reglas de vigilancia. Un **predio** (finca) tiene **lotes** (los cuadros de cultivo) y puede dibujarse como polígono en el mapa. Sobre el predio se define una **retícula** (cuadrícula de celdas para ubicar trampas y hallazgos) y un **programa de inspección** versionado (cada cuánto se lee, qué distancia mínima entre trampas, umbrales).

### `predio`

**Para qué sirve.** Predio inscrito (RDD-001). per_cc = productor responsable. pre_codigo = código interno ICA del predio (parte del código de trampa cuando no hay ruta, RN-005). La columna pre_lotes del esquema actual se elimina: era derivable (COUNT de lote) y generaba anomalías de actualización.

  ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Campo                            Tipo                           Obligatorio       Significado
  -------------------------------- ------------------------------ ----------------- --------------------------------------------------------------------------------------------------------------
  `pre_id`                         entero                         sí                Identificador del registro (clave primaria).

  `pre_codigo`                     texto                          no                Código interno ICA del predio (parte del código de trampa cuando no hay ruta). Único.

  `pre_nombre`                     texto                          sí                Nombre del predio.

  `mun_id`                         entero                         sí                Referencia a municipio(mun_id).

  `pre_area`                       número(14,4)                   sí                \[ud: ha\] Área declarada del predio. Unidad por CONFIRMAR con los datos reales (el frontend usa hectáreas).

  `per_cc`                         entero largo                   sí                Referencia a productor(per_cc).

  `pre_geom`                       geometría(MultiPolygon,4326)   no                Límite del predio, SRID 4326. Nulo hasta cargar el polígono (fuente pendiente de definir).

  `pre_zona_horaria`               texto                          sí                ADR-10: zona horaria IANA del predio; las marcas temporales se guardan en UTC (timestamptz).

  `pre_fecha_registro`             fecha                          sí                Fecha de registro del predio.

  `pre_fecha_actualizacion`        fecha                          no                Fecha de la última actualización del registro (antes era obligatoria; ahora nula hasta que haya una).

  `pre_tecnico_registro_id`        entero                         sí                Identificador lógico del registro: igual en todas sus versiones (el cliente lo genera, UUID v7).

  `pre_tecnico_actualizacion_id`   entero                         no                Referencia a tecnico(tec_id).
  ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

**Identificación.** Clave primaria: `pre_id`.

**Se relaciona con:** `mun_id` → `municipio`; `pre_tecnico_actualizacion_id` → `tecnico`; `pre_tecnico_registro_id` → `tecnico`; `per_cc` → `productor`.

**No se puede repetir:** (`pre_codigo`).

**Reglas que la base exige:** - `predio_area_positiva`: `((pre_area > (0)::numeric))` - `predio_fechas_validas`: `(((pre_fecha_actualizacion IS NULL) OR (pre_fecha_actualizacion >= pre_fecha_registro)))` - `predio_geom_valida`: `(((pre_geom IS NULL) OR st_isvalid(pre_geom)))` - `predio_nombre_no_vacio`: `((btrim((pre_nombre)::text) <> ''::text))` - `predio_zona_horaria_formato`: `(((pre_zona_horaria)::text ~ '^[A-Za-z_]+(/[A-Za-z0-9_+-]+)+$'::text))`

**Disparadores:** `trg_aud_predio (fn_auditar)`.

### `lote`

**Para qué sirve.** Lote: subdivisión del predio (UQQ-001: la definición operativa ICA vs productor sigue abierta). Activo entre lot_fecha_registro y lot_fecha_baja. La geometría vive en lote_geometria (versionada, ADR-06).

  ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Campo                            Tipo              Obligatorio       Significado
  -------------------------------- ----------------- ----------------- -------------------------------------------------------------------------------------------------------------------------------------------------------------
  `lot_id`                         entero            sí                Identificador del registro (clave primaria).

  `lot_codigo`                     texto             no                Código del lote dentro del predio (RDD-002); único por predio.

  `lot_descripcion`                texto             sí                Descripción libre del lote (no es única; el identificador de negocio es (pre_id, lot_codigo)).

  `lot_area`                       número(14,4)      sí                \[ud: ha\] Área declarada. Unidad por CONFIRMAR con los datos reales.

  `pre_id`                         entero            sí                Referencia a predio(pre_id).

  `esc_id`                         entero            no                Especie de cultivo del lote. Forma parte de la FK compuesta (esc_id, var_id) hacia variedad_cultivo, que garantiza que la variedad es de esa especie.

  `var_id`                         entero            no                Referencia a variedad_cultivo(var_id).

  `lot_fecha_plantacion`           fecha             no                Fecha de plantación; base para derivar la etapa fenológica (RN-012).

  `lot_fecha_registro`             fecha             sí                Fecha de registro del lote; inicio de su actividad.

  `lot_fecha_actualizacion`        fecha             no                Fecha de la última actualización del registro.

  `lot_fecha_baja`                 fecha             no                Primer día en que el lote deja de estar activo (nulo = activo). Permite validar "el lote debe estar activo en el periodo inspeccionado" (Arquitectura 5.3).

  `lot_tecnico_registro_id`        entero            sí                Identificador lógico del registro: igual en todas sus versiones (el cliente lo genera, UUID v7).

  `lot_tecnico_actualizacion_id`   entero            no                Referencia a tecnico(tec_id).
  ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

**Identificación.** Clave primaria: `lot_id`.

**Se relaciona con:** `esc_id` → `especie_cultivo`; `lot_tecnico_actualizacion_id` → `tecnico`; `lot_tecnico_registro_id` → `tecnico`; `pre_id` → `predio`; `esc_id, var_id` → `variedad_cultivo`.

**No se puede repetir:** (`lot_id, pre_id`); (`pre_id, lot_codigo`).

**Reglas que la base exige:** - `lote_area_positiva`: `((lot_area > (0)::numeric))` - `lote_descripcion_no_vacia`: `((btrim((lot_descripcion)::text) <> ''::text))` - `lote_fechas_validas`: `((((lot_fecha_actualizacion IS NULL) OR (lot_fecha_actualizacion >= lot_fecha_registro)) AND ((lot_fecha_baja IS NULL) OR (lot_fecha_baja >= lot_fecha_registro)) AND ((lot_fecha_plantacion IS NULL) OR (lot_fecha_plantacion <= COAL` - `lote_var_requiere_esc`: `(((var_id IS NULL) OR (esc_id IS NOT NULL)))`

**Disparadores:** `trg_aud_lote (fn_auditar)`.

### `lote_geometria`

**Para qué sirve.** RF-085 / ADR-06: versiones de la geometría de un lote con vigencia; cada medición se asocia a la versión vigente en su fecha de observación. Una sola versión vigente por instante (EXCLUDE).

  ---------------------------------------------------------------------------------------------------------------------------------------------------------
  Campo                  Tipo                           Obligatorio       Significado
  ---------------------- ------------------------------ ----------------- ---------------------------------------------------------------------------------
  `log_id`               entero                         sí                Identificador del registro (clave primaria).

  `lot_id`               entero                         sí                Referencia a lote(lot_id).

  `log_version`          entero                         sí                Número de versión de la geometría del lote (1, 2, ...).

  `log_geom`             geometría(MultiPolygon,4326)   sí                Polígono del lote, SRID 4326, válido y no vacío.

  `log_area_m2`          número                         no                \[ud: m2\] Área geodésica calculada (geography); columna derivada, no editable.

  `log_vigente_desde`    fecha y hora                   sí                Inicio de vigencia de la versión (inclusive).

  `log_vigente_hasta`    fecha y hora                   no                Fin de vigencia de la versión (exclusivo); nulo = vigente.

  `log_fuente`           texto                          no                Origen de la geometría (GPS del dispositivo, digitalización, importación).

  `log_motivo`           texto                          no                Motivo del cambio de geometría.

  `log_registrado_en`    fecha y hora                   sí                Momento en que se registró la versión.

  `log_registrado_por`   entero                         no                Usuario que registró la versión (opcional).
  ---------------------------------------------------------------------------------------------------------------------------------------------------------

**Identificación.** Clave primaria: `log_id`.

**Se relaciona con:** `lot_id` → `lote`.

**No se puede repetir:** (`lot_id, log_version`).

**Reglas que la base exige:** - `lote_geometria_geom_valida`: `((st_isvalid(log_geom) AND (NOT st_isempty(log_geom))))` - `lote_geometria_version_positiva`: `((log_version >= 1))` - `lote_geometria_vigencia_valida`: `(((log_vigente_hasta IS NULL) OR (log_vigente_hasta > log_vigente_desde)))`

**Disparadores:** `trg_aud_lote_geometria (fn_auditar)`, `trg_lote_geometria_valida (fn_lote_geometria_valida)`.

### `reticula`

**Para qué sirve.** RF-006 / RDD-003: retícula regular de un predio con su resolución en metros (parámetro por predio, no constante). El tamaño de celda es pendiente (UQQ-005); debe ser múltiplo de la distancia mínima entre trampas y mayor que 60 m (RN-004, RI-002).

  -----------------------------------------------------------------------------------------------------------------------
  Campo                      Tipo              Obligatorio       Significado
  -------------------------- ----------------- ----------------- --------------------------------------------------------
  `ret_id`                   entero            sí                Identificador del registro (clave primaria).

  `pre_id`                   entero            sí                Referencia a predio(pre_id).

  `ret_resolucion_m`         entero            sí                \[ud: m\] Lado de la celda.

  `ret_fecha_corte_imagen`   fecha             no                Fecha de corte de la imagen satelital usada (RDD-003).

  `ret_creada_en`            fecha y hora      sí                Momento en que se creó la retícula.
  -----------------------------------------------------------------------------------------------------------------------

**Identificación.** Clave primaria: `ret_id`.

**Se relaciona con:** `pre_id` → `predio`.

**No se puede repetir:** (`pre_id, ret_resolucion_m`); (`ret_id, pre_id`).

**Reglas que la base exige:** - `reticula_resolucion_valida`: `((ret_resolucion_m > 60))`

**Disparadores:** `trg_reticula_inmutable (fn_reticula_inmutable)`.

### `reticula_celda`

**Para qué sirve.** Celda de la retícula (RDD-003). La resolución y la fecha de corte de imagen se heredan de reticula (no se repiten por celda: 3FN).

  ---------------------------------------------------------------------------------------------------------------------
  Campo             Tipo                      Obligatorio       Significado
  ----------------- ------------------------- ----------------- -------------------------------------------------------
  `rce_id`          entero largo              sí                Identificador del registro (clave primaria).

  `ret_id`          entero                    sí                Referencia a reticula(ret_id).

  `rce_codigo`      texto                     sí                Código de la celda dentro de la retícula (p. ej. C3).

  `rce_geom`        geometría(Polygon,4326)   sí                Polígono de la celda, SRID 4326, válido.
  ---------------------------------------------------------------------------------------------------------------------

**Identificación.** Clave primaria: `rce_id`.

**Se relaciona con:** `ret_id` → `reticula`.

**No se puede repetir:** (`ret_id, rce_codigo`).

**Reglas que la base exige:** - `reticula_celda_codigo_no_vacio`: `((btrim((rce_codigo)::text) <> ''::text))` - `reticula_celda_geom_valida`: `(st_isvalid(rce_geom))`

### `usuario_predio`

**Para qué sirve.** RF-002: predios a los que un usuario tiene acceso, con vigencia. El rol es ÚNICO por usuario (usuario.rol_id): esta tabla no repite el rol, solo dice dónde aplica. No puede tener dos asignaciones solapadas sobre el mismo predio. Solo admite usuarios con rol de ámbito predio (el Administrador es global). Los lotes concretos de cada técnico (p. ej. Andrés: A y C; Juan: B y D) salen de las planificaciones aceptadas (v_asignacion_lote_tecnico). El alcance del Agrónomo/Supervisor es pendiente institucional.

  -----------------------------------------------------------------------------------------------------------------------
  Campo                Tipo              Obligatorio       Significado
  -------------------- ----------------- ----------------- --------------------------------------------------------------
  `usp_id`             entero            sí                Identificador del registro (clave primaria).

  `usu_id`             entero            sí                Usuario que realizó/capturó la acción.

  `pre_id`             entero            sí                Referencia a predio(pre_id).

  `usp_desde`          fecha             sí                Primer día en que rige la asignación (inclusive).

  `usp_hasta`          fecha             no                Primer día en que deja de regir (exclusivo); nulo = vigente.

  `usp_asignado_por`   entero            no                Referencia a usuario(usu_id).

  `usp_creado_en`      fecha y hora      sí                Momento en que se creó la asignación.
  -----------------------------------------------------------------------------------------------------------------------

**Identificación.** Clave primaria: `usp_id`.

**Se relaciona con:** `usp_asignado_por` → `usuario`; `pre_id` → `predio`; `usu_id` → `usuario`.

**Reglas que la base exige:** - `usuario_predio_vigencia_valida`: `(((usp_hasta IS NULL) OR (usp_hasta > usp_desde)))`

**Disparadores:** `trg_aud_usuario_predio (fn_auditar)`, `trg_usuario_predio_valida (fn_usuario_predio_valida)`.

### `programa_inspeccion`

**Para qué sirve.** RF-080 / RDD-007: configuración versionada del programa de inspección de un predio (nunca se edita: se crea una versión nueva y se cierra la anterior). El umbral de EXPORTACIÓN es nulo mientras no se defina (UQQ-004); si existe debe citar la norma que lo sustenta.

  ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Campo                           Tipo              Obligatorio       Significado
  ------------------------------- ----------------- ----------------- ----------------------------------------------------------------------------------------------------------------------------
  `pri_id`                        entero            sí                Identificador del registro (clave primaria).

  `pre_id`                        entero            sí                Predio del programa de inspección. Forma parte de la FK compuesta (ret_id, pre_id) hacia reticula y de la FK hacia predio.

  `pri_version`                   entero            sí                Número de versión de la configuración del predio (1, 2, ...).

  `pri_vigente_desde`             fecha             sí                Primer día de vigencia (inclusive).

  `pri_vigente_hasta`             fecha             no                Primer día en que deja de regir (exclusivo); nulo = vigente.

  `pri_ciclo_inicio`              fecha             no                Inicio del ciclo de cultivo del programa (opcional).

  `pri_ciclo_fin`                 fecha             no                Fin del ciclo de cultivo del programa (opcional; definición del ciclo pendiente).

  `pri_periodo_lectura_dias`      entero corto      sí                \[ud: días\] RN-007: 7 a 14 días en predios de exportación (UQQ-003 pide confirmarlo).

  `pri_distancia_min_trampas_m`   entero corto      sí                \[ud: m\] RN-004: distancia mínima entre trampas, 40 a 60 m. El valor exacto es parámetro por predio.

  `ret_id`                        entero            no                Referencia a reticula(ret_id).

  `pri_proveedor_imagen`          texto             no                Proveedor de imagen satelital configurado (UQQ-007 pendiente).

  `pri_umbral_exportacion_mtd`    número(10,4)      no                \[ud: moscas/trampa/día\] Umbral de MTD de exportación. NO INVENTADO: nulo hasta que UQQ-004 se resuelva.

  `nor_id`                        entero            no                Referencia a norma(nor_id).

  `pri_motivo_cambio`             texto             no                Motivo del cambio respecto de la versión anterior.

  `pri_creado_por`                entero            no                Referencia a usuario(usu_id).

  `pri_creado_en`                 fecha y hora      sí                Momento en que se creó la versión.
  ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

**Identificación.** Clave primaria: `pri_id`.

**Se relaciona con:** `pri_creado_por` → `usuario`; `nor_id` → `norma`; `pre_id` → `predio`; `ret_id, pre_id` → `reticula`.

**No se puede repetir:** (`pre_id, pri_version`); (`pri_id, pre_id`).

**Reglas que la base exige:** - `programa_inspeccion_ciclo_valido`: `((((pri_ciclo_inicio IS NULL) = (pri_ciclo_fin IS NULL)) AND ((pri_ciclo_inicio IS NULL) OR (pri_ciclo_fin >= pri_ciclo_inicio))))` - `programa_inspeccion_distancia_rn004`: `(((pri_distancia_min_trampas_m >= 40) AND (pri_distancia_min_trampas_m <= 60)))` - `programa_inspeccion_periodo_rn007`: `(((pri_periodo_lectura_dias >= 7) AND (pri_periodo_lectura_dias <= 14)))` - `programa_inspeccion_umbral_con_norma`: `(((pri_umbral_exportacion_mtd IS NULL) = (nor_id IS NULL)))` - `programa_inspeccion_umbral_valido`: `(((pri_umbral_exportacion_mtd IS NULL) OR (pri_umbral_exportacion_mtd >= (0)::numeric)))` - `programa_inspeccion_version_positiva`: `((pri_version >= 1))` - `programa_inspeccion_vigencia_valida`: `(((pri_vigente_hasta IS NULL) OR (pri_vigente_hasta > pri_vigente_desde)))`

**Disparadores:** `trg_aud_programa (fn_auditar)`, `trg_programa_valida (fn_programa_valida)`.

### `programa_umbral`

**Para qué sirve.** RN-002: límites de MTD de cada escenario de trampeo, configurables por versión de programa. \[ud: moscas/trampa/día\]. La inclusión de los extremos del intervalo es una decisión institucional pendiente.

  ---------------------------------------------------------------------------------------------------------------------------------
  Campo             Tipo              Obligatorio       Significado
  ----------------- ----------------- ----------------- ---------------------------------------------------------------------------
  `pri_id`          entero            sí                Referencia a programa_inspeccion(pri_id).

  `esq_id`          entero            sí                Referencia a escenario_trampeo(esq_id).

  `pru_mtd_desde`   número(10,4)      sí                \[ud: moscas/trampa/día\] Límite inferior del escenario en este programa.

  `pru_mtd_hasta`   número(10,4)      no                \[ud: moscas/trampa/día\] Límite superior; nulo = sin límite.
  ---------------------------------------------------------------------------------------------------------------------------------

**Identificación.** Clave primaria: `pri_id, esq_id`.

**Se relaciona con:** `esq_id` → `escenario_trampeo`; `pri_id` → `programa_inspeccion`.

**Reglas que la base exige:** - `programa_umbral_rango_valido`: `(((pru_mtd_desde >= (0)::numeric) AND ((pru_mtd_hasta IS NULL) OR (pru_mtd_hasta >= pru_mtd_desde))))`

### `fenologia_regla`

**Para qué sirve.** RN-012: tabla de etapas vigente en una fecha. La etapa derivada de un lote = etapa cuyo intervalo de días desde la plantación contiene (fecha de observación − fecha de plantación). Los valores no están en la documentación disponible: se cargan desde la fuente agronómica.

  ------------------------------------------------------------------------------------------------------------------------------------------
  Campo                 Tipo              Obligatorio       Significado
  --------------------- ----------------- ----------------- --------------------------------------------------------------------------------
  `fer_id`              entero            sí                Identificador del registro (clave primaria).

  `esc_id`              entero            sí                Referencia a especie_cultivo(esc_id).

  `fen_id`              entero            sí                Referencia a fenologia(fen_id).

  `fer_dias_desde`      entero            sí                \[ud: días desde la plantación\] límite inferior inclusivo.

  `fer_dias_hasta`      entero            no                \[ud: días desde la plantación\] Límite superior exclusivo; nulo = sin límite.

  `fer_vigente_desde`   fecha             sí                Primer día de vigencia de la regla.

  `fer_vigente_hasta`   fecha             no                Primer día en que la regla deja de regir (exclusivo); nulo = vigente.
  ------------------------------------------------------------------------------------------------------------------------------------------

**Identificación.** Clave primaria: `fer_id`.

**Se relaciona con:** `esc_id` → `especie_cultivo`; `fen_id` → `fenologia`.

**Reglas que la base exige:** - `fenologia_regla_dias_validos`: `(((fer_dias_desde >= 0) AND ((fer_dias_hasta IS NULL) OR (fer_dias_hasta > fer_dias_desde))))` - `fenologia_regla_vigencia_valida`: `(((fer_vigente_hasta IS NULL) OR (fer_vigente_hasta > fer_vigente_desde)))`

### `paquete_campo`

**Para qué sirve.** RF-004 / M-07: versión del paquete de campo descargable de un predio (geometrías, retícula, trampas, catálogos, umbrales). Se invalida al cambiar la configuración. paq_hash = SHA-256 hex del contenido generado.

  ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Campo                       Tipo              Obligatorio       Significado
  --------------------------- ----------------- ----------------- --------------------------------------------------------------------------------------------------------------------
  `paq_id`                    UUID              sí                Identificador del registro (clave primaria).

  `pre_id`                    entero            sí                Predio del paquete de datos para campo. Forma parte de la FK compuesta (pri_id, pre_id) hacia programa_inspeccion.

  `paq_version`               entero            sí                Número de versión del paquete del predio.

  `pri_id`                    entero            sí                Referencia a programa_inspeccion(pri_id).

  `paq_hash`                  hash 64 hex       sí                SHA-256 hexadecimal del contenido del paquete.

  `paq_generado_en`           fecha y hora      sí                Momento en que se generó el paquete.

  `paq_invalidado_en`         fecha y hora      no                Momento en que el paquete dejó de ser válido (cambio de configuración).

  `paq_motivo_invalidacion`   texto             no                Motivo de la invalidación.
  ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

**Identificación.** Clave primaria: `paq_id`.

**Se relaciona con:** `pre_id` → `predio`; `pri_id, pre_id` → `programa_inspeccion`.

**No se puede repetir:** (`pre_id, paq_version`).

**Reglas que la base exige:** - `paquete_campo_hash_formato`: `((paq_hash ~ '^[0-9a-f]{64}$'::text))` - `paquete_campo_invalidacion_coherente`: `(((paq_invalidado_en IS NULL) = (paq_motivo_invalidacion IS NULL)))` - `paquete_campo_version_positiva`: `((paq_version >= 1))`

**Disparadores:** `trg_aud_paquete (fn_auditar)`.

## 6. Trampas y ubicaciones

Las trampas Jackson/McPhail con su **código ICA** oficial y **dónde estuvo cada una y cuándo**. La ubicación se guarda como historial: si una trampa se cambia de sitio no se pierde el lugar anterior. Esta área también calcula en qué lote cae cada trampa a partir de su coordenada.

### `trampa`

**Para qué sirve.** Trampa física identificada por su código ICA (RN-005: Divipola(5)-ruta o predio interno-número). El código puede ser nulo solo en trampas heredadas del esquema anterior; no se puede asignar ni leer una trampa nueva sin código. La posición y el lote están en ubicacion_trampa (historial). tra_atr_id = atrayente vigente por defecto.

  ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Campo                            Tipo              Obligatorio       Significado
  -------------------------------- ----------------- ----------------- ------------------------------------------------------------------------------------------------------------------------------------
  `tra_id`                         entero            sí                Identificador del registro (clave primaria).

  `tra_codigo_ica`                 texto             no                Código oficial impreso en la trampa. Formato verificado de forma mínima (el Manual Técnico T1 no está disponible): ver pendientes.

  `tra_numero`                     entero            no                Número de trampa extraído del código (columna generada). Jackson impar / McPhail par (RN-005).

  `tit_id`                         entero            sí                Referencia a tipo_trampa(tit_id).

  `atr_id`                         entero            sí                Referencia a atrayente(atr_id).

  `est_id`                         entero            sí                Referencia a estado_registro(est_id).

  `tra_fecha_registro`             fecha             sí                Fecha de registro de la trampa.

  `tra_fecha_actualizacion`        fecha             no                Fecha de la última actualización del registro.

  `tra_fecha_estado`               fecha             no                Fecha del último cambio de estado (est_id) de la trampa.

  `tra_tecnico_registro_id`        entero            sí                Identificador lógico del registro: igual en todas sus versiones (el cliente lo genera, UUID v7).

  `tra_tecnico_actualizacion_id`   entero            no                Referencia a tecnico(tec_id).

  `tra_tecnico_estado_id`          entero            no                Referencia a tecnico(tec_id).
  ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

**Identificación.** Clave primaria: `tra_id`.

**Se relaciona con:** `atr_id` → `atrayente`; `est_id` → `estado_registro`; `tit_id` → `tipo_trampa`; `tra_tecnico_actualizacion_id` → `tecnico`; `tra_tecnico_estado_id` → `tecnico`; `tra_tecnico_registro_id` → `tecnico`.

**No se puede repetir:** (`tra_codigo_ica`).

**Reglas que la base exige:** - `trampa_codigo_ica_formato`: `(((tra_codigo_ica)::text ~ '^[0-9]{5}-[0-9A-Za-z]{1,10}-[0-9]{1,4}$'::text))` - `trampa_fechas_validas`: `((((tra_fecha_actualizacion IS NULL) OR (tra_fecha_actualizacion >= tra_fecha_registro)) AND ((tra_fecha_estado IS NULL) OR (tra_fecha_estado >= tra_fecha_registro))))`

**Disparadores:** `trg_aud_trampa (fn_auditar)`, `trg_trampa_valida (fn_trampa_valida)`.

### `ubicacion_trampa`

**Para qué sirve.** Asignación y ubicación de una trampa en un lote durante un intervalo \[ubi_fecha, ubi_fecha_fin). Es la asignación EXPLÍCITA trampa--lote exigida por RN-013/RF-013 y conserva el historial de reubicaciones. Una trampa no puede tener dos ubicaciones simultáneas (EXCLUDE). Evoluciona la tabla ubicacion_trampa del esquema actual (que no tenía lote). lot_id es nulo solo en filas ubi_origen=legado pendientes de asignar.

  -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Campo                 Tipo                    Obligatorio       Significado
  --------------------- ----------------------- ----------------- -------------------------------------------------------------------------------------------------------------------------------------------------------
  `ubi_id`              entero largo            sí                Identificador del registro (clave primaria).

  `tra_id`              entero                  sí                Referencia a trampa(tra_id).

  `pre_id`              entero                  sí                Redundancia controlada: lot_id determina pre_id; la FK compuesta (lot_id, pre_id) impide la incoherencia. Permite conservar filas heredadas sin lote.

  `lot_id`              entero                  no                Referencia a lote(lot_id).

  `ubi_fecha`           fecha                   sí                Fecha de instalación en este puesto (inclusive). ubi_fecha_fin = primer día en que ya no está (exclusivo; retiro o reubicación).

  `ubi_fecha_fin`       fecha                   no                Primer día en que la trampa ya no está en este puesto (exclusivo); nulo = vigente.

  `tec_id`              entero                  sí                Referencia a tecnico(tec_id).

  `vig_id`              entero                  sí                Referencia a vigilancia(vig_id).

  `rut_id`              entero                  no                Referencia a ruta(rut_id).

  `rce_id`              entero largo            no                Referencia a reticula_celda(rce_id).

  `loc_id`              entero                  no                Referencia a localizacion(loc_id).

  `arb_id`              entero                  no                Referencia a arbol(arb_id).

  `ubi_long`            número(8,5)             sí                \[ud: grados decimales WGS84\] 5 decimales (RN-006); numeric evita ruido de punto flotante.

  `ubi_lat`             número(7,5)             sí                \[ud: grados decimales WGS84\] Latitud con 5 decimales (RN-006).

  `ubi_alt`             decimal                 no                \[ud: m s. n. m.\] Altitud; puede faltar si el GPS no la entrega.

  `ubi_referencia`      texto                   no                Descripción libre del sitio (opcional).

  `ubi_geom`            geometría(Point,4326)   no                Punto SRID 4326 derivado de ubi_long/ubi_lat (columna generada: una sola fuente de verdad). Base de ST_Contains contra lote_geometria.

  `ubi_origen`          texto                   sí                operacion = creada con las reglas vigentes; legado = migrada del esquema anterior sin lote asignado.

  `ubi_registrado_en`   fecha y hora            sí                Momento en que se registró la ubicación.
  -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

**Identificación.** Clave primaria: `ubi_id`.

**Se relaciona con:** `arb_id` → `arbol`; `loc_id` → `localizacion`; `lot_id, pre_id` → `lote`; `pre_id` → `predio`; `rce_id` → `reticula_celda`; `rut_id` → `ruta`; `tec_id` → `tecnico`; `tra_id` → `trampa`; `vig_id` → `vigilancia`.

**No se puede repetir:** (`ubi_id, tra_id`).

**Reglas que la base exige:** - `ubicacion_trampa_coordenadas_validas`: `((((ubi_long >= ('-180'::integer)::numeric) AND (ubi_long <= (180)::numeric)) AND ((ubi_lat >= ('-90'::integer)::numeric) AND (ubi_lat <= (90)::numeric))))` - `ubicacion_trampa_lote_obligatorio`: `((((ubi_origen)::text = 'legado'::text) OR (lot_id IS NOT NULL)))` - `ubicacion_trampa_origen_valido`: `(((ubi_origen)::text = ANY ((ARRAY['operacion'::character varying, 'legado'::character varying])::text[])))` - `ubicacion_trampa_vigencia_valida`: `(((ubi_fecha_fin IS NULL) OR (ubi_fecha_fin > ubi_fecha)))`

**Disparadores:** `trg_aud_ubicacion_trampa (fn_auditar)`, `trg_ubicacion_trampa_valida (fn_ubicacion_trampa_valida)`.

## 7. Sincronización offline y auditoría

Lo que permite trabajar sin Internet y confiar en los datos. Cada vez que el celular envía algo queda una **operación** con un identificador propio: si se reenvía por una caída de red, el servidor lo reconoce y no lo duplica. También está la **bitácora de auditoría**: quién cambió qué y cuándo. Ninguna de estas tablas se puede editar ni borrar.

### `dispositivo`

**Para qué sirve.** Instalación de la aplicación móvil (identificador generado en el primer arranque). Forma parte de la clave de idempotencia (dis_id, ope_cliente_id).

  ---------------------------------------------------------------------------------------------------------------------------------
  Campo                 Tipo              Obligatorio       Significado
  --------------------- ----------------- ----------------- -----------------------------------------------------------------------
  `dis_id`              UUID              sí                Dispositivo que capturó el registro.

  `dis_nombre`          texto             no                Nombre descriptivo del dispositivo (opcional).

  `dis_plataforma`      texto             sí                android, ios u otro.

  `dis_version_app`     texto             no                Versión de la aplicación instalada.

  `dis_registrado_en`   fecha y hora      sí                Momento en que el dispositivo se registró por primera vez.

  `dis_ultima_sync`     fecha y hora      no                Último momento en que el dispositivo sincronizó.

  `dis_activo`          sí/no             sí                Falso = dispositivo dado de baja; sus operaciones nuevas se rechazan.
  ---------------------------------------------------------------------------------------------------------------------------------

**Identificación.** Clave primaria: `dis_id`.

**Reglas que la base exige:** - `dispositivo_plataforma_valida`: `(((dis_plataforma)::text = ANY ((ARRAY['android'::character varying, 'ios'::character varying, 'otro'::character varying])::text[])))`

### `operacion_sync`

**Para qué sirve.** Operación recibida desde un dispositivo (ADR-04, RF-062..066). La clave (dis_id, ope_cliente_id) hace idempotente el reintento (RN-010). Se inserta una sola vez (append-only); los reenvíos se registran en recepcion_sync. Las operaciones revisar/rechazada no crean filas en las tablas de dominio: su contenido queda en ope_payload hasta que el usuario las resuelva con una operación nueva (ope_resuelve_ope_id). ope_payload es el ÚNICO uso de JSONB para datos de negocio: sobre de transporte no consultable relacionalmente.

  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Campo                    Tipo                              Obligatorio       Significado
  ------------------------ --------------------------------- ----------------- --------------------------------------------------------------------------------------------------------------------------
  `ope_id`                 entero largo                      sí                Operación de sincronización que creó el registro (idempotencia y trazabilidad).

  `dis_id`                 UUID                              sí                Dispositivo que capturó el registro.

  `ope_cliente_id`         UUID                              sí                Identificador de la operación generado en el dispositivo (UUID); junto con dis_id es la clave de idempotencia.

  `usu_id`                 entero                            sí                Usuario que realizó/capturó la acción.

  `ope_entidad`            texto                             sí                Tabla de dominio a la que se refiere la operación.

  `ope_accion`             texto                             sí                crear, corregir (nueva versión) o anular.

  `ope_registro_id`        UUID                              sí                Identificador lógico del registro afectado.

  `ope_version`            entero                            sí                Número de versión del registro: 1 = alta; n+1 = corrección. Append-only (ADR-03).

  `ope_hash_contenido`     hash 64 hex                       sí                SHA-256 hex del contenido canónico. Mismo (dis_id, ope_cliente_id) con hash distinto = conflicto (RN-010).

  `ope_clasificacion`      sigat.d_clasificacion_operacion   sí                Clasificación del servidor (ADR-04): alta_nueva, alta_retroactiva, correccion, revisar o rechazada.

  `ope_motivo`             texto                             no                Motivo de la clasificación (obligatorio si revisar o rechazada).

  `ope_t_captura`          fecha y hora                      sí                Momento en que el dato se guardó, según el reloj del dispositivo (no puede ser anterior a t_observacion).

  `ope_t_recepcion`        fecha y hora                      sí                Momento (servidor) en que se recibió por primera vez la operación.

  `ope_deriva_reloj_seg`   entero                            no                \[ud: s\] Diferencia detectada entre el reloj del dispositivo y el del servidor (RDD-010); nulo si no se detectó.

  `ope_resuelve_ope_id`    entero largo                      no                Referencia a operacion_sync(ope_id).

  `ope_payload`            jsonb                             no                Sobre de transporte recibido (JSONB). Obligatorio solo en operaciones revisar/rechazada; no se consulta relacionalmente.
  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

**Identificación.** Clave primaria: `ope_id`.

**Se relaciona con:** `dis_id` → `dispositivo`; `ope_resuelve_ope_id` → `operacion_sync`; `usu_id` → `usuario`.

**No se puede repetir:** (`dis_id, ope_cliente_id`).

**Reglas que la base exige:** - `operacion_sync_accion_valida`: `(((ope_accion)::text = ANY ((ARRAY['crear'::character varying, 'corregir'::character varying, 'anular'::character varying])::text[])))` - `operacion_sync_clasificacion_original`: `(((ope_clasificacion)::text <> 'idempotente_repetida'::text))` - `operacion_sync_entidad_valida`: `(((ope_entidad)::text = ANY ((ARRAY['visita'::character varying, 'lectura_trampa'::character varying, 'aplicacion_fitosanitaria'::character varying, 'cosecha'::character varying, 'etapa_declarada'::character varying, 'hallazgo'::c` - `operacion_sync_hash_formato`: `((ope_hash_contenido ~ '^[0-9a-f]{64}$'::text))` - `operacion_sync_motivo_requerido`: `((((ope_clasificacion)::text <> ALL (ARRAY['revisar'::text, 'rechazada'::text])) OR ((ope_motivo IS NOT NULL) AND (ope_payload IS NOT NULL))))` - `operacion_sync_version_positiva`: `((ope_version >= 1))`

**Disparadores:** `trg_operacion_sync_notruncate (fn_bloquear_truncate)`, `trg_operacion_sync_ro (fn_bloquear_modificacion)`.

### `recepcion_sync`

**Para qué sirve.** Registro append-only de cada reenvío de una operación ya recibida: idempotente_repetida (mismo hash, no produce duplicados) o conflicto_contenido (mismo identificador, contenido distinto → se rechaza y se reporta, RN-010).

  ---------------------------------------------------------------------------------------------------------------------------------------------------------------
  Campo             Tipo              Obligatorio       Significado
  ----------------- ----------------- ----------------- ---------------------------------------------------------------------------------------------------------
  `rec_id`          entero largo      sí                Identificador del registro (clave primaria).

  `ope_id`          entero largo      sí                Operación de sincronización que creó el registro (idempotencia y trazabilidad).

  `rec_t`           fecha y hora      sí                Momento (servidor) del reenvío.

  `rec_hash`        hash 64 hex       sí                SHA-256 del contenido recibido en el reenvío.

  `rec_resultado`   texto             sí                idempotente_repetida (mismo contenido) o conflicto_contenido (mismo identificador, contenido distinto).
  ---------------------------------------------------------------------------------------------------------------------------------------------------------------

**Identificación.** Clave primaria: `rec_id`.

**Se relaciona con:** `ope_id` → `operacion_sync`.

**Reglas que la base exige:** - `recepcion_sync_hash_formato`: `((rec_hash ~ '^[0-9a-f]{64}$'::text))` - `recepcion_sync_resultado_valido`: `(((rec_resultado)::text = ANY ((ARRAY['idempotente_repetida'::character varying, 'conflicto_contenido'::character varying])::text[])))`

**Disparadores:** `trg_recepcion_sync_notruncate (fn_bloquear_truncate)`, `trg_recepcion_sync_ro (fn_bloquear_modificacion)`.

### `bitacora_auditoria`

**Para qué sirve.** RF-083 / RNF-014: bitácora que no admite modificación. Registra actor, las tres marcas temporales, versión afectada y el detalle del cambio (aud_detalle: diferencias; nunca contraseñas). También recibe los accesos a datos personales.

  ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Campo                    Tipo              Obligatorio       Significado
  ------------------------ ----------------- ----------------- -----------------------------------------------------------------------------------------------------------------------
  `aud_id`                 entero largo      sí                Identificador del registro (clave primaria).

  `aud_t_registro`         fecha y hora      sí                Momento (reloj del servidor) en que se escribió la entrada de bitácora.

  `aud_tabla`              texto             sí                Nombre de la tabla afectada.

  `aud_registro`           texto             sí                Clave primaria del registro afectado, en texto.

  `aud_accion`             texto             sí                Operación auditada: INSERT, UPDATE, DELETE, ACCESO (lectura de datos personales) o SYNC.

  `aud_version`            entero            no                Número de versión del registro: 1 = alta; n+1 = corrección. Append-only (ADR-03).

  `usu_id`                 entero            no                Usuario que realizó/capturó la acción.

  `dis_id`                 UUID              no                Dispositivo que capturó el registro.

  `aud_t_observacion`      fecha y hora      no                Momento en que ocurrió lo observado (ADR-02); orden canónico del registro. Inmutable entre versiones (RN-009).

  `aud_t_captura`          fecha y hora      no                Momento en que el dato se guardó, según el reloj del dispositivo (no puede ser anterior a t_observacion).

  `aud_t_sincronizacion`   fecha y hora      no                Momento en que el servidor recibió el dato (reloj del servidor, asignado por trigger; el cliente no lo controla).

  `aud_detalle`            jsonb             no                Detalle del cambio en JSONB: fila completa (INSERT/DELETE) o pares antes/después (UPDATE). Nunca incluye contraseñas.
  ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

**Identificación.** Clave primaria: `aud_id`.

**Se relaciona con:** `dis_id` → `dispositivo`; `usu_id` → `usuario`.

**Reglas que la base exige:** - `bitacora_auditoria_accion_valida`: `(((aud_accion)::text = ANY ((ARRAY['INSERT'::character varying, 'UPDATE'::character varying, 'DELETE'::character varying, 'ACCESO'::character varying, 'SYNC'::character varying])::text[])))`

**Disparadores:** `trg_bitacora_notruncate (fn_bloquear_truncate)`, `trg_bitacora_ro (fn_bloquear_modificacion)`.

## 8. Registros de campo (visitas, lecturas, aplicaciones, cosecha, fenología)

Lo que se captura en el campo. Una **visita** agrupa los lotes recorridos; cada **lectura** dice cuántas moscas había en una trampa y en qué estado estaba. El productor reporta **aplicaciones**, **cosecha** y **etapa fenológica**. Todos estos registros son *versionados*: para corregir uno se agrega una versión nueva, la anterior se conserva. Cada dato lleva tres fechas: cuándo se observó, cuándo se capturó y cuándo llegó al servidor.

### `visita`

**Para qué sirve.** Sesión de inspección de un técnico en un predio (RF-060, ADR-08). Solo llega al servidor ya cerrada. Solo las columnas de revisión (Agrónomo/Supervisor) admiten UPDATE. El estado de ciclo en el dispositivo (en progreso/completada/sincronizada) vive en la base local, no aquí.

  ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Campo                    Tipo                      Obligatorio       Significado
  ------------------------ ------------------------- ----------------- -------------------------------------------------------------------------------------------------------------------
  `vis_id`                 UUID                      sí                Identificador del registro (clave primaria).

  `dis_id`                 UUID                      sí                Dispositivo que capturó el registro.

  `ope_id`                 entero largo              sí                Operación de sincronización que creó el registro (idempotencia y trazabilidad).

  `usu_id`                 entero                    sí                Usuario que realizó/capturó la acción.

  `pre_id`                 entero                    sí                Referencia a predio(pre_id).

  `rut_id`                 entero                    no                Referencia a ruta(rut_id).

  `vis_t_inicio_obs`       fecha y hora              sí                Momento observado de inicio de la visita (reloj del dispositivo).

  `vis_t_fin_obs`          fecha y hora              sí                Momento observado de cierre de la visita.

  `vis_t_captura`          fecha y hora              sí                Momento en que el dato se guardó, según el reloj del dispositivo (no puede ser anterior a t_observacion).

  `vis_t_sincronizacion`   fecha y hora              sí                Momento en que el servidor recibió el dato (reloj del servidor, asignado por trigger; el cliente no lo controla).

  `vis_deriva_reloj_seg`   entero                    no                \[ud: s\] Diferencia detectada entre el reloj del dispositivo y el del servidor (RDD-010); nulo si no se detectó.

  `vis_estado_revision`    sigat.d_estado_revision   sí                Revisión del Agrónomo/Supervisor (origen: frontend; confirmar como regla institucional).

  `vis_motivo_revision`    texto                     no                Motivo cuando la visita pasa a revisión.

  `vis_revisada_por`       entero                    no                Referencia a usuario(usu_id).

  `vis_revisada_en`        fecha y hora              no                Momento de la última revisión del Agrónomo/Supervisor.
  ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

**Identificación.** Clave primaria: `vis_id`.

**Se relaciona con:** `dis_id` → `dispositivo`; `ope_id` → `operacion_sync`; `pre_id` → `predio`; `vis_revisada_por` → `usuario`; `rut_id` → `ruta`; `usu_id` → `usuario`.

**No se puede repetir:** (`ope_id`); (`vis_id, pre_id`).

**Reglas que la base exige:** - `visita_revision_coherente`: `((((vis_estado_revision)::text = 'pendiente'::text) = ((vis_revisada_por IS NULL) AND (vis_revisada_en IS NULL))))` - `visita_tiempos_validos`: `(((vis_t_fin_obs >= vis_t_inicio_obs) AND (vis_t_fin_obs <= vis_t_captura)))`

**Disparadores:** `trg_aud_visita (fn_auditar)`, `trg_visita_integridad (fn_visita_integridad)`.

### `visita_lote`

**Para qué sirve.** Relación N:M visita--lote (lotes cubiertos). pre_id se repite para garantizar por FK compuestas que visita y lote pertenecen al mismo predio.

  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Campo             Tipo              Obligatorio       Significado
  ----------------- ----------------- ----------------- -------------------------------------------------------------------------------------------------------------------------------------------------------------------
  `vis_id`          UUID              sí                Referencia a visita(vis_id).

  `lot_id`          entero            sí                Referencia a lote(lot_id).

  `pre_id`          entero            sí                Predio de la visita. Forma parte de las FK compuestas (vis_id, pre_id) hacia visita y (lot_id, pre_id) hacia lote: el lote visitado debe ser del predio visitado.
  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

**Identificación.** Clave primaria: `vis_id, lot_id`.

**Se relaciona con:** `lot_id, pre_id` → `lote`; `vis_id, pre_id` → `visita`.

**Disparadores:** `trg_visita_lote_ro (fn_bloquear_modificacion)`.

### `lectura_trampa`

**Para qué sirve.** Lectura de una trampa en una fecha (RF-020). Append-only: corregir = nueva versión con el mismo lec_registro_id; anular = versión con lec_anulada. lec_especimenes = total capturado SIN especie (la determinación de la especie queda fuera de este diseño: se retiró el módulo de laboratorio); NULL cuando la trampa no se leyó (lec_leida=false, p. ej. no encontrada) para no confundir "no leída" con "cero capturas" en el MTD. ubi_id fija la asignación trampa--lote vigente al observar (trazabilidad ADR-06; nulo = sin asignación, no entra al MTD, RN-013).

  -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Campo                          Tipo                    Obligatorio       Significado
  ------------------------------ ----------------------- ----------------- ----------------------------------------------------------------------------------------------------------------------------------------------------
  `lec_id`                       UUID                    sí                Identificador del registro (clave primaria).

  `lec_registro_id`              UUID                    sí                Identificador lógico del registro: igual en todas sus versiones (el cliente lo genera, UUID v7).

  `lec_version`                  entero                  sí                Número de versión del registro: 1 = alta; n+1 = corrección. Append-only (ADR-03).

  `vis_id`                       UUID                    sí                Referencia a visita(vis_id).

  `tra_id`                       entero                  sí                Trampa leída. Forma parte de la FK compuesta (ubi_id, tra_id) hacia ubicacion_trampa, que garantiza que la ubicación pertenece a esa trampa.

  `ubi_id`                       entero largo            no                Referencia a ubicacion_trampa(ubi_id).

  `lec_leida`                    sí/no                   sí                Verdadero si la trampa se leyó; falso si no (p. ej. no encontrada). Distingue "no leída" de "cero capturas".

  `lec_especimenes`              entero                  no                \[ud: especímenes (individuos)\] Número de moscas capturadas. Nulo si lec_leida = false.

  `lec_justificacion`            texto                   no                Motivo por el que la trampa no se leyó (obligatorio si lec_leida = falso).

  `con_id`                       entero                  sí                Referencia a condicion_trampa(con_id).

  `lec_fecha_cambio_cuerpo`      fecha                   no                Fecha de cambio del cuerpo de la trampa informada en esta lectura (RF-021).

  `lec_fecha_cambio_atrayente`   fecha                   no                Fecha de cambio de atrayente informada en esta lectura (RF-021). Requiere atr_id.

  `atr_id`                       entero                  no                Referencia a atrayente(atr_id).

  `lec_observaciones`            texto                   no                Observaciones libres del técnico.

  `lec_geom`                     geometría(Point,4326)   no                Posición GPS del dispositivo al leer (evidencia de RF-012). Opcional.

  `lec_precision_m`              decimal                 no                \[ud: m\] Precisión horizontal reportada por el GPS al leer.

  `lec_coincide_lote`            sí/no                   no                Resultado de la comparación trampa--lote--ubicación hecha por el dispositivo (RF-012). Falso = hubo advertencia y el usuario confirmó; no bloquea.

  `lec_linaje`                   sigat.d_linaje          sí                Linaje del dato (RN-014): inspeccion_oficial o autorreporte.

  `usu_id`                       entero                  sí                Usuario que realizó/capturó la acción.

  `dis_id`                       UUID                    sí                Dispositivo que capturó el registro.

  `ope_id`                       entero largo            sí                Operación de sincronización que creó el registro (idempotencia y trazabilidad).

  `lec_t_observacion`            fecha y hora            sí                Momento en que ocurrió lo observado (ADR-02); orden canónico del registro. Inmutable entre versiones (RN-009).

  `lec_t_captura`                fecha y hora            sí                Momento en que el dato se guardó, según el reloj del dispositivo (no puede ser anterior a t_observacion).

  `lec_t_sincronizacion`         fecha y hora            sí                Momento en que el servidor recibió el dato (reloj del servidor, asignado por trigger; el cliente no lo controla).

  `lec_deriva_reloj_seg`         entero                  no                \[ud: s\] Diferencia detectada entre el reloj del dispositivo y el del servidor (RDD-010); nulo si no se detectó.

  `lec_anulada`                  sí/no                   sí                Verdadero si esta versión anula el registro. Los registros no se borran (RN-009).

  `lec_motivo_anulacion`         texto                   no                Motivo obligatorio cuando la versión es una anulación.
  -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

**Identificación.** Clave primaria: `lec_id`.

**Se relaciona con:** `atr_id` → `atrayente`; `con_id` → `condicion_trampa`; `dis_id` → `dispositivo`; `ope_id` → `operacion_sync`; `tra_id` → `trampa`; `ubi_id, tra_id` → `ubicacion_trampa`; `usu_id` → `usuario`; `vis_id` → `visita`.

**No se puede repetir:** (`ope_id`); (`lec_registro_id, lec_version`).

**Reglas que la base exige:** - `lectura_trampa_anulacion_coherente`: `(((NOT lec_anulada) OR ((lec_motivo_anulacion IS NOT NULL) AND (btrim((lec_motivo_anulacion)::text) <> ''::text))))` - `lectura_trampa_atrayente_coherente`: `(((lec_fecha_cambio_atrayente IS NULL) OR (atr_id IS NOT NULL)))` - `lectura_trampa_conteo_coherente`: `(((lec_leida AND (lec_especimenes IS NOT NULL) AND (lec_especimenes >= 0)) OR ((NOT lec_leida) AND (lec_especimenes IS NULL) AND (lec_justificacion IS NOT NULL) AND (btrim((lec_justificacion)::text) <> ''::text))))` - `lectura_trampa_precision_valida`: `(((lec_precision_m IS NULL) OR (lec_precision_m >= (0)::double precision)))` - `lectura_trampa_tiempos_validos`: `((lec_t_observacion <= lec_t_captura))` - `lectura_trampa_version_positiva`: `((lec_version >= 1))`

**Disparadores:** `trg_aud_lectura (fn_auditar)`, `trg_lectura_trampa_1_version (fn_registro_version_valida)`, `trg_lectura_trampa_2_valida (fn_lectura_valida)`, `trg_lectura_trampa_notruncate (fn_bloquear_truncate)`, `trg_lectura_trampa_ro (fn_bloquear_modificacion)`.

### `aplicacion_fitosanitaria`

**Para qué sirve.** RF-040/RDD-008: aplicación fitosanitaria por lote. Autorreporte: no alimenta el MTD ni el concepto (RN-014). Responsable: persona registrada o, si es externo, nombre libre (denormalización controlada por CHECK: al menos uno).

  ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Campo                      Tipo              Obligatorio       Significado
  -------------------------- ----------------- ----------------- ------------------------------------------------------------------------------------------------------------------------------------
  `apf_id`                   UUID              sí                Identificador del registro (clave primaria).

  `apf_registro_id`          UUID              sí                Identificador lógico del registro: igual en todas sus versiones (el cliente lo genera, UUID v7).

  `apf_version`              entero            sí                Número de versión del registro: 1 = alta; n+1 = corrección. Append-only (ADR-03).

  `lot_id`                   entero            sí                Referencia a lote(lot_id).

  `pfs_id`                   entero            no                Referencia a producto_fitosanitario(pfs_id).

  `apf_producto_texto`       texto             no                Nombre del producto escrito por el productor cuando no está en el catálogo (frontend: campo libre). Obligatorio si pfs_id es nulo.

  `apf_dosis`                número(12,4)      sí                Dosis con unidad en apf_dosis_uni_id (RN-017). Las unidades admitidas están por definir (pendiente).

  `apf_dosis_uni_id`         entero            sí                Referencia a unidad_medida(uni_id).

  `apf_area_tratada`         número(12,4)      sí                Área tratada con unidad en apf_area_uni_id (normalmente ha).

  `apf_area_uni_id`          entero            sí                Referencia a unidad_medida(uni_id).

  `per_cc_responsable`       entero largo      no                Referencia a persona(per_cc).

  `apf_responsable_nombre`   texto             no                Nombre del responsable cuando es una persona no registrada (externo). Obligatorio si per_cc_responsable es nulo.

  `apf_observaciones`        texto             no                Observaciones libres del productor sobre la aplicación.

  `apf_linaje`               sigat.d_linaje    sí                Linaje del dato (RN-014): inspeccion_oficial o autorreporte.

  `usu_id`                   entero            sí                Usuario que realizó/capturó la acción.

  `dis_id`                   UUID              sí                Dispositivo que capturó el registro.

  `ope_id`                   entero largo      sí                Operación de sincronización que creó el registro (idempotencia y trazabilidad).

  `apf_t_observacion`        fecha y hora      sí                Momento en que ocurrió lo observado (ADR-02); orden canónico del registro. Inmutable entre versiones (RN-009).

  `apf_t_captura`            fecha y hora      sí                Momento en que el dato se guardó, según el reloj del dispositivo (no puede ser anterior a t_observacion).

  `apf_t_sincronizacion`     fecha y hora      sí                Momento en que el servidor recibió el dato (reloj del servidor, asignado por trigger; el cliente no lo controla).

  `apf_deriva_reloj_seg`     entero            no                \[ud: s\] Diferencia detectada entre el reloj del dispositivo y el del servidor (RDD-010); nulo si no se detectó.

  `apf_anulada`              sí/no             sí                Verdadero si esta versión anula el registro. Los registros no se borran (RN-009).

  `apf_motivo_anulacion`     texto             no                Motivo obligatorio cuando la versión es una anulación.
  ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

**Identificación.** Clave primaria: `apf_id`.

**Se relaciona con:** `apf_area_uni_id` → `unidad_medida`; `dis_id` → `dispositivo`; `apf_dosis_uni_id` → `unidad_medida`; `lot_id` → `lote`; `ope_id` → `operacion_sync`; `pfs_id` → `producto_fitosanitario`; `per_cc_responsable` → `persona`; `usu_id` → `usuario`.

**No se puede repetir:** (`ope_id`); (`apf_registro_id, apf_version`).

**Reglas que la base exige:** - `aplicacion_fitosanitaria_anulacion_coherente`: `(((NOT apf_anulada) OR ((apf_motivo_anulacion IS NOT NULL) AND (btrim((apf_motivo_anulacion)::text) <> ''::text))))` - `aplicacion_fitosanitaria_area_positiva`: `((apf_area_tratada > (0)::numeric))` - `aplicacion_fitosanitaria_dosis_positiva`: `((apf_dosis > (0)::numeric))` - `aplicacion_fitosanitaria_producto_presente`: `(((pfs_id IS NOT NULL) OR ((apf_producto_texto IS NOT NULL) AND (btrim((apf_producto_texto)::text) <> ''::text))))` - `aplicacion_fitosanitaria_responsable_presente`: `(((per_cc_responsable IS NOT NULL) OR ((apf_responsable_nombre IS NOT NULL) AND (btrim((apf_responsable_nombre)::text) <> ''::text))))` - `aplicacion_fitosanitaria_tiempos_validos`: `((apf_t_observacion <= apf_t_captura))` - `aplicacion_fitosanitaria_version_positiva`: `((apf_version >= 1))`

**Disparadores:** `trg_aplicacion_fitosanitaria_1_version (fn_registro_version_valida)`, `trg_aplicacion_fitosanitaria_notruncate (fn_bloquear_truncate)`, `trg_aplicacion_fitosanitaria_ro (fn_bloquear_modificacion)`, `trg_aud_aplicacion (fn_auditar)`.

### `cosecha`

**Para qué sirve.** RF-042/RDD-009: un único registro de cosecha con dos componentes (esperado y real). El componente real es completo o ausente (CHECK). Ambos volúmenes comparten la unidad cos_volumen_uni_id (RN-017). Autorreporte (RN-014).

  --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Campo                    Tipo              Obligatorio       Significado
  ------------------------ ----------------- ----------------- -------------------------------------------------------------------------------------------------------------------------
  `cos_id`                 UUID              sí                Identificador del registro (clave primaria).

  `cos_registro_id`        UUID              sí                Identificador lógico del registro: igual en todas sus versiones (el cliente lo genera, UUID v7).

  `cos_version`            entero            sí                Número de versión del registro: 1 = alta; n+1 = corrección. Append-only (ADR-03).

  `lot_id`                 entero            sí                Referencia a lote(lot_id).

  `cos_fecha_esperada`     fecha             sí                Fecha esperada de cosecha.

  `cos_volumen_esperado`   número(14,3)      sí                Volumen esperado, en la unidad cos_volumen_uni_id.

  `cos_fecha_real`         fecha             no                Fecha en que realmente se cosechó; nula mientras no se coseche.

  `cos_volumen_real`       número(14,3)      no                Volumen realmente recolectado, en cos_volumen_uni_id; nulo mientras no se coseche.

  `cos_volumen_uni_id`     entero            sí                Referencia a unidad_medida(uni_id).

  `cos_metodo_registro`    texto             no                Método de registro (RDD-009). Vocabulario no definido en la documentación: texto libre hasta que se defina (pendiente).

  `cos_observaciones`      texto             no                Observaciones libres.

  `cos_linaje`             sigat.d_linaje    sí                Linaje del dato (RN-014): inspeccion_oficial o autorreporte.

  `usu_id`                 entero            sí                Usuario que realizó/capturó la acción.

  `dis_id`                 UUID              sí                Dispositivo que capturó el registro.

  `ope_id`                 entero largo      sí                Operación de sincronización que creó el registro (idempotencia y trazabilidad).

  `cos_t_observacion`      fecha y hora      sí                Momento en que ocurrió lo observado (ADR-02); orden canónico del registro. Inmutable entre versiones (RN-009).

  `cos_t_captura`          fecha y hora      sí                Momento en que el dato se guardó, según el reloj del dispositivo (no puede ser anterior a t_observacion).

  `cos_t_sincronizacion`   fecha y hora      sí                Momento en que el servidor recibió el dato (reloj del servidor, asignado por trigger; el cliente no lo controla).

  `cos_deriva_reloj_seg`   entero            no                \[ud: s\] Diferencia detectada entre el reloj del dispositivo y el del servidor (RDD-010); nulo si no se detectó.

  `cos_anulada`            sí/no             sí                Verdadero si esta versión anula el registro. Los registros no se borran (RN-009).

  `cos_motivo_anulacion`   texto             no                Motivo obligatorio cuando la versión es una anulación.
  --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

**Identificación.** Clave primaria: `cos_id`.

**Se relaciona con:** `dis_id` → `dispositivo`; `lot_id` → `lote`; `ope_id` → `operacion_sync`; `usu_id` → `usuario`; `cos_volumen_uni_id` → `unidad_medida`.

**No se puede repetir:** (`ope_id`); (`cos_registro_id, cos_version`).

**Reglas que la base exige:** - `cosecha_anulacion_coherente`: `(((NOT cos_anulada) OR ((cos_motivo_anulacion IS NOT NULL) AND (btrim((cos_motivo_anulacion)::text) <> ''::text))))` - `cosecha_real_completa`: `(((cos_fecha_real IS NULL) = (cos_volumen_real IS NULL)))` - `cosecha_tiempos_validos`: `((cos_t_observacion <= cos_t_captura))` - `cosecha_version_positiva`: `((cos_version >= 1))` - `cosecha_volumenes_validos`: `(((cos_volumen_esperado >= (0)::numeric) AND ((cos_volumen_real IS NULL) OR (cos_volumen_real >= (0)::numeric))))`

**Disparadores:** `trg_aud_cosecha (fn_auditar)`, `trg_cosecha_1_version (fn_registro_version_valida)`, `trg_cosecha_notruncate (fn_bloquear_truncate)`, `trg_cosecha_ro (fn_bloquear_modificacion)`.

### `etapa_declarada`

**Para qué sirve.** RF-044 / RN-012: etapa fenológica DECLARADA por el productor o el técnico, con fecha, valor y autor. La etapa derivada se calcula (fenologia_regla + fecha de plantación) y se compara en la vista v_etapa_discrepancia.

  --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Campo                    Tipo              Obligatorio       Significado
  ------------------------ ----------------- ----------------- -------------------------------------------------------------------------------------------------------------------
  `etd_id`                 UUID              sí                Identificador del registro (clave primaria).

  `etd_registro_id`        UUID              sí                Identificador lógico del registro: igual en todas sus versiones (el cliente lo genera, UUID v7).

  `etd_version`            entero            sí                Número de versión del registro: 1 = alta; n+1 = corrección. Append-only (ADR-03).

  `lot_id`                 entero            sí                Referencia a lote(lot_id).

  `fen_id`                 entero            sí                Referencia a fenologia(fen_id).

  `etd_linaje`             sigat.d_linaje    sí                Linaje del dato (RN-014): inspeccion_oficial o autorreporte.

  `usu_id`                 entero            sí                Usuario que realizó/capturó la acción.

  `dis_id`                 UUID              sí                Dispositivo que capturó el registro.

  `ope_id`                 entero largo      sí                Operación de sincronización que creó el registro (idempotencia y trazabilidad).

  `etd_t_observacion`      fecha y hora      sí                Momento en que ocurrió lo observado (ADR-02); orden canónico del registro. Inmutable entre versiones (RN-009).

  `etd_t_captura`          fecha y hora      sí                Momento en que el dato se guardó, según el reloj del dispositivo (no puede ser anterior a t_observacion).

  `etd_t_sincronizacion`   fecha y hora      sí                Momento en que el servidor recibió el dato (reloj del servidor, asignado por trigger; el cliente no lo controla).

  `etd_deriva_reloj_seg`   entero            no                \[ud: s\] Diferencia detectada entre el reloj del dispositivo y el del servidor (RDD-010); nulo si no se detectó.

  `etd_anulada`            sí/no             sí                Verdadero si esta versión anula el registro. Los registros no se borran (RN-009).

  `etd_motivo_anulacion`   texto             no                Motivo obligatorio cuando la versión es una anulación.
  --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

**Identificación.** Clave primaria: `etd_id`.

**Se relaciona con:** `dis_id` → `dispositivo`; `fen_id` → `fenologia`; `lot_id` → `lote`; `ope_id` → `operacion_sync`; `usu_id` → `usuario`.

**No se puede repetir:** (`ope_id`); (`etd_registro_id, etd_version`).

**Reglas que la base exige:** - `etapa_declarada_anulacion_coherente`: `(((NOT etd_anulada) OR ((etd_motivo_anulacion IS NOT NULL) AND (btrim((etd_motivo_anulacion)::text) <> ''::text))))` - `etapa_declarada_tiempos_validos`: `((etd_t_observacion <= etd_t_captura))` - `etapa_declarada_version_positiva`: `((etd_version >= 1))`

**Disparadores:** `trg_aud_etapa (fn_auditar)`, `trg_etapa_declarada_1_version (fn_registro_version_valida)`, `trg_etapa_declarada_notruncate (fn_bloquear_truncate)`, `trg_etapa_declarada_ro (fn_bloquear_modificacion)`.

## 9. MTD, periodos y concepto de aptitud

El resultado fitosanitario. El **MTD** (moscas por trampa por día) se calcula en el servidor para cada periodo de trampeo y se contrasta con el umbral. El **concepto de aptitud** guarda el resultado oficial por lote. Mientras el ICA no defina el umbral de exportación, el concepto queda en «no emitido»: la base no inventa valores.

### `periodo_trampeo`

**Para qué sirve.** RF-022: periodo de trampeo de un lote y tipo de muestreo (ventana \[inicio, fin\]). Dos periodos del mismo lote y tipo no se solapan (RN-011: una lectura dentro de una ventana ya cubierta se marca "revisar"). pri_id fija la versión de programa aplicable a la fecha del periodo (RN-003).

  ----------------------------------------------------------------------------------------------------
  Campo             Tipo              Obligatorio       Significado
  ----------------- ----------------- ----------------- ----------------------------------------------
  `ptr_id`          entero largo      sí                Identificador del registro (clave primaria).

  `lot_id`          entero            sí                Referencia a lote(lot_id).

  `vig_id`          entero            sí                Referencia a vigilancia(vig_id).

  `pri_id`          entero            sí                Referencia a programa_inspeccion(pri_id).

  `ptr_inicio`      fecha             sí                Primer día del periodo (inclusive).

  `ptr_fin`         fecha             sí                Último día del periodo (inclusive).

  `ptr_estado`      texto             sí                abierto (aún recibe lecturas) o cerrado.

  `ptr_creado_en`   fecha y hora      sí                Momento en que se creó el periodo.
  ----------------------------------------------------------------------------------------------------

**Identificación.** Clave primaria: `ptr_id`.

**Se relaciona con:** `lot_id` → `lote`; `pri_id` → `programa_inspeccion`; `vig_id` → `vigilancia`.

**No se puede repetir:** (`ptr_id, lot_id`).

**Reglas que la base exige:** - `periodo_trampeo_estado_valido`: `(((ptr_estado)::text = ANY ((ARRAY['abierto'::character varying, 'cerrado'::character varying])::text[])))` - `periodo_trampeo_rango_valido`: `((ptr_fin >= ptr_inicio))`

**Disparadores:** `trg_periodo_valida (fn_periodo_valida)`.

### `indice_mtd`

**Para qué sirve.** RDD-006 / RN-001: MTD = M / (T × D) por periodo y especie (esm_id nulo = total sin especie diagnosticada; qué se emite en el MVP queda pendiente). M, T y D se guardan junto al resultado para trazabilidad; mtd_valor es columna GENERADA (la fórmula vive en la base y no puede divergir). El umbral y la norma aplicados se copian (instantánea) para que un cambio de umbral no altere resultados históricos (RDD-007). Append-only: el recálculo crea una versión nueva con motivo.

  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Campo                       Tipo                          Obligatorio       Significado
  --------------------------- ----------------------------- ----------------- ---------------------------------------------------------------------------------------------------------------------------------------
  `mtd_id`                    entero largo                  sí                Identificador del registro (clave primaria).

  `ptr_id`                    entero largo                  sí                Referencia a periodo_trampeo(ptr_id).

  `esm_id`                    entero                        no                Referencia a especie_mosca(esm_id).

  `mtd_version`               entero                        sí                Número de versión del registro: 1 = alta; n+1 = corrección. Append-only (ADR-03).

  `mtd_moscas`                entero                        sí                \[ud: moscas\] M = total de moscas capturadas en las trampas atendidas.

  `mtd_trampas`               entero                        sí                \[ud: trampas\] T = número de trampas atendidas.

  `mtd_dias_exposicion`       número(8,3)                   sí                \[ud: días\] D = número promedio de días de exposición de las trampas.

  `mtd_valor`                 número(14,6)                  no                \[ud: moscas/trampa/día\] Nulo si T×D = 0.

  `mtd_unidad`                texto                         sí                Unidad fija del MTD: moscas/trampa/día (RN-017).

  `mtd_umbral_aplicado`       número(10,4)                  no                \[ud: moscas/trampa/día\] Umbral de exportación vigente a la fecha del periodo (copia). Nulo = no había umbral configurado (UQQ-004).

  `nor_id`                    entero                        no                Referencia a norma(nor_id).

  `mtd_resultado_contraste`   sigat.d_resultado_contraste   sí                Resultado de contrastar el MTD con el umbral vigente (RF-024).

  `esq_id`                    entero                        no                Escenario de trampeo (RN-002) en que cae el MTD, si el programa tiene límites configurados.

  `mtd_calculado_en`          fecha y hora                  sí                Momento (servidor) en que se calculó esta versión.

  `mtd_motivo_recalculo`      texto                         no                Motivo del recálculo (obligatorio desde la versión 2), p. ej. llegada de una lectura retroactiva.
  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

**Identificación.** Clave primaria: `mtd_id`.

**Se relaciona con:** `esm_id` → `especie_mosca`; `esq_id` → `escenario_trampeo`; `nor_id` → `norma`; `ptr_id` → `periodo_trampeo`.

**No se puede repetir:** (`mtd_id, ptr_id`).

**Reglas que la base exige:** - `indice_mtd_componentes_validos`: `(((mtd_moscas >= 0) AND (mtd_trampas >= 0) AND (mtd_dias_exposicion >= (0)::numeric)))` - `indice_mtd_contraste_coherente`: `(((((mtd_resultado_contraste)::text = 'sin_umbral'::text) AND (mtd_umbral_aplicado IS NULL) AND (nor_id IS NULL)) OR (((mtd_resultado_contraste)::text <> 'sin_umbral'::text) AND (mtd_umbral_aplicado IS NOT NULL) AND (nor_id IS NOT` - `indice_mtd_recalculo_motivado`: `(((mtd_version = 1) OR ((mtd_motivo_recalculo IS NOT NULL) AND (btrim((mtd_motivo_recalculo)::text) <> ''::text))))` - `indice_mtd_umbral_valido`: `(((mtd_umbral_aplicado IS NULL) OR (mtd_umbral_aplicado >= (0)::numeric)))` - `indice_mtd_unidad_fija`: `(((mtd_unidad)::text = 'moscas/trampa/día'::text))` - `indice_mtd_version_positiva`: `((mtd_version >= 1))`

**Disparadores:** `trg_aud_indice_mtd (fn_auditar)`, `trg_indice_mtd_notruncate (fn_bloquear_truncate)`, `trg_indice_mtd_ro (fn_bloquear_modificacion)`.

### `indice_mtd_lectura`

**Para qué sirve.** Trazabilidad N:M: qué versiones exactas de lectura sustentan cada MTD (RN-013: el conjunto de trampas que sustenta un MTD queda determinado de forma explícita). Permite saber qué MTD se ven afectados cuando llega una corrección retroactiva (RF-054).

  --------------------------------------------------------------------------------------------
  Campo             Tipo              Obligatorio       Significado
  ----------------- ----------------- ----------------- --------------------------------------
  `mtd_id`          entero largo      sí                Referencia a indice_mtd(mtd_id).

  `lec_id`          UUID              sí                Referencia a lectura_trampa(lec_id).
  --------------------------------------------------------------------------------------------

**Identificación.** Clave primaria: `mtd_id, lec_id`.

**Se relaciona con:** `lec_id` → `lectura_trampa`; `mtd_id` → `indice_mtd`.

**Disparadores:** `trg_indice_mtd_lectura_ro (fn_bloquear_modificacion)`, `trg_indice_mtd_lectura_valida (fn_mtd_lectura_valida)`.

### `concepto_aptitud`

**Para qué sirve.** RF-024/RF-054: concepto de aptitud del lote por periodo, con norma aplicada y fecha de efecto; las reemisiones son versiones nuevas (no se sobrescribe). "no_emitido" cuando no hay umbral configurado (UQQ-004): el sistema no inventa el valor.

  ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Campo                Tipo              Obligatorio       Significado
  -------------------- ----------------- ----------------- -------------------------------------------------------------------------------------------------------------------------------------------------
  `cap_id`             entero largo      sí                Identificador del registro (clave primaria).

  `lot_id`             entero            sí                Lote evaluado. Forma parte de la FK compuesta (ptr_id, lot_id) hacia periodo_trampeo y de la FK hacia lote: el periodo debe ser del mismo lote.

  `ptr_id`             entero largo      sí                Periodo de trampeo evaluado. Forma parte de las FK compuestas (ptr_id, lot_id) hacia periodo_trampeo y (mtd_id, ptr_id) hacia indice_mtd.

  `mtd_id`             entero largo      sí                Referencia a indice_mtd(mtd_id).

  `cap_version`        entero            sí                Número de versión del registro: 1 = alta; n+1 = corrección. Append-only (ADR-03).

  `cap_resultado`      texto             sí                apto, no_apto o no_emitido (no_emitido = sin umbral configurado, UQQ-004).

  `cap_fecha_efecto`   fecha             sí                Fecha desde la cual rige el concepto emitido (en una reemisión por corrección retroactiva puede ser anterior a la fecha de emisión).

  `nor_id`             entero            no                Referencia a norma(nor_id).

  `cap_emitido_en`     fecha y hora      sí                Momento (servidor) en que se emitió esta versión del concepto.

  `cap_motivo`         texto             no                Motivo de la reemisión (obligatorio desde la versión 2).
  ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

**Identificación.** Clave primaria: `cap_id`.

**Se relaciona con:** `lot_id` → `lote`; `mtd_id, ptr_id` → `indice_mtd`; `nor_id` → `norma`; `ptr_id, lot_id` → `periodo_trampeo`.

**No se puede repetir:** (`lot_id, ptr_id, cap_version`).

**Reglas que la base exige:** - `concepto_aptitud_norma_requerida`: `((((cap_resultado)::text = 'no_emitido'::text) = (nor_id IS NULL)))` - `concepto_aptitud_reemision_motivada`: `(((cap_version = 1) OR ((cap_motivo IS NOT NULL) AND (btrim((cap_motivo)::text) <> ''::text))))` - `concepto_aptitud_resultado_valido`: `(((cap_resultado)::text = ANY ((ARRAY['apto'::character varying, 'no_apto'::character varying, 'no_emitido'::character varying])::text[])))` - `concepto_aptitud_version_positiva`: `((cap_version >= 1))`

**Disparadores:** `trg_aud_concepto (fn_auditar)`, `trg_concepto_aptitud_notruncate (fn_bloquear_truncate)`, `trg_concepto_aptitud_ro (fn_bloquear_modificacion)`, `trg_concepto_valida (fn_concepto_valida)`.

## 10. Fase 2: plagas, hallazgos, BPA, producción, manejo

Funciones de una segunda etapa: hallazgos de plagas y enfermedades marcados en el mapa, verificación de buenas prácticas agrícolas (BPA), estimación de producción y manejo agronómico.

### `plaga_enfermedad`

**Para qué sirve.** Catálogo configurable de plagas, enfermedades y hongos (RF-029, RF-081). Sin valores oficiales en la documentación.

  ---------------------------------------------------------------------------------------------------------------------
  Campo               Tipo              Obligatorio       Significado
  ------------------- ----------------- ----------------- -------------------------------------------------------------
  `ple_id`            entero            sí                Identificador del registro (clave primaria).

  `ple_descripcion`   texto             sí                Texto descriptivo del valor del catálogo (único, no vacío).

  `ple_tipo`          texto             sí                plaga, enfermedad u hongo (RF-029).
  ---------------------------------------------------------------------------------------------------------------------

**Identificación.** Clave primaria: `ple_id`.

**No se puede repetir:** (`ple_descripcion`).

**Reglas que la base exige:** - `plaga_enfermedad_descripcion_no_vacia`: `((btrim((ple_descripcion)::text) <> ''::text))` - `plaga_enfermedad_tipo_valido`: `(((ple_tipo)::text = ANY ((ARRAY['plaga'::character varying, 'enfermedad'::character varying, 'hongo'::character varying])::text[])))`

### `severidad`

**Para qué sirve.** Escala de severidad declarada de un hallazgo (RF-029). Escala no definida en la documentación: la carga el Administrador.

  ---------------------------------------------------------------------------------------------------------------------
  Campo               Tipo              Obligatorio       Significado
  ------------------- ----------------- ----------------- -------------------------------------------------------------
  `sev_id`            entero            sí                Identificador del registro (clave primaria).

  `sev_descripcion`   texto             sí                Texto descriptivo del valor del catálogo (único, no vacío).

  `sev_orden`         entero corto      sí                Orden ascendente de gravedad (único).
  ---------------------------------------------------------------------------------------------------------------------

**Identificación.** Clave primaria: `sev_id`.

**No se puede repetir:** (`sev_descripcion`); (`sev_orden`).

**Reglas que la base exige:** - `severidad_descripcion_no_vacia`: `((btrim((sev_descripcion)::text) <> ''::text))`

### `hallazgo`

**Para qué sirve.** RF-029 / RDD-012: hallazgo fitosanitario (plaga, enfermedad u hongo) observado en un lote, con celda opcional y punto opcional (el marcado geográfico preciso RF-010 se difiere a v0.4, X-05).

  --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Campo                    Tipo                    Obligatorio       Significado
  ------------------------ ----------------------- ----------------- -------------------------------------------------------------------------------------------------------------------
  `hal_id`                 UUID                    sí                Identificador del registro (clave primaria).

  `hal_registro_id`        UUID                    sí                Identificador lógico del registro: igual en todas sus versiones (el cliente lo genera, UUID v7).

  `hal_version`            entero                  sí                Número de versión del registro: 1 = alta; n+1 = corrección. Append-only (ADR-03).

  `lot_id`                 entero                  sí                Referencia a lote(lot_id).

  `rce_id`                 entero largo            no                Referencia a reticula_celda(rce_id).

  `ple_id`                 entero                  sí                Referencia a plaga_enfermedad(ple_id).

  `sev_id`                 entero                  sí                Referencia a severidad(sev_id).

  `hal_geom`               geometría(Point,4326)   no                Punto del hallazgo en el mapa (opcional; el marcado preciso RF-010 se difiere a v0.4).

  `hal_observaciones`      texto                   no                Observaciones libres del hallazgo.

  `hal_linaje`             sigat.d_linaje          sí                Linaje del dato (RN-014): inspeccion_oficial o autorreporte.

  `usu_id`                 entero                  sí                Usuario que realizó/capturó la acción.

  `dis_id`                 UUID                    sí                Dispositivo que capturó el registro.

  `ope_id`                 entero largo            sí                Operación de sincronización que creó el registro (idempotencia y trazabilidad).

  `hal_t_observacion`      fecha y hora            sí                Momento en que ocurrió lo observado (ADR-02); orden canónico del registro. Inmutable entre versiones (RN-009).

  `hal_t_captura`          fecha y hora            sí                Momento en que el dato se guardó, según el reloj del dispositivo (no puede ser anterior a t_observacion).

  `hal_t_sincronizacion`   fecha y hora            sí                Momento en que el servidor recibió el dato (reloj del servidor, asignado por trigger; el cliente no lo controla).

  `hal_deriva_reloj_seg`   entero                  no                \[ud: s\] Diferencia detectada entre el reloj del dispositivo y el del servidor (RDD-010); nulo si no se detectó.

  `hal_anulada`            sí/no                   sí                Verdadero si esta versión anula el registro. Los registros no se borran (RN-009).

  `hal_motivo_anulacion`   texto                   no                Motivo obligatorio cuando la versión es una anulación.
  --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

**Identificación.** Clave primaria: `hal_id`.

**Se relaciona con:** `dis_id` → `dispositivo`; `lot_id` → `lote`; `ope_id` → `operacion_sync`; `ple_id` → `plaga_enfermedad`; `rce_id` → `reticula_celda`; `sev_id` → `severidad`; `usu_id` → `usuario`.

**No se puede repetir:** (`ope_id`); (`hal_registro_id, hal_version`).

**Reglas que la base exige:** - `hallazgo_anulacion_coherente`: `(((NOT hal_anulada) OR ((hal_motivo_anulacion IS NOT NULL) AND (btrim((hal_motivo_anulacion)::text) <> ''::text))))` - `hallazgo_tiempos_validos`: `((hal_t_observacion <= hal_t_captura))` - `hallazgo_version_positiva`: `((hal_version >= 1))`

**Disparadores:** `trg_aud_hallazgo (fn_auditar)`, `trg_hallazgo_1_version (fn_registro_version_valida)`, `trg_hallazgo_2_valida (fn_hallazgo_valida)`, `trg_hallazgo_notruncate (fn_bloquear_truncate)`, `trg_hallazgo_ro (fn_bloquear_modificacion)`.

### `criterio_bpa`

**Para qué sirve.** Criterio del checklist de Buenas Prácticas Agrícolas (RF-028, RF-081). Sin valores oficiales en la documentación.

  ---------------------------------------------------------------------------------------------------------------------
  Campo               Tipo              Obligatorio       Significado
  ------------------- ----------------- ----------------- -------------------------------------------------------------
  `cbp_id`            entero            sí                Identificador del registro (clave primaria).

  `cbp_descripcion`   texto             sí                Texto descriptivo del valor del catálogo (único, no vacío).

  `cbp_activo`        sí/no             sí                Falso = criterio retirado del catálogo.
  ---------------------------------------------------------------------------------------------------------------------

**Identificación.** Clave primaria: `cbp_id`.

**No se puede repetir:** (`cbp_descripcion`).

**Reglas que la base exige:** - `criterio_bpa_descripcion_no_vacia`: `((btrim((cbp_descripcion)::text) <> ''::text))`

### `programa_criterio_bpa`

**Para qué sirve.** N:M: checklist de BPA vigente en cada versión del programa de inspección (RF-003, RF-080).

  -------------------------------------------------------------------------------------------------
  Campo             Tipo              Obligatorio       Significado
  ----------------- ----------------- ----------------- -------------------------------------------
  `pri_id`          entero            sí                Referencia a programa_inspeccion(pri_id).

  `cbp_id`          entero            sí                Referencia a criterio_bpa(cbp_id).
  -------------------------------------------------------------------------------------------------

**Identificación.** Clave primaria: `pri_id, cbp_id`.

**Se relaciona con:** `cbp_id` → `criterio_bpa`; `pri_id` → `programa_inspeccion`.

### `bpa_verificacion`

**Para qué sirve.** RF-028 / RDD-012: resultado de cada criterio de BPA por lote y por visita (cumplimiento + observación). Evidencia fotográfica opcional: diferida (X-03).

  --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Campo                    Tipo              Obligatorio       Significado
  ------------------------ ----------------- ----------------- -------------------------------------------------------------------------------------------------------------------
  `bpv_id`                 UUID              sí                Identificador del registro (clave primaria).

  `bpv_registro_id`        UUID              sí                Identificador lógico del registro: igual en todas sus versiones (el cliente lo genera, UUID v7).

  `bpv_version`            entero            sí                Número de versión del registro: 1 = alta; n+1 = corrección. Append-only (ADR-03).

  `vis_id`                 UUID              sí                Referencia a visita_lote(vis_id).

  `lot_id`                 entero            sí                Referencia a visita_lote(lot_id).

  `cbp_id`                 entero            sí                Referencia a criterio_bpa(cbp_id).

  `bpv_cumple`             sí/no             sí                Resultado del criterio de BPA en el lote y la visita: cumple (verdadero) o no cumple.

  `bpv_observacion`        texto             no                Observación del inspector sobre el criterio.

  `bpv_linaje`             sigat.d_linaje    sí                Linaje del dato (RN-014): inspeccion_oficial o autorreporte.

  `usu_id`                 entero            sí                Usuario que realizó/capturó la acción.

  `dis_id`                 UUID              sí                Dispositivo que capturó el registro.

  `ope_id`                 entero largo      sí                Operación de sincronización que creó el registro (idempotencia y trazabilidad).

  `bpv_t_observacion`      fecha y hora      sí                Momento en que ocurrió lo observado (ADR-02); orden canónico del registro. Inmutable entre versiones (RN-009).

  `bpv_t_captura`          fecha y hora      sí                Momento en que el dato se guardó, según el reloj del dispositivo (no puede ser anterior a t_observacion).

  `bpv_t_sincronizacion`   fecha y hora      sí                Momento en que el servidor recibió el dato (reloj del servidor, asignado por trigger; el cliente no lo controla).

  `bpv_deriva_reloj_seg`   entero            no                \[ud: s\] Diferencia detectada entre el reloj del dispositivo y el del servidor (RDD-010); nulo si no se detectó.

  `bpv_anulada`            sí/no             sí                Verdadero si esta versión anula el registro. Los registros no se borran (RN-009).

  `bpv_motivo_anulacion`   texto             no                Motivo obligatorio cuando la versión es una anulación.
  --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

**Identificación.** Clave primaria: `bpv_id`.

**Se relaciona con:** `cbp_id` → `criterio_bpa`; `dis_id` → `dispositivo`; `ope_id` → `operacion_sync`; `usu_id` → `usuario`; `vis_id, lot_id` → `visita_lote`.

**No se puede repetir:** (`ope_id`); (`bpv_registro_id, bpv_version`).

**Reglas que la base exige:** - `bpa_verificacion_anulacion_coherente`: `(((NOT bpv_anulada) OR ((bpv_motivo_anulacion IS NOT NULL) AND (btrim((bpv_motivo_anulacion)::text) <> ''::text))))` - `bpa_verificacion_tiempos_validos`: `((bpv_t_observacion <= bpv_t_captura))` - `bpa_verificacion_version_positiva`: `((bpv_version >= 1))`

**Disparadores:** `trg_aud_bpa (fn_auditar)`, `trg_bpa_verificacion_1_version (fn_registro_version_valida)`, `trg_bpa_verificacion_notruncate (fn_bloquear_truncate)`, `trg_bpa_verificacion_ro (fn_bloquear_modificacion)`.

### `estimacion_produccion`

**Para qué sirve.** RF-030: producción esperada de un lote = número de árboles × rendimiento por árbol (el total NO se almacena: es derivado; v_estimacion_total).

  ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Campo                      Tipo              Obligatorio       Significado
  -------------------------- ----------------- ----------------- -------------------------------------------------------------------------------------------------------------------
  `esp_id`                   UUID              sí                Identificador del registro (clave primaria).

  `esp_registro_id`          UUID              sí                Identificador lógico del registro: igual en todas sus versiones (el cliente lo genera, UUID v7).

  `esp_version`              entero            sí                Número de versión del registro: 1 = alta; n+1 = corrección. Append-only (ADR-03).

  `lot_id`                   entero            sí                Referencia a lote(lot_id).

  `esp_num_arboles`          entero            sí                \[ud: árboles\] Número de árboles considerados en la estimación.

  `esp_rendimiento_arbol`    número(12,3)      sí                Rendimiento esperado por árbol, en la unidad esp_rendimiento_uni_id (p. ej. kg por árbol).

  `esp_rendimiento_uni_id`   entero            sí                Referencia a unidad_medida(uni_id).

  `esp_metodo`               texto             sí                Método de estimación empleado (RF-030). Texto libre hasta definir vocabulario.

  `esp_linaje`               sigat.d_linaje    sí                Linaje del dato (RN-014): inspeccion_oficial o autorreporte.

  `usu_id`                   entero            sí                Usuario que realizó/capturó la acción.

  `dis_id`                   UUID              sí                Dispositivo que capturó el registro.

  `ope_id`                   entero largo      sí                Operación de sincronización que creó el registro (idempotencia y trazabilidad).

  `esp_t_observacion`        fecha y hora      sí                Momento en que ocurrió lo observado (ADR-02); orden canónico del registro. Inmutable entre versiones (RN-009).

  `esp_t_captura`            fecha y hora      sí                Momento en que el dato se guardó, según el reloj del dispositivo (no puede ser anterior a t_observacion).

  `esp_t_sincronizacion`     fecha y hora      sí                Momento en que el servidor recibió el dato (reloj del servidor, asignado por trigger; el cliente no lo controla).

  `esp_deriva_reloj_seg`     entero            no                \[ud: s\] Diferencia detectada entre el reloj del dispositivo y el del servidor (RDD-010); nulo si no se detectó.

  `esp_anulada`              sí/no             sí                Verdadero si esta versión anula el registro. Los registros no se borran (RN-009).

  `esp_motivo_anulacion`     texto             no                Motivo obligatorio cuando la versión es una anulación.
  ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

**Identificación.** Clave primaria: `esp_id`.

**Se relaciona con:** `dis_id` → `dispositivo`; `lot_id` → `lote`; `ope_id` → `operacion_sync`; `esp_rendimiento_uni_id` → `unidad_medida`; `usu_id` → `usuario`.

**No se puede repetir:** (`ope_id`); (`esp_registro_id, esp_version`).

**Reglas que la base exige:** - `estimacion_produccion_anulacion_coherente`: `(((NOT esp_anulada) OR ((esp_motivo_anulacion IS NOT NULL) AND (btrim((esp_motivo_anulacion)::text) <> ''::text))))` - `estimacion_produccion_metodo_no_vacio`: `((btrim((esp_metodo)::text) <> ''::text))` - `estimacion_produccion_tiempos_validos`: `((esp_t_observacion <= esp_t_captura))` - `estimacion_produccion_valores_positivos`: `(((esp_num_arboles > 0) AND (esp_rendimiento_arbol > (0)::numeric)))` - `estimacion_produccion_version_positiva`: `((esp_version >= 1))`

**Disparadores:** `trg_aud_estimacion (fn_auditar)`, `trg_estimacion_produccion_1_version (fn_registro_version_valida)`, `trg_estimacion_produccion_notruncate (fn_bloquear_truncate)`, `trg_estimacion_produccion_ro (fn_bloquear_modificacion)`.

### `tipo_manejo`

**Para qué sirve.** Tipo de operación de manejo agronómico (RF-043: riego, fertilización, poda, thinning y renovación).

  ---------------------------------------------------------------------------------------------------------------------
  Campo               Tipo              Obligatorio       Significado
  ------------------- ----------------- ----------------- -------------------------------------------------------------
  `tim_id`            entero            sí                Identificador del registro (clave primaria).

  `tim_descripcion`   texto             sí                Texto descriptivo del valor del catálogo (único, no vacío).
  ---------------------------------------------------------------------------------------------------------------------

**Identificación.** Clave primaria: `tim_id`.

**No se puede repetir:** (`tim_descripcion`).

**Reglas que la base exige:** - `tipo_manejo_descripcion_no_vacia`: `((btrim((tim_descripcion)::text) <> ''::text))`

### `manejo_agronomico`

**Para qué sirve.** RF-043 (Could): operación de manejo aplicada a un lote.

  --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Campo                    Tipo              Obligatorio       Significado
  ------------------------ ----------------- ----------------- -------------------------------------------------------------------------------------------------------------------
  `man_id`                 UUID              sí                Identificador del registro (clave primaria).

  `man_registro_id`        UUID              sí                Identificador lógico del registro: igual en todas sus versiones (el cliente lo genera, UUID v7).

  `man_version`            entero            sí                Número de versión del registro: 1 = alta; n+1 = corrección. Append-only (ADR-03).

  `lot_id`                 entero            sí                Referencia a lote(lot_id).

  `tim_id`                 entero            sí                Referencia a tipo_manejo(tim_id).

  `man_observaciones`      texto             no                Observaciones libres de la operación.

  `man_linaje`             sigat.d_linaje    sí                Linaje del dato (RN-014): inspeccion_oficial o autorreporte.

  `usu_id`                 entero            sí                Usuario que realizó/capturó la acción.

  `dis_id`                 UUID              sí                Dispositivo que capturó el registro.

  `ope_id`                 entero largo      sí                Operación de sincronización que creó el registro (idempotencia y trazabilidad).

  `man_t_observacion`      fecha y hora      sí                Momento en que ocurrió lo observado (ADR-02); orden canónico del registro. Inmutable entre versiones (RN-009).

  `man_t_captura`          fecha y hora      sí                Momento en que el dato se guardó, según el reloj del dispositivo (no puede ser anterior a t_observacion).

  `man_t_sincronizacion`   fecha y hora      sí                Momento en que el servidor recibió el dato (reloj del servidor, asignado por trigger; el cliente no lo controla).

  `man_deriva_reloj_seg`   entero            no                \[ud: s\] Diferencia detectada entre el reloj del dispositivo y el del servidor (RDD-010); nulo si no se detectó.

  `man_anulada`            sí/no             sí                Verdadero si esta versión anula el registro. Los registros no se borran (RN-009).

  `man_motivo_anulacion`   texto             no                Motivo obligatorio cuando la versión es una anulación.
  --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

**Identificación.** Clave primaria: `man_id`.

**Se relaciona con:** `dis_id` → `dispositivo`; `lot_id` → `lote`; `ope_id` → `operacion_sync`; `tim_id` → `tipo_manejo`; `usu_id` → `usuario`.

**No se puede repetir:** (`ope_id`); (`man_registro_id, man_version`).

**Reglas que la base exige:** - `manejo_agronomico_anulacion_coherente`: `(((NOT man_anulada) OR ((man_motivo_anulacion IS NOT NULL) AND (btrim((man_motivo_anulacion)::text) <> ''::text))))` - `manejo_agronomico_tiempos_validos`: `((man_t_observacion <= man_t_captura))` - `manejo_agronomico_version_positiva`: `((man_version >= 1))`

**Disparadores:** `trg_aud_manejo (fn_auditar)`, `trg_manejo_agronomico_1_version (fn_registro_version_valida)`, `trg_manejo_agronomico_notruncate (fn_bloquear_truncate)`, `trg_manejo_agronomico_ro (fn_bloquear_modificacion)`.

## 11. Archivos e imágenes, planificación, notificaciones y perfil (extensión del frontend)

Lo que la aplicación móvil ya hace y la base no tenía. **Archivos**: registro de cada foto o documento (hash, tipo, tamaño, dónde está guardado); el archivo en sí va en un almacén de objetos, no dentro de la base. **Evidencia**: fotos de respaldo de una lectura o hallazgo. **Imágenes de diseño**: logos e ilustraciones de la app. **Planificación**: el Agrónomo asigna lotes a un técnico o actividades a un productor, que acepta o rechaza con motivo. **Notificaciones** y sus preferencias, **foto de perfil** y **recuperación de contraseña.**

### `archivo_adjunto`

**Para qué sirve.** Registro de binarios (RDD-011, Arquitectura §3.6): hash, tipo, tamaño y referencia al almacén de objetos. El contenido NO se guarda en la base. Un archivo nace al sincronizar su metadato (pendiente_contenido) y pasa a almacenado cuando sube el binario (la foto sube después del dato numérico, RF-067).

  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Campo                      Tipo              Obligatorio       Significado
  -------------------------- ----------------- ----------------- ----------------------------------------------------------------------------------------------------------------------------------------------
  `adj_id`                   UUID              sí                Identificador del archivo (UUID generado en el dispositivo cuando nace allí).

  `adj_clase`                texto             sí                Para qué se usa: foto_evidencia, foto_perfil, documento_instruccion o imagen_diseno. Las tablas que lo referencian exigen la clase correcta.

  `adj_nombre_original`      texto             no                Nombre del archivo tal como lo eligió el usuario (opcional).

  `adj_mime`                 texto             sí                Tipo de contenido validado en el servidor por el contenido, no por la extensión: JPG, PNG, WebP, PDF o Word.

  `adj_tamano_bytes`         entero largo      sí                \[ud: bytes\] Tamaño. Máximo 8 MB para imágenes y 10 MB para documentos (reglas del frontend; a confirmar).

  `adj_hash_sha256`          hash 64 hex       sí                SHA-256 del contenido en hexadecimal; permite verificar integridad y detectar duplicados.

  `adj_paginas`              entero corto      no                Número de páginas cuando es un PDF (opcional).

  `adj_ref_almacenamiento`   texto             no                Referencia (clave) del objeto en el almacén de objetos; nula mientras no se ha subido el binario.

  `adj_estado`               texto             sí                pendiente_contenido (llegó el metadato, falta el binario), almacenado o rechazado (el servidor revalidó y lo descartó).

  `adj_motivo_rechazo`       texto             no                Motivo cuando el servidor rechaza el archivo.

  `usu_id`                   entero            no                Usuario que lo subió (nulo para recursos del sistema, p. ej. imágenes de diseño).

  `dis_id`                   UUID              no                Dispositivo de origen (nulo para recursos del sistema).

  `adj_t_captura`            fecha y hora      sí                Momento en que se tomó o eligió el archivo (reloj del dispositivo).

  `adj_t_sincronizacion`     fecha y hora      sí                Momento en que el servidor recibió el metadato (reloj del servidor).

  `adj_t_almacenado`         fecha y hora      no                Momento en que quedó guardado el binario.
  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

**Identificación.** Clave primaria: `adj_id`.

**Se relaciona con:** `dis_id` → `dispositivo`; `usu_id` → `usuario`.

**No se puede repetir:** (`adj_id, adj_clase`).

**Reglas que la base exige:** - `archivo_adjunto_clase_mime_coherente`: `((((adj_clase)::text = 'documento_instruccion'::text) OR ((adj_mime)::text ~~ 'image/%'::text)))` - `archivo_adjunto_clase_valida`: `(((adj_clase)::text = ANY ((ARRAY['foto_evidencia'::character varying, 'foto_perfil'::character varying, 'documento_instruccion'::character varying, 'imagen_diseno'::character varying])::text[])))` - `archivo_adjunto_estado_coherente`: `(((((adj_estado)::text = 'almacenado'::text) AND (adj_ref_almacenamiento IS NOT NULL) AND (btrim((adj_ref_almacenamiento)::text) <> ''::text) AND (adj_t_almacenado IS NOT NULL) AND (adj_motivo_rechazo IS NULL)) OR (((adj_estado)::` - `archivo_adjunto_estado_valido`: `(((adj_estado)::text = ANY ((ARRAY['pendiente_contenido'::character varying, 'almacenado'::character varying, 'rechazado'::character varying])::text[])))` - `archivo_adjunto_hash_hex`: `((adj_hash_sha256 ~ '^[0-9a-f]{64}$'::text))` - `archivo_adjunto_mime_valido`: `(((adj_mime)::text = ANY ((ARRAY['image/jpeg'::character varying, 'image/png'::character varying, 'image/webp'::character varying, 'application/pdf'::character varying, 'application/msword'::character varying, 'application/vnd.ope` - `archivo_adjunto_nombre_no_vacio`: `(((adj_nombre_original IS NULL) OR (btrim((adj_nombre_original)::text) <> ''::text)))` - `archivo_adjunto_paginas_positivas`: `(((adj_paginas IS NULL) OR (adj_paginas > 0)))` - `archivo_adjunto_tamano_valido`: `(((adj_tamano_bytes > 0) AND (adj_tamano_bytes <= CASE     WHEN ((adj_clase)::text = 'documento_instruccion'::text) THEN 10485760     ELSE 8388608 END)))`

**Disparadores:** `trg_archivo_adjunto_no_borrar (fn_bloquear_modificacion)`, `trg_archivo_adjunto_valida (fn_archivo_adjunto_valida)`.

### `evidencia`

**Para qué sirve.** RDD-011 / RF-033: fotografía que respalda una lectura de trampa o un hallazgo (exactamente uno). Fecha de captura y hash viven en archivo; aquí la georreferenciación y la observación. Solo inserción: la evidencia queda ligada a la versión de la lectura vigente al capturarla; v_evidencia_lectura la resuelve por registro lógico.

  -------------------------------------------------------------------------------------------------------------------------------------------------------------
  Campo                    Tipo                    Obligatorio       Significado
  ------------------------ ----------------------- ----------------- ------------------------------------------------------------------------------------------
  `evi_id`                 UUID                    sí                Identificador de la evidencia (UUID generado en el dispositivo).

  `adj_id`                 UUID                    sí                Archivo de la fotografía (clase foto_evidencia).

  `evi_clase`              texto                   no                Clase constante foto_evidencia: hace que la FK compuesta solo admita fotos de evidencia.

  `lec_id`                 UUID                    no                Versión de la lectura de trampa que respalda (excluyente con hal_id).

  `hal_id`                 UUID                    no                Versión del hallazgo que respalda (excluyente con lec_id).

  `evi_observacion`        texto                   sí                Observación que escribió quien tomó la foto (puede estar vacía).

  `evi_geom`               geometría(Point,4326)   no                Punto donde se tomó la foto (WGS84), si el dispositivo lo tenía.

  `evi_precision_m`        decimal                 no                \[ud: m\] Precisión del GPS al tomar la foto.

  `usu_id`                 entero                  sí                Usuario que capturó la evidencia.

  `dis_id`                 UUID                    sí                Dispositivo que la capturó.

  `ope_id`                 entero largo            sí                Operación de sincronización que la trajo (idempotencia).

  `evi_t_sincronizacion`   fecha y hora            sí                Momento en que el servidor la recibió.
  -------------------------------------------------------------------------------------------------------------------------------------------------------------

**Identificación.** Clave primaria: `evi_id`.

**Se relaciona con:** `adj_id, evi_clase` → `archivo_adjunto`; `dis_id` → `dispositivo`; `hal_id` → `hallazgo`; `lec_id` → `lectura_trampa`; `ope_id` → `operacion_sync`; `usu_id` → `usuario`.

**No se puede repetir:** (`adj_id, evi_clase`); (`ope_id`).

**Reglas que la base exige:** - `evidencia_precision_con_punto`: `(((evi_precision_m IS NULL) OR (evi_geom IS NOT NULL)))` - `evidencia_precision_positiva`: `(((evi_precision_m IS NULL) OR (evi_precision_m >= (0)::double precision)))` - `evidencia_un_solo_origen`: `((num_nonnulls(lec_id, hal_id) = 1))`

**Disparadores:** `trg_evidencia_aud (fn_auditar)`, `trg_evidencia_inmutable (fn_bloquear_modificacion)`.

### `imagen_diseno`

**Para qué sirve.** Imágenes que forman parte del diseño de la aplicación (logo, ilustraciones, banners). Permite cambiar una imagen sin publicar una nueva versión de la app: se inserta una versión nueva y queda activa una sola por código. El binario está en el almacén de objetos (archivo.adj_ref_almacenamiento).

  -------------------------------------------------------------------------------------------------------------------------------------------
  Campo             Tipo              Obligatorio       Significado
  ----------------- ----------------- ----------------- -------------------------------------------------------------------------------------
  `ima_id`          entero            sí                Identificador interno de la imagen de diseño.

  `ima_codigo`      texto             sí                Nombre estable con el que la app pide la imagen (p. ej. login_hero, logo_oficial).

  `ima_version`     entero corto      sí                Versión de la imagen; al cambiarla se inserta una nueva y se desactiva la anterior.

  `ima_uso`         texto             sí                Dónde se muestra en la aplicación.

  `adj_id`          UUID              sí                Archivo que contiene la imagen.

  `adj_clase`       texto             sí                Clase constante imagen_diseno para la FK compuesta.

  `ima_activa`      sí/no             sí                Solo una versión por código está activa.

  `ima_creada_en`   fecha y hora      sí                Cuándo se registró esta versión.
  -------------------------------------------------------------------------------------------------------------------------------------------

**Identificación.** Clave primaria: `ima_id`.

**Se relaciona con:** `adj_id, adj_clase` → `archivo_adjunto`.

**No se puede repetir:** (`adj_id, adj_clase`); (`ima_codigo, ima_version`).

**Reglas que la base exige:** - `imagen_diseno_clase_fija`: `(((adj_clase)::text = 'imagen_diseno'::text))` - `imagen_diseno_codigo_formato`: `(((ima_codigo)::text ~ '^[a-z0-9_]+$'::text))` - `imagen_diseno_uso_no_vacio`: `((btrim((ima_uso)::text) <> ''::text))` - `imagen_diseno_version_positiva`: `((ima_version >= 1))`

### `categoria_notificacion`

**Para qué sirve.** Categorías de aviso que el usuario puede activar o desactivar (las 5 de la pantalla de preferencias del frontend).

  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Campo               Tipo              Obligatorio       Significado
  ------------------- ----------------- ----------------- -----------------------------------------------------------------------------------------------------------------------------------
  `cnt_id`            entero            sí                Identificador de la categoría.

  `cnt_codigo`        texto             sí                Código estable que usa el frontend (asignacion, alertas_fitosanitarias, recordatorios_inspeccion, avisos_predio, sincronizacion).

  `cnt_descripcion`   texto             sí                Texto descriptivo del valor del catálogo (único, no vacío).
  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

**Identificación.** Clave primaria: `cnt_id`.

**No se puede repetir:** (`cnt_codigo`); (`cnt_descripcion`).

**Reglas que la base exige:** - `categoria_notificacion_codigo_formato`: `(((cnt_codigo)::text ~ '^[a-z_]+$'::text))` - `categoria_notificacion_descripcion_no_vacia`: `((btrim((cnt_descripcion)::text) <> ''::text))`

### `perfil_usuario`

**Para qué sirve.** Perfil del usuario autenticado: foto (referencia a archivo de clase foto_perfil) y el interruptor general de notificaciones. Una fila por usuario, creada cuando el usuario guarda su primer ajuste.

  --------------------------------------------------------------------------------------------------------------------------------------
  Campo                           Tipo              Obligatorio       Significado
  ------------------------------- ----------------- ----------------- ------------------------------------------------------------------
  `usu_id`                        entero            sí                Usuario dueño del perfil.

  `adj_id_foto`                   UUID              no                Foto de perfil (archivo de clase foto_perfil); nula si no tiene.

  `perf_foto_clase`               texto             no                Clase constante foto_perfil para la FK compuesta.

  `perf_notificaciones_activas`   sí/no             sí                Interruptor general de notificaciones.

  `perf_actualizado_en`           fecha y hora      sí                Última vez que el usuario cambió su perfil.
  --------------------------------------------------------------------------------------------------------------------------------------

**Identificación.** Clave primaria: `usu_id`.

**Se relaciona con:** `adj_id_foto, perf_foto_clase` → `archivo_adjunto`; `usu_id` → `usuario`.

### `preferencia_notificacion`

**Para qué sirve.** Preferencia por categoría. Si no hay fila para una categoría, el frontend la considera activada.

  ---------------------------------------------------------------------------------------------------------------
  Campo              Tipo              Obligatorio       Significado
  ------------------ ----------------- ----------------- --------------------------------------------------------
  `usu_id`           entero            sí                Usuario que fija la preferencia.

  `cnt_id`           entero            sí                Categoría de aviso.

  `pno_habilitada`   sí/no             sí                Si el usuario quiere recibir avisos de esta categoría.
  ---------------------------------------------------------------------------------------------------------------

**Identificación.** Clave primaria: `usu_id, cnt_id`.

**Se relaciona con:** `cnt_id` → `categoria_notificacion`; `usu_id` → `usuario`.

### `notificacion`

**Para qué sirve.** Aviso dirigido a un usuario. Lo genera el servidor ante un evento (no la app). not_evento_clave evita duplicados: una asignación = un aviso. Solo cambia not_leida_en (nulo → fecha).

  ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Campo                     Tipo              Obligatorio       Significado
  ------------------------- ----------------- ----------------- --------------------------------------------------------------------------------------------------------------------
  `not_id`                  entero largo      sí                Identificador del aviso.

  `usu_id`                  entero            sí                Destinatario (el servidor lo deduce del evento, no de la app).

  `cnt_id`                  entero            sí                Categoría del aviso.

  `not_titulo`              texto             sí                Título corto del aviso.

  `not_cuerpo`              texto             sí                Texto del aviso.

  `not_evento_clave`        texto             sí                Clave del evento que lo originó (p. ej. planificacion::asignada); con el usuario es única para no duplicar avisos.

  `not_destino_ruta`        texto             no                Pantalla de la app a la que lleva el aviso al tocarlo.

  `not_destino_argumento`   texto             no                Parámetro de la pantalla destino (p. ej. el id de la planificación).

  `not_creada_en`           fecha y hora      sí                Cuándo se generó el aviso (reloj del servidor).

  `not_leida_en`            fecha y hora      no                Cuándo lo leyó el usuario; nulo = no leído.
  ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

**Identificación.** Clave primaria: `not_id`.

**Se relaciona con:** `cnt_id` → `categoria_notificacion`; `usu_id` → `usuario`.

**No se puede repetir:** (`usu_id, not_evento_clave`).

**Reglas que la base exige:** - `notificacion_cuerpo_no_vacio`: `((btrim(not_cuerpo) <> ''::text))` - `notificacion_destino_coherente`: `(((not_destino_argumento IS NULL) OR (not_destino_ruta IS NOT NULL)))` - `notificacion_evento_no_vacio`: `((btrim((not_evento_clave)::text) <> ''::text))` - `notificacion_lectura_posterior`: `(((not_leida_en IS NULL) OR (not_leida_en >= not_creada_en)))` - `notificacion_titulo_no_vacio`: `((btrim((not_titulo)::text) <> ''::text))`

**Disparadores:** `trg_notificacion_valida (fn_notificacion_valida)`.

### `planificacion`

**Para qué sirve.** Asignación de lotes a un técnico o planeación de actividades para un productor, creada por un Agrónomo/Supervisor. El tipo de destino (técnico/productor) no se guarda: se deduce del rol del destinatario (v_planificacion.pla_destino). Productor: pendiente → aceptada \| rechazada (con motivo); aceptada → completada. Técnico: no acepta ni rechaza; la asignación queda vigente (pendiente) y pasa a completada. Los campos de la solicitud no se modifican después de creada. NOTA: la Tabla de Prioridades deja la programación/asignación de visitas fuera del MVP (X-08); se incluye porque el frontend ya la implementa.

  ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Campo                   Tipo                     Obligatorio       Significado
  ----------------------- ------------------------ ----------------- --------------------------------------------------------------------------------------------------------------------------------------------------
  `pla_id`                UUID                     sí                Identificador de la planificación.

  `usu_id_destinatario`   entero                   sí                Destinatario. Si es Productor, debe aceptar o rechazar; si es Técnico no responde: se le asigna y la asignación queda vigente hasta completarse.

  `usu_id_creador`        entero                   sí                Agrónomo/Supervisor que la creó.

  `pla_actividad`         texto                    sí                Actividad a realizar (texto libre, p. ej. "Muestreo de cultivos").

  `pla_fecha_inicio`      fecha                    sí                Fecha de inicio.

  `pla_fecha_fin`         fecha                    no                Fecha de fin (opcional; no anterior al inicio).

  `pla_hora_desde`        time without time zone   no                Hora de inicio del horario diario (opcional, junto con hora_hasta).

  `pla_hora_hasta`        time without time zone   no                Hora de fin del horario diario.

  `pla_observaciones`     texto                    no                Indicaciones adicionales del Agrónomo.

  `adj_id_documento`      UUID                     no                Documento de instrucciones adjunto (PDF, Word o imagen).

  `pla_documento_clase`   texto                    no                Clase constante documento_instruccion para la FK compuesta.

  `pla_estado`            texto                    sí                Productor: pendiente, aceptada, rechazada o completada. Técnico: pendiente (asignación vigente) o completada; nunca aceptada ni rechazada.

  `pla_motivo_rechazo`    texto                    no                Motivo del rechazo; obligatorio si y solo si está rechazada.

  `pla_respondida_en`     fecha y hora             no                Cuándo respondió el destinatario; nula mientras está pendiente.

  `pla_creada_en`         fecha y hora             sí                Cuándo se creó (reloj del servidor).
  ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

**Identificación.** Clave primaria: `pla_id`.

**Se relaciona con:** `usu_id_creador` → `usuario`; `usu_id_destinatario` → `usuario`; `adj_id_documento, pla_documento_clase` → `archivo_adjunto`.

**Reglas que la base exige:** - `planificacion_actividad_no_vacia`: `((btrim((pla_actividad)::text) <> ''::text))` - `planificacion_distintas_personas`: `((usu_id_destinatario <> usu_id_creador))` - `planificacion_estado_valido`: `(((pla_estado)::text = ANY ((ARRAY['pendiente'::character varying, 'aceptada'::character varying, 'rechazada'::character varying, 'completada'::character varying])::text[])))` - `planificacion_fechas_validas`: `(((pla_fecha_fin IS NULL) OR (pla_fecha_fin >= pla_fecha_inicio)))` - `planificacion_horario_completo`: `(((pla_hora_desde IS NULL) = (pla_hora_hasta IS NULL)))` - `planificacion_horario_valido`: `(((pla_hora_desde IS NULL) OR (pla_hora_hasta > pla_hora_desde)))` - `planificacion_rechazo_con_motivo`: `((((pla_estado)::text = 'rechazada'::text) = ((pla_motivo_rechazo IS NOT NULL) AND (btrim((pla_motivo_rechazo)::text) <> ''::text))))` - `planificacion_respuesta_coherente`: `((((pla_estado)::text = 'pendiente'::text) = (pla_respondida_en IS NULL)))`

**Disparadores:** `trg_aud_planificacion (fn_auditar)`, `trg_planificacion_valida (fn_planificacion_valida)`.

### `planificacion_lote`

**Para qué sirve.** Lotes incluidos en una planificación (el frontend los muestra por nombre; aquí se enlazan por id). Solo se modifican mientras la planificación está pendiente.

  -----------------------------------------------------------------------
  Campo             Tipo              Obligatorio       Significado
  ----------------- ----------------- ----------------- -----------------
  `pla_id`          UUID              sí                Planificación.

  `lot_id`          entero            sí                Lote incluido.
  -----------------------------------------------------------------------

**Identificación.** Clave primaria: `pla_id, lot_id`.

**Se relaciona con:** `lot_id` → `lote`; `pla_id` → `planificacion`.

**Disparadores:** `trg_planificacion_lote_valida (fn_planificacion_lote_valida)`.

### `restablecimiento_clave`

**Para qué sirve.** Solicitudes de restablecimiento de contraseña. Solo se guarda el HASH del token (el token viaja por correo y no se almacena), con vencimiento y uso único. El proveedor de identidad (RI-008) sigue pendiente: si es externo, esta tabla no se usa.

  ------------------------------------------------------------------------------------------------------------------------
  Campo                 Tipo              Obligatorio       Significado
  --------------------- ----------------- ----------------- --------------------------------------------------------------
  `rcl_id`              entero largo      sí                Identificador de la solicitud.

  `usu_id`              entero            sí                Usuario que pidió restablecer la contraseña.

  `rcl_token_hash`      hash 64 hex       sí                SHA-256 del token enviado por correo; el token no se guarda.

  `rcl_solicitado_en`   fecha y hora      sí                Cuándo se pidió.

  `rcl_expira_en`       fecha y hora      sí                Hasta cuándo sirve el token.

  `rcl_usado_en`        fecha y hora      no                Cuándo se usó (uso único); nulo = sin usar.
  ------------------------------------------------------------------------------------------------------------------------

**Identificación.** Clave primaria: `rcl_id`.

**Se relaciona con:** `usu_id` → `usuario`.

**No se puede repetir:** (`rcl_token_hash`).

**Reglas que la base exige:** - `restablecimiento_clave_hash_hex`: `((rcl_token_hash ~ '^[0-9a-f]{64}$'::text))` - `restablecimiento_clave_uso_en_vigencia`: `(((rcl_usado_en IS NULL) OR ((rcl_usado_en >= rcl_solicitado_en) AND (rcl_usado_en <= rcl_expira_en))))` - `restablecimiento_clave_vigencia`: `((rcl_expira_en > rcl_solicitado_en))`

## 12. Vistas (consultas ya armadas)

Una vista es una consulta guardada con nombre: no almacena datos, los arma al consultarla. Las `v_*_vigente` devuelven la última versión no anulada; las `*_app` tienen la forma que consumen las pantallas.

  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Vista                               Qué entrega
  ----------------------------------- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  `v_acceso_predio`                   RF-002: predios a los que un usuario tiene acceso hoy (asignación vigente o propietario). El Administrador (ámbito global) no necesita fila. La autorización final se aplica en el servidor (RNF-015).

  `v_actividad_lote`                  Historial por lote (frontend ActivityRecord): visitas, aplicaciones y cosechas vigentes, del tipo vigilancia \| aplicacion \| cosecha.

  `v_asignacion_lote_tecnico`         Lotes que cada técnico tiene asignados y con qué fechas: salen de las planificaciones que el supervisor le asignó (el técnico no acepta: la asignación está vigente mientras esté pendiente; completada queda como historial). Ejemplo: Andrés con los lotes A y C, Juan con B y D.

  `v_concepto_vigente`                Última versión del concepto de aptitud de cada lote y periodo.

  `v_estimacion_total`                Total estimado = árboles × rendimiento, en la misma unidad que el rendimiento por árbol (se asume que "por árbol" se refiere a la unidad de masa; ver pendientes).

  `v_etapa_discrepancia`              RN-012: etapas fenológicas declaradas por el productor que difieren de la observada por el técnico en el mismo lote, para revisión del Agrónomo.

  `v_evidencia_lectura`               Evidencia fotográfica por lectura, resuelta al registro lógico (lec_registro_id) para que sobreviva a las correcciones de la lectura.

  `v_lectura_vigente`                 Última versión no anulada de cada lectura (la que alimenta el MTD si el linaje es inspeccion_oficial).

  `v_lote_app`                        Lote con los datos que muestra la lista del frontend (Lot): predio, productor, municipio, cultivo, área, vigilancia activa y trampas vigentes. El estado pendiente/en curso/visitado es estado de la jornada en el dispositivo y no se guarda aquí.

  `v_lote_resumen_app`                Resumen fitosanitario del lote (frontend LotSummary): MTD, escenario, umbral, concepto, conteos de inspecciones/aplicaciones/lecturas/especímenes, etapa declarada, cosecha y hallazgos vigentes. Todo calculado en el servidor; el umbral de exportación sigue vacío hasta que el ICA lo defina (UQQ-004).

  `v_mtd_serie_lote`                  Serie del MTD por lote y periodo (frontend MtdPoint / gráfica del resumen). El valor lo calcula el servidor; la app solo lo presenta.

  `v_mtd_vigente`                     Última versión de MTD de cada periodo y especie.

  `v_municipio_divipola`              Código Divipola de 5 dígitos (dep+mun) para componer el código ICA de trampa (RN-005).

  `v_notificacion_resumen`            Conteo de avisos no leídos por usuario (insignia de la campana en el frontend).

  `v_planificacion`                   Planificación con nombres de destinatario/creador, documento adjunto y lotes: forma que consume el modelo Planning del frontend.

  `v_registro_campo`                  Registro de campo pendiente de revisión del Agrónomo (frontend FieldRecord): técnico, fechas observada/recibida, lotes y trampas, estado de revisión.

  `v_resumen_lote`                    RF-070 / RF-041 (base): resumen por lote --- trampas vigentes, última aplicación, última visita, concepto vigente.

  `v_ruta_codigo_ica`                 Código Ruta de 9 dígitos del formato MF_UBI/MF_CAP del ICA = Divipola del municipio de la ruta (5) + registro de la ruta con 4 dígitos (p. ej. 54125 + 0602 = 541250602). Derivado, no se almacena (3FN). Solo rutas con municipio y registro numérico.

  `v_trampa_app`                      Trampa con la forma del modelo Trap del frontend: código ICA, tipo, lote, coordenadas, celda, estado y última lectura.

  `v_trampa_lote_vigente`             Ubicación vigente de cada trampa y si su punto cae dentro de la geometría del lote asignado (advertencia RF-012, no bloqueo).

  `v_visita_lote_sin_asignacion`      Informe de validación: visitas de un técnico a lotes que no tenía asignados ese día. No bloquea el registro (el dato llega del celular sin conexión y no se descarta); sirve para revisar y para que el supervisor corrija la asignación.
  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## 13. Funciones y reglas automáticas

  --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Función                             Qué hace
  ----------------------------------- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  `fn_actividad_lote`                 v_actividad_lote filtrada a los lotes que el usuario puede ver.

  `fn_archivo_adjunto_valida`         Trigger de archivo: identidad inmutable, estado solo avanza desde pendiente_contenido y reloj del servidor para t_sincronizacion.

  `fn_auditar`                        Trigger AFTER genérico que escribe en bitacora_auditoria (RF-083). Argumentos: columna PK y prefijo de las columnas de versión/marcas temporales.

  `fn_bloquear_modificacion`          Trigger BEFORE UPDATE/DELETE para tablas append-only (mediciones versionadas y bitácora).

  `fn_bloquear_truncate`              Trigger BEFORE TRUNCATE: impide vaciar las tablas de solo inserción.

  `fn_concepto_valida`                Concepto de aptitud: solo es «no_emitido» cuando el MTD no tiene umbral configurado (RF-024).

  `fn_etapa_derivada`                 RN-012: etapa fenológica derivada del lote en una fecha, según la tabla de reglas vigente en esa fecha. Nulo si falta la fecha de plantación o la regla.

  `fn_hallazgo_valida`                RF-010: la celda del hallazgo debe pertenecer a una retícula del predio del lote.

  `fn_lectura_valida`                 Lectura de trampa: la trampa debe tener código ICA, la ubicación debe ser del predio de la visita y vigente en la fecha observada, y una corrección no puede cambiar la trampa.

  `fn_lote_app`                       v_lote_app filtrada a los lotes que el usuario puede ver (lista de lotes del teléfono).

  `fn_lote_geometria_valida`          RF-084: la geometría de un lote debe quedar contenida en el límite del predio (si el límite ya está cargado).

  `fn_lote_que_contiene`              Devuelve el/los lotes cuya geometría vigente en p_instante cubre el punto (usa el índice GiST de lote_geometria).

  `fn_lote_resumen_app`               v_lote_resumen_app filtrada a los lotes que el usuario puede ver.

  `fn_lotes_visibles`                 Lotes que un usuario puede ver: Administrador todos; Productor y Agrónomo/Supervisor los de sus predios; Técnico solo los lotes de sus asignaciones vigentes, sin necesidad de aceptar nada (p. ej. Andrés: A y C; Juan: B y D; ninguno ve los del otro). Las funciones fn\_\*\_app la usan para filtrar lo que recibe el teléfono.

  `fn_mtd_lectura_valida`             Lecturas que alimentan el MTD: solo inspección oficial, leídas, no anuladas, con trampa asignada al lote y dentro del periodo (RN-013 / RN-014).

  `fn_mtd_serie_lote`                 v_mtd_serie_lote filtrada a los lotes que el usuario puede ver.

  `fn_notificacion_valida`            Trigger de notificacion: contenido inmutable; solo se marca leída, una vez.

  `fn_periodo_valida`                 Periodo de trampeo: el programa debe ser del predio del lote y estar vigente en la fecha final del periodo (RN-003).

  `fn_planificacion_lote_valida`      Trigger de planificacion_lote: congela los lotes cuando la planificación deja de estar pendiente y exige que cada lote sea de un predio al que el destinatario tiene acceso (v_acceso_predio).

  `fn_planificacion_valida`           Trigger de planificacion: solo un Agrónomo/Supervisor crea; el destinatario debe ser Técnico o Productor (el destino se deduce del rol del destinatario, no se guarda); transiciones del Productor pendiente→aceptada\|rechazada y aceptada→completada; el Técnico solo pendiente→completada (no acepta ni rechaza); solo el destinatario responde; la solicitud es inmutable.

  `fn_programa_valida`                Programa de inspección: la retícula debe ser del mismo predio y su resolución múltiplo de la distancia mínima entre trampas (RI-002 / RN-004).

  `fn_registro_version_valida`        Garantiza versionado append-only coherente y fija la marca t_sincronizacion con el reloj del servidor.

  `fn_reticula_inmutable`             La resolución y el predio de una retícula no se modifican; se crea otra retícula.

  `fn_trampa_app`                     v_trampa_app filtrada a las trampas de los lotes que el usuario puede ver.

  `fn_trampa_valida`                  RN-005: el número del código ICA debe respetar la paridad del tipo de trampa (Jackson impar, McPhail par).

  `fn_ubicacion_trampa_valida`        Ubicación de trampa: exige código ICA, coordenadas dentro del rango del departamento del predio (RN-006 / RF-084) y celda de retícula del mismo predio.

  `fn_usuario_actual`                 Identificador usu_id del actor de la sesión, tomado del parámetro de sesión sigat.usuario_actual (lo establece la capa de aplicación; hoy no existe backend).

  `fn_usuario_predio_valida`          Un usuario cuyo rol es de ámbito global no puede asignarse a un predio.

  `fn_visita_integridad`              Visita: no se borra y solo se modifican las columnas de revisión del Agrónomo.
  --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## 14. Qué se hizo en esta entrega (resumen para decidir)

### 14.0 Cambios de la v5 (última revisión)

Detalle completo en `14_cambios_v5.md`. - **Tabla de archivos**: ahora se llama `archivo_adjunto` y sus columnas llevan el prefijo `adj_`. - **Laboratorio retirado**: se quitaron `laboratorio`, `muestra_laboratorio`, `muestra_lectura`, `diagnostico_especie` y la vista `v_lectura_estado_diagnostico`. Consecuencia: el MTD queda solo como total; el cálculo por especie y el estado «pendiente de diagnóstico» quedan sin soporte hasta decidir dónde se registra la especie. - **Nombres**: `usuarios`→`usuario`, `ubi`→`ubicacion_trampa`, `rango`→`rango_departamento`, `estado`→`estado_registro`, `tipo_usuario`→`rol`, y las abreviaturas `*_fecha_reg`, `*_tec_reg`, etc. escritas completas. - **Un solo rol por usuario** (decisión del cliente): `usuario_predio` ya no repite el rol; el rol es `usuario.rol_id`. - **Lotes por técnico**: cada planificación solo puede asignar lotes de predios a los que el destinatario tiene acceso; las vistas `v_asignacion_lote_tecnico` (qué lotes tiene cada técnico) y `v_visita_lote_sin_asignacion` (visitas a lotes no asignados) dan el informe de validación. - **Normalización**: se quitó `planificacion.pla_destino` (se deducía del rol del destinatario) y las áreas pasan a `numeric(14,4)`. No queda ninguna tabla con dos dependencias multivaluadas independientes (4FN).

### 14.1 Auditoría del diseño anterior (v3)

Se revisó todo lo entregado antes (SQL, migración, catálogos, documentos) y se corrigió lo que no tenía sentido:

  ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Hallazgo                                                                                                              Qué se hizo
  --------------------------------------------------------------------------------------------------------------------- ------------------------------------------------------------------------------------------
  `tipo_persona` y `persona.tip_id`: catálogo sin uso (todos los usuarios son personas naturales)                       Eliminados del esquema final. El dato original queda en el esquema legado

  `sitio_muestra` y `ubi.sim_id`: tabla huérfana que ningún formato del ICA usa                                         Eliminados

  `cento_acopio` (errata)                                                                                               Renombrada `centro_acopio` en el esquema final; la migración copia desde el nombre viejo

  7 comentarios de columnas apuntaban a la tabla equivocada; textos genéricos que no aplicaban; comentarios faltantes   Corregidos y verificados con una consulta de control

  Cifras de la documentación desactualizadas                                                                            Regeneradas desde la base
  ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

### 14.2 Cruce con el frontend: lo que se agregó

Se leyó todo el código de la aplicación y se comparó contra la base en los dos sentidos (documento 12, que va completo en el capítulo 15).

**Tablas nuevas de la v4 (10)**

  --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Tabla                               Para qué
  ----------------------------------- --------------------------------------------------------------------------------------------------------------------------------------------------------------
  `archivo_adjunto`                   Registro de toda foto o documento: clase, tipo, tamaño, hash SHA-256, referencia al almacén, estado de subida

  `evidencia`                         Foto que respalda una lectura de trampa o un hallazgo, con punto GPS y observación

  `imagen_diseno`                     Imágenes de la app (logo, login, banners, ilustraciones) con versión; solo una activa por código

  `categoria_notificacion`            Las 5 categorías de aviso de la app

  `perfil_usuario`                    Foto de perfil y interruptor general de notificaciones

  `preferencia_notificacion`          Activar o desactivar cada categoría

  `notificacion`                      Avisos al usuario (creados por el servidor; sin duplicados por evento; solo se marcan leídos)

  `planificacion`                     Asignación de lotes a técnicos y planeación de actividades para productores, con aceptar/rechazar solo para el productor; el técnico no acepta, se le asigna

  `planificacion_lote`                Lotes incluidos en cada planificación

  `restablecimiento_clave`            Solicitud de recuperar contraseña (solo el hash del token)
  --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

**Cambios en tablas existentes** - `aplicacion_fitosanitaria`: el producto puede ser del catálogo **o** texto libre (`apf_producto_texto`), porque el frontend lo escribe a mano. - `operacion_sync`: `evidencia` pasó a ser una entidad sincronizable (la foto llega después del dato, RF-067).

**Vistas nuevas (9)** para las pantallas: `v_lote_app`, `v_trampa_app`, `v_lote_resumen_app`, `v_mtd_serie_lote`, `v_actividad_lote`, `v_registro_campo`, `v_planificacion`, `v_notificacion_resumen`, `v_evidencia_lectura`.

**Imágenes**: las 7 imágenes del frontend quedaron registradas con su hash real (`sql/02c_frontend_catalogos.sql`). Por la decisión de arquitectura (los binarios no van en la base) el archivo en sí debe subirse al almacén de objetos; mientras no se suba, su estado es `pendiente_contenido` (la validación H3 lo informa).

**Reglas importantes de las tablas nuevas** - Un archivo no puede cambiar de contenido (hash, tipo, tamaño) ni borrarse; solo avanza de `pendiente_contenido` a `almacenado` o `rechazado`. - Cada tabla solo acepta archivos de su clase (la foto de perfil no puede ser un PDF; la evidencia no puede ser un documento) mediante una llave foránea compuesta con una clase constante generada. - Una planificación solo la crea un Agrónomo/Supervisor, el destinatario debe ser Técnico o Productor (el tipo de destino se deduce de su rol; no se guarda), solo el destinatario acepta o rechaza, rechazar exige motivo, y después de creada no se modifica su contenido ni sus lotes. - Las evidencias son de solo inserción; las notificaciones solo cambian su fecha de lectura, una vez.

### 14.3 Datos iniciales y de demostración

  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Archivo                                                Contenido
  ------------------------------------------------------ ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  `sql/02_catalogos_oficiales.sql`                       Roles (4), permisos (13), normas, unidades, condiciones de trampa (5) y demás catálogos con fuente confiable

  `sql/02b_catalogos_ica.sql`                            Del formato oficial MF_UBI/MF_CAP del ICA: 5 regiones, 32 departamentos, 1.109 municipios con código DANE, 31 rangos geográficos, 66 especies/resultados de mosca, localizaciones y vigilancia

  `sql/02c_frontend_catalogos.sql`                       5 categorías de notificación y 7 imágenes de diseño con hash real

  `sql/03_catalogos_propuestos_opcional.sql`             Catálogos propuestos (opcional, a validar con el ICA)

  `sql/04_datos_demo.sql` / `05_borrar_datos_demo.sql`   Datos de demostración marcados «DEMO» y su borrado (verificado: la base queda igual que una instalación limpia)
  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

### 14.4 Migración desde el esquema actual

Etapas, cada una con su reversa: **M0** diagnóstico, **M1** preparar (mueve el esquema actual a `sigat_legado`), **M2** instalar el esquema final, **M3** catálogos (incluye 02b y 02c), **M4** personas y usuarios, **M5** predios y lotes, **M6** trampas y ubicaciones, **M7** verificación (conciliación de conteos y sumas), **M8** cierre. Las 10 tablas nuevas no tienen datos de origen: nacen vacías. Verificado: el esquema migrado es **idéntico** (2.758 elementos, 0 diferencias) a una instalación limpia y la reversa devuelve el esquema legado.

### 14.5 Pruebas

156 pruebas automáticas de restricciones (17 grupos): intentan violar cada regla y comprueban que la base lo rechaza con el error esperado, y que las operaciones válidas pasan. 51 son del grupo «Frontend». Además: consultas de validación (`06_validacion.sql`, secciones A--H) y comparación de huellas de esquema.

## 15. Anexo: cruce completo frontend ↔ base de datos

### 1. Lo que el frontend necesita y la base ahora tiene

  ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Frontend (modelo / pantalla)                                                                                     Dónde queda en la base                                                                                                                                     Estado
  ---------------------------------------------------------------------------------------------------------------- ---------------------------------------------------------------------------------------------------------------------------------------------------------- -----------------------
  `UserSession` (usuario, nombre, rol, dispositivo)                                                                `usuario` + `persona` + `rol` + `dispositivo`. El token de sesión lo maneja el backend/IdP, no la base                                                     ✅

  `UserRole` coordinador                                                                                           No existe en la base (solo 4 roles confirmados: Administrador, Agrónomo/Supervisor, Técnico, Productor)                                                    ⚠️ ver §3

  Login «recordarme»                                                                                               Solo dispositivo                                                                                                                                           📱

  Recuperar contraseña (`requestPasswordReset`)                                                                    `restablecimiento_clave` (solo el hash del token, vence, uso único)                                                                                        ➕

  `HomeSummary` (lotes asignados, visitas pendientes, próxima visita, última sincronización)                       `v_lote_app`, `planificacion` (hora desde) y `dispositivo.dis_ultima_sync`                                                                                 ✅🧮

  `Lot` (código, nombre, productor, municipio, predio, cultivo, área, vigilancia activa, trampas, última visita)   `v_lote_app`                                                                                                                                               ➕🧮

  `LotStatus` (pendiente / en curso / visitado)                                                                    Estado de la jornada: se deduce de la visita en curso; no se guarda como dato del lote                                                                     📱

  `LotControl` (MTD, umbral de exportación, aptitud)                                                               `v_lote_resumen_app` (umbral sigue vacío hasta que el ICA lo defina, UQQ-004)                                                                              ➕🧮

  `InspectionProgram` / `InspectionConfig` (periodo de lectura, buenas prácticas, escenarios)                      `programa_inspeccion`, `programa_criterio_bpa`, `escenario_trampeo`                                                                                        ✅

  `Trap` (código ICA, tipo, lat/lng, celda, activa, última lectura)                                                `v_trampa_app` (trampa + ubicación vigente + celda de retícula + última lectura)                                                                           ➕🧮

  `TrapLookup` (¿del lote activo? ¿dentro del lote? ¿en catálogo?)                                                 `trampa.tra_codigo_ica` (QR), `fn_lote_que_contiene`, `lec_coincide_lote`                                                                                  ✅

  `Reading` (especímenes, condición, cambio de cuerpo/atrayente, observaciones)                                    `lectura_trampa` (+ `condicion_trampa` con las 5 condiciones del front)                                                                                    ✅

  `justifyTrap` (trampa no registrada con motivo)                                                                  `lectura_trampa.lec_leida = false` + `lec_justificacion`                                                                                                   ✅

  `Evidence` (foto, observación, lat/lng, estado de subida)                                                        `evidencia` + `archivo_adjunto`                                                                                                                            ➕

  `PhotoFile` / `PhotoRules` (JPG/PNG/WebP, máx. 8 MB)                                                             `archivo_adjunto` (tipo MIME, tamaño ≤ 8 MB, hash SHA-256)                                                                                                 ➕

  `UploadStatus` local / subiendo / subido / fallido                                                               Dispositivo (`loc_archivo_adjunto.adj_estado_subida`); en la base: `pendiente_contenido` / `almacenado` / `rechazado`                                      ➕📱

  `VisitRecord` / `VisitStatus`                                                                                    `visita` + `visita_lote` (sincronizada = `vis_t_sincronizacion`)                                                                                           ✅

  `FieldRecord` / `RecordReviewStatus` (revisión del Agrónomo)                                                     `visita.vis_estado_revision` (`pendiente`, `en_revision`, `aceptado`) y vista `v_registro_campo`                                                           ➕🧮

  `LotSummary` (MTD, serie, inspecciones del mes, aplicaciones, especímenes, etapa, cosecha, hallazgos)            `v_lote_resumen_app` y `v_mtd_serie_lote`                                                                                                                  ➕🧮

  `ActivityRecord` (historial vigilancia/aplicación/cosecha)                                                       `v_actividad_lote`                                                                                                                                         ➕🧮

  `CropSummary` (productor)                                                                                        `v_lote_app` + `v_lote_resumen_app`                                                                                                                        ✅🧮

  `PhytoApplication` (producto escrito a mano, dosis mL/L, área ha, responsable)                                   `aplicacion_fitosanitaria`: ahora el producto puede ser del catálogo (`pfs_id`) **o** texto libre (`apf_producto_texto`); la unidad `mL/L` ya existe       ➕

  `HarvestReport` (fecha esperada/real, volumen kg)                                                                `cosecha`                                                                                                                                                  ✅

  `Planning`, `PlanningTarget`, `PlanningStatus`, rechazo con motivo                                               `planificacion` (+ `planificacion_lote`) con reglas: solo un Agrónomo crea, solo el destinatario responde, ciclo pendiente→aceptada/rechazada→completada   ➕

  `PlanningDoc` (PDF, Word o imagen, ≤ 10 MB, páginas)                                                             `archivo_adjunto` de clase `documento_instruccion` enlazado desde `planificacion.adj_id_documento`                                                         ➕

  `Recipient` / `getAssignableLots`                                                                                Consulta sobre `usuario` por rol y `v_lote_app`                                                                                                            ✅🧮

  `AppNotification` (título, cuerpo, categoría, leída, destino)                                                    `notificacion` (+ `categoria_notificacion`) con clave de evento para no duplicar                                                                           ➕

  `NotificationPreferences` (interruptor general y por categoría)                                                  `perfil_usuario.perf_notificaciones_activas` + `preferencia_notificacion`                                                                                  ➕

  `UserProfile` (foto de perfil)                                                                                   `perfil_usuario.adj_id_foto` → `archivo_adjunto` de clase `foto_perfil`                                                                                    ➕

  Imágenes de diseño (`assets/images`: logo, login, banner, estadísticas, planeación)                              `imagen_diseno` + `archivo_adjunto` (clase `imagen_diseno`), 7 imágenes registradas con su hash real                                                       ➕

  `MapRepository` (mapa descargado sin conexión)                                                                   Solo dispositivo (`loc_mapa_descargado`); el proveedor de imágenes sigue pendiente (UQQ-007)                                                               📱

  `SyncItem` / `SyncRepository`                                                                                    `cola_sync` (dispositivo) ↔ `operacion_sync` y `recepcion_sync` (servidor); `evidencia` se agregó como entidad sincronizable                               ✅➕

  Exportar PDF del resumen del lote                                                                                Se arma en el dispositivo con los datos de `v_lote_resumen_app` (RF-073)                                                                                   🧮
  ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

### 2. Lo que la base tiene y el frontend todavía no usa

Estas capacidades están en el diseño por los requisitos del proyecto pero el frontend no las ofrece (no es un error de la base):

1.  **Posición GPS de la lectura** (`lec_geom`, precisión y coincidencia con el lote): el front solo guarda lat/lng en la foto, no en la lectura.
2.  **Hallazgos fitosanitarios en el mapa** (RF-010): el resumen muestra su conteo, pero no hay pantalla para marcarlos.
3.  **Etapa fenológica declarada por el productor** y **estimación de producción**: sin pantalla de captura.
4.  **Qué atrayente se cambió** (`atr_id`): el front solo guarda las fechas de cambio.
5.  **Corregir o anular** una lectura ya guardada (versionado, RF-052): el front no lo ofrece; el historial por lote muestra solo lo vigente.
6.  **Conflictos de sincronización**: la base clasifica cada operación (`alta_retroactiva`, `revisar`, `rechazada`...), pero la pantalla de sincronización solo muestra pendiente / sincronizado.
7.  **Versión del paquete de campo** (`paquete_campo`, RF-068): el front no verifica si su configuración quedó invalidada.
8.  **Buenas prácticas** (verificación BPA): Fase 2, sin pantallas. El laboratorio y las muestras se retiraron del diseño en v5.
9.  **Administración de usuarios y roles** (RF-082): el rol Administrador existe pero no hay pantallas de administración.
10. **Línea de tiempo y reconstrucción histórica** de un lote en una fecha pasada (RF-050, RF-053).
11. **Tiempos**: la base distingue fecha observada / capturada / sincronizada y la deriva del reloj; el front solo maneja `observedAt`.

### 3. Diferencias por decidir

  --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  \#                      Diferencia                                                                                                                                                                        Recomendación
  ----------------------- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- ----------------------------------------------------------------------------------------------------------------
  1                       El frontend define el rol **coordinador**; el proyecto confirmó solo 4 roles                                                                                                      Quitarlo del front o mapearlo a Agrónomo/Supervisor

  2                       Los ids del front son texto; la base usa enteros (predio, lote, usuario, trampa) y UUID (registros de campo, evidencia, archivo adjunto)                                          El backend convierte; las evidencias y archivos ya nacen con UUID en el dispositivo

  3                       `Planning.lotNames` envía nombres de lote; la base enlaza por `lot_id`                                                                                                            El front debe enviar ids

  4                       La Tabla de Prioridades deja fuera del MVP la evidencia fotográfica (X-03), el recorrido (X-04) y la asignación/programación de visitas (X-08), pero el front ya los implementa   Se agregaron las tablas necesarias; quedan marcadas como extensión (parte 85 del esquema) y no bloquean el MVP

  5                       Las planificaciones y notificaciones requieren conexión (no pasan por la cola offline)                                                                                            Confirmar con el equipo; si deben crearse sin conexión habría que agregarlas a las entidades de sincronización

  6                       Los binarios no van en la base (decisión de arquitectura §3.6)                                                                                                                    Se registra hash, tipo, tamaño y referencia; falta definir el almacén de objetos (UQQ-008)

  7                       `logoapp.png` (ícono de la app) está declarado en `pubspec.yaml` pero no viene en el código recibido                                                                              Agregarlo al proyecto; queda sin registrar en `imagen_diseno` hasta entonces

  8                       Límites 8 MB (imágenes) y 10 MB (documentos) vienen del front                                                                                                                     Se copiaron a la base como reglas; confirmar con el ICA

  9                       El estado «en curso / visitado» de un lote es de la jornada y no está en la base                                                                                                  Si se quiere persistir, derivarlo de `visita`/`visita_lote`
  --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## 16. Pendientes y decisiones

Los pendientes institucionales (umbral de exportación del MTD, proveedor de imágenes satelitales, proveedor de identidad, fuente de polígonos, nombres de fenologías, códigos del ICA por confirmar) están en `09_pendientes_institucionales.md`; **ninguno se inventó**. De esta entrega quedan para decidir: el rol «coordinador» del frontend, si las planificaciones y notificaciones deben funcionar sin conexión, el almacén de objetos para las imágenes y los límites de tamaño de archivo (8 MB / 10 MB, tomados del frontend).

## 17. Dónde está cada cosa en el paquete

  ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Carpeta / archivo                                                  Contenido
  ------------------------------------------------------------------ -----------------------------------------------------------------------------------------------------
  `sql/01_esquema_completo.sql`                                      Esquema final completo (74 tablas, 21 vistas, 29 funciones, 310 índices, comentarios en todo)

  `sql/02…05`, `06_validacion.sql`, `07_pruebas_restricciones.sql`   Datos iniciales, demo, validaciones y 150 pruebas

  `migracion/`                                                       Etapas M0--M8, sus reversas y la prueba con datos legados sintéticos

  `local/sigat_local_sqlite.sql`                                     Modelo de la base local del dispositivo (SQLite), con archivos, evidencia, perfil y mapa descargado

  `diagramas/`                                                       ER por área (PNG/SVG/DOT), `sigat.dbml` para dbdiagram.io, DBML por área y DDL simplificado

  `docs/`                                                            Documentación 00--14 (`14_cambios_v5.md`: nombres, laboratorio retirado y normalización)

  `herramientas/`                                                    Generadores (documentación, DBML, ER, catálogos) y scripts de prueba
  ------------------------------------------------------------------------------------------------------------------------------------------------------------------------

> Regla de oro de esta entrega: **nada de esto se ejecutó en tu base real ni se modificó el frontend**; todo se probó en bases de pruebas desechables.
