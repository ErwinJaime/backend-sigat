# Pruebas de escritorio · SIGAT v6

Una **prueba de escritorio** es seguir un caso con papel y lápiz: se parte de datos conocidos, se aplica la regla a mano, se anota qué *debería* pasar y después se compara con lo que la base hace de verdad. Este documento tiene **49 escenarios** sobre los datos de demostración (`sql/05_datos_demo.sql`); cada uno dice la regla que prueba, los pasos, el resultado esperado y el resultado obtenido en la última ejecución. El archivo `PE_ejecutable.sql` los corre todos de una vez (y no deja rastro: termina en ROLLBACK).

## Los datos de partida (la «hoja de trabajo»)

| Persona / usuario | Rol | Qué hace en la demo |
|---|---|---|
| Ana (`ana.admin`) | Administrador (ámbito global) | Ve todo; no se asigna a predios |
| Sara (`sara.super`) | Agrónomo/Supervisor | Crea planificaciones, revisa visitas; acceso a los dos predios |
| Andrés (`andres.tec`) | Técnico | Tiene asignados los lotes **A y C** (1–30 sep 2026) |
| Juan (`juan.tec`) | Técnico | Tiene asignados los lotes **B y D** |
| Pedro (`pedro.prod`) | Productor | Dueño de «Finca El Mirador» (lotes A, B, C, D) |
| Marta (`marta.prod`) | Productora | Dueña de «Finca La Esperanza» (lote E) |

**Lo que pasó en el campo:** el 10-sep-2026 Andrés visitó el lote A y leyó 3 trampas (54518-602-1 Jackson → 2 moscas; 54518-602-2 McPhail → 0; 54518-602-3 Jackson → 4, corregida después a **5**). Juan visitó el lote A el 11-sep sin tenerlo asignado. El periodo 1–14 sep se cerró con MTD = 7 / (3 × 7) = **0,3333**. No hay umbral oficial (UQQ-004), por eso el concepto es «no_emitido».

**Cómo se lee cada escenario:** *Esperado* es lo que usted debería predecir antes de mirar; *Obtenido* es lo que respondió la base en la última ejecución; el sello **OK** significa que coinciden.

> Los escenarios se ejecutan **en este orden** y algunos dependen del anterior (p. ej. PE-12 completa la planificación de Andrés y PE-13 comprueba el efecto).


## A · Quién ve qué (visibilidad por rol)

### PE-01 · El técnico Andrés ve solo los lotes que le asignaron

- **Regla que se prueba:** RF-002 / RNF-015
- **Quién:** consulta de lectura
- **Pasos:** Consultar fn_lotes_visibles para andres.tec. Su planificación pendiente incluye los lotes A y C.
- **Esperado:** {A,C}
- **Obtenido (última ejecución):** {A,C} → **OK**

### PE-02 · El técnico Juan ve solo B y D (no ve los lotes de Andrés)

- **Regla que se prueba:** RF-002
- **Quién:** consulta de lectura
- **Pasos:** Consultar fn_lotes_visibles para juan.tec.
- **Esperado:** {B,D}
- **Obtenido (última ejecución):** {B,D} → **OK**

### PE-03 · El productor Pedro ve los lotes de su predio (A,B,C,D) pero no el E de Marta

- **Regla que se prueba:** RF-002
- **Quién:** consulta de lectura
- **Pasos:** Consultar fn_lotes_visibles para pedro.prod (dueño del predio DEMO-1).
- **Esperado:** {A,B,C,D}
- **Obtenido (última ejecución):** {A,B,C,D} → **OK**

### PE-04 · La productora Marta ve solo su lote E

- **Regla que se prueba:** RF-002
- **Quién:** consulta de lectura
- **Pasos:** Consultar fn_lotes_visibles para marta.prod.
- **Esperado:** {E}
- **Obtenido (última ejecución):** {E} → **OK**

### PE-05 · El administrador ve todos los lotes

- **Regla que se prueba:** RF-002
- **Quién:** consulta de lectura
- **Pasos:** Consultar fn_lotes_visibles para ana.admin (rol de ámbito global).
- **Esperado:** {A,B,C,D,E}
- **Obtenido (última ejecución):** {A,B,C,D,E} → **OK**

