# Diccionario de datos SIGAT v6

Generado desde `sigat_v6.dbml`. 74 tablas, 586 columnas. El prefijo de cada columna son las 4 primeras letras de su tabla (ver `07_prefijos.md`).


## Área 1 · Catalogos geograficos


### `arbol` (prefijo `arbo_`)

Árbol/especie hospedera donde se cuelga la trampa (campo del registro de ubicación).

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `arbo_id` | integer (identidad) | sí |  | Identificador del registro (clave primaria). |
| `arbo_descripcion` | varchar | sí |  | Texto descriptivo del valor del catálogo (único, no vacío). |

- **Clave primaria:** `arbo_id`
- **No se puede repetir:** (`arbo_descripcion`)
- **Regla `arbol_descripcion_no_vacia`:** `((btrim((arbo_descripcion)::text) <> ''::text))`


### `atrayente` (prefijo `atra_`)

Atrayente. Vida útil de campo en semanas (RN-008: plug 4–6; proteico hidrolizado 1–2).

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `atra_id` | integer (identidad) | sí |  | Identificador del registro (clave primaria). |
| `atra_descripcion` | varchar | sí |  | Texto descriptivo del valor del catálogo (único, no vacío). |
| `atra_vida_util_min_sem` | smallint | no |  | [ud: semanas] Vida útil mínima de campo del atrayente (RN-008). |
| `atra_vida_util_max_sem` | smallint | no |  | [ud: semanas] Vida útil máxima de campo del atrayente (RN-008). |

- **Clave primaria:** `atra_id`
- **No se puede repetir:** (`atra_descripcion`)
- **Regla `atrayente_descripcion_no_vacia`:** `((btrim((atra_descripcion)::text) <> ''::text))`
- **Regla `atrayente_vida_util_valida`:** `((((atra_vida_util_min_sem IS NULL) = (atra_vida_util_max_sem IS NULL)) AND ((atra_vida_util_min_sem IS NULL) OR ((atra_vida_util_min_sem > 0) AND (atra_vida_util_min_sem <= atra_vida_util_max_sem)))))`


### `centro_acopio` (prefijo `cent_`)

Centro de acopio

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `cent_id` | integer (identidad) | sí |  | Identificador del registro (clave primaria). |
| `cent_descripcion` | varchar | sí |  | Texto descriptivo del valor del catálogo (único, no vacío). |
| `depa_id` | integer | sí |  | Referencia a departamento(depa_id). |

- **Clave primaria:** `cent_id`
- **No se puede repetir:** (`cent_descripcion`)
- **Se relaciona con:** (`depa_id`) → `departamento`
- **Regla `centro_acopio_descripcion_no_vacia`:** `((btrim((cent_descripcion)::text) <> ''::text))`


### `condicion_trampa` (prefijo `cond_`)

RDD-005: estado físico de la trampa en la lectura. Los valores no vienen del Manual (no disponible); se proponen desde el frontend en el archivo de catálogos propuestos.

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `cond_id` | integer (identidad) | sí |  | Identificador del registro (clave primaria). |
| `cond_descripcion` | varchar | sí |  | Texto descriptivo del valor del catálogo (único, no vacío). |
| `cond_activa` | boolean | sí | true | Falso = valor retirado del catálogo (se conserva por historia). |

- **Clave primaria:** `cond_id`
- **No se puede repetir:** (`cond_descripcion`)
- **Regla `condicion_trampa_descripcion_no_vacia`:** `((btrim((cond_descripcion)::text) <> ''::text))`


### `departamento` (prefijo `depa_`)

Departamento. depa_codigo = código DANE de 2 dígitos (parte inicial del Divipola, RN-005). Nulo hasta cargar la fuente DANE.

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `depa_id` | integer (identidad) | sí |  | Identificador del registro (clave primaria). |
| `depa_descripcion` | varchar | sí |  | Texto descriptivo del valor del catálogo (único, no vacío). |
| `regi_id` | integer | sí |  | Referencia a region(regi_id). |
| `depa_codigo` | character(2) | no |  | Código DANE del departamento (2 dígitos). Fuente a cargar desde DANE. |

- **Clave primaria:** `depa_id`
- **No se puede repetir:** (`depa_descripcion`); (`depa_codigo`)
- **Se relaciona con:** (`regi_id`) → `region`
- **Regla `departamento_codigo_formato`:** `((depa_codigo ~ '^[0-9]{2}$'::text))`
- **Regla `departamento_descripcion_no_vacia`:** `((btrim((depa_descripcion)::text) <> ''::text))`


### `escenario_trampeo` (prefijo `esce_`)

RN-002: escenarios de trampeo (Tabla 1, OIEA 2005). Los límites por defecto son referencia; el valor aplicable se configura por predio en programa_umbral. NO es el umbral de exportación (UQQ-004).

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `esce_id` | integer (identidad) | sí |  | Identificador del registro (clave primaria). |
| `esce_descripcion` | varchar | sí |  | Texto descriptivo del valor del catálogo (único, no vacío). |
| `esce_orden` | smallint | sí |  | Orden de presentación (de mayor a menor gravedad). |
| `esce_mtd_desde_defecto` | numeric(10,4) | no |  | [ud: moscas/trampa/día] Límite inferior de referencia del escenario. |
| `esce_mtd_hasta_defecto` | numeric(10,4) | no |  | [ud: moscas/trampa/día] Límite superior de referencia; nulo = sin límite superior. |
| `esce_fuente` | varchar | no |  | Fuente documental de los límites por defecto (p. ej. Levantamiento RN-002, Tabla 1, OIEA 2005). |

- **Clave primaria:** `esce_id`
- **No se puede repetir:** (`esce_descripcion`); (`esce_orden`)
- **Regla `escenario_trampeo_descripcion_no_vacia`:** `((btrim((esce_descripcion)::text) <> ''::text))`
- **Regla `escenario_trampeo_rango_defecto_valido`:** `((esce_mtd_desde_defecto IS NULL OR esce_mtd_desde_defecto >= 0) AND (esce_mtd_hasta_defecto IS NULL OR esce_mtd_hasta_defecto >= 0) AND (esce_mtd_desde_defecto IS NULL OR esce_mtd_hasta_defecto IS NULL OR esce_mtd_desde_defecto <= esce_mtd_hasta_defecto))`


### `especie_cultivo` (prefijo `espc_`)

Especie de cultivo (durazno). Hoy no estaba referenciada; se enlaza con lote y variedad.

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `espc_id` | integer (identidad) | sí |  | Identificador del registro (clave primaria). |
| `espc_descripcion` | varchar | sí |  | Texto descriptivo del valor del catálogo (único, no vacío). |

- **Clave primaria:** `espc_id`
- **No se puede repetir:** (`espc_descripcion`)
- **Regla `especie_cultivo_descripcion_no_vacia`:** `((btrim((espc_descripcion)::text) <> ''::text))`


### `especie_mosca` (prefijo `espm_`)

Resultado de determinación taxonómica de mosca de la fruta (RN-015). espm_codigo es un código numérico opcional del catálogo. espm_tipo distingue especie, género sin especie (p. ej. Anastrepha sp.) y los resultados especiales «No captura» y «No Tephritidae», que se registran en el mismo catálogo pero no son especies.

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `espm_id` | integer (identidad) | sí |  | Identificador del registro (clave primaria). |
| `espm_descripcion` | varchar | sí |  | Texto descriptivo del valor del catálogo (único, no vacío). |
| `espm_codigo` | smallint | no |  | Código numérico de la especie en el catálogo de captura (1 = Ceratitis capitata, 51 = No captura, 54 = No Tephritidae, 56 = Anastrepha sp.). Nulo para especies agregadas localmente. |
| `espm_tipo` | varchar | sí | 'especie'::character varying | Naturaleza del resultado de determinación: especie, genero_sin_especie, sin_captura o no_tephritidae. |

- **Clave primaria:** `espm_id`
- **No se puede repetir:** (`espm_descripcion`); (`espm_codigo`)
- **Regla `especie_mosca_codigo_positivo`:** `(((espm_codigo IS NULL) OR (espm_codigo > 0)))`
- **Regla `especie_mosca_descripcion_no_vacia`:** `((btrim((espm_descripcion)::text) <> ''::text))`
- **Regla `especie_mosca_tipo_valido`:** `(((espm_tipo)::text = ANY ((ARRAY['especie'::character varying, 'genero_sin_especie'::character varying, 'sin_captura'::character varying, 'no_tephritidae'::character varying])::text[])))`


### `estado_registro` (prefijo `esta_`)

Estado de vigencia de un registro maestro (activo/inactivo) usado por usuarios, técnicos, rutas y trampas. Se conserva por compatibilidad; ver informe de normalización (catálogo genérico compartido).

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `esta_id` | integer (identidad) | sí |  | Identificador del registro (clave primaria). |
| `esta_descripcion` | varchar | sí |  | Texto descriptivo del valor del catálogo (único, no vacío). |

- **Clave primaria:** `esta_id`
- **No se puede repetir:** (`esta_descripcion`)
- **Regla `estado_registro_descripcion_no_vacia`:** `((btrim((esta_descripcion)::text) <> ''::text))`


### `fenologia` (prefijo `feno_`)

Catálogo de etapas fenológicas. Las reglas que derivan la etapa por fecha están en fenologia_regla (RN-012).

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `feno_id` | integer (identidad) | sí |  | Identificador del registro (clave primaria). |
| `feno_descripcion` | varchar | sí |  | Texto descriptivo del valor del catálogo (único, no vacío). |
| `feno_codigo` | smallint | no |  | Código numérico de la etapa fenológica (nulo si la etapa no tiene código). |

- **Clave primaria:** `feno_id`
- **No se puede repetir:** (`feno_descripcion`); (`feno_codigo`)
- **Regla `fenologia_descripcion_no_vacia`:** `((btrim((feno_descripcion)::text) <> ''::text))`


### `localizacion` (prefijo `loca_`)

Localización de la trampa dentro del árbol/sitio (campo del registro de ubicación).

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `loca_id` | integer (identidad) | sí |  | Identificador del registro (clave primaria). |
| `loca_descripcion` | varchar | sí |  | Texto descriptivo del valor del catálogo (único, no vacío). |
| `loca_codigo` | smallint | no |  | Código numérico de la localización de la trampa. |

- **Clave primaria:** `loca_id`
- **No se puede repetir:** (`loca_descripcion`); (`loca_codigo`)
- **Regla `localizacion_descripcion_no_vacia`:** `((btrim((loca_descripcion)::text) <> ''::text))`


### `municipio` (prefijo `muni_`)

Municipio. muni_codigo = parte municipal (3 dígitos) del código DANE; el Divipola de 5 dígitos.

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `muni_id` | integer (identidad) | sí |  | Identificador del registro (clave primaria). |
| `muni_descripcion` | varchar | sí |  | Texto descriptivo del valor del catálogo (único, no vacío). |
| `depa_id` | integer | sí |  | Referencia a departamento(depa_id). |
| `muni_codigo` | character(3) | no |  | Código DANE del municipio dentro del departamento (3 dígitos). |

- **Clave primaria:** `muni_id`
- **No se puede repetir:** (`depa_id`, `muni_codigo`)
- **Se relaciona con:** (`depa_id`) → `departamento`
- **Regla `municipio_codigo_formato`:** `((muni_codigo ~ '^[0-9]{3}$'::text))`
- **Regla `municipio_descripcion_no_vacia`:** `((btrim((muni_descripcion)::text) <> ''::text))`


### `norma` (prefijo `norm_`)

Norma que sustenta un umbral o un concepto de aptitud (RDD-007, RF-024). norm_texto_disponible=false: el equipo aún no dispone del texto (UQQ-004).

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `norm_id` | integer (identidad) | sí |  | Identificador del registro (clave primaria). |
| `norm_codigo` | varchar | sí |  | Identificador corto único de la norma. |
| `norm_titulo` | varchar | sí |  | Título completo de la norma. |
| `norm_emisor` | varchar | sí |  | Entidad que expide la norma. |
| `norm_anio` | smallint | no |  | Año de expedición de la norma. |
| `norm_texto_disponible` | boolean | sí | false | Falso si el equipo aún no dispone del texto de la norma. |

- **Clave primaria:** `norm_id`
- **No se puede repetir:** (`norm_codigo`)
- **Regla `norma_anio_valido`:** `(((norm_anio >= 1900) AND (norm_anio <= 2200)))`
- **Regla `norma_textos_no_vacios`:** `(((btrim((norm_codigo)::text) <> ''::text) AND (btrim((norm_titulo)::text) <> ''::text) AND (btrim((norm_emisor)::text) <> ''::text)))`


### `producto_fitosanitario` (prefijo `prof_`)

Catálogo de productos fitosanitarios (RF-081). Sin valores oficiales en la documentación; lo administra el rol Administrador.

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `prof_id` | integer (identidad) | sí |  | Identificador del registro (clave primaria). |
| `prof_nombre` | varchar | sí |  | Nombre comercial (único). |
| `prof_ingrediente_activo` | varchar | no |  | Ingrediente activo (opcional). |
| `prof_registro` | varchar | no |  | Número de registro oficial del producto (opcional, único). |
| `prof_activo` | boolean | sí | true | Falso = producto retirado del catálogo. |

- **Clave primaria:** `prof_id`
- **No se puede repetir:** (`prof_nombre`); (`prof_registro`)
- **Regla `producto_fitosanitario_nombre_no_vacio`:** `((btrim((prof_nombre)::text) <> ''::text))`


### `rango_departamento` (prefijo `rang_`)

Caja envolvente (WGS84, grados) de cada departamento; se usa para validar que las coordenadas de una trampa caen en el departamento del predio. Relación 1:1 con departamento.

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `depa_id` | integer | sí |  | Referencia a departamento(depa_id). |
| `rang_long_min` | float8 | sí |  | [ud: grados] Longitud mínima de la caja del departamento. |
| `rang_long_max` | float8 | sí |  | [ud: grados] Longitud máxima de la caja del departamento. |
| `rang_lat_min` | float8 | sí |  | [ud: grados] Latitud mínima de la caja del departamento. |
| `rang_lat_max` | float8 | sí |  | [ud: grados] Latitud máxima de la caja del departamento. |

- **Clave primaria:** `depa_id`
- **Se relaciona con:** (`depa_id`) → `departamento`
- **Regla `rango_departamento_latitud_valida`:** `(((rang_lat_min < rang_lat_max) AND (rang_lat_min >= ('-90'::integer)::double precision) AND (rang_lat_max <= (90)::double precision)))`
- **Regla `rango_departamento_longitud_valida`:** `(((rang_long_min < rang_long_max) AND (rang_long_min >= ('-180'::integer)::double precision) AND (rang_long_max <= (180)::double precision)))`


### `region` (prefijo `regi_`)

Región geográfica agrupadora de departamentos (catálogo conservado).

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `regi_id` | integer (identidad) | sí |  | Identificador del registro (clave primaria). |
| `regi_descripcion` | varchar | sí |  | Texto descriptivo del valor del catálogo (único, no vacío). |

- **Clave primaria:** `regi_id`
- **No se puede repetir:** (`regi_descripcion`)
- **Regla `region_descripcion_no_vacia`:** `((btrim((regi_descripcion)::text) <> ''::text))`


### `rol` (prefijo `rol_`)

Rol del sistema. Decisión confirmada: solo 4 roles (ADMINISTRADOR, AGRONOMO_SUPERVISOR, TECNICO, PRODUCTOR). rol_ambito: global = rige en todo el sistema (Administrador); predio = rige sobre los predios asignados en usuario_predio (RF-002).

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `rol_id` | integer (identidad) | sí |  | Identificador del registro (clave primaria). |
| `rol_descripcion` | varchar | sí |  | Texto descriptivo del valor del catálogo (único, no vacío). |
| `rol_codigo` | varchar | no |  | Código estable del rol para el código de aplicación (MAYÚSCULAS_Y_GUION_BAJO). |
| `rol_ambito` | varchar | sí | 'predio'::character varying | global (rige en todo el sistema) o predio (rige sobre los predios asignados). |

- **Clave primaria:** `rol_id`
- **No se puede repetir:** (`rol_descripcion`); (`rol_codigo`)
- **Regla `rol_ambito_valido`:** `(((rol_ambito)::text = ANY ((ARRAY['global'::character varying, 'predio'::character varying])::text[])))`
- **Regla `rol_codigo_formato`:** `(((rol_codigo)::text ~ '^[A-Z_]+$'::text))`
- **Regla `rol_descripcion_no_vacia`:** `((btrim((rol_descripcion)::text) <> ''::text))`


### `tipo_trampa` (prefijo `tipt_`)

Tipo de trampa (Jackson, McPhail). tipt_paridad: paridad exigida al número de trampa (RN-005: Jackson impar, McPhail par).

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `tipt_id` | integer (identidad) | sí |  | Identificador del registro (clave primaria). |
| `tipt_descripcion` | varchar | sí |  | Texto descriptivo del valor del catálogo (único, no vacío). |
| `tipt_paridad` | varchar | no |  | impar o par: paridad que debe cumplir el número de trampa (RN-005). Nulo = sin regla. |

