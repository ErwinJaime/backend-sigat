---
title: "Tabla de prioridades y MVP"
subtitle: "Backlog priorizado del sistema de gestion y monitoreo de cultivos de durazno"
author: "Equipo de Arquitectura de Software"
date: "3 de octubre de 2026"
lang: es-CO
---

# Como usar este documento {#sec-uso}

Este documento es la **tabla de prioridades** que permite construir un MVP y, desde ahi, ir agregando
el resto de funcionalidades. Es el unico documento de la entrega que el equipo de desarrollo deberia
abrir a diario.

Los tres documentos de la entrega cumplen funciones distintas y esta separacion es deliberada:

| Documento | Para que se abre | Cuando se abre |
|---|---|---|
| *Levantamiento de requerimientos* | Para saber **que** hay que hacer y por que | Al iniciar cada historia |
| *Arquitectura tecnologica* | Para saber **como** esta construido y que reglas no se pueden romper | Al disenar cada modulo |
| **Este documento** | Para saber **en que orden** se construye | En la planificacion de cada sprint |

## La regla de priorizacion {#sec-regla}

La priorizacion no se hizo por lo importante que parece cada funcionalidad, sino por una pregunta
operativa: **que ocurre en el campo si esta funcionalidad no existe?**

Esa pregunta produce un orden distinto al intuitivo en cuatro casos concretos, y en los cuatro la
intuicion equivoca:

| Funcionalidad | Prioridad intuitive | Priorizacion real | Razon |
|---|---|---|---|
| Registrar el recorrido en el mapa | Alta | **Should** | Es informacion de apoyo. El dato que sostiene el tramite es la lectura de trampa, y esa se puede registrar sin recorrido |
| Evidencia fotografica | Alta | **Should** | El Manual del ICA no la exige. Es valor agregado, no cumplimiento |
| Codigo QR en las trampas | Alta | **Should** | El ICA identifica trampas por codigo numerico impreso. El QR es una comodidad de captura, no un estandar |
| Autorreporte del productor (fumigaciones, cosecha) | Media | **Must** | Es el unico registro que el productor hace sin el tecnico, y sin el el sistema no seria de gestion de cultivo sino un formulario de inspeccion |

## Escala de prioridad {#sec-escala}

Se usan tres etiquetas, que son las unicas que el equipo de desarrollo necesita para decidir que entra
en el sprint:

| Etiqueta | Significado | Criterio de inclusion |
|---|---|---|
| **P0 · Nucleo** | Sin esto el sistema no cumple su proposito | Su ausencia impide el uso principal en campo |
| **P1 · Necesario** | Su ausencia no impide el uso principal, pero produce un defecto visible que el usuario nota | Se puede sustituir por un procedimiento manual durante la operacion, con costo |
| **P2 · Valor** | Su ausencia solo se nota en tiempos | Se puede aplazar sin impacto en el tramite |

# El MVP {#sec-mvp}

## Criterio de cierre del MVP {#sec-mvp-cierre}

El MVP se define por lo que **permite hacer de punta a punta**, no por la cantidad de funciones que
tenga. El criterio de corte es una frase que el equipo de desarrollo debe poder verificar de punta a
punta:

> **Un tecnico puede, en un predio sin cobertura, recorrer sus lotes, registrar la lectura de sus
> trampas con su codigo ICA, cerrar la visita, subirla despues aunque haya llegado antes el dato de una
> visita posterior, y ver el resumen del lote con el MTD, el umbral y la fecha de efecto.**

Si el sistema no puede hacer eso completo, no es un MVP: es una demostracion.

## Backlog del MVP {#sec-backlog}

Ordenado por la secuencia en que debe construirse, no solo por prioridad. La columna **Depende de** es
la que mas importa: es la que convierte esta tabla en un plan.

### Iteracion 1 - Fundamentos del dominio {#iter-1}

Sin esto no hay sobre que construir. Es la iteracion mas importante del proyecto y la que mas riesgo
tiene, porque sus errores se propagan a todas las demas.

| ID | Alcance | Requisitos | Prioridad | Depende de |
|---|---|---|---|---|
| M-01 | Esquema de datos con versionado de geometria y las tres marcas temporales | RDD-001 a RDD-010, RST-010 | **P0** | - |
| M-02 | Asignacion trampa-lote y validacion de la pertenencia de la trampa | RF-013, RF-012, RN-005, RN-006, RN-013 | **P0** | M-01 |
| M-03 | Configuracion del programa de inspeccion por predio, versionada | RF-080, RF-081, ADR-07 | **P0** | M-01 |
| M-04 | Motores de umbral y de etapas fenologicas versionados | RF-024, RN-003, RN-012 | **P0** | M-01, M-03 |
| M-05 | Calculo del MTD con la formula del Manual | RF-023, RN-001 | **P0** | M-01, M-02 |