### PE-06 · Andrés recibe en su teléfono las 3 trampas del lote A; Juan no recibe ninguna

- **Regla que se prueba:** fn_trampa_app
- **Quién:** consulta de lectura
- **Pasos:** Contar las filas de fn_trampa_app para cada técnico (las trampas están en el lote A, que Juan no tiene asignado).
- **Esperado:** Andrés 3 · Juan 0
- **Obtenido (última ejecución):** 3-0 → **OK**


## B · Planificaciones (supervisor → técnico / productor)

### PE-07 · Un técnico no puede crear planificaciones

- **Regla que se prueba:** fn_planificacion_valida
- **Quién:** andres.tec
- **Pasos:** Con la sesión de Andrés (técnico) intentar crear una planificación para Juan.
- **Esperado:** Rechazado: «Solo un Agrónomo/Supervisor crea planificaciones»
- **Obtenido (última ejecución):** 23000 Solo un Agrónomo/Supervisor crea planificaciones → **OK**

### PE-08 · El destinatario no puede ser Administrador

- **Regla que se prueba:** fn_planificacion_valida
- **Quién:** sara.super
- **Pasos:** Sara intenta planificar para ana.admin.
- **Esperado:** Rechazado: «El destinatario debe ser Técnico o Productor»
- **Obtenido (última ejecución):** 23000 El destinatario debe ser Técnico o Productor → **OK**

### PE-09 · No se pueden asignar lotes de un predio al que el destinatario no tiene acceso

- **Regla que se prueba:** fn_planificacion_lote_valida
- **Quién:** sara.super
- **Pasos:** Sara crea una planificación para Andrés y le agrega el lote E (predio de Marta, donde Andrés no tiene acceso).
- **Esperado:** Rechazado: «El destinatario no tiene acceso al predio del lote»
- **Obtenido (última ejecución):** 23000 El destinatario no tiene acceso al predio del lote 5 → **OK**

### PE-10 · El técnico no puede rechazar (solo completar)

- **Regla que se prueba:** fn_planificacion_valida
- **Quién:** andres.tec
- **Pasos:** Andrés intenta pasar su planificación pendiente a «rechazada».
- **Esperado:** Rechazado: transición pendiente → rechazada no permitida para Técnico
- **Obtenido (última ejecución):** 23000 Transición pendiente -> rechazada no permitida para el rol TECNICO → **OK**

### PE-11 · Solo el destinatario responde: Sara no puede completar la planificación de Juan

- **Regla que se prueba:** fn_planificacion_valida
- **Quién:** sara.super
- **Pasos:** Con la sesión de Sara intentar completar la planificación de Juan.
- **Esperado:** Rechazado: «Solo el destinatario responde»
- **Obtenido (última ejecución):** 23000 Solo el destinatario responde la planificación → **OK**

### PE-12 · Andrés completa su planificación

- **Regla que se prueba:** fn_planificacion_valida
- **Quién:** andres.tec
- **Pasos:** Con la sesión de Andrés pasar su planificación de pendiente a completada.
- **Esperado:** Aceptado
- **Obtenido (última ejecución):** se aceptó → **OK**

### PE-13 · Al completarse, los lotes dejan de estar vigentes para el técnico (queda el historial)

- **Regla que se prueba:** v_asignacion_lote_tecnico
- **Quién:** consulta de lectura
- **Pasos:** Consultar de nuevo qué lotes ve Andrés tras completar.
- **Esperado:** {}  (vacío)
- **Obtenido (última ejecución):** {} → **OK**

### PE-14 · Pedro (productor) completa la planificación que ya había aceptado

- **Regla que se prueba:** fn_planificacion_valida
- **Quién:** pedro.prod
- **Pasos:** Pedro pasa su planificación de aceptada → completada (el productor sí acepta primero; el técnico no).
- **Esperado:** Aceptado
- **Obtenido (última ejecución):** se aceptó → **OK**

### PE-15 · Una planificación completada no admite más lotes

