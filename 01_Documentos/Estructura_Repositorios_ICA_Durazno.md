---
title: "Estructura de repositorios y patrones de diseño"
subtitle: "Backend modular, aplicación móvil offline-first y backoffice web en React"
author: "Equipo de Arquitectura de Software"
date: "23 de octubre de 2026"
lang: es-CO
---

# Resumen ejecutivo {#sec-resumen}

> **Decisión.** El sistema se organiza en **tres repositorios de código** —`ica-durazno-api`, `ica-durazno-app` e `ica-durazno-web`— unidos por un único contrato OpenAPI. El backend es un monolito modular; el móvil es una aplicación Flutter offline-first; la web es un backoffice interno en React + TypeScript + Vite. Ningún frontend tiene base de datos propia ni duplica reglas de negocio.

Esta estructura mantiene las decisiones ADR-14 (monolito modular con fronteras de microservicio) y ADR-16 (repositorios de solo código unidos por el contrato) y las extiende con **ADR-18**: la web es un tercer cliente del mismo backend, no un segundo backend.

| Repositorio | Stack | Responsabilidad | Lo que no debe tener |
|---|---|---|---|
| `ica-durazno-api` | Python + FastAPI | Dominio, reglas, persistencia, sincronización, autorización, reportes, importación histórica | Lógica de UI, HTML, clientes móviles o web |
| `ica-durazno-app` | Flutter + Dart | Captura en campo, mapa, SQLite espacial, cola de envío, operación sin red | Reglas de negocio duplicadas, acceso directo a PostgreSQL |
| `ica-durazno-web` | React + TypeScript + Vite | Backoffice: predios, lotes, trampas, lecturas, MTD, catálogos, usuarios, reportes, importación | Base de datos propia, cálculo duplicado del MTD |

**Por qué tres repositorios y no un monorepo.** Python, Dart y TypeScript tienen toolchains, ciclos de vida y cadenas de integración distintos. Un monorepo agregaría coordinación de versiones y CI sin compartir código de negocio: lo único que realmente comparten los tres es el contrato HTTP. Separarlos permite que el móvil se actualice en campo con su propio ritmo, que la web despliegue varias veces al día y que la API mantenga compatibilidad hacia atrás.

# Contexto y restricciones {#sec-contexto}

## Decisiones que enmarcan la estructura {#sec-decisiones-marco}

| Decisión | Qué fija | Efecto en la estructura |
|---|---|---|
| **ADR-14** | Monolito modular con fronteras de microservicio | El backend es un solo despliegue; los módulos son carpetas con contrato y datos propios |
| **ADR-16** | Repositorios de solo código unidos por OpenAPI | No hay documentos, ADR ni diagramas dentro de los repos de código |
| **ADR-18** | Tercer repositorio para el backoffice web | La web consume la misma API; no hay backend ni base de datos para web |
| **ADR-13** | El MTD se calcula en el servidor | La web y el móvil muestran; no calculan ni emiten conceptos |
| **ADR-03** | Mediciones append-only con versiones | La web no edita lecturas: crea correcciones versionadas |
| **ADR-17** | Fronteras y contrato verificados en CI | `import-linter`, contract diff y pruebas bloquean fusiones |

## Restricciones del proyecto {#sec-restricciones}

- **Un solo backend.** La API es la única puerta a PostgreSQL/PostGIS, a la cola y al almacenamiento de objetos.
- **Dos clientes con ciclos distintos.** El móvil opera sin red y permanece meses instalado; la web es un backoffice con sesión y red permanente.
- **Un contrato, dos generadores.** El backend publica `openapi.json`; el móvil genera Dart y la web genera TypeScript.
- **La web es interna.** No necesita SEO ni renderizado en servidor; por eso React + Vite es suficiente. Si se convierte en portal público, se evalúa Next.js sin cambiar la organización por features.
- **Los documentos no viven en los repos de código.** Este documento y los ADR forman parte de la entrega documental.

## Supuestos {#sec-supuestos}

1. La web es un **backoffice interno del ICA** para administradores, supervisores y personal técnico; no es un portal para productores ni un sitio público.
2. El equipo adopta **React 19 + TypeScript** y acepta Vite como herramienta de construcción.
3. La autenticación institucional se resuelve con OIDC/JWT; la API sigue siendo la autoridad de autorización.
4. El equipo de móvil mantiene Flutter y la base local espacial; no se migra a otra tecnología.
5. La importación de los `.xls` históricos se hará por un módulo del backend y una pantalla de la web, no por scripts manuales en producción.

