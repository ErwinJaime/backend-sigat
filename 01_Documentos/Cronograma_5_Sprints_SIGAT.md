---
title: "Cronograma de desarrollo SIGAT -- 5 sprints (Mon-Sab)"
date: "28 de octubre de 2026"
lang: es-CO
---

> **Base documental.** Requisitos (`Levantamiento_...`) + especificacion tecnica (`Especificacion_...`).

# Equipo asignado y roles

| Rol | Persona | Responsabilidad |
|---|---|---|
| **Backend** (`backend-sigat`) | Dev Backend | Módulos DDD (`ica_api`), DDL/vistas, contratos OpenAPI, sincronización idempotente |
| **Web** (`frontend-sigat`) | Dev Web | React 19 / TS, TanStack Query, portal productor (`PW01-PW07`) |
| **Móvil** (`mobile-sigat`) | Dev Móvil | Flutter / Drift, `SyncEngine`, mapa `maplibre_gl` |
| **QA / Integración** | QA Engineer | BDD Gherkin (Seccion 7), CI `.github/workflows/ci.yml` |
| **Lead / Arquitecto** (`SIGAT-UP`) | Arquitecto / PO | Revisión domingo, aprobación merges, cierre MVP |

# Calendario (Lun-Sáb, inicio 2 nov 2026)

Entrega de avances (código): sábado al finalizar el sprint. Revisión del Lead: domingo anterior al inicio del sprint siguiente (ej. S2 inicia 9 nov => entrega 7 nov, revisión 8 nov).

| Sprint | Trabajo | Revisión | Objetivo |
|---|---|---|---|
| **S1** | 2 -- 7 nov (entrega 7 nov) | **8 nov** (revisión) | Cimientos: DDL, catálogos, auth, repos |
| **S2** | 9 -- 14 nov (entrega 14 nov) | **15 nov** (revisión) | Datos centrales: registro, vigilancia, cosecha, vistas |
| **S3** | 16 -- 21 nov (entrega 21 nov) | **22 nov** (revisión) | Funcionalidades: aplicaciones, sync, MTD |
| **S4** | 23 -- 28 nov (entrega 28 nov) | **29 nov** (revisión) | Portal + mapa + RBAC + avisos |
| **S5** | 30 nov -- 5 dic (entrega 5 dic) | **6 dic** (revisión) | Integración final, CI, cierre MVP |

# Sprint 1 -- revisión 8 nov (`Seccion 3.2.1`, `Seccion 3.2.2`, `Seccion 3.1`, `Seccion 1.2`, `Seccion 5.2`)

- **Backend:** `escenario_trampeo` + `permiso`; 3 vistas (`v_actividad_lote_detalle`, etc.); `identidad` (`/auth/login`, `/health`); módulos DDD; `tests/`.
- **Web:** `router.tsx` (`DashboardLayout`); `.env`; `DataTable`; `oxlint` limpio.
- **Móvil:** esquema Drift (`local_operacion_queue`, `local_lotes`); `core/sync/` básico.
- **QA:** CI verde en los 3 repos.

# Sprint 2 -- revisión 15 nov (`Seccion 3.2.3`–`Seccion 3.2.6`, `Seccion 4.1`, `Seccion 5.1`)

- **Backend:** `v_cosecha_lote_vigente`; `v_aplicacion_ultima_lote`; indice `ux_cosecha_abierta`; `registro`.
- **Web:** `DashboardPage`, `PrediosPage`, `LotesPage`, `CatalogosPage`; `lib/api/client.ts`; `useQuery`.
- **Móvil:** árbol `lib/features/` completo (`auth`, `autorreporte`, `historial`, `mapa`, `configuracion`, `muestra`, `visita`).
- **QA:** `HU-01` paso 1.

# Sprint 3 -- revisión 22 nov (`Seccion 3.2.7`/`Seccion 3.2.8`, `Seccion 3.3`, `Seccion 4.1`, `Seccion 5.3`)

- **Backend:** `v_notificacion_app`; `v_planificacion` ampliada; `POST /aplicaciones`, `/cosechas`; contrato OpenAPI 3.1.
- **Web:** `features/productor/` + `pages/productor/` (`PW01`–`PW07`); `RoleGuard`; `PW03a` (`RHF`+`Zod`); mapa `MapLibre`.
- **Móvil:** `Dio`; `SyncEngine`; `P03`→`P04`; `P07` (cola + confirmación); `P07d` error.
- **QA:** `HU-02` (idempotencia `207 Multi-Status`).

# Sprint 4 -- revisión 29 nov (`Seccion 4.2`, `Seccion 7.3`/`Seccion 7.4`, `Seccion 6.7`)

- **Web:** `PW01`–`PW07` completos (`PW02b`: MTD + `escenario_trampeo`; `PW06b`: `v_notificacion_app`; `PW07a`–`PW07f`); mapa completo.
- **Móvil:** `P01-P`, `P02-P`, `P07-P`; mapa con polígonos.
- **QA:** `HU-03` (`PW02b` → MTD 0,36 → `Supresión`) + `HU-04` (`PW07a` → rechazo).

# Sprint 5 -- revisión 6 dic (`Seccion 6.2`, `Seccion 8.1`, `Seccion 8`)

- **Backend:** `fn_planificacion_valida`; `POST /planificaciones/*`; `operacion_sync` idempotente; catálogos restantes.
- **Web:** `PW07c` (rechazo obligatorio); cierre `README.md`.
- **Móvil:** `P07d-P` (reintentar); cierre `build.md`.
- **QA / Lead:** integración completa; cierre bloqueantes (`escenario_trampeo`, `permiso`, `UQQ-004`); tag `v0.1.0-mvp`; `build/dev.pdf` 19 págs, 0 `Overfull`.

# Regla de entrega por sprint

Revisión domingo 17:00. Si hay `Overfull`, error `ruff`/`oxlint`/`flutter analyze` o bloqueante `Seccion 8.1` sin resolver, se activa hotfix antes del lunes; **no avanza sin cierre**.
