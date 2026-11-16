---
title: "Pruebas de escritorio y revisión del modelo de datos"
subtitle: "Datos reales MF_UBI/MF_CAP del ICA aplicados al esquema SIGAT v6"
author: "Equipo de Arquitectura de Software"
date: "23 de octubre de 2026"
lang: es-CO
---

# Resumen ejecutivo {#sec-resumen}

> **Conclusión en una frase.** El esquema SIGAT v6 es coherente para los datos que produce la aplicación, pero **no está listo para cargar los archivos históricos del ICA tal como están**: 17 de las 40 comprobaciones realizadas evidencian brechas de modelo o de dato, y cinco de ellas son bloqueantes para una migración.

El paquete `BD/sigat_db_v6` contiene un modelo relacional maduro: 74 tablas, 164 llaves foráneas, 182 reglas `CHECK`, 5 restricciones de no-solapamiento, 299 índices, 21 vistas, 30 funciones y 84 disparadores. Sus propias pruebas pasan: **31/31** restricciones y **52/52** pasos de los 49 escenarios de demostración, y las 8 consultas de validación devuelven cero filas. Ese resultado demuestra que el modelo funciona con los datos sintéticos para los que fue diseñado; no demuestra que sirva para los datos que el técnico llenó a mano entre 2012 y 2015.

Los dos archivos reales no son una muestra cualquiera:

| Archivo | Qué contiene | Volumen | Cobertura |
|---|---|---|---|
| `MF_UBI_54_2_ ... Cacota_Chitaga_2014.xls` | Ubicación de trampas | **298 registros de trampa** (297 con número) en **139 predios** de 4 rutas (602, 603, 604, 605) | Municipios de Cácota, Chitagá y Silos (Norte de Santander) |
| `MF_CAP pasantia semana 7 ... 2015.xls` | Captura de moscas | **20 lecturas** de 20 trampas de la ruta 606 | Pamplonita, una sola fecha (10-feb-2015) |

La primera comprobación incómoda es que **los dos archivos no se cruzan**: el MF_UBI cubre las rutas 602 a 605 y el MF_CAP cubre la ruta 606. No hay una sola trampa compartida. Eso impide probar de punta a punta la cadena «ubicación → trampa → lectura → MTD» con estos dos archivos; se probó por separado y se documenta como brecha de datos, no como fallo del esquema.

Los cinco hallazgos bloqueantes son:

1. **La lectura no guarda especie, sexo ni estado de diagnóstico.** El modelo solo conserva un total (`lect_especimenes`) y declara explícitamente que «la especie no se determina aquí». Los requisitos RF-023, RF-025, RF-026, RF-027, RDD-005 y RDD-006 exigen MTD por especie, estado pendiente de diagnóstico y relación de muestras. El archivo real sí trae especie, machos, hembras y hembras grávidas: el dato existe, pero el modelo lo pierde.
2. **El predio y el lote exigen área positiva y no admiten «sin dato».** Las 298 filas traen `Lote = NO APLICA` y ningún área; el modelo rechaza `NULL`, `0` y el texto `NO APLICA`. Para cargar se inventó 1 ha por predio, que es exactamente lo que no debe hacerse.
3. **La identidad del productor es obligatoria y única.** El archivo solo trae nombres; 89 filas no traen propietario, 44 predios quedan sin dueño y 11 predios tienen más de un propietario. El modelo usa la cédula como llave primaria y un solo productor por predio; no representa coautoría ni propietario desconocido.
4. **La visita y la lectura exigen usuario, dispositivo y operación de sincronización.** El archivo histórico no trae colector (0/20 filas) ni código de predio (0/20 filas), y no nació de un celular. El modelo no tiene un camino de importación histórica: si se rellenan esos campos con datos sintéticos, se mezcla evidencia real con evidencia inventada.
5. **El MTD y el concepto están amarrados al lote.** El archivo histórico está organizado por ruta y predio, no por lote; sin lote no hay periodo, no hay MTD y no hay concepto. La asignación trampa–lote es opcional en la ubicación, pero obligatoria para que la lectura entre al MTD, de modo que las 20 lecturas del CAP se insertan y **ninguna** alimenta el indicador.

Además hay brechas de dato que no son culpa del esquema pero sí del proceso manual: una trampa sin número, un predio sin nombre, tres fechas de 2012 en un archivo de 2014, cinco formas de escribir «durazno» (incluida `CAFÉ`), una hoja llamada «SILOS» con municipio Chitagá, y un encabezado de año 2019/semana 7 sobre una fecha de 2015.

La recomendación es no cargar los `.xls` directamente. Primero se corrige el modelo en los cinco puntos bloqueantes, se crea un esquema de staging para la carga histórica y se completa la ubicación de la ruta 606; después se migra con validaciones por lote. El plan está en la sección\nobreakspace\ref{sec-plan}.

# Alcance, fuentes y método {#sec-metodo}

## Qué se revisó {#sec-fuentes}

Se tomó todo el contenido de `BD/` y se contrastó con el levantamiento de requerimientos y con la arquitectura tecnológica del proyecto.

| Fuente | Uso en este informe |
|---|---|
| `BD/sigat_db_v6/sql/01_esquema_completo.sql` | Esquema de 74 tablas, dominios, restricciones, índices, funciones y disparadores |
| `BD/sigat_db_v6/sql/02_catalogos_basicos.sql` | Valores iniciales de catálogos y su correspondencia con los códigos del archivo |
| `BD/sigat_db_v6/sql/03_vistas.sql` y `04_funciones.sql` | Vistas de vigencia, visibilidad, MTD y reglas de validación |
| `BD/sigat_db_v6/sql/05_datos_demo.sql` | Datos sintéticos para ejecutar los escenarios existentes |
| `BD/sigat_db_v6/sql/06_validacion.sql` y `07_pruebas_restricciones.sql` | Validación de integridad y 31 pruebas de restricciones |
| `BD/sigat_db_v6/pruebas_escritorio/PE_escenarios.md` y `PE_ejecutable.sql` | 49 escenarios de escritorio y su versión ejecutable (52 pasos) |
| `BD/sigat_db_v6/docs/03_diccionario_datos.md`, `05_matriz_relaciones.md`, `06_matriz_indices.md`, `09_pendientes_institucionales.md` | Diccionario, relaciones, índices y pendientes institucionales |
| `BD/sigat_db_v6/migracion/` | Procedimiento v5 → v6 y pruebas de migración |
| `BD/sigat_db_v6/diagramas/sigat.dbml` y diagramas por área | Modelo entidad-relación de referencia |
| `BD/MF_UBI_54_2_ ... .xls` | Datos reales de ubicación de trampas |
| `BD/MF_CAP pasantia semana 7 ... .xls` | Datos reales de captura de moscas |
| `Levantamiento_Requerimientos_ICA_Durazno.md` | Requisitos RF, RDD, RN y RNF citados |
| `Arquitectura_Tecnologica_ICA_Durazno.md` | Decisiones ADR-03, ADR-06, ADR-14 y modelo temporal |

No se usó la base de producción ni se modificó el paquete original. Todas las pruebas se ejecutaron en bases desechables.

## Método {#sec-metodo-detalle}

Una **prueba de escritorio** es seguir un caso con papel y lápiz: se parte de un dato conocido, se aplica la regla a mano, se anota qué debería pasar y se compara con lo que hace la base. Aquí se hizo en dos capas:

1. **Prueba manual sobre el archivo.** Se identificaron las filas útiles, se convirtieron las fechas seriales de Excel, se separaron las plantillas vacías y se calcularon a mano los totales, la paridad y el MTD.
2. **Prueba ejecutada.** Se cargaron los datos en una base temporal PostgreSQL 18.6 + PostGIS 3.6.4, se aplicaron las reglas del esquema y se registraron los errores y los valores obtenidos. Cuando una regla rechazó el dato, se capturó el `SQLSTATE` y el mensaje.

El entorno de ejecución fue:

| Elemento | Versión / configuración |
|---|---|
| PostgreSQL | 18.6 |
| PostGIS | 3.6.4 (GEOS, PROJ y estadísticas habilitados) |
| Esquema | `sigat_db_v6` instalado desde `00_instalar_todo.sql` |
| Codificación | UTF-8, locale `C` |
| Base de pruebas | `sigat_schema` (sin datos), `sigat_demo` (con demostración), `sigat_real` (datos reales) |
| Precisión de fechas | Fechas seriales de Excel convertidas con `xlrd` (sistema 1900) |

## Límites del ejercicio {#sec-limites}

- **Muestra pequeña y antigua.** 298 registros de trampa y 20 lecturas no representan el universo del ICA; además, los datos son de 2012–2015 y pueden no reflejar el proceso actual.
- **Archivos disjuntos.** El MF_UBI no trae la ruta 606 y el MF_CAP no trae coordenadas, predio ni colector; la cadena completa se probó con fixtures explícitos.
- **Catálogos oficiales incompletos.** El paquete no carga valores oficiales de fenología, condición de trampa, localización, variedad, norma ni umbral. Las pruebas usan valores marcados como *fixture* y no deben interpretarse como catálogo institucional.
- **Geometrías ausentes.** No hay polígonos de predios ni de lotes; las validaciones espaciales se probaron con las coordenadas puntuales y con el rango departamental, no con geometrías reales.
- **Datos personales.** El informe omite nombres de personas y usa iniciales o códigos. Los archivos originales permanecen en `BD/` y deben tratarse como información interna.

# Los archivos .xls: qué contienen {#sec-xls}

## MF_UBI: ubicación de trampas {#sec-ubi}

El archivo `MF_UBI_54_2_ SEPTIEMBRE CONGLOMERADOS FRUTICOLAS_CACOTA_CHITAGA _2014 a diciembre 23 2014.xls` tiene 7 hojas. Cuatro son datos y tres son plantillas o auxiliares:

| Hoja | Tipo | Filas útiles | Contenido |
|---|---|---:|---|
| `CONGLOMERADO CACOTA 602 ` | Datos | 95 | Ruta 602, municipio de Cácota |
| `CONGLOMERADO CHITAGA 603 ` | Datos | 118 | Ruta 603, municipio de Chitagá |
| `CONGLOMERADO CHITAGA  605 SILOS` | Datos | 20 | Ruta 605; el nombre de la hoja dice SILOS, pero el municipio y el código son de Chitagá |
| `CONGLOMERADO SILOS BABEGA  604` | Datos | 65 | Ruta 604, municipio de Silos |
| `BD AUX` | Auxiliar | — | Códigos DANE de departamentos y municipios, y rangos de coordenadas |
| `INDIRECTO`, `INDIRECTO2` | Auxiliar | — | Matrices de búsqueda de municipios; no son datos de trampas |

Cada hoja tiene el encabezado en la fila 12 y 20 columnas útiles. Las filas 13 en adelante son datos; las plantillas vacías repiten el valor `42` en varias columnas y no deben importarse. La lectura del archivo confirma **298 filas con coordenadas válidas** (297 con número de trampa) y **139 predios**.