- **Clave primaria:** `tipt_id`
- **No se puede repetir:** (`tipt_descripcion`)
- **Regla `tipo_trampa_descripcion_no_vacia`:** `((btrim((tipt_descripcion)::text) <> ''::text))`
- **Regla `tipo_trampa_paridad_valida`:** `(((tipt_paridad)::text = ANY ((ARRAY['impar'::character varying, 'par'::character varying])::text[])))`


### `unidad_medida` (prefijo `unid_`)

RN-017: toda magnitud se almacena con su unidad. Catálogo de unidades (símbolos SI/UCUM).

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `unid_id` | integer (identidad) | sí |  | Identificador del registro (clave primaria). |
| `unid_simbolo` | varchar | sí |  | Símbolo de la unidad (único), p. ej. kg, ha, mL/L. |
| `unid_nombre` | varchar | sí |  | Nombre de la unidad. |
| `unid_magnitud` | varchar | sí |  | Magnitud: masa, area, volumen, longitud o concentracion. |

- **Clave primaria:** `unid_id`
- **No se puede repetir:** (`unid_simbolo`)
- **Regla `unidad_medida_magnitud_valida`:** `(((unid_magnitud)::text = ANY ((ARRAY['masa'::character varying, 'area'::character varying, 'volumen'::character varying, 'longitud'::character varying, 'concentracion'::character varying])::text[])))`
- **Regla `unidad_medida_nombre_no_vacio`:** `(((btrim((unid_nombre)::text) <> ''::text) AND (btrim((unid_simbolo)::text) <> ''::text)))`


### `variedad_cultivo` (prefijo `vari_`)

Variedad de una especie de cultivo (RDD-002). Sin valores oficiales en la documentación: se carga por el Administrador (RF-081).

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `vari_id` | integer (identidad) | sí |  | Identificador del registro (clave primaria). |
| `espc_id` | integer | sí |  | Referencia a especie_cultivo(espc_id). |
| `vari_descripcion` | varchar | sí |  | Texto descriptivo del valor del catálogo (único, no vacío). |

- **Clave primaria:** `vari_id`
- **No se puede repetir:** (`espc_id`, `vari_descripcion`); (`espc_id`, `vari_id`)
- **Se relaciona con:** (`espc_id`) → `especie_cultivo`
- **Regla `variedad_cultivo_descripcion_no_vacia`:** `((btrim((vari_descripcion)::text) <> ''::text))`


### `vigilancia` (prefijo `vigi_`)

Tipo de vigilancia/muestreo (RN-007: la cadencia depende del tipo de vigilancia; RN-011: el solapamiento se evalúa por lote y tipo de muestreo).

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `vigi_id` | integer (identidad) | sí |  | Identificador del registro (clave primaria). |
| `vigi_descripcion` | varchar | sí |  | Texto descriptivo del valor del catálogo (único, no vacío). |
| `vigi_codigo` | smallint | no |  | Código numérico del tipo de vigilancia. |

- **Clave primaria:** `vigi_id`
- **No se puede repetir:** (`vigi_descripcion`); (`vigi_codigo`)
- **Regla `vigilancia_descripcion_no_vacia`:** `((btrim((vigi_descripcion)::text) <> ''::text))`


## Área 2 · Personas usuarios roles


### `administrador` (prefijo `admi_`)

Especialización 1:1 de persona: administrador asociado a un centro de acopio. La obligatoriedad del centro de acopio queda como pendiente institucional.

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `admi_id` | integer (identidad) | sí |  | Identificador del registro (clave primaria). |
| `pers_cc` | bigint | sí |  | Referencia a persona(pers_cc). |
| `cent_id` | integer | sí |  | Referencia a centro_acopio(cent_id). |

- **Clave primaria:** `admi_id`
- **No se puede repetir:** (`pers_cc`)
- **Se relaciona con:** (`pers_cc`) → `persona`; (`cent_id`) → `centro_acopio`
- **Disparador:** auditoría en bitacora_auditoria


### `permiso` (prefijo `perm_`)

Operación autorizable del sistema (RF-002, RNF-015: la autorización se aplica en el servidor). Formato recurso.accion.

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `perm_id` | integer (identidad) | sí |  | Identificador del registro (clave primaria). |
| `perm_codigo` | varchar | sí |  | Código recurso.accion del permiso (minúsculas). |
| `perm_descripcion` | varchar | sí |  | Texto descriptivo del valor del catálogo (único, no vacío). |

- **Clave primaria:** `perm_id`
- **No se puede repetir:** (`perm_codigo`)
- **Regla `permiso_codigo_formato`:** `(((perm_codigo)::text ~ '^[a-z_]+\.[a-z_]+$'::text))`
- **Regla `permiso_descripcion_no_vacia`:** `((btrim((perm_descripcion)::text) <> ''::text))`


### `persona` (prefijo `pers_`)

Persona natural (administrador, técnico, agrónomo o productor). pers_cc = número de identificación sin dígito de verificación ni separadores (se conserva el nombre por compatibilidad). Datos personales: RNF-014 / Ley 1581 de 2012.

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `pers_cc` | bigint | sí |  | Identificador del registro (clave primaria). |
| `pers_nombre` | varchar | sí |  | Nombres o razón social. |
| `pers_apellido` | varchar | sí |  | Apellidos o razón social complementaria. |
| `pers_telefono` | varchar | no |  | Teléfono: solo dígitos, con + opcional (tipo texto: antes numeric perdía ceros y prefijos). |
| `pers_direccion` | varchar | no |  | Dirección de contacto (opcional; dato personal). |
| `pers_correo` | varchar | no |  | Correo electrónico (opcional, único sin distinguir mayúsculas). |

- **Clave primaria:** `pers_cc`
- **Regla `persona_correo_formato`:** `(((pers_correo)::text ~ '^[^@\s]+@[^@\s]+\.[^@\s]+$'::text))`
- **Regla `persona_nombre_no_vacio`:** `(((btrim((pers_nombre)::text) <> ''::text) AND (btrim((pers_apellido)::text) <> ''::text)))`
- **Regla `persona_per_cc_positivo`:** `((pers_cc > 0))`
- **Regla `persona_telefono_formato`:** `(((pers_telefono)::text ~ '^\+?[0-9]{7,15}$'::text))`
- **Disparador:** auditoría en bitacora_auditoria


### `productor` (prefijo `prod_`)

Especialización 1:1 de persona: productor (propietario/responsable de predios). muni_id = municipio de residencia/domicilio del productor.

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `pers_cc` | bigint | sí |  | Referencia a persona(pers_cc). |
| `prod_fecha_registro` | date | sí |  | Fecha de registro del productor. |
| `prod_fecha_actualizacion` | date | no |  | Fecha de la última actualización. |
| `prod_tecnico_registro_id` | integer | sí |  | Técnico que registró al productor. Referencia a tecnico(tecn_id). |
| `prod_tecnico_actualizacion_id` | integer | no |  | Técnico que hizo la última actualización del productor. Referencia a tecnico(tecn_id). |
| `prod_activo` | boolean | sí | true | Verdadero = productor activo. |
| `muni_id` | integer | sí |  | Referencia a municipio(muni_id). |

- **Clave primaria:** `pers_cc`
- **Se relaciona con:** (`pers_cc`) → `persona`; (`prod_tecnico_registro_id`) → `tecnico`; (`prod_tecnico_actualizacion_id`) → `tecnico`; (`muni_id`) → `municipio`
- **Regla `productor_fechas_validas`:** `(((prod_fecha_actualizacion IS NULL) OR (prod_fecha_actualizacion >= prod_fecha_registro)))`
- **Disparador:** auditoría en bitacora_auditoria


### `rol_permiso` (prefijo `rolp_`)

Relación N:M rol–permiso. Tabla de intersección pura (BCNF/4NF: sin atributos no clave).

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `rol_id` | integer | sí |  | Referencia a rol(rol_id). |
| `perm_id` | integer | sí |  | Referencia a permiso(perm_id). |

- **Clave primaria:** `rol_id`, `perm_id`
- **Se relaciona con:** (`rol_id`) → `rol`; (`perm_id`) → `permiso`


### `ruta` (prefijo `ruta_`)

Ruta de inspección de un centro de acopio. ruta_codigo = registro de la ruta (p. ej. 602) que forma parte del código de trampa (RN-005).

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `ruta_id` | integer (identidad) | sí |  | Identificador del registro (clave primaria). |
| `ruta_nombre` | varchar | sí |  | Nombre de la ruta (único). |
| `cent_id` | integer | sí |  | Referencia a centro_acopio(cent_id). |
| `muni_id` | integer | no |  | Municipio al que pertenece la ruta (aporta los 5 dígitos Divipola del código de ruta). Nulo hasta confirmarlo. |
| `ruta_descripcion` | varchar | sí |  | Descripción libre de la ruta (no es única; el identificador de negocio es el nombre ruta_nombre y (cent_id, ruta_codigo)). |
| `ruta_codigo` | varchar | no |  | Código de la ruta (alfanumérico, hasta 10); único dentro del centro de acopio. |
| `ruta_fecha_registro` | date | sí |  | Fecha de registro de la ruta. |
| `ruta_fecha_actualizacion` | date | no |  | Fecha de la última actualización. |
| `ruta_admin_registro_id` | integer | sí |  | Administrador que registró la ruta. Referencia a administrador(admi_id). |
| `ruta_admin_actualizacion_id` | integer | no |  | Administrador que hizo la última actualización de la ruta. Referencia a administrador(admi_id). |
| `esta_id` | integer | sí |  | Referencia a estado_registro(esta_id). |

- **Clave primaria:** `ruta_id`
- **No se puede repetir:** (`ruta_nombre`); (`cent_id`, `ruta_codigo`)
- **Se relaciona con:** (`cent_id`) → `centro_acopio`; (`muni_id`) → `municipio`; (`ruta_admin_registro_id`) → `administrador`; (`ruta_admin_actualizacion_id`) → `administrador`; (`esta_id`) → `estado_registro`
- **Regla `ruta_codigo_formato`:** `(((ruta_codigo)::text ~ '^[0-9A-Za-z]{1,10}$'::text))`
- **Regla `ruta_fechas_validas`:** `(((ruta_fecha_actualizacion IS NULL) OR (ruta_fecha_actualizacion >= ruta_fecha_registro)))`
- **Regla `ruta_nombre_no_vacio`:** `((btrim((ruta_nombre)::text) <> ''::text))`
- **Disparador:** auditoría en bitacora_auditoria


### `tecnico` (prefijo `tecn_`)

Especialización 1:1 de persona: técnico de campo (inspector). admi_id = administrador que lo registró.

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `tecn_id` | integer (identidad) | sí |  | Identificador del registro (clave primaria). |
| `pers_cc` | bigint | sí |  | Referencia a persona(pers_cc). |
| `cent_id` | integer | sí |  | Referencia a centro_acopio(cent_id). |
| `tecn_codigo` | varchar | no |  | Código del recolector: Divipola (5 dígitos) + consecutivo de 3 dígitos. Nulo si no tiene. |
| `admi_id` | integer | sí |  | Referencia a administrador(admi_id). |
| `tecn_fecha_registro` | date | sí |  | Fecha de registro del técnico. |
| `tecn_fecha_actualizacion` | date | no |  | Fecha de la última actualización. |
| `esta_id` | integer | sí |  | Referencia a estado_registro(esta_id). |

- **Clave primaria:** `tecn_id`
- **No se puede repetir:** (`pers_cc`); (`tecn_codigo`)
- **Se relaciona con:** (`pers_cc`) → `persona`; (`cent_id`) → `centro_acopio`; (`admi_id`) → `administrador`; (`esta_id`) → `estado_registro`
- **Regla `tecnico_codigo_formato`:** `(((tecn_codigo)::text ~ '^[0-9]{1,12}$'::text))`
- **Regla `tecnico_fechas_validas`:** `(((tecn_fecha_actualizacion IS NULL) OR (tecn_fecha_actualizacion >= tecn_fecha_registro)))`
- **Disparador:** auditoría en bitacora_auditoria


### `usuario` (prefijo `usua_`)

Cuenta de acceso (1:1 con persona). Autenticación intercambiable (RI-008): proveedor local (hash argon2id/bcrypt, nunca texto plano) o externo (solo identificador del IdP; no se guardan credenciales institucionales). rol_id = el rol único del usuario; usuario_predio solo dice a qué predios aplica.

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `usua_id` | integer (identidad) | sí |  | Identificador del registro (clave primaria). |
| `pers_cc` | bigint | sí |  | Referencia a persona(pers_cc). |
| `usua_usuario` | varchar | sí |  | Nombre de usuario (3–64 caracteres; único sin distinguir mayúsculas). |
| `usua_contrasena` | varchar | no |  | Solo HASH (argon2id o bcrypt). Nulo si la cuenta usa proveedor externo o está pendiente de establecer contraseña. |
| `usua_proveedor` | varchar | sí | 'local'::character varying | local (autenticación propia) o externo (proveedor de identidad institucional, RI-008). |
| `usua_sujeto_externo` | varchar | no |  | Identificador del usuario en el proveedor externo (no es una credencial). Obligatorio si usua_proveedor = externo. |
| `usua_requiere_reinicio` | boolean | sí | false | Verdadero = la cuenta local aún no tiene contraseña y debe establecerla. |
| `rol_id` | integer | sí |  | Referencia a rol(rol_id). |
| `esta_id` | integer | sí |  | Referencia a estado_registro(esta_id). |
| `usua_ultimo_acceso` | timestamptz | no |  | Último acceso exitoso (para revisión de cuentas inactivas). |

- **Clave primaria:** `usua_id`
- **No se puede repetir:** (`pers_cc`); (`usua_proveedor`, `usua_sujeto_externo`)
- **Se relaciona con:** (`pers_cc`) → `persona`; (`rol_id`) → `rol`; (`esta_id`) → `estado_registro`
- **Regla `usuario_credencial_coherente`:** `((usua_proveedor = 'local' AND usua_sujeto_externo IS NULL AND (usua_contrasena IS NOT NULL OR usua_requiere_reinicio)) OR (usua_proveedor = 'externo' AND usua_sujeto_externo IS NOT NULL AND usua_contrasena IS NULL))`
- **Regla `usuario_hash_formato`:** `(((usua_contrasena IS NULL) OR ((usua_contrasena)::text ~ '^\$(argon2id|2[aby])\$'::text)))`
- **Regla `usuario_proveedor_valido`:** `(((usua_proveedor)::text = ANY ((ARRAY['local'::character varying, 'externo'::character varying])::text[])))`
- **Regla `usuario_usuario_formato`:** `(((usua_usuario)::text ~ '^[A-Za-z0-9._@-]{3,64}$'::text))`
- **Disparador:** auditoría en bitacora_auditoria


## Área 3 · Predios lotes programa


### `fenologia_regla` (prefijo `fenr_`)

RN-012: tabla de etapas vigente en una fecha. La etapa derivada de un lote = etapa cuyo intervalo de días desde la plantación contiene (fecha de observación − fecha de plantación). Los valores no están en la documentación disponible: se cargan desde la fuente agronómica.

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `fenr_id` | integer (identidad) | sí |  | Identificador del registro (clave primaria). |
| `espc_id` | integer | sí |  | Referencia a especie_cultivo(espc_id). |
| `feno_id` | integer | sí |  | Referencia a fenologia(feno_id). |
| `fenr_dias_desde` | integer | sí |  | [ud: días desde la plantación] límite inferior inclusivo. |
| `fenr_dias_hasta` | integer | no |  | [ud: días desde la plantación] Límite superior exclusivo; nulo = sin límite. |
| `fenr_vigente_desde` | date | sí |  | Primer día de vigencia de la regla. |
| `fenr_vigente_hasta` | date | no |  | Primer día en que la regla deja de regir (exclusivo); nulo = vigente. |

- **Clave primaria:** `fenr_id`
- **Se relaciona con:** (`espc_id`) → `especie_cultivo`; (`feno_id`) → `fenologia`
- **Regla `fenologia_regla_dias_validos`:** `(((fenr_dias_desde >= 0) AND ((fenr_dias_hasta IS NULL) OR (fenr_dias_hasta > fenr_dias_desde))))`
- **Regla `fenologia_regla_vigencia_valida`:** `(((fenr_vigente_hasta IS NULL) OR (fenr_vigente_hasta > fenr_vigente_desde)))`


### `lote` (prefijo `lote_`)

Lote: subdivisión del predio (UQQ-001: la definición operativa vs productor sigue abierta). Activo entre lote_fecha_registro y lote_fecha_baja. La geometría vive en lote_geometria (versionada, ADR-06).

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `lote_id` | integer (identidad) | sí |  | Identificador del registro (clave primaria). |
| `lote_codigo` | varchar | no |  | Código del lote dentro del predio (RDD-002); único por predio. |
| `lote_descripcion` | varchar | sí |  | Descripción libre del lote (no es única; el identificador de negocio es (pred_id, lote_codigo)). |
| `lote_area` | numeric(14,4) | sí |  | [ud: ha] Área declarada. Unidad por CONFIRMAR con los datos reales. |
| `pred_id` | integer | sí |  | Referencia a predio(pred_id). |
| `espc_id` | integer | no |  | Especie de cultivo del lote. Forma parte de la FK compuesta (espc_id, vari_id) hacia variedad_cultivo, que garantiza que la variedad es de esa especie. |
| `vari_id` | integer | no |  | Referencia a variedad_cultivo(vari_id). |
| `lote_fecha_plantacion` | date | no |  | Fecha de plantación; base para derivar la etapa fenológica (RN-012). |
| `lote_fecha_registro` | date | sí |  | Fecha de registro del lote; inicio de su actividad. |
| `lote_fecha_actualizacion` | date | no |  | Fecha de la última actualización del registro. |
| `lote_fecha_baja` | date | no |  | Primer día en que el lote deja de estar activo (nulo = activo). Permite validar "el lote debe estar activo en el periodo inspeccionado" (Arquitectura 5.3). |
| `lote_tecnico_registro_id` | integer | sí |  | Técnico que registró el lote. Referencia a tecnico(tecn_id). |
| `lote_tecnico_actualizacion_id` | integer | no |  | Técnico que hizo la última actualización del lote. Referencia a tecnico(tecn_id). |