# Topología de repositorios {#sec-topologia}

```text
┌─────────────────────┐        ┌─────────────────────┐
│  ica-durazno-app    │        │  ica-durazno-web    │
│  Flutter / Dart     │        │  React / TypeScript │
│  offline-first      │        │  backoffice ICA     │
└──────────┬──────────┘        └──────────┬──────────┘
           │                              │
           │        HTTPS + OpenAPI       │
           └──────────────┬───────────────┘
                          │
                 ┌────────▼────────┐
                 │ ica-durazno-api │
                 │ Python/FastAPI  │
                 │ monolito modular│
                 └────────┬────────┘
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
  PostgreSQL/PostGIS   Cola interna    Object storage
```

## Fronteras y responsabilidades {#sec-fronteras}

| Frontera | Qué cruza | Qué no cruza |
|---|---|---|
| Móvil → API | Contrato OpenAPI, JWT, operaciones de sincronización | SQL, reglas de MTD, acceso a tablas |
| Web → API | Contrato OpenAPI, JWT/OIDC, consultas y comandos administrativos | SQL, cálculos de negocio, estado de otro cliente |
| API → PostgreSQL | Repositorios y unit of work | Entidades de dominio expuestas al cliente |
| API → almacenamiento | Referencias y URLs firmadas | Binarios dentro de la base de datos |
| API → cola | Trabajos internos (reproceso, imágenes, avisos) | Cola expuesta a los frontends |

## Por qué no un monorepo {#sec-monorepo}

Un monorepo sería razonable si los tres proyectos compartieran lenguaje y librerías. Aquí no: Flutter usa Dart, la API Python y la web TypeScript. Las únicas ventajas serían una raíz común y un `README` compartido; los costos serían un CI que instala tres toolchains, acoplamiento de versiones y PRs que mezclan cambios de mobile con cambios de API. La separación por repositorio sigue la frontera real de despliegue y de ciclo de vida.

Si en el futuro la web y la API comparten tipos, se comparte el **contrato generado**, no un paquete de código. Un paquete TypeScript compartido entre web y API acoplaría el backend a las decisiones de React.

# Backend: `ica-durazno-api` {#sec-backend}

## Estructura de carpetas {#sec-backend-tree}

```text
ica-durazno-api/
├── pyproject.toml
├── uv.lock
├── Dockerfile
├── compose.yaml
├── alembic.ini
├── .github/workflows/ci.yml
├── migrations/
├── contracts/
│   └── openapi.json              # generado; artefacto publicado
├── src/ica_api/
│   ├── main.py
│   ├── app.py
│   ├── api/
│   │   ├── deps.py               # auth, DB, paginación
│   │   ├── errors.py             # formato único de error
│   │   └── v1/
│   │       ├── router.py
│   │       └── routes/           # routers delgados; llaman casos de uso
│   ├── core/
│   │   ├── config.py
│   │   ├── security/
│   │   ├── logging.py
│   │   ├── time.py
│   │   └── pagination.py
│   ├── modules/
│   │   ├── identidad/
│   │   ├── sincronizacion/
│   │   ├── registro/
│   │   ├── configuracion/
│   │   ├── imagenes/
│   │   ├── concepto/
│   │   ├── reportes/
│   │   ├── administracion/
│   │   └── importacion/
│   ├── infra/
│   │   ├── db/                   # engine, sesión, tipos, unit of work
│   │   ├── queue/
│   │   ├── storage/
│   │   ├── geo/
│   │   └── observability/
│   └── kernel/                   # solo primitivas: IDs, errores, reloj
├── tests/
│   ├── unit/
│   ├── integration/
│   ├── contract/
│   └── e2e/
├── scripts/
└── README.md
```

## Anatomía de un módulo {#sec-backend-modulo}