- **Regla que se prueba:** fn_planificacion_lote_valida
- **Quién:** sara.super
- **Pasos:** Sara intenta agregar el lote C a la planificación de Pedro (ya completada).
- **Esperado:** Rechazado: «Los lotes de una planificación no pendiente … están congelados»
- **Obtenido (última ejecución):** 23000 Los lotes de una planificación no pendiente (completada) están congelados → **OK**


## C · Lecturas de trampa y versionado

### PE-16 · La corrección de una lectura reemplaza a la original (vigente = versión 2)

- **Regla que se prueba:** v_lectura_vigente · RN-009
- **Quién:** consulta de lectura
- **Pasos:** La trampa 3 se leyó con 4 moscas (versión 1) y se corrigió a 5 (versión 2). Consultar las lecturas vigentes por trampa.
- **Esperado:** Trampa 1 = 2 · Trampa 2 = 0 · Trampa 3 = 5
- **Obtenido (última ejecución):** 2,0,5 → **OK**

### PE-17 · No se puede saltar una versión (de la 2 a la 4)

- **Regla que se prueba:** fn_registro_version_valida
- **Quién:** andres.tec
- **Pasos:** Insertar una versión 4 de la lectura de la trampa 3.
- **Esperado:** Rechazado: «Versión 4 inválida … se esperaba 3»
- **Obtenido (última ejecución):** 23000 Versión 4 inválida para el registro 9aed5d85-f579-4527-b227-d24743e435b4 de lectura_trampa: se esperaba 3 → **OK**

### PE-18 · La hora observada no puede cambiar entre versiones

- **Regla que se prueba:** fn_registro_version_valida · RN-009
- **Quién:** andres.tec
- **Pasos:** Insertar la versión 3 cambiando t_observacion.
- **Esperado:** Rechazado: «t_observacion es inmutable»
- **Obtenido (última ejecución):** 23000 t_observacion es inmutable entre versiones (RN-009) en lectura_trampa → **OK**

### PE-19 · Una corrección no puede mover la lectura a otra trampa/ubicación

- **Regla que se prueba:** fn_lectura_valida
- **Quién:** andres.tec
- **Pasos:** Insertar la versión 3 de la lectura de la trampa 3 apuntando a la trampa 2.
- **Esperado:** Rechazado: «La ubicación … no es de la trampa …»
- **Obtenido (última ejecución):** 23000 La ubicación 3 no es de la trampa 2 → **OK**

### PE-20 · Las lecturas no se modifican (solo inserción)

- **Regla que se prueba:** fn_bloquear_modificacion
- **Quién:** andres.tec
- **Pasos:** Intentar UPDATE sobre una lectura.
- **Esperado:** Rechazado: «es de solo inserción (append-only)»
- **Obtenido (última ejecución):** 23000 La tabla sigat.lectura_trampa es de solo inserción (append-only): UPDATE no permitido. Para corregir un dato i → **OK**

### PE-21 · No se puede leer una trampa en una fecha en que la ubicación aún no existía

- **Regla que se prueba:** fn_lectura_valida
- **Quién:** andres.tec
- **Pasos:** Visita del 15-ene-2026 y lectura de la trampa 1, cuya ubicación vigente empieza el 5-feb-2026.
- **Esperado:** Rechazado: «La ubicación no estaba vigente el día observado»
- **Obtenido (última ejecución):** 23000 La ubicación no estaba vigente el día observado (2026-01-15) → **OK**


## D · MTD y concepto de aptitud

### PE-22 · MTD calculado a mano = moscas / (trampas × días)

- **Regla que se prueba:** Fórmula MTD = M / (T × D)
- **Quién:** consulta de lectura
- **Pasos:** Lecturas válidas del periodo 1–14 sep: 2 + 0 + 5 = 7 moscas; 3 trampas; 7 días de exposición. MTD = 7 / (3 × 7) = 7/21 = 0,3333.
- **Esperado:** 0.3333
- **Obtenido (última ejecución):** 0.3333 → **OK**

### PE-23 · Solo las lecturas oficiales, leídas y vigentes del lote y del periodo alimentan el MTD