| Ruta | Municipio | Trampas | Predios | Fechas de instalación | Longitud (mín–máx) | Latitud (mín–máx) |
|---|---|---:|---:|---|---|---|
| 541250602 | Cácota | 95 | 43 | 2013-04-10 a 2014-12-17 | −72,65094 a −72,61269 | 7,19040 a 7,25151 |
| 541740603 | Chitagá | 118 | 58 | 2012-04-23 a 2014-12-18 | −72,65929 a −72,22387 | 7,16314 a 7,26220 |
| 541740605 | Chitagá | 20 | 8 | 2014-12-22 a 2014-12-23 | −72,71227 a −72,69482 | 7,17248 a 7,18036 |
| 547430604 | Silos | 65 | 30 | 2014-04-24 a 2014-12-17 | −72,76700 a −72,69109 | 7,15526 a 7,20233 |

Las columnas del MF_UBI son: `Codigo Vigilancia`, `Region`, `Departamento`, `Municipio`, `Registro de la ruta`, `Código Ruta`, `Lote`, `Tipo Trampa`, `Numero Trampa`, `Atrayente`, `Fecha Instalacion`, `Longitud`, `Latitud`, `Altitud`, `Ubicación`, `Nombre Predio`, `Propietario`, `Codigo Localizacion`, `Arbol` y `Nombre_Ruta`.

> **Observación sobre los códigos.** El archivo trae dos códigos de ruta: el **registro** (`602`, `603`, `604`, `605`) y el **código de 9 dígitos** (`541250602`, etc.). El modelo espera que `ruta.ruta_codigo` guarde el registro corto (`602`) y deriva el código de 9 dígitos en la vista `v_ruta_codigo_ica`. Si el importador guarda el código de 9 dígitos en `ruta_codigo`, la vista devuelve cero filas. Es un error de importación fácil de cometer y difícil de ver.

## MF_CAP: captura de moscas {#sec-cap}

El archivo `MF_CAP pasantia semana 7 (Copia en conflicto de Mauricio Zafra Aycardi 2015-06-16).xls` tiene 7 hojas, pero solo **`10-02-15`** contiene datos. Las hojas `Predio`, `Ruta`, `Ruta (2)` a `Ruta (5)` son plantillas vacías; `BD AUX`, `INDIRECTO` e `INDIRECTO2` son auxiliares.

La hoja `10-02-15` tiene 20 filas útiles, todas de la **ruta 606**, municipio de **Pamplonita**, con fecha **10 de febrero de 2015**. Las 20 trampas son 26, 28, 30, 32 a 45, 47, 49 y 51. La siguiente tabla resume las capturas:

| Código de especie | Nombre | Filas | Machos | Hembras | Hembras grávidas | Total |
|---|---|---:|---:|---:|---:|---:|
| 51 | No captura | 17 | 0 | 0 | 0 | 0 |
| 54 | No Tephritidae | 1 | 0 | 5 | — | 5 |
| 56 | *Anastrepha* sp. | 1 | 6 | 10 | — | 16 |
| 1 | *Ceratitis capitata* | 1 | 56 | 0 | 0 | 56 |
| **Total** | | **20** | **62** | **15** | **0** | **77** |

Las columnas del MF_CAP son: `Codigo Vigilancia`, `Region`, `Departamento`, `Municipio`, `Registro de la ruta`, `Código Ruta`, `Lote`, `Tipo Trampa`, `Numero Trampa`, `código de la especie`, `Fecha`, `código del recolector`, `Machos`, `Hembras`, `Hembras gravidas`, `Estado trampa` y `Fenologia`.

> **Trampa de lectura del encabezado.** La hoja `10-02-15` usa las etiquetas `Registro de la ruta` y `Código Ruta`; la hoja `Predio` usa, en las mismas posiciones, `Registro del Predio` y `Código Predio`. Un importador que lea por posición y asuma «predio» interpretará `606` y `545200606` como predio; un importador que lea por etiqueta encontrará columnas distintas según la hoja. El encabezado debe resolverse por hoja y por semántica, no por posición.

## Calidad de los datos de origen {#sec-calidad}

| Hallazgo | Evidencia | Consecuencia |
|---|---|---|
| Predios sin propietario | 89 filas sin propietario; 44 predios sin ningún dueño | No se puede crear `persona`/`productor` sin inventar cédula |
| Predios con varios propietarios | 11 predios con más de un propietario; un mismo propietario aparece en hasta 3 predios | El modelo solo admite un `pers_cc` por predio |
| Predio sin nombre | 1 fila (ruta 604) | `pred_nombre` es `NOT NULL` y no vacío |
| Trampa sin número | 1 fila (ruta 604, fila 13) | No se puede componer el código ICA |
| Lote no aplica | 297 filas `NO APLICA` y 1 vacía; 0 lotes reales | El modelo exige `lote_area > 0` |
| Árbol/cultivo | `durazno` 166, `DURAZNO` 121, `DURANZO` 8, `DUARZNO` 2, `CAFÉ` 1 | El catálogo es sensible a mayúsculas y no está normalizado |
| Fechas anteriores al proyecto | 3 trampas de la ruta 603 con 2012-04-23 | Probable error de digitación; requiere revisión |
| Nombre de hoja vs municipio | Hoja `605 SILOS`, municipio `CHITAGA`, código `541740605` | Riesgo de asignar la ruta al municipio equivocado |
| Coordenadas repetidas | 147 pares únicos; 8 pares aparecen en 4 trampas; 1 par se comparte entre rutas | Puede ser normal (par Jackson/McPhail) o duplicación; requiere revisión |
| Fechas del CAP | Celda 2015-02-10; hoja `10-02-15`; encabezado año 2019, semana 7 | Inconsistencia de plantilla; no afecta la fecha de la celda, pero confunde |
| Colector y predio del CAP | 0/20 filas con colector; 0/20 con predio | Sin usuario ni predio no se puede crear visita/lectura en el modelo |
| Hembras grávidas | 2/20 filas con valor vacío (Anastrepha y No Tephritidae) | Hay que distinguir «cero» de «no informado» |

# Correspondencia entre los archivos y el modelo {#sec-mapa}

La siguiente tabla confronta cada campo de los archivos con la tabla y columna que debería recibirlo. La columna «Estado» indica si la correspondencia es directa, requiere transformación, o no existe en el modelo.

| Campo del archivo | Destino en SIGAT v6 | Estado | Observación |
|---|---|---|---|
| `Codigo Vigilancia` | `vigilancia.vigi_codigo` | Transformar | El catálogo no trae valores; el código 2 debe cargarse |
| `Region` | `region.regi_id` | Transformar | `region` no tiene columna de código; se depende del `IDENTITY` |
| `Departamento` | `departamento.depa_codigo` | Transformar | El catálogo DANE está vacío; el archivo trae 54 |
| `Municipio` | `municipio.muni_codigo` | Transformar | El catálogo DANE está vacío; el archivo trae nombre y código en `BD AUX` |
| `Registro de la ruta` | `ruta.ruta_codigo` | Directa | Debe guardarse el registro corto (602), no el código de 9 dígitos |
| `Código Ruta` | `v_ruta_codigo_ica.ruta_codigo_9` | Derivada | Se compone de Divipola (5) + registro (4) |
| `Lote` | `lote.lote_codigo` / `ubicacion_trampa.lote_id` | **Ausente** | 297 filas `NO APLICA`; no hay lote que crear |
| `Tipo Trampa` | `trampa.tipt_id` | Transformar | El catálogo no tiene código; 1=Jackson, 2=McPhail |
| `Numero Trampa` | `trampa.tram_codigo` / `tram_numero` | Transformar | Hay que componer el código ICA; una fila no trae número |
| `Atrayente` | `trampa.atra_id` | Transformar | El catálogo no tiene código; el orden de inserción invierte 1 y 2 |
| `Fecha Instalacion` | `trampa.tram_fecha_registro`, `ubicacion_trampa.ubic_fecha` | Directa | Fecha serial de Excel; solo fecha, sin hora |
| `Longitud`, `Latitud`, `Altitud` | `ubicacion_trampa.ubic_long`, `ubic_lat`, `ubic_alt` | Directa | WGS84, 5 decimales; el modelo usa `numeric(8,5)` y `numeric(7,5)` |
| `Ubicación` | `ubicacion_trampa.ubic_referencia` | Directa | Texto de vereda; no es una geometría |
| `Nombre Predio` | `predio.pred_nombre` | Transformar | 1 fila vacía; el modelo exige nombre no vacío |
| `Propietario` | `persona.pers_nombre`/`pers_apellido`, `predio.pers_cc` | **Ausente** | Solo nombre; sin cédula, sin tipo de documento, con copropiedad |
| `Codigo Localizacion` | `localizacion.loca_codigo` | Transformar | Catálogo vacío; el archivo usa 1 |
| `Arbol` | `arbol.arbo_id` | Transformar | Sin código; 5 variantes, incluida `CAFÉ` |
| `Nombre_Ruta` | `ruta.ruta_nombre` | **Conflicto** | Las 4 rutas se llaman `CONGLOMERADO FRUTICOLA`; el modelo impone nombre único |
| `código de la especie` | `especie_mosca.espm_codigo` | **Parcial** | El catálogo tiene 1, 51, 54 y 56; la lectura no tiene FK de especie |
| `Fecha` (CAP) | `lectura_trampa.lect_t_observacion` | Transformar | Solo fecha; el modelo usa `timestamptz` |
| `código del recolector` | `lectura_trampa.usua_id` | **Ausente** | 0/20 filas; el modelo exige usuario |
| `Machos`, `Hembras`, `Hembras gravidas` | **Sin destino** | **Ausente** | El modelo solo tiene `lect_especimenes` (total) |
| `Estado trampa` | `lectura_trampa.cond_id` | Transformar | Catálogo vacío; el archivo usa 1 |
| `Fenologia` | **Sin destino en la lectura** | **Ausente** | Existe `etapa_declarada` por lote, pero no por lectura |

**Resumen:** 6 correspondencias directas, 10 que requieren transformación y 7 que no tienen destino o chocan con una restricción. Las tres ausencias más costosas son especie/sexo, identidad del propietario y lote.

# Pruebas de escritorio ejecutadas {#sec-pruebas}

## Diseño de la suite {#sec-suite}

Se ejecutaron **40 comprobaciones** sobre PostgreSQL 18.6 + PostGIS 3.6.4. Cada comprobación tiene un identificador `T-nn`, un resultado esperado, el resultado obtenido y una lectura. El Anexo\nobreakspace\ref{sec-anexo-pruebas} contiene la matriz completa. En el cuerpo se presentan las pruebas que cambian una decisión de diseño.

Para poder cargar los datos reales se necesitaron **ocho concesiones de importación**, que se documentan en la sección\nobreakspace\ref{sec-concesiones}. Ninguna de ellas es una corrección del modelo: son parches de la prueba. El hecho de necesitarlas es, en sí mismo, el resultado principal.

## Pruebas que confirman reglas del modelo {#sec-pruebas-ok}