### Iteracion 2 - Captura sin conexion {#iter-2}

Es el nucleo funcional. Sin esta iteracion no hay sistema, porque el problema del proyecto es que la
visita ocurre sin senal.

| ID | Alcance | Requisitos | Prioridad | Depende de |
|---|---|---|---|---|
| M-06 | Base local espacial con poligonos de lote y celda consultables sin red | RF-005 a RF-007, ADR-09 | **P0** | M-01, M-02 |
| M-07 | Paquete de campo por predio, versionado e invalidado al cambiar la configuracion | RF-004, RF-068 | **P0** | M-03, M-06 |
| M-08 | Captura de lectura de trampa con su codigo ICA | RF-020, RF-021, RNF-001 | **P0** | M-02, M-07 |
| M-09 | Validacion de coherencia trampa-lote-ubicacion, con advertencia y no bloqueo | RF-012 | **P0** | M-08 |
| M-10 | Persistencia local inmediata y cola de salidas con reintentos | RF-061, RF-062 | **P0** | M-08 |
| M-11 | Visita completa y su cierre sin conexion | RF-060, ADR-08 | **P0** | M-10 |

### Iteracion 3 - Sincronizacion y regla temporal {#iter-3}

Esta iteracion es la que resuelve el problema central del proyecto. Es la mas delicada y la que mas
conviene construir con pruebas desde el primer dia.

| ID | Alcance | Requisitos | Prioridad | Depende de |
|---|---|---|---|---|
| M-12 | Endpoint de carga idempotente por operaciones | RF-062, RF-063, RNF-011 | **P0** | M-10 |
| M-13 | Clasificacion de operaciones: alta, alta retroactiva, correccion, repetida, a revisar, rechazada | RF-064, RF-065, RF-066, ADR-04 | **P0** | M-12 |
| M-14 | Motor temporal: orden canonico, correccion versionada, inmutabilidad de la fecha | RF-050, RF-051, RF-052, ADR-02, ADR-03 | **P0** | M-12, M-01 |
| M-15 | Reproceso asincrono del MTD y reemision del concepto con fecha de efecto | RF-054, RF-053 | **P0** | M-13, M-14, M-05 |
| M-16 | Linea de tiempo del lote | RF-050 | **P0** | M-14 |
| M-17 | Bitacora de auditoria append-only | RF-083 | **P0** | M-01 |

### Iteracion 4 - Autorreporte del productor {#iter-4}

Es lo que convierte el sistema en un sistema de gestion de cultivo y no solo en un formulario de
inspeccion. Va cuarto porque no es urgente para el tramite de exportacion, pero es lo que asegura el
uso diario.

| ID | Alcance | Requisitos | Prioridad | Depende de |
|---|---|---|---|---|
| M-18 | Autenticacion, roles y perfil de usuario por predio | RF-001, RF-002, RF-082 | **P0** | M-03 |
| M-19 | Aplicacion movil para el productor con lenguaje no tecnico | RNF-003, RNF-004, RN-016 | **P0** | M-18 |
| M-20 | Registro de aplicaciones fitosanitarias y consulta de la ultima por lote | RF-040, RF-041 | **P0** | M-19, M-14 |
| M-21 | Registro de cosecha esperada y real | RF-042, RDD-009 | **P0** | M-19, M-14 |
| M-22 | Marcacion del linaje en todo registro y reglas diferenciadas | RN-014, ADR-07 | **P0** | M-14 |

### Iteracion 5 - Consulta y resumen {#iter-5}

Con esto el sistema empieza a devolver valor a sus tres tipos de usuario. Va al final del MVP porque sin
las iteraciones anteriores no hay nada que consultar, pero es la iteracion que el ICA va a notar
primero.

| ID | Alcance | Requisitos | Prioridad | Depende de |
|---|---|---|---|---|
| M-23 | Resumen del lote ordenado por riesgo de exportacion | RF-070, RF-028 | **P0** | M-15, M-20, M-21 |
| M-24 | Historico de inspecciones y autorreportes con filtros | RF-072 | **P0** | M-16, M-22 |
| M-25 | Resumen del predio con tendencia del MTD | RF-071 | **P1** | M-15 |
| M-26 | Exportacion del resumen de visita a documento imprimible | RF-073, RI-005 | **P1** | M-23 |
| M-27 | Superficie de consulta para el supervisor | RI-009 | **P0** | M-23, M-24 |

# Fuera del MVP {#sec-fuera}