```text
modules/registro/
├── domain/
│   ├── entities/                 # Lectura, Periodo, IndiceMTD
│   ├── value_objects/            # CantidadMoscas, Version, FechaObservacion
│   ├── services/                 # CalculoMTD, ReglaVersionado
│   ├── events/                   # LecturaRegistrada, MTDRecalculado
│   └── ports/                    # interfaces: LecturaRepository, Clock
├── application/
│   ├── use_cases/                # RegistrarLectura, CorregirLectura, CalcularMTD
│   ├── dto/
│   └── handlers/
├── infrastructure/
│   ├── persistence/              # SQLAlchemy, repositorios concretos
│   ├── geo/                      # adaptadores PostGIS
│   └── messaging/                # outbox
├── api/
│   ├── router.py
│   └── schemas.py
└── tests/
```

La regla de dependencia es estricta:

```text
api → application → domain
infrastructure → application/domain
domain → nada (ni FastAPI, ni SQLAlchemy, ni PostGIS)
```

`import-linter` verifica que un módulo no importe otro fuera de su contrato. Un módulo solo puede importar de sí mismo, de `api/` y de `infra/`; las dependencias apuntan hacia `domain`.

## Módulos y responsabilidades {#sec-backend-modulos}

| Módulo | Responsabilidad | Contenedor C4 |
|---|---|---|
| `identidad` | Usuarios, roles, predios asignados, autenticación OIDC/JWT | Nuevo; transversal |
| `sincronizacion` | Recepción, clasificación, idempotencia, cola de reproceso | 3 |
| `registro` | Motor temporal, versionado, validación de invariantes, bitácora | 4 |
| `configuracion` | Programa de inspección, catálogos, retícula | 5 |
| `imagenes` | Mosaicos, fotografías, evidencia, almacenamiento de objetos | 6 |
| `concepto` | MTD, umbral, concepto de aptitud e histórico | 7 |
| `reportes` | Vistas de lectura, filtros, exportaciones | Nuevo; CQRS-lite |
| `administracion` | CRUD de predios, lotes, trampas y catálogos para la web | Nuevo; soporte al backoffice |
| `importacion` | Carga histórica de MF_UBI/MF_CAP, staging y validación | Nuevo; anti-corruption layer |

Los módulos nuevos no son microservicios: son carpetas dentro del mismo despliegue. `reportes` y `administracion` pueden empezar como casos de uso delgados y crecer solo cuando tengan carga propia.

## Superficie HTTP {#sec-backend-api}

Una sola API versionada, con recursos y permisos por rol:

```text
/api/v1/auth/*
/api/v1/sync/operaciones
/api/v1/predios
/api/v1/lotes
/api/v1/trampas
/api/v1/visitas
/api/v1/lecturas
/api/v1/mtd
/api/v1/conceptos
/api/v1/catalogos
/api/v1/reportes
/api/v1/archivos
/api/v1/usuarios
/api/v1/importaciones
```

La app móvil usa sobre todo `sync`, `visitas`, `lecturas` y `catalogos`; la web usa `predios`, `lotes`, `trampas`, `reportes`, `usuarios` e `importaciones`. Ambas comparten autenticación y autorización. Si la app necesita un paquete optimizado para operar sin red, se agrega un **read model** `/api/v1/mobile/bootstrap`; no se duplica la API.

## Patrones del backend {#sec-backend-patrones}

| Patrón | Dónde | Para qué | Anti-patrón evitado |
|---|---|---|---|
| **Monolito modular / vertical slices** | `modules/` | Un despliegue, fronteras ejecutables | Microsservicios prematuros |
| **Hexagonal / ports & adapters** | Cada módulo | Dominio puro; FastAPI, PostgreSQL, S3 y cola son adaptadores | Dominio acoplado al ORM |
| **Repository + Unit of Work** | `infrastructure/persistence` | Persistencia por agregado y transacción por caso de uso | SQL disperso en routers |
| **Use case / application service** | `application/use_cases` | Orquestar; nada de lógica en el router | Routers gordos |
| **DTO + Mapper** | `api/schemas` ↔ `domain` | No exponer entidades ni acoplar la API al ORM | Devolver modelos SQLAlchemy |
| **Strategy** | Clasificación de sincronización, cálculo MTD, proveedor de identidad | Variantes sin `if` por predio o cliente | Condicionales por predio |
| **State machine** | Estado de visita, operación de sync, concepto | Transiciones válidas explícitas | Estados como texto libre |
| **Domain events + transactional outbox** | Notificaciones, recálculo de MTD, auditoría | Efectos secundarios sin perder transacciones | Enviar correo dentro de la transacción |
| **Idempotent consumer** | `modules/sincronizacion` | Reintentos del celular sin duplicar | Duplicados por reintento |
| **Anti-corruption layer** | `modules/importacion` | Aislar los `.xls` históricos y el esquema `sigat_imp` | Cargar `.xls` directo al dominio |
| **CQRS-lite** | `modules/reportes` | Vistas de lectura para web; no CQRS completo | Reportes sobre tablas transaccionales |
| **Policy / specification** | Autorización y filtros por predio/rol | Seguridad y consultas componibles | Filtrar solo en la UI |

