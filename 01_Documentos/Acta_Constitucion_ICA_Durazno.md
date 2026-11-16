---
title: "Acta de constitucion del proyecto"
subtitle: "Autorizacion formal del MVP del sistema de gestion y monitoreo de cultivos de durazno"
author: "Equipo de Arquitectura de Software"
date: "14 de octubre de 2026"
lang: es-CO
---

# Proposito de este documento {#sec-proposito-acta}

Este documento es el **acta de constitucion del proyecto** del sistema de gestion y monitoreo de cultivos
de durazno con fines de exportacion, en adelante *el Proyecto*. Constituye la autorizacion formal para
ejecutarlo, nombra quien lo dirige, fija que se va a construir, con que tecnologias, en cuanto tiempo y
bajo que criterios se considerara terminado.

> **Base normativa.** El acta de constitucion es el entregable del proceso de iniciacion descrito en
> **ISO 21500**, *Desarrollo del acta de constitucion del proyecto*, cuyo objetivo es vincular el proposito
> de negocio con el trabajo del equipo y conferir al director del proyecto la autoridad para aplicar los
> recursos. La familia de normas fue reorganizada: **ISO 21500:2021** establece el contexto y los conceptos,
> e **ISO 21502:2020** contiene la guia de gestion de proyectos que sustituyo a ISO 21500:2012. Este
> documento sigue la estructura de esa guia.

> **Estado: borrador para discusion.** Esta version es un **borrador (v0.1)** que el equipo debe revisar,
> discutir y corregir en la reunion de inicio. Los campos marcados como *(por designar)* y *(pendiente)* se
> completan o confirman en esa reunion. Mientras no exista la firma de aprobacion de la
> seccion\nobreakspace\ref{sec-aprobacion}, el Proyecto no se considera formalmente constituido.

## Documentos de los que se deriva {#sec-deriva}

El acta no introduce contenido tecnico nuevo: resume y autoriza lo que ya esta especificado en los
documentos de la entrega. Si hay conflicto entre este resumen y el documento de detalle, prevalece el
documento de detalle.

| Documento | Que aporta al acta |
|---|---|
| *Levantamiento de requerimientos* (ISO/IEC/IEEE 29148) | Los requisitos de alto nivel, las partes interesadas y las restricciones |
| *Tabla de prioridades y MVP* | El alcance exacto del MVP, el orden de construccion y los criterios de aceptacion |
| *Arquitectura tecnologica* | Las decisiones de tecnologia (Flutter y MapLibre entre ellas), el modelo temporal y los riesgos |
| *Manual Tecnico de Trampeo de Moscas de la Fruta* (ICA, 2020) | La fuente normativa de las reglas de negocio del sistema |

# Identificacion del proyecto {#sec-identificacion}

| Campo | Valor |
|---|---|
| **Nombre del proyecto** | Sistema de gestion y monitoreo de cultivos de durazno con fines de exportacion |
| **Codigo de proyecto** | ICA-DURAZNO-MVP |
| **Fase que constituye esta acta** | Construccion del MVP (primera version utilizable de punta a punta) |
| **Patrocinador (sponsor)** | Direccion Tecnica de Epidemiologia y Vigilancia Fitosanitaria (DTEVF), ICA *(por ratificar)* |
| **Director del proyecto** | *(por designar en la reunion de inicio)* |
| **Arquitecto responsable** | Equipo de Arquitectura de Software |
| **Fecha de inicio propuesta** | *(por confirmar)* |
| **Duracion prevista** | 11 semanas (2,5 meses) |
| **Estado** | Borrador v0.1, sujeto a discusion y aprobacion |

# Justificacion y proposito del proyecto {#sec-justificacion}

El durazno colombiano con destino de exportacion exige demostrar el estado fitosanitario de cada lote
frente a la mosca del Mediterraneo (*Ceratitis capitata*). Ese estado se sostiene con lecturas de trampas
que se toman **en el campo, sin cobertura de datos**, y que hoy se registran en papel y se consolidan
despues, con perdida de informacion, retraso y sin trazabilidad de las fechas de observacion.

El Proyecto existe para resolver ese problema puntual: **capturar la inspeccion en el predio sin conexion,
conservar la fecha real de cada lectura y reconstruir el estado de un lote en cualquier fecha pasada**, de
forma que el ICA pueda sustentar el tramite de exportacion y el productor pueda gestionar su cultivo.

