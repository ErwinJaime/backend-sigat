---
title: "Consumo de datos de la vista del productor"
subtitle: "Prototipos móvil y web frente al modelo SIGAT v6"
author: "Equipo de Arquitectura de Software"
date: "26 de octubre de 2026"
lang: es-CO
---

# Resumen ejecutivo {#sec-resumen}

> **Alcance.** Se analiza la **vista del productor** completa: los veinte marcos web de la página «04 — Cliente web» (`PW01` a `PW07`) y los dieciséis marcos móviles de la página «03 — Cliente móvil · Productor y Agrónomo» (`P01-P` a `P07d-P`). Quedan fuera las pantallas del técnico (`WT`, `Mxx-T`), las del administrador (`WADM`), las del agrónomo (`MAxx`) y el inicio de sesión común.

El productor es **consumidor de datos ya calculados y autor de dos registros**. De las 74 tablas del esquema SIGAT v6 usa 41; escribe en dos (`aplicacion_fitosanitaria` y `cosecha`) y responde una tercera (`planificacion`). No calcula MTD, no emite conceptos y no registra visitas ni lecturas. Los dos canales —móvil y web— consumen **los mismos datos por las mismas vistas**; lo que cambia es la forma de la pantalla y, en el móvil, la existencia de una cola local que la base solo ve cuando el registro llega. **La base de datos actualizada (BD/sigat_db_v6) contiene 28 vistas nuevas/actualizadas, catálogos sembrados (`escenario_trampeo`, `permiso`) y 10 índices/cláusulas pendientes para performance total y bloqueantes `§8.1`.**

**La estructura de datos cubre el prototipo: no falta ninguna tabla.** Lo que falta es exposición y una decisión de sincronización:

1. **Catálogos sembrados** (en `01_esquema_completo.sql`): `escenario_trampeo`, `permiso`/`rol_permiso`. Listos para que las pantallas pinten etiquetas de situación y RBAC.
2. **Diez consultas de pantalla** que hoy exigirían unir cinco o seis tablas en el cliente y que deben resolverse en el servidor (historial con responsable, cosecha vigente por lote, última aplicación por lote, avisos, estado de sincronización, entre otras).
3. **Siete reglas de negocio** que los prototipos insinúan pero el esquema no restringe todavía (una cosecha abierta por lote, vigencia de hallazgos, contexto de lote en el móvil, coherencia entre canales).

| Tipo de hallazgo | Cantidad | Efecto si no se corrige |
|---|---|---|
| Bloqueantes (catálogo o permiso ausente) | 3 | La pantalla no puede pintar la columna o no puede decidir qué ocultar |
| Vistas o campos faltantes | 10 | El cliente une tablas y duplica reglas; se rompe ADR-13 |
| Correcciones de modelo o de regla | 7 | Datos inconsistentes o contradictorios entre pantallas y canales |
| Diferencias de vocabulario | 7 | Etiquetas de la interfaz que no existen en la base |

**La decisión de fondo:** el servidor entrega la pantalla resuelta. Cada pantalla del productor —móvil o web— debería apoyarse en una vista o en un recurso de la API, nunca en una consulta compuesta construida por el cliente. El móvil agrega una condición: la **cola local es la fuente de verdad en campo**, y la base solo registra lo confirmado.

# Alcance y fuentes {#sec-alcance}

## Fuentes utilizadas {#sec-fuentes}

| Fuente | Qué se tomó |
|---|---|
| `Página web.penpot` | Penpot 2.18.3, revisión 4661, 8 páginas. Páginas 03 (móvil) y 04 (web), solo marcos del productor |
| `BD/sigat_db_v6/sql/01_esquema_completo.sql` | 74 tablas, dominios, 182 reglas `CHECK`, 299 índices |
| `BD/sigat_db_v6/sql/03_vistas.sql` | 21 vistas, en particular `v_*_app`, `v_resumen_lote` y `v_planificacion` |
| `BD/sigat_db_v6/sql/04_funciones.sql` | `fn_lotes_visibles`, `fn_etapa_derivada`, `fn_planificacion_valida` |
| `BD/sigat_db_v6/docs/03_diccionario_datos.md` | Significado y dominio de cada columna |
| `Arquitectura_Tecnologica_ICA_Durazno.md` | ADR-13 (MTD en el servidor), ADR-16 (contrato), ADR-18 (web) |
| `Levantamiento_Requerimientos_ICA_Durazno.md` | RN-002 (escenarios de trampeo), RN-010 (idempotencia), RN-017 (unidades) |

## Recorte aplicado {#sec-recorte}

El archivo tiene ocho páginas. La vista del productor se reparte en dos de ellas y se reconoce por el prefijo `PW` (*productor web*) y `P0x-P` (*productor móvil*).

| Página del archivo | Contenido | ¿Se usó? |
|---|---|---|
| 01 — Design System | Fundamentos visuales | No |
| 02 — Cliente móvil · Técnico | WT01 a WT10, M01-T a M11-T | No |
| 03 — Cliente móvil · Productor y Agrónomo | P01-P a P07d-P y MA01 a MA07 | **Solo los marcos `P`** |
| 04 — Cliente web | PW01 a PW07, WT y WADM | **Solo los marcos `PW`** |
| 05 — Flujos y prototipo | Conexiones entre pantallas | No |
| 06 — Componentes | Catálogo de componentes | No |
| 07 — Estados del sistema | Vacíos, error, carga | No |
| 08 — Arquitectura y demostración | Láminas de presentación | No |

# Inventario de pantallas {#sec-inventario}

## Cliente web (20 marcos) {#sec-inventario-web}

| Código | Pantalla | Tipo | Propósito | Datos que introduce |
|---|---|---|---|---|
| PW01 | Inicio productor | Página | Resumen del predio y de los lotes | Ninguno |
| PW02 | Mi cultivo | Página | Tarjetas por lote | Ninguno |
| PW02b | Estado del lote | Página | Detalle fitosanitario y línea de tiempo | Ninguno |
| PW03 | Aplicaciones | Página | Última aplicación por lote y listado | Ninguno |
| PW03a | Registrar aplicación | Página | Formulario de autorreporte | Lote, fecha, producto, dosis, área, responsable |
| PW03b | Aplicación registrada | Ventana | Confirmación | Ninguno |
| PW03c | Registrar aplicación · datos por corregir | Página | Estado de validación | Ninguno |
| PW04 | Cosecha | Página | Esperada y real por lote | Ninguno |
| PW04a | Registrar cosecha | Página | Formulario de autorreporte | Lote, fecha y volumen esperado, fecha y volumen real |
| PW04b | Cosecha registrada | Ventana | Confirmación | Ninguno |
| PW05 | Historial | Página | Actividad unificada por lote y periodo | Filtros de lote y periodo |
| PW06 | Mi perfil | Página | Cuenta, cultivo y preferencias | Ninguno |
| PW06b | Notificaciones | Panel | Bandeja de avisos | Marcar como leída |
| PW07 | Planeaciones | Página | Asignaciones del agrónomo | Filtro por estado |
| PW07a | Planeación · pendiente | Página | Detalle y decisión | Aceptar o rechazar |
| PW07b | Documento de instrucciones | Modal | Vista previa del adjunto | Ninguno |
| PW07c | Rechazar planeación | Modal | Motivo obligatorio | Motivo del rechazo |
| PW07d | Planeación · aceptada | Página | Estado resuelto | Ninguno |
| PW07e | Planeación · rechazada | Página | Motivo y datos | Ninguno |
| PW07f | Planeaciones · rechazo enviado | Página | Confirmación en la lista | Ninguno |

## Cliente móvil (16 marcos, 12 pantallas) {#sec-inventario-movil}

| Código | Pantalla | Tipo | Propósito | Datos que introduce |
|---|---|---|---|---|
| P01-P (a) | Inicio · mi cultivo | Pantalla | Tarjeta del lote y accesos directos | Ninguno |
| P01-P (b) | Inicio · asignaciones | Pantalla | Lista de planificaciones por estado | Filtro por estado |
| P01-P (c) | Inicio · detalle de asignación | Panel | Datos y decisión | Aceptar o rechazar |
| P01-P (d) | Inicio · documento | Visor | Vista previa del adjunto | Ninguno |
| P01-P (e) | Inicio · rechazar asignación | Modal | Motivo obligatorio | Motivo del rechazo |
| P02-P | Estado del lote | Pantalla | Resumen y actividad reciente | Ninguno |
| P03-P | Registrar aplicación | Pantalla | Formulario de autorreporte | Fecha, producto, dosis, área, responsable |
| P03-P | Aplicación registrada | Estado | Confirmación local | Ninguno |
| P04-P | Registrar cosecha | Pantalla | Formulario de autorreporte | Fecha esperada, fecha real, volumen |
| P04b-P | Cosecha registrada | Pantalla | Confirmación local | Ninguno |
| P05-P | Historial | Pantalla | Actividad unificada | Filtro por tipo |
| P06-P | Perfil y ajustes | Pantalla | Cuenta, lote, conteos y preferencias | Ninguno |
| P07-P | Sincronización · pendientes | Pantalla | Cola de envío | Sincronizar ahora |
| P07b-P | Sincronización · en curso | Estado | Progreso por registro | Ninguno |
| P07c-P | Sincronización · completada | Estado | Confirmación del servidor | Ninguno |
| P07d-P | Sincronización · error | Estado | Reintento | Reintentar |