## Flujo de una operación de sincronización {#sec-backend-sync}

```text
Celular
  └── POST /api/v1/sync/operaciones (lote, id_cliente, hash)
        └── sincronizacion: idempotencia + clasificación
              ├── alta_nueva → registro: caso de uso RegistrarLectura
              ├── alta_retroactiva → registro: insertar en posición real
              ├── correccion → registro: nueva versión
              ├── revisar → cola de revisión humana
              └── rechazada → respuesta con motivo
        └── outbox: evento LecturaRegistrada
              ├── concepto: recalcular MTD afectado
              └── reportes: invalidar proyección
```

La respuesta al celular incluye el estado por operación y la versión del servidor. La web consulta el resultado por las vistas de `reportes`; no participa en la sincronización.

# Móvil: `ica-durazno-app` {#sec-movil}

## Estructura de carpetas {#sec-movil-tree}

```text
ica-durazno-app/
├── pubspec.yaml
├── analysis_options.yaml
├── lib/
│   ├── main.dart
│   ├── bootstrap.dart
│   ├── app/
│   │   ├── app.dart
│   │   ├── router.dart
│   │   ├── theme/
│   │   └── l10n/
│   ├── core/
│   │   ├── auth/
│   │   ├── config/
│   │   ├── error/
│   │   ├── network/
│   │   ├── storage/              # SQLite/Drift + extensión espacial
│   │   ├── sync/                 # outbox, cola, conectividad, scheduler
│   │   ├── location/
│   │   ├── time/
│   │   └── ui/                   # design system
│   ├── features/
│   │   ├── auth/
│   │   ├── visita/
│   │   │   ├── data/             # DTO, DAO local, API remota, repo impl
│   │   │   ├── domain/           # entidades, repositorio, casos de uso
│   │   │   └── presentation/     # páginas, controladores, widgets
│   │   ├── mapa/
│   │   ├── historial/
│   │   ├── reportes/
│   │   ├── autorreporte/
│   │   └── configuracion/
│   └── contracts/                # cliente Dart generado desde OpenAPI
├── test/
├── integration_test/
├── assets/
├── tool/
└── l10n/
```

## Capas y reglas {#sec-movil-capas}

| Capa | Contiene | Regla |
|---|---|---|
| `presentation` | Páginas, widgets, controladores de estado | No accede a SQL ni a HTTP directamente |
| `domain` | Entidades, repositorios abstractos, casos de uso | No importa Flutter ni paquetes de infraestructura |
| `data` | DTOs, DAOs, clientes remotos, implementaciones | Implementa los puertos de `domain` |
| `core` | Infraestructura transversal | No conoce features concretos |
| `contracts` | Cliente generado | No se edita a mano |

## Offline-first {#sec-movil-offline}

```text
Pantalla
  └── caso de uso
        └── repositorio local (SQLite)  ← fuente de verdad en campo
              ├── lee/escribe entidad local
              └── encola operación en outbox
                    └── sincronizador (red disponible)
                          └── POST /sync/operaciones
                                └── servidor idempotente
                                      └── respuesta: versión/estado
```

Reglas:

1. **La base local es la fuente de verdad en campo.** La pantalla no espera a la red para mostrar el dato.
2. **Toda escritura genera una operación de outbox** con `id_cliente`, `registro_id`, versión y hash.
3. **El servidor es la autoridad del orden temporal y del MTD.** El móvil muestra una estimación marcada como no normativa (ADR-13/ADR-15).
4. **La base local no replica las 74 tablas.** Contiene catálogos, predios/lotes visibles, trampas, visitas, lecturas, cola de salida y metadatos de sync.
5. **La sincronización es reintentable.** Un fallo de red no pierde la operación; el outbox se reintenta con backoff.
6. **El estado de la operación es visible:** pendiente, enviando, sincronizada, rechazada o en revisión.