| ID | Regla probada | Esperado | Obtenido | Lectura |
|---|---|---|---|---|
| T-08 | Jackson solo impar (RN-005) | Rechazo 23000 | `El número de trampa 2 no respeta la paridad (impar)` | La regla funciona |
| T-18 | Paridad de las 297 trampas con número | 0 violaciones | 0 violaciones | Los datos reales respetan la paridad |
| T-19 | Códigos de ruta de 9 dígitos | 0 inválidos | 0 inválidos | La composición del archivo es correcta |
| T-20 | Coordenadas dentro de Norte de Santander | Dentro del rango | lon −72,767 a −72,224; lat 7,155 a 7,262 | Las coordenadas son plausibles |
| T-22 | Fórmula MTD = M/(T×D) | 0,55 total; 0,5143 objetivo; 0,4429 machos | Coincide | La fórmula del modelo es correcta; el problema es qué M usar |
| T-32 | Índice MTD total 77/(20×7) | 0,550000 | 0,550000 | La columna generada funciona |
| T-34 | Código de ruta CAP 606 | 545200606 | 545200606 | Divipola 54 + municipio 520 + ruta 0606 |
| T-38 | Cero capturas vs. trampa no leída | 17 lecturas con cero, no nulas | 17 | El modelo distingue los dos casos |

También se confirmó la línea base del paquete: **31/31** pruebas de restricciones, **52/52** pasos de los escenarios de demostración y **8/8** consultas de validación con cero filas. Esa línea base es importante: el problema no es que el esquema esté roto, sino que fue diseñado para otro origen de datos.

## Pruebas que evidencian brechas {#sec-pruebas-gaps}

| ID | Qué se probó | Esperado | Obtenido | Decisión |
|---|---|---|---|---|
| T-01 | Cuatro rutas reales se llaman `CONGLOMERADO FRUTICOLA` | Cargar las cuatro | `23505` por `ruta_ruta_nombre_key` | Quitar la unicidad del nombre; usar `(cent_id, ruta_codigo)` |
| T-02 | Predio sin área | Aceptar «sin dato» | `23502`; y `0` viola `predio_area_positiva` | Permitir `NULL` con estado de calidad |
| T-03 | Lote `NO APLICA` | Aceptar «no aplica» | `22P02` al convertir a `numeric` | Permitir lote nulo o estado «sin lote» |
| T-04 | Persona sin cédula | Aceptar propietario desconocido | `23502` en `pers_cc` | Cambiar a identificador surrogate + documento opcional |
| T-05 | Visita sin predio | Aceptar visita de ruta | `23502` en `visita.pred_id` | Permitir visita por ruta o completar predio |
| T-06 | Lectura sin usuario | Aceptar lectura histórica | `23502` en `lectura_trampa.usua_id` | Añadir origen histórico y actor opcional |
| T-07 | Código de trampa `1` | Aceptar y componer | `23514` por `trampa_codigo_formato` | Componer `54125-0602-1`; hacer `NOT NULL` |
| T-07b | Código ICA repetido | Rechazar duplicado | `23505` | Correcto; la unicidad funciona |
| T-09 | Coordenada fuera del departamento | Rechazar | `23000` | Correcto |
| T-10 | La misma coordenada con `ubic_origen='legado'` | Rechazar | **Aceptada** | El bypass de legado es una puerta trasera; restringirlo |
| T-11 | Código de ruta con prefijo de otro municipio | Rechazar | **Aceptado** | Falta validación código ↔ municipio |
| T-12 | `durazno` y `DURAZNO` en el catálogo | Un solo valor | **Ambos aceptados** | Normalizar o usar `citext`/código |
| T-15 | Columnas de especie, sexo, fenología y diagnóstico | 6 columnas | **0 columnas** | Bloqueante: añadir especie/sexo/diagnóstico |
| T-16 | Tablas de muestra, laboratorio y diagnóstico | ≥1 | **0 tablas** | Bloqueante para RF-025 a RF-027 |
| T-17 | Atrayente 2 = Plug (Jackson) | Plug en código 2 | `1=Plug`, `2=Proteico` | Añadir `atra_codigo`; sembrar 1=Proteico, 2=Plug |
| T-21 | Periodo de trampeo sin lote | Rechazar | `23000` | Correcto, pero impide el nivel ruta/predio |
| T-23 | Cruce MF_UBI ↔ MF_CAP | Alguna ruta/trampa compartida | **0 rutas, 0 trampas** | Brecha de datos: falta MF_UBI de la ruta 606 |
| T-24 | Fecha CAP vs. año/semana | Coherente | 2015-02-10 vs. año 2019/semana 7 | Regla de validación de plantilla |
| T-25 | Predios con más de un propietario | 0 | **11 predios** | Modelo N:M de propietarios |
| T-26 | Lotes reales | ≥1 | **0**; 297 `NO APLICA` | Bloqueante: decidir lote operativo |
| T-27 | Catálogo de cultivo | 1 valor | **5 variantes** (`CAFÉ` incluida) | Normalización y validación |
| T-28 | Fechas anteriores a 2013 | 0 | **3** (2012-04-23) | Revisión manual |
| T-29 | Trampa sin número | 0 | **1** (ruta 604) | Validación de origen |
| T-30 | Hoja 605 «SILOS» vs. municipio | SILOS | **CHITAGA** | Corregir nombre de hoja o municipio |
| T-31 | Las 20 lecturas CAP entran al MTD | 20 | **0** | Sin ubicación/lote no hay MTD |
| T-33 | MTD por especie (RF-023) | Una por especie | **Solo total** | Bloqueante: falta detalle por especie |
| T-35 | Predio en MF_CAP | 20/20 | **0/20** | Completar plantilla o usar ruta |
| T-36 | Colector en MF_CAP | 20/20 | **0/20** | Completar plantilla o actor histórico |
| T-37 | Hembras grávidas 0 vs. vacío | Distinguir | **2/20 vacías** | Permitir `NULL` |
| T-39 | No Tephritidae (5 hembras) | No inflar el MTD objetivo | **5 especímenes** | Definir criterio de conteo |

## Caso 1: una trampa del MF_UBI {#sec-caso-ubi}

Se tomó la trampa 1 de la ruta 602 (Cácota), tipo Jackson, atrayente 2, instalada el 10-abr-2014, coordenadas −72,63342 / 7,24964, altitud 2096 m, predio «Estación Pulido». La prueba de escritorio predice:

- El código ICA debe ser `54125-0602-1` (Divipola 54125 + registro 0602 + número 1).
- El tipo Jackson exige número impar: 1 es impar; **pasa**.
- La coordenada cae dentro del rango de Norte de Santander: **pasa**.
- El predio no trae área, código ni geometría; el modelo exige área positiva: **falla** si se carga el dato tal cual.
- El propietario solo tiene nombre; el modelo exige cédula: **falla** si no se inventa una identidad.
- La ruta se llama `CONGLOMERADO FRUTICOLA`, igual que las otras tres; el modelo exige nombre único: **falla** al cargar la segunda ruta.

La trampa se pudo insertar en la base de prueba solo después de aplicar las concesiones de la sección\nobreakspace\ref{sec-concesiones}. La conclusión no es que la trampa esté mal: es que el modelo pide más de lo que el formato histórico captura.

## Caso 2: una lectura del MF_CAP {#sec-caso-cap}

Se tomó la lectura de la trampa 45, *Ceratitis capitata*, 56 machos, 0 hembras, estado 1, fenología 3. La prueba de escritorio predice:

- El total de especímenes es 56; el modelo puede guardar `lect_especimenes = 56`.
- La especie, el sexo y el estado de diagnóstico **no tienen columna**; se pierden.
- La lectura no trae coordenadas ni ubicación; `ubic_id` queda nulo. El modelo permite insertarla, pero `fn_mtd_lectura_valida` no la devuelve porque no hay ubicación/lote.
- La visita no trae predio; se creó un predio ficticio para poder insertar la visita.
- El colector está vacío; se usó un usuario sintético.

El resultado ejecutado: **20 lecturas insertadas, 77 especímenes, 0 lecturas en el MTD**. La tabla `indice_mtd` se pudo llenar manualmente con 77/(20×7) = 0,550000, pero ese índice no se puede reproducir desde las lecturas con la función oficial. Es una inconsistencia de trazabilidad, no solo de dato.

## Caso 3: el MTD de la semana {#sec-caso-mtd}

La hoja `10-02-15` dice «semana 7», pero no trae fechas de inicio y fin del periodo. Si se asume una ventana de 7 días y 20 trampas atendidas, el cálculo manual da tres respuestas distintas según qué se cuente como «mosca»:

| Criterio | M | T | D | MTD |
|---|---:|---:|---:|---:|
| Total de especímenes (incluye No Tephritidae) | 77 | 20 | 7 | **0,5500** |
| Solo especies objetivo (*Ceratitis* + *Anastrepha*) | 72 | 20 | 7 | **0,5143** |
| Solo machos de especies objetivo | 62 | 20 | 7 | **0,4429** |

El modelo actual solo puede guardar un total por lectura y un `espm_id` opcional en el índice; no puede reproducir las tres variantes. La decisión de cuál es la M oficial no está en el levantamiento (UQQ-004 solo fija el umbral, no el criterio de conteo). Es una pregunta que debe responder el ICA antes de cargar datos históricos.

## Concesiones de importación {#sec-concesiones}

Para que los datos reales entraran en la base de prueba se hicieron estos ocho ajustes. **Ninguno debe convertirse en una práctica de producción.**

| # | Concesión | Por qué fue necesaria | Riesgo si se institucionaliza |
|---|---|---|---|
| 1 | Nombres de ruta con sufijo (`... 602`, `... 603`, etc.) | `ruta_nombre` es único | Se pierde el nombre oficial único del conglomerado |
| 2 | Área de predio y lote = 1 ha | `pred_area` y `lote_area` son `NOT NULL` y `> 0` | Se inventa superficie y se distorsiona cualquier indicador por área |
| 3 | Cédulas sintéticas para propietarios | `persona.pers_cc` es PK y `productor` la exige | Se crean identidades falsas; se rompe la trazabilidad con el ICA |
| 4 | Nombre del propietario partido en nombre/apellido | `persona` separa `pers_nombre` y `pers_apellido` | Nombres compuestos y copropietarios se interpretan mal |
| 5 | Usuario, técnico, administrador y dispositivo sintéticos | Las tablas de campo exigen actor y dispositivo | Se atribuye un dato histórico a un actor que no lo capturó |
| 6 | Código de trampa compuesto `54125-0602-1` | La restricción exige 5-4-número; el archivo trae 9 dígitos | Se cambia el código impreso en campo |
| 7 | `ubic_origen='legado'` | El trigger omite la validación de rango para legado | Se saltan controles sin dejar evidencia de la validación |
| 8 | Predio, visita y trampas ficticias para la ruta 606; `ubic_id=NULL` | El CAP no trae predio ni coordenadas | Las lecturas existen, pero no alimentan el MTD |