**Observación de navegación.** La web organiza al productor por **predio** —«Finca El Mirador · 4 lotes»— y el móvil por **lote** —«Lote A — Durazno»—. La barra inferior del móvil tiene tres entradas (Inicio, Mi cultivo, Historial); el resto se alcanza por acciones dentro de la tarjeta. En la web el menú lateral tiene siete entradas y la de «Estado» exige un lote que el menú no aporta: se llega desde la tarjeta, no desde el menú. Ambos patrones son válidos, pero conviene que el móvil declare explícitamente cuál es el lote en contexto cuando el productor tiene varios.

# Navegación y alcance del rol {#sec-rol}

## Estructura de las interfaces {#sec-estructura-ui}

| Zona | Web | Móvil | Origen del dato |
|---|---|---|---|
| Cabecera | «SIGAT», «Vigilancia de Durazno» | Barra de estado y título de pantalla | Constantes de la aplicación |
| Frescura del dato | «Datos al 08 oct · 14:20» | «Última sincronización: 05 oct, 9:15 a. m.» | `meta.generado_en` en web; `dispositivo.disp_ultima_sync` en móvil |
| Aviso de demostración | «Prototipo · datos ficticios» | «Datos de ejemplo» | Rótulo, no es dato |
| Identidad | Nombre, rol e iniciales | Nombre, rol e iniciales | `persona` + `rol` |
| Avisos | Campana con contador | Preferencia en el perfil | `v_notificacion_resumen` |
| Navegación | Menú lateral, 7 entradas | Barra inferior, 3 entradas | Constantes |

La frescura del dato se resuelve de forma distinta en cada canal y es correcto que así sea: la web consulta en línea y puede mostrar la hora del servidor; el móvil trabaja sin red y solo puede mostrar **cuándo sincronizó por última vez**. Confundirlas sería un error: en el móvil, «Datos al…» debe ser siempre la última sincronización confirmada, nunca la hora del teléfono.

## Qué puede hacer el productor {#sec-permisos}

| Acción en los prototipos | ¿Permitida? | Respaldo en el modelo |
|---|---|---|
| Ver predios y lotes propios | Sí | `v_acceso_predio` (origen `propietario`) y `fn_lotes_visibles` |
| Ver visitas y lecturas del técnico | Solo lectura | `visita`, `lectura_trampa`, `v_lectura_vigente` |
| Ver MTD y concepto | Solo lectura | `indice_mtd`, `concepto_aptitud`, `v_mtd_vigente` |
| Registrar aplicación | Sí | `aplicacion_fitosanitaria` con `apli_linaje = 'autorreporte'` |
| Registrar o completar cosecha | Sí | `cosecha` con `cose_linaje = 'autorreporte'` |
| Aceptar o rechazar planeación | Sí | `fn_planificacion_valida`: pendiente → aceptada/rechazada |
| Crear visita o lectura | **No** | No hay camino de escritura para el rol |
| Cambiar el concepto | **No** | Solo lo emite el servidor (ADR-13) |
| Sincronizar autorreportes | Sí | `operacion_sync` + `recepcion_sync` (RN-010) |

Los prototipos refuerzan esa frontera con leyendas equivalentes en los dos canales: «Solo el técnico del ICA registra las visitas y las lecturas de trampas; tú registras tus aplicaciones y tu cosecha» (web) y «Solo se sincronizan tus autorreportes» (móvil). Ambas coinciden con `d_linaje`.

## Alcance documental de la web {#sec-contradiccion}

`Estructura_Repositorios_ICA_Durazno.md`, supuesto 1, afirma que la web «es un backoffice interno del ICA… no es un portal para productores ni un sitio público». Los prototipos incluyen un **portal de productor** con siete pantallas web propias y sesión autenticada, además del cliente móvil del mismo rol.

| Opción | Consecuencia |
|---|---|
| **A. Ampliar el alcance de la web** | Se actualiza el supuesto 1 y ADR-18: la web atiende a los cuatro roles. Es lo que el prototipo ya dibuja |
| B. Dejar el productor solo en el móvil | Se descartan PW01 a PW07; el productor sin teléfono queda sin canal |
| C. Sitio separado | Un cuarto repositorio; contradice ADR-18 y duplica el consumo del contrato |

Se recomienda **A**: el prototipo ya está construido, el backend no cambia y el coste es documental. La consecuencia técnica es que la web necesita **guarda de rutas por rol** y que la API debe aplicar `fn_lotes_visibles` también en los recursos del productor, igual que ya lo hace para el móvil.

# Vista web: consumo por pantalla {#sec-pantallas-web}

Convenciones de las tablas: **Origen** indica la tabla o vista; **Derivado** significa que el valor se calcula en el servidor y no se almacena; **Falta** señala que no hay origen en el modelo actual.

## PW01 — Inicio productor {#sec-pw01}

Encabezado «Finca El Mirador · resumen de mi cultivo» y tres tarjetas de contexto; debajo, la tabla «Mis lotes».

| Elemento de interfaz | Origen | Observación |
|---|---|---|
| «Finca El Mirador» | `predio.pred_nombre` | Vía `v_lote_app` o `v_acceso_predio` |
| «tus 4 lotes» | `count(lote)` | Derivado; `lote.lote_fecha_baja IS NULL` |
| Última visita del técnico · fecha | `max(visita.visi_t_fin_obs)` | `v_resumen_lote.ultima_visita` |
| «Se revisaron las 4 trampas del Lote 2 · Centro» | `visita_lote` + `count(lectura_trampa)` + `lote.lote_descripcion` | **Falta** el par leídas/vigentes por visita |
| Última aplicación · «Hace 2 días» | `max(aplicacion_fitosanitaria.apli_t_observacion)` | `v_resumen_lote.ultima_aplicacion` |
| «06 oct 2026 · Lote 2 · Centro» | `apli_t_observacion` + `lote` | Falta el lote en la vista |
| Próxima cosecha · fecha y volumen | `cosecha.cose_fecha_esperada`, `cose_volumen_esperado` | Falta vista de cosecha vigente |
| Columna «Trampas revisadas» (4 de 4) | leídas / `count(ubicacion_trampa)` vigentes | **Falta** |
| Columna «Moscas por trampa al día» (0,36) | `indice_mtd.indi_valor` | Vía `v_mtd_vigente`; nunca se calcula en el cliente |
| Columna «Situación según el ICA» | `escenario_trampeo.esce_descripcion` vía `indice_mtd.esce_id` | **Bloqueante**: el catálogo está vacío |
| Columna «Última aplicación» | `max(apli_t_observacion)` por lote | `v_resumen_lote` |
| Leyenda Supresión / Erradicación | RN-002 | Coherente con los valores del prototipo (0,36 → supresión; 0,07 → erradicación) |
| «El concepto para exportar todavía no se emite» | `programa_inspeccion.prog_umbral_exportacion_mtd IS NULL` | Correcto: es UQQ-004, no un defecto |
| Bloque Planeaciones | `planificacion` + `usuario` + `persona` | `v_planificacion` |

**Verificación de los valores del prototipo.** Con MTD 0,36 la etiqueta es «Supresión»; con 0,07, «Erradicación»; con 0,58, «Supresión»; con cero lecturas, «Sin revisar». Eso corresponde a RN-002: supresión entre 1 y 0,1; erradicación entre 0,1 y 0. La interfaz es consistente; **el catálogo que la alimenta no está cargado**.

## PW02 — Mi cultivo {#sec-pw02}

Cuatro tarjetas, una por lote, con el estado fitosanitario y el último movimiento de cada una.

| Elemento | Origen | Observación |
|---|---|---|
| «Finca El Mirador · durazno · 4 lotes» | `predio.pred_nombre`, `especie_cultivo.espc_descripcion`, `count(lote)` | `v_lote_app` ya lo entrega |
| «Lote 2 · Centro» | `lote.lote_descripcion` | |
| «Trampas del ICA: ICA-001 a ICA-004» | `trampa.tram_codigo` | `v_trampa_lote_vigente.tram_codigo` |
| «Última visita · 08 oct 2026 · 4 de 4 trampas» | `visita` + `lectura_trampa` | **Falta** el conteo por visita |
| «Última aplicación · 06 oct 2026 · hace 2 días» | `aplicacion_fitosanitaria` | |
| «Cosecha esperada · 15 nov 2026 · 850 kg» | `cosecha` | **Falta** vista de cosecha vigente |
| Insignia «Supresión» / «Erradicación» / «Sin revisar» | `escenario_trampeo` | Bloqueante (catálogo) |
| «Sin visita en el periodo» | `visita` inexistente en `periodo_trampeo` | Derivado |