## Patrones del móvil {#sec-movil-patrones}

| Patrón | Dónde | Para qué |
|---|---|---|
| **Feature-first + clean architecture** | `lib/features` | Aislar visita, mapa, historial y configuración |
| **Repository local-first** | `data/` | La UI lee del repositorio; la red sincroniza |
| **Outbox / command queue** | `core/sync` | Persistir operaciones y reintentar sin duplicar |
| **Optimistic UI + state machine** | `presentation` | Mostrar el dato de inmediato y su estado real |
| **Mapper** | `data/` | DTO del contrato ↔ entidad local |
| **DI con Riverpod o Bloc** | `app/providers` | Providers por feature; no un contenedor global |
| **Result/Either** | `domain/` | Errores de dominio explícitos, sin excepciones everywhere |
| **Background sync** | `core/sync` | Sincronizar con restricciones de batería y red |

# Web: `ica-durazno-web` {#sec-web}

## Stack {#sec-web-stack}

| Necesidad | Elección | Motivo |
|---|---|---|
| UI | React 19 + TypeScript | Ecosistema, tipado y disponibilidad de talento |
| Build | Vite | Backoffice interno; build estático y rápido |
| Routing | React Router | Rutas, layouts y guards |
| Estado del servidor | TanStack Query | Cache, invalidación, paginación y reintentos |
| Formularios | React Hook Form | Formularios controlados y eficientes |
| Validación | Zod | Esquemas compartidos entre formulario y tipos |
| UI base | Tailwind + shadcn/ui | Componentes accesibles y consistentes |
| Tablas | TanStack Table | Paginación y filtros en servidor |
| Mapas | MapLibre GL JS | Mismo estilo y tiles que el móvil |
| Gráficos | Recharts o Visx | Series de MTD y reportes |
| Fechas | date-fns | Zona horaria `America/Bogota` |
| Pruebas | Vitest + Testing Library + MSW | Unidad, componentes y mocks de API |
| E2E | Playwright | Flujos críticos del backoffice |

## Estructura de carpetas {#sec-web-tree}

```text
ica-durazno-web/
├── package.json
├── tsconfig.json
├── vite.config.ts
├── eslint.config.js
├── .env.example
├── index.html
├── src/
│   ├── main.tsx
│   ├── app/
│   │   ├── App.tsx
│   │   ├── router.tsx
│   │   ├── providers.tsx          # QueryClient, Auth, Theme, Toasts
│   │   └── layouts/
│   │       ├── AuthLayout.tsx
│   │       └── DashboardLayout.tsx
│   ├── pages/
│   │   ├── login/
│   │   ├── dashboard/
│   │   ├── predios/
│   │   ├── lotes/
│   │   ├── trampas/
│   │   ├── lecturas/
│   │   ├── mtd/
│   │   ├── conceptos/
│   │   ├── reportes/
│   │   ├── usuarios/
│   │   ├── catalogos/
│   │   └── importaciones/
│   ├── features/
│   │   ├── auth/
│   │   ├── predios/
│   │   │   ├── api/               # hooks de TanStack Query
│   │   │   ├── components/        # tabla, formulario, detalle
│   │   │   ├── hooks/
│   │   │   ├── schemas/           # Zod
│   │   │   ├── types/
│   │   │   └── index.ts           # API pública del feature
│   │   ├── lotes/
│   │   ├── trampas/
│   │   ├── lecturas/
│   │   ├── mtd/
│   │   ├── reportes/
│   │   ├── usuarios/
│   │   ├── catalogos/
│   │   └── importaciones/
│   ├── components/
│   │   ├── ui/                    # Button, Table, Dialog, Form...
│   │   ├── layout/
│   │   ├── data-table/
│   │   ├── charts/
│   │   └── maps/
│   ├── lib/
│   │   ├── api/
│   │   │   ├── client.ts          # openapi-fetch tipado
│   │   │   ├── errors.ts
│   │   │   └── queryKeys.ts
│   │   ├── auth/
│   │   ├── permissions/           # RBAC: can('predio:editar')
│   │   ├── validation/
│   │   ├── config/
│   │   ├── format/
│   │   └── utils/
│   ├── styles/
│   └── contracts/
│       ├── openapi.json           # contrato fijado
│       └── schema.d.ts            # generado por openapi-typescript
├── public/
├── tests/
│   ├── unit/
│   └── e2e/
└── README.md
```

