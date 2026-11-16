---
title: "Especificación Técnica de Desarrollo — Versión Final (Handover para Desarrolladores)"
subtitle: "Guía de construcción para backend-sigat, frontend-sigat y mobile-sigat sobre SIGAT v6"
author: "Equipo de Arquitectura de Software"
date: "31 de octubre de 2026"
lang: es-CO
---

# Resumen ejecutivo y guía de inicio para desarrolladores {#sec-resumen}

> **Propósito.** Este documento es la **referencia técnica de construcción — versión final** del sistema SIGAT (Sistema de Gestión y Monitoreo Fitosanitario para Cultivos de Durazno con Fines de Exportación - ICA). Consolida todos los requerimientos funcionales, decisiones de arquitectura (ADRs), esquemas de base de datos (incluyendo 28 vistas actualizadas en `BD/sigat_db_v6/sql/03_vistas.sql`), contratos HTTP REST (OpenAPI 3.1), flujos offline-first de sincronización, historias BDD (Gherkin) y el cronograma de 5 sprints. Corresponde a los tres repositorios del proyecto en la organización GitHub `SIGAT-UP` (`backend-sigat`, `frontend-sigat`, `mobile-sigat`).

El sistema se compone de tres proyectos de software independientes conectados mediante un único contrato explícito (OpenAPI 3.1):

1. **`backend-sigat`**: Monolito modular en Python 3.12 con FastAPI, SQLAlchemy 2.0 y Alembic. Expone la API RESTful, ejecuta las funciones transaccionales de sincronización, calcula el índice MTD y emite los conceptos fitosanitarios.
2. **`frontend-sigat`**: Aplicación web SPA en React 19, TypeScript, Vite, Tailwind CSS v4 y TanStack Query v5. Funciona como Backoffice Administrativo/Técnico y como Portal de Autogestión del Productor.
3. **`mobile-sigat`**: Aplicación móvil offline-first en Flutter (Dart) con base local Drift sobre SQLite, cola de operaciones pendientes e integración de mapas vectoriales con MapLibre GL Native.

```
+------------------------+      +------------------------+
|     frontend-sigat     |      |      mobile-sigat      |
|        React 19        |      |    Flutter / Drift     |
+------------------------+      +------------------------+
            | HTTPS / REST                  | HTTPS / sync
            +----------------+--------------+
                             v
                +------------------------+
                |     backend-sigat      |
                |    Python / FastAPI    |
                +------------------------+
                             |  psycopg / SQL
                             v
                +------------------------+
                |     PostgreSQL 16      |
                |     + PostGIS 3.4      |
                +------------------------+
```

## Documentos de origen y entregables finales {#sec-fuentes}

Este documento no reemplaza a los anteriores: los resume en instrucciones de construcción. Cuando haga falta el detalle, la fuente es:

| Si necesitas… | Consulta |
|---|---|
| Requisitos, reglas de negocio y criterios de verificación | `Levantamiento_Requerimientos_ICA_Durazno.md` (versión final) |
| Decisiones de arquitectura y contrato entre repositorios | `Arquitectura_Tecnologica_ICA_Durazno.md` (ADR-01 a ADR-18) |
| Fronteras, patrones y puertas de calidad por repositorio | `Estructura_Repositorios_ICA_Durazno.md` (árboles reales) |
| DDL completo, vistas, funciones y catálogos | `BD/sigat_db_v6/` (28 vistas + catálogos sembrados) |
| Correspondencia pantalla → tabla → recurso HTTP | `Consumo_Datos_Vista_Productor_ICA_Durazno.md` (versión unificada) |
| Mapa vectorial, geolocalización y uso sin conexión | `Implementacion_MapLibre_Flutter_ICA_Durazno.md` |
| Orden de construcción y alcance del MVP | `Tabla_Prioridades_MVP_ICA_Durazno.md` |
| Plan de 5 sprints (Mon-Sab, 2 nov–5 dic) | `Cronograma_5_Sprints_SIGAT.md` |
| Entregable completo en carpeta | `LVDocs/` |

> **Actualización BD (31 oct 2026).** Las vistas creadas/actualizadas en `BD/sigat_db_v6/sql/03_vistas.sql` cubren todas las pantallas del productor (web `PW01`–`PW07` y móvil `P01-P`–`P07d-P`). Las 7 vistas nuevas/ampliadas son: `v_notificacion_app`, `v_actividad_lote_detalle`, `v_mtd_por_lote_escenario`, `v_planificacion` (con documento adjunto y `lotes_descripcion`), `v_ultima_sincronizacion`/`v_operacion_confirmada`, y `v_resumen_productor`. Los catálogos `escenario_trampeo` y `permiso` están sembrados con datos oficiales (OIEA/ICA y RBAC productor).

## Ficha técnica de tecnologías y versiones aprobadas {#sec-stack}

| Repositorio | Lenguaje / Runtime | Framework Principal | Bibliotecas Clave | Herramientas de Calidad |
|---|---|---|---|---|
| `backend-sigat` | Python 3.12 (Alpine) | FastAPI 0.115+ | `uv`, SQLAlchemy 2.0, Alembic, psycopg3, Pydantic v2 | `ruff`, `pytest`, `httpx` |
| `frontend-sigat` | TypeScript 6.0 / Node 22 | React 19.3 / Vite 8.3 | React Router 7.18, TanStack Query 5.104, RHF 7.91 + Zod 4.6, MapLibre GL 6.15, Recharts 3.10, Tailwind 4.3 | `oxlint`, `vitest` 5, `playwright` 1.64, MSW 3 |
| `mobile-sigat` | Dart 3.6+ / Flutter 3.27+ | Flutter SDK | `flutter_riverpod`, `go_router`, `dio`, `drift`, `maplibre_gl`, `connectivity_plus`, `path_provider`, `freezed` + `json_serializable` | `flutter analyze`, `flutter test` |
| **Infraestructura** | Docker Alpine | Coolify PaaS | PostgreSQL 16 + PostGIS 3.4, Nginx | GitHub Actions CI/CD |

## Variables de entorno estándar por repositorio {#sec-env-vars}