## PW02b — Estado del lote {#sec-pw02b}

Es la pantalla con más densidad de datos y la que mejor se apoya en las vistas existentes.

| Elemento | Origen | Observación |
|---|---|---|
| «Lote 2 · Centro · Finca El Mirador» | `lote` + `predio` | `v_lote_app` |
| «Situación según el ICA: Supresión» + descripción | `escenario_trampeo` | Bloqueante |
| «0,36» | `indice_mtd.indi_valor` | |
| «Promedio del periodo 02 – 08 oct 2026 en 4 trampas» | `periodo_trampeo.peri_inicio/fin`, `indice_mtd.indi_trampas` | `v_mtd_serie_lote` |
| «Concepto para exportar: Aún no se emite» | `concepto_aptitud.conc_resultado = 'no_emitido'` | `v_concepto_vigente` |
| «Falta definir el umbral oficial» | `prog_umbral_exportacion_mtd IS NULL` | Mensaje correcto (UQQ-004) |
| «Etapa del cultivo: Fructificación» | `fn_etapa_derivada(lote, fecha)` | Usa `fenologia_regla` y `lote.lote_fecha_plantacion`; **no** `etapa_declarada` |
| «Calculada por el sistema con la fecha de siembra» | Coherente con `fn_etapa_derivada` | |
| «Última aplicación · 06 oct 2026 · registrada por ti» | `aplicacion_fitosanitaria` | |
| «Cosecha: Esperada 15 nov 2026 · 850 kg / Real: sin registrar» | `cosecha` | `cosecha_real_completa` permite real nulo |
| «Hallazgos fitosanitarios vigentes: Ninguno» | `hallazgo` + `plaga_enfermedad` + `severidad` | **Falta** definición de «vigente» |
| Línea de tiempo | `v_actividad_lote` | Requiere el detalle que hoy no trae |

**Corrección de vocabulario.** La pantalla dice «Moscas por trampa al día · Promedio del periodo». El MTD es un **índice** (moscas ÷ trampas × días), no un promedio de lecturas. Conviene rotularlo «Índice MTD del periodo» para no sugerir un cálculo distinto del que hace `indice_mtd.indi_valor`.

## PW03 — Aplicaciones (con PW03a, PW03b y PW03c) {#sec-pw03}

| Elemento | Origen | Observación |
|---|---|---|
| Tabla «Última aplicación por lote» | `lote` LEFT JOIN `aplicacion_fitosanitaria` | **Falta** vista: incluye lotes sin registro |
| «Días desde la aplicación» | `current_date - apli_t_observacion` | Derivado; debe usar `pred_zona_horaria` |
| «Producto» | `producto_fitosanitario.prof_nombre` o `apli_producto_texto` | El modelo admite las dos formas |
| Listado «Mis aplicaciones registradas» | `aplicacion_fitosanitaria` | |
| «Dosis: 2 ml por litro de agua» | `apli_dosis` + `unidad_medida.unid_simbolo` (`mL/L`) | |
| «Área tratada: 1,2 ha» | `apli_area_tratada` + `unidad_medida` (`ha`) | |
| «Responsable: María Rodríguez» | `pers_cc_responsable` → `persona`, o `apli_responsable_nombre` | |
| Insignia «Autorreporte» | `apli_linaje = 'autorreporte'` | |
| Validación «La dosis debe ser un número mayor que cero» | `aplicacion_fitosanitaria_dosis_positiva` | El servidor ya la aplica |
| Validación «Escribe el área solo con números» | `aplicacion_fitosanitaria_area_positiva` | El servidor ya la aplica |
| «Todos los campos son obligatorios» | Más estricto que el `CHECK` | `prof_id` **o** `apli_producto_texto`; ver §9.4 |

El formulario de PW03a envía seis datos y el modelo los admite todos. Los dos campos numéricos llevan la unidad fija al lado («ml por litro de agua», «hectáreas»): la interfaz **no** debe enviar el texto de la unidad, sino el `unid_id` del catálogo, para que RN-017 se cumpla sin cadenas mágicas.

## PW04 — Cosecha (con PW04a y PW04b) {#sec-pw04}

| Elemento | Origen | Observación |
|---|---|---|
| Tabla «Cosecha por lote» | `lote` LEFT JOIN `cosecha` | **Falta** vista de cosecha vigente |
| «15 nov 2026 · 850 kg» | `cose_fecha_esperada`, `cose_volumen_esperado`, `cose_volumen_uni_id` | |
| «Aún sin cosechar» | `cose_fecha_real IS NULL` | |
| «Registrar cosecha real» | Actualización versionada | `cose_registro_id` + `cose_version` |
| Formulario PW04a | `cose_fecha_esperada`, `cose_volumen_esperado`, `cose_fecha_real`, `cose_volumen_real` | |
| «Puedes dejarla en blanco por ahora» | `cosecha_real_completa` exige ambos nulos o ambos presentes | Correcto |
| «La cosecha esperada se registró el 01 oct 2026» | `cose_t_observacion` de la versión 1 | |

El prototipo acierta al modelar **un solo registro con lo esperado y lo real**. La tabla `cosecha` ya tiene esa forma y la regla `cosecha_real_completa` impide dejar media cosecha real. Lo que falta es la garantía de que exista **una sola** cosecha abierta por lote.

## PW05 — Historial {#sec-pw05}

| Elemento | Origen | Observación |
|---|---|---|
| Filtro «Lote» | `lote` del productor | |
| Filtro «Periodo · Octubre 2026» | `periodo_trampeo` o rango de fechas | El prototipo usa mes calendario |
| Pestañas «Todo / Visitas del ICA / Aplicaciones / Cosecha» | `v_actividad_lote.tipo` | Tipos `vigilancia`, `aplicacion`, `cosecha` |
| Columna «Fecha» | `t_observacion` | |
| Columna «Lote» | `lote.lote_descripcion` | |
| Columna «Qué pasó» | Texto compuesto por tipo | **Falta** `detalle` en la vista |
| Columna «Quién lo registró» | `usuario` → `persona`, y rol | **Falta** el nombre en la vista |
| Columna «Tipo» | `d_linaje` del registro | `inspeccion_oficial` → «Inspección oficial»; `autorreporte` → «Autorreporte» |
| «4 trampas revisadas» / «2 de 4 trampas revisadas» | `lectura_trampa` de la visita | **Falta** |
| Paginación | — | `page`/`size` como parámetros de la API |

`v_actividad_lote` devuelve `lote_id`, `tipo`, `registro_id`, `t_observacion` y `usua_id`. Es suficiente para ordenar y filtrar, pero **no** para pintar tres de las cinco columnas: el cliente tendría que consultar por separado visitas, aplicaciones y cosechas y unir en memoria. Eso rompe el criterio de que la pantalla llega resuelta.

## PW06 — Mi perfil (con PW06b) {#sec-pw06}

| Elemento | Origen | Observación |
|---|---|---|
| Nombre y apellidos | `persona.pers_nombre`, `pers_apellido` | |
| Iniciales «MR» | Derivado | |
| «Productora · Finca El Mirador · durazno» | `rol`, `predio`, `especie_cultivo` | |
| «Activo» | `estado_registro.esta_descripcion` o `usuario.esta_id` | |
| «Móvil y web» | `operacion_sync` + `usuario.usua_ultimo_acceso` | **Falta**: no hay columna de canal |
| «Nombre completo» | `persona` | |
| «Rol en SIGAT: Productor» | `rol.rol_descripcion` | |
| «Correo electrónico» | `persona.pers_correo` | |
| «Mis aplicaciones registradas: 1 registro» | `count(aplicacion_fitosanitaria)` | Derivado |
| «Mis cosechas: 1 registro» | `count(cosecha)` | Derivado |
| «Predio: Finca El Mirador · 4 lotes» | `predio` + `count(lote)` | |
| «Vigilancia: activa» | `periodo_trampeo.peri_estado = 'abierto'` | `v_lote_app.vigilancia_activa` |
| «Notificaciones: Activadas» | `perfil_usuario.perf_notificaciones_activas` | |
| «Sincronización: Todo actualizado» | `operacion_sync` sin pendientes | Derivado |
| Panel PW06b «No tienes notificaciones nuevas» | `notificacion` con `noti_leida_en IS NULL` | `v_notificacion_resumen` solo da el conteo |

## PW07 — Planeaciones (con PW07a a PW07f) {#sec-pw07}