- **Clave primaria:** `lote_id`
- **No se puede repetir:** (`lote_id`, `pred_id`); (`pred_id`, `lote_codigo`)
- **Se relaciona con:** (`pred_id`) → `predio`; (`espc_id`) → `especie_cultivo`; (`espc_id`, `vari_id`) → `variedad_cultivo`; (`lote_tecnico_registro_id`) → `tecnico`; (`lote_tecnico_actualizacion_id`) → `tecnico`
- **Regla `lote_area_positiva`:** `((lote_area > (0)::numeric))`
- **Regla `lote_descripcion_no_vacia`:** `((btrim((lote_descripcion)::text) <> ''::text))`
- **Regla `lote_fechas_validas`:** `((lote_fecha_actualizacion IS NULL OR lote_fecha_actualizacion >= lote_fecha_registro) AND (lote_fecha_baja IS NULL OR lote_fecha_baja >= lote_fecha_registro))`
- **Regla `lote_var_requiere_esc`:** `(((vari_id IS NULL) OR (espc_id IS NOT NULL)))`
- **Disparador:** auditoría en bitacora_auditoria


### `lote_geometria` (prefijo `lotg_`)

RF-085 / ADR-06: versiones de la geometría de un lote con vigencia; cada medición se asocia a la versión vigente en su fecha de observación. Una sola versión vigente por instante (EXCLUDE).

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `lotg_id` | integer (identidad) | sí |  | Identificador del registro (clave primaria). |
| `lote_id` | integer | sí |  | Referencia a lote(lote_id). |
| `lotg_version` | integer | sí |  | Número de versión de la geometría del lote (1, 2, …). |
| `lotg_geom` | geometry(MultiPolygon,4326) | sí |  | Polígono del lote, SRID 4326, válido y no vacío. |
| `lotg_area_m2` | numeric (generada) | no |  | [ud: m2] Área geodésica calculada (geography); columna derivada, no editable. |
| `lotg_vigente_desde` | timestamptz | sí |  | Inicio de vigencia de la versión (inclusive). |
| `lotg_vigente_hasta` | timestamptz | no |  | Fin de vigencia de la versión (exclusivo); nulo = vigente. |
| `lotg_fuente` | varchar | no |  | Origen de la geometría (GPS del dispositivo, digitalización, importación). |
| `lotg_motivo` | varchar | no |  | Motivo del cambio de geometría. |
| `lotg_registrado_en` | timestamptz | sí | now() | Momento en que se registró la versión. |
| `lotg_registrado_por` | integer | no |  | Usuario que registró la versión (opcional). |

- **Clave primaria:** `lotg_id`
- **No se puede repetir:** (`lote_id`, `lotg_version`)
- **Se relaciona con:** (`lote_id`) → `lote`
- **Regla `lote_geometria_geom_valida`:** `((st_isvalid(lotg_geom) AND (NOT st_isempty(lotg_geom))))`
- **Regla `lote_geometria_version_positiva`:** `((lotg_version >= 1))`
- **Regla `lote_geometria_vigencia_valida`:** `(((lotg_vigente_hasta IS NULL) OR (lotg_vigente_hasta > lotg_vigente_desde)))`
- **Sin solapamiento `lotg_vigencia_sin_solape`:** `lote_id WITH =, tstzrange(lotg_vigente_desde, lotg_vigente_hasta) WITH &&`
- **Disparador:** auditoría en bitacora_auditoria


### `paquete_campo` (prefijo `paqu_`)

RF-004 / M-07: versión del paquete de campo descargable de un predio (geometrías, retícula, trampas, catálogos, umbrales). Se invalida al cambiar la configuración. paqu_hash = SHA-256 hex del contenido generado.

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `paqu_id` | uuid | sí | gen_random_uuid() | Identificador del registro (clave primaria). |
| `pred_id` | integer | sí |  | Predio del paquete de datos para campo. Forma parte de la FK compuesta (prog_id, pred_id) hacia programa_inspeccion. |
| `paqu_version` | integer | sí |  | Número de versión del paquete del predio. |
| `prog_id` | integer | sí |  | Referencia a programa_inspeccion(prog_id). |
| `paqu_hash` | character(64) | sí |  | SHA-256 hexadecimal del contenido del paquete. |
| `paqu_generado_en` | timestamptz | sí | now() | Momento en que se generó el paquete. |
| `paqu_invalidado_en` | timestamptz | no |  | Momento en que el paquete dejó de ser válido (cambio de configuración). |
| `paqu_motivo_invalidacion` | varchar | no |  | Motivo de la invalidación. |

- **Clave primaria:** `paqu_id`
- **No se puede repetir:** (`pred_id`, `paqu_version`)
- **Se relaciona con:** (`pred_id`) → `predio`; (`prog_id`, `pred_id`) → `programa_inspeccion`
- **Regla `paquete_campo_hash_formato`:** `((paqu_hash ~ '^[0-9a-f]{64}$'::text))`
- **Regla `paquete_campo_invalidacion_coherente`:** `(((paqu_invalidado_en IS NULL) = (paqu_motivo_invalidacion IS NULL)))`
- **Regla `paquete_campo_version_positiva`:** `((paqu_version >= 1))`
- **Disparador:** auditoría en bitacora_auditoria


### `predio` (prefijo `pred_`)

Predio inscrito (RDD-001). pers_cc = productor responsable. pred_codigo = código interno del predio (parte del código de trampa cuando no hay ruta, RN-005). El número de lotes no se almacena: se cuenta.

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `pred_id` | integer (identidad) | sí |  | Identificador del registro (clave primaria). |
| `pred_codigo` | varchar | no |  | Código interno del predio (parte del código de trampa cuando no hay ruta). Único. |
| `pred_nombre` | varchar | sí |  | Nombre del predio. |
| `muni_id` | integer | sí |  | Referencia a municipio(muni_id). |
| `pred_area` | numeric(14,4) | sí |  | [ud: ha] Área declarada del predio. Unidad por CONFIRMAR con los datos reales (el frontend usa hectáreas). |
| `pers_cc` | bigint | sí |  | Referencia a productor(pers_cc). |
| `pred_geom` | geometry(MultiPolygon,4326) | no |  | Límite del predio, SRID 4326. Nulo hasta cargar el polígono (fuente pendiente de definir). |
| `pred_zona_horaria` | varchar | sí | 'America/Bogota'::character varying | ADR-10: zona horaria IANA del predio; las marcas temporales se guardan en UTC (timestamptz). |
| `pred_fecha_registro` | date | sí |  | Fecha de registro del predio. |
| `pred_fecha_actualizacion` | date | no |  | Fecha de la última actualización del registro (antes era obligatoria; ahora nula hasta que haya una). |
| `pred_tecnico_registro_id` | integer | sí |  | Técnico que registró el predio. Referencia a tecnico(tecn_id). |
| `pred_tecnico_actualizacion_id` | integer | no |  | Técnico que hizo la última actualización del predio. Referencia a tecnico(tecn_id). |

- **Clave primaria:** `pred_id`
- **No se puede repetir:** (`pred_codigo`)
- **Se relaciona con:** (`muni_id`) → `municipio`; (`pers_cc`) → `productor`; (`pred_tecnico_registro_id`) → `tecnico`; (`pred_tecnico_actualizacion_id`) → `tecnico`
- **Regla `predio_area_positiva`:** `((pred_area > (0)::numeric))`
- **Regla `predio_fechas_validas`:** `(((pred_fecha_actualizacion IS NULL) OR (pred_fecha_actualizacion >= pred_fecha_registro)))`
- **Regla `predio_geom_valida`:** `(((pred_geom IS NULL) OR st_isvalid(pred_geom)))`
- **Regla `predio_nombre_no_vacio`:** `((btrim((pred_nombre)::text) <> ''::text))`
- **Regla `predio_zona_horaria_formato`:** `(((pred_zona_horaria)::text ~ '^[A-Za-z_]+(/[A-Za-z0-9_+-]+)+$'::text))`
- **Disparador:** auditoría en bitacora_auditoria


### `programa_inspeccion` (prefijo `prog_`)

RF-080 / RDD-007: configuración versionada del programa de inspección de un predio (nunca se edita: se crea una versión nueva y se cierra la anterior). El umbral de EXPORTACIÓN es nulo mientras no se defina (UQQ-004); si existe debe citar la norma que lo sustenta.

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `prog_id` | integer (identidad) | sí |  | Identificador del registro (clave primaria). |
| `pred_id` | integer | sí |  | Predio del programa de inspección. Forma parte de la FK compuesta (reti_id, pred_id) hacia reticula y de la FK hacia predio. |
| `prog_version` | integer | sí |  | Número de versión de la configuración del predio (1, 2, …). |
| `prog_vigente_desde` | date | sí |  | Primer día de vigencia (inclusive). |
| `prog_vigente_hasta` | date | no |  | Primer día en que deja de regir (exclusivo); nulo = vigente. |
| `prog_ciclo_inicio` | date | no |  | Inicio del ciclo de cultivo del programa (opcional). |
| `prog_ciclo_fin` | date | no |  | Fin del ciclo de cultivo del programa (opcional; definición del ciclo pendiente). |
| `prog_periodo_lectura_dias` | smallint | sí |  | [ud: días] RN-007: 7 a 14 días en predios de exportación (UQQ-003 pide confirmarlo). |
| `prog_distancia_min_trampas_m` | smallint | sí |  | [ud: m] RN-004: distancia mínima entre trampas, 40 a 60 m. El valor exacto es parámetro por predio. |
| `reti_id` | integer | no |  | Referencia a reticula(reti_id). |
| `prog_proveedor_imagen` | varchar | no |  | Proveedor de imagen satelital configurado (UQQ-007 pendiente). |
| `prog_umbral_exportacion_mtd` | numeric(10,4) | no |  | [ud: moscas/trampa/día] Umbral de MTD de exportación. NO INVENTADO: nulo hasta que UQQ-004 se resuelva. |
| `norm_id` | integer | no |  | Referencia a norma(norm_id). |
| `prog_motivo_cambio` | varchar | no |  | Motivo del cambio respecto de la versión anterior. |
| `prog_creado_por` | integer | no |  | Referencia a usuario(usua_id). |
| `prog_creado_en` | timestamptz | sí | now() | Momento en que se creó la versión. |

- **Clave primaria:** `prog_id`
- **No se puede repetir:** (`pred_id`, `prog_version`); (`prog_id`, `pred_id`)
- **Se relaciona con:** (`pred_id`) → `predio`; (`reti_id`, `pred_id`) → `reticula`; (`norm_id`) → `norma`; (`prog_creado_por`) → `usuario`
- **Regla `programa_inspeccion_ciclo_valido`:** `((((prog_ciclo_inicio IS NULL) = (prog_ciclo_fin IS NULL)) AND ((prog_ciclo_inicio IS NULL) OR (prog_ciclo_fin >= prog_ciclo_inicio))))`
- **Regla `programa_inspeccion_distancia_rn004`:** `(((prog_distancia_min_trampas_m >= 40) AND (prog_distancia_min_trampas_m <= 60)))`
- **Regla `programa_inspeccion_periodo_rn007`:** `(((prog_periodo_lectura_dias >= 7) AND (prog_periodo_lectura_dias <= 14)))`
- **Regla `programa_inspeccion_umbral_con_norma`:** `(((prog_umbral_exportacion_mtd IS NULL) = (norm_id IS NULL)))`
- **Regla `programa_inspeccion_umbral_valido`:** `(((prog_umbral_exportacion_mtd IS NULL) OR (prog_umbral_exportacion_mtd >= (0)::numeric)))`
- **Regla `programa_inspeccion_version_positiva`:** `((prog_version >= 1))`
- **Regla `programa_inspeccion_vigencia_valida`:** `(((prog_vigente_hasta IS NULL) OR (prog_vigente_hasta > prog_vigente_desde)))`
- **Sin solapamiento `programa_inspeccion_sin_solape`:** `pred_id WITH =, daterange(prog_vigente_desde, prog_vigente_hasta) WITH &&`
- **Disparador:** auditoría en bitacora_auditoria


### `programa_umbral` (prefijo `prou_`)

RN-002: límites de MTD de cada escenario de trampeo, configurables por versión de programa. [ud: moscas/trampa/día]. La inclusión de los extremos del intervalo es una decisión institucional pendiente.

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `prog_id` | integer | sí |  | Referencia a programa_inspeccion(prog_id). |
| `esce_id` | integer | sí |  | Referencia a escenario_trampeo(esce_id). |
| `prou_mtd_desde` | numeric(10,4) | sí |  | [ud: moscas/trampa/día] Límite inferior del escenario en este programa. |
| `prou_mtd_hasta` | numeric(10,4) | no |  | [ud: moscas/trampa/día] Límite superior; nulo = sin límite. |

- **Clave primaria:** `prog_id`, `esce_id`
- **Se relaciona con:** (`prog_id`) → `programa_inspeccion`; (`esce_id`) → `escenario_trampeo`
- **Regla `programa_umbral_rango_valido`:** `(((prou_mtd_desde >= (0)::numeric) AND ((prou_mtd_hasta IS NULL) OR (prou_mtd_hasta >= prou_mtd_desde))))`


### `reticula` (prefijo `reti_`)

RF-006 / RDD-003: retícula regular de un predio con su resolución en metros (parámetro por predio, no constante). El tamaño de celda es pendiente (UQQ-005); debe ser múltiplo de la distancia mínima entre trampas y mayor que 60 m (RN-004, RI-002).

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `reti_id` | integer (identidad) | sí |  | Identificador del registro (clave primaria). |
| `pred_id` | integer | sí |  | Referencia a predio(pred_id). |
| `reti_resolucion_m` | integer | sí |  | [ud: m] Lado de la celda. |
| `reti_fecha_corte_imagen` | date | no |  | Fecha de corte de la imagen satelital usada (RDD-003). |
| `reti_creada_en` | timestamptz | sí | now() | Momento en que se creó la retícula. |

- **Clave primaria:** `reti_id`
- **No se puede repetir:** (`reti_id`, `pred_id`); (`pred_id`, `reti_resolucion_m`)
- **Se relaciona con:** (`pred_id`) → `predio`
- **Regla `reticula_resolucion_valida`:** `((reti_resolucion_m > 60))`


### `reticula_celda` (prefijo `retc_`)

Celda de la retícula (RDD-003). La resolución y la fecha de corte de imagen se heredan de reticula (no se repiten por celda: 3FN).

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `retc_id` | bigint (identidad) | sí |  | Identificador del registro (clave primaria). |
| `reti_id` | integer | sí |  | Referencia a reticula(reti_id). |
| `retc_codigo` | varchar | sí |  | Código de la celda dentro de la retícula (p. ej. C3). |
| `retc_geom` | geometry(Polygon,4326) | sí |  | Polígono de la celda, SRID 4326, válido. |

- **Clave primaria:** `retc_id`
- **No se puede repetir:** (`reti_id`, `retc_codigo`)
- **Se relaciona con:** (`reti_id`) → `reticula`
- **Regla `reticula_celda_codigo_no_vacio`:** `((btrim((retc_codigo)::text) <> ''::text))`
- **Regla `reticula_celda_geom_valida`:** `(st_isvalid(retc_geom))`


### `usuario_predio` (prefijo `usup_`)

RF-002: predios a los que un usuario tiene acceso, con vigencia. El rol es ÚNICO por usuario (usuario.rol_id): esta tabla no repite el rol, solo dice dónde aplica. No puede tener dos asignaciones solapadas sobre el mismo predio. Solo admite usuarios con rol de ámbito predio (el Administrador es global). El alcance del Agrónomo/Supervisor es pendiente institucional.

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `usup_id` | integer (identidad) | sí |  | Identificador del registro (clave primaria). |
| `usua_id` | integer | sí |  | Usuario que realizó/capturó la acción. |
| `pred_id` | integer | sí |  | Referencia a predio(pred_id). |
| `rol_id` | integer | sí |  | Referencia a rol(rol_id). |
| `usup_desde` | date | sí | CURRENT_DATE | Primer día en que rige la asignación (inclusive). |
| `usup_hasta` | date | no |  | Primer día en que deja de regir (exclusivo); nulo = vigente. |
| `usup_asignado_por` | integer | no |  | Referencia a usuario(usua_id). |
| `usup_creado_en` | timestamptz | sí | now() | Momento en que se creó la asignación. |