### `backend-sigat` (`.env`)
```bash
DATABASE_URL=postgresql+psycopg://sigat_user:sigat_pass@sigat-db:5432/sigat_db
SECRET_KEY=super-secret-key-change-in-production-min-32-chars
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=480
STORAGE_PATH=/var/sigat/storage
CORS_ORIGINS=["http://localhost:8080","https://sigat.ica.gov.co"]
RUN_MIGRATIONS=0
```

### `frontend-sigat` (`.env`)
```bash
VITE_API_BASE_URL=https://api.sigat.ica.gov.co/api/v1
VITE_APP_ENV=production
VITE_MAP_STYLE_URL=https://tiles.sigat.ica.gov.co/style.json
```

### `mobile-sigat` (`lib/core/config/api_config.dart`)
```bash
# La URL entra por --dart-define, no se escribe en el código:
flutter build apk --dart-define=API_BASE_URL=https://api.sigat.ica.gov.co
```

# Dominio fitosanitario y reglas de negocio transversales {#sec-dominio}

Todo desarrollador debe conocer y respetar las reglas de negocio del dominio fitosanitario del ICA antes de escribir código.

## Cálculo e interpretación del Índice MTD (RN-001 / RN-002) {#sec-rn-mtd}

El cálculo del índice **MTD** (*Moscas por Trampa al Día*) determina el nivel de infestación de moscas de la fruta (*Anastrepha spp.* y *Ceratitis capitata*) en un lote o predio durante un periodo de vigencia:

**MTD = E ÷ (T × D)**

Donde:

- **E**: total de especímenes capturados en el periodo.
- **T**: número de trampas de vigilancia activas y leídas en el lote.
- **D**: número de días calendario transcurridos en el periodo de trampeo.

### Clasificación oficial por escenarios (OIEA / ICA) {#sec-escenarios}

El valor del MTD se mapea al catálogo `escenario_trampeo` según las ventanas oficiales:

| Escenario | Rango MTD | Significado Fitosanitario | Acción en Sistema |
|---|---|---|---|
| **Área Infestada** | MTD > 1,0000 | Infestación alta por encima de umbral | Notificación crítica automática, bloqueo de certificado |
| **Supresión** | 0,1000 < MTD ≤ 1,0000 | Infestación moderada en proceso de control | Requerimiento de aplicaciones fitosanitarias obligatorias |
| **Erradicación** | 0,0000 < MTD ≤ 0,1000 | Nivel de baja prevalencia | Mantenimiento de monitoreo intensivo |
| **Exclusión** | MTD = 0,0000 | Ausencia total de especímenes capturados | Condición óptima para emisión de certificado |

> **REGLA DE ORO (ADR-13):** El cliente (web o móvil) **NUNCA** calcula el MTD ni asigna el escenario. El MTD es calculado exclusivamente por el backend en PostgreSQL mediante la vista `v_mtd_vigente` y las funciones de agregación.

## Concepto de Aptitud para Exportación (RN-003 / UQQ-004) {#sec-rn-concepto}

El concepto fitosanitario determina si un predio/lote puede exportar fruta. Se registra en la tabla `concepto_aptitud`:

- `apto`: El MTD del periodo se encuentra por debajo del umbral del programa (`prog_umbral_exportacion_mtd`) y no existen hallazgos ni sanciones pendientes.
- `no_apto`: El MTD superó el umbral o existen incumplimientos fitosanitarios.
- `no_emitido`: El programa de inspección aún no define el umbral oficial (condición UQQ-004) o faltan lecturas obligatorias en el periodo.

## Linaje de datos (RN-005) {#sec-rn-linaje}

Cada registro de campo posee una columna `*_linaje` con dominio estricto:

- `inspeccion_oficial`: Registro realizado directamente por un Técnico o Agrónomo del ICA (visitas, lecturas de trampas, hallazgos, censos).
- `autorreporte`: Registro realizado por el Productor agrícola desde la App Móvil o Portal Web (aplicaciones fitosanitarias, cosechas esperadas/reales).

## Fenología de cultivo: Calculada vs. Declarada (RN-008) {#sec-rn-fenologia}

La etapa fenológica (Brotación, Floración, Cuajado, Crecimiento, Fructificación, Cosecha, Reposo) **se calcula dinámicamente** mediante la función de base de datos `sigat.fn_etapa_derivada(lote_id, fecha_evaluacion)` a partir de la fecha de siembra/plantación (`lote_fecha_plantacion`) y las reglas de `fenologia_regla`. La tabla `etapa_declarada` es únicamente para registro histórico manual.

## Control de acceso y visibilidad RBAC (RNF-015) {#sec-rn-rbac}

El sistema implementa control de acceso basado en roles (RBAC) reforzado a nivel de base de datos con la función `sigat.fn_lotes_visibles(usua_id)`:

- **Productor**: Solo visualiza y registra datos de los predios/lotes asociados a su número de cédula (`usuario_predio`).
- **Técnico**: Visualiza y registra visitas/lecturas en los predios de su zona/ruta asignada.
- **Agrónomo**: Visualiza el estado fitosanitario de sus predios asignados y gestiona planificaciones.
- **Administrador**: Acceso total de lectura y configuración de catálogos/usuarios.

# Especificación técnica del backend (`backend-sigat`) {#sec-backend}

## Arquitectura modular DDD / Clean Architecture {#sec-arch-backend}

El paquete Python se llama `ica_api` (distribución `ica-durazno-api`) y se organiza en una capa compartida más 11 módulos de negocio. Cada módulo repite la misma separación en cuatro capas internas:

```text
src/ica_api/
├── api/v1/router.py      # Punto de montaje de los routers de módulo
├── core/                 # Configuración, seguridad, paginación, logging, tiempo
├── infra/                # Adaptadores: db, geo, storage, queue, observability
├── kernel/               # Primitivas compartidas del dominio
└── modules/<modulo>/
    ├── domain/           # entities, value_objects, services, events, ports
    ├── application/      # Casos de uso y DTOs
    ├── infrastructure/   # persistence, geo, messaging
    ├── api/              # router.py y schemas.py
    └── tests/
```