El Proyecto **no** automatiza el tramite de exportacion ni sustituye el diagnostico de laboratorio: produce
el insumo tecnico y el dato trazable que esos procesos institucionales consumen (RST-005, RST-006).

# Objetivos del proyecto {#sec-objetivos}

Los objetivos se formulan medibles, para que su cumplimiento no dependa de una opinion.

| ID | Objetivo (SMART) | Como se comprueba |
|---|---|---|
| **O-1** | Entregar el MVP completo: los 27 elementos del backlog (25 de nucleo P0 y 2 necesarios P1) en las 5 iteraciones planificadas | Tabla de backlog con todos los elementos cerrados y verificados |
| **O-2** | Ejecutar el Proyecto en **11 semanas**, con los tres hitos de decision cumplidos y sin adelantar trabajo de fases posteriores | Cronograma contra las fechas de los hitos H1, H2 y H3 |
| **O-3** | Cumplir los **10 criterios de aceptacion** del MVP (A-01 a A-10), todos verificables por prueba | Ejecucion de los criterios de la seccion\nobreakspace\ref{sec-criterios} |
| **O-4** | Construir la aplicacion movil **en Flutter con MapLibre** como motor de mapas, sin cambiar estas tecnologias sin una decision de arquitectura nueva registrada | Revision de dependencias del repositorio `ica-durazno-app` |
| **O-5** | Garantizar **cero perdida de registros confirmados** (RNF-009) y **cero duplicados** ante reintentos (RNF-011) | Pruebas A-02 y A-03 en modo avion |

## Criterios de exito del proyecto {#sec-exito-proyecto}

El exito se mide sobre las cuatro restricciones clasicas del proyecto. Un resultado que sacrifique una de
forma no acordada no cuenta como exito.

| Dimension | Criterio de exito |
|---|---|
| **Alcance** | La frase de cierre del MVP se puede verificar de punta a punta (ver la seccion\nobreakspace\ref{sec-alcance}) |
| **Tiempo** | Los cinco incrementos se entregan dentro de las 11 semanas; el MVP se etiqueta `v0.1` |
| **Costo** | La estructura de costos no excede lo aprobado en la reunion de inicio (ver la seccion\nobreakspace\ref{sec-recursos}) |
| **Calidad** | Los 10 criterios de aceptacion pasan; la cobertura de las reglas de negocio es de al menos el 80% (RNF-017) |

# Requisitos de alto nivel {#sec-requisitos}

El Proyecto debe satisfacer las capacidades del Sistema, agrupadas por funcion de alto nivel. El detalle
completo (58 requisitos funcionales, 20 no funcionales y sus criterios de verificacion) esta en el
*Levantamiento de requerimientos*.

| Grupo | Capacidad | Requisitos representativos |
|---|---|---|
| 1 | Identidad y configuracion por predio | RF-001, RF-002, RF-082 |
| 2 | Orientacion geografica sin conexion | RF-004 a RF-007, RF-013, RI-002, RI-004 |
| 3 | Captura de la inspeccion oficial | RF-020 a RF-027, RF-060 a RF-066 |
| 4 | Captura del autorreporte del productor | RF-040 a RF-042 |
| 5 | Consolidacion temporal (MTD, umbral y fecha de efecto) | RF-023, RF-024, RF-050 a RF-054 |
| 6 | Sincronizacion diferida, idempotente y fuera de orden | RF-062 a RF-066, RNF-009, RNF-011 |
| 7 | Consulta y resumen por rol | RF-070 a RF-073, RI-009 |

Ademas, el Proyecto queda sujeto a las **restricciones** declaradas, que no son negociables sin cambiar el
enunciado: sin cobertura de red en el predio (RST-001), personalizacion por predio (RST-002), aplicacion
movil (RST-003), desarrollo ejecutado por un equipo de construccion distinto del de arquitectura (RST-004),
sin automatizar el tramite de exportacion (RST-005), sin diagnostico automatico (RST-006) y sin sustituir
la imagen satelital (RST-007).

# Alcance del proyecto {#sec-alcance}

El alcance de esta acta es **exactamente el MVP** definido en la *Tabla de prioridades y MVP*. No es una
seleccion nueva: es el mismo alcance que el equipo ya acepto, ahora autorizado formalmente.

## Alcance incluido {#sec-alcance-incluido}