- **Clave primaria:** `usup_id`
- **Se relaciona con:** (`usua_id`) → `usuario`; (`pred_id`) → `predio`; (`rol_id`) → `rol`; (`usup_asignado_por`) → `usuario`
- **Regla `usuario_predio_vigencia_valida`:** `(((usup_hasta IS NULL) OR (usup_hasta > usup_desde)))`
- **Sin solapamiento `usuario_predio_sin_solape`:** `usua_id WITH =, pred_id WITH =, daterange(usup_desde, usup_hasta) WITH &&`
- **Disparador:** auditoría en bitacora_auditoria


## Área 4 · Trampas ubicaciones


### `trampa` (prefijo `tram_`)

Trampa física identificada por su código impreso (RN-005: Divipola(5)-ruta o predio interno-número). El código puede ser nulo solo en trampas heredadas del esquema anterior; no se puede asignar ni leer una trampa nueva sin código. La posición y el lote están en ubicacion_trampa (historial). tra_atr_id = atrayente vigente por defecto.

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `tram_id` | integer (identidad) | sí |  | Identificador del registro (clave primaria). |
| `tram_codigo` | varchar | no |  | Código oficial impreso en la trampa. Formato verificado de forma mínima (el Manual Técnico T1 no está disponible): ver pendientes. |
| `tram_numero` | integer (generada) | no |  | Número de trampa extraído del código (columna generada). Jackson impar / McPhail par (RN-005). |
| `tipt_id` | integer | sí |  | Referencia a tipo_trampa(tipt_id). |
| `atra_id` | integer | sí |  | Referencia a atrayente(atra_id). |
| `esta_id` | integer | sí |  | Referencia a estado_registro(esta_id). |
| `tram_fecha_registro` | date | sí |  | Fecha de registro de la trampa. |
| `tram_fecha_actualizacion` | date | no |  | Fecha de la última actualización del registro. |
| `tram_fecha_estado` | date | no |  | Fecha del último cambio de estado (esta_id) de la trampa. |
| `tram_tecnico_registro_id` | integer | sí |  | Técnico que registró la trampa. Referencia a tecnico(tecn_id). |
| `tram_tecnico_actualizacion_id` | integer | no |  | Técnico que hizo la última actualización de la trampa. Referencia a tecnico(tecn_id). |
| `tram_tecnico_estado_id` | integer | no |  | Técnico que cambió por última vez el estado de la trampa. Referencia a tecnico(tecn_id). |

- **Clave primaria:** `tram_id`
- **No se puede repetir:** (`tram_codigo`)
- **Se relaciona con:** (`tipt_id`) → `tipo_trampa`; (`atra_id`) → `atrayente`; (`esta_id`) → `estado_registro`; (`tram_tecnico_registro_id`) → `tecnico`; (`tram_tecnico_actualizacion_id`) → `tecnico`; (`tram_tecnico_estado_id`) → `tecnico`
- **Regla `trampa_codigo_formato`:** `(((tram_codigo)::text ~ '^[0-9]{5}-[0-9A-Za-z]{1,10}-[0-9]{1,4}$'::text))`
- **Regla `trampa_fechas_validas`:** `((((tram_fecha_actualizacion IS NULL) OR (tram_fecha_actualizacion >= tram_fecha_registro)) AND ((tram_fecha_estado IS NULL) OR (tram_fecha_estado >= tram_fecha_registro))))`
- **Disparador:** auditoría en bitacora_auditoria
- **Disparador:** paridad del número según el tipo (Jackson impar, McPhail par)


### `ubicacion_trampa` (prefijo `ubic_`)

Asignación y ubicación de una trampa en un lote durante un intervalo [ubic_fecha, ubic_fecha_fin). Es la asignación EXPLÍCITA trampa–lote exigida por RN-013/RF-013 y conserva el historial de reubicaciones. Una trampa no puede tener dos ubicaciones simultáneas (EXCLUDE). lote_id es nulo solo en filas ubic_origen=legado pendientes de asignar.

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `ubic_id` | bigint (identidad) | sí |  | Identificador del registro (clave primaria). |
| `tram_id` | integer | sí |  | Referencia a trampa(tram_id). |
| `pred_id` | integer | sí |  | Redundancia controlada: lote_id determina pred_id; la FK compuesta (lote_id, pred_id) impide la incoherencia. Permite conservar filas heredadas sin lote. |
| `lote_id` | integer | no |  | Referencia a lote(lote_id). |
| `ubic_fecha` | date | sí |  | Fecha de instalación en este puesto (inclusive). ubic_fecha_fin = primer día en que ya no está (exclusivo; retiro o reubicación). |
| `ubic_fecha_fin` | date | no |  | Primer día en que la trampa ya no está en este puesto (exclusivo); nulo = vigente. |
| `tecn_id` | integer | sí |  | Referencia a tecnico(tecn_id). |
| `vigi_id` | integer | sí |  | Referencia a vigilancia(vigi_id). |
| `ruta_id` | integer | no |  | Referencia a ruta(ruta_id). |
| `retc_id` | bigint | no |  | Referencia a reticula_celda(retc_id). |
| `loca_id` | integer | no |  | Referencia a localizacion(loca_id). |
| `arbo_id` | integer | no |  | Referencia a arbol(arbo_id). |
| `ubic_long` | numeric(8,5) | sí |  | [ud: grados decimales WGS84] 5 decimales (RN-006); numeric evita ruido de punto flotante. |
| `ubic_lat` | numeric(7,5) | sí |  | [ud: grados decimales WGS84] Latitud con 5 decimales (RN-006). |
| `ubic_alt` | float8 | no |  | [ud: m s. n. m.] Altitud; puede faltar si el GPS no la entrega. |
| `ubic_referencia` | varchar | no |  | Descripción libre del sitio (opcional). |
| `ubic_geom` | geometry(Point,4326) (generada) | no |  | Punto SRID 4326 derivado de ubic_long/ubic_lat (columna generada: una sola fuente de verdad). Base de ST_Contains contra lote_geometria. |
| `ubic_origen` | varchar | sí | 'operacion'::character varying | operacion = creada con las reglas vigentes; legado = migrada del esquema anterior sin lote asignado. |
| `ubic_registrado_en` | timestamptz | sí | now() | Momento en que se registró la ubicación. |

- **Clave primaria:** `ubic_id`
- **No se puede repetir:** (`ubic_id`, `tram_id`)
- **Se relaciona con:** (`tram_id`) → `trampa`; (`pred_id`) → `predio`; (`lote_id`, `pred_id`) → `lote`; (`tecn_id`) → `tecnico`; (`vigi_id`) → `vigilancia`; (`ruta_id`) → `ruta`; (`retc_id`) → `reticula_celda`; (`loca_id`) → `localizacion`; (`arbo_id`) → `arbol`
- **Regla `ubicacion_trampa_coordenadas_validas`:** `((((ubic_long >= ('-180'::integer)::numeric) AND (ubic_long <= (180)::numeric)) AND ((ubic_lat >= ('-90'::integer)::numeric) AND (ubic_lat <= (90)::numeric))))`
- **Regla `ubicacion_trampa_lote_obligatorio`:** `((((ubic_origen)::text = 'legado'::text) OR (lote_id IS NOT NULL)))`
- **Regla `ubicacion_trampa_origen_valido`:** `(((ubic_origen)::text = ANY ((ARRAY['operacion'::character varying, 'legado'::character varying])::text[])))`
- **Regla `ubicacion_trampa_vigencia_valida`:** `(((ubic_fecha_fin IS NULL) OR (ubic_fecha_fin > ubic_fecha)))`
- **Sin solapamiento `ubicacion_trampa_sin_solape`:** `tram_id WITH =, daterange(ubic_fecha, ubic_fecha_fin) WITH &&`
- **Disparador:** auditoría en bitacora_auditoria


## Área 5 · Sincronizacion auditoria


### `bitacora_auditoria` (prefijo `bita_`)

RF-083 / RNF-014: bitácora que no admite modificación. Registra actor, las tres marcas temporales, versión afectada y el detalle del cambio (bita_detalle: diferencias; nunca contraseñas). También recibe los accesos a datos personales.

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `bita_id` | bigint (identidad) | sí |  | Identificador del registro (clave primaria). |
| `bita_t_registro` | timestamptz | sí | now() | Momento (reloj del servidor) en que se escribió la entrada de bitácora. |
| `bita_tabla` | varchar | sí |  | Nombre de la tabla afectada. |
| `bita_registro` | varchar | sí |  | Clave primaria del registro afectado, en texto. |
| `bita_accion` | varchar | sí |  | Operación auditada: INSERT, UPDATE, DELETE, ACCESO (lectura de datos personales) o SYNC. |
| `bita_version` | integer | no |  | Número de versión del registro: 1 = alta; n+1 = corrección. Append-only (ADR-03). |
| `usua_id` | integer | no |  | Usuario que realizó/capturó la acción. |
| `disp_id` | uuid | no |  | Dispositivo que capturó el registro. |
| `bita_t_observacion` | timestamptz | no |  | Momento en que ocurrió lo observado (ADR-02); orden canónico del registro. Inmutable entre versiones (RN-009). |
| `bita_t_captura` | timestamptz | no |  | Momento en que el dato se guardó, según el reloj del dispositivo (no puede ser anterior a t_observacion). |
| `bita_t_sincronizacion` | timestamptz | no |  | Momento en que el servidor recibió el dato (reloj del servidor, asignado por trigger; el cliente no lo controla). |
| `bita_detalle` | jsonb | no |  | Detalle del cambio en JSONB: fila completa (INSERT/DELETE) o pares antes/después (UPDATE). Nunca incluye contraseñas. |

- **Clave primaria:** `bita_id`
- **Se relaciona con:** (`usua_id`) → `usuario`; (`disp_id`) → `dispositivo`
- **Regla `bitacora_auditoria_accion_valida`:** `(((bita_accion)::text = ANY ((ARRAY['INSERT'::character varying, 'UPDATE'::character varying, 'DELETE'::character varying, 'ACCESO'::character varying, 'SYNC'::character varying])::text[])))`
- **Disparador:** solo inserción (UPDATE/DELETE/TRUNCATE bloqueados)


### `dispositivo` (prefijo `disp_`)

Instalación de la aplicación móvil (identificador generado en el primer arranque). Forma parte de la clave de idempotencia (disp_id, oper_cliente_id).

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `disp_id` | uuid | sí | gen_random_uuid() | Dispositivo que capturó el registro. |
| `disp_nombre` | varchar | no |  | Nombre descriptivo del dispositivo (opcional). |
| `disp_plataforma` | varchar | sí | 'otro'::character varying | android, ios u otro. |
| `disp_version_app` | varchar | no |  | Versión de la aplicación instalada. |
| `disp_registrado_en` | timestamptz | sí | now() | Momento en que el dispositivo se registró por primera vez. |
| `disp_ultima_sync` | timestamptz | no |  | Último momento en que el dispositivo sincronizó. |
| `disp_activo` | boolean | sí | true | Falso = dispositivo dado de baja; sus operaciones nuevas se rechazan. |

- **Clave primaria:** `disp_id`
- **Regla `dispositivo_plataforma_valida`:** `(((disp_plataforma)::text = ANY ((ARRAY['android'::character varying, 'ios'::character varying, 'otro'::character varying])::text[])))`


### `operacion_sync` (prefijo `oper_`)

Operación recibida desde un dispositivo (ADR-04, RF-062.066). La clave (disp_id, oper_cliente_id) hace idempotente el reintento (RN-010). Se inserta una sola vez (append-only); los reenvíos se registran en recepcion_sync. Las operaciones revisar/rechazada no crean filas en las tablas de dominio: su contenido queda en oper_payload hasta que el usuario las resuelva con una operación nueva (oper_resuelve_oper_id). oper_payload es el ÚNICO uso de JSONB para datos de negocio: sobre de transporte no consultable relacionalmente.

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `oper_id` | bigint (identidad) | sí |  | Operación de sincronización que creó el registro (idempotencia y trazabilidad). |
| `disp_id` | uuid | sí |  | Dispositivo que capturó el registro. |
| `oper_cliente_id` | uuid | sí |  | Identificador de la operación generado en el dispositivo (UUID); junto con disp_id es la clave de idempotencia. |
| `usua_id` | integer | sí |  | Usuario que realizó/capturó la acción. |
| `oper_entidad` | varchar | sí |  | Tabla de dominio a la que se refiere la operación. |
| `oper_accion` | varchar | sí |  | crear, corregir (nueva versión) o anular. |
| `oper_registro_id` | uuid | sí |  | Identificador lógico del registro afectado. |
| `oper_version` | integer | sí | 1 | Número de versión del registro: 1 = alta; n+1 = corrección. Append-only (ADR-03). |
| `oper_hash_contenido` | character(64) | sí |  | SHA-256 hex del contenido canónico. Mismo (disp_id, oper_cliente_id) con hash distinto = conflicto (RN-010). |
| `oper_clasificacion` | sigat.d_clasificacion_operacion | sí |  | Clasificación del servidor (ADR-04): alta_nueva, alta_retroactiva, correccion, revisar o rechazada. |
| `oper_motivo` | varchar | no |  | Motivo de la clasificación (obligatorio si revisar o rechazada). |
| `oper_t_captura` | timestamptz | sí |  | Momento en que el dato se guardó, según el reloj del dispositivo (no puede ser anterior a t_observacion). |
| `oper_t_recepcion` | timestamptz | sí | now() | Momento (servidor) en que se recibió por primera vez la operación. |
| `oper_deriva_reloj_seg` | integer | no |  | [ud: s] Diferencia detectada entre el reloj del dispositivo y el del servidor (RDD-010); nulo si no se detectó. |
| `oper_resuelve_oper_id` | bigint | no |  | Referencia a operacion_sync(oper_id). |
| `oper_payload` | jsonb | no |  | Sobre de transporte recibido (JSONB). Obligatorio solo en operaciones revisar/rechazada; no se consulta relacionalmente. |

- **Clave primaria:** `oper_id`
- **No se puede repetir:** (`disp_id`, `oper_cliente_id`)
- **Se relaciona con:** (`disp_id`) → `dispositivo`; (`usua_id`) → `usuario`; (`oper_resuelve_oper_id`) → `operacion_sync`
- **Regla `operacion_sync_accion_valida`:** `(((oper_accion)::text = ANY ((ARRAY['crear'::character varying, 'corregir'::character varying, 'anular'::character varying])::text[])))`
- **Regla `operacion_sync_clasificacion_original`:** `(((oper_clasificacion)::text <> 'idempotente_repetida'::text))`
- **Regla `operacion_sync_entidad_valida`:** `(oper_entidad IN ('visita','lectura_trampa','aplicacion_fitosanitaria','cosecha','etapa_declarada','hallazgo','bpa_verificacion','manejo_agronomico','estimacion_produccion'))`
- **Regla `operacion_sync_hash_formato`:** `((oper_hash_contenido ~ '^[0-9a-f]{64}$'::text))`
- **Regla `operacion_sync_motivo_requerido`:** `((((oper_clasificacion)::text <> ALL (ARRAY['revisar'::text, 'rechazada'::text])) OR ((oper_motivo IS NOT NULL) AND (oper_payload IS NOT NULL))))`
- **Regla `operacion_sync_version_positiva`:** `((oper_version >= 1))`
- **Disparador:** solo inserción (UPDATE/DELETE/TRUNCATE bloqueados)


### `recepcion_sync` (prefijo `rece_`)

Registro append-only de cada reenvío de una operación ya recibida: idempotente_repetida (mismo hash, no produce duplicados) o conflicto_contenido (mismo identificador, contenido distinto → se rechaza y se reporta, RN-010).

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `rece_id` | bigint (identidad) | sí |  | Identificador del registro (clave primaria). |
| `oper_id` | bigint | sí |  | Operación de sincronización que creó el registro (idempotencia y trazabilidad). |
| `rece_t` | timestamptz | sí | now() | Momento (servidor) del reenvío. |
| `rece_hash` | character(64) | sí |  | SHA-256 del contenido recibido en el reenvío. |
| `rece_resultado` | varchar | sí |  | idempotente_repetida (mismo contenido) o conflicto_contenido (mismo identificador, contenido distinto). |

- **Clave primaria:** `rece_id`
- **Se relaciona con:** (`oper_id`) → `operacion_sync`
- **Regla `recepcion_sync_hash_formato`:** `((rece_hash ~ '^[0-9a-f]{64}$'::text))`
- **Regla `recepcion_sync_resultado_valido`:** `(((rece_resultado)::text = ANY ((ARRAY['idempotente_repetida'::character varying, 'conflicto_contenido'::character varying])::text[])))`
- **Disparador:** solo inserción (UPDATE/DELETE/TRUNCATE bloqueados)


## Área 6 · Registros de campo


### `aplicacion_fitosanitaria` (prefijo `apli_`)