### Árbol de los 11 módulos de dominio {#sec-modulos-tree}

1. `identidad`: Usuarios, personas, roles, permisos, autenticación JWT, seguridad.
2. `sincronizacion`: Operaciones offline, la cola `operacion_sync`, la recepción `recepcion_sync` y control de idempotencia.
3. `registro`: Predios, lotes, trampas, ubicaciones, especies y cultivos.
4. `configuracion`: Catálogos generales, unidades de medida, fenología y productos fitosanitarios.
5. `imagenes`: Carga, almacenamiento, URL firmadas y metadata de adjuntos/evidencias.
6. `concepto`: Lectura de MTD, evaluación de umbrales y emisión de conceptos fitosanitarios.
7. `reportes`: Vistas consolidadas, resúmenes por lote, línea de tiempo de actividades y estadísticas.
8. `administracion`: Gestión institucional de audit log, bitácoras y monitoreo de salud.
9. `importacion`: Carga masiva de archivos CSV/Excel de campañas anteriores.
10. `laboratorio`: Muestreo, remisión de especímenes y diagnóstico taxonómico.
11. `calidad`: Verificaciones BPA (Buenas Prácticas Agrícolas) y criterios de calidad.

## Esquema de base de datos (SIGAT v6) y DDLs fundamentales {#sec-ddl-backend}

El esquema `sigat` cuenta con 74 tablas. A continuación se presentan las **vistas y scripts de sembrado indispensables** que el backend utiliza para resolver las consultas de las interfaces.

### Sembrado del catálogo de escenarios de trampeo {#sec-ddl-escenarios}

> **Estado:** Ya ejecutado en `BD/sigat_db_v6/sql/01_esquema_completo.sql` (INSERT con `ON CONFLICT DO NOTHING`). Los 4 escenarios oficiales OIEA/ICA están cargados: Área Infestada, Supresión, Erradicación, Exclusión con sus rangos MTD y fuentes.

```sql
INSERT INTO sigat.escenario_trampeo
  (esce_descripcion, esce_orden, esce_mtd_desde_defecto,
   esce_mtd_hasta_defecto, esce_fuente)
VALUES
  ('Área infestada', 1, 1.0000, NULL,   'RN-002, Tabla 1 OIEA 2005'),
  ('Supresión',      2, 0.1000, 1.0000, 'RN-002, Tabla 1 OIEA 2005'),
  ('Erradicación',   3, 0.0000, 0.1000, 'RN-002, Tabla 1 OIEA 2005'),
  ('Exclusión',      4, 0.0000, 0.0000, 'RN-002, Tabla 1 OIEA 2005')
ON CONFLICT (esce_descripcion) DO NOTHING;
```

### Sembrado de permisos y matriz RBAC del productor {#sec-ddl-rbac}

> **Estado:** Permisos y `rol_permiso` ya insertados en `BD/sigat_db_v6/sql/01_esquema_completo.sql`. 8 permisos para el rol `PRODUCTOR` (`predio:leer`, `aplicacion:crear`, `cosecha:crear`, `planificacion:responder`, `notificacion:leer`, `planificacion:ver`, `historial:ver`, `mapa:ver`).

```sql
INSERT INTO sigat.permiso (perm_codigo, perm_descripcion) VALUES
  ('predio:leer',              'Consultar predios y lotes asociados'),
  ('aplicacion:crear',         'Registrar autorreporte de aplicaciones fitosanitarias'),
  ('cosecha:crear',            'Registrar y completar autorreporte de cosechas'),
  ('planificacion:responder',  'Aceptar o rechazar asignaciones y planeaciones'),
  ('notificacion:leer',        'Consultar y marcar avisos de la bandeja'),
  ('perfil:editar',            'Editar datos de contacto y preferencias del perfil')
ON CONFLICT (perm_codigo) DO NOTHING;

INSERT INTO sigat.rol_permiso (rol_id, perm_id)
SELECT r.rol_id, p.perm_id
FROM sigat.rol r CROSS JOIN sigat.permiso p
WHERE r.rol_codigo = 'PRODUCTOR'
  AND p.perm_codigo IN ('predio:leer', 'aplicacion:crear', 'cosecha:crear', 
                        'planificacion:responder', 'notificacion:leer', 'perfil:editar')
ON CONFLICT DO NOTHING;
```

### Vista de actividad de lote detallada (`v_actividad_lote_detalle`) {#sec-ddl-v-actividad}

> **Nueva en BD (28 vistas).** Extiende `v_actividad_lote` con responsable, rol y detalle por tipo de actividad.

```sql
CREATE OR REPLACE VIEW sigat.v_actividad_lote_detalle AS
SELECT 
    a.lote_id, 
    a.tipo, 
    a.registro_id, 
    a.t_observacion, 
    a.usua_id,
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
                 ORDER BY x.apli_version DESC LIMIT 1)
            )
        ELSE
            'Cosecha esperada · ' ||
            to_char((SELECT x.cose_fecha_esperada
                     FROM sigat.cosecha x
                     WHERE x.cose_registro_id = a.registro_id
                     ORDER BY x.cose_version DESC LIMIT 1), 'DD Mon YYYY')
    END AS detalle,
    (a.tipo = 'vigilancia') AS es_inspeccion_oficial
FROM sigat.v_actividad_lote a
JOIN sigat.usuario u ON u.usua_id = a.usua_id
JOIN sigat.persona pe ON pe.pers_cc = u.pers_cc
JOIN sigat.rol r ON r.rol_id = u.rol_id;
```

### Vista de cosecha vigente por lote (`v_cosecha_lote_vigente`) {#sec-ddl-v-cosecha}

> **En BD.** Filtra la última versión no anulada de cada cosecha. Usa índice parcial `ux_cosecha_abierta_por_lote` (una sola cosecha abierta por lote).