**Efecto acumulado en la base de prueba:** 153 predios (139 del origen, más las separaciones por copropiedad y el predio ficticio de la ruta 606), 318 trampas (297 del UBI con número, 20 del CAP y 1 de prueba), 297 ubicaciones y 20 lecturas. La diferencia entre 139 y 153 es, en sí misma, una medida del trabajo de resolución de entidades que el modelo no resuelve.

# Hallazgos y correcciones al modelo {#sec-hallazgos}

## Prioridad de los hallazgos {#sec-prioridad}

| Severidad | Cantidad | Criterio |
|---|---:|---|
| **Bloqueante** | 5 | Sin la corrección no se puede cargar el dato real sin inventar información |
| **Alta** | 5 | La carga es posible con workarounds, pero se pierde trazabilidad o se crea un riesgo operativo |
| **Media** | 7 | Afecta calidad, validación o mantenibilidad; se puede convivir temporalmente |
| **Baja** | 4 | Documentación, normalización o higiene de datos |

## Bloqueantes {#sec-bloqueantes}

### H-01 · La lectura no guarda especie, sexo ni diagnóstico {#sec-h01}

**Evidencia.** `lectura_trampa` solo tiene `lect_especimenes` (total). El comentario de la tabla dice: «total capturado SIN especie (la determinación de la especie queda fuera de este diseño: se retiró el módulo de laboratorio)». La consulta T-15 devuelve **0** columnas de especie, sexo, fenología o diagnóstico; T-16 devuelve **0** tablas de muestra, laboratorio o diagnóstico. El archivo CAP trae especie, machos, hembras y hembras grávidas en cada fila.

**Requisitos afectados.** RF-020 (registro de lectura), RF-023 (MTD por especie), RF-025 (estado pendiente de diagnóstico), RF-026 (enlace del resultado de laboratorio), RF-027 (relación de muestras), RDD-005 (lectura con estado de diagnóstico), RDD-006 (MTD por lote, especie y periodo), RN-015 (diagnóstico de especie en laboratorio).

**Impacto.** El sistema no puede emitir un MTD por especie ni demostrar qué especie se capturó. Tampoco puede distinguir una lectura pendiente de diagnóstico de una confirmada. Para el trámite de exportación, el dato de especie es el que justifica la interceptación; perderlo convierte la lectura en un número sin valor normativo.

**Corrección propuesta (mínima).** Añadir a `lectura_trampa` las columnas de especie y sexo, con una restricción que obligue a que el total sea la suma de machos y hembras (las grávidas son un subconjunto de las hembras y **no** se suman):

```sql
ALTER TABLE sigat.lectura_trampa
  ADD COLUMN lect_espm_id integer REFERENCES sigat.especie_mosca(espm_id),
  ADD COLUMN lect_machos integer,
  ADD COLUMN lect_hembras integer,
  ADD COLUMN lect_hembras_gravidas integer,
  ADD COLUMN lect_diagnostico_estado varchar NOT NULL DEFAULT 'pendiente'
    CHECK (lect_diagnostico_estado IN ('pendiente','confirmado','no_aplica'));

ALTER TABLE sigat.lectura_trampa
  ADD CONSTRAINT lect_conteo_sexos CHECK (
    (lect_machos IS NULL OR lect_machos >= 0) AND
    (lect_hembras IS NULL OR lect_hembras >= 0) AND
    (lect_hembras_gravidas IS NULL OR
       (lect_hembras_gravidas >= 0 AND lect_hembras_gravidas <= lect_hembras)) AND
    (lect_especimenes IS NULL OR
       lect_especimenes = COALESCE(lect_machos,0) + COALESCE(lect_hembras,0))
  );
```

**Corrección completa (recomendada para el MVP).** Si una lectura puede contener varias especies, usar una tabla hija:

```sql
CREATE TABLE sigat.lectura_trampa_especie (
  lect_id uuid NOT NULL REFERENCES sigat.lectura_trampa(lect_id),
  espm_id integer NOT NULL REFERENCES sigat.especie_mosca(espm_id),
  lees_machos integer NOT NULL DEFAULT 0 CHECK (lees_machos >= 0),
  lees_hembras integer NOT NULL DEFAULT 0 CHECK (lees_hembras >= 0),
  lees_hembras_gravidas integer CHECK (lees_hembras_gravidas >= 0),
  lees_estado_diagnostico varchar NOT NULL DEFAULT 'pendiente'
    CHECK (lees_estado_diagnostico IN ('pendiente','confirmado','rechazado')),
  PRIMARY KEY (lect_id, espm_id),
  CHECK (lees_hembras_gravidas IS NULL OR lees_hembras_gravidas <= lees_hembras)
);
```

Y crear las tablas de muestra y diagnóstico que exige RF-027:

```sql
CREATE TABLE sigat.muestra (
  muest_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  muest_registro_id uuid NOT NULL,
  muest_version integer NOT NULL DEFAULT 1,
  visi_id uuid NOT NULL REFERENCES sigat.visita(visi_id),
  lote_id integer REFERENCES sigat.lote(lote_id),
  muest_fecha_colecta date NOT NULL,
  muest_numero_ruta varchar,
  muest_municipio integer REFERENCES sigat.municipio(muni_id),
  muest_estado varchar NOT NULL DEFAULT 'pendiente'
    CHECK (muest_estado IN ('pendiente','enviada','diagnosticada','anulada')),
  muest_laboratorio varchar,
  muest_fecha_envio date,
  muest_fecha_resultado date,
  muest_observaciones text,
  UNIQUE (muest_registro_id, muest_version)
);

CREATE TABLE sigat.muestra_lectura (
  muest_id uuid NOT NULL REFERENCES sigat.muestra(muest_id),
  lect_id uuid NOT NULL REFERENCES sigat.lectura_trampa(lect_id),
  PRIMARY KEY (muest_id, lect_id)
);

CREATE TABLE sigat.diagnostico_muestra (
  diag_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  muest_id uuid NOT NULL REFERENCES sigat.muestra(muest_id),
  espm_id integer REFERENCES sigat.especie_mosca(espm_id),
  diag_machos integer CHECK (diag_machos >= 0),
  diag_hembras integer CHECK (diag_hembras >= 0),
  diag_resultado varchar NOT NULL,
  diag_fecha date NOT NULL,
  diag_laboratorio varchar,
  diag_boletin varchar,
  diag_observaciones text
);
```

**Criterio de aceptación.** Cargar la fila 45 del CAP (56 machos, *Ceratitis capitata*) debe producir una lectura con `lect_especimenes=56`, `lect_machos=56`, `lect_hembras=0`, `lect_espm_id` de *Ceratitis*, y un MTD por especie de 56/(20×7)=0,4000. Cargar la fila 42 (*Anastrepha*: 6+10) debe producir 16 y un MTD de 0,1143. La fila 32 (No Tephritidae: 5 hembras) debe quedar fuera del MTD objetivo por decisión explícita del programa, no por accidente.

### H-02 · Predio y lote no admiten «sin área» {#sec-h02}

**Evidencia.** `predio.pred_area` es `NOT NULL` con `CHECK (pred_area > 0)`; `lote.lote_area` es `NOT NULL` con `CHECK (lote_area > 0)`. El MF_UBI no trae área de predio ni de lote; las 298 filas traen `Lote = NO APLICA` (297) o vacío (1). La prueba T-02 rechaza `NULL` con `23502`; `0` también es rechazado por la regla de área positiva; el texto `NO APLICA` falla con `22P02` (T-03).

**Requisitos afectados.** RDD-001 (predio con área), RDD-002 (lote con área), RF-084 (geometrías), RN-013 (asignación trampa–lote). El requisito pide área; el dato no la tiene. La solución no es inventar 1 ha: es representar **«área no conocida»** y bloquear los indicadores que dependan de ella.

**Corrección propuesta.** Permitir `NULL` y añadir un estado de calidad:

```sql
ALTER TABLE sigat.predio ALTER COLUMN pred_area DROP NOT NULL;
ALTER TABLE sigat.predio DROP CONSTRAINT predio_area_positiva;
ALTER TABLE sigat.predio ADD CONSTRAINT predio_area_positiva
  CHECK (pred_area IS NULL OR pred_area > 0);
ALTER TABLE sigat.predio
  ADD COLUMN pred_area_origen varchar NOT NULL DEFAULT 'sin_dato'
  CHECK (pred_area_origen IN ('declarada','levantamiento','catastro','sin_dato'));

ALTER TABLE sigat.lote ALTER COLUMN lote_area DROP NOT NULL;
ALTER TABLE sigat.lote DROP CONSTRAINT lote_area_positiva;
ALTER TABLE sigat.lote ADD CONSTRAINT lote_area_positiva
  CHECK (lote_area IS NULL OR lote_area > 0);
ALTER TABLE sigat.lote
  ADD COLUMN lote_area_origen varchar NOT NULL DEFAULT 'sin_dato'
  CHECK (lote_area_origen IN ('declarada','levantamiento','catastro','sin_dato'));
```

Para el lote, además, el modelo debe aceptar que **no exista lote** en una ubicación histórica. `ubicacion_trampa.lote_id` ya es opcional; el problema es que `periodo_trampeo.lote_id` y `concepto_aptitud.lote_id` son obligatorios (H-05).

**Criterio de aceptación.** Cargar un predio sin área debe ser posible con `pred_area IS NULL` y `pred_area_origen='sin_dato'`; cualquier reporte que use área debe mostrar «sin dato», no cero. Cargar una ubicación con `lote_id NULL` debe ser válido y debe quedar excluida del MTD por lote, sin error.

### H-03 · Identidad del productor y copropiedad {#sec-h03}

**Evidencia.** `persona.pers_cc` es la llave primaria (`bigint NOT NULL`); `productor.pers_cc` es PK y FK; `predio.pers_cc` es `NOT NULL` y apunta a un solo productor. El archivo solo trae `Propietario` como texto: 89 filas sin propietario, 44 predios sin dueño, 11 predios con más de un propietario y 10 propietarios con más de un predio. La prueba T-04 rechaza una persona sin cédula; T-25 cuenta 11 predios con varios propietarios.

**Requisitos afectados.** RDD-001 (responsable del predio), RF-002 (visibilidad por productor), RNF-015 (control de acceso). La identidad es la base de la autorización; si se inventa la cédula, la autorización deja de ser verificable.

**Corrección propuesta.** Separar la identidad de la persona de su documento y permitir varias personas por predio:

```sql
-- v7: persona con identificador surrogate y documento opcional
CREATE TABLE sigat.persona (
  pers_id bigint GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
  pers_tipo_documento varchar,
  pers_documento varchar,
  pers_nombre varchar NOT NULL,
  pers_apellido varchar,
  pers_nombre_completo varchar,
  pers_telefono varchar,
  pers_direccion varchar,
  pers_correo varchar,
  pers_identificado boolean NOT NULL DEFAULT false
);
CREATE UNIQUE INDEX persona_documento_uq
  ON sigat.persona (pers_tipo_documento, pers_documento)
  WHERE pers_documento IS NOT NULL;

-- relación N:M entre predio y productor
CREATE TABLE sigat.predio_productor (
  pred_id integer NOT NULL REFERENCES sigat.predio(pred_id),
  pers_id bigint NOT NULL REFERENCES sigat.persona(pers_id),
  prpr_rol varchar NOT NULL
    CHECK (prpr_rol IN ('propietario','poseedor','representante','otro')),
  prpr_desde date,
  prpr_hasta date,
  PRIMARY KEY (pred_id, pers_id, prpr_rol)
);
```