RF-040/RDD-008: aplicación fitosanitaria por lote. Autorreporte: no alimenta el MTD ni el concepto (RN-014). Responsable: persona registrada o, si es externo, nombre libre (denormalización controlada por CHECK: al menos uno).

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `apli_id` | uuid | sí | gen_random_uuid() | Identificador del registro (clave primaria). |
| `apli_registro_id` | uuid | sí |  | Identificador lógico del registro: igual en todas sus versiones (el cliente lo genera, UUID v7). |
| `apli_version` | integer | sí | 1 | Número de versión del registro: 1 = alta; n+1 = corrección. Append-only (ADR-03). |
| `lote_id` | integer | sí |  | Referencia a lote(lote_id). |
| `prof_id` | integer | no |  | Referencia a producto_fitosanitario(prof_id). |
| `apli_producto_texto` | varchar | no |  | Nombre del producto escrito por el productor cuando no está en el catálogo (frontend: campo libre). Obligatorio si prof_id es nulo. |
| `apli_dosis` | numeric(12,4) | sí |  | Dosis con unidad en apli_dosis_uni_id (RN-017). Las unidades admitidas están por definir (pendiente). |
| `apli_dosis_uni_id` | integer | sí |  | Referencia a unidad_medida(unid_id). |
| `apli_area_tratada` | numeric(12,4) | sí |  | Área tratada con unidad en apli_area_uni_id (normalmente ha). |
| `apli_area_uni_id` | integer | sí |  | Referencia a unidad_medida(unid_id). |
| `pers_cc_responsable` | bigint | no |  | Referencia a persona(pers_cc). |
| `apli_responsable_nombre` | varchar | no |  | Nombre del responsable cuando es una persona no registrada (externo). Obligatorio si pers_cc_responsable es nulo. |
| `apli_observaciones` | text | no |  | Observaciones libres del productor sobre la aplicación. |
| `apli_linaje` | sigat.d_linaje | sí | 'autorreporte'::text | Linaje del dato (RN-014): inspeccion_oficial o autorreporte. |
| `usua_id` | integer | sí |  | Usuario que realizó/capturó la acción. |
| `disp_id` | uuid | sí |  | Dispositivo que capturó el registro. |
| `oper_id` | bigint | sí |  | Operación de sincronización que creó el registro (idempotencia y trazabilidad). |
| `apli_t_observacion` | timestamptz | sí |  | Momento en que ocurrió lo observado (ADR-02); orden canónico del registro. Inmutable entre versiones (RN-009). |
| `apli_t_captura` | timestamptz | sí |  | Momento en que el dato se guardó, según el reloj del dispositivo (no puede ser anterior a t_observacion). |
| `apli_t_sincronizacion` | timestamptz | sí | now() | Momento en que el servidor recibió el dato (reloj del servidor, asignado por trigger; el cliente no lo controla). |
| `apli_deriva_reloj_seg` | integer | no |  | [ud: s] Diferencia detectada entre el reloj del dispositivo y el del servidor (RDD-010); nulo si no se detectó. |
| `apli_anulada` | boolean | sí | false | Verdadero si esta versión anula el registro. Los registros no se borran (RN-009). |
| `apli_motivo_anulacion` | varchar | no |  | Motivo obligatorio cuando la versión es una anulación. |

- **Clave primaria:** `apli_id`
- **No se puede repetir:** (`oper_id`); (`apli_registro_id`, `apli_version`)
- **Se relaciona con:** (`pers_cc_responsable`) → `persona`; (`lote_id`) → `lote`; (`prof_id`) → `producto_fitosanitario`; (`apli_dosis_uni_id`) → `unidad_medida`; (`apli_area_uni_id`) → `unidad_medida`; (`usua_id`) → `usuario`; (`disp_id`) → `dispositivo`; (`oper_id`) → `operacion_sync`
- **Regla `aplicacion_fitosanitaria_anulacion_coherente`:** `(((NOT apli_anulada) OR ((apli_motivo_anulacion IS NOT NULL) AND (btrim((apli_motivo_anulacion)::text) <> ''::text))))`
- **Regla `aplicacion_fitosanitaria_area_positiva`:** `((apli_area_tratada > (0)::numeric))`
- **Regla `aplicacion_fitosanitaria_dosis_positiva`:** `((apli_dosis > (0)::numeric))`
- **Regla `aplicacion_fitosanitaria_producto_presente`:** `(((prof_id IS NOT NULL) OR ((apli_producto_texto IS NOT NULL) AND (btrim((apli_producto_texto)::text) <> ''::text))))`
- **Regla `aplicacion_fitosanitaria_responsable_presente`:** `(((pers_cc_responsable IS NOT NULL) OR ((apli_responsable_nombre IS NOT NULL) AND (btrim((apli_responsable_nombre)::text) <> ''::text))))`
- **Regla `aplicacion_fitosanitaria_tiempos_validos`:** `((apli_t_observacion <= apli_t_captura))`
- **Regla `aplicacion_fitosanitaria_version_positiva`:** `((apli_version >= 1))`
- **Disparador:** solo inserción (UPDATE/DELETE/TRUNCATE bloqueados)
- **Disparador:** versionado coherente + t_sincronizacion del servidor
- **Disparador:** auditoría en bitacora_auditoria


### `cosecha` (prefijo `cose_`)

RF-042/RDD-009: un único registro de cosecha con dos componentes (esperado y real). El componente real es completo o ausente (CHECK). Ambos volúmenes comparten la unidad cose_volumen_uni_id (RN-017). Autorreporte (RN-014).

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `cose_id` | uuid | sí | gen_random_uuid() | Identificador del registro (clave primaria). |
| `cose_registro_id` | uuid | sí |  | Identificador lógico del registro: igual en todas sus versiones (el cliente lo genera, UUID v7). |
| `cose_version` | integer | sí | 1 | Número de versión del registro: 1 = alta; n+1 = corrección. Append-only (ADR-03). |
| `lote_id` | integer | sí |  | Referencia a lote(lote_id). |
| `cose_fecha_esperada` | date | sí |  | Fecha esperada de cosecha. |
| `cose_volumen_esperado` | numeric(14,3) | sí |  | Volumen esperado, en la unidad cose_volumen_uni_id. |
| `cose_fecha_real` | date | no |  | Fecha en que realmente se cosechó; nula mientras no se coseche. |
| `cose_volumen_real` | numeric(14,3) | no |  | Volumen realmente recolectado, en cose_volumen_uni_id; nulo mientras no se coseche. |
| `cose_volumen_uni_id` | integer | sí |  | Referencia a unidad_medida(unid_id). |
| `cose_metodo_registro` | varchar | no |  | Método de registro (RDD-009). Vocabulario no definido en la documentación: texto libre hasta que se defina (pendiente). |
| `cose_observaciones` | text | no |  | Observaciones libres. |
| `cose_linaje` | sigat.d_linaje | sí | 'autorreporte'::text | Linaje del dato (RN-014): inspeccion_oficial o autorreporte. |
| `usua_id` | integer | sí |  | Usuario que realizó/capturó la acción. |
| `disp_id` | uuid | sí |  | Dispositivo que capturó el registro. |
| `oper_id` | bigint | sí |  | Operación de sincronización que creó el registro (idempotencia y trazabilidad). |
| `cose_t_observacion` | timestamptz | sí |  | Momento en que ocurrió lo observado (ADR-02); orden canónico del registro. Inmutable entre versiones (RN-009). |
| `cose_t_captura` | timestamptz | sí |  | Momento en que el dato se guardó, según el reloj del dispositivo (no puede ser anterior a t_observacion). |
| `cose_t_sincronizacion` | timestamptz | sí | now() | Momento en que el servidor recibió el dato (reloj del servidor, asignado por trigger; el cliente no lo controla). |
| `cose_deriva_reloj_seg` | integer | no |  | [ud: s] Diferencia detectada entre el reloj del dispositivo y el del servidor (RDD-010); nulo si no se detectó. |
| `cose_anulada` | boolean | sí | false | Verdadero si esta versión anula el registro. Los registros no se borran (RN-009). |
| `cose_motivo_anulacion` | varchar | no |  | Motivo obligatorio cuando la versión es una anulación. |

- **Clave primaria:** `cose_id`
- **No se puede repetir:** (`oper_id`); (`cose_registro_id`, `cose_version`)
- **Se relaciona con:** (`lote_id`) → `lote`; (`cose_volumen_uni_id`) → `unidad_medida`; (`usua_id`) → `usuario`; (`disp_id`) → `dispositivo`; (`oper_id`) → `operacion_sync`
- **Regla `cosecha_anulacion_coherente`:** `(((NOT cose_anulada) OR ((cose_motivo_anulacion IS NOT NULL) AND (btrim((cose_motivo_anulacion)::text) <> ''::text))))`
- **Regla `cosecha_real_completa`:** `(((cose_fecha_real IS NULL) = (cose_volumen_real IS NULL)))`
- **Regla `cosecha_tiempos_validos`:** `((cose_t_observacion <= cose_t_captura))`
- **Regla `cosecha_version_positiva`:** `((cose_version >= 1))`
- **Regla `cosecha_volumenes_validos`:** `(((cose_volumen_esperado >= (0)::numeric) AND ((cose_volumen_real IS NULL) OR (cose_volumen_real >= (0)::numeric))))`
- **Disparador:** solo inserción (UPDATE/DELETE/TRUNCATE bloqueados)
- **Disparador:** versionado coherente + t_sincronizacion del servidor
- **Disparador:** auditoría en bitacora_auditoria


### `etapa_declarada` (prefijo `etap_`)

RF-044 / RN-012: etapa fenológica DECLARADA por el productor o el técnico, con fecha, valor y autor. La etapa derivada se calcula (fenologia_regla + fecha de plantación) y se compara con esta para revisión del Agrónomo.

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `etap_id` | uuid | sí | gen_random_uuid() | Identificador del registro (clave primaria). |
| `etap_registro_id` | uuid | sí |  | Identificador lógico del registro: igual en todas sus versiones (el cliente lo genera, UUID v7). |
| `etap_version` | integer | sí | 1 | Número de versión del registro: 1 = alta; n+1 = corrección. Append-only (ADR-03). |
| `lote_id` | integer | sí |  | Referencia a lote(lote_id). |
| `feno_id` | integer | sí |  | Referencia a fenologia(feno_id). |
| `etap_linaje` | sigat.d_linaje | sí |  | Linaje del dato (RN-014): inspeccion_oficial o autorreporte. |
| `usua_id` | integer | sí |  | Usuario que realizó/capturó la acción. |
| `disp_id` | uuid | sí |  | Dispositivo que capturó el registro. |
| `oper_id` | bigint | sí |  | Operación de sincronización que creó el registro (idempotencia y trazabilidad). |
| `etap_t_observacion` | timestamptz | sí |  | Momento en que ocurrió lo observado (ADR-02); orden canónico del registro. Inmutable entre versiones (RN-009). |
| `etap_t_captura` | timestamptz | sí |  | Momento en que el dato se guardó, según el reloj del dispositivo (no puede ser anterior a t_observacion). |
| `etap_t_sincronizacion` | timestamptz | sí | now() | Momento en que el servidor recibió el dato (reloj del servidor, asignado por trigger; el cliente no lo controla). |
| `etap_deriva_reloj_seg` | integer | no |  | [ud: s] Diferencia detectada entre el reloj del dispositivo y el del servidor (RDD-010); nulo si no se detectó. |
| `etap_anulada` | boolean | sí | false | Verdadero si esta versión anula el registro. Los registros no se borran (RN-009). |
| `etap_motivo_anulacion` | varchar | no |  | Motivo obligatorio cuando la versión es una anulación. |

- **Clave primaria:** `etap_id`
- **No se puede repetir:** (`oper_id`); (`etap_registro_id`, `etap_version`)
- **Se relaciona con:** (`lote_id`) → `lote`; (`feno_id`) → `fenologia`; (`usua_id`) → `usuario`; (`disp_id`) → `dispositivo`; (`oper_id`) → `operacion_sync`
- **Regla `etapa_declarada_anulacion_coherente`:** `(((NOT etap_anulada) OR ((etap_motivo_anulacion IS NOT NULL) AND (btrim((etap_motivo_anulacion)::text) <> ''::text))))`
- **Regla `etapa_declarada_tiempos_validos`:** `((etap_t_observacion <= etap_t_captura))`
- **Regla `etapa_declarada_version_positiva`:** `((etap_version >= 1))`
- **Disparador:** solo inserción (UPDATE/DELETE/TRUNCATE bloqueados)
- **Disparador:** versionado coherente + t_sincronizacion del servidor
- **Disparador:** auditoría en bitacora_auditoria


### `lectura_trampa` (prefijo `lect_`)

Lectura de una trampa en una fecha (RF-020). Append-only: corregir = nueva versión con el mismo lect_registro_id; anular = versión con lect_anulada. lect_especimenes = total capturado SIN especie (la determinación de la especie queda fuera de este diseño: se retiró el módulo de laboratorio); NULL cuando la trampa no se leyó (lect_leida=false, p. ej. no encontrada) para no confundir "no leída" con "cero capturas" en el MTD. ubic_id fija la asignación trampa–lote vigente al observar (trazabilidad ADR-06; nulo = sin asignación, no entra al MTD, RN-013).

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `lect_id` | uuid | sí | gen_random_uuid() | Identificador del registro (clave primaria). |
| `lect_registro_id` | uuid | sí |  | Identificador lógico del registro: igual en todas sus versiones (el cliente lo genera, UUID v7). |
| `lect_version` | integer | sí | 1 | Número de versión del registro: 1 = alta; n+1 = corrección. Append-only (ADR-03). |
| `visi_id` | uuid | sí |  | Referencia a visita(visi_id). |
| `tram_id` | integer | sí |  | Trampa leída. Forma parte de la FK compuesta (ubic_id, tram_id) hacia ubicacion_trampa, que garantiza que la ubicación pertenece a esa trampa. |
| `ubic_id` | bigint | no |  | Referencia a ubicacion_trampa(ubic_id). |
| `lect_leida` | boolean | sí |  | Verdadero si la trampa se leyó; falso si no (p. ej. no encontrada). Distingue "no leída" de "cero capturas". |
| `lect_especimenes` | integer | no |  | [ud: especímenes (individuos)] Número de moscas capturadas. Nulo si lect_leida = false. |
| `lect_justificacion` | varchar | no |  | Motivo por el que la trampa no se leyó (obligatorio si lect_leida = falso). |
| `cond_id` | integer | sí |  | Referencia a condicion_trampa(cond_id). |
| `lect_fecha_cambio_cuerpo` | date | no |  | Fecha de cambio del cuerpo de la trampa informada en esta lectura (RF-021). |
| `lect_fecha_cambio_atrayente` | date | no |  | Fecha de cambio de atrayente informada en esta lectura (RF-021). Requiere atra_id. |
| `atra_id` | integer | no |  | Referencia a atrayente(atra_id). |
| `lect_observaciones` | text | no |  | Observaciones libres del técnico. |
| `lect_geom` | geometry(Point,4326) | no |  | Posición GPS del dispositivo al leer (evidencia de RF-012). Opcional. |
| `lect_precision_m` | real | no |  | [ud: m] Precisión horizontal reportada por el GPS al leer. |
| `lect_coincide_lote` | boolean | no |  | Resultado de la comparación trampa–lote–ubicación hecha por el dispositivo (RF-012). Falso = hubo advertencia y el usuario confirmó; no bloquea. |
| `lect_linaje` | sigat.d_linaje | sí | 'inspeccion_oficial'::text | Linaje del dato (RN-014): inspeccion_oficial o autorreporte. |
| `usua_id` | integer | sí |  | Usuario que realizó/capturó la acción. |
| `disp_id` | uuid | sí |  | Dispositivo que capturó el registro. |
| `oper_id` | bigint | sí |  | Operación de sincronización que creó el registro (idempotencia y trazabilidad). |
| `lect_t_observacion` | timestamptz | sí |  | Momento en que ocurrió lo observado (ADR-02); orden canónico del registro. Inmutable entre versiones (RN-009). |
| `lect_t_captura` | timestamptz | sí |  | Momento en que el dato se guardó, según el reloj del dispositivo (no puede ser anterior a t_observacion). |
| `lect_t_sincronizacion` | timestamptz | sí | now() | Momento en que el servidor recibió el dato (reloj del servidor, asignado por trigger; el cliente no lo controla). |
| `lect_deriva_reloj_seg` | integer | no |  | [ud: s] Diferencia detectada entre el reloj del dispositivo y el del servidor (RDD-010); nulo si no se detectó. |
| `lect_anulada` | boolean | sí | false | Verdadero si esta versión anula el registro. Los registros no se borran (RN-009). |
| `lect_motivo_anulacion` | varchar | no |  | Motivo obligatorio cuando la versión es una anulación. |