| Elemento | Origen | Observación |
|---|---|---|
| Pestañas Todas / Pendientes / Aceptadas / Rechazadas | `planificacion.plan_estado` | También existe `completada` (PW07 muestra una fila así) |
| Columna «Fecha propuesta» | `plan_fecha_inicio` | Formato largo en español |
| Columna «Actividad» | `plan_actividad` | Texto libre |
| Columna «Enviada por» | `usuario` creador → `persona` + `rol` | `v_planificacion.creador` |
| Columna «Estado» | `plan_estado` | `planificacion_estado_valido` |
| Detalle · Documento «Instrucciones_muestreo.pdf» | `archivo_adjunto.arch_nombre_original` | `v_planificacion.documento` |
| Detalle · «2.4 MB» | `archivo_adjunto.arch_tamano_bytes` | **Falta** en la vista |
| Detalle · «Ver documento» y vista previa | `arch_ref_almacenamiento` | Requiere URL firmada de la API |
| «Horario 08:00 – 16:00» | `plan_hora_desde`, `plan_hora_hasta` | |
| «Observaciones» | `plan_observaciones` | |
| «Motivo del rechazo» | `plan_motivo_rechazo` | `planificacion_rechazo_con_motivo` |
| «18 nov. 2026 · 14:32» | `plan_respondida_en` | |
| Botones Aceptar / Rechazar | `fn_planificacion_valida` | Solo el destinatario; transición pendiente → aceptada/rechazada |

**Dos faltantes de interfaz, no de modelo.** El detalle de la planeación **no muestra el lote ni el predio**, aunque `planificacion_lote` los vincula y `v_planificacion` ya devuelve `lotes` como arreglo de códigos. El productor acepta una visita sin ver a qué lote se refiere. Y el documento se ofrece sin tamaño ni tipo en la lista, aunque el dato existe.

# Vista móvil: consumo por pantalla {#sec-pantallas-movil}

El móvil repite el mismo modelo de datos que la web con tres diferencias estructurales: trabaja **por lote** y no por predio, **captura sin red** y **sincroniza después**. Por eso su análisis separa lo que se lee del servidor de lo que vive en el dispositivo.

## P01-P — Inicio, asignaciones y decisión {#sec-p01}

El marco `P01-P` agrupa cinco estados que se abren como hojas sobre la pantalla de inicio.

### Inicio: tarjeta del lote {#sec-p01-inicio}

| Elemento | Origen | Observación |
|---|---|---|
| «Hola, …» | `persona.pers_nombre` | |
| «Durazno» | `especie_cultivo.espc_descripcion` | Vía `v_lote_app` |
| «Lote de producción» | `lote.lote_descripcion` | |
| «Vigilancia activa» | `periodo_trampeo.peri_estado = 'abierto'` | `v_lote_app.vigilancia_activa` |
| «Última visita · 08 oct 2026» | `max(visita.visi_t_fin_obs)` | `v_resumen_lote.ultima_visita` |
| «Estado del cultivo · Activa» | `programa_inspeccion` vigente | Derivado |
| «Último MTD: 0,35» | `indice_mtd.indi_valor` | **Inconsistente con la web**, que muestra 0,36 |
| Planificaciones · «Nueva» | `planificacion` con `plan_estado = 'pendiente'` | `v_planificacion` |
| «Registrar aplicación» | Acción | `aplicacion_fitosanitaria` |
| «Registrar cosecha» | Acción | `cosecha` |
| «Sincronizar ahora» | Acción | Cola local → `operacion_sync` |

La anotación del prototipo «Último MTD: 0,35 (si existe un cálculo válido)» es una nota de diseño, no un dato: la pantalla debe ocultar la cifra cuando no hay `indice_mtd` para el periodo, en lugar de mostrar un cero.

### Asignaciones: lista por estado {#sec-p01-lista}

| Elemento | Origen | Observación |
|---|---|---|
| Pestañas Pendientes / Aceptadas / Rechazadas / Todas | `planificacion.plan_estado` | Mismos valores que la web |
| «Muestreo de cultivos» | `plan_actividad` | |
| «22 de Noviembre 2026» | `plan_fecha_inicio` | |
| Insignia de estado | `plan_estado` | `planificacion_estado_valido` |

### Detalle y decisión {#sec-p01-detalle}

| Elemento | Origen | Observación |
|---|---|---|
| Actividad y fecha | `plan_actividad`, `plan_fecha_inicio` | `v_planificacion` |
| «Documento de instrucciones» | `archivo_adjunto.arch_nombre_original` | `arch_clase = 'documento_instruccion'` |
| «Observaciones del agronomo» | `plan_observaciones` | |
| «Aceptar» / «Rechazar» | `fn_planificacion_valida` | Transición pendiente → aceptada/rechazada |
| «Motivo del rechazo» (obligatorio) | `plan_motivo_rechazo` | `planificacion_rechazo_con_motivo` |

El detalle móvil sí muestra el documento y las observaciones, y **tampoco muestra el lote**: comparte el faltante de la web. Es la misma decisión pendiente en los dos canales.

### Visor de documento {#sec-p01-doc}

| Elemento | Origen | Observación |
|---|---|---|
| Nombre del archivo | `archivo_adjunto.arch_nombre_original` | |
| «Vista previa» | `arch_ref_almacenamiento` | URL firmada de la API |
| «Cerrar documento» | — | — |

## P02-P — Estado del lote {#sec-p02}

| Elemento | Origen | Observación |
|---|---|---|
| «Estado de mi cultivo» | `lote` + `predio` | `v_lote_app` |
| «Cultivo: Durazno» | `especie_cultivo` | |
| «Última visita: 08 de octubre de 2026» | `visita.visi_t_fin_obs` | |
| «Lotes revisadas: 4» | `count(lectura_trampa)` | **Rótulo erróneo**: son trampas, no lotes |
| «Estado: Vigilancia activa» | `periodo_trampeo` | |
| «Última aplicación: Hace 2 días» | `max(apli_t_observacion)` | Texto de ejemplo en el prototipo |
| «Actividad reciente» | `v_actividad_lote` | Requiere F1 |

El móvil no muestra la situación del ICA ni el concepto de exportación. Es una omisión deliberada y razonable —el productor en campo necesita saber qué hacer, no el dictamen—, pero conviene que sea explícita en el diseño y no una diferencia accidental con la web.

## P03-P — Registrar aplicación {#sec-p03}

| Elemento | Origen | Observación |
|---|---|---|
| «Fecha de la aplicación» | `apli_t_observacion` | La interfaz captura solo la fecha; la hora la fija la API |
| «Producto utilizado» | `prof_id` o `apli_producto_texto` | El prototipo admite texto libre |
| «Dosis (mililitros por litro de agua)» | `apli_dosis` + `unidad_medida` `mL/L` | |
| «Área aplicada (hectáreas)» | `apli_area_tratada` + `unidad_medida` `ha` | |
| «Persona responsable» | `pers_cc_responsable` o `apli_responsable_nombre` | |
| «Guardar» | `aplicacion_fitosanitaria` + `operacion_sync` | Escritura en dos tablas |
| «Aplicación registrada correctamente» | Estado local | Aún sin confirmar por el servidor |

**El formulario móvil no incluye el lote**, a diferencia del formulario web (PW03a). `aplicacion_fitosanitaria.lote_id` es obligatorio, así que el lote debe viajar en el contexto de la pantalla y no como campo del formulario. Es una decisión de contrato, no una falta de dato: el productor móvil trabaja dentro de un lote.

## P04-P y P04b-P — Cosecha {#sec-p04}

| Elemento | Origen | Observación |
|---|---|---|
| «Fecha esperada · Fecha» | `cose_fecha_esperada` | |
| «Fecha real · Fecha» | `cose_fecha_real` | Puede quedar vacía |
| «Volumen cosechado (kilos)» | `cose_volumen_real`, `cose_volumen_esperado` | Unidad `kg` |
| «Guardar cosecha» | `cosecha` + `operacion_sync` | |
| «Tu autorreporte se ha guardado localmente» | Cola del dispositivo | No hay fila en la base todavía |
| «Pendiente de sincronizar» | Cola del dispositivo | Se resuelve con `operacion_sync` |
| «Fecha estimada / Fecha real (pendiente) / Volumen» | `cosecha` | Confirmación local |

El móvil distingue dos momentos que la web no separa: **guardado local** y **confirmado por el servidor**. Esa distinción no tiene columna en `cosecha`; se resuelve con la cola del dispositivo y con la respuesta de `operacion_sync`.

## P05-P — Historial {#sec-p05}

| Elemento | Origen | Observación |
|---|---|---|
| Pestañas Todo / Vigilancia / Aplicación / Cosecha | `v_actividad_lote.tipo` | Equivalen a las de PW05 |
| «08 OCT · Visita de vigilancia · Se revisaron las 4 trampas» | `visita` + `lectura_trampa` | **Falta** el detalle y el conteo |
| «06 OCT · Aplicación registrada · Registrada por ti» | `aplicacion_fitosanitaria` | |
| «01 OCT · Cosecha actualizada · Fecha esperada actualizada» | `cosecha` | Nueva versión del registro |

El móvil no muestra «quién lo registró» porque en su caso siempre es el propio productor o el técnico; la web sí lo necesita porque muestra varios lotes y varias visitas. Es la misma vista con distinto nivel de detalle.