- **Regla que se prueba:** fn_mtd_lectura_valida · RN-013/014
- **Quién:** consulta de lectura
- **Pasos:** Contar las lecturas que devuelve fn_mtd_lectura_valida para el periodo de la demo (3 trampas leídas).
- **Esperado:** 3
- **Obtenido (última ejecución):** 3 → **OK**

### PE-24 · Sin umbral oficial el concepto queda «no_emitido»

- **Regla que se prueba:** UQQ-004 · RF-024
- **Quién:** consulta de lectura
- **Pasos:** Consultar el concepto vigente del lote A.
- **Esperado:** no_emitido
- **Obtenido (última ejecución):** no_emitido → **OK**

### PE-25 · No se puede emitir «apto» sin umbral configurado

- **Regla que se prueba:** fn_concepto_valida
- **Quién:** sara.super
- **Pasos:** Intentar registrar una versión 2 del concepto con resultado «apto» (con norma) cuando el MTD no tiene umbral.
- **Esperado:** Rechazado: «No se puede emitir apto/no_apto sin umbral configurado»
- **Obtenido (última ejecución):** 23000 No se puede emitir apto/no_apto sin umbral configurado (UQQ-004) → **OK**

### PE-26 · La etapa fenológica se deriva de la fecha de plantación y la regla vigente

- **Regla que se prueba:** fn_etapa_derivada · RN-012
- **Quién:** consulta de lectura
- **Pasos:** Lote A plantado el 1-mar-2025; al 10-sep-2026 han pasado 558 días. Regla «Cuajado» = 401–900 días.
- **Esperado:** Cuajado
- **Obtenido (última ejecución):** Cuajado → **OK**

### PE-27 · Se detecta la discrepancia entre lo que declara el productor y lo que observa el técnico

- **Regla que se prueba:** v_etapa_discrepancia · RN-012
- **Quién:** consulta de lectura
- **Pasos:** Pedro declaró «Cuajado» (autorreporte) y Andrés observó «Floración» (inspección oficial) en el lote A.
- **Esperado:** 1 fila: Cuajado vs Floración
- **Obtenido (última ejecución):** 1 Cuajado vs Floración → **OK**


## E · Trampas y ubicaciones

### PE-28 · La paridad del número de trampa depende del tipo (Jackson impar)

- **Regla que se prueba:** fn_trampa_valida · RN-005
- **Quién:** andres.tec
- **Pasos:** Crear la trampa 54518-602-4 (número par) de tipo Jackson.
- **Esperado:** Rechazado: «no respeta la paridad»
- **Obtenido (última ejecución):** 23000 El número de trampa 4 no respeta la paridad (impar) de su tipo (RN-005) → **OK**

### PE-29 · Las coordenadas deben caer dentro del rango del departamento

- **Regla que se prueba:** fn_ubicacion_trampa_valida · RN-006
- **Quién:** andres.tec
- **Pasos:** Ubicar la trampa 1 en longitud -80,0 (Norte de Santander va de -73,6 a -72,0).
- **Esperado:** Rechazado: «fuera del rango del departamento»
- **Obtenido (última ejecución):** 23000 Coordenadas (-80.00000, 7.37000) fuera del rango del departamento del predio (RN-006) → **OK**

### PE-30 · Una trampa no puede estar en dos puestos a la vez (vigencias que se solapan)

- **Regla que se prueba:** EXCLUDE ubicacion_trampa
- **Quién:** andres.tec
- **Pasos:** La trampa 1 ya está ubicada desde el 5-feb-2026 sin fecha fin. Registrar otra ubicación desde el 1-mar-2026 sin cerrar la anterior.
- **Esperado:** Rechazado por restricción de exclusión (SQLSTATE 23P01)
- **Obtenido (última ejecución):** 23P01 conflicting key value violates exclusion constraint "ubicacion_trampa_sin_solape" → **OK**

### PE-31 · Un punto GPS se asigna al lote que lo contiene