- **Clave primaria:** `lect_id`
- **No se puede repetir:** (`oper_id`); (`lect_registro_id`, `lect_version`)
- **Se relaciona con:** (`visi_id`) → `visita`; (`tram_id`) → `trampa`; (`ubic_id`, `tram_id`) → `ubicacion_trampa`; (`cond_id`) → `condicion_trampa`; (`atra_id`) → `atrayente`; (`usua_id`) → `usuario`; (`disp_id`) → `dispositivo`; (`oper_id`) → `operacion_sync`
- **Regla `lectura_trampa_anulacion_coherente`:** `(((NOT lect_anulada) OR ((lect_motivo_anulacion IS NOT NULL) AND (btrim((lect_motivo_anulacion)::text) <> ''::text))))`
- **Regla `lectura_trampa_atrayente_coherente`:** `(((lect_fecha_cambio_atrayente IS NULL) OR (atra_id IS NOT NULL)))`
- **Regla `lectura_trampa_conteo_coherente`:** `(((lect_leida AND (lect_especimenes IS NOT NULL) AND (lect_especimenes >= 0)) OR ((NOT lect_leida) AND (lect_especimenes IS NULL) AND (lect_justificacion IS NOT NULL) AND (btrim((lect_justificacion)::text) <> ''::text))))`
- **Regla `lectura_trampa_precision_valida`:** `(((lect_precision_m IS NULL) OR (lect_precision_m >= (0)::double precision)))`
- **Regla `lectura_trampa_tiempos_validos`:** `((lect_t_observacion <= lect_t_captura))`
- **Regla `lectura_trampa_version_positiva`:** `((lect_version >= 1))`
- **Disparador:** solo inserción (UPDATE/DELETE/TRUNCATE bloqueados)
- **Disparador:** versionado coherente + t_sincronizacion del servidor
- **Disparador:** auditoría en bitacora_auditoria


### `visita` (prefijo `visi_`)

Sesión de inspección de un técnico en un predio (RF-060, ADR-08). Solo llega al servidor ya cerrada. Solo las columnas de revisión (Agrónomo/Supervisor) admiten UPDATE. El estado de ciclo en el dispositivo (en progreso/completada/sincronizada) vive en la base local, no aquí.

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `visi_id` | uuid | sí | gen_random_uuid() | Identificador del registro (clave primaria). |
| `disp_id` | uuid | sí |  | Dispositivo que capturó el registro. |
| `oper_id` | bigint | sí |  | Operación de sincronización que creó el registro (idempotencia y trazabilidad). |
| `usua_id` | integer | sí |  | Usuario que realizó/capturó la acción. |
| `pred_id` | integer | sí |  | Referencia a predio(pred_id). |
| `ruta_id` | integer | no |  | Referencia a ruta(ruta_id). |
| `visi_t_inicio_obs` | timestamptz | sí |  | Momento observado de inicio de la visita (reloj del dispositivo). |
| `visi_t_fin_obs` | timestamptz | sí |  | Momento observado de cierre de la visita. |
| `visi_t_captura` | timestamptz | sí |  | Momento en que el dato se guardó, según el reloj del dispositivo (no puede ser anterior a t_observacion). |
| `visi_t_sincronizacion` | timestamptz | sí | now() | Momento en que el servidor recibió el dato (reloj del servidor, asignado por trigger; el cliente no lo controla). |
| `visi_deriva_reloj_seg` | integer | no |  | [ud: s] Diferencia detectada entre el reloj del dispositivo y el del servidor (RDD-010); nulo si no se detectó. |
| `visi_estado_revision` | sigat.d_estado_revision | sí | 'pendiente'::text | Revisión del Agrónomo/Supervisor (origen: frontend; confirmar como regla institucional). |
| `visi_motivo_revision` | varchar | no |  | Motivo cuando la visita pasa a revisión. |
| `visi_revisada_por` | integer | no |  | Referencia a usuario(usua_id). |
| `visi_revisada_en` | timestamptz | no |  | Momento de la última revisión del Agrónomo/Supervisor. |

- **Clave primaria:** `visi_id`
- **No se puede repetir:** (`oper_id`); (`visi_id`, `pred_id`)
- **Se relaciona con:** (`oper_id`) → `operacion_sync`; (`usua_id`) → `usuario`; (`pred_id`) → `predio`; (`ruta_id`) → `ruta`; (`visi_revisada_por`) → `usuario`; (`disp_id`) → `dispositivo`
- **Regla `visita_revision_coherente`:** `((((visi_estado_revision)::text = 'pendiente'::text) = ((visi_revisada_por IS NULL) AND (visi_revisada_en IS NULL))))`
- **Regla `visita_tiempos_validos`:** `(((visi_t_fin_obs >= visi_t_inicio_obs) AND (visi_t_fin_obs <= visi_t_captura)))`
- **Disparador:** t_sincronizacion del servidor; solo columnas de revisión modificables; no se borra
- **Disparador:** auditoría en bitacora_auditoria


### `visita_lote` (prefijo `visl_`)

Relación N:M visita–lote (lotes cubiertos). pred_id se repite para garantizar por FK compuestas que visita y lote pertenecen al mismo predio.

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `visi_id` | uuid | sí |  | Referencia a visita(visi_id). |
| `lote_id` | integer | sí |  | Referencia a lote(lote_id). |
| `pred_id` | integer | sí |  | Predio de la visita. Forma parte de las FK compuestas (visi_id, pred_id) hacia visita y (lote_id, pred_id) hacia lote: el lote visitado debe ser del predio visitado. |

- **Clave primaria:** `visi_id`, `lote_id`
- **Se relaciona con:** (`visi_id`, `pred_id`) → `visita`; (`lote_id`, `pred_id`) → `lote`
- **Disparador:** solo inserción (UPDATE/DELETE/TRUNCATE bloqueados)


## Área 7 · MTD y concepto


### `concepto_aptitud` (prefijo `conc_`)

RF-024/RF-054: concepto de aptitud del lote por periodo, con norma aplicada y fecha de efecto; las reemisiones son versiones nuevas (no se sobrescribe). "no_emitido" cuando no hay umbral configurado (UQQ-004): el sistema no inventa el valor.

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `conc_id` | bigint (identidad) | sí |  | Identificador del registro (clave primaria). |
| `lote_id` | integer | sí |  | Lote evaluado. Forma parte de la FK compuesta (peri_id, lote_id) hacia periodo_trampeo y de la FK hacia lote: el periodo debe ser del mismo lote. |
| `peri_id` | bigint | sí |  | Periodo de trampeo evaluado. Forma parte de las FK compuestas (peri_id, lote_id) hacia periodo_trampeo y (indi_id, peri_id) hacia indice_mtd. |
| `indi_id` | bigint | sí |  | Referencia a indice_mtd(indi_id). |
| `conc_version` | integer | sí | 1 | Número de versión del registro: 1 = alta; n+1 = corrección. Append-only (ADR-03). |
| `conc_resultado` | varchar | sí |  | apto, no_apto o no_emitido (no_emitido = sin umbral configurado, UQQ-004). |
| `conc_fecha_efecto` | date | sí |  | Fecha desde la cual rige el concepto emitido (en una reemisión por corrección retroactiva puede ser anterior a la fecha de emisión). |
| `norm_id` | integer | no |  | Referencia a norma(norm_id). |
| `conc_emitido_en` | timestamptz | sí | now() | Momento (servidor) en que se emitió esta versión del concepto. |
| `conc_motivo` | varchar | no |  | Motivo de la reemisión (obligatorio desde la versión 2). |

- **Clave primaria:** `conc_id`
- **No se puede repetir:** (`lote_id`, `peri_id`, `conc_version`)
- **Se relaciona con:** (`lote_id`) → `lote`; (`peri_id`, `lote_id`) → `periodo_trampeo`; (`indi_id`, `peri_id`) → `indice_mtd`; (`norm_id`) → `norma`
- **Regla `concepto_aptitud_norma_requerida`:** `((((conc_resultado)::text = 'no_emitido'::text) = (norm_id IS NULL)))`
- **Regla `concepto_aptitud_reemision_motivada`:** `(((conc_version = 1) OR ((conc_motivo IS NOT NULL) AND (btrim((conc_motivo)::text) <> ''::text))))`
- **Regla `concepto_aptitud_resultado_valido`:** `(((conc_resultado)::text = ANY ((ARRAY['apto'::character varying, 'no_apto'::character varying, 'no_emitido'::character varying])::text[])))`
- **Regla `concepto_aptitud_version_positiva`:** `((conc_version >= 1))`
- **Disparador:** solo inserción (UPDATE/DELETE/TRUNCATE bloqueados)
- **Disparador:** auditoría en bitacora_auditoria


### `indice_mtd` (prefijo `indi_`)

RDD-006 / RN-001: MTD = M / (T × D) por periodo y especie (espm_id nulo = total sin especie diagnosticada; qué se emite en el MVP queda pendiente). M, T y D se guardan junto al resultado para trazabilidad; indi_valor es columna GENERADA (la fórmula vive en la base y no puede divergir). El umbral y la norma aplicados se copian (instantánea) para que un cambio de umbral no altere resultados históricos (RDD-007). Append-only: el recálculo crea una versión nueva con motivo.

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `indi_id` | bigint (identidad) | sí |  | Identificador del registro (clave primaria). |
| `peri_id` | bigint | sí |  | Referencia a periodo_trampeo(peri_id). |
| `espm_id` | integer | no |  | Referencia a especie_mosca(espm_id). |
| `indi_version` | integer | sí | 1 | Número de versión del registro: 1 = alta; n+1 = corrección. Append-only (ADR-03). |
| `indi_moscas` | integer | sí |  | [ud: moscas] M = total de moscas capturadas en las trampas atendidas. |
| `indi_trampas` | integer | sí |  | [ud: trampas] T = número de trampas atendidas. |
| `indi_dias_exposicion` | numeric(8,3) | sí |  | [ud: días] D = número promedio de días de exposición de las trampas. |
| `indi_valor` | numeric(14,6) (generada) | no |  | [ud: moscas/trampa/día] Nulo si T×D = 0. |
| `indi_unidad` | varchar | sí | 'moscas/trampa/día'::character varying | Unidad fija del MTD: moscas/trampa/día (RN-017). |
| `indi_umbral_aplicado` | numeric(10,4) | no |  | [ud: moscas/trampa/día] Umbral de exportación vigente a la fecha del periodo (copia). Nulo = no había umbral configurado (UQQ-004). |
| `norm_id` | integer | no |  | Referencia a norma(norm_id). |
| `indi_resultado_contraste` | sigat.d_resultado_contraste | sí |  | Resultado de contrastar el MTD con el umbral vigente (RF-024). |
| `esce_id` | integer | no |  | Escenario de trampeo (RN-002) en que cae el MTD, si el programa tiene límites configurados. |
| `indi_calculado_en` | timestamptz | sí | now() | Momento (servidor) en que se calculó esta versión. |
| `indi_motivo_recalculo` | varchar | no |  | Motivo del recálculo (obligatorio desde la versión 2), p. ej. llegada de una lectura retroactiva. |

- **Clave primaria:** `indi_id`
- **No se puede repetir:** (`indi_id`, `peri_id`)
- **Se relaciona con:** (`peri_id`) → `periodo_trampeo`; (`espm_id`) → `especie_mosca`; (`norm_id`) → `norma`; (`esce_id`) → `escenario_trampeo`
- **Regla `indice_mtd_componentes_validos`:** `(((indi_moscas >= 0) AND (indi_trampas >= 0) AND (indi_dias_exposicion >= (0)::numeric)))`
- **Regla `indice_mtd_contraste_coherente`:** `((indi_resultado_contraste = 'sin_umbral' AND indi_umbral_aplicado IS NULL AND norm_id IS NULL) OR (indi_resultado_contraste <> 'sin_umbral' AND indi_umbral_aplicado IS NOT NULL AND norm_id IS NOT NULL AND indi_valor IS NOT NULL))`
- **Regla `indice_mtd_recalculo_motivado`:** `(((indi_version = 1) OR ((indi_motivo_recalculo IS NOT NULL) AND (btrim((indi_motivo_recalculo)::text) <> ''::text))))`
- **Regla `indice_mtd_umbral_valido`:** `(((indi_umbral_aplicado IS NULL) OR (indi_umbral_aplicado >= (0)::numeric)))`
- **Regla `indice_mtd_unidad_fija`:** `(((indi_unidad)::text = 'moscas/trampa/día'::text))`
- **Regla `indice_mtd_version_positiva`:** `((indi_version >= 1))`
- **Disparador:** solo inserción (UPDATE/DELETE/TRUNCATE bloqueados)
- **Disparador:** auditoría en bitacora_auditoria


### `indice_mtd_lectura` (prefijo `indm_`)

Trazabilidad N:M: qué versiones exactas de lectura sustentan cada MTD (RN-013: el conjunto de trampas que sustenta un MTD queda determinado de forma explícita). Permite saber qué MTD se ven afectados cuando llega una corrección retroactiva (RF-054).

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `indi_id` | bigint | sí |  | Referencia a indice_mtd(indi_id). |
| `lect_id` | uuid | sí |  | Referencia a lectura_trampa(lect_id). |

- **Clave primaria:** `indi_id`, `lect_id`
- **Se relaciona con:** (`indi_id`) → `indice_mtd`; (`lect_id`) → `lectura_trampa`
- **Disparador:** solo inserción (UPDATE/DELETE/TRUNCATE bloqueados)


### `periodo_trampeo` (prefijo `peri_`)

RF-022: periodo de trampeo de un lote y tipo de muestreo (ventana [inicio, fin]). Dos periodos del mismo lote y tipo no se solapan (RN-011: una lectura dentro de una ventana ya cubierta se marca "revisar"). prog_id fija la versión de programa aplicable a la fecha del periodo (RN-003).

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `peri_id` | bigint (identidad) | sí |  | Identificador del registro (clave primaria). |
| `lote_id` | integer | sí |  | Referencia a lote(lote_id). |
| `vigi_id` | integer | sí |  | Referencia a vigilancia(vigi_id). |
| `prog_id` | integer | sí |  | Referencia a programa_inspeccion(prog_id). |
| `peri_inicio` | date | sí |  | Primer día del periodo (inclusive). |
| `peri_fin` | date | sí |  | Último día del periodo (inclusive). |
| `peri_estado` | varchar | sí | 'abierto'::character varying | abierto (aún recibe lecturas) o cerrado. |
| `peri_creado_en` | timestamptz | sí | now() | Momento en que se creó el periodo. |

- **Clave primaria:** `peri_id`
- **No se puede repetir:** (`peri_id`, `lote_id`)
- **Se relaciona con:** (`lote_id`) → `lote`; (`vigi_id`) → `vigilancia`; (`prog_id`) → `programa_inspeccion`
- **Regla `periodo_trampeo_estado_valido`:** `(((peri_estado)::text = ANY ((ARRAY['abierto'::character varying, 'cerrado'::character varying])::text[])))`
- **Regla `periodo_trampeo_rango_valido`:** `((peri_fin >= peri_inicio))`
- **Sin solapamiento `periodo_trampeo_sin_solape`:** `lote_id WITH =, vigi_id WITH =, daterange(peri_inicio, peri_fin, '[]') WITH &&`


## Área 8 · Fase2 hallazgos BPA produccion


### `bpa_verificacion` (prefijo `bpav_`)

RF-028 / RDD-012: resultado de cada criterio de BPA por lote y por visita (cumplimiento + observación). Evidencia fotográfica opcional: diferida (X-03).

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `bpav_id` | uuid | sí | gen_random_uuid() | Identificador del registro (clave primaria). |
| `bpav_registro_id` | uuid | sí |  | Identificador lógico del registro: igual en todas sus versiones (el cliente lo genera, UUID v7). |
| `bpav_version` | integer | sí | 1 | Número de versión del registro: 1 = alta; n+1 = corrección. Append-only (ADR-03). |
| `visi_id` | uuid | sí |  | Referencia a visita_lote(visi_id). |
| `lote_id` | integer | sí |  | Referencia a visita_lote(lote_id). |
| `crit_id` | integer | sí |  | Referencia a criterio_bpa(crit_id). |
| `bpav_cumple` | boolean | sí |  | Resultado del criterio de BPA en el lote y la visita: cumple (verdadero) o no cumple. |
| `bpav_observacion` | text | no |  | Observación del inspector sobre el criterio. |
| `bpav_linaje` | sigat.d_linaje | sí | 'inspeccion_oficial'::text | Linaje del dato (RN-014): inspeccion_oficial o autorreporte. |
| `usua_id` | integer | sí |  | Usuario que realizó/capturó la acción. |
| `disp_id` | uuid | sí |  | Dispositivo que capturó el registro. |
| `oper_id` | bigint | sí |  | Operación de sincronización que creó el registro (idempotencia y trazabilidad). |
| `bpav_t_observacion` | timestamptz | sí |  | Momento en que ocurrió lo observado (ADR-02); orden canónico del registro. Inmutable entre versiones (RN-009). |
| `bpav_t_captura` | timestamptz | sí |  | Momento en que el dato se guardó, según el reloj del dispositivo (no puede ser anterior a t_observacion). |
| `bpav_t_sincronizacion` | timestamptz | sí | now() | Momento en que el servidor recibió el dato (reloj del servidor, asignado por trigger; el cliente no lo controla). |
| `bpav_deriva_reloj_seg` | integer | no |  | [ud: s] Diferencia detectada entre el reloj del dispositivo y el del servidor (RDD-010); nulo si no se detectó. |
| `bpav_anulada` | boolean | sí | false | Verdadero si esta versión anula el registro. Los registros no se borran (RN-009). |
| `bpav_motivo_anulacion` | varchar | no |  | Motivo obligatorio cuando la versión es una anulación. |