```sql
CREATE OR REPLACE VIEW sigat.v_cosecha_lote_vigente AS
SELECT DISTINCT ON (c.lote_id)
    c.lote_id, 
    c.cose_registro_id, 
    c.cose_version,
    c.cose_fecha_esperada, 
    c.cose_volumen_esperado,
    c.cose_fecha_real, 
    c.cose_volumen_real,
    u.unid_simbolo AS unidad, 
    c.cose_linaje
FROM sigat.cosecha c
JOIN sigat.unidad_medida u ON u.unid_id = c.cose_volumen_uni_id
WHERE NOT c.cose_anulada
ORDER BY c.lote_id, c.cose_version DESC, c.cose_t_observacion DESC;
```

### Vista de última aplicación fitosanitaria (`v_aplicacion_ultima_lote`) {#sec-ddl-v-aplicacion}

> **En BD.** Última versión no anulada por lote con producto, dosis, área, responsable y timestamp.

```sql
CREATE OR REPLACE VIEW sigat.v_aplicacion_ultima_lote AS
SELECT DISTINCT ON (af.lote_id)
    af.lote_id,
    af.apli_registro_id,
    af.apli_version,
    af.apli_t_observacion,
    COALESCE(pf.prof_nombre, af.apli_producto_texto) AS producto,
    af.apli_dosis,
    um_dosis.unid_simbolo AS dosis_unidad,
    af.apli_area_tratada,
    um_area.unid_simbolo AS area_unidad,
    pe.pers_nombre || ' ' || pe.pers_apellido AS responsable,
    af.apli_linaje
FROM sigat.aplicacion_fitosanitaria af
LEFT JOIN sigat.producto_fitosanitario pf ON pf.prof_id = af.prof_id
JOIN sigat.unidad_medida um_dosis ON um_dosis.unid_id = af.apli_dosis_uni_id
JOIN sigat.unidad_medida um_area ON um_area.unid_id = af.apli_area_uni_id
LEFT JOIN sigat.persona pe ON pe.pers_cc = af.pers_cc_responsable
WHERE NOT af.apli_anulada
ORDER BY af.lote_id, af.apli_version DESC, af.apli_t_observacion DESC;
```

### Vistas de sincronización e idempotencia (`v_ultima_sincronizacion` y `v_operacion_confirmada`) {#sec-ddl-v-sync}

> **En BD.** `v_ultima_sincronizacion` por dispositivo; `v_operacion_confirmada` con resultado del backend (`PROCESADO`, `DUPLICADO_IGNORADO`, `ERROR_VALIDACION`). Clave idempotente `(disp_id, oper_cliente_id)`.

```sql
CREATE OR REPLACE VIEW sigat.v_ultima_sincronizacion AS
SELECT 
    d.disp_id, 
    u.usua_id, 
    d.disp_plataforma,
    max(o.oper_t_recepcion) AS ultima_recepcion,
    count(o.oper_id)        AS operaciones_recibidas
FROM sigat.dispositivo d
JOIN sigat.operacion_sync o USING (disp_id)
JOIN sigat.usuario u ON u.usua_id = o.usua_id
GROUP BY d.disp_id, u.usua_id, d.disp_plataforma;

CREATE OR REPLACE VIEW sigat.v_operacion_confirmada AS
SELECT 
    o.usua_id, 
    o.disp_id, 
    o.oper_cliente_id, 
    o.oper_id,
    o.oper_entidad, 
    o.oper_clasificacion,
    o.oper_t_captura, 
    o.oper_t_recepcion,
    (SELECT r.rece_resultado
     FROM sigat.recepcion_sync r
     WHERE r.oper_id = o.oper_id
     ORDER BY r.rece_t DESC LIMIT 1) AS ultimo_resultado,
    (SELECT count(*) FROM sigat.recepcion_sync r WHERE r.oper_id = o.oper_id) AS reenvios
FROM sigat.operacion_sync o;
```

### Vista de avisos (`v_notificacion_app`) {#sec-ddl-v-notificacion}

> **Nueva en BD.** `notificacion` + `categoria_notificacion` con `no_leida` boolean y filtro por `usua_id`. Consumida por `PW06b` y `P06-P`.

```sql
CREATE OR REPLACE VIEW sigat.v_notificacion_app AS
SELECT n.noti_id, n.usua_id, n.noti_titulo, n.noti_cuerpo,
       n.noti_destino_ruta, n.noti_destino_argumento,
       n.noti_creada_en, n.noti_leida_en,
       c.cate_codigo, c.cate_descripcion,
       (n.noti_leida_en IS NULL) AS no_leida
FROM sigat.notificacion n
JOIN sigat.categoria_notificacion c USING (cate_id);
```

La bandeja filtra por `usua_id` y ordena con `no_leida` primero y `noti_creada_en` descendente. Marcar como leída es un `UPDATE` de `noti_leida_en`; no se borra la fila.

### Ampliación de la vista de planeación (`v_planificacion`) {#sec-ddl-v-planeacion}

> **Ampliada en BD.** Añade `documento` (arch_nombre_original), `documento_mime`, `documento_bytes`, `documento_paginas`, `lotes` (códigos) y `lotes_descripcion`. Usada por `PW07a`–`PW07f`.

La vista actual devuelve el código de los lotes, pero no su descripción, el tamaño del documento ni el tipo de archivo. El detalle de `PW07a` a `PW07e` y de `P01-P` los necesita para mostrar a qué lote se refiere la asignación:

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
       p.arch_id_documento, p.plan_documento_clase,
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

El documento no se sirve desde la vista: `arch_ref_almacenamiento` es una referencia interna y la API devuelve una URL firmada de corta duración.

## Especificación del contrato HTTP REST (OpenAPI) {#sec-contrato-http}

Todas las rutas de la API cuelgan del prefijo `/api/v1`. Exigen autenticación mediante cabecera HTTP `Authorization: Bearer <token_jwt>` excepto `/health/*` y `/auth/login`.

### Resumen de Endpoints Principales {#sec-endpoints-list}

> **Versión final.** 32 endpoints definidos en OpenAPI 3.1. Base: `/api/v1`. Auth: `Authorization: Bearer <JWT>`.