## P06-P — Perfil y ajustes {#sec-p06}

| Elemento | Origen | Observación |
|---|---|---|
| Nombre e iniciales | `persona` | |
| «Productora · Lote de durazno» | `rol` + `lote` | |
| «Lote A — Durazno» | `lote.lote_descripcion` | **Un solo lote**, frente a los cuatro de la web |
| «Vigilancia fitosanitaria activa» | `periodo_trampeo` | |
| «Mis aplicaciones registradas: 3 registros» | `count(aplicacion_fitosanitaria)` | Derivado |
| «Mis cosechas: 1 registro» | `count(cosecha)` | Derivado |
| «Datos de contacto» | `persona.pers_correo` | |
| «Notificaciones: Activadas» | `perfil_usuario.perf_notificaciones_activas` | |
| «Sincronización: Todo actualizado» | `dispositivo.disp_ultima_sync` | Derivado |
| «Las inspecciones oficiales son gestionadas por el técnico del ICA» | Regla de negocio | Coincide con `d_linaje` |

## P07-P a P07d-P — Sincronización {#sec-p07}

| Elemento | Origen | Observación |
|---|---|---|
| «Conectado» | Conectividad del dispositivo | No es un dato de la base |
| «2 registros pendientes» | Cola local | No es un dato de la base |
| Tipo y fecha de cada registro | Cola local | `aplicacion_fitosanitaria` / `cosecha` |
| «Pendiente» | Cola local | |
| «Última sincronización: 05 oct, 9:15 a. m.» | `dispositivo.disp_ultima_sync` o `max(oper_t_recepcion)` | |
| «Sincronizar ahora» | `POST` de operaciones | Idempotente por `(disp_id, oper_cliente_id)` |
| «Enviando 1 de 2 registros…» | Progreso del envío | No es un dato de la base |
| «Enviada» / «Enviando…» | Estado por registro | |
| «Registros sincronizados · Confirmado» | `recepcion_sync.rece_resultado` | |
| «Sincronizado: 08 oct 2026, 14:45» | `max(rece_t)` | |
| «No se pudo sincronizar · Tus datos no se han perdido» | Error de red | La cola local persiste |
| «Reintentar sincronización» | Reintento idempotente | RN-010 |

### El ciclo offline-first {#sec-ciclo}

| Estado en pantalla | Dónde vive | Columna o tabla |
|---|---|---|
| «Guardado localmente» | SQLite del dispositivo | No existe en la base |
| «Pendiente de sincronizar» | Cola del dispositivo | No existe en la base |
| «Enviando…» | Petición HTTP en curso | No existe en la base |
| «Confirmado» | Servidor | `operacion_sync` y `recepcion_sync.rece_resultado` |
| «Última sincronización» | Servidor | `dispositivo.disp_ultima_sync` |
| «Reintentar» | Cliente | Nueva fila en `recepcion_sync`, no en el dominio |

Esta separación es la que hace que el móvil pueda operar meses sin red. La base **no** guarda pendientes: cuando el registro llega, ya viene con `oper_cliente_id`, `oper_t_captura` y `oper_deriva_reloj_seg`, y se inserta una sola vez. Un reintento no duplica porque `(disp_id, oper_cliente_id)` es único.

# Los dos canales sobre el mismo dato {#sec-canales}

| Dato | Web | Móvil | Origen único |
|---|---|---|---|
| MTD del periodo | PW01 «0,36» | P01 «0,35» | `indice_mtd.indi_valor` |
| Trampas revisadas | PW01 «4 de 4» | P02 «Lotes revisadas: 4» | `lectura_trampa` sobre `ubicacion_trampa` |
| Última visita | PW01 «08 oct 2026» | P01 y P02 «08 oct 2026» | `visita.visi_t_fin_obs` |
| Última aplicación | PW03 «06 oct · hace 2 días» | P02 «Hace 2 días» | `max(apli_t_observacion)` |
| Cosecha esperada | PW04 «15 nov · 850 kg» | P04 y P04b «15/11/2026 · 850 kg» | `cosecha` |
| Planificación | PW07 | P01 | `planificacion` |
| Documento de instrucciones | PW07b | P01 (d) | `archivo_adjunto` |
| Notificaciones | PW06b | P06 (preferencia) | `notificacion`, `perfil_usuario` |

Tres observaciones:

1. **El MTD difiere entre canales.** Para el mismo lote y periodo, la web muestra 0,36 y el móvil 0,35. No es un problema del modelo —ambos leen `indice_mtd.indi_valor`— sino de datos de ejemplo inconsistentes en el prototipo. La vista debe ser una sola y el valor debe coincidir al dígito.
2. **El conteo de trampas pierde el denominador en el móvil.** «4» y «4 de 4» deberían salir del mismo par (leídas, vigentes). Es el hallazgo F1 aplicado a los dos canales.
3. **La unidad de trabajo cambia.** La web razona sobre el predio; el móvil, sobre el lote. La API debe aceptar las dos granularidades sin duplicar recursos: el lote es la unidad de captura y el predio, la de consulta.

# Matriz consolidada de consumo {#sec-matriz}

## Tablas consumidas: 41 de 74 {#sec-consumidas}

### Identidad y acceso (7)

| Tabla | Columnas usadas | Web | Móvil |
|---|---|---|---|
| `persona` | `pers_nombre`, `pers_apellido`, `pers_correo` | PW01, PW05, PW06, PW07 | P01, P05, P06 |
| `productor` | `pers_cc`, `prod_activo` | PW01, PW02 | P01, P06 |
| `usuario` | `usua_id`, `pers_cc`, `rol_id`, `esta_id`, `usua_ultimo_acceso` | Todas | Todas |
| `rol` | `rol_codigo`, `rol_descripcion` | Todas | Todas |
| `usuario_predio` | `usua_id`, `pred_id`, `usup_desde`, `usup_hasta` | PW01, PW02 | P01, P06 |
| `permiso` | `perm_codigo` | RBAC | RBAC |
| `rol_permiso` | `rol_id`, `perm_id` | RBAC | RBAC |

### Predio y cultivo (5)

| Tabla | Columnas usadas | Web | Móvil |
|---|---|---|---|
| `predio` | `pred_nombre`, `pred_zona_horaria`, `pers_cc` | PW01, PW02, PW06 | P01, P02, P06 |
| `lote` | `lote_descripcion`, `lote_area`, `lote_fecha_plantacion`, `lote_fecha_baja` | Todas | Todas |
| `especie_cultivo` | `espc_descripcion` | PW02, PW06 | P01, P02, P06 |
| `variedad_cultivo` | `vari_descripcion` | PW06 | P06 |
| `programa_inspeccion` | `prog_umbral_exportacion_mtd`, `prog_vigente_desde` | PW01, PW02b | P01 |

### Vigilancia (7)

| Tabla | Columnas usadas | Web | Móvil |
|---|---|---|---|
| `periodo_trampeo` | `peri_inicio`, `peri_fin`, `peri_estado` | PW01, PW02b, PW05 | P01, P02, P06 |
| `trampa` | `tram_codigo`, `esta_id` | PW02 | — |
| `ubicacion_trampa` | `lote_id`, `ubic_fecha_fin` | PW01, PW02 | P02 |
| `visita` | `visi_t_fin_obs`, `usua_id`, `visi_estado_revision` | PW01, PW02, PW05 | P01, P02, P05 |
| `visita_lote` | `visi_id`, `lote_id` | PW01, PW02, PW05 | P02, P05 |
| `lectura_trampa` | `lect_especimenes`, `lect_t_observacion`, `lect_linaje` | PW01, PW02b, PW05 | P02, P05 |
| `hallazgo` | `plag_id`, `seve_id`, `hall_t_observacion` | PW02b | — |

### Cálculo (2)

| Tabla | Columnas usadas | Web | Móvil |
|---|---|---|---|
| `indice_mtd` | `indi_valor`, `indi_trampas`, `indi_resultado_contraste`, `esce_id` | PW01, PW02b | P01, P02 |
| `concepto_aptitud` | `conc_resultado`, `conc_fecha_efecto` | PW01, PW02b | — |

### Autorreporte (2)

| Tabla | Columnas usadas | Web | Móvil |
|---|---|---|---|
| `aplicacion_fitosanitaria` | `lote_id`, `prof_id`, `apli_producto_texto`, `apli_dosis`, `apli_dosis_uni_id`, `apli_area_tratada`, `apli_area_uni_id`, `pers_cc_responsable`, `apli_linaje`, `apli_t_observacion` | PW01, PW02, PW03, PW05, PW06 | P01, P02, P03, P05, P06 |
| `cosecha` | `lote_id`, `cose_fecha_esperada`, `cose_volumen_esperado`, `cose_fecha_real`, `cose_volumen_real`, `cose_volumen_uni_id`, `cose_linaje` | PW01, PW02, PW04, PW05, PW06 | P01, P04, P04b, P05, P06 |

### Planificación (3)