- **Clave primaria:** `bpav_id`
- **No se puede repetir:** (`oper_id`); (`bpav_registro_id`, `bpav_version`)
- **Se relaciona con:** (`visi_id`, `lote_id`) → `visita_lote`; (`crit_id`) → `criterio_bpa`; (`usua_id`) → `usuario`; (`disp_id`) → `dispositivo`; (`oper_id`) → `operacion_sync`
- **Regla `bpa_verificacion_anulacion_coherente`:** `(((NOT bpav_anulada) OR ((bpav_motivo_anulacion IS NOT NULL) AND (btrim((bpav_motivo_anulacion)::text) <> ''::text))))`
- **Regla `bpa_verificacion_tiempos_validos`:** `((bpav_t_observacion <= bpav_t_captura))`
- **Regla `bpa_verificacion_version_positiva`:** `((bpav_version >= 1))`
- **Disparador:** solo inserción (UPDATE/DELETE/TRUNCATE bloqueados)
- **Disparador:** versionado coherente + t_sincronizacion del servidor
- **Disparador:** auditoría en bitacora_auditoria


### `criterio_bpa` (prefijo `crit_`)

Criterio del checklist de Buenas Prácticas Agrícolas (RF-028, RF-081). Sin valores oficiales en la documentación.

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `crit_id` | integer (identidad) | sí |  | Identificador del registro (clave primaria). |
| `crit_descripcion` | varchar | sí |  | Texto descriptivo del valor del catálogo (único, no vacío). |
| `crit_activo` | boolean | sí | true | Falso = criterio retirado del catálogo. |

- **Clave primaria:** `crit_id`
- **No se puede repetir:** (`crit_descripcion`)
- **Regla `criterio_bpa_descripcion_no_vacia`:** `((btrim((crit_descripcion)::text) <> ''::text))`


### `estimacion_produccion` (prefijo `esti_`)

RF-030: producción esperada de un lote = número de árboles × rendimiento por árbol. El total NO se almacena: es derivado.

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `esti_id` | uuid | sí | gen_random_uuid() | Identificador del registro (clave primaria). |
| `esti_registro_id` | uuid | sí |  | Identificador lógico del registro: igual en todas sus versiones (el cliente lo genera, UUID v7). |
| `esti_version` | integer | sí | 1 | Número de versión del registro: 1 = alta; n+1 = corrección. Append-only (ADR-03). |
| `lote_id` | integer | sí |  | Referencia a lote(lote_id). |
| `esti_num_arboles` | integer | sí |  | [ud: árboles] Número de árboles considerados en la estimación. |
| `esti_rendimiento_arbol` | numeric(12,3) | sí |  | Rendimiento esperado por árbol, en la unidad esti_rendimiento_uni_id (p. ej. kg por árbol). |
| `esti_rendimiento_uni_id` | integer | sí |  | Referencia a unidad_medida(unid_id). |
| `esti_metodo` | varchar | sí |  | Método de estimación empleado (RF-030). Texto libre hasta definir vocabulario. |
| `esti_linaje` | sigat.d_linaje | sí | 'autorreporte'::text | Linaje del dato (RN-014): inspeccion_oficial o autorreporte. |
| `usua_id` | integer | sí |  | Usuario que realizó/capturó la acción. |
| `disp_id` | uuid | sí |  | Dispositivo que capturó el registro. |
| `oper_id` | bigint | sí |  | Operación de sincronización que creó el registro (idempotencia y trazabilidad). |
| `esti_t_observacion` | timestamptz | sí |  | Momento en que ocurrió lo observado (ADR-02); orden canónico del registro. Inmutable entre versiones (RN-009). |
| `esti_t_captura` | timestamptz | sí |  | Momento en que el dato se guardó, según el reloj del dispositivo (no puede ser anterior a t_observacion). |
| `esti_t_sincronizacion` | timestamptz | sí | now() | Momento en que el servidor recibió el dato (reloj del servidor, asignado por trigger; el cliente no lo controla). |
| `esti_deriva_reloj_seg` | integer | no |  | [ud: s] Diferencia detectada entre el reloj del dispositivo y el del servidor (RDD-010); nulo si no se detectó. |
| `esti_anulada` | boolean | sí | false | Verdadero si esta versión anula el registro. Los registros no se borran (RN-009). |
| `esti_motivo_anulacion` | varchar | no |  | Motivo obligatorio cuando la versión es una anulación. |

- **Clave primaria:** `esti_id`
- **No se puede repetir:** (`oper_id`); (`esti_registro_id`, `esti_version`)
- **Se relaciona con:** (`lote_id`) → `lote`; (`esti_rendimiento_uni_id`) → `unidad_medida`; (`usua_id`) → `usuario`; (`disp_id`) → `dispositivo`; (`oper_id`) → `operacion_sync`
- **Regla `estimacion_produccion_anulacion_coherente`:** `(((NOT esti_anulada) OR ((esti_motivo_anulacion IS NOT NULL) AND (btrim((esti_motivo_anulacion)::text) <> ''::text))))`
- **Regla `estimacion_produccion_metodo_no_vacio`:** `((btrim((esti_metodo)::text) <> ''::text))`
- **Regla `estimacion_produccion_tiempos_validos`:** `((esti_t_observacion <= esti_t_captura))`
- **Regla `estimacion_produccion_valores_positivos`:** `(((esti_num_arboles > 0) AND (esti_rendimiento_arbol > (0)::numeric)))`
- **Regla `estimacion_produccion_version_positiva`:** `((esti_version >= 1))`
- **Disparador:** solo inserción (UPDATE/DELETE/TRUNCATE bloqueados)
- **Disparador:** versionado coherente + t_sincronizacion del servidor
- **Disparador:** auditoría en bitacora_auditoria


### `hallazgo` (prefijo `hall_`)

RF-029 / RDD-012: hallazgo fitosanitario (plaga, enfermedad u hongo) observado en un lote, con celda opcional y punto opcional (el marcado geográfico preciso RF-010 se difiere a v0.4, X-05).

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `hall_id` | uuid | sí | gen_random_uuid() | Identificador del registro (clave primaria). |
| `hall_registro_id` | uuid | sí |  | Identificador lógico del registro: igual en todas sus versiones (el cliente lo genera, UUID v7). |
| `hall_version` | integer | sí | 1 | Número de versión del registro: 1 = alta; n+1 = corrección. Append-only (ADR-03). |
| `lote_id` | integer | sí |  | Referencia a lote(lote_id). |
| `retc_id` | bigint | no |  | Referencia a reticula_celda(retc_id). |
| `plag_id` | integer | sí |  | Referencia a plaga_enfermedad(plag_id). |
| `seve_id` | integer | sí |  | Referencia a severidad(seve_id). |
| `hall_geom` | geometry(Point,4326) | no |  | Punto del hallazgo en el mapa (opcional; el marcado preciso RF-010 se difiere a v0.4). |
| `hall_observaciones` | text | no |  | Observaciones libres del hallazgo. |
| `hall_linaje` | sigat.d_linaje | sí |  | Linaje del dato (RN-014): inspeccion_oficial o autorreporte. |
| `usua_id` | integer | sí |  | Usuario que realizó/capturó la acción. |
| `disp_id` | uuid | sí |  | Dispositivo que capturó el registro. |
| `oper_id` | bigint | sí |  | Operación de sincronización que creó el registro (idempotencia y trazabilidad). |
| `hall_t_observacion` | timestamptz | sí |  | Momento en que ocurrió lo observado (ADR-02); orden canónico del registro. Inmutable entre versiones (RN-009). |
| `hall_t_captura` | timestamptz | sí |  | Momento en que el dato se guardó, según el reloj del dispositivo (no puede ser anterior a t_observacion). |
| `hall_t_sincronizacion` | timestamptz | sí | now() | Momento en que el servidor recibió el dato (reloj del servidor, asignado por trigger; el cliente no lo controla). |
| `hall_deriva_reloj_seg` | integer | no |  | [ud: s] Diferencia detectada entre el reloj del dispositivo y el del servidor (RDD-010); nulo si no se detectó. |
| `hall_anulada` | boolean | sí | false | Verdadero si esta versión anula el registro. Los registros no se borran (RN-009). |
| `hall_motivo_anulacion` | varchar | no |  | Motivo obligatorio cuando la versión es una anulación. |

- **Clave primaria:** `hall_id`
- **No se puede repetir:** (`oper_id`); (`hall_registro_id`, `hall_version`)
- **Se relaciona con:** (`lote_id`) → `lote`; (`retc_id`) → `reticula_celda`; (`plag_id`) → `plaga_enfermedad`; (`seve_id`) → `severidad`; (`usua_id`) → `usuario`; (`disp_id`) → `dispositivo`; (`oper_id`) → `operacion_sync`
- **Regla `hallazgo_anulacion_coherente`:** `(((NOT hall_anulada) OR ((hall_motivo_anulacion IS NOT NULL) AND (btrim((hall_motivo_anulacion)::text) <> ''::text))))`
- **Regla `hallazgo_tiempos_validos`:** `((hall_t_observacion <= hall_t_captura))`
- **Regla `hallazgo_version_positiva`:** `((hall_version >= 1))`
- **Disparador:** solo inserción (UPDATE/DELETE/TRUNCATE bloqueados)
- **Disparador:** versionado coherente + t_sincronizacion del servidor
- **Disparador:** auditoría en bitacora_auditoria


### `manejo_agronomico` (prefijo `mane_`)

RF-043 (Could): operación de manejo aplicada a un lote.

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `mane_id` | uuid | sí | gen_random_uuid() | Identificador del registro (clave primaria). |
| `mane_registro_id` | uuid | sí |  | Identificador lógico del registro: igual en todas sus versiones (el cliente lo genera, UUID v7). |
| `mane_version` | integer | sí | 1 | Número de versión del registro: 1 = alta; n+1 = corrección. Append-only (ADR-03). |
| `lote_id` | integer | sí |  | Referencia a lote(lote_id). |
| `tipm_id` | integer | sí |  | Referencia a tipo_manejo(tipm_id). |
| `mane_observaciones` | text | no |  | Observaciones libres de la operación. |
| `mane_linaje` | sigat.d_linaje | sí | 'autorreporte'::text | Linaje del dato (RN-014): inspeccion_oficial o autorreporte. |
| `usua_id` | integer | sí |  | Usuario que realizó/capturó la acción. |
| `disp_id` | uuid | sí |  | Dispositivo que capturó el registro. |
| `oper_id` | bigint | sí |  | Operación de sincronización que creó el registro (idempotencia y trazabilidad). |
| `mane_t_observacion` | timestamptz | sí |  | Momento en que ocurrió lo observado (ADR-02); orden canónico del registro. Inmutable entre versiones (RN-009). |
| `mane_t_captura` | timestamptz | sí |  | Momento en que el dato se guardó, según el reloj del dispositivo (no puede ser anterior a t_observacion). |
| `mane_t_sincronizacion` | timestamptz | sí | now() | Momento en que el servidor recibió el dato (reloj del servidor, asignado por trigger; el cliente no lo controla). |
| `mane_deriva_reloj_seg` | integer | no |  | [ud: s] Diferencia detectada entre el reloj del dispositivo y el del servidor (RDD-010); nulo si no se detectó. |
| `mane_anulada` | boolean | sí | false | Verdadero si esta versión anula el registro. Los registros no se borran (RN-009). |
| `mane_motivo_anulacion` | varchar | no |  | Motivo obligatorio cuando la versión es una anulación. |

- **Clave primaria:** `mane_id`
- **No se puede repetir:** (`oper_id`); (`mane_registro_id`, `mane_version`)
- **Se relaciona con:** (`disp_id`) → `dispositivo`; (`oper_id`) → `operacion_sync`; (`lote_id`) → `lote`; (`tipm_id`) → `tipo_manejo`; (`usua_id`) → `usuario`
- **Regla `manejo_agronomico_anulacion_coherente`:** `(((NOT mane_anulada) OR ((mane_motivo_anulacion IS NOT NULL) AND (btrim((mane_motivo_anulacion)::text) <> ''::text))))`
- **Regla `manejo_agronomico_tiempos_validos`:** `((mane_t_observacion <= mane_t_captura))`
- **Regla `manejo_agronomico_version_positiva`:** `((mane_version >= 1))`
- **Disparador:** solo inserción (UPDATE/DELETE/TRUNCATE bloqueados)
- **Disparador:** versionado coherente + t_sincronizacion del servidor
- **Disparador:** auditoría en bitacora_auditoria


### `plaga_enfermedad` (prefijo `plag_`)

Catálogo configurable de plagas, enfermedades y hongos (RF-029, RF-081). Sin valores oficiales en la documentación.

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `plag_id` | integer (identidad) | sí |  | Identificador del registro (clave primaria). |
| `plag_descripcion` | varchar | sí |  | Texto descriptivo del valor del catálogo (único, no vacío). |
| `plag_tipo` | varchar | sí |  | plaga, enfermedad u hongo (RF-029). |

- **Clave primaria:** `plag_id`
- **No se puede repetir:** (`plag_descripcion`)
- **Regla `plaga_enfermedad_descripcion_no_vacia`:** `((btrim((plag_descripcion)::text) <> ''::text))`
- **Regla `plaga_enfermedad_tipo_valido`:** `(((plag_tipo)::text = ANY ((ARRAY['plaga'::character varying, 'enfermedad'::character varying, 'hongo'::character varying])::text[])))`


### `programa_criterio_bpa` (prefijo `proc_`)

N:M: checklist de BPA vigente en cada versión del programa de inspección (RF-003, RF-080).

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `prog_id` | integer | sí |  | Referencia a programa_inspeccion(prog_id). |
| `crit_id` | integer | sí |  | Referencia a criterio_bpa(crit_id). |

- **Clave primaria:** `prog_id`, `crit_id`
- **Se relaciona con:** (`prog_id`) → `programa_inspeccion`; (`crit_id`) → `criterio_bpa`


### `severidad` (prefijo `seve_`)

Escala de severidad declarada de un hallazgo (RF-029). Escala no definida en la documentación: la carga el Administrador.

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `seve_id` | integer (identidad) | sí |  | Identificador del registro (clave primaria). |
| `seve_descripcion` | varchar | sí |  | Texto descriptivo del valor del catálogo (único, no vacío). |
| `seve_orden` | smallint | sí |  | Orden ascendente de gravedad (único). |

- **Clave primaria:** `seve_id`
- **No se puede repetir:** (`seve_descripcion`); (`seve_orden`)
- **Regla `severidad_descripcion_no_vacia`:** `((btrim((seve_descripcion)::text) <> ''::text))`


### `tipo_manejo` (prefijo `tipm_`)

Tipo de operación de manejo agronómico (RF-043: riego, fertilización, poda, thinning y renovación).

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `tipm_id` | integer (identidad) | sí |  | Identificador del registro (clave primaria). |
| `tipm_descripcion` | varchar | sí |  | Texto descriptivo del valor del catálogo (único, no vacío). |

- **Clave primaria:** `tipm_id`
- **No se puede repetir:** (`tipm_descripcion`)
- **Regla `tipo_manejo_descripcion_no_vacia`:** `((btrim((tipm_descripcion)::text) <> ''::text))`


## Área 9 · Archivos planificacion notificaciones


### `archivo_adjunto` (prefijo `arch_`)

Registro de binarios (RDD-011, Arquitectura §3.6): hash, tipo, tamaño y referencia al almacén de objetos. El contenido NO se guarda en la base. Un archivo nace al sincronizar su metadato (pendiente_contenido) y pasa a almacenado cuando sube el binario (la foto sube después del dato numérico, RF-067).

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `arch_id` | uuid | sí |  | Identificador del archivo (UUID generado en el dispositivo cuando nace allí). |
| `arch_clase` | varchar | sí |  | Para qué se usa: foto_evidencia, foto_perfil, documento_instruccion o imagen_diseno. Las tablas que lo referencian exigen la clase correcta. |
| `arch_nombre_original` | varchar | no |  | Nombre del archivo tal como lo eligió el usuario (opcional). |
| `arch_mime` | varchar | sí |  | Tipo de contenido validado en el servidor por el contenido, no por la extensión: JPG, PNG, WebP, PDF o Word. |
| `arch_tamano_bytes` | bigint | sí |  | [ud: bytes] Tamaño. Máximo 8 MB para imágenes y 10 MB para documentos (reglas del frontend; a confirmar). |
| `arch_hash_sha256` | character(64) | sí |  | SHA-256 del contenido en hexadecimal; permite verificar integridad y detectar duplicados. |
| `arch_paginas` | smallint | no |  | Número de páginas cuando es un PDF (opcional). |
| `arch_ref_almacenamiento` | varchar | no |  | Referencia (clave) del objeto en el almacén de objetos; nula mientras no se ha subido el binario. |
| `arch_estado` | varchar | sí | 'pendiente_contenido'::character varying | pendiente_contenido (llegó el metadato, falta el binario), almacenado o rechazado (el servidor revalidó y lo descartó). |
| `arch_motivo_rechazo` | varchar | no |  | Motivo cuando el servidor rechaza el archivo. |
| `usua_id` | integer | no |  | Usuario que lo subió (nulo para recursos del sistema, p. ej. imágenes de diseño). |
| `disp_id` | uuid | no |  | Dispositivo de origen (nulo para recursos del sistema). |
| `arch_t_captura` | timestamptz | sí | now() | Momento en que se tomó o eligió el archivo (reloj del dispositivo). |
| `arch_t_sincronizacion` | timestamptz | sí | now() | Momento en que el servidor recibió el metadato (reloj del servidor). |
| `arch_t_almacenado` | timestamptz | no |  | Momento en que quedó guardado el binario. |