La exclusion de un requisito se documenta con la misma disciplina que su inclusion: con un motivo.

| ID | Alcance excluido | Requisitos | Motivo | Cuando vuelve |
|---|---|---|---|---|
| X-01 | Enlace del resultado de laboratorio | RF-026 | Depende de un intercambio con el laboratorio cuyo formato no esta definido (UQQ-006). El estado *pendiente de diagnostico* si se implementa en el MVP, porque sin el los datos se pierden de vista | v0.2 |
| X-02 | Relacion de muestras automatica | RF-027 | El formato en papel puede seguir usándose en el MVP sin perdida de informacion | v0.2 |
| X-03 | Evidencia fotografica | RF-033 | El Manual del ICA no la exige. Es valor agregado, y ademas es un activo de riesgo por datos personales (ADR-11) | v0.4 |
| X-04 | Recorrido de la visita | RF-009 | Es informacion de apoyo. El dato que sostiene el tramite es la lectura de trampa | v0.4 |
| X-05 | Marcado geografico de hallazgos | RF-010 | Puede registrarse por celda de reticula sin necesidad de un punto preciso | v0.4 |
| X-06 | Indicadores de gestion de predios | RF-075 | Se calculan despues; el historico ya estara disponible y el indicador es una consulta | v0.5 |
| X-07 | Alertas de vencimiento y de incumplimiento | RF-074 | Depende del canal de comunicacion institucional, que no esta definido | v0.5 |
| X-08 | Asignacion y reasignacion de visitas | Programacion de visitas, descartada en el levantamiento | Pertenece al proceso de programacion del ICA, no al de registro. Ademas, reasignar una visita **no es recuperacion de datos**: el estado del cultivo y de las trampas cambia entre una visita y otra, de modo que los conteos de la visita reasignada no son comparables con los de la original | v0.6 |
| X-09 | Codigo QR de trampa | RF-011 | Mecanismo propuesto, no estandar del ICA (el Manual no lo menciona). El MVP debe funcionar con seleccion de la trampa de la lista | v0.4 |
| X-10 | Geometria versionada en detalle | RF-085 | El MVP versiona la geometria en el dato, pero sin interfaz de redibujo | v0.5 |
| X-11 | Diagnostico automatico de plagas y enfermedades | RST-006 | Restriccion explicita: no se implementa | No previsto |
| X-12 | Tramite de licencia fitosanitaria y certificado de exportacion | RST-005 | El sistema produce el insumo; el tramite sigue siendo parte del proceso institucional | No previsto |

# Resumen de esfuerzo {#sec-esfuerzo}

## Distribucion por iteracion {#sec-esfuerzo-dist}

| Iteracion | Alcance | Nucleo (P0) | Necesario (P1) | Peso relativo |
|---|---|---|---|---|
| 1 | Fundamentos del dominio | 5 | 0 | Alto |
| 2 | Captura sin conexion | 6 | 0 | Muy alto |
| 3 | Sincronizacion y regla temporal | 6 | 0 | Muy alto |
| 4 | Autorreporte del productor | 5 | 0 | Medio |
| 5 | Consulta y resumen | 3 | 2 | Medio |
| **MVP** | | **25** | **2** | |

> **Lectura de esta tabla.** Las tres primeras iteraciones concentran 17 de los 25 elementos del nucleo y
> son las unicas que no admiten recorte: si falta cualquiera de ellas, el sistema no cumple su
> proposito. Las iteraciones 4 y 5 se pueden comprimir, con la unica excepcion de M-18, M-19 y M-20, que son
> lo que asegura el uso diario por parte del productor.

> **Orden de las iteraciones.** Este orden es una recomendacion, no una imposicion. Si el equipo decide
> construir la iteracion 4 antes que la 3, la consecuencia no es tecnica sino de proceso: el productor
> empezaria a introducir datos que el servidor todavia no sabe interpretar, y habria una ventana en la que
> habria datos en el dispositivo que todavia no se pueden consultar. Eso no es un error, pero es una
> decision que conviene tomar a conciencia.

## La secuencia de riesgo {#sec-riesgo-sec}

Tres hitos de decision para el proyecto, cada uno en un punto donde el error es todavia
corregible:

| Hito | Momento | Que se verifica | Que se hace si falla |
|---|---|---|---|
| **H1 · El modelo temporal esta cerrado** | Al terminar la iteracion 3 | Un alta retroactiva inserta en su posicion correcta y no altera el pasado | Se replantea el modelo antes de construir sobre el. Es el punto de control mas importante del plan |
| **H2 · La visita funciona en modo avion** | Al terminar la iteracion 2 | Una visita completa se ejecuta y se cierra sin ninguna llamada de red | Se corrige el nucleo de almacenamiento local antes de seguir |
| **H3 · El resumen es util** | Al terminar la iteracion 5 | El resumen del lote permite decidir en un minuto si un lote tiene problema | Se rediseña la informacion del resumen, que es barato de cambiar a esta altura |