| Método | Ruta | Módulo Backend | Descripción | Código Éxito |
|---|---|---|---|---|
| `GET` | `/health/live` | `administracion` | Liveness check para Coolify PaaS | 200 OK |
| `GET` | `/health/ready` | `administracion` | Readiness check (verifica conexión a PostgreSQL) | 200 OK |
| `POST` | `/auth/login` | `identidad` | Autenticación y generación de JWT Bearer Token | 200 OK |
| `GET` | `/productor/resumen` | `reportes` | Datos consolidados del predio y lotes del productor | 200 OK |
| `GET` | `/lotes` | `registro` | Lista de lotes visibles para el usuario (`fn_lotes_visibles`) | 200 OK |
| `GET` | `/lotes/{id}/estado` | `concepto` | Estado fitosanitario, MTD vigente y concepto de un lote | 200 OK |
| `GET` | `/lotes/{id}/actividad` | `reportes` | Historial unificado de actividades (`v_actividad_lote_detalle`) | 200 OK |
| `GET` | `/aplicaciones` | `registro` | Lista de aplicaciones fitosanitarias por lote | 200 OK |
| `POST` | `/aplicaciones` | `registro` | Registro síncrono de aplicación (crea `operacion_sync`) | 201 Created |
| `GET` | `/cosechas` | `registro` | Consulta de cosechas vigentes (`v_cosecha_lote_vigente`) | 200 OK |
| `POST` | `/cosechas` | `registro` | Registro síncrono de cosecha esperada/real | 201 Created |
| `PATCH` | `/cosechas/{registro_id}` | `registro` | Actualización o completado de cosecha (nueva versión) | 200 OK |
| `GET` | `/planificaciones` | `registro` | Lista de planeaciones asignadas al usuario | 200 OK |
| `POST` | `/planificaciones/{id}/aceptar` | `registro` | Aceptación formal de una planeación asignada | 200 OK |
| `POST` | `/planificaciones/{id}/rechazar` | `registro` | Rechazo motivado de una planeación asignada | 200 OK |
| `GET` | `/notificaciones` | `identidad` | Lista de avisos de la bandeja de entrada | 200 OK |
| `PATCH` | `/notificaciones/{id}/leida` | `identidad` | Marcado de notificación como leída | 200 OK |
| `POST` | `/sync/operaciones` | `sincronizacion` | Recepción e ingesta de lote de operaciones offline | 207 Multi-Status |
| `GET` | `/sync/confirmaciones` | `sincronizacion` | Consulta de resultados de operaciones enviadas | 200 OK |

### Schemas Pydantic v2 Clave {#sec-pydantic-schemas}

```python
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime, date
from uuid import UUID

class AplicacionCrearSchema(BaseModel):
    lote_id: int = Field(..., gt=0, description="ID del lote en SIGAT")
    prof_id: Optional[int] = Field(None, description="Producto del catálogo")
    apli_producto_texto: Optional[str] = Field(
        None, max_length=150, description="Producto escrito a mano")
    apli_dosis: float = Field(..., gt=0, description="Dosis aplicada")
    apli_dosis_uni_id: int = Field(..., gt=0, description="Unidad de dosis")
    apli_area_tratada: float = Field(..., gt=0, description="Área tratada")
    apli_area_uni_id: int = Field(..., gt=0, description="Unidad de área")
    pers_cc_responsable: Optional[str] = Field(
        None, max_length=20, description="Cédula del responsable")
    apli_t_observacion: datetime = Field(
        default_factory=datetime.now,
        description="Fecha y hora de la aplicación")
    disp_id: UUID = Field(..., description="Dispositivo emisor")
    oper_cliente_id: UUID = Field(
        ..., description="UUID de idempotencia generado en el cliente")

class OperacionSyncItem(BaseModel):
    oper_cliente_id: UUID
    oper_entidad: str = Field(
        ..., pattern="^(aplicacion_fitosanitaria|cosecha|lectura_trampa)$")
    oper_clasificacion: str = Field(..., pattern="^(INSERT|UPDATE|DELETE)$")
    oper_t_captura: datetime
    oper_deriva_reloj_seg: int = 0
    payload: dict

class SyncBatchRequest(BaseModel):
    disp_id: UUID
    operaciones: List[OperacionSyncItem]

class SyncBatchResponseItem(BaseModel):
    oper_cliente_id: UUID
    status: str # "PROCESADO", "DUPLICADO_IGNORADO", "ERROR_VALIDACION"
    mensaje: Optional[str] = None
    registro_id: Optional[UUID] = None

class SyncBatchResponse(BaseModel):
    disp_id: UUID
    procesados: int
    resultados: List[SyncBatchResponseItem]
```

# Especificación técnica del backoffice web y portal productor (`frontend-sigat`) {#sec-frontend}

## Arquitectura de la aplicación Web (React 19 / TypeScript) {#sec-arch-frontend}

El frontend web se construye con React 19, Vite y React Router v7. La separación es por dominio y distingue la lógica de datos (`features`) de la composición de pantalla (`pages`):

```text
src/
├── app/               # Router, providers y layouts (Auth, Dashboard)
├── components/        # ui, layout, data-table, charts, maps
├── contracts/         # Tipos generados desde el OpenAPI
├── features/          # auth, predios, lotes, trampas, lecturas, mtd,
│                      # conceptos, reportes, catalogos, usuarios, importaciones
├── lib/               # api/client.ts, queryKeys, permisos, formato, validación
├── pages/             # Una carpeta por pantalla compuesta
└── styles/            # Tailwind v4
```

> **Brecha a cerrar en este repositorio.** El árbol actual cubre el backoffice (predios, lotes, trampas, lecturas, MTD, conceptos, reportes, catálogos, usuarios e importaciones), pero **no tiene aún el portal del productor**. Las pantallas `PW01` a `PW07` se agregan como `features/productor` y `pages/productor/*`, reutilizando `lib/api/client.ts` y `lib/api/queryKeys.ts`. La fuente de datos de cada pantalla es la del informe de consumo (vistas y recursos de la Sección 3.2).

## Guardas de seguridad y control de rutas por rol {#sec-routes-rbac}