| Tabla | Columnas usadas | Web | Móvil |
|---|---|---|---|
| `planificacion` | `plan_actividad`, `plan_fecha_inicio`, `plan_hora_desde`, `plan_hora_hasta`, `plan_estado`, `plan_observaciones`, `plan_motivo_rechazo`, `plan_respondida_en` | PW01, PW07 | P01 |
| `planificacion_lote` | `plan_id`, `lote_id` | PW07 | P01 |
| `archivo_adjunto` | `arch_nombre_original`, `arch_tamano_bytes`, `arch_ref_almacenamiento` | PW07a, PW07b, PW07e | P01 |

### Avisos y perfil (4)

| Tabla | Columnas usadas | Web | Móvil |
|---|---|---|---|
| `notificacion` | `noti_titulo`, `noti_cuerpo`, `noti_leida_en`, `noti_destino_ruta` | PW06b | P06 |
| `categoria_notificacion` | `cate_codigo`, `cate_descripcion` | PW06 | P06 |
| `preferencia_notificacion` | `pref_habilitada` | PW06 | P06 |
| `perfil_usuario` | `perf_notificaciones_activas` | PW06 | P06 |

### Catálogos de apoyo (8)

| Tabla | Columnas usadas | Web | Móvil |
|---|---|---|---|
| `estado_registro` | `esta_descripcion` | PW06 | P06 |
| `unidad_medida` | `unid_simbolo`, `unid_magnitud` | PW03, PW04 | P03, P04 |
| `producto_fitosanitario` | `prof_nombre`, `prof_activo` | PW03 | P03 |
| `escenario_trampeo` | `esce_descripcion`, `esce_mtd_desde_defecto`, `esce_mtd_hasta_defecto` | PW01, PW02, PW02b | — |
| `plaga_enfermedad` | `plag_descripcion` | PW02b | — |
| `severidad` | `seve_descripcion` | PW02b | — |
| `fenologia` | `feno_descripcion` | PW02b | — |
| `fenologia_regla` | `fenr_dias_desde`, `fenr_dias_hasta` | PW02b | — |

### Sincronización (3)

| Tabla | Columnas usadas | Web | Móvil |
|---|---|---|---|
| `operacion_sync` | `oper_cliente_id`, `oper_t_captura`, `oper_t_recepcion`, `oper_clasificacion`, `disp_id` | PW06 | P03, P04, P07 |
| `dispositivo` | `disp_id`, `disp_ultima_sync`, `disp_plataforma` | PW06 | P01, P06, P07 |
| `recepcion_sync` | `rece_id`, `oper_id`, `rece_resultado`, `rece_t` | — | P07c |

## Tablas que esta vista no consume: 33 de 74 {#sec-no-consumidas}

| Grupo | Tablas | Por qué no aparecen |
|---|---|---|
| Geografía y territorio | `departamento`, `municipio`, `region`, `rango_departamento`, `centro_acopio`, `localizacion`, `arbol`, `ruta` | El productor no ve mapas, rutas ni ubicación administrativa |
| Trampeo operativo | `tipo_trampa`, `atrayente`, `condicion_trampa`, `reticula`, `reticula_celda`, `programa_umbral`, `vigilancia`, `paquete_campo` | Son datos del técnico o parámetros del programa |
| Identidad institucional | `administrador`, `tecnico`, `restablecimiento_clave` | Otros roles u otro flujo |
| Geometría | `lote_geometria`, `evidencia`, `imagen_diseno` | El productor no dibuja polígonos ni adjunta evidencia |
| Auditoría | `bitacora_auditoria` | La traza se consulta desde administración |
| Producción y BPA | `estimacion_produccion`, `manejo_agronomico`, `tipo_manejo`, `bpa_verificacion`, `criterio_bpa`, `programa_criterio_bpa` | Fuera del alcance del productor en estos prototipos |
| Catálogos sin uso en pantalla | `especie_mosca`, `norma` | Se usan en el cálculo y en el concepto, no se muestran |
| Registro declarado | `etapa_declarada` | La etapa se **deriva** con `fn_etapa_derivada`, no se declara |
| Trazabilidad del MTD | `indice_mtd_lectura` | Detalle interno del cálculo |

# Hallazgos y cambios propuestos {#sec-hallazgos}

## Bloqueantes {#sec-bloqueantes}

### El catálogo de escenarios está vacío {#sec-b1}

La columna «Situación según el ICA» y la insignia de cada lote leen `escenario_trampeo.esce_descripcion`. El catálogo no se carga en `02_catalogos_basicos.sql` porque «los valores oficiales los define la institución». Sin esos cuatro registros, la pantalla no puede pintar Supresión, Erradicación, Exclusión ni Área infestada.

**Propuesta:** sembrar los cuatro escenarios de RN-002 con los rangos del Manual (Tabla 1, OIEA 2005), en las columnas `esce_mtd_desde_defecto`, `esce_mtd_hasta_defecto` y `esce_orden`. No es inventar el umbral de exportación: es cargar un catálogo que el propio levantamiento documenta.

| Escenario | MTD desde | MTD hasta | Orden |
|---|---|---|---|
|--------------------|------------------------|----------------|------------------|
| Área infestada | 1,0000 | *(nulo)* | 1 |
| Supresión | 0,1000 | 1,0000 | 2 |
| Erradicación | 0,0000 | 0,1000 | 3 |
| Exclusión | 0,0000 | 0,0000 | 4 |

El límite superior nulo significa «sin techo». La regla de asignación debe ser consistente en los bordes: el prototipo usa 0,36 → supresión y 0,07 → erradicación, lo que confirma intervalos semiabiertos por la izquierda.

### Los permisos no están declarados {#sec-b2}

Las dos interfaces necesitan ocultar acciones. El esquema tiene el mecanismo (`permiso.perm_codigo` + `rol_permiso`), pero no los valores. Hoy la única autorización efectiva es `fn_lotes_visibles`, que resuelve **qué predios** ve un usuario, no **qué acciones** puede ejecutar. `permiso` se declara explícitamente como pendiente institucional.

**Propuesta mínima para el productor:** `predio:leer`, `aplicacion:crear`, `cosecha:crear`, `planificacion:responder`, `notificacion:leer`, `perfil:editar`, y para los demás roles los permisos que ya usa la web. La matriz de `permiso` debe ser la misma que consuman los dos clientes para decidir qué botones dibujar; la API sigue siendo la autoridad final (RNF-015).

### No existe el concepto de trampas revisadas {#sec-b3}

Es el dato más repetido de los dos canales (PW01, PW02, PW05, P02, P05) y no tiene origen. Se puede reconstruir con `count(lectura_trampa)` de la visita y `count(ubicacion_trampa)` vigentes del lote, pero **no** existe una vista que lo entregue, y hacerlo en el cliente exige tres consultas y aritmética de fechas.

## Vistas y campos faltantes {#sec-faltantes}

| # | Qué falta | Dónde se nota | Propuesta |
|---|---|---|---|
| F1 | Historial con responsable, detalle y conteo de trampas | PW05, PW02b, P05 | `v_actividad_lote_detalle` |
| F2 | Cosecha vigente por lote (esperada + real) | PW01, PW02, PW04, P04 | `v_cosecha_lote_vigente` |
| F3 | Última aplicación por lote, con producto y días | PW03, P02 | `v_aplicacion_ultima_lote` |
| F4 | `arch_tamano_bytes`, `arch_mime` y `arch_id` en la planeación | PW07e, PW07b, P01 | Ampliar `v_planificacion` |
| F5 | Nombre del lote y del predio en la planeación | PW07a–e, P01 | Ampliar `v_planificacion` |
| F6 | Lista de avisos con título, cuerpo y fecha de lectura | PW06b | `v_notificacion_app` |
| F7 | MTD, escenario, periodo, última visita y vigilancia en el resumen | PW01, PW02, P01, P02 | Ampliar `v_resumen_lote` |
| F8 | Origen del «canal de acceso» (Móvil y web) | PW06 | `v_usuario_acceso` derivada |
| F9 | Última sincronización por usuario y dispositivo | P01, P06, P07 | `v_ultima_sincronizacion` |
| F10 | Resultado del servidor por operación de cliente | P07b, P07c, P07d | `v_operacion_confirmada` |

## Correcciones de modelo o de regla {#sec-correcciones}