Si el cambio de PK es demasiado costoso para el MVP, una alternativa mínima es conservar `pers_cc` pero reservar un rango de cédulas sintéticas y añadir `pers_identificado boolean`; **no se recomienda** porque mantiene el riesgo de confundir una identidad real con una sintética.

**Criterio de aceptación.** Un predio con dos propietarios debe tener dos filas en `predio_productor`; un predio sin propietario debe poder existir con `pers_identificado=false`; la vista de visibilidad debe decidir qué hacer con un productor no identificado (por defecto, no mostrar el predio a nadie hasta completar la identidad).

### H-04 · La visita y la lectura histórica no tienen camino de importación {#sec-h04}

**Evidencia.** `visita.pred_id`, `visita.dispositivo`, `visita.usua_id` y `visita.oper_id` son `NOT NULL`; `lectura_trampa.visi_id`, `usua_id`, `disp_id` y `oper_id` también. El MF_CAP no trae colector (0/20), no trae predio (0/20) y no nació de un celular. Las pruebas T-05 y T-06 rechazan la visita sin predio y la lectura sin usuario. Para cargar las 20 lecturas se crearon un usuario, un dispositivo, un predio y una visita ficticios.

**Requisitos afectados.** ADR-03 (append-only con versiones), RN-009 (inmutabilidad de la fecha de observación), RN-010 (idempotencia), RF-083 (bitácora). La trazabilidad exige saber quién capturó y con qué dispositivo; un dato histórico no tiene esa información, pero tampoco debe atribuirse a un actor ficticio.

**Corrección propuesta.** Añadir un origen explícito y un lote de carga:

```sql
ALTER TABLE sigat.visita
  ADD COLUMN visi_origen varchar NOT NULL DEFAULT 'app'
  CHECK (visi_origen IN ('app','importacion_papel','migracion_v5','correccion'));
ALTER TABLE sigat.lectura_trampa
  ADD COLUMN lect_origen varchar NOT NULL DEFAULT 'app'
  CHECK (lect_origen IN ('app','importacion_papel','migracion_v5','correccion'));

CREATE TABLE sigat.carga_historica (
  carga_id bigint GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
  carga_archivo varchar NOT NULL,
  carga_hoja varchar NOT NULL,
  carga_hash varchar(64) NOT NULL,
  carga_fecha timestamptz NOT NULL DEFAULT now(),
  carga_estado varchar NOT NULL DEFAULT 'abierta'
    CHECK (carga_estado IN ('abierta','validada','publicada','rechazada')),
  carga_notas text
);

ALTER TABLE sigat.lectura_trampa
  ADD COLUMN lect_carga_id bigint REFERENCES sigat.carga_historica(carga_id);
ALTER TABLE sigat.visita
  ADD COLUMN visi_carga_id bigint REFERENCES sigat.carga_historica(carga_id);
```

Para los datos históricos, `usua_id` y `disp_id` deben ser **opcionales** (o apuntar a un actor «importador histórico» identificado como tal), y la UI debe mostrar «carga histórica» en lugar de un nombre de técnico. La operación de sincronización puede generarse de forma determinista a partir de `(carga_id, fila)` para mantener la idempotencia.

**Criterio de aceptación.** Importar dos veces el mismo archivo no duplica filas; la bitácora distingue `origen='importacion_papel'`; ninguna lectura histórica se atribuye a un técnico real sin evidencia.

### H-05 · El MTD y el concepto están amarrados al lote, pero el dato histórico es por ruta/predio {#sec-h05}

**Evidencia.** `periodo_trampeo.lote_id` es `NOT NULL`; `concepto_aptitud.lote_id` es `NOT NULL`; `indice_mtd` se calcula por periodo (y por lote); `fn_mtd_lectura_valida` une `ubicacion_trampa.lote_id = periodo.lote_id`. Las 20 lecturas del CAP se insertaron con `ubic_id=NULL` y **0** entraron al MTD (T-31). El archivo no trae lote: `Lote = NO APLICA` en 297/298 filas del UBI y en 20/20 del CAP.

**Requisitos afectados.** RF-022 (periodo de trampeo), RF-023 (MTD del lote), RF-024 (concepto del lote), RN-013 (asignación trampa–lote), RDD-006 (MTD por lote, especie y periodo). El requisito es explícitamente por lote; el dato histórico no lo tiene. Hay que decidir si el histórico se carga a nivel ruta/predio o si se exige digitalizar lotes antes de migrar.

**Opciones.**

1. **Exigir lote antes de migrar (más fiel al requisito).** Completar la geometría y el área de los lotes; asignar cada trampa a un lote; cargar el histórico solo cuando exista esa asignación. Es la opción correcta para el trámite de exportación, pero bloquea la migración hasta que el ICA entregue los polígonos.
2. **Permitir un ámbito ruta/predio para el histórico (más pragmático).** Hacer `periodo_trampeo.lote_id` nullable y añadir `pred_id`/`ruta_id` con una restricción de ámbito; calcular un MTD informativo por ruta/predio que **no** emita concepto de aptitud. El concepto sigue exigiendo lote.

```sql
ALTER TABLE sigat.periodo_trampeo ALTER COLUMN lote_id DROP NOT NULL;
ALTER TABLE sigat.periodo_trampeo
  ADD COLUMN pred_id integer REFERENCES sigat.predio(pred_id),
  ADD COLUMN ruta_id integer REFERENCES sigat.ruta(ruta_id);
ALTER TABLE sigat.periodo_trampeo
  ADD CONSTRAINT periodo_ambito CHECK (
    (lote_id IS NOT NULL)::int + (pred_id IS NOT NULL)::int + (ruta_id IS NOT NULL)::int = 1
  );
```

La función `fn_mtd_lectura_valida` debe cambiar para filtrar por el ámbito del periodo: si es lote, por `ubicacion.lote_id`; si es predio, por `ubicacion.pred_id`; si es ruta, por `ubicacion.ruta_id`. El `concepto_aptitud` sigue con `lote_id NOT NULL` y solo se emite cuando el ámbito es lote.

**Criterio de aceptación.** Un periodo de ruta con 20 lecturas válidas debe devolver 20 y un MTD informativo; no debe permitir insertar un concepto de aptitud para ese periodo.

## Altas {#sec-altas}

### H-06 · El nombre de ruta es único, pero las cuatro rutas reales se llaman igual {#sec-h06}

**Evidencia.** `ruta.ruta_nombre` tiene `UNIQUE`; el archivo usa `CONGLOMERADO FRUTICOLA` en las cuatro hojas. La prueba T-01 rechaza la segunda ruta con `23505`. La unicidad de negocio ya existe en `(cent_id, ruta_codigo)`, que es el código que usa el ICA.

**Corrección.** Eliminar la unicidad del nombre y conservar la del código:

```sql
ALTER TABLE sigat.ruta DROP CONSTRAINT ruta_ruta_nombre_key;
-- (cent_id, ruta_codigo) ya es UNIQUE
```

**Criterio de aceptación.** Las cuatro rutas se cargan con el mismo nombre y códigos distintos; la vista `v_ruta_codigo_ica` las distingue por código.

### H-07 · El formato del código de trampa no coincide con el código de ruta del archivo {#sec-h07}

**Evidencia.** La restricción `trampa_codigo_formato` exige cinco dígitos, un guion, hasta diez caracteres alfanuméricos, otro guion y hasta cuatro dígitos (por ejemplo, `54125-0602-1`). El archivo trae el código de ruta de 9 dígitos (`541250602`) y el número de trampa (`1`); el código natural `541250602-1` **no pasa** la restricción. La prueba T-07 confirma que un código `1` es rechazado; la prueba T-07b confirma que un código completo repetido choca con la unicidad. El modelo usa dos representaciones distintas: el código de ruta de 9 dígitos que deriva `v_ruta_codigo_ica` y el código de trampa de 5-4-número que exige la restricción. El importador debe partir el código de ruta; el formato no está documentado en el archivo y es fácil equivocarse.

**Corrección.** Definir un formato canónico y documentarlo. La recomendación es `Divipola(5)-RegistroRuta(4)-Numero(1-4)`, que es el que usa el ICA en campo:

```sql
ALTER TABLE sigat.trampa ALTER COLUMN tram_codigo SET NOT NULL;
ALTER TABLE sigat.trampa DROP CONSTRAINT trampa_codigo_formato;
ALTER TABLE sigat.trampa ADD CONSTRAINT trampa_codigo_formato
  CHECK (tram_codigo ~ '^[0-9]{5}-[0-9]{4}-[0-9]{1,4}$');
```

El importador debe partir el código de 9 dígitos: `541250602` → `54125` + `0602` + `1`. Si se decide aceptar también el formato de 9 dígitos, la restricción debe admitir ambas formas y la aplicación debe normalizar antes de mostrar.

### H-08 · Los catálogos no tienen código de origen y el atrayente está invertido {#sec-h08}

**Evidencia.** El archivo usa códigos numéricos para región, tipo de trampa, atrayente, condición, fenología, localización, árbol y vigilancia. Varios catálogos no tienen columna de código (`region`, `tipo_trampa`, `atrayente`, `condicion_trampa`, `arbol`, `centro_acopio`) y dependen del `IDENTITY`. La prueba T-17 muestra que `02_catalogos_basicos.sql` inserta `Plug` primero (`atra_id=1`) y `Proteico hidrolizado` después (`atra_id=2`), mientras el archivo usa **2 = Plug** (Jackson) y **1 = Proteico** (McPhail). Cargar por `atra_id` intercambia los atrayentes.

**Corrección.**

```sql
ALTER TABLE sigat.atrayente ADD COLUMN atra_codigo smallint UNIQUE;
ALTER TABLE sigat.tipo_trampa ADD COLUMN tipt_codigo smallint UNIQUE;
ALTER TABLE sigat.condicion_trampa ADD COLUMN cond_codigo smallint UNIQUE;
ALTER TABLE sigat.arbol ADD COLUMN arbo_codigo smallint UNIQUE;
ALTER TABLE sigat.region ADD COLUMN regi_codigo smallint UNIQUE;
ALTER TABLE sigat.centro_acopio ADD COLUMN cent_codigo varchar UNIQUE;

UPDATE sigat.atrayente SET atra_codigo = 1 WHERE atra_descripcion = 'Proteico hidrolizado';
UPDATE sigat.atrayente SET atra_codigo = 2 WHERE atra_descripcion = 'Plug';
```

Y corregir el orden de inserción del catálogo para que el `IDENTITY` no se use como código de negocio. Los códigos oficiales de condición, fenología, localización y árbol siguen pendientes (`docs/09_pendientes_institucionales.md`); el importador debe rechazar un código desconocido, no adivinar.