| Iteracion | Alcance | Elementos |
|---|---|---|
| 1 | Fundamentos del dominio (esquema, asignacion trampa-lote, motores de MTD y umbral) | M-01 a M-05 |
| 2 | Captura sin conexion (base local espacial, paquete de campo, lectura de trampa, cola de salida, cierre de visita) | M-06 a M-11 |
| 3 | Sincronizacion y regla temporal (carga idempotente, motor temporal, reproceso del MTD, bitacora) | M-12 a M-17 |
| 4 | Autorreporte del productor (autenticacion, app no tecnica, aplicaciones y cosecha) | M-18 a M-22 |
| 5 | Consulta y resumen (resumen de lote y predio, historico, superficie del supervisor) | M-23 a M-27 |

El criterio de cierre del alcance es una sola frase verificable:

> **Un tecnico puede, en un predio sin cobertura, recorrer sus lotes, registrar la lectura de sus trampas
> con su codigo ICA, cerrar la visita, subirla despues aunque haya llegado antes el dato de una visita
> posterior, y ver el resumen del lote con el MTD, el umbral y la fecha de efecto.**

Si el Sistema no puede hacer eso completo, no cumple el alcance de esta acta.

## Alcance excluido {#sec-alcance-excluido}

Queda **fuera del Proyecto**, con su motivo y su momento de retorno documentados. Estas exclusiones acotan
el alcance de la misma forma que las inclusiones.

| ID | Excluido | Motivo resumido | Retorna en |
|---|---|---|---|
| X-01 | Enlace del resultado de laboratorio | Formato de intercambio no definido (UQQ-006) | v0.2 |
| X-02 | Relacion de muestras automatica | El formato en papel sirve durante el MVP | v0.2 |
| X-03 | Evidencia fotografica | No la exige el Manual; riesgo por datos personales | v0.4 |
| X-04 | Recorrido de la visita | Informacion de apoyo, no sostiene el tramite | v0.4 |
| X-05 | Marcado geografico de hallazgos | Se puede registrar por celda de reticula | v0.4 |
| X-06 | Indicadores de gestion de predios | Se calculan despues, sobre el historico | v0.5 |
| X-07 | Alertas de vencimiento e incumplimiento | Canal institucional no definido | v0.5 |
| X-08 | Asignacion y reasignacion de visitas | Pertenece al proceso de programacion del ICA | v0.6 |
| X-09 | Codigo QR de trampa | No es estandar del ICA; basta la lista | v0.4 |
| X-10 | Geometria versionada en detalle | El MVP versiona el dato, sin interfaz de redibujo | v0.5 |
| X-11 | Diagnostico automatico de plagas | Restriccion explicita (RST-006) | No previsto |
| X-12 | Tramite de licencia y certificado de exportacion | Proceso institucional, no de registro | No previsto |

# Tecnologias establecidas {#sec-tecnologias}

Esta acta **establece Flutter y MapLibre como tecnologias del Proyecto**. Cambiarlas requiere una decision
de arquitectura nueva registrada, no una preferencia del equipo de construccion.

| Componente | Tecnologia establecida | Por que |
|---|---|---|
| Aplicacion movil | **Flutter** (Dart) | Un solo codigo para Android e iOS; cubre camara, GPS, almacenamiento local y mapas; es la tecnologia declarada por el proyecto (RST-003) |
| Motor de mapas | **MapLibre GL** | Unica opcion sin riesgo contractual al cachear mosaicos en el dispositivo, gestiona muchos poligonos con atributos y permite cambiar de proveedor de imagen cambiando una URL |
| Base de datos local | SQLite con extension espacial | Tolerancia a la corrupcion por corte de energia y consultas espaciales «dame el lote que contiene este punto» sin red |
| Servidor | Python con FastAPI | El tipado con pydantic genera el contrato OpenAPI a partir del codigo, de modo que el contrato no puede quedar desactualizado |
| Base de datos del servidor | PostgreSQL con PostGIS | Geometria y reglas de negocio en el servidor |
| Imagenes | Almacenamiento de objetos con acceso por referencia | Los binarios no van a la base transaccional |

**Nota sobre el mapa.** MapLibre resuelve el *render*, no la disponibilidad de los mosaicos: si no hay
imagen descargada en el dispositivo, no hay mapa. Por eso el proveedor de imagen es una dependencia
externa (UQQ-007) y el diseño admite un modo degradado con el fondo vectorial minimo.

# Entregables del proyecto {#sec-entregables}