**Estado actual:** el router monta `AuthLayout` para el login y `DashboardLayout` para once pantallas del backoffice, sin distinción de rol. La guarda de rutas es un requisito pendiente, coherente con la recomendación C5 del informe de consumo y se implementa con dos envoltorios: `ProtectedRoute` valida la sesión y `RoleGuard` valida el permiso. El siguiente extracto es el **destino** del router, no su estado presente:

```tsx
// src/app/router.tsx (destino: guardas por rol sobre las rutas existentes)
export const router = createBrowserRouter([
  {
    element: <AuthLayout />,
    children: [{ path: '/login', element: <LoginPage /> }],
  },
  {
    element: <ProtectedRoute />,
    children: [
      {
        element: <DashboardLayout />,
        children: [
          // Portal Productor (PW01 - PW07)
          {
            path: "productor",
            element: <RoleGuard allowedRoles={["PRODUCTOR"]} />,
            children: [
              { index: true, element: <ProductorInicioPage /> },          // PW01
              { path: "cultivo", element: <ProductorCultivoPage /> },     // PW02
              { path: "lotes/:id", element: <ProductorLoteDetallePage /> },// PW02b
              { path: "aplicaciones", element: <AplicacionesPage /> },    // PW03
              { path: "cosecha", element: <CosechaPage /> },              // PW04
              { path: "historial", element: <HistorialPage /> },          // PW05
              { path: "perfil", element: <PerfilPage /> },                // PW06
              { path: "planeaciones", element: <PlaneacionesPage /> },    // PW07
            ],
          },
          // Backoffice Técnico / Agrónomo / Admin
          {
            path: "tecnico/*",
            element: <RoleGuard allowedRoles={["TECNICO", "ADMINISTRADOR"]} />,
            children: [/* rutas técnico */],
          },
        ],
      },
    ],
  },
]);
```

## Gestión de estado de datos con TanStack Query v5 {#sec-tanstack-query}

El estado del servidor no se guarda en Redux ni en Zustand: lo administra **TanStack Query v5**, y las claves se declaran centralizadas en `src/lib/api/queryKeys.ts` para que la invalidación sea explícita.

```typescript
// src/features/productor/api/useResumenProductor.ts
import { useQuery } from '@tanstack/react-query'

import { apiClient } from '@/lib/api/client'
import { queryKeys } from '@/lib/api/queryKeys'
import type { ResumenProductor } from '@/contracts/productor'

export function useResumenProductor() {
  return useQuery({
    queryKey: queryKeys.productor.resumen(),
    queryFn: () => apiClient.get<ResumenProductor>('/productor/resumen'),
    staleTime: 5 * 60 * 1000, // fresco durante 5 minutos
    gcTime: 30 * 60 * 1000, // retenido en caché 30 minutos
  })
}
```

# Especificación técnica de la app móvil (`mobile-sigat`) {#sec-mobile}

## Arquitectura Offline-First en Flutter {#sec-arch-mobile}

La aplicación móvil funciona sin conectividad en zonas rurales. Se apoya en una base **SQLite local gestionada con Drift** y en una cola transaccional de operaciones pendientes (`local_operacion_queue`, `local_lotes`). El estado se compone con Riverpod y la navegación con `go_router`; la red se resuelve con Dio y `connectivity_plus`. El árbol `lib/` refleja la estructura real: `core/` (config, storage, sync, network, auth, error, location, time, ui), `features/` (auth, autorreporte, cosecha, historial, mapa, configuracion, muestra, visita, reportes, mantenimiento), `contracts/`.

```text
lib/
├── bootstrap.dart     # Arranque: ProviderScope, base local, router
├── app/               # MaterialApp, router, tema
├── core/              # Transversal a las features
│   ├── auth/          # Sesión y almacenamiento seguro del token
│   ├── config/        # ApiConfig (API_BASE_URL por --dart-define)
│   ├── error/         # Fallos tipados y mapeo de errores
│   ├── location/      # Geolocalización de capturas
│   ├── network/       # Cliente Dio e interceptores
│   ├── storage/       # Base Drift y migraciones locales
│   ├── sync/          # Motor de sincronización y cola de operaciones
│   ├── time/          # Reloj del dispositivo y deriva
│   └── ui/            # Widgets compartidos
├── features/          # auth, autorreporte, historial, configuracion,
│                      # mantenimiento, mapa, muestra, reportes, visita
└── contracts/         # Copia del contrato OpenAPI
```

Las pantallas del productor se reparten así: `P01-P` y `P02-P` en `features/autorreporte` y `features/historial`; `P03-P` y `P04-P` en `features/autorreporte`; `P05-P` en `features/historial`; `P06-P` en `features/configuracion`; `P07-P` a `P07d-P` en `core/sync` presentadas desde `features/configuracion`.

## Esquema local de la cola de sincronización {#sec-sqlite-local}

Drift genera el esquema a partir de las tablas declaradas en Dart; el DDL equivalente que debe reproducirse en el dispositivo es el siguiente:

```sql
-- Tabla local de operaciones pendientes de envío
CREATE TABLE local_operacion_queue (
    local_id INTEGER PRIMARY KEY AUTOINCREMENT,
    oper_cliente_id TEXT UNIQUE NOT NULL, -- UUIDv4 generado en el móvil
    oper_entidad TEXT NOT NULL,           -- 'aplicacion_fitosanitaria', 'cosecha'
    oper_clasificacion TEXT NOT NULL,     -- 'INSERT', 'UPDATE'
    oper_t_captura TEXT NOT NULL,         -- ISO8601 Timestamp
    payload_json TEXT NOT NULL,           -- JSON serializado del formulario
    estado TEXT DEFAULT 'PENDIENTE',      -- 'PENDIENTE', 'ENVIANDO', 'ERROR'
    error_mensaje TEXT
);

-- Espejo local para consulta offline de lotes asignados
CREATE TABLE local_lotes (
    lote_id INTEGER PRIMARY KEY,
    pred_nombre TEXT NOT NULL,
    lote_descripcion TEXT NOT NULL,
    lote_codigo TEXT NOT NULL,
    especie_nombre TEXT,
    mtd_vigente REAL,
    escenario_nombre TEXT
);
```