### H-09 · La fenología se registra por lectura, pero el modelo solo la guarda por lote {#sec-h09}

**Evidencia.** El MF_CAP trae `Fenologia` en cada fila (1 en 7 filas, 3 en 13). El modelo tiene `etapa_declarada` por lote, con usuario, dispositivo y operación; no tiene `lect_feno_id`. Para una lectura histórica sin lote, no hay dónde guardar la fenología observada.

**Corrección.** Añadir a la lectura una referencia opcional a la etapa observada:

```sql
ALTER TABLE sigat.lectura_trampa
  ADD COLUMN lect_feno_id integer REFERENCES sigat.fenologia(feno_id);
```

Si se prefiere mantener la separación entre «declarada» y «derivada», crear `lectura_fenologia` con `lect_id`, `feno_id`, `autor` y `origen`. La etapa derivada sigue calculándose con `fn_etapa_derivada`; la observada se conserva como evidencia.

### H-10 · Las fechas del archivo son solo fecha; el modelo usa `timestamptz` {#sec-h10}

**Evidencia.** `Fecha Instalacion` y `Fecha` son seriales de Excel sin hora (41739 → 2014-04-10; 42045 → 2015-02-10). El modelo usa `timestamptz` para `lect_t_observacion`, `lect_t_captura` y `visi_t_*`. Para cargar, se puso medianoche; eso es una decisión, no un dato.

**Corrección.** Añadir precisión y origen a la fecha:

```sql
ALTER TABLE sigat.lectura_trampa
  ADD COLUMN lect_fecha_precision varchar NOT NULL DEFAULT 'fecha'
  CHECK (lect_fecha_precision IN ('fecha','hora','desconocida'));
ALTER TABLE sigat.visita
  ADD COLUMN visi_fecha_precision varchar NOT NULL DEFAULT 'fecha'
  CHECK (visi_fecha_precision IN ('fecha','hora','desconocida'));
```

Regla de importación: una fecha sin hora se guarda a las 00:00 de `America/Bogota`, con `precision='fecha'`; no se inventa una hora. La validación de plantilla debe comprobar que el año/semana del encabezado coincidan con la fecha de la celda (T-24).

## Medias {#sec-medias}

### H-11 · El catálogo de cultivo no está normalizado {#sec-h11}

**Evidencia.** `arbol` es `UNIQUE` pero sensible a mayúsculas. El archivo trae `durazno` (166), `DURAZNO` (121), `DURANZO` (8), `DUARZNO` (2) y `CAFÉ` (1). La prueba T-12 acepta `durazno` y `DURAZNO` como dos filas distintas. `CAFÉ` es un cultivo distinto, no una variante de durazno; no debe mapearse a durazno sin decisión.

**Corrección.** Añadir `arbo_codigo` y normalizar con `upper(trim())` o `citext`; crear una tabla de alias para los errores de digitación y una regla que rechace un cultivo no declarado en el programa. No convertir `CAFÉ` en durazno.

### H-12 · Nombres de predio y propietario sucios o incompletos {#sec-h12}

**Evidencia.** 1 predio sin nombre; 89 filas sin propietario; 44 predios sin dueño; nombres con `/` para copropiedad, con puntos, dobles espacios y variantes (`VISTOR`/`VICTOR`, `MARCO A. RODRIGUEZ`/`MARCO A. RODRIGUEZ/NERIO SOLANO`). La entidad «predio» se identificó por `(municipio, nombre normalizado, propietario)`; sin esa normalización, el mismo predio puede duplicarse.

**Corrección.** Crear una tabla de alias y un proceso de resolución de entidades:

```sql
CREATE TABLE sigat.predio_alias (
  pred_id integer NOT NULL REFERENCES sigat.predio(pred_id),
  pral_alias varchar NOT NULL,
  pral_fuente varchar,
  PRIMARY KEY (pred_id, pral_alias)
);
```

Regla de importación: no crear un predio nuevo si el alias normalizado ya existe en el mismo municipio; si hay conflicto de propietario, marcar para revisión humana. Los nombres de personas se guardan como texto completo además de nombre/apellido para no perder compuestos.

### H-13 · Coordenadas repetidas y posibles duplicados {#sec-h13}

**Evidencia.** 147 pares de coordenadas únicos para 298 registros (297 con número). Ocho pares aparecen en 4 trampas; un par se comparte entre rutas. Parte de la repetición es normal: Jackson y McPhail se instalan en el mismo punto. Pero la repetición de 4 trampas en el mismo par, o entre rutas, puede ser duplicación de datos.

**Corrección.** No prohibir coordenadas iguales (la trampa es la entidad, no el punto). Añadir una advertencia de calidad: si dos trampas de la misma ruta y tipo comparten coordenada exacta, marcar para revisión; si dos rutas distintas comparten coordenada, exigir confirmación. Guardar `ubic_precision_m` y `ubic_origen` para distinguir GPS de estimación.

### H-14 · El código de ruta no se valida contra el municipio {#sec-h14}

**Evidencia.** La prueba T-11 insertó una ruta con `ruta_codigo='541250603'` y `muni_id` de Chitagá; el modelo la aceptó. La hoja 605 se llama SILOS pero tiene municipio Chitagá y código `541740605` (T-30). Sin validación, un error de plantilla se convierte en un error de negocio.

**Corrección.** Trigger que compruebe que el prefijo de 5 dígitos del código de ruta coincide con el Divipola del municipio:

```sql
CREATE OR REPLACE FUNCTION sigat.fn_ruta_codigo_valida() RETURNS trigger ...
-- divipola = depa_codigo || muni_codigo
-- si ruta_codigo es de 9 dígitos, validar substring(1,5) = divipola
```

Y una regla de importación que compare el nombre de la hoja con el municipio; si no coincide, detener la carga y pedir confirmación.

### H-15 · «Centro de acopio» del archivo no es el centro de acopio del modelo {#sec-h15}

**Evidencia.** El encabezado del MF_UBI dice `**** CENTRO DE ACOPIO:` y el valor es `NORTE_DE_SANTANDER`, que es el departamento, no un centro de acopio. El modelo tiene `centro_acopio` con `cent_descripcion` y `depa_id`, y lo usa para rutas, técnicos y administradores. Mapear el departamento a un centro de acopio crea una entidad falsa.

**Corrección.** Aclarar con el ICA qué significa «centro de acopio» en el formato. Si es la regional/departamento, mapearlo a `departamento`/`region`; si es una oficina, cargar el catálogo real. Mientras tanto, no usar ese campo para crear `centro_acopio`.

### H-16 · El bypass `ubic_origen='legado'` no tiene control {#sec-h16}

**Evidencia.** `fn_ubicacion_trampa_valida` hace `IF NEW.ubic_origen = 'legado' THEN RETURN NEW;`. La prueba T-09 rechaza una coordenada fuera de rango con `origen='operacion'`; la prueba T-10 la acepta con `origen='legado'`. `ubic_origen` es `varchar` libre, sin `CHECK`.

**Corrección.** Convertir `ubic_origen` en un dominio con valores permitidos (`app`, `importacion`, `legado`, `correccion`) y separar la validación: el legado puede omitir la validación automática, pero debe registrar el resultado de una validación posterior y quedar marcado para revisión. No debe ser una puerta silenciosa.

### H-17 · `ruta_codigo` corto vs. código de 9 dígitos {#sec-h17}

**Evidencia.** El modelo documenta `ruta.ruta_codigo` como el registro corto (`602`) y la vista `v_ruta_codigo_ica` compone 9 dígitos. En la prueba de carga se guardó el código de 9 dígitos y la vista devolvió **0 filas**. El archivo trae ambos campos, así que el importador tiene que elegir el corto; no es evidente para quien lee el `.xls`.

**Corrección.** Añadir una validación de formato a `ruta.ruta_codigo` (`^[0-9]{1,4}$`) y una nota en el contrato de importación. Si se quiere admitir el código de 9 dígitos, añadir una columna `ruta_codigo_9` generada o una función de normalización; no guardar dos significados en la misma columna.

## Bajas {#sec-bajas}

### H-18 · Trampa sin número {#sec-h18}

Una fila de la ruta 604 (fila 13, predio «La Vega de Víctor») no trae número de trampa. El importador debe rechazarla y reportarla; no debe inventar un número. La restricción de formato ya la rechaza (T-07), pero el proceso debe dar un mensaje claro y una lista de filas.

### H-19 · Fechas de 2012 en un archivo de 2014 {#sec-h19}

Tres trampas de la ruta 603 (predio «Piedra Blanca») tienen fecha 2012-04-23. Puede ser un error de digitación o una instalación real anterior. La regla de importación debe comparar la fecha con el rango del programa y marcar la fila para revisión; no debe corregirla automáticamente.

### H-20 · Datos personales y retención {#sec-h20}

Los archivos contienen nombres de propietarios y posibles direcciones. El modelo guarda nombres, teléfonos, direcciones y correos. Hay que aplicar minimización, control de acceso por rol, cifrado en reposo y una política de retención. El informe evita reproducir nombres completos; los scripts de importación deben hacer lo mismo en los logs.

### H-21 · Documentación desactualizada {#sec-h21}

El comentario de `lectura_trampa` afirma que la especie queda fuera del diseño; los requisitos vigentes exigen lo contrario. El diccionario y el PDF «Explicación de cada tabla» repiten esa afirmación. Hay que actualizar comentarios, diccionario, DBML, diagramas y pruebas cuando se aprueben H-01 a H-05.

# Trazabilidad con los requisitos {#sec-trazabilidad}