| # | Situación | Corrección propuesta | Riesgo si no se hace |
|---|---|---|---|
| C1 | Varias cosechas abiertas por lote | Índice único parcial: una sola cosecha no anulada y sin fecha real por lote | Dos «esperadas» simultáneas y totales duplicados |
| C2 | «Hallazgos vigentes» sin definición | Ventana explícita (por periodo o por días) o columna `hall_vigente_hasta` | La pantalla puede mostrar hallazgos cerrados o esconder los activos |
| C3 | `v_lote_resumen_app.concepto` no explica el motivo | Exponer `prog_umbral_exportacion_mtd` y `conc_motivo` | El cliente inventa el texto «falta definir el umbral» |
| C4 | `apli_t_observacion` es `timestamptz` y las interfaces capturan solo fecha | La API fija la hora con la zona del predio y lo documenta | Desfase de un día en el historial |
| C5 | El productor web contradice el supuesto 1 de ADR-18 | Actualizar el supuesto y la guarda de rutas por rol | Documento y producto describen alcances distintos |
| C6 | Los formularios móviles no traen lote | Tomar `lote_id` del contexto de la pantalla; la API lo exige | El `INSERT` falla o se asocia al lote equivocado |
| C7 | MTD distinto entre canales (0,36 y 0,35) y lote único frente a cuatro | Una sola vista por dato y un solo juego de datos de ejemplo | El productor ve cifras distintas según el dispositivo |

## Diferencias de vocabulario {#sec-vocabulario}

| Etiqueta del prototipo | Valor en el modelo | Tratamiento |
|---|---|---|
| «Supresión», «Erradicación», «Sin revisar» | `escenario_trampeo.esce_descripcion`; «sin revisar» = sin `indice_mtd` | Cargar catálogo (§9.1.1); «sin revisar» se deriva |
| «Concepto para exportar: Aún no se emite» | `concepto_aptitud.conc_resultado = 'no_emitido'` | Mapear en la API; no mostrar el literal |
| «Autorreporte» / «Inspección oficial» | `d_linaje`: `autorreporte` / `inspeccion_oficial` | Mapear en la API |
| «Todos los campos son obligatorios» | `prof_id` **o** `apli_producto_texto`; responsable **o** nombre | Aceptable si se documenta |
| «Moscas por trampa al día · promedio» | `indice_mtd.indi_valor` (índice, no promedio) | Rotular «Índice MTD» |
| «Lotes revisadas» (móvil) | `count(lectura_trampa)` | Rotular «Trampas revisadas» |
| «Pendiente de sincronizar» / «Confirmado» | Cola local / `recepcion_sync.rece_resultado` | No son estados de la tabla de dominio |

# DDL propuesto {#sec-ddl}

> **Estado:** propuesta para discusión. No se ejecutó sobre la base. Todo el bloque es idempotente salvo el sembrado del catálogo, que fallaría si los valores ya existen.

## Semillado del catálogo de escenarios {#sec-ddl-escenario}

```sql
INSERT INTO sigat.escenario_trampeo
  (esce_descripcion, esce_orden,
   esce_mtd_desde_defecto, esce_mtd_hasta_defecto, esce_fuente)
VALUES
  ('Área infestada', 1, 1.0000, NULL,   'RN-002, Tabla 1 OIEA 2005'),
  ('Supresión',      2, 0.1000, 1.0000, 'RN-002, Tabla 1 OIEA 2005'),
  ('Erradicación',   3, 0.0000, 0.1000, 'RN-002, Tabla 1 OIEA 2005'),
  ('Exclusión',      4, 0.0000, 0.0000, 'RN-002, Tabla 1 OIEA 2005')
ON CONFLICT (esce_descripcion) DO NOTHING;
```

## Permisos del productor {#sec-ddl-permisos}

```sql
INSERT INTO sigat.permiso (perm_codigo, perm_descripcion) VALUES
  ('predio:leer',              'Consultar predios y lotes'),
  ('aplicacion:crear',         'Registrar aplicaciones'),
  ('cosecha:crear',            'Registrar y completar cosechas'),
  ('planificacion:responder',  'Aceptar o rechazar planeaciones'),
  ('notificacion:leer',        'Consultar y marcar avisos'),
  ('perfil:editar',            'Editar preferencias del perfil')
ON CONFLICT (perm_codigo) DO NOTHING;

INSERT INTO sigat.rol_permiso (rol_id, perm_id)
SELECT r.rol_id, p.perm_id
FROM sigat.rol r CROSS JOIN sigat.permiso p
WHERE r.rol_codigo = 'PRODUCTOR'
  AND p.perm_codigo IN ('predio:leer', 'aplicacion:crear',
                        'cosecha:crear', 'planificacion:responder',
                        'notificacion:leer', 'perfil:editar')
ON CONFLICT DO NOTHING;
```

## Vista de historial detallado {#sec-ddl-historial}

```sql
CREATE OR REPLACE VIEW sigat.v_actividad_lote_detalle AS
SELECT a.lote_id, a.tipo, a.registro_id, a.t_observacion, a.usua_id,
       pe.pers_nombre || ' ' || pe.pers_apellido AS responsable,
       r.rol_descripcion AS rol_responsable,
       CASE a.tipo
         WHEN 'vigilancia' THEN 'Visita de vigilancia'
         WHEN 'aplicacion' THEN 'Aplicación fitosanitaria'
         ELSE 'Cosecha'
       END AS titulo,
       CASE a.tipo
         WHEN 'vigilancia' THEN
           (SELECT count(*) FROM sigat.lectura_trampa lt
             WHERE lt.visi_id = a.registro_id)::text
           || ' de ' ||
           (SELECT count(*) FROM sigat.ubicacion_trampa u
             WHERE u.lote_id = a.lote_id
               AND u.ubic_fecha_fin IS NULL)::text
           || ' trampas revisadas'
         WHEN 'aplicacion' THEN
           COALESCE(
             (SELECT p.prof_nombre
                FROM sigat.aplicacion_fitosanitaria x
                JOIN sigat.producto_fitosanitario p USING (prof_id)
               WHERE x.apli_registro_id = a.registro_id
               ORDER BY x.apli_version DESC LIMIT 1),
             (SELECT x.apli_producto_texto
                FROM sigat.aplicacion_fitosanitaria x
               WHERE x.apli_registro_id = a.registro_id
               ORDER BY x.apli_version DESC LIMIT 1))
         ELSE
           'Cosecha esperada · ' ||
           to_char((SELECT x.cose_fecha_esperada
                      FROM sigat.cosecha x
                     WHERE x.cose_registro_id = a.registro_id
                     ORDER BY x.cose_version DESC LIMIT 1),
                   'DD Mon YYYY')
       END AS detalle,
       (a.tipo = 'vigilancia') AS es_inspeccion_oficial
FROM sigat.v_actividad_lote a
JOIN sigat.usuario u ON u.usua_id = a.usua_id
JOIN sigat.persona pe ON pe.pers_cc = u.pers_cc
JOIN sigat.rol r ON r.rol_id = u.rol_id;
```

## Vista de cosecha vigente por lote {#sec-ddl-cosecha}

```sql
CREATE OR REPLACE VIEW sigat.v_cosecha_lote_vigente AS
SELECT DISTINCT ON (c.lote_id)
       c.lote_id, c.cose_registro_id, c.cose_version,
       c.cose_fecha_esperada, c.cose_volumen_esperado,
       c.cose_fecha_real, c.cose_volumen_real,
       u.unid_simbolo AS unidad, c.cose_linaje
FROM sigat.cosecha c
JOIN sigat.unidad_medida u ON u.unid_id = c.cose_volumen_uni_id
WHERE NOT c.cose_anulada
ORDER BY c.lote_id, c.cose_version DESC, c.cose_t_observacion DESC;
```

## Índice de una sola cosecha abierta {#sec-ddl-indice}

```sql
CREATE UNIQUE INDEX ux_cosecha_abierta_por_lote
  ON sigat.cosecha (lote_id)
  WHERE NOT cose_anulada AND cose_fecha_real IS NULL;
```

> **Decisión pendiente.** Si un lote puede tener varias cosechas esperadas a la vez —por ejemplo, dos ciclos solapados—, este índice debe cambiar por `(lote_id, periodo)`. El prototipo dice «un solo registro con lo esperado y lo real», pero no define el ciclo. Se recomienda confirmarlo antes de aplicarlo.

## Vistas de sincronización {#sec-ddl-sync}

```sql
CREATE OR REPLACE VIEW sigat.v_ultima_sincronizacion AS
SELECT d.disp_id, u.usua_id, d.disp_plataforma,
       max(o.oper_t_recepcion) AS ultima_recepcion,
       count(o.oper_id)        AS operaciones_recibidas
FROM sigat.dispositivo d
JOIN sigat.operacion_sync o USING (disp_id)
JOIN sigat.usuario u ON u.usua_id = o.usua_id
GROUP BY d.disp_id, u.usua_id, d.disp_plataforma;

CREATE OR REPLACE VIEW sigat.v_operacion_confirmada AS
SELECT o.usua_id, o.disp_id, o.oper_cliente_id, o.oper_id,
       o.oper_entidad, o.oper_clasificacion,
       o.oper_t_captura, o.oper_t_recepcion,
       (SELECT r.rece_resultado
          FROM sigat.recepcion_sync r
         WHERE r.oper_id = o.oper_id
         ORDER BY r.rece_t DESC LIMIT 1) AS ultimo_resultado,
       (SELECT count(*) FROM sigat.recepcion_sync r
         WHERE r.oper_id = o.oper_id) AS reenvios
FROM sigat.operacion_sync o;
```