## Rutas del backoffice {#sec-web-rutas}

```text
/login
/                         → dashboard
/predios
/predios/:predId
/lotes/:loteId
/trampas
/lecturas
/mtd
/conceptos
/reportes
/usuarios
/catalogos
/importaciones
```

- Rutas protegidas con `RequireAuth` + `RequireRole`.
- `React.lazy` por ruta para code splitting.
- Filtros y paginación en la URL (`useSearchParams`) para que un reporte sea compartible.
- `ErrorBoundary` por layout y estados explícitos de carga, vacío y error.

## Capas y patrones {#sec-web-patrones}

| Patrón | Dónde | Para qué | Anti-patrón evitado |
|---|---|---|---|
| **Feature-sliced** | `features/` | Cada feature agrupa API, componentes, esquemas y tipos | `components/` gigante |
| **Server state** | TanStack Query | Cache, invalidación y paginación | Guardar datos del servidor en Redux |
| **URL como estado** | `useSearchParams` | Filtros y reportes compartibles | Estado global para filtros |
| **Formularios tipados** | RHF + Zod | Validación de UX y tipos | Validación casera duplicada |
| **RBAC en UI** | `lib/permissions` | Ocultar acciones no permitidas | Confiar solo en la UI |
| **Tablas server-side** | `components/data-table` | Paginar y filtrar en la API | Traer todo y filtrar en el navegador |
| **Mapa presentacional** | `components/maps` | Visualizar sin lógica de dominio | Calcular MTD en el mapa |
| **Contrato generado** | `lib/api` | Tipos y cliente desde OpenAPI | DTOs escritos a mano |

La web **no calcula MTD, no decide aptitud y no versiona lecturas**. Esas reglas viven en `ica-durazno-api`; la web muestra el resultado y, cuando corresponde, envía un comando de corrección.

## Manejo de datos {#sec-web-datos}

```text
Page
  └── feature hook (usePredios, useLecturas...)
        └── lib/api/client.ts (OpenAPI tipado)
              └── API FastAPI
        └── TanStack Query cache
```

- `openapi-typescript` genera `schema.d.ts` desde `openapi.json`.
- `openapi-fetch` crea un cliente tipado; no se escriben DTOs a mano.
- `queryKeys.ts` centraliza las claves: `['predios', filtros]`, `['lotes', predioId]`, etc.
- Después de una mutación se invalida la clave afectada; no se recarga toda la aplicación.
- Los errores del backend se normalizan en `lib/api/errors.ts` y se muestran con un formato único.

## Autenticación y permisos {#sec-web-auth}

- OIDC/JWT con flujo PKCE; el token de acceso se mantiene en memoria y se renueva con refresh token rotado.
- La API es la autoridad: la web solo oculta acciones con `can('recurso:accion')`.
- Roles: `ADMINISTRADOR`, `AGRONOMO_SUPERVISOR`, `TECNICO`, `PRODUCTOR`.
- El backoffice no muestra predios fuera del ámbito del usuario; la API vuelve a filtrar.
- Toda acción administrativa queda en la bitácora; la web muestra el historial de cambios.

# Contrato entre repositorios {#sec-contrato}

```text
ica-durazno-api
   └── genera openapi.json
           │
           ├── artefacto versionado (ej. openapi-1.0.0.json)
           │
           ├── ica-durazno-app/contracts/openapi.json
           │      └── cliente Dart generado
           │
           └── ica-durazno-web/contracts/openapi.json
                  └── cliente TypeScript generado
```

Reglas:

1. El **backend es la fuente de verdad** del contrato.
2. Los clientes se generan; **no se editan a mano**.
3. Cada frontend fija una versión del contrato y la actualiza en un PR explícito.
4. El CI del backend corre un diff del `openapi.json` y bloquea cambios incompatibles.
5. El CI de cada frontend regenera el cliente y falla si el contrato fijado no coincide.
6. El móvil puede quedar meses sin actualizarse: la API mantiene compatibilidad hacia atrás o versiona (`/api/v2`).
7. Un cambio incompatible exige ventana de transición, no un despliegue sorpresa.

# Matriz de patrones por capa {#sec-matriz}