- **Regla que se prueba:** fn_lote_que_contiene
- **Quién:** consulta de lectura
- **Pasos:** Punto (-72,6425; 7,3725) está en el cuadrante del lote B.
- **Esperado:** B
- **Obtenido (última ejecución):** B → **OK**

### PE-32 · Las 3 trampas caen dentro de la geometría del lote A

- **Regla que se prueba:** v_trampa_lote_vigente · RF-012
- **Quién:** consulta de lectura
- **Pasos:** Contar las trampas vigentes cuyo punto está dentro del lote.
- **Esperado:** 3
- **Obtenido (última ejecución):** 3 → **OK**

### PE-33 · El código de ruta de 9 dígitos se compone del Divipola + registro de ruta

- **Regla que se prueba:** v_ruta_codigo_ica · RN-005
- **Quién:** consulta de lectura
- **Pasos:** Departamento 54 + municipio 518 + ruta 0602.
- **Esperado:** 545180602
- **Obtenido (última ejecución):** 545180602 → **OK**


## F · Geometría, retícula y programa

### PE-34 · La geometría de un lote no puede salirse del predio

- **Regla que se prueba:** fn_lote_geometria_valida · RF-084
- **Quién:** sara.super
- **Pasos:** Registrar una nueva versión de geometría del lote B desplazada fuera del predio.
- **Esperado:** Rechazado: «queda fuera del límite del predio»
- **Obtenido (última ejecución):** 23000 La geometría del lote 2 queda fuera del límite del predio (RF-084) → **OK**

### PE-35 · La resolución de la retícula debe ser múltiplo de la distancia mínima entre trampas