| Requisito | Qué exige | Implementación actual | Estado | Hallazgo |
|---|---|---|---|---|
| RF-002 | Autorización por rol y predio | Vistas y funciones de visibilidad; PE-01 a PE-06 | **Cumple** | — |
| RF-012 | Coherencia trampa–lote–presencia | `lect_geom`, `lect_coincide_lote`, `fn_lote_que_contiene` | **Parcial** | Sin GPS por lectura en el archivo histórico; no hay evidencia de campo |
| RF-020 | Lectura por trampa con especímenes y fecha | `lectura_trampa` con total y fecha | **Parcial** | No guarda especie/sexo (H-01) |
| RF-021 | Instalación y mantenimiento de trampa | `tram_fecha_registro`, `lect_fecha_cambio_cuerpo/atrayente` | **Parcial** | El MF_UBI solo trae instalación; no hay cambios de cuerpo/atrayente |
| RF-022 | Periodo y días de exposición | `periodo_trampeo`, `indi_dias_exposicion` | **Parcial** | El CAP no trae inicio/fin de periodo; el histórico es por ruta (H-05) |
| RF-023 | MTD por especie | `indice_mtd.espm_id`, pero lectura sin especie | **No cumple** | H-01, H-05 |
| RF-024 | Concepto contra umbral vigente | `concepto_aptitud`, `fn_concepto_valida` | **Cumple** con umbral nulo | UQQ-004 pendiente; no se inventa |
| RF-025 | Estado pendiente de diagnóstico | No existe | **No cumple** | H-01 |
| RF-026 | Enlace de resultado de laboratorio | No existe | **No cumple** | H-01 |
| RF-027 | Relación de muestras | No existe | **No cumple** | H-01 |
| RF-083 | Bitácora de auditoría | `bitacora_auditoria`, `fn_auditar`; PE-42 a PE-44 | **Cumple** | — |
| RF-084 | Validación de geometrías | `fn_lote_geometria_valida`, `fn_ubicacion_trampa_valida` | **Cumple** si hay geometría | El archivo no trae polígonos (H-02) |
| RDD-001 | Predio con código, nombre, municipio, geometría, área y responsable | `predio` | **Parcial** | Área obligatoria, un solo productor, geometría opcional (H-02, H-03) |
| RDD-002 | Lote con código, polígono, área, variedad, plantación y estado | `lote`, `lote_geometria` | **Parcial** | No hay lotes en el archivo; área obligatoria (H-02, H-05) |
| RDD-003 | Celda de retícula | `reticula`, `reticula_celda` | **Cumple** | No hay datos en el archivo; se probó con demo |
| RDD-004 | Trampa con nomenclatura, tipo, atrayente, lote, coordenadas y fechas | `trampa`, `ubicacion_trampa` | **Parcial** | Código/formato, lote opcional, sin fechas de retiro explícitas (H-06, H-07) |
| RDD-005 | Lectura con especímenes, estado, cambios y diagnóstico | `lectura_trampa` | **Parcial** | Sin diagnóstico; sin especie/sexo (H-01) |
| RDD-006 | MTD por lote, especie y periodo | `indice_mtd` | **Parcial** | Índice tiene especie, pero la lectura no; ámbito lote (H-01, H-05) |
| RDD-007 | Umbral y programa versionados | `programa_inspeccion`, `programa_umbral`, vigencias | **Cumple** | UQQ-004 pendiente |
| RDD-008 | Aplicaciones fitosanitarias | `aplicacion_fitosanitaria` | **Cumple** | Sin datos en el archivo |
| RDD-009 | Cosechas | `cosecha` | **Cumple** | Sin datos en el archivo |
| RN-005 | Nomenclatura Divipola + ruta + número; paridad | `fn_trampa_valida`, `v_ruta_codigo_ica` | **Parcial** | Formatos incompatibles (H-07, H-17); paridad cumple (T-08/T-18) |
| RN-006 | WGS84, grados decimales, 5 decimales | `numeric(8,5)`, `numeric(7,5)`, SRID 4326 | **Cumple** | Coordenadas reales dentro del rango (T-20) |
| RN-009 | Fecha de observación inmutable | `fn_registro_version_valida` | **Cumple** | PE-18 |
| RN-010 | Idempotencia | `operacion_sync` UNIQUE (dispositivo, cliente) | **Cumple** para app | La importación histórica no tiene clave equivalente (H-04) |
| RN-013 | Asignación trampa–lote para MTD | `ubicacion_trampa.lote_id`; `fn_mtd_lectura_valida` | **Parcial** | Lote opcional en ubicación; sin lote no hay MTD (H-05) |
| RN-014 | Autorreporte no alimenta MTD | `lect_linaje` | **Cumple** | — |
| RN-015 | Diagnóstico de especie en laboratorio | No existe | **No cumple** | H-01 |

# Plan de corrección y carga {#sec-plan}

## Decisiones que deben tomarse antes de tocar el esquema {#sec-decisiones}

| Decisión | Dueño | Por qué bloquea |
|---|---|---|
| ¿El histórico se carga a nivel lote o a nivel ruta/predio? | ICA + arquitectura | Define H-05 y el alcance del MTD histórico |
| ¿Se digitalizan lotes y geometrías antes de migrar? | ICA + catastro | Sin lote no hay MTD ni concepto |
| ¿Cuál es la M oficial del MTD: total, objetivo o machos? | ICA (UQQ-004 y norma) | Cambia el resultado de 0,55 a 0,44 |
| ¿Se acepta un productor no identificado? | ICA + seguridad | Define H-03 y la autorización |
| ¿Se cargan muestras/laboratorio en el MVP o solo el estado pendiente? | ICA + arquitectura | Define el alcance de H-01 |
| ¿Qué significa «centro de acopio» en el formato? | ICA | Define H-15 |

## Fases {#sec-fases}

**Fase 0 · Acuerdos y datos maestros.** Confirmar las decisiones anteriores; cargar catálogos oficiales (DANE, fenología, condición, localización, árbol, región, vigilancia); definir el umbral y el criterio de conteo. Sin esto, cualquier carga produce resultados no comparables.

**Fase 1 · Correcciones bloqueantes (v6.1).** Aplicar H-01 a H-05 en una migración versionada: especie/sexo/diagnóstico, áreas opcionales, identidad y copropiedad, origen histórico, ámbito del MTD. Añadir pruebas de regresión con las filas reales del CAP y del UBI.

**Fase 2 · Correcciones altas.** H-06 a H-10: nombre de ruta, formato de código, códigos de catálogo, fenología por lectura y precisión de fecha.

**Fase 3 · Staging y ETL.** Crear `sigat_imp` con las tablas crudas, el hash de archivo y la fila de origen. El ETL debe ser idempotente y dejar trazabilidad de cada fila; no debe escribir directamente en `sigat` sin pasar por validación.

**Fase 4 · Carga piloto.** Cargar una ruta completa del UBI (por ejemplo, 602 con 95 trampas) y la semana del CAP (20 lecturas). Validar conteos, paridad, coordenadas, MTD manual y cero duplicados. Después ampliar a las otras rutas.

**Fase 5 · Cierre.** Actualizar diccionario, DBML, diagramas, comentarios y pruebas; registrar las decisiones como ADR; capacitar al equipo de campo en el formato de importación.

## ETL mínimo propuesto {#sec-etl}

1. **Extraer** cada hoja a CSV con un mapa de encabezados por hoja y por semántica (no por posición).
2. **Cargar** en `sigat_imp.fila_ubi`/`fila_cap` con `carga_id`, `archivo`, `hoja`, `fila`, `hash` y el JSON crudo.
3. **Normalizar** fechas, números, códigos y nombres; registrar el valor original y el normalizado.
4. **Resolver** catálogos por código, no por `ID`; rechazar códigos desconocidos.
5. **Resolver** entidades: predio por alias normalizado; propietario por documento si existe, si no por nombre + revisión humana.
6. **Crear** trampas y ubicaciones; componer el código ICA; validar paridad y rango.
7. **Crear** visitas y lecturas; si no hay lote, usar el ámbito ruta/predio y marcarlo como histórico.
8. **Validar** conteos, duplicados, MTD manual y reglas; publicar solo si el lote de carga queda en `validada`.

## Criterios de aceptación de la migración {#sec-aceptacion}

- Las 297 trampas con número del UBI se cargan con código ICA único, paridad correcta y coordenadas dentro del rango; la fila sin número se rechaza y se reporta.
- Los 139 predios se cargan sin inventar área; los que no tienen área quedan marcados `sin_dato`.
- Los 11 predios con copropiedad tienen más de un productor; los 44 sin dueño quedan marcados y no se asignan a un usuario.
- Las 20 lecturas del CAP se cargan con especie, sexo y estado de diagnóstico; el MTD por especie se reproduce a mano.
- El MTD total, objetivo y de machos se puede calcular con un criterio explícito y documentado.
- Ninguna lectura histórica se atribuye a un técnico real sin evidencia.
- La carga es idempotente: ejecutarla dos veces no duplica filas.
- Las consultas de validación (`06_validacion.sql`) siguen dando cero filas.
- Las 31 pruebas de restricciones y los 52 pasos de los escenarios siguen pasando.
- El informe de importación lista las filas rechazadas y el motivo, sin corregirlas en silencio.

## Qué no hacer {#sec-no-hacer}

- No usar `pred_area = 0` ni `1 ha` como sustituto de «sin dato».
- No inventar cédulas para propietarios; usar un identificador surrogate y marcar `identificado=false`.
- No usar `ubic_origen='legado'` para saltar la validación sin registrar el resultado.
- No importar las plantillas vacías ni las filas con `42`.
- No interpretar el código de 9 dígitos como `ruta_codigo`; usar el registro corto y derivar el código.
- No mapear `CAFÉ` a durazno ni unificar nombres de propietario sin revisión.
- No cargar el CAP como si tuviera ubicación: no la tiene; hay que completar el MF_UBI de la ruta 606.
- No emitir un concepto de aptitud con datos históricos sin lote y sin umbral.

# Conclusiones {#sec-conclusiones}

El modelo SIGAT v6 está bien construido para el sistema que se está diseñando: las reglas de versión, la auditoría, la paridad de trampas, la validación de geometrías y el control de acceso funcionan y están probadas. Pero fue diseñado para datos que nacen en la aplicación, no para los formatos manuales que el ICA usó antes. La diferencia no es cosmética: el archivo real trae especie, sexo, fenología y copropiedad que el modelo no puede representar, y exige áreas, cédulas, lotes y usuarios que el archivo no trae.

Las cinco correcciones bloqueantes no son un rediseño completo. Son cambios acotados: una tabla hija de especie/sexo, dos columnas de área opcionales, una identidad surrogate con relación N:M, un origen histórico con lote de carga y un ámbito de MTD por ruta/predio. Con ellas, los datos reales se pueden cargar sin inventar información y el sistema puede seguir cumpliendo RF-023, RF-025, RF-026, RF-027, RDD-005 y RDD-006.

La recomendación operativa es secuencial: **primero se corrigen las reglas y se completa el dato faltante; después se migra**. Cargar ahora los `.xls` con los ocho parches de la sección\nobreakspace\ref{sec-concesiones} produciría una base que parece completa pero que perdió la especie, la identidad del productor y la relación con el lote. Eso es peor que una carga incompleta: es una carga que no se puede auditar.

# Anexo A. Matriz completa de pruebas {#sec-anexo-pruebas .unnumbered}