| Capa | Patrón principal | Patrón secundario | Evitar |
|---|---|---|---|
| API | Monolito modular | Hexagonal, use cases | Microsservicios prematuros |
| Persistencia | Repository + Unit of Work | Specification | Repositorio genérico único |
| Sincronización | Idempotent consumer | Outbox, state machine | Lógica de sync en el router |
| Reportes | CQRS-lite (read models) | Vistas SQL / proyecciones | Calcular reportes en la web |
| Importación histórica | Anti-corruption layer | Staging + validación por lote | Cargar `.xls` directo a tablas de dominio |
| Móvil | Offline-first repository | Outbox, optimistic UI | Espejar todo el esquema del servidor |
| Web | Feature-sliced + server state | RBAC, URL state | Duplicar reglas del backend |
| Contrato | Generated client + version pin | Contract testing | Copiar DTOs a mano |

# Puertas de calidad y CI {#sec-calidad}

| Repositorio | Formato / tipos | Pruebas | Fronteras / contrato | Seguridad |
|---|---|---|---|---|
| `ica-durazno-api` | `ruff format`, `ruff check`, `mypy` | `pytest`, cobertura de reglas ≥ 80% | `import-linter`, diff de `openapi.json`, `alembic check` | Barrido de secretos, dependencias vulnerables |
| `ica-durazno-app` | `dart format`, `flutter analyze` | `flutter test`, `integration_test` | `custom_lint`, cliente regenerado | Firma de APK/IPA, secretos |
| `ica-durazno-web` | `tsc --noEmit`, `eslint`, `prettier` | `vitest`, `playwright` | Cliente regenerado, contract testing | CSP, dependencias, secretos |

**Regla de oro:** ninguna fusión avanza sin verde. Las puertas viven en el repositorio y se versionan como código; desactivar una exige un ADR que la reemplace.

# Plan de implementación {#sec-plan}

| Fase | Entregable | Criterio de salida |
|---|---|---|
| 0 | Repositorios, CI, contrato inicial, ADR-18 | `openapi.json` generado y clientes vacíos compilan |
| 1 | API: identidad, configuración, registro, sincronización | Primer vertical slice: visita → lectura → sync → MTD |
| 2 | Móvil: auth, visita, mapa, sync, historial | Visita completa en modo avión y sincronización posterior |
| 3 | Web: auth, dashboard, predios, lotes, trampas, lecturas, MTD | Consulta de solo lectura sobre datos reales de prueba |
| 4 | Web admin: catálogos, usuarios, programación, reportes | CRUD con RBAC y bitácora |
| 5 | Importación histórica: `modules/importacion` + pantalla web | Carga de MF_UBI/MF_CAP con staging y validación |
| 6 | Endurecimiento: contract testing, E2E, observabilidad | Puertas completas y runbook de despliegue |

**Primer vertical slice recomendado:** una visita con una lectura, su operación de sincronización, el cálculo de MTD y la visualización en la web. Es el camino que cruza los tres repositorios y el contrato; si funciona, la estructura está probada.

# Decisiones registradas {#sec-adr}

## ADR-18 · Tercer repositorio para el backoffice web {#sec-adr-18}

**Contexto.** ADR-16 fijó dos repositorios: la app móvil y la API. El proyecto requiere un backoffice web para administración, reportes e importación histórica. La web tiene otro lenguaje, otro ciclo de despliegue y otra forma de autenticación, pero comparte el mismo dominio y la misma base de datos.

**Decisión.** Se agrega `ica-durazno-web` como tercer repositorio de código. Es un cliente React + TypeScript + Vite que consume el mismo contrato OpenAPI que la app móvil. No crea un segundo backend, no tiene base de datos propia y no duplica reglas de negocio.

**Consecuencias.**

- ADR-16 se extiende: de dos a tres repositorios, un solo contrato.
- El backend publica `openapi.json`; se generan dos clientes: Dart (móvil) y TypeScript (web).
- La web puede desplegarse como estático en un CDN y escalar independientemente de la API.
- La autorización sigue siendo responsabilidad de la API; la web solo reproduce la política en la UI.
- La importación histórica se implementa en `modules/importacion` y se opera desde la web, no desde scripts manuales.
- La vista C4 de contenedores debe actualizarse para incluir el contenedor web y su relación con la API.

## Relación con ADR-16 {#sec-adr-16-extension}