`v_operacion_confirmada` es la pieza que cierra el ciclo del móvil: permite mapear el identificador local de la cola (`oper_cliente_id`) con la respuesta del servidor, sin que el cliente tenga que adivinar si su registro llegó.

## Ampliación de la vista de planeación {#sec-ddl-planeacion}

```sql
CREATE OR REPLACE VIEW sigat.v_planificacion AS
SELECT p.plan_id, p.plan_actividad,
       p.plan_fecha_inicio, p.plan_fecha_fin,
       p.plan_hora_desde, p.plan_hora_hasta,
       p.plan_estado, p.plan_observaciones,
       p.plan_motivo_rechazo, p.plan_creada_en,
       p.plan_respondida_en,
       p.usua_id_destinatario,
       pd.pers_nombre || ' ' || pd.pers_apellido AS destinatario,
       rd.rol_descripcion AS rol_destinatario,
       p.usua_id_creador,
       pc.pers_nombre || ' ' || pc.pers_apellido AS creador,
       p.arch_id_documento,
       a.arch_nombre_original AS documento,
       a.arch_mime            AS documento_mime,
       a.arch_tamano_bytes    AS documento_bytes,
       a.arch_paginas         AS documento_paginas,
       COALESCE((SELECT array_agg(l.lote_codigo ORDER BY l.lote_codigo)
                   FROM sigat.planificacion_lote pl
                   JOIN sigat.lote l USING (lote_id)
                  WHERE pl.plan_id = p.plan_id), '{}') AS lotes,
       COALESCE((SELECT array_agg(l.lote_descripcion
                                  ORDER BY l.lote_codigo)
                   FROM sigat.planificacion_lote pl
                   JOIN sigat.lote l USING (lote_id)
                  WHERE pl.plan_id = p.plan_id), '{}')
         AS lotes_descripcion
FROM sigat.planificacion p
JOIN sigat.usuario ud ON ud.usua_id = p.usua_id_destinatario
JOIN sigat.persona pd ON pd.pers_cc = ud.pers_cc
JOIN sigat.rol rd ON rd.rol_id = ud.rol_id
JOIN sigat.usuario uc ON uc.usua_id = p.usua_id_creador
JOIN sigat.persona pc ON pc.pers_cc = uc.pers_cc
LEFT JOIN sigat.archivo_adjunto a ON a.arch_id = p.arch_id_documento;
```

# Contrato HTTP que la vista exige {#sec-contrato}

Los dos canales consumen **los mismos recursos**; cambia la forma de la respuesta y, en el móvil, la existencia de un recurso de sincronización. Todas las rutas de la tabla cuelgan de `/api/v1`.

| Recurso | Verbo | Pantalla | Origen |
|---|---|---|---|
| `/productor/resumen` | GET | PW01, P01 | `v_resumen_lote` + `v_mtd_serie_lote` |
| `/lotes` | GET | PW02, P01 | `v_lote_app` |
| `/lotes/{id}/estado` | GET | PW02b, P02 | `v_lote_resumen_app` |
| `/lotes/{id}/actividad` | GET | PW02b, PW05, P02, P05 | `v_actividad_lote_detalle` |
| `/aplicaciones` | GET | PW03, P02 | `v_aplicacion_ultima_lote` |
| `/aplicaciones` | POST | PW03a, P03 | `aplicacion_fitosanitaria` |
| `/cosechas` | GET | PW04, P04 | `v_cosecha_lote_vigente` |
| `/cosechas` | POST | PW04a, P04 | `cosecha` |
| `/cosechas/{registro_id}` | PATCH | PW04a, P04 | Nueva versión de `cosecha` |
| `/planificaciones` | GET | PW07, PW07f, P01 | `v_planificacion` |
| `/planificaciones/{id}` | GET | PW07a–e, P01 | `v_planificacion` |
| `/planificaciones/{id}/aceptar` | POST | PW07a, P01 | `fn_planificacion_valida` |
| `/planificaciones/{id}/rechazar` | POST | PW07c, P01 | `fn_planificacion_valida` |
| `/notificaciones` | GET | PW06b, P06 | `v_notificacion_app` |
| `/notificaciones/{id}/leida` | PATCH | PW06b | `notificacion.noti_leida_en` |
| `/perfil` | GET | PW06, P06 | `persona` + `usuario` + `perfil_usuario` |
| `/perfil/preferencias` | PATCH | PW06, P06 | `perfil_usuario` |
| `/catalogos/{nombre}` | GET | PW03a, P03 | `producto_fitosanitario`, `unidad_medida` |
| `/sync/operaciones` | POST | P03, P04, P07 | `operacion_sync` + `recepcion_sync` |
| `/sync/estado` | GET | P06, P07 | `v_ultima_sincronizacion` |
| `/sync/confirmaciones` | GET | P07b, P07c | `v_operacion_confirmada` |

Cuatro observaciones de contrato:

1. **El `POST` de aplicación y de cosecha debe crear la operación de sincronización** (`operacion_sync`) en la misma transacción, porque ambas tablas exigen `oper_id` no nulo y `disp_id`. Esa es la razón por la que ningún cliente puede escribir con un `INSERT` simple, ni en web ni en móvil.
2. **El `POST` de sincronización es por lote de operaciones, no por registro.** La clave `(disp_id, oper_cliente_id)` hace idempotente el reintento (RN-010) y permite responder un resultado por operación, que es lo que pinta P07c.
3. **El recurso de archivo no se sirve desde la base.** `arch_ref_almacenamiento` es una referencia; la API debe devolver una URL firmada y de corta vida. Los dos canales dibujan vista previa del documento.
4. **La web no necesita el recurso de sincronización**, pero sí el estado (`/sync/estado`) para pintar «Móvil y web» en el perfil.

# Riesgos y decisiones abiertas {#sec-riesgos}

| Riesgo | Impacto | Decisión requerida | Responsable |
|---|---|---|---|
| Catálogo de escenarios sin cargar | La columna «Situación según el ICA» queda vacía | Aprobar el sembrado de RN-002 | ICA / Agronomía |
| Permisos sin definir | Los clientes ocultan acciones con listas propias | Definir la matriz `permiso` por rol | Arquitectura + ICA |
| Umbral de exportación (UQQ-004) | El concepto siempre será `no_emitido` | Decisión institucional | ICA |
| Cosecha abierta duplicada | Totales de producción inflados | Confirmar si hay ciclos solapados | Agronomía |
| «Vigencia» de hallazgos | La pantalla puede mostrar u ocultar de más | Definir la ventana de vigencia | Sanidad vegetal |
| Productor en la web | Contradice el supuesto 1 de ADR-18 | Actualizar el alcance | Arquitectura |
| Doble captura entre canales | La misma aplicación registrada en web y móvil | Duplicado por `oper_cliente_id` distinto; definir aviso al usuario | Producto |
| Reloj del dispositivo | Fechas de captura adelantadas o atrasadas | Usar `oper_deriva_reloj_seg` y mostrar advertencia | Arquitectura |
| Pérdida del dispositivo con cola pendiente | Autorreportes nunca llegan al servidor | Definir política de respaldo y tiempo máximo sin sincronizar | Operación |
| Catálogos de producto y plaga vacíos | P03 y PW03a no pueden ofrecer el selector | Cargar `producto_fitosanitario` y `plaga_enfermedad` | ICA |

# Conclusiones {#sec-conclusiones}

1. **El modelo de datos resiste los dos prototipos.** De 74 tablas, 41 participan en la vista del productor y las relaciones necesarias existen. No hace falta una tabla nueva para ninguna pantalla, ni móvil ni web.
2. **El problema es de exposición, no de esquema.** Diez pantallas requieren una consulta que hoy no existe como vista; resolverlas en React o en Dart contradice ADR-13 y duplicaría reglas en dos lenguajes.
3. **Tres catálogos bloquean las interfaces** (`escenario_trampeo`, `permiso`, `rol_permiso`) y dos más limitan la captura (`producto_fitosanitario`, `plaga_enfermedad`). Son datos, no estructura.
4. **La frontera de escritura es la misma en los dos canales y hay que conservarla.** El productor escribe dos tablas y responde una tercera; todo lo demás es lectura calculada por el servidor.
5. **El móvil agrega una capa que la base no debe modelar: la cola local.** «Pendiente de sincronizar» no es un estado de `aplicacion_fitosanitaria` ni de `cosecha`; es una fila en el dispositivo que se convierte en `operacion_sync` cuando llega. Modelarla en PostgreSQL duplicaría la fuente de verdad.
6. **Los dos canales deben mostrar el mismo número.** El 0,36 de la web y el 0,35 del móvil son el mismo dato leído de la misma columna; la diferencia es un error de los datos de ejemplo y una señal de que falta una vista única por pantalla.

El orden de trabajo sugerido es: sembrar catálogos, publicar las diez vistas, definir el recurso de sincronización y solo entonces conectar las pantallas. Las pantallas no cambian; cambia de dónde leen.