- **Clave primaria:** `arch_id`
- **No se puede repetir:** (`arch_id`, `arch_clase`)
- **Se relaciona con:** (`usua_id`) → `usuario`; (`disp_id`) → `dispositivo`
- **Regla `archivo_adjunto_clase_mime_coherente`:** `((((arch_clase)::text = 'documento_instruccion'::text) OR ((arch_mime)::text ~~ 'image/%'::text)))`
- **Regla `archivo_adjunto_clase_valida`:** `(((arch_clase)::text = ANY ((ARRAY['foto_evidencia'::character varying, 'foto_perfil'::character varying, 'documento_instruccion'::character varying, 'imagen_diseno'::character varying])::text[])))`
- **Regla `archivo_adjunto_estado_coherente`:** `((arch_estado = 'pendiente_contenido' AND arch_ref_almacenamiento IS NULL AND arch_t_almacenado IS NULL AND arch_motivo_rechazo IS NULL) OR (arch_estado = 'almacenado' AND arch_ref_almacenamiento IS NOT NULL AND arch_t_almacenado IS NOT NULL AND arch_motivo_rechazo IS NULL) OR (arch_estado = 'rechazado' AND arch_motivo_rechazo IS NOT NULL))`
- **Regla `archivo_adjunto_estado_valido`:** `(((arch_estado)::text = ANY ((ARRAY['pendiente_contenido'::character varying, 'almacenado'::character varying, 'rechazado'::character varying])::text[])))`
- **Regla `archivo_adjunto_hash_hex`:** `((arch_hash_sha256 ~ '^[0-9a-f]{64}$'::text))`
- **Regla `archivo_adjunto_mime_valido`:** `(arch_mime IN ('image/jpeg','image/png','image/webp','application/pdf','application/msword','application/vnd.openxmlformats-officedocument.wordprocessingml.document'))`
- **Regla `archivo_adjunto_nombre_no_vacio`:** `(((arch_nombre_original IS NULL) OR (btrim((arch_nombre_original)::text) <> ''::text)))`
- **Regla `archivo_adjunto_paginas_positivas`:** `(((arch_paginas IS NULL) OR (arch_paginas > 0)))`
- **Regla `archivo_adjunto_tamano_valido`:** `(((arch_tamano_bytes > 0) AND (arch_tamano_bytes <= CASE     WHEN ((arch_clase)::text = 'documento_instruccion'::text) THEN 10485760     ELSE 8388608 END)))`


### `categoria_notificacion` (prefijo `cate_`)

Categorías de aviso que el usuario puede activar o desactivar (las 5 de la pantalla de preferencias del frontend).

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `cate_id` | integer (identidad) | sí |  | Identificador de la categoría. |
| `cate_codigo` | varchar | sí |  | Código estable que usa el frontend (asignacion, alertas_fitosanitarias, recordatorios_inspeccion, avisos_predio, sincronizacion). |
| `cate_descripcion` | varchar | sí |  | Texto descriptivo del valor del catálogo (único, no vacío). |

- **Clave primaria:** `cate_id`
- **No se puede repetir:** (`cate_codigo`); (`cate_descripcion`)
- **Regla `categoria_notificacion_codigo_formato`:** `(((cate_codigo)::text ~ '^[a-z_]+$'::text))`
- **Regla `categoria_notificacion_descripcion_no_vacia`:** `((btrim((cate_descripcion)::text) <> ''::text))`


### `evidencia` (prefijo `evid_`)

RDD-011 / RF-033: fotografía que respalda una lectura de trampa o un hallazgo (exactamente uno). Fecha de captura y hash viven en archivo_adjunto; aquí la georreferenciación y la observación. Solo inserción: la evidencia queda ligada a la versión de la lectura vigente al capturarla.

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `evid_id` | uuid | sí |  | Identificador de la evidencia (UUID generado en el dispositivo). |
| `arch_id` | uuid | sí |  | Archivo de la fotografía (clase foto_evidencia). |
| `evid_clase` | varchar | no |  | Clase constante foto_evidencia: hace que la FK compuesta solo admita fotos de evidencia. |
| `lect_id` | uuid | no |  | Versión de la lectura de trampa que respalda (excluyente con hall_id). |
| `hall_id` | uuid | no |  | Versión del hallazgo que respalda (excluyente con lect_id). |
| `evid_observacion` | text | sí | ''::text | Observación que escribió quien tomó la foto (puede estar vacía). |
| `evid_geom` | geometry(Point,4326) | no |  | Punto donde se tomó la foto (WGS84), si el dispositivo lo tenía. |
| `evid_precision_m` | real | no |  | [ud: m] Precisión del GPS al tomar la foto. |
| `usua_id` | integer | sí |  | Usuario que capturó la evidencia. |
| `disp_id` | uuid | sí |  | Dispositivo que la capturó. |
| `oper_id` | bigint | sí |  | Operación de sincronización que la trajo (idempotencia). |
| `evid_t_sincronizacion` | timestamptz | sí | now() | Momento en que el servidor la recibió. |

- **Clave primaria:** `evid_id`
- **No se puede repetir:** (`oper_id`); (`arch_id`, `evid_clase`)
- **Se relaciona con:** (`oper_id`) → `operacion_sync`; (`hall_id`) → `hallazgo`; (`usua_id`) → `usuario`; (`disp_id`) → `dispositivo`; (`arch_id`, `evid_clase`) → `archivo_adjunto`; (`lect_id`) → `lectura_trampa`
- **Regla `evidencia_precision_con_punto`:** `(((evid_precision_m IS NULL) OR (evid_geom IS NOT NULL)))`
- **Regla `evidencia_precision_positiva`:** `(((evid_precision_m IS NULL) OR (evid_precision_m >= (0)::double precision)))`
- **Regla `evidencia_un_solo_origen`:** `((num_nonnulls(lect_id, hall_id) = 1))`
- **Disparador:** solo inserción (UPDATE/DELETE/TRUNCATE bloqueados)
- **Disparador:** auditoría en bitacora_auditoria


### `imagen_diseno` (prefijo `imag_`)

Imágenes que forman parte del diseño de la aplicación (logo, ilustraciones, banners). Permite cambiar una imagen sin publicar una nueva versión de la app: se inserta una versión nueva y queda activa una sola por código. El binario está en el almacén de objetos (archivo.arch_ref_almacenamiento).

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `imag_id` | integer (identidad) | sí |  | Identificador interno de la imagen de diseño. |
| `imag_codigo` | varchar | sí |  | Nombre estable con el que la app pide la imagen (p. ej. login_hero, logo_oficial). |
| `imag_version` | smallint | sí | 1 | Versión de la imagen; al cambiarla se inserta una nueva y se desactiva la anterior. |
| `imag_uso` | varchar | sí |  | Dónde se muestra en la aplicación. |
| `arch_id` | uuid | sí |  | Archivo que contiene la imagen. |
| `arch_clase` | varchar | sí | 'imagen_diseno'::character varying | Clase constante imagen_diseno para la FK compuesta. |
| `imag_activa` | boolean | sí | true | Solo una versión por código está activa. |
| `imag_creada_en` | timestamptz | sí | now() | Cuándo se registró esta versión. |

- **Clave primaria:** `imag_id`
- **No se puede repetir:** (`imag_codigo`, `imag_version`); (`arch_id`, `arch_clase`)
- **Se relaciona con:** (`arch_id`, `arch_clase`) → `archivo_adjunto`
- **Regla `imagen_diseno_clase_fija`:** `(((arch_clase)::text = 'imagen_diseno'::text))`
- **Regla `imagen_diseno_codigo_formato`:** `(((imag_codigo)::text ~ '^[a-z0-9_]+$'::text))`
- **Regla `imagen_diseno_uso_no_vacio`:** `((btrim((imag_uso)::text) <> ''::text))`
- **Regla `imagen_diseno_version_positiva`:** `((imag_version >= 1))`


### `notificacion` (prefijo `noti_`)

Aviso dirigido a un usuario. Lo genera el servidor ante un evento (no la app). noti_evento_clave evita duplicados: una asignación = un aviso. Solo cambia noti_leida_en (nulo → fecha).

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `noti_id` | bigint (identidad) | sí |  | Identificador del aviso. |
| `usua_id` | integer | sí |  | Destinatario (el servidor lo deduce del evento, no de la app). |
| `cate_id` | integer | sí |  | Categoría del aviso. |
| `noti_titulo` | varchar | sí |  | Título corto del aviso. |
| `noti_cuerpo` | text | sí |  | Texto del aviso. |
| `noti_evento_clave` | varchar | sí |  | Clave del evento que lo originó (p. ej. planificacion:<id>:asignada); con el usuario es única para no duplicar avisos. |
| `noti_destino_ruta` | varchar | no |  | Pantalla de la app a la que lleva el aviso al tocarlo. |
| `noti_destino_argumento` | varchar | no |  | Parámetro de la pantalla destino (p. ej. el id de la planificación). |
| `noti_creada_en` | timestamptz | sí | now() | Cuándo se generó el aviso (reloj del servidor). |
| `noti_leida_en` | timestamptz | no |  | Cuándo lo leyó el usuario; nulo = no leído. |

- **Clave primaria:** `noti_id`
- **No se puede repetir:** (`usua_id`, `noti_evento_clave`)
- **Se relaciona con:** (`usua_id`) → `usuario`; (`cate_id`) → `categoria_notificacion`
- **Regla `notificacion_cuerpo_no_vacio`:** `((btrim(noti_cuerpo) <> ''::text))`
- **Regla `notificacion_destino_coherente`:** `(((noti_destino_argumento IS NULL) OR (noti_destino_ruta IS NOT NULL)))`
- **Regla `notificacion_evento_no_vacio`:** `((btrim((noti_evento_clave)::text) <> ''::text))`
- **Regla `notificacion_lectura_posterior`:** `(((noti_leida_en IS NULL) OR (noti_leida_en >= noti_creada_en)))`
- **Regla `notificacion_titulo_no_vacio`:** `((btrim((noti_titulo)::text) <> ''::text))`


### `perfil_usuario` (prefijo `perf_`)

Perfil del usuario autenticado: foto (referencia a archivo de clase foto_perfil) y el interruptor general de notificaciones. Una fila por usuario, creada cuando el usuario guarda su primer ajuste.

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `usua_id` | integer | sí |  | Usuario dueño del perfil. |
| `arch_id_foto` | uuid | no |  | Foto de perfil (archivo de clase foto_perfil); nula si no tiene. |
| `perf_foto_clase` | varchar | no |  | Clase constante foto_perfil para la FK compuesta. |
| `perf_notificaciones_activas` | boolean | sí | true | Interruptor general de notificaciones. |
| `perf_actualizado_en` | timestamptz | sí | now() | Última vez que el usuario cambió su perfil. |

- **Clave primaria:** `usua_id`
- **Se relaciona con:** (`usua_id`) → `usuario`; (`arch_id_foto`, `perf_foto_clase`) → `archivo_adjunto`


### `planificacion` (prefijo `plan_`)

Asignación de lotes a un técnico o planeación de actividades para un productor, creada por un Agrónomo/Supervisor. El tipo de destino (técnico/productor) no se guarda: se deduce del rol del destinatario. Productor: pendiente → aceptada | rechazada (con motivo); aceptada → completada. Técnico: no acepta ni rechaza; la asignación queda vigente (pendiente) y pasa a completada.

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `plan_id` | uuid | sí | gen_random_uuid() | Identificador de la planificación. |
| `usua_id_destinatario` | integer | sí |  | Usuario que debe aceptar o rechazar; su rol debe corresponder al destino. |
| `usua_id_creador` | integer | sí |  | Agrónomo/Supervisor que la creó. |
| `plan_actividad` | varchar | sí |  | Actividad a realizar (texto libre, p. ej. "Muestreo de cultivos"). |
| `plan_fecha_inicio` | date | sí |  | Fecha de inicio. |
| `plan_fecha_fin` | date | no |  | Fecha de fin (opcional; no anterior al inicio). |
| `plan_hora_desde` | time without time zone | no |  | Hora de inicio del horario diario (opcional, junto con hora_hasta). |
| `plan_hora_hasta` | time without time zone | no |  | Hora de fin del horario diario. |
| `plan_observaciones` | text | no |  | Indicaciones adicionales del Agrónomo. |
| `arch_id_documento` | uuid | no |  | Documento de instrucciones adjunto (PDF, Word o imagen). |
| `plan_documento_clase` | varchar | no |  | Clase constante documento_instruccion para la FK compuesta. |
| `plan_estado` | varchar | sí | 'pendiente'::character varying | pendiente, aceptada, rechazada o completada. |
| `plan_motivo_rechazo` | varchar | no |  | Motivo del rechazo; obligatorio si y solo si está rechazada. |
| `plan_respondida_en` | timestamptz | no |  | Cuándo respondió el destinatario; nula mientras está pendiente. |
| `plan_creada_en` | timestamptz | sí | now() | Cuándo se creó (reloj del servidor). |

- **Clave primaria:** `plan_id`
- **Se relaciona con:** (`usua_id_destinatario`) → `usuario`; (`usua_id_creador`) → `usuario`; (`arch_id_documento`, `plan_documento_clase`) → `archivo_adjunto`
- **Regla `planificacion_actividad_no_vacia`:** `((btrim((plan_actividad)::text) <> ''::text))`
- **Regla `planificacion_distintas_personas`:** `((usua_id_destinatario <> usua_id_creador))`
- **Regla `planificacion_estado_valido`:** `(((plan_estado)::text = ANY ((ARRAY['pendiente'::character varying, 'aceptada'::character varying, 'rechazada'::character varying, 'completada'::character varying])::text[])))`
- **Regla `planificacion_fechas_validas`:** `(((plan_fecha_fin IS NULL) OR (plan_fecha_fin >= plan_fecha_inicio)))`
- **Regla `planificacion_horario_completo`:** `(((plan_hora_desde IS NULL) = (plan_hora_hasta IS NULL)))`
- **Regla `planificacion_horario_valido`:** `(((plan_hora_desde IS NULL) OR (plan_hora_hasta > plan_hora_desde)))`
- **Regla `planificacion_rechazo_con_motivo`:** `((((plan_estado)::text = 'rechazada'::text) = ((plan_motivo_rechazo IS NOT NULL) AND (btrim((plan_motivo_rechazo)::text) <> ''::text))))`
- **Regla `planificacion_respuesta_coherente`:** `((((plan_estado)::text = 'pendiente'::text) = (plan_respondida_en IS NULL)))`
- **Disparador:** auditoría en bitacora_auditoria


### `planificacion_lote` (prefijo `plal_`)

Lotes incluidos en una planificación (el frontend los muestra por nombre; aquí se enlazan por id). Solo se modifican mientras la planificación está pendiente.

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `plan_id` | uuid | sí |  | Planificación. |
| `lote_id` | integer | sí |  | Lote incluido. |

- **Clave primaria:** `plan_id`, `lote_id`
- **Se relaciona con:** (`plan_id`) → `planificacion`; (`lote_id`) → `lote`


### `preferencia_notificacion` (prefijo `pref_`)

Preferencia por categoría. Si no hay fila para una categoría, el frontend la considera activada.

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `usua_id` | integer | sí |  | Usuario que fija la preferencia. |
| `cate_id` | integer | sí |  | Categoría de aviso. |
| `pref_habilitada` | boolean | sí |  | Si el usuario quiere recibir avisos de esta categoría. |

- **Clave primaria:** `usua_id`, `cate_id`
- **Se relaciona con:** (`usua_id`) → `usuario`; (`cate_id`) → `categoria_notificacion`


### `restablecimiento_clave` (prefijo `rest_`)

Solicitudes de restablecimiento de contraseña. Solo se guarda el HASH del token (el token viaja por correo y no se almacena), con vencimiento y uso único. El proveedor de identidad (RI-008) sigue pendiente: si es externo, esta tabla no se usa.

| Columna | Tipo | Obligatorio | Por defecto | Significado |
| --- | --- | --- | --- | --- |
| `rest_id` | bigint (identidad) | sí |  | Identificador de la solicitud. |
| `usua_id` | integer | sí |  | Usuario que pidió restablecer la contraseña. |
| `rest_token_hash` | character(64) | sí |  | SHA-256 del token enviado por correo; el token no se guarda. |
| `rest_solicitado_en` | timestamptz | sí | now() | Cuándo se pidió. |
| `rest_expira_en` | timestamptz | sí |  | Hasta cuándo sirve el token. |
| `rest_usado_en` | timestamptz | no |  | Cuándo se usó (uso único); nulo = sin usar. |

- **Clave primaria:** `rest_id`
- **No se puede repetir:** (`rest_token_hash`)
- **Se relaciona con:** (`usua_id`) → `usuario`
- **Regla `restablecimiento_clave_hash_hex`:** `((rest_token_hash ~ '^[0-9a-f]{64}$'::text))`
- **Regla `restablecimiento_clave_uso_en_vigencia`:** `(((rest_usado_en IS NULL) OR ((rest_usado_en >= rest_solicitado_en) AND (rest_usado_en <= rest_expira_en))))`
- **Regla `restablecimiento_clave_vigencia`:** `((rest_expira_en > rest_solicitado_en))`
- **Disparador:** auditoría en bitacora_auditoria