# Dependencias externas del MVP {#sec-dependencias}

Cuatro dependencias pueden bloquear el MVP. Se listan porque conviene saber de antemano cuales son y
cual es el plan cuando no llegan.

| Dependencia | Que se necesita | Plan si no llega |
|---|---|---|
| **Umbral de exportacion** (UQQ-004) | La expresion numerica del umbral que habilita o bloquea la exportacion, con su norma | El sistema calcula el MTD y **no emite concepto**. La vista del concepto queda vacia con un mensaje explicito. Es preferible a emitir un valor inventado, porque un concepto de aptitud falso es un problema institucional, no un detalle de software |
| **Asignacion trampa-lote** (RN-013) | Confirmacion de que las trampas se pueden asignar a lotes y con que criterio | Se usa una asignacion por defecto configurada por el administrador del predio, marcada como estimada en la interfaz |
| **Tamano de reticula** (UQQ-005) | El tamano de celda en metros | Se adopta el valor por defecto que exige RN-004: mayor a 60 metros, y en la practica un multiplo de esa distancia |
| **Proveedor de imagen** (UQQ-007) | Un proveedor cuya licencia permita cache en el dispositivo | Se usa una imagen ortometrica propia del predio, o un fondo vectorial minimo con los limites de lote y la reticula, que es lo unico imprescindible para poder llenar un formulario. El sistema debe seguir siendo utilizable en este modo degradado |

# Dependencias tecnicas internas {#sec-dep-tecnicas}

El orden de las historias esta sujeto a una restriccion adicional que no es de negocio sino de la base de
datos: **los modulos de datos deben existir antes que los modulos que los consultan**. En la practica,
esto significa que el orden de tabla de arriba ya incorpora las restricciones reales y que ninguna
historia puede adelantarse por una razon tecnica.

El camino critico del MVP, en el sentido de que una demora en cualquiera de estos elementos retrasa todo
lo demas, es:

> **M-01 (esquema) → M-02 (asignacion trampa-lote) → M-06 (base local espacial) → M-08 (captura de
> lectura) → M-10 (persistencia y cola) → M-12 (endpoint idempotente) → M-13 (clasificacion) → M-15
> (reproceso del MTD) → M-23 (resumen del lote)**

Nueve elementos. Si el proyecto tiene que recortar, el lugar correcto para recortar no es este camino sino
las iteraciones 4 y 5, y dentro de ellas lo que no toque M-18, M-19 y M-20.

# Como se mide que el MVP esta terminado {#sec-medicion}

Un MVP no se mide por la cantidad de historias cerradas, sino por la capacidad de hacer la frase de la
seccion de criterio de cierre. Los criterios de aceptacion son:

| ID | Criterio | Como se verifica |
|---|---|---|
| A-01 | El tecnico completa una visita de al menos ocho trampas en un predio sin cobertura, sin que ninguna accion dependa de la red | Operacion real en modo avion |
| A-02 | Ningun registro confirmado se pierde tras forzar el cierre de la aplicacion y reiniciar el dispositivo | RNF-009 |
| A-03 | El mismo envio repetido tres veces, con corte de red, no produce mas de un registro | RNF-011 |
| A-04 | Un registro con fecha de observacion de hace treinta dias, enviado despues de uno de ayer, aparece en la linea de tiempo **antes** que el de ayer | RF-065 |
| A-05 | El MTD del periodo afectado muestra valor anterior, valor nuevo y fecha del recalculo | RF-054 |
| A-06 | Un registro solapado queda en estado *revisar* y no altera la serie hasta que el usuario confirme | RF-066 |
| A-07 | Un conjunto de lecturas de prueba produce un MTD exactamente igual al calculo manual con la formula del Manual | RF-023, RN-001 |
| A-08 | Una trampa fuera del lote asignado produce advertencia y exige confirmacion, no un bloqueo | RF-012 |
| A-09 | El resumen del lote permite decidir en un minuto si ese lote tiene un problema de exportacion | RF-070 |
| A-10 | Incorporar un predio nuevo se hace solo con datos de configuracion, sin cambiar codigo | RNF-016 |

\vfill
\begin{center}
\small\itshape
Fin del documento. Este documento debe leerse junto con el levantamiento de requerimientos y la
arquitectura tecnologica. Los identificadores M-nn, X-nn y A-nn son estables y se usan como
referencia en el control de cambios.
\end{center}