ADR-16 sigue siendo válida en su principio: **repositorios de solo código unidos por el contrato OpenAPI**. ADR-18 solo cambia el número de clientes. La frase “dos repositorios” debe leerse como “un repositorio por pila y por ciclo de vida”; con la web son tres.

# Anexo A. Convenciones de nombres {#sec-anexo-nombres}

| Elemento | Convención | Ejemplo |
|---|---|---|
| Repositorio | `ica-durazno-<cliente>` | `ica-durazno-web` |
| Módulo backend | sustantivo en español, singular | `registro`, `sincronizacion` |
| Caso de uso | verbo + objeto | `RegistrarLectura`, `CorregirLectura` |
| Feature web | sustantivo plural | `predios`, `lecturas`, `reportes` |
| Componente React | PascalCase | `PredioTable`, `LecturaForm` |
| Hook | `use` + sustantivo | `usePredios`, `useLectura` |
| Tabla SQL | sustantivo en español, prefijo de 4 letras | `lectura_trampa`, `lect_especimenes` |
| Ruta HTTP | plural, minúsculas, guiones | `/api/v1/predios`, `/api/v1/sync/operaciones` |
| Contrato | `openapi.json` versionado | `openapi-1.0.0.json` |

# Anexo B. Reglas de dependencia {#sec-anexo-dependencias}

**Backend**

```text
api → application → domain
infrastructure → application/domain
domain → nada
kernel → nada (solo primitivas)
```

**Móvil**

```text
presentation → domain
data → domain
core → nada de features
features → core, contracts
```

**Web**

```text
pages → features (API pública index.ts)
features → lib, components/ui
components/ui → nada de features
lib → nada de features
```

Un import que cruce estas reglas se bloquea en CI. No es una convención de estilo: es una frontera de arquitectura.

# Anexo C. Secuencia de sincronización {#sec-anexo-sync}

```text
1. El técnico registra una lectura sin red.
2. El móvil guarda la lectura en SQLite y una operación en outbox.
3. Al recuperar red, el sincronizador envía el lote.
4. La API verifica idempotencia por (dispositivo, id_cliente).
5. La API clasifica: alta_nueva, alta_retroactiva, correccion, revisar o rechazada.
6. El módulo registro aplica la regla temporal y guarda la versión.
7. El outbox emite LecturaRegistrada; concepto recalcula el MTD afectado.
8. La API responde con el estado y la versión del servidor.
9. El móvil marca la operación como sincronizada o rechazada.
10. La web consulta el MTD y el histórico por las vistas de reportes.
```

# Anexo D. Checklist para una nueva feature {#sec-anexo-feature}

- ¿La feature tiene un nombre de negocio, no de tecnología?
- ¿Tiene su carpeta en `features/` (web/móvil) o `modules/` (API)?
- ¿Expone una API pública (`index.ts`) y no permite imports internos?
- ¿La lógica de negocio está en `domain`/`application`, no en la UI?
- ¿El contrato OpenAPI se actualizó y el cliente se regeneró?
- ¿Tiene pruebas unitarias de la regla y al menos un flujo E2E?
- ¿La autorización se prueba en la API, no solo en la UI?
- ¿El error tiene un mensaje útil y un código estable?
- ¿La feature funciona sin red (móvil) o con red intermitente (web)?
- ¿La documentación de la feature vive fuera del repo de código?

# Anexo E. Glosario {#sec-anexo-glosario}

| Término | Definición |
|---|---|
| **Monolito modular** | Un solo despliegue con módulos de frontera explícita; ADR-14 |
| **Hexagonal** | Dominio aislado; adaptadores para HTTP, DB, cola y almacenamiento |
| **Unit of Work** | Una transacción por caso de uso; confirma o revierte todo |
| **Outbox** | Tabla de eventos pendientes que se publican después del commit |
| **Idempotencia** | Reintentar la misma operación no produce duplicados |
| **Anti-corruption layer** | Capa que traduce un formato legado al dominio, sin contaminarlo |
| **CQRS-lite** | Escritura transaccional y vistas de lectura separadas, sin event sourcing |
| **Feature-sliced** | Organización por funcionalidad, no por tipo técnico |
| **Server state** | Datos que viven en la API y se cachean en el cliente |
| **RBAC** | Autorización basada en roles |
| **Contract testing** | Verificar que cliente y servidor respetan el mismo contrato |
| **Vertical slice** | Una funcionalidad completa de punta a punta, no una capa aislada |