- **Regla que se prueba:** fn_programa_valida · RI-002 / RN-004
- **Quién:** sara.super
- **Pasos:** Nuevo programa con distancia mínima 40 m sobre una retícula de 90 m (90 no es múltiplo de 40).
- **Esperado:** Rechazado: «debe ser múltiplo de la distancia mínima»
- **Obtenido (última ejecución):** 23000 La resolución de la retícula (90 m) debe ser múltiplo de la distancia mínima entre trampas (40 m) (RI-002/RN-0 → **OK**

### PE-36 · Una retícula no cambia de resolución (se crea otra)

- **Regla que se prueba:** fn_reticula_inmutable
- **Quién:** sara.super
- **Pasos:** Intentar cambiar la resolución de 80 a 100 m.
- **Esperado:** Rechazado: «no se modifican; cree otra retícula»
- **Obtenido (última ejecución):** 23000 La resolución y el predio de una retícula no se modifican; cree otra retícula → **OK**


## G · Visitas y revisión

### PE-37 · Se detecta la visita a un lote no asignado, sin bloquear el registro

- **Regla que se prueba:** v_visita_lote_sin_asignacion
- **Quién:** consulta de lectura
- **Pasos:** Juan visitó el lote A el 11-sep sin tenerlo asignado; Andrés sí lo tenía.
- **Esperado:** 1 fila: juan.tec
- **Obtenido (última ejecución):** 1 juan.tec → **OK**

### PE-38 · De una visita solo cambian las columnas de revisión

- **Regla que se prueba:** fn_visita_integridad
- **Quién:** sara.super
- **Pasos:** Intentar cambiar la hora de captura de una visita.
- **Esperado:** Rechazado: «solo se pueden modificar las columnas de revisión»
- **Obtenido (última ejecución):** 23000 En una visita solo se pueden modificar las columnas de revisión → **OK**

### PE-39 · La supervisora puede poner una visita en revisión

- **Regla que se prueba:** fn_visita_integridad
- **Quién:** sara.super
- **Pasos:** Sara marca la visita pendiente (la de Juan) «en_revision».
- **Esperado:** Aceptado
- **Obtenido (última ejecución):** se aceptó → **OK**


## H · Sincronización y reloj

### PE-40 · La misma operación del celular enviada dos veces no se duplica (idempotencia)

- **Regla que se prueba:** operacion_sync UNIQUE (dispositivo, id_cliente)
- **Quién:** andres.tec
- **Pasos:** Reenviar una operación con el mismo dispositivo y el mismo identificador de cliente.
- **Esperado:** Rechazado por llave única (SQLSTATE 23505)
- **Obtenido (última ejecución):** 23505 duplicate key value violates unique constraint "operacion_sync_disp_id_oper_cliente_id_key" → **OK**

### PE-41 · El reloj de sincronización lo pone el servidor, no el celular

- **Regla que se prueba:** fn_registro_version_valida
- **Quién:** andres.tec
- **Pasos:** Insertar una cosecha con t_sincronizacion = año 2000 y comprobar que quedó con la hora del servidor.
- **Esperado:** 0 filas con fecha anterior a 2020
- **Obtenido (última ejecución):** se aceptó → 0 → **OK**


## I · Seguridad y auditoría

### PE-42 · La bitácora no se borra

- **Regla que se prueba:** fn_bloquear_modificacion
- **Quién:** ana.admin
- **Pasos:** Intentar DELETE sobre bitacora_auditoria.
- **Esperado:** Rechazado: «solo inserción»
- **Obtenido (última ejecución):** 23000 La tabla sigat.bitacora_auditoria es de solo inserción (append-only): DELETE no permitido. Para corregir un da → **OK**

### PE-43 · La bitácora nunca guarda contraseñas

- **Regla que se prueba:** fn_auditar · RF-083
- **Quién:** consulta de lectura
- **Pasos:** Buscar el texto «argon2id» (formato del hash) en el detalle de la bitácora.
- **Esperado:** 0
- **Obtenido (última ejecución):** 0 → **OK**

### PE-44 · Un cambio en una tabla auditada queda registrado

- **Regla que se prueba:** fn_auditar · RF-083
- **Quién:** sara.super
- **Pasos:** Cambiar la dirección de la persona Pedro y contar los UPDATE de persona en la bitácora.
- **Esperado:** 1
- **Obtenido (última ejecución):** se aceptó → 1 → **OK**

### PE-45 · Un usuario de ámbito global (Administrador) no se asigna a un predio

- **Regla que se prueba:** fn_usuario_predio_valida
- **Quién:** ana.admin
- **Pasos:** Asignar a ana.admin al predio DEMO-1.
- **Esperado:** Rechazado: «ámbito global»
- **Obtenido (última ejecución):** 23000 Un usuario con rol de ámbito global no se asigna a un predio → **OK**


## J · Archivos y avisos

### PE-46 · El estado de un archivo solo avanza (almacenado no vuelve a pendiente)

- **Regla que se prueba:** fn_archivo_adjunto_valida
- **Quién:** andres.tec
- **Pasos:** Intentar regresar el archivo de la evidencia de «almacenado» a «pendiente_contenido».
- **Esperado:** Rechazado: «solo avanza desde pendiente_contenido»
- **Obtenido (última ejecución):** 23000 El estado del archivo solo avanza desde pendiente_contenido (actual: almacenado) → **OK**

### PE-47 · La identidad de un archivo (hash) no se modifica

- **Regla que se prueba:** fn_archivo_adjunto_valida
- **Quién:** andres.tec
- **Pasos:** Intentar cambiar el hash SHA-256 del archivo.
- **Esperado:** Rechazado: «La identidad … no se modifica»
- **Obtenido (última ejecución):** 23000 La identidad de un archivo adjunto no se modifica → **OK**

### PE-48 · Un aviso se marca leído una sola vez

- **Regla que se prueba:** fn_notificacion_valida
- **Quién:** andres.tec
- **Pasos:** Andrés marca su aviso como leído, y luego intenta marcarlo con otra hora.
- **Esperado:** Primero aceptado; luego rechazado: «ya fue leída»
- **Obtenido (última ejecución):** se aceptó → 23000 La notificación ya fue leída → **OK**

### PE-49 · El contenido de un aviso no se edita

- **Regla que se prueba:** fn_notificacion_valida
- **Quién:** juan.tec
- **Pasos:** Intentar cambiar el título de un aviso de Juan.
- **Esperado:** Rechazado: «no se modifica»
- **Obtenido (última ejecución):** 23000 El contenido de una notificación no se modifica → **OK**