| ID | Entregable | Estado |
|---|---|---|
| E-1 | Documentos de definicion (requerimientos, arquitectura y tabla de prioridades) | Entregados (v1.1) |
| E-2 | Aplicacion movil del MVP (`ica-durazno-app`) | Por construir |
| E-3 | Servidor del MVP (`ica-durazno-api`) | Por construir |
| E-4 | Contrato `openapi.json` generado desde el servidor y fijado en el cliente | Por construir |
| E-5 | Paquete de campo por predio, versionado e invalidado al cambiar la configuracion | Por construir |
| E-6 | Acta de cierre del Proyecto, con lecciones aprendidas | Al cierre |

# Hitos y cronograma {#sec-hitos}

El Proyecto se ejecuta en cinco incrementos dentro de las 11 semanas. Los tres **hitos de decision** son
puntos de control en los que el error todavia es corregible.

| Hito | Momento | Que se verifica | Que se hace si falla |
|---|---|---|---|
| **H1 · El modelo temporal esta cerrado** | Al terminar la iteracion 3 | Un alta retroactiva se inserta en su posicion correcta y no altera el pasado | Se replantea el modelo antes de construir encima |
| **H2 · La visita funciona en modo avion** | Al terminar la iteracion 2 | Una visita completa se ejecuta y se cierra sin ninguna llamada de red | Se corrige el nucleo de almacenamiento local antes de seguir |
| **H3 · El resumen es util** | Al terminar la iteracion 5 | El resumen del lote permite decidir en un minuto si hay problema de exportacion | Se rediseña la informacion del resumen |

| Incremento | Contenido | Resultado |
|---|---|---|
| v0.1 | Las cinco iteraciones del MVP | **MVP** operable de punta a punta |
| v0.2 | Cierre del ciclo de laboratorio (X-01, X-02) | Dato de campo hasta el diagnostico |
| v0.4 | Evidencia y georreferencia fina (X-03, X-04, X-05, X-09) | Registro apoyado con imagen y recorrido |
| v0.5 | Consolidacion institucional (X-06, X-07, X-10) | Dato agregado para el programa y la auditoria |
| v0.6 | Asignaciones (X-08) | Programacion de visitas integrada |

# Recursos y estructura de costos {#sec-recursos}

El Proyecto cuenta con un equipo de **diez personas** durante las 11 semanas. La asignacion nominal se
confirma en la reunion de inicio.

| Rol | Cantidad | Responsabilidad |
|---|---|---|
| Director del proyecto | 1 | Planificar, controlar el avance y reportar al patrocinador |
| Arquitecto de software | 1 | Custodiar las decisiones de arquitectura y las puertas de calidad |
| Desarrollador movil (Flutter) | 2 | Aplicacion, base local y motor de mapas |
| Desarrollador de servidor (FastAPI/PostGIS) | 2 | Modulos de dominio, contratos y motor temporal |
| Ingeniero geospatial | 1 | Geometria, reticula y proveedor de imagen |
| Responsable de calidad (QA) | 1 | Pruebas, criterios de aceptacion y regresion |
| Analista funcional / proxy del ICA | 1 | Validar requisitos y reglas de negocio con el ICA |
| Responsable de datos y seguridad | 1 | Modelo de datos, retencion y datos personales |

> **Presupuesto.** Esta acta **no fija una cifra monetaria**, porque no existe aun el dato de volumen de
> predios, dispositivos e infraestructura (UQQ-008) ni la licencia del proveedor de imagen (UQQ-007). Lo
> que si queda establecido es la **estructura de costos** sobre la que el patrocinador definira el monto:
> personal (10 personas durante 11 semanas), infraestructura de servidor y almacenamiento, licencia o
> contrato del proveedor de imagen, y equipos de captura. MapLibre y Flutter no tienen costo de licencia.

# Supuestos y restricciones del proyecto {#sec-supuestos}

## Supuestos {#sec-supuestos-lista}

Se asumen ciertas mientras no se demuestre lo contrario. Si un supuesto falla, se revisa el alcance o el
cronograma.

- Los dispositivos que usara el tecnico tienen GPS y almacenamiento suficiente para el paquete de campo
  (RNF-020).
- La formula del MTD es `M / (T x D)` segun el Manual del ICA; lo que falta es el umbral de exportacion.
- Las trampas se pueden asignar a lotes (RN-013) y el tamaño de reticula se adopta por defecto (RN-004).
- El ICA facilitara el acceso a un interlocutor que valide las reglas de negocio.

## Restricciones {#sec-restricciones-lista}