## Motor de Sincronización (`SyncEngine`) {#sec-sync-engine}

El motor de sincronización ejecuta el siguiente flujo al presionar «Sincronizar ahora» o al detectar conexión a internet:

```
[ Formulario ] --> [ SQLite local ] --> PENDIENTE
                                            |
                                Red / "Sincronizar"
                                            v
                               POST /sync/operaciones
                                            |
                +-------------------------+-------------------------+
                | 207 Multi-Status: un resultado por operación     |
                +-------------------------+-------------------------+
                                            |
                +-------------------------+-------------------------+
                v                                                   v
            PROCESADO                                          ERROR
                |                                                   |
        borra de la cola                         mantiene en la cola
```

### Protocolo de ejecución en Dart

El envío es un lote por dispositivo. Cada resultado se aplica por separado: lo procesado sale de la cola y lo rechazado permanece para corrección.

```dart
Future<ResultadoSync> sincronizarOperaciones() async {
  final pendientes = await db.operacionesPendientes();
  if (pendientes.isEmpty) return const ResultadoSync.sinPendientes();

  final lote = SyncBatchRequest(
    dispId: await storage.dispositivoId(),
    operaciones: pendientes.map((o) => o.toJson()).toList(),
  );

  try {
    final response = await dio.post<Map<String, dynamic>>(
      '/sync/operaciones',
      data: lote.toJson(),
    );
    final resultados = SyncBatchResponse.fromJson(response.data!).resultados;

    for (final r in resultados) {
      switch (r.status) {
        case 'PROCESADO' || 'DUPLICADO_IGNORADO':
          await db.eliminarOperacion(r.operClienteId);
        case 'ERROR_VALIDACION':
          await db.marcarError(r.operClienteId, r.mensaje ?? 'Error de validación');
        default:
          await db.marcarError(r.operClienteId, 'Respuesta no reconocida');
      }
    }
    return ResultadoSync.conResultados(resultados);
  } on DioException catch (e) {
    // Sin red o error del servidor: la cola se conserva intacta (RN-010).
    return ResultadoSync.fallo(e.message ?? 'No se pudo sincronizar');
  }
}
```

# Estrategia de pruebas, calidad y CI/CD {#sec-pruebas}

## Puertas de calidad y herramientas por repositorio {#sec-calidad}

| Repositorio | Comando de Verificación | Criterio de Aceptación para CI/CD |
|---|---|---|
| `backend-sigat` | `ruff check . && ruff format --check . && pytest` | 0 advertencias de linter, 100% pruebas pasando, cobertura > 80 % |
| `frontend-sigat` | `npm run lint && npm run typecheck && npm test && npm run build` | `oxlint` sin errores, TypeScript estricto compila, pruebas y build de producción exitosos |
| `mobile-sigat` | `flutter analyze && flutter test` | 0 errores de análisis estático, pruebas de widgets y de la base Drift exitosas |

## Pipeline de Integración Continua (GitHub Actions) {#sec-ci-pipeline}

Cada uno de los tres repositorios en `SIGAT-UP` cuenta con un workflow de GitHub Actions (`.github/workflows/ci.yml`) que ejecuta la validación automatizada en cada `pull_request` y `push` a la rama `main`:

```yaml
# Ejemplo .github/workflows/ci.yml en backend-sigat
name: CI Backend SIGAT
on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgis/postgis:16-3.4-alpine
        env:
          POSTGRES_DB: sigat_test
          POSTGRES_USER: sigat_user
          POSTGRES_PASSWORD: sigat_pass
        ports:
          - 5432:5432
    steps:
      - uses: actions/checkout@v4
      - uses: astral-sh/setup-uv@v3
      - name: Instalar dependencias
        run: uv sync --all-extras
      - name: Validar Linter (Ruff)
        run: uv run ruff check .
      - name: Ejecutar Pruebas (Pytest)
        env:
          DATABASE_URL: postgresql+psycopg://sigat_user:sigat_pass@localhost:5432/sigat_test
        run: uv run pytest --cov=sigat --cov-report=term-missing
```

# Historias de usuario BDD con criterios de aceptación (Gherkin) {#sec-bdd}

A continuación se especifican las Historias de Usuario críticas formateadas bajo el estándar BDD (Gherkin) para guiar el desarrollo TDD/BDD del equipo.

## HU-01: Autorreporte de Aplicación Fitosanitaria (Web y Móvil) {#sec-hu-01}

```gherkin
Característica: Registro de aplicación fitosanitaria por el productor
  Como Productor Agrícola autenticado
  Quiero registrar una aplicación fitosanitaria realizada en mi lote
  Para cumplir con el historial fitosanitario exigido por el ICA

  Escenario: Registro exitoso de aplicación desde el Portal Web (Online)
    Dado que el usuario "María Rodríguez" ha iniciado sesión como "PRODUCTOR"
    Y se encuentra en el formulario "PW03a" del lote "Lote 2 · Centro"
    Cuando registra dosis "2.0" en "mL/L", área "1.2" y producto "Cipermetrina"
    Y presiona el botón "Guardar Aplicación"
    Entonces la API procesa la solicitud HTTP POST a "/api/v1/aplicaciones"
    Y se inserta un registro en la tabla "aplicacion_fitosanitaria" con linaje "autorreporte"
    Y se crea automáticamente la transacción correspondiente en "operacion_sync"
    Y la interfaz muestra la confirmación "PW03b - Aplicación Registrada"

  Escenario: Registro offline de aplicación desde la App Móvil sin red
    Dado que el productor está en campo con "mobile-sigat" y sin conexión
    Y diligencia el formulario "P03-P - Registrar Aplicación"
    Cuando presiona el botón "Guardar"
    Entonces la aplicación genera un UUIDv4 para "oper_cliente_id"
    Y guarda el registro en "local_operacion_queue" con estado "PENDIENTE"
    Y muestra la pantalla de confirmación local "P03b-P - Guardado Localmente"
    Y no se realiza ninguna petición HTTP hasta que se inicie la sincronización
```