| ID | Prueba | Esperado | Obtenido | Veredicto |
|---|---|---|---|---|
| T-01 | Nombre de ruta duplicado | `23505` | `23505` | OK (confirma límite) |
| T-02 | Predio sin área | `23502` | `23502` | OK (confirma límite) |
| T-03 | Lote `NO APLICA` | `22P02` | `22P02` | OK (confirma límite) |
| T-04 | Persona sin cédula | `23502` | `23502` | OK (confirma límite) |
| T-05 | Visita sin predio | `23502` | `23502` | OK (confirma límite) |
| T-06 | Lectura sin usuario | `23502` | `23502` | OK (confirma límite) |
| T-07 | Código de trampa `1` | `23514` | `23514` | OK (confirma límite) |
| T-07b | Código ICA repetido | `23505` | `23505` | OK |
| T-08 | Jackson con número par | `23000` | `23000` | OK |
| T-09 | Coordenada fuera de rango | `23000` | `23000` | OK |
| T-10 | Coordenada fuera de rango con `legado` | Rechazo | Aceptada | **Brecha** |
| T-11 | Código de ruta incoherente | Rechazo | Aceptado | **Brecha** |
| T-12 | `durazno` y `DURAZNO` | Un valor | Dos valores | **Brecha** |
| T-13 | Periodo sin lote | Rechazo | `23000` | OK (confirma límite) |
| T-14 | Concepto sin lote | Rechazo | `23000` | OK (confirma límite) |
| T-15 | Columnas de especie/sexo | 6 | 0 | **Brecha** |
| T-16 | Tablas de laboratorio | ≥1 | 0 | **Brecha** |
| T-17 | Atrayente 2 = Plug | Plug | Proteico | **Brecha** |
| T-18 | Paridad de 297 trampas con número | 0 violaciones | 0 | OK |
| T-19 | Códigos de ruta de 9 dígitos | 0 inválidos | 0 | OK |
| T-20 | Coordenadas en el rango | Dentro | Dentro | OK |
| T-21 | Periodo con lote ficticio | Se crea | Se crea | OK (workaround) |
| T-22 | MTD manual | 0,55 / 0,5143 / 0,4429 | Coincide | OK |
| T-23 | Cruce UBI–CAP | Comparten ruta/trampa | 0 | **Brecha de dato** |
| T-24 | Fecha CAP vs. año/semana | Coherente | 2015 vs. 2019 | **Brecha de dato** |
| T-25 | Predios con varios dueños | 0 | 11 | **Brecha** |
| T-26 | Lotes reales | ≥1 | 0 | **Brecha** |
| T-27 | Catálogo de cultivo | 1 | 5 | **Brecha** |
| T-28 | Fechas de 2012 | 0 | 3 | **Brecha de dato** |
| T-29 | Trampa sin número | 0 | 1 | **Brecha de dato** |
| T-30 | Hoja 605 vs. municipio | SILOS | CHITAGA | **Brecha de dato** |
| T-31 | Lecturas CAP en el MTD | 20 | 0 | **Brecha** |
| T-32 | MTD total 77/(20×7) | 0,550000 | 0,550000 | OK |
| T-33 | MTD por especie | Por especie | Solo total | **Brecha** |
| T-34 | Código de ruta 606 | 545200606 | 545200606 | OK |
| T-35 | Predio en CAP | 20/20 | 0/20 | **Brecha de dato** |
| T-36 | Colector en CAP | 20/20 | 0/20 | **Brecha de dato** |
| T-37 | Hembras grávidas 0 vs. vacío | Distinguir | 2 vacías | **Brecha** |
| T-38 | Cero capturas vs. no leída | 17 | 17 | OK |
| T-39 | No Tephritidae en el MTD | Excluir | 5 incluidas | **Brecha** |

**Resumen:** 40 comprobaciones; 23 coincidieron con lo previsto (incluidas varias que confirman límites del modelo) y 17 evidenciaron una brecha de modelo o de dato.

# Anexo B. Diccionario de campos de los .xls {#sec-anexo-campos .unnumbered}

## MF_UBI {#sec-anexo-ubi .unnumbered}

| Columna | Tipo observado | Ejemplo | Problema |
|---|---|---|---|
| `Codigo Vigilancia` | Numérico | 2 | Catálogo sin valores |
| `Region` | Numérico | 1 | Catálogo sin código |
| `Departamento` | Numérico | 54 | Catálogo DANE vacío |
| `Municipio` | Texto | CACOTA | Catálogo DANE vacío |
| `Registro de la ruta` | Numérico | 602 | Debe ir a `ruta_codigo` corto |
| `Código Ruta` | Numérico | 541250602 | Derivado; no guardar en `ruta_codigo` |
| `Lote` | Texto | NO APLICA | No hay lote |
| `Tipo Trampa` | Numérico | 1 | 1=Jackson, 2=McPhail |
| `Numero Trampa` | Numérico | 1 | Una fila vacía |
| `Atrayente` | Numérico | 2 | 2=Plug, 1=Proteico |
| `Fecha Instalacion` | Serial Excel | 41739 | Solo fecha |
| `Longitud` | Decimal | −72,63342 | WGS84, 5 decimales |
| `Latitud` | Decimal | 7,24964 | WGS84, 5 decimales |
| `Altitud` | Decimal | 2096 | Metros |
| `Ubicación` | Texto | VEREDA ESTACION PULIDO | Referencia, no geometría |
| `Nombre Predio` | Texto | ESTACION PULIDO | Una fila vacía |
| `Propietario` | Texto | (omitido) | Sin documento; copropiedad |
| `Codigo Localizacion` | Numérico | 1 | Catálogo vacío |
| `Arbol` | Texto | DURAZNO | 5 variantes, incluida CAFÉ |
| `Nombre_Ruta` | Texto | CONGLOMERADO FRUTICOLA | Duplicado en 4 rutas |

## MF_CAP {#sec-anexo-cap .unnumbered}

| Columna | Tipo observado | Ejemplo | Problema |
|---|---|---|---|
| `Codigo Vigilancia` | Numérico | 2 | Catálogo sin valores |
| `Region` | Numérico | 1 | Catálogo sin código |
| `Departamento` | Numérico | 54 | Catálogo DANE vacío |
| `Municipio` | Texto | PAMPLONITA | Catálogo DANE vacío |
| `Registro de la ruta` | Numérico | 606 | En la hoja `10-02-15`; en `Predio` la etiqueta es otra |
| `Código Ruta` | Numérico | 545200606 | Derivado |
| `Lote` | Texto | NO APLICA | No hay lote |
| `Tipo Trampa` | Numérico | 2 | 1=Jackson, 2=McPhail |
| `Numero Trampa` | Numérico | 26 | 20 trampas |
| `código de la especie` | Texto | 1 Ceratitis capitata | Código + nombre |
| `Fecha` | Serial Excel | 42045 | Solo fecha |
| `código del recolector` | Texto | (vacío) | 0/20 |
| `Machos` | Numérico | 56 | Sin destino en el modelo |
| `Hembras` | Numérico | 0 | Sin destino |
| `Hembras gravidas` | Numérico/vacío | 0 o vacío | No sumar al total |
| `Estado trampa` | Numérico | 1 | Catálogo vacío |
| `Fenologia` | Numérico | 3 | Sin destino en la lectura |

# Anexo C. Inventario del paquete BD {#sec-anexo-inventario .unnumbered}

| Ruta | Contenido | Uso |
|---|---|---|
| `BD/sigat_db_v6/sql/00_instalar_todo.sql` | Instalación completa | Punto de entrada |
| `BD/sigat_db_v6/sql/01_esquema_completo.sql` | 74 tablas, dominios, restricciones, índices y disparadores | Modelo |
| `BD/sigat_db_v6/sql/02_catalogos_basicos.sql` | Catálogos mínimos | Semilla |
| `BD/sigat_db_v6/sql/03_vistas.sql` | 21 vistas | Consulta |
| `BD/sigat_db_v6/sql/04_funciones.sql` | 22 funciones y 13 disparadores | Reglas |
| `BD/sigat_db_v6/sql/05_datos_demo.sql` | Demo | Pruebas |
| `BD/sigat_db_v6/sql/06_validacion.sql` | 8 consultas de validación | Control |
| `BD/sigat_db_v6/sql/07_pruebas_restricciones.sql` | 31 pruebas | Control |
| `BD/sigat_db_v6/pruebas_escritorio/` | 49 escenarios y ejecutable | Pruebas |
| `BD/sigat_db_v6/migracion/` | M1–M5 y reversión | Migración v5→v6 |
| `BD/sigat_db_v6/docs/` | Diccionario, relaciones, índices, prefijos y pendientes | Documentación |
| `BD/sigat_db_v6/diagramas/` | DBML, DOT, SVG y PNG | Modelo visual |
| `BD/sigat_db_v6/herramientas/` | Generadores y fuentes | Mantenimiento |
| `BD/corregido.pdf` | Diagrama ER de dos páginas | Referencia visual |
| `BD/SIGAT v6 · Explicación de cada tabla.pdf` | Explicación narrativa de las 74 tablas | Referencia |
| `BD/sql.sql` | Script de pgAdmin con el esquema v5 | Referencia histórica |

# Anexo D. Reproducción {#sec-anexo-repro .unnumbered}

Los pasos mínimos para repetir la línea base y las pruebas de datos reales son:

```bash
# 1. Base temporal (no usar producción)
initdb -D /tmp/sigat_pg -U postgres --no-locale --encoding=UTF8
pg_ctl -D /tmp/sigat_pg -o "-k /tmp/sigat_sock -p 55432" -l /tmp/sigat_pg.log start
createdb -h /tmp/sigat_sock -p 55432 -U postgres sigat_demo

# 2. Instalar esquema y demo
cd BD/sigat_db_v6/sql
psql -h /tmp/sigat_sock -p 55432 -U postgres -d sigat_demo \
  -v ON_ERROR_STOP=1 -v demo=SI -f 00_instalar_todo.sql

# 3. Línea base
psql -h /tmp/sigat_sock -p 55432 -U postgres -d sigat_demo \
  -f pruebas_escritorio/PE_ejecutable.sql

# 4. Restricciones (base sin demo)
createdb -h /tmp/sigat_sock -p 55432 -U postgres sigat_schema
psql -h /tmp/sigat_sock -p 55432 -U postgres -d sigat_schema \
  -v ON_ERROR_STOP=1 -f 00_instalar_todo.sql
psql -h /tmp/sigat_sock -p 55432 -U postgres -d sigat_schema \
  -f 07_pruebas_restricciones.sql
```

La extracción de los `.xls` se hizo con `xlrd` 2.0.2 y las fechas se convirtieron con `xlrd.xldate_as_datetime`. El script de extracción y el de pruebas se mantuvieron fuera del paquete para no alterar los archivos originales; los resultados están en este informe.

# Anexo E. Glosario {#sec-anexo-glosario .unnumbered}

| Término | Definición |
|---|---|
| **MTD** | Moscas por trampa por día: `M / (T × D)` |
| **Divipola** | Código DANE de departamento (2) + municipio (3) |
| **Código ICA de ruta** | Divipola (5) + registro de ruta (4), por ejemplo `541250602` |
| **Código ICA de trampa** | Divipola (5) + registro de ruta (4) + número de trampa, por ejemplo `54125-0602-1` |
| **Jackson / McPhail** | Tipos de trampa; Jackson impar, McPhail par (RN-005) |
| **Plug / Proteico hidrolizado** | Atrayentes; el archivo usa 2 para Plug y 1 para Proteico |
| **Linaje** | Origen del dato: `inspeccion_oficial` o `autorreporte` (RN-014) |
| **Append-only** | Solo se insertan versiones; no se actualiza ni se borra (ADR-03) |
| **Bitemporal** | Se distinguen tiempo de observación, captura y sincronización |
| **Staging** | Zona intermedia donde se cargan y validan los datos crudos antes de publicarlos |
| **UQQ** | Pregunta abierta del levantamiento de requerimientos |
| **RDD** | Requisito de datos |
| **RN** | Regla de negocio |
| **RF** | Requisito funcional |
| **RNF** | Requisito no funcional |