- **Sin cobertura de red** en el predio: es la condicion normal, no la excepcion (RST-001).
- **Duración de 11 semanas** y equipo de 10 personas.
- **Tecnologias fijadas**: Flutter y MapLibre no se sustituyen sin decision registrada.
- **El desarrollo lo ejecuta un equipo de construccion** distinto del de arquitectura (RST-004).
- **Sin automatizar** el tramite de exportacion ni el diagnostico (RST-005, RST-006).

# Riesgos de alto nivel {#sec-riesgos}

Los riesgos se registran con su probabilidad, su impacto y su tratamiento. El detalle de la arquitectura
esta en el documento de arquitectura; aqui se resumen los que pueden mover el alcance, el cronograma o el
costo.

| ID | Riesgo | Prob. | Impacto | Tratamiento |
|---|---|---|---|---|
| RK-01 | Definicion oficial del MTD no entregada | Baja | Alto | Formula del Manual como base; el umbral queda como parametro versionado sin valor inventado |
| RK-02 | El concepto de lote no esta en la norma del ICA | Alta | Alto | Se trata como concepto configurable; el MTD queda condicionado a la asignacion trampa-lote |
| RK-03 | Cache offline inaceptable en el dispositivo | Media | Medio | RNF-020 limita el tamaño; descarga por zona |
| RK-04 | El contrato no permite cachear la imagen | Media | Alto | MapLibre reduce el riesgo tecnico; el contractual se resuelve en UQQ-007 antes de construir |
| RK-05 | Deriva del reloj de los dispositivos | Media | Alto | Validacion de deriva al iniciar la visita (R-T6) |
| RK-06 | Un tecnico sube datos del cuaderno mucho despues | Alta | Bajo | Alta retroactiva (R-T2) |
| RK-07 | Datos personales expuestos por fotografias | Media | Alto | Retencion diferenciada para evidencia (ADR-11) |
| RK-08 | La cadencia real de visita no coincide con la fuente | Media | Medio | Visita y lectura de trampa son series independientes |
| RK-09 | La estimacion en campo se confunde con el MTD emitido | Media | Alto | Marcador visual de estimacion (ADR-15) |
| RK-10 | El equipo empieza antes de que la arquitectura este estable | Media | Medio | Hito de cierre formal; documentos aprobados como contrato |
| RK-11 | Las puertas de calidad se relajan | Media | Alto | Comprobaciones bloqueantes y revision obligatoria por rol (ADR-17) |

# Partes interesadas {#sec-interesados}

Se identificaron seis partes interesadas. Las tres primeras son **usuarios del Sistema**; las tres ultimas
no acceden a el, pero condicionan el diseño.

| ID | Parte | Rol | Que necesita del Sistema | Interaccion |
|---|---|---|---|---|
| **INS** | Productor de durazno | Dueno o responsable del cultivo | Saber si su lote puede exportar y registrar lo que hizo, en lenguaje no tecnico | Usuario diario |
| **TIC** | Tecnico inspector del ICA | Ejecuta la visita y registra la inspeccion oficial | Registrar lecturas sin conectividad y que el historico no se altere | Usuario diario en campo, sin red |
| **SUP** | Supervisor o coordinador sectional del ICA | Consolida, supervisa y rinde cuentas | Ver el estado de todos los predios y exportar el resumen | Usuario de consulta, con red |
| **EICA** | Direccion Tecnica de Epidemiologia y Vigilancia Fitosanitaria | Define la norma y el programa | Consolidar los datos en los formatos oficiales | Consume datos en lote |
| **LAB** | Laboratorio de diagnostico de moscas de la fruta | Confirma la especie de los especimenes | Recibir la relacion de muestras con sus datos | Intercambio de datos |
| **ORG** | Organismos de control, certificacion y compradores | Auditan la trazabilidad de la fruta | Reconstruir el estado fitosanitario de un lote en una fecha | Solo consulta |

# Organizacion, roles y autoridad {#sec-organizacion}