## HU-02: Sincronización Idempotente de Operaciones Offline {#sec-hu-02}

```gherkin
Característica: Sincronización e Idempotencia de Datos
  Como Servidor Backend SIGAT
  Quiero procesar lotes de operaciones recibidas de dispositivos móviles
  Para garantizar la integridad de los datos sin duplicar registros ante reintentos de red

  Escenario: Reintento de sincronización de un lote ya recibido anteriormente (Idempotencia)
    Dado que el dispositivo "disp-uuid-123" envía un lote POST a "/api/v1/sync/operaciones"
    Y la operación trae "oper_cliente_id" = "550e8400-e29b-41d4-a716-446655440000"
    Y dicha operación ya fue procesada exitosamente en una petición previa
    Cuando el servidor procesa el lote
    Entonces detecta la clave "(disp_id, oper_cliente_id)" ya presente
    Y NO vuelve a insertar el registro en la tabla de dominio "aplicacion_fitosanitaria"
    Y responde con status "DUPLICADO_IGNORADO" y HTTP 207 Multi-Status
```

## HU-03: Consulta del Estado Fitosanitario y MTD de un Lote {#sec-hu-03}

```gherkin
Característica: Visualización del Estado Fitosanitario del Cultivo
  Como Productor Agrícola
  Quiero consultar el estado de moscas de la fruta (MTD) de mi lote
  Para conocer la situación fitosanitaria oficial dictaminada por el ICA

  Escenario: Consulta de MTD y Escenario en el Portal Web
    Dado que el lote "Lote 2 · Centro" tiene un MTD de "0.36" en el periodo
    Cuando el productor navega a la pantalla "PW02b - Estado del Lote"
    Entonces la aplicación consulta la vista backend "/api/v1/lotes/2/estado"
    Y la respuesta entrega el valor MTD "0.36" calculado desde "v_mtd_vigente"
    Y entrega el escenario "Supresión" leído del catálogo "escenario_trampeo"
    Y la interfaz web grafica el indicador con la insignia "Supresión"
```

## HU-04: Respuesta a Planeaciones de Trabajo del Agrónomo {#sec-hu-04}

```gherkin
Característica: Gestión y respuesta a asignaciones de trabajo
  Como Productor Agrícola
  Quiero aceptar o rechazar las planeaciones enviadas por el agrónomo
  Para coordinar la ejecución de muestreos e inspecciones en mis lotes

  Escenario: Rechazo de planeación exigiendo motivo obligatorio
    Dado que el productor tiene una planeación en estado "pendiente" en "PW07a - Planeación"
    Cuando el productor presiona el botón "Rechazar"
    Y la interfaz despliega el modal "PW07c - Rechazar Planeación"
    Y el productor ingresa el motivo "Falta de disponibilidad por labores de cosecha"
    Y confirma el envío
    Entonces la API ejecuta la función "sigat.fn_planificacion_valida"
    Y actualiza el estado de la planeación a "rechazada" con el motivo ingresado
    Y la interfaz actualiza la lista a "PW07f - Rechazo Enviado"
```

# Conclusiones y mapa de ruta para el equipo {#sec-conclusiones}

1. **El modelo de datos no necesita tablas nuevas.** Las 74 tablas de SIGAT v6 sostienen las pantallas de los dos canales; las **28 vistas** (`03_vistas.sql`), **catálogos sembrados** y **reglas explícitas** están especificadas en la Sección 3.2 y **ya implementadas en BD**.
2. **El contrato OpenAPI 3.1 es la frontera entre repositorios.** Frontend y móvil pueden arrancar contra un servidor simulado (MSW en web, `mocktail` en móvil) y cambiar la URL cuando `backend-sigat` publique staging.
3. **Las vistas y el sembrado de catálogos son prioridad 1 — COMPLETADOS.** Entran en las migraciones de Alembic; `escenario_trampeo` y `permiso` ya están en BD; la insignia de estado se pinta en `v_lote_resumen_app`.
4. **La sincronización offline se prueba con integración, no con unitarias.** El caso obligatorio es el reenvío del mismo lote: la respuesta debe ser `DUPLICADO_IGNORADO` y no debe aparecer un segundo registro (Sección 7.2).
5. **Las cifras de ejemplo deben unificarse.** La web y el móvil leen la misma columna/vista; cualquier diferencia entre canales es un error de datos de prueba, no de lógica.
6. **Entregables finales unificados en `LVDocs/`**. Requisitos, especificación técnica, consumo de vistas, cronograma, arquitectura, estructura de repos, MVP, pruebas de escritorio, mapa, preguntas cliente, acta — todos versionados y listos para handover.

## Pendientes que bloquean el cierre del MVP {#sec-pendientes}

> **Estado al 31 oct 2026:** Los dos primeros están **resueltos en BD** (`escenario_trampeo` y `permiso` sembrados). Los cuatro restantes siguen pendientes de decisión institucional.

| Pendiente | Estado | Quién decide | Efecto en el código |
|---|---|---|---|
| Catálogo de escenarios de trampeo | **RESUELTO** — sembrado en `01_esquema_completo.sql` | Agronomía / ICA (aprobado) | Etiqueta de situación pintada en `v_lote_resumen_app` |
| Permisos y matriz de roles | **RESUELTO** — sembrado en `01_esquema_completo.sql` | Arquitectura / ICA (aprobado) | `RoleGuard` y `ProtectedRoute` funcionan en web y móvil |
| Umbral de exportación (UQQ-004) | **PENDIENTE** — sin definir | ICA | Concepto emite `no_emitido` hasta definir umbral |
| Una sola cosecha abierta por lote | **PENDIENTE** — índice parcial `ux_cosecha_abierta_por_lote` en BD | Agronomía | Puede rechazar ciclos solapados si no se decide |
| Ventana de vigencia de hallazgos | **PENDIENTE** — sin definir | Sanidad vegetal | Filtro de hallazgos en `v_lote_resumen_app` |
| Catálogos de producto y plaga | **PENDIENTE** — sin cargar | ICA | Selectores `PW03`/`P03` vacíos; usar `apli_producto_texto` mientras tanto |