| Rol | Quien | Autoridad y responsabilidad |
|---|---|---|
| Patrocinador (sponsor) | DTEVF del ICA *(por ratificar)* | Autoriza el Proyecto, aprueba el presupuesto y firma esta acta. Es quien emite el acta, no el director del proyecto |
| Director del proyecto | *(por designar)* | Dirige, planifica y controla; aplica los recursos del Proyecto; aprueba cambios dentro del umbral acordado |
| Arquitecto responsable | Equipo de Arquitectura de Software | Custodia las decisiones de arquitectura; ninguna fusion que cruce una frontera de modulo se aprueba sin su revision |
| Comite de proyecto | Patrocinador, director y arquitecto | Resuelve decisiones que afectan alcance, plazo o costo; autoriza el paso entre incrementos |
| Equipo de construccion | 10 personas (ver la seccion\nobreakspace\ref{sec-recursos}) | Ejecuta el trabajo por iteraciones segun la *Tabla de prioridades y MVP* |

**Autoridad del director del proyecto.** Puede asignar los recursos aprobados, aprobar cambios que no
alteren el alcance ni el presupuesto, y aceptar entregables. **No puede** modificar el alcance excluido
ni cambiar las tecnologias establecidas, sin decision del comite y registro de la decision de
arquitectura correspondiente.

# Criterios de exito y aceptacion {#sec-criterios}

El MVP se mide por su capacidad de cumplir la frase de cierre, no por el numero de historias cerradas. Los
criterios de aceptacion son los mismos diez del documento de prioridades.

| ID | Criterio | Como se verifica |
|---|---|---|
| A-01 | El tecnico completa una visita de al menos ocho trampas sin cobertura | Operacion real en modo avion |
| A-02 | Ningun registro confirmado se pierde al forzar el cierre de la app | RNF-009 |
| A-03 | El mismo envio repetido tres veces con corte de red no duplica | RNF-011 |
| A-04 | Un registro de hace treinta dias, enviado despues de uno de ayer, aparece antes en la linea de tiempo | RF-065 |
| A-05 | El MTD muestra valor anterior, valor nuevo y fecha del recalculo | RF-054 |
| A-06 | Un registro solapado queda en *revisar* y no altera la serie hasta confirmarlo | RF-066 |
| A-07 | Unas lecturas de prueba producen un MTD igual al calculo manual del Manual | RF-023, RN-001 |
| A-08 | Una trampa fuera del lote produce advertencia, no bloqueo | RF-012 |
| A-09 | El resumen del lote permite decidir en un minuto si hay problema | RF-070 |
| A-10 | Incorporar un predio nuevo se hace solo con configuracion, sin cambiar codigo | RNF-016 |

El Proyecto se considerara **terminado** cuando los diez criterios pasen sobre el incremento `v0.1` y el
acta de cierre quede firmada. Si algun criterio no pasa, el incremento correspondiente no se da por
cerrado aunque las historias esten marcadas como hechas.

# Gestion de cambios del acta {#sec-cambios}

Esta acta es un documento **sujeto a discusion y cambios**. Toda modificacion se registra y se aprueba,
para que el alcance, el plazo o las tecnologias no cambien por acuerdo tacito.

| Version | Fecha | Cambio | Estado |
|---|---|---|---|
| 0.1 | 14 de octubre de 2026 | Version inicial para discusion del equipo | Borrador |
| | | | |

Reglas de cambio:

1. Un cambio de **alcance incluido o excluido** lo aprueba el comite de proyecto y se refleja en la *Tabla
   de prioridades y MVP*, que es el documento de detalle.
2. Un cambio de **tecnologia** (por ejemplo, sustituir Flutter o MapLibre) exige una decision de
   arquitectura nueva registrada en el documento de arquitectura, antes de tocar el acta.
3. Un cambio de **plazo o presupuesto** lo aprueba el patrocinador.
4. Correcciones de redaccion no alteran la version y no requieren aprobacion.

# Aprobacion {#sec-aprobacion}

El acta queda aprobada con la firma del patrocinador y el visto bueno del director del proyecto. Mientras
no existan estas firmas, el Proyecto no se considera formalmente constituido y esta version sigue siendo
un borrador para discusion.

| Rol | Nombre | Firma | Fecha |
|---|---|---|---|
| Patrocinador (DTEVF, ICA) | | | |
| Director del proyecto | | | |
| Arquitecto responsable | | | |
| Interlocutor funcional del ICA | | | |

\vfill
\begin{center}
\small\itshape
Fin del documento. Esta acta autoriza el alcance del MVP y fija Flutter y MapLibre como tecnologias. Debe
leerse junto con el levantamiento de requerimientos, la arquitectura tecnologica y la tabla de
prioridades. Los identificadores M-nn, X-nn, A-nn, RK-nn y RST-nnn son los del resto de la entrega y son
estables: se usan como referencia en el control de cambios.
\end{center}
