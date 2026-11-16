---
title: "Propuesta de arquitectura"
subtitle: "Aplicación móvil para la inspección fitosanitaria de lotes de durazno con fines de exportación"
author: "Equipo de Arquitectura de Software"
date: "30 de septiembre de 2026"
lang: es-CO
---

# Resumen ejecutivo {#sec-resumen}

El ICA adelanta, para predios productores de durazno destinados a exportación, un conjunto de
inspecciones que hoy se ejecutan en papel. Un técnico llega al predio con una imagen satelital
impresa o consultada en su teléfono, recorre los lotes en un orden que él mismo fija, anota en un
cuaderno cinco datos por lote (índice MTD, etapa fenológica, cumplimiento de buenas prácticas
agrícolas, estimación de producción y enfermedades observables) y luego transcribe ese cuaderno a
planillas. El problema no es la transcripción: es que **el papel pierde la noción de cuándo se
tomó cada medición**.

Sobre esa pérdida se acumulan tres efectos. Primero, el histórico de un lote deja de ser una serie
ordenada y se convierte en un montón de anotaciones sin fecha confiable, de modo que es imposible
responder la única pregunta que importa en un trámite de exportación: *¿este lote estaba en
condición de exportar el día en que se exportó la fruta?* Segundo, cuando el técnico regresa al
predio y sube al sistema datos de una visita anterior, no hay forma de distinguir un dato nuevo de
una corrección de uno viejo, y el software termina aceptando la última escritura y reescribiendo el
pasado. Tercero, al no existir una copia digital estructurada, el ICA no puede construir indicadores
sobre cuáles predios cumplen mejor o peor.

Este documento propone la arquitectura de un sistema que resuelve los tres efectos, y propone
además una forma de organizar el trabajo de un equipo de diez personas durante once semanas.

Dos ideas sostienen toda la propuesta:

1. **El sistema es offline-first de verdad.** La señal no es un escenario excepcional, es el
   estado normal del predio durante cuatro a seis horas. La arquitectura se diseña suponiendo que
   la transmisión de datos ocurre *después* de la visita, nunca durante ella.

2. **La fecha de la medición es un dato de primer orden del dominio, no un metadato técnico.** El
   sistema separa tres relojes —cuándo se observó, cuándo se digitó y cuándo llegó al servidor— y
   todas las correcciones se conservan como versiones en lugar de sobrescribirse. Esta es
   la decisión de arquitectura que resuelve el enunciado, y por eso recibe la mayor parte del
   esfuerzo de modelado.

Sobre la forma de trabajar: este equipo no se va a limitar a producir diagramas una vez y entregar.
Va a construir un conjunto de **skills**, entendidas como recetas de trabajo reproducibles, tal
como se explica en la sección 4. Cada skill tiene un objetivo, entradas, un procedimiento, una
salida esperada y límites explícitos. El beneficio es doble: los diagramas y contratos se
producen siempre igual, con el mismo nivel de detalle, sin depender de quién esté disponible esa
semana; y el trabajo queda registrado en un formato legible por alguien que no estuvo en la
reunión.

La propuesta entrega, en once semanas, el modelo de dominio, el modelo temporal, los cuatro niveles
C4, las vistas dinámica y de despliegue, dieciséis decisiones de arquitectura registradas, los
contratos de datos y de API, y un plan de trabajo priorizado para el equipo de desarrollo.

\newpage

# Contexto y problema {#sec-problema}

## El proceso actual, tal como ocurre {#sec-asis}

El ciclo productivo del durazno se organiza en lotes que se encuentran en fases de crecimiento
distintas, de manera que exista producción continua durante todo el año. El ICA visita el predio,
recorre lote por lote y levanta la información fitosanitaria que sustenta la habilitación del
lote para exportar.

Hoy ese levantamiento tiene estas características:

- **Inspección itinerante, no georreferenciada.** El técnico marca el recorrido sobre una imagen
  satelital que consulta en un buscador y que a veces lleva impresa. El orden de recorrido lo
  decide él en el momento.
- **Registro en papel.** Cinco grupos de datos por lote, anotados a mano durante el trayecto.
- **Doble digitación.** El cuaderno se vuelve a pasar a una planilla en la oficina del municipio.
- **Memoria como base de datos.** Cuando llega la siguiente visita, no existe un registro anterior
  consultable que permita comparar, salvo el cuaderno viejo, que además no siempre vuelve al
  archivo.
- **Sin histórico por lote confiable.** No se puede responder "¿cómo venía este lote hace tres
  semanas?".

## Descomposición del problema en requisitos de arquitectura {#sec-descomp}

Un enunciado de usuario rara vez es un requisito. Esta propuesta no empieza por la solución, sino
por descomponer el enunciado en restricciones que la arquitectura debe satisfacer. Cada
restricción se referencia con un identificador estable (`R-01`…`R-12`) y se traza después
hasta las decisiones y los diagramas que la atienden.

: **R-01 Captura íntegra sin conectividad.** La visita debe poder realizarse, registrarse y
cerrarse por completo en un predio sin cobertura de datos celulares ni wifi.

: **R-02 Trazabilidad temporal de la medición.** El sistema debe saber, para cada dato, cuándo se
tomó en campo, cuándo se digitó y cuándo se sincronizó.

: **R-03 Aceptación de carga fuera de orden.** Un técnico puede subir mediciones con fecha de
observación posterior a datos ya sincronizados, y también puede subir datos anteriores a datos ya
sincronizados. En ambos casos el histórico resultante debe ser correcto.

: **R-04 Conservación del pasado.** Una corrección de un dato ya sincronizado no debe destruir el
valor anterior; debe quedar registrada como corrección fechada.

: **R-05 Geometría del predio y retícula de lotes.** El sistema debe mostrar la imagen satelital del
predio con los límites de cada lote y una retícula superpuesta, y permitir rellenar los campos por
lote.

: **R-06 Personalización por predio.** La solución no es un producto genérico de fitosanitología.
Se configura para predios concretos: variedad, ciclo, umbrales, checklist de buenas prácticas,
catálogo de enfermedades, geometría de lotes.

: **R-07 Umbral MTD como parámetro, no como constante.** El valor que habilita o bloquea la
exportación es un parámetro del programa de inspección vigente en la fecha de la medición.

: **R-08 Concepto de aptitud fechado.** La habilitación de un lote se emite con una fecha de efecto,
y debe poder reconstruirse tal como se habría emitido en cualquier fecha pasada.

: **R-09 Consumo institucional.** El supervisor y el proceso de exportación del ICA deben poder
consultar el histórico y el concepto vigente, sin depender del cuaderno.

: **R-10 Trazabilidad de la actuación.** Toda modificación relevante debe registrar quién la hizo,
cuándo y qué cambió.

: **R-11 Protección de datos personales.** El sistema registra datos de técnicos y de productores;
debe atender la Ley 1581 de 2012 (Ley General de Protección de Datos Personales en Colombia).

: **R-12 Entregable reutilizable por otro equipo.** La arquitectura debe quedar documentada de modo
que un equipo de desarrollo que no participó en su elaboración pueda construir sin volver a
preguntar lo ya decidido.

## Qué no vamos a resolver {#sec-no-objetivos}

Declarar los límites desde el principio evita el crecimiento descontrolado que este tipo de proyectos
suelen sufrir.

- **No** se construye un sistema fitosanitario general. Se construye para durazno de exportación.
- **No** se implementa el trámite de la licencia fitosanitaria de movilización ni el certificado de
exportación. El sistema **produce** el insumo; el trámite sigue siendo parte del proceso institucional.
- **No** se sustituye la imagen satelital. Se consume la de un proveedor existente, dentro de su
licencia.
- **No** se diseña la interfaz visual. Se define la arquitectura de información y los flujos
críticos, no el diseño de pantallas.
- **No** se escribe código en esta fase. Se entregan contratos ejecutables como prueba, pero no
lógica de negocio implementada.
- **No** se dimensiona la infraestructura hasta tener un dato de campo sobre número de predios,
frecuencia de visita y técnicos activos. El dimensionamiento se deja como pregunta abierta (ver
sección 12, P-08).

## Referencia normativa {#sec-norma}

El sistema se apoya en la Resolución ICA 995 de 2019, que establece las medidas fitosanitarias
para el control de la mosca del Mediterráneo (*Ceratitis capitata*) en predios productores de
durazno y plantas empacadoras, y en la Resolución 106407 de 2021 sobre manejo de moscas de la fruta.
Las áreas declaradas de baja prevalencia para la especie incluyen, entre otras, las regiones
productoras de Boyacá, Santander y Norte de Santander.

> **Advertencia metodológica que la arquitectura asume.** Esta propuesta **no interpreta** la
> Resolución 995 de 2019. El texto normativo es la fuente de verdad y su lectura corresponde al ICA.
> El trabajo de arquitectura se limita a construir un modelo de datos donde el umbral, el
> período de vigencia, la fórmula de agregación y el catálogo de criterios son **configurables y
> versionados**, de modo que cuando el ICA entregue la definición oficial, se cargue como
> configuración y no requiera rediseño.

\hspace{0pt}\textbf{Definición operativa de MTD usada en este documento.} A lo largo de la
propuesta, MTD designa el índice de monitoreo de moscas de la fruta que, calculado sobre el
muestreo de un lote y su periodo, se contrasta contra un umbral para determinar la aptitud del
lote para exportar. La arquitectura lo trata como **valor parametrizable** con la forma
`MTD = Σ moscas capturadas / (número de trampas × días de exposición)`, y registra como pregunta
abierta (P-01) confirmar con el ICA la fórmula oficial, la unidad, la expresión numérica del
umbral y la duración del ciclo de trampeo que la resolución establece.

# Marco de referencia: el modelo C4 {#sec-c4}

## Por qué C4 y no otro método {#sec-why-c4}

El modelo C4 (Simon Brown) organiza una arquitectura en cuatro niveles de zoom con granularidad
creciente:

| Nivel | Nombre | Pregunta que responde | Producto |
|---|---|---|---|
| C0 | Contexto de sistema | ¿El sistema está en el mundo correcto? | Diagrama de contexto |
| C1 | Contenedores | ¿En qué unidades de software y hardware se ejecuta? | Diagrama de contenedores |
| C2 | Componentes | ¿De qué piezas se compone un contenedor? | Diagrama de componentes |
| C3 | Código | ¿Cómo se refleja esto en archivos? | Diagramas de clases / esquema |

C4 se acompaña de dos vistas adicionales que resultan tan importantes como los propios niveles
para este problema:

- **Vista dinámica**: muestra cómo los contenedores colaboran en un escenario concreto.
- **Vista de despliegue**: muestra dónde se ejecuta cada contenedor en el mundo físico.

: **Por qué la vista dinámica es el corazón de esta propuesta.** En este sistema, el lugar donde
se decide si la arquitectura es correcta o no es un escenario de interacción: la visita en campo
seguido de la carga tardía y fuera de orden. Un diagrama de contenedores preciso pero que no
sobreviva a ese escenario es un diagrama equivocado. Por eso la sección 6 se dedica íntegramente a
la vista dinámica.

: **Por qué la vista de despliegue es obligatoria y no opcional.** El problema tiene una dimensión
física inescapable: la señal desaparece en la mitad del recorrido. Una arquitectura que no dibuje
dónde vive cada pieza y bajo qué condiciones pierde el enlace está incompleta.

## Qué se entrega en esta fase y qué se aplaza {#sec-alcance-c4}

Con un equipo de diez personas en once semanas, entregar los cuatro niveles de C4 más dos vistas es
factible, pero solo si se aplica una regla explícita de profundidad:

| Nivel | Producto | Profundidad en esta fase | Condición |
|---|---|---|---|
| C0 | Contexto de sistema | Completa | Requisito R-01…R-09 cerrado |
| C1 | Contenedores | Completa | Sin excepciones; es la frontera con el equipo de desarrollo |
| C2 | Componentes | **Selectiva**: solo el *Servicio de Registro e Historial* y el *Motor de Sincronización* | Son los que concentran la complejidad |
| C3 | Código | **No se entrega.** Se entrega el contrato de datos y el de API | Se delega al equipo de desarrollo |
| Dinámica | Escenario de visita, carga y alta retroactiva | Completa | Es el criterio de aceptación arquitectónico |
| Despliegue | Campo ↔ nube | Completa | Deriva de R-01 y R-09 |

Esta tabla es una decisión, no una omisión. Documentada, es defendible; no documentada, se vuelve
un hueco que alguien descubrirá tarde.

\newpage

## Nivel 1 — Contexto de sistema {#fig-contexto}

![Contexto de sistema. La aplicación móvil de inspección y el backend de sincronización dentro de la frontera del sistema; el resto son actores o sistemas externos.](diagrams/c4-nivel1-contexto.png){width=\textwidth #figura-c4-nivel1-contexto}

**Qué establece la vista.** El sistema de alcance es único y tiene una frontera clara: captura de
inspección en campo, estructura del predio y lotes, histórico temporal y concepto de aptitud por
lote. Todo lo demás es sistema externo.

**Decisiones de frontera que se toman aquí y no se revisan después:**

- **El proveedor de imágenes satelitales es externo.** El sistema consume mosaicos; no genera,
  procesa ni almacena imágenes de satélite por cuenta propia. La consecuencia arquitectónica es que
  el uso de la imagen queda sujeto a un contrato de licencia cuyo uso (términos de servicio,
  cuota, caché permitido) es un riesgo de proyecto, no un detalle técnico. Se registra como riesgo
  RK-04 en la sección 11.
- **La autenticación se delega al directorio institucional.** El sistema no administra credenciales
  de empleados del ICA; valida identidades contra el proveedor institucional.
- **El consumo del histórico y del concepto se expone como servicio.** No es un reporte descargado
  a mano: el supervisor y el proceso de exportación consultan el sistema.

## Nivel 2 — Contenedores {#fig-contenedores}

![Contenedores del sistema. La aplicación móvil, el servicio de sincronización, la base de datos operativa y la capa de integración, con los protocolos y el almacenamiento de cada uno.](diagrams/c4-nivel2-contenedores.png){width=\textwidth #figura-c4-nivel2-contenedores}

**Los nueve contenedores y por qué existen.**

| # | Contenedor | Responsabilidad | Por qué es un contenedor y no una clase |
|---|---|---|---|
| 1 | **Aplicación móvil** | Toda la interacción en campo: mapa, formularios, cálculo de ruta, almacenamiento local y cola de envío | Corre en un dispositivo con recursos, sistema operativo y ciclo de vida propios; su modo de fallo (perder señal) es un hecho de diseño |
| 2 | **API de Inspección** | Contrato HTTP para el dispositivo y para consumidores internos | Frontera de despliegue y de versionado; permite evolucionar sin romper el cliente ya instalado en campo |
| 3 | **Servicio de Sincronización** | Recibe lotes idempotentes, decide qué se acepta, qué se rechaza y qué entra en conflicto, y devuelve cursor de avance | Aísla la complejidad de la carga fuera de orden; es el componente que da nombre al problema |
| 4 | **Servicio de Registro e Historial** | Almacena mediciones de forma *append-only* y resuelve el orden temporal y las versiones | Único lugar donde se decide cómo se ordena el pasado; ver sección 6 |
| 5 | **Servicio de Configuración de Predios** | Programa de inspección por predio: ciclo de 52 semanas, umbral MTD, checklist de buenas prácticas, catálogo de enfermedades | Materializa R-06 y R-07: la personalización no vive en el código sino en datos |
| 6 | **Servicio de Imágenes y Evidencia** | Mosaicos satelitales, fotografías de lote y almacenamiento de binarios | Almacenamiento de objetos con ciclo de vida distinto al transaccional; no debe ir a la base de datos |
| 7 | **Servicio de Reportes y Concepto de Aptitud** | Emite el concepto por lote y periodo, y responde consultas de histórico | Lectura analítica sobre datos ya cerrados; se puede aislar del camino crítico |
| 8 | **Base de datos de registro** | Series históricas, geometrías, configuración, bitácora | Estado durable; exige geometría (PostGIS) y versionado de filas |
| 9 | **Almacenamiento de objetos** | Binarios de imagen y fotografías | Volumen alto, acceso por referencia, política de retención diferente |

**La frontera más importante de la Figura 2** es la línea punteada naranja que separa el
dispositivo del resto: en la práctica hay un actor dentro de la frontera y otro fuera, y **no es
una frontera de red sino una frontera de verdad**. Ningún evento de negocio debe depender de que
exista conexión durante la visita.

## Nivel 3 — Componentes {#fig-componentes}

![Componentes de la aplicación móvil y del servicio de sincronización. El detalle se limita a los componentes con responsabilidades que condicionan la arquitectura; el resto se describe por contrato.](diagrams/c4-nivel3-componentes.png){width=\textwidth #figura-c4-nivel3-componentes}

El nivel 3 se profundiza únicamente donde está la complejidad. Los componentes del
*Servicio de Registro e Historial* son:

- **Endpoint de sincronización** — recibe lotes de operaciones idempotentes.
- **Validador de invariantes** — forma, dominio permitido, pertenencia del lote y coherencia de
  fechas. Descarta lo mal formado *antes* de tocar el historial, para que un error de captura en
  campo no contamine la serie.
- **Motor temporal bitemporal** — ordena por fecha de observación, inserta altas retroactivas y
  versiona correcciones. **Es el componente que justifica el proyecto.**
- **Motor de umbrales MTD** — agrega el muestreo del periodo y lo contrasta contra el umbral
  vigente *a la fecha del período*, no contra el vigente hoy.
- **Registrador de auditoría** — bitácora *append-only* de toda acción, con actor y huella.
- **Publicador de eventos** — emite el cambio de estado de aptitud con su fecha de efecto, para que
  los consumidores (reportes, notificaciones, exportadores) reaccionen a tiempo.
- **Generador de concepto** — produce el documento de aptitud por lote y periodo.
- **Almacén de evidencia** — vincula fotografías y mosaicos a cada medición concreta.

\newpage

# Método de trabajo: arquitectura por *skills* {#sec-skills}

## La idea {#sec-idea-skill}

Una *skill* es, en este contexto, una receta de trabajo: una descripción estructurada de **una tarea
que se repite** y que merece ejecutarse siempre de la misma manera. El nombre viene de los
*agent skills* de los entornos de desarrollo asistido por IA, donde una skill empaqueta
instrucciones para una tarea recurrente en lugar de depender de que alguien escriba el mismo prompt
correcto cada vez.

Tres propiedades hacen que el concepto sea útil para un equipo de arquitectura, y no solo para un
agente:

1. **Estandariza la salida.** Quien produzca un diagrama de contenedores lo producirá con los
   mismos elementos, las mismas decisiones anotadas y el mismo nivel de detalle, lo haga la persona
   que lo haga.
2. **Separa el *qué* del *cómo*.** La descripción dice qué skill se está aplicando; el cuerpo de la
   skill dice exactamente en qué orden y con qué criterio. Quien audita el resultado sabe qué
   receta se aplicó.
3. **Es legible por alguien que no estuvo.** Una skill bien escrita es un documento de
   incorporación: un desarrollador nuevo puede entender por qué la arquitectura es como es leyendo
   la skill que la produjo.

## La regla que evita el exceso {#sec-regla-skill}

La regla que gobierna la creación de skills es la misma que gobierna cualquier biblioteca: **no se
crea una skill por cada posible tarea**. Existe un umbral explícito.

> **Regla de umbral.** Se crea una skill solo si se cumplen **las tres** condiciones:
>
> 1. **Repetición**: la tarea se va a ejecutar al menos tres veces durante el proyecto.
> 2. **Método**: hay un procedimiento que merece conservarse, no solo una intención.
> 3. **Patrón estable**: se reconoce que la salida tendrá siempre la misma forma.
>
> Si falta alguna de las tres, la tarea **no** se convierte en skill: se resuelve con un prompt
> puntual o con una plantilla. Este proyecto produce **16 skills**; una lista de 60 no sería más
> completa, sería menos útil.

## Formato canónico de una skill {#sec-formato-skill}

Este es el formato que el equipo adopta para todas las skills del proyecto. Cada skill es un
archivo de texto con encabezado y cuerpo, y por diseño **no contiene implementación**: describe
cómo se decide, no cómo se programa.

```text
---
name: nombre-de-la-skill
description: Qué hace la skill y cuándo debe invocarse. Una sola frase
             que permita a un agente o a una persona decidir si aplica.
---

## Qué hace
## Cuándo usarla
## Cuándo NO usarla
## Entradas        (qué se necesita tener antes de empezar)
## Procedimiento    (los pasos, en orden, con el criterio de decisión en cada uno)
## Salida          (qué artefactos produce y con qué nombres exactos)
## Límites          (qué NO hace esta skill y a quién le corresponde)
```

El campo `description` no es decorativo: es el que determina si la skill se invoca sola. Una
descripción vaga produce una skill que nadie invoca; una descripción demasiado amplia produce una
skill que se invoca cuando no debe. Este equipo lo revisa con el mismo rigor con que revisa un
contrato de API.

## Catálogo de skills {#sec-catalogo}

| ID | Skill | Responsable principal | Sprint |
|---|---|---|---|
| SK-01 | Descubrimiento del proceso de inspección ICA | AN-01 | S0 |
| SK-02 | Modelado del dominio de lotes y ciclo de 52 semanas | AR-02 | S1 |
| SK-03 | Definición del contrato temporal (tres relojes) | AR-01 | S1 |
| SK-04 | Diseño *offline-first* del cliente móvil | AR-03 | S3 |
| SK-05 | Protocolo de sincronización idempotente | AR-04 | S2 |
| SK-06 | Resolución de conflictos y reproceso de series | AR-01 | S4 |
| SK-07 | Geometría predial y retícula sobre imagen satelital | AR-05 | S5 |
| SK-08 | Configuración por predio (programa de inspección) | AR-02 | S5 |
| SK-09 | Diagramas C4 como código (C0 → C2) | AR-01 | S1–S5 |
| SK-10 | Vista dinámica y vista de despliegue | AR-01 | S3 |
| SK-11 | Contrato de datos de muestreo y MTD | AR-02 | S4 |
| SK-12 | Seguridad, datos personales y trazabilidad | AR-09 | S4 |
| SK-13 | Validación arquitectónica mediante contratos ejecutables | AR-07 | S5 |
| SK-14 | Registro de decisiones (ADR) | AR-01 | Continuo |
| SK-15 | Trazabilidad requisito → decisión → sprint | AN-02 | Continuo |
| SK-16 | Entrega formal al equipo de desarrollo | PM-01 | S5 |

Las skills SK-03, SK-06 y SK-11 se desarrollan en detalle más adelante porque son las que resuelven
el corazón del problema. Las demás quedan en el repositorio con el mismo formato.

\newpage

## Skills críticas, desarrolladas {#sec-skills-criticas}

### SK-03 · Definición del contrato temporal {#skill-03}

```text
---
name: contrato-temporal-tres-relojes
description: Usar cuando se defina, revise o modifique cualquier dato que
             registre el momento de una medición. Establece los tres relojes
             del dominio y las reglas de orden, alta retroactiva y versionado.
---

## Qué hace
Fija los tres tiempos que el sistema almacena para toda medición y las reglas
de ordenación y versionado del historial. Sin esta skill, cada tabla y cada
pantalla inventa su propia noción de fecha.

## Cuándo usarla
- Al diseñar el esquema de datos de cualquier entidad con fecha.
- Al revisar un contrato de API que transporte mediciones.
- Al definir un reporte que ordene una serie por lote.

## Cuándo NO usarla
- Para eventos que no son mediciones de campo (p. ej. fecha de creación de
  un usuario). Esos llevan un solo tiempo y no los tres.

## Entradas
- Definición de la unidad de medición (trampa, lote, visita).
- Fuentes de hora disponibles en el momento del levantamiento.

## Procedimiento
1. Asignar a cada medición los tres tiempos: t_observación, t_captura,
   t_sincronización. Documentar la fuente de cada uno.
2. Declarar que el orden canónico del dominio es t_observación.
3. Declarar t_observación como inmutable una vez sincronizado.
4. Prohibir la sobrescritura: toda corrección genera versión n+1.
5. Fijar la clave de idempotencia del registro y probarla.
6. Definir el comportamiento ante deriva del reloj del dispositivo.

## Salida
- Capítulo «Modelo temporal» del documento de arquitectura.
- ADR-02 y ADR-03 aceptados.
- Claves y columnas temporales en el contrato de datos.

## Límites
No define la fórmula de MTD (eso es SK-11) ni la geometría (SK-07).
```

### SK-06 · Resolución de conflictos y reproceso de series {#skill-06}

```text
---
name: resolucion-conflictos-y-reproceso
description: Usar cuando un registro llegue con fecha de observación anterior a
             datos ya sincronizados, cuando dos técnicos registren sobre el
             mismo periodo, o cuando una corrección cambie un valor histórico.
             Decide qué se inserta, qué se rechaza y qué se reprocesa.
---

## Qué hace
Define el comportamiento del sistema ante llegadas fuera de orden, ediciones
concurrentes y correcciones de datos ya publicados, evitando que el pasado se
reescriba en silencio.

## Cuándo usarla
- Al implementar o revisar el endpoint de sincronización.
- Al diseñar las reglas de reproceso de una serie histórica.
- Cuando el ICA pregunte qué pasa si un técnico sube datos antiguos.

## Cuándo NO usarla
- Para el caso simple de alta de un registro nuevo y posterior.
- Para conflictos puramente de UI (mensajes de validación de un formulario).

## Entradas
- Contrato temporal vigente (SK-03).
- Clave de idempotencia por tipo de medición.

## Procedimiento
1. Descartar por invalidez de forma antes de evaluar el orden.
2. Clasificar la operación: alta nueva, alta retroactiva o corrección.
3. Alta retroactiva: aceptar e insertar en su posición cronológica real.
4. Corrección: crear versión n+1 conservando la anterior; no borrar.
5. Detectar solapamiento con una ventana ya cubierta y marcar «revisar»
   en vez de decidir automáticamente.
6. Encolar el reproceso del periodo afectado y reemitir el concepto con
   la fecha de efecto correspondiente.
7. Devolver al cliente el resultado por operación, nunca un todo o nada.

## Salida
- ADR-04 aceptado.
- Tabla de clasificación de operaciones en el contrato de API.
- Casos de prueba de la skill SK-13.

## Límites
No decide el umbral ni el periodo de agregación (SK-11).
```

### SK-11 · Contrato de datos de muestreo y MTD {#skill-11}

```text
---
name: contrato-datos-muestreo-mtd
description: Usar al definir o modificar cómo se captura el muestreo de un lote
             y cómo se convierte en un índice MTD comparable contra un umbral,
             incluyendo su normalización y su vigencia normativa.
---

## Qué hace
Define la unidad de muestreo, su normalización a índice MTD, la forma de
agregarlo por lote y periodo, y la regla de vigencia del umbral aplicado.

## Cuándo usarla
- Al definir el formulario de muestreo de campo.
- Al modificar la fórmula o el periodo de agregación.
- Al incorporar una nueva resolución o un cambio de umbral.

## Cuándo NO usarla
- Para el resto de los campos de la visita (BPA, producción, enfermedades):
  son catálogos configurables, no cálculos.

## Entradas
- Definición oficial del indicador entregada por el ICA.
- Periodo de trampeo y número de trampas por lote.

## Procedimiento
1. Declarar la unidad de muestreo (trampa con fecha de instalación y retiro).
2. Normalizar por días de exposición y por número de trampas.
3. Agregar por lote y por periodo definido en la configuración del predio.
4. Contrastar contra el umbral vigente **a la fecha del periodo**.
5. Emitir el resultado con la fecha de efecto y la norma que lo sustenta.
6. Si la definición oficial aún no está, dejar el parámetro sin valor por
   defecto y bloquear la emisión del concepto. Nunca inventar el valor.

## Salida
- Capítulo «Muestreo y MTD» del documento de arquitectura.
- Configuración de umbral versionada en el modelo de datos.

## Límites
No valida el cumplimiento de buenas prácticas ni el diagnóstico fitosanitario.
```

\newpage

# Modelo de dominio {#sec-dominio}

## Entidades núcleo {#fig-entidades}

El dominio se modela en torno a una idea: **el objeto que importa para el trámite de exportación es
el par (lote, fecha)**. Todo lo demás son atributos, evidencia o configuración de ese par.

| Entidad | Descripción | Campos esenciales |
|---|---|---|
| **Predio** | Unidad productiva inscrita ante el ICA | Código, nombre, municipio, departamento, geometría, área, responsable |
| **Programa de inspección** | Configuración vigente del predio | Vigencia desde/hasta, ciclo, umbral MTD, checklist BPA, catálogos |
| **Lote** | Subdivisión del predio con etapa propia | Código, polígono, área, variedad, fecha de plantación, lote activo |
| **Retícula (celda)** | Subdivisión del lote sobre la imagen satelital | Código, polígono, resolución, fecha de corte de imagen |
| **Ciclo de cultivo** | Ciclo de 52 semanas con etapa fenológica derivada | Semana 1…52, etapa, variedad de referencia |
| **Visita** | Sesión de inspección en un predio | Técnico, fecha de inicio y fin observados, lotes cubiertos, ruta, estado |
| **Trampa** | Punto de monitoreo de un lote | Código, lote, tipo, fecha de instalación, fecha de retiro |
| **Medición de captura** | Moscas capturadas en una trampa en una fecha | Trampa, cantidad, especie, sexo, fecha de observación, tres tiempos, versión |
| **Índice MTD** | Resultado agregado del muestreo de un lote en un periodo | Lote, periodo, valor, unidad, umbral aplicado, cumple o no |
| **Ítem de buenas prácticas** | Verificación de un criterio agronómico | Catálogo, cumple, observación, evidencia |
| **Estimación de producción** | Proyección de cosecha de un lote | Árboles, kg por árbol, estimado, fecha de estimación, método |
| **Hallazgo de enfermedad** | Signo o síntoma observado | Catálogo, severidad, lote, fecha de observación, evidencia |
| **Etapa reportada** | Etapa declarada por el técnico | Etapa, fecha de observación, origen: derivada o declarada |
| **Evidencia** | Imagen que respalda una medición | Hash, referencia en almacenamiento, fecha de captura, georreferencia |
| **Concepto de aptitud** | Documento que habilita o bloquea la exportación | Lote, periodo, resultado, fecha de efecto, norma aplicada, versión |
| **Versión de registro** | Revisión de un dato ya sincronizado | Registro, versión, valor anterior, valor nuevo, autor, fecha |

## El ciclo de 52 semanas {#ciclo-52}

La producción continua durante todo el año es precisamente la razón por la que el ICA necesita que
cualquier lote sea inspeccionable en cualquier momento: los ciclos están **escalonados**, de modo que en
cualquier semana hay lotes en floración, en cuajado, en maduración, en cosecha y en poscosecha.

La arquitectura no debe almacenar «la etapa del lote» como un hecho que se teclea, porque ese es
exactamente el tipo de dato que se vuelve inconsistente entre visitas.

La decisión es:

> **La etapa fenológica se deriva, no se captura como verdad.** Se deriva de la fecha de
> observación del muestreo, la fecha de plantación del lote y la tabla de etapas del programa de
> inspección vigente. El técnico puede **declarar** una etapa, y esa declaración se guarda con su
> fecha, valor y autor, y se marca como `reportada` frente a `derivada`. Cuando ambas difieren, el
> sistema muestra las dos y la discrepancia queda registrada. No se descarta ninguna.

La etapa derivada se calcula siempre con la tabla vigente **a la fecha de observación**, por la
misma razón que el umbral MTD. Si el ICA reorganiza la tabla de etapas, los históricos siguen siendo
reproducibles porque cada medición guarda la versión de tabla con la que se interpretó.

## Reglas de validación {#validaciones}

Estas reglas se aplican en el dispositivo (forma) y se revalidan en el servidor (dominio), porque un
dispositivo puede estar desactualizado respecto a la configuración vigente.

| Regla | Dónde se valida | Mensaje al técnico |
|---|---|---|
| La fecha de observación no puede estar en el futuro respecto a la fecha de captura | Cliente y servidor | "La fecha de medición no puede ser futura" |
| La fecha de observación debe caer dentro del periodo de trampeo de la trampa | Cliente y servidor | "La fecha no está dentro del periodo de la trampa" |
| La trampa debe pertenecer al lote indicado | Servidor | "La trampa no pertenece a este lote" |
| La cantidad capturada no puede ser negativa | Cliente y servidor | "Valor no válido" |
| El umbral vigente en la fecha del periodo debe existir | Servidor | "No hay umbral configurado para esa fecha; concepto no emitido" |
| El lote debe estar activo en el periodo inspeccionado | Servidor | "El lote no estaba activo en esa fecha" |
| El número de serie del lote es único dentro del predio | Servidor | "Duplicidad de código de lote" |

\newpage

# La decisión central: modelo temporal y carga fuera de orden {#sec-temporal}

Esta sección es la que justifica el proyecto. Si el resto de la arquitectura se puede resumir en
poco más de un diagrama, esto necesita un modelo propio.

## El problema, enunciado con precisión {#problema-temporal}

Tres situaciones del enunciado convergen en un solo defecto de diseño:

1. El técnico sale del predio con datos anotados el lunes.
2. El técnico regresa tres semanas después, con datos anotados ese día.
3. Ambos suben su información. El orden en que el sistema la recibe **no coincide** con el orden en
   que fue observada, y no hay nada en el modelo que lo advierta.

Si el sistema guarda "la última fecha que vi para este lote", la serie del lote queda mal. Si el
sistema sobrescribe valores, se pierde el pasado. Si el sistema ordena por la hora de llegada, el
histórico miente.

## Los tres relojes {#tres-relojes}

![Modelo temporal bitemporal. Cada registro conserva tres relojes —observación, captura y sincronización— y la idempotencia se decide con la clave de operación del dispositivo.](diagrams/modelo-temporal-bitemporal.png){width=\textwidth #figura-modelo-temporal-bitemporal}

El sistema no guarda "una fecha". Guarda **tres**, con significado distinto y con reglas de
inmutabilidad distintas:

| Tiempo | Qué significa | ¿Se puede modificar? | ¿Ordena el dominio? |
|---|---|---|---|
| `t_observación` | Cuándo el técnico tomó la medición en el predio | **Nunca**, una vez sincronizado | **Sí**, es el orden canónico |
| `t_captura` | Cuándo se digitó en el dispositivo | No | No; sirve para auditar la labor |
| `t_sincronización` | Cuándo llegó al servidor | Asignada por el servidor | No |

Una cuarta dimensión, no un reloj, acompaña a las tres: la **versión**, que es un entero que
incrementa en cada corrección y que, junto con `t_observación`, forma la identidad lógica del dato.

## Las seis reglas {#reglas}

> **R-T1 · Orden canónico.** El orden del dominio es `t_observación` ascendente. A igualdad de
> `t_observación`, desempata `(t_captura, identificador)`. El tiempo de llegada al servidor no
> participa jamás del orden.
>
> **R-T2 · Alta retroactiva.** Si llega un registro cuyo `t_observación` es anterior al último ya
> sincronizado **y que no existía**, no es una actualización: es un alta. Se inserta en su posición
> cronológica real y la serie se recalcula. El sistema responde `aceptado, tipo: alta_retroactiva`.
>
> **R-T3 · Corrección sin sobrescritura.** Si el registro ya existía y el técnico cambia un valor,
> se crea una versión `n+1` que conserva la anterior. La versión anterior permanece consultable. La
> pregunta "¿qué se registró originalmente el lunes?" siempre tiene respuesta.
>
> **R-T4 · Idempotencia.** Reintentar el envío de un lote ya recibido no duplica nada. La clave de
> idempotencia es `(dispositivo, cliente_id)` con `cliente_id` derivado del reloj de observación, más
> una huella de contenido; si llega el mismo `cliente_id` con contenido distinto, se rechaza y se
> reporta como conflicto.
>
> **R-T5 · Solapamiento marcado, no decidido.** Si el `t_observación` cae dentro de una ventana
> ya cubierta por otro muestreo del mismo tipo para el mismo lote y trampa, el sistema no elige
> un ganador: marca la operación `revisar` y la devuelve al técnico para confirmación humana. La
> automatización no debe decidir qué medición es la buena en materia fitosanitaria.
>
> **R-T6 · Deriva del reloj.** El dispositivo compara su reloj con la referencia del campo al
> iniciar la visita. Si la deriva supera un umbral definido, el sistema marca el registro con
> `deriva_reloj` y pide confirmación explícita del técnico al enviarlo. Un reloj de teléfono
> manipulado no debe poder falsear una serie fitosanitaria.

## Vista dinámica: el escenario que juzga la arquitectura {#vista-dinamica}

![Vista dinámica. Tres actos encadenados —captura en campo, carga fuera de orden y reproceso de una serie— que juzgan si la arquitectura resuelve el problema real.](diagrams/vista-dinamica-visita.png){width=\textwidth #figura-vista-dinamica-visita}

La Figura 5 se lee como una prueba. El **Acto 3** es la pregunta que el sistema debe responder
correctamente, y la respuesta del servidor está escrita en el panel derecho:

> `aceptado: true` · `tipo: alta_retroactiva` · la serie del lote 12 se recalculó e insertó en su
> posición real · el concepto de aptitud se reemitió con **fecha de efecto = miércoles**.

Ese último punto es la respuesta de negocio que hace útil el sistema: cuando entre un registro
antiguo, el ICA no solo tiene el dato; tiene la posibilidad de reconstruir **en qué estado estaba el
lote el día en que se tomó ese muestreo**.

## Reglas de negocio con fecha de efecto {#reglas-fecha-efecto}

Dos reglas adicionales hacen que el anterior no se pierda en la traducción a papel:

- **Serie histórica.** El índice MTD de un lote en un periodo se recalcula si llega un registro de
  ese periodo. El valor recalculado conserva el valor anterior con su fecha de recálculo, de modo
  que se puede mostrar «MTD del lote 7 la semana del 12: **2,1 %**, recalculado el día 24 a
  **1,4 %** por alta retroactiva».
- **Concepto de aptitud.** El concepto se reemite con **fecha de efecto** igual al `t_observación`
  del registro que lo disparó. Un consumidor que consulta el estado de un lote «al día 12» obtiene
  el estado que habría obtenido entonces, no el de hoy.

## Consecuencias de diseño que se aceptan {#consecuencias}

Toda esta disciplina tiene un precio, y conviene decirlo antes de que lo pregunten:

| Consecuencia aceptada | Por qué es el precio correcto |
|---|---|
| La base de datos es append-only para las mediciones | Es la única forma de que el histórico sea auditable |
| Un alta retroactiva dispara trabajo asíncrono de reproceso | Reconstruir el pasado cuesta; ocultarlo costaría más |
| El dispositivo guarda más datos localmente | El almacenamiento local barato es lo que hace posible la operación sin señal |
| Un registro puede quedar en estado `revisar` sin que el técnico entienda por qué | Preferible a que el sistema decida silenciosamente un dato fitosanitario |
| La fotografía pesa más que el dato y sube después | El dato numérico es lo que sostiene el trámite; la imagen es soporte |

\newpage

# Decisiones de arquitectura {#sec-adr}

Registro resumido de las decisiones de arquitectura. El formato completo (contexto, opciones
consideradas, consecuencias y estado) vive en el repositorio como ADR numerados y versionados; aquí
se presenta lo esencial para que este documento se pueda leer solo.

## ADR-01 · El dispositivo es la fuente de captura, no una caché {#adr-01}

**Estado:** Aceptada.

**Contexto.** El predio no tiene cobertura y la visita dura varias horas.

**Decisión.** La aplicación móvil opera de forma autónoma. El servidor no participa en la captura.
El cliente solo valida forma, no reglas de negocio. Ninguna regla —cálculo de MTD, etapa
fenológica, estado de aptitud— se evalúa en el dispositivo.

**Consecuencias.** El equipo de desarrollo debe poder compilar y operar la visita entera con el
dispositivo en modo avión. Se acepta la duplicación parcial de validaciones: la forma se valida dos
veces, el dominio una sola vez y en el servidor.

## ADR-02 · `t_observación` es inmutable {#adr-02}

**Estado:** Aceptada.

**Decisión.** Una vez que un registro se sincroniza, su `t_observación` no puede cambiarse bajo
ninguna circunstancia, incluso por corrección. Lo que se corrige es el **valor medido**; el momento
en que se midió es un hecho del pasado.

**Consecuencias.** Si el técnico se equivocó de día, no se corrige la fecha: se anula el registro y
se crea uno nuevo con la fecha correcta, dejando ambos visibles y el anulado marcado.

## ADR-03 · Mediciones append-only con versiones {#adr-03}

**Estado:** Aceptada.

**Decisión.** No hay `UPDATE` sobre una medición sincronizada. Hay inserciones y versiones.

**Consecuencias.** La tabla crece de forma monótona; es el precio de la auditabilidad. Las
consultas de la serie leen la versión vigente de cada medición, y las consultas de auditoría leen
todas.

## ADR-04 · Clasificación explícita de cada operación recibida {#adr-04}

**Estado:** Aceptada.

**Decisión.** El endpoint de sincronización clasifica cada operación recibida como `alta_nueva`,
`alta_retroactiva`, `correccion`, `idempotente_repetida`, `revisar` o `rechazada`, y devuelve el
resultado **por operación**, nunca un resultado único para todo el lote. Un lote parcialmente
aceptado es un resultado normal y esperado.

**Consecuencias.** El cliente puede mostrar al técnico exactamente qué se guardó y qué no.

## ADR-05 · El umbral MTD se versiona con vigencia {#adr-05}

**Estado:** Aceptada.

**Decisión.** El umbral, la fórmula, el periodo de agregación y la tabla de etapas fenológicas son
entidades versionadas con `vigente_desde` / `vigente_hasta`. Cada medición guarda la versión con la
que fue interpretada.

**Consecuencias.** Un cambio de umbral no altera el pasado: los conceptos ya emitidos siguen siendo
reproducibles con la norma que los originó. Si el umbral aplicable a un periodo no existe, **no se
emite concepto**; el sistema lo dice en lugar de adivinar.

## ADR-06 · La geometría del lote se versiona aparte de las mediciones {#adr-06}

**Estado:** Aceptada.

**Decisión.** El polígono de un lote y el corte de la retícula son entidades versionadas
(`vigente_desde`, `vigente_hasta`) y las mediciones apuntan a la versión de geometría vigente en su
fecha de observación.

**Consecuencias.** Si el productor redibuja un lote, los muestreos antiguos siguen correctamente
referidos al contorno que se midió entonces. Un cambio de geometría genera un evento, porque puede
alterar el área y por tanto la normalización del MTD.

## ADR-07 · La personalización es configuración, nunca condicional en el código {#adr-07}

**Estado:** Aceptada.

**Decisión.** Un predio se personaliza mediante un *programa de inspección* versionado: umbral,
ciclo, checklist de buenas prácticas, catálogo de enfermedades y trampas, resolución de retícula,
proveedor de imagen. El código no contiene `if (predio == ...)`.

**Consecuencias.** Atender un predio nuevo es una operación de configuración, no un despliegue. Es
la manera directa de atender el requisito «personalizado específicamente a ciertos predios, no en
general».

## ADR-08 · El enlace intermitente es un elemento del modelo, no un error {#adr-08}

**Estado:** Aceptada.

**Decisión.** Se diseña para transmisión **cero** durante la visita. La sincronización es una
actividad posterior, por lotes, con reintentos y sin que la falta de conexión sea una excepción.
La experiencia de la aplicación no debe diferenciar «no hay señal» de «no se guardó».

**Consecuencias.** RPO efectivo igual a cero para lo capturado (la copia local es la garantía) y
RTO de horas para el servidor. El equipo de desarrollo debe poder demostrar la captura íntegra en
modo avión como criterio de aceptación.

## ADR-09 · La configuración de un predio viaja precargada en el dispositivo {#adr-09}

**Estado:** Aceptada.

**Decisión.** El dispositivo debe poder abrir un predio y trabajar en él sin ninguna llamada a la
red: programa de inspección, geometría de lotes, retícula y mosaicos se descargan en el momento en
que el técnico programa la visita y quedan disponibles en ella.

**Consecuencias.** Obliga a una caché de imagen satelital en el dispositivo, con una política de
tamaño y de caducidad. Es la razón por la que el uso de la imagen queda sujeto al contrato del
proveedor (riesgo RK-04).

## ADR-10 · Idioma, unidades y formatos se fijan en el dominio {#adr-10}

**Estado:** Aceptada.

**Decisión.** El dominio almacena fechas en UTC con zona horaria del predio asociada, números en
unidades explícitas con su campo de unidad, y texto en español Colombia. La conversión a zona
local ocurre en la capa de presentación.

**Consecuencias.** Una visita que cruza el mediodía no produce mediciones con horas ambiguas, y un
lote no se reposa por el uso de coma decimal. Este detalle, omitido, es una fuente clásica de
disputas de datos en campo.

## ADR-11 · Datos personales dentro del alcance de la arquitectura {#adr-11}

**Estado:** Aceptada.

**Decisión.** El sistema registra datos de técnicos y de responsables de predios. Se aplican
minimización (solo lo necesario para la trazabilidad), cifrado en tránsito y en reposo,
control de acceso por rol, bitácora de accesos, y atención de la Ley 1581 de 2012.

**Consecuencias.** La foto satelital y la fotografía de campo pueden contener personas o
actividad productiva identificable; su política de retención se define antes del despliegue.

## ADR-12 · La evidencia viaja por debajo del dato {#adr-12}

**Estado:** Aceptada.

**Decisión.** En cada lote de sincronización, el motor prioriza el dato numérico y la evidencia
fotográfica se envía después, en segundo plano, sin bloquear el cierre de la visita.

**Consecuencias.** La confirmación al técnico llega antes. Si el dispositivo se queda sin batería
durante la subida de fotos, el dato crítico ya está confirmado en el servidor.

# Vista de despliegue {#sec-despliegue}

![Vista de despliegue. Frontera de red, equipos de campo, el acoplamiento con el enlace intermitente y los componentes del servidor dentro de la topología de ejecución.](diagrams/vista-despliegue.png){width=\textwidth #figura-vista-despliegue}

La vista de despliegue hace explícita la consecuencia de ADR-01 y ADR-08: **el sistema tiene dos
entornos que no comparten supuestos**, y el primero es el que opera el ICA la mayor parte del
tiempo.

- **Entorno 1 · Predio.** El dispositivo es autónomo. Guarda mosaicos, geometría y la cola de
  salidas pendientes. Su modo de fallo característico no es «dejar de funcionar», sino
  «acumular trabajo». La arquitectura debe hacer que ese trabajo acumulado sea recuperable y
  visible.
- **Entorno 2 · Nube.** Servicios, base de datos y almacenamiento. El enlace rural es intermitente
  por diseño, no por avería.

**Postura operativa derivada.** RPO efectivo cero para los datos capturados: la copia local es la
garantía de que una medición no se pierde por un fallo de red. RTO de horas para el servidor, lo
que es admisible para un trámite fitosanitario que no tiene una ventana de minutos.

\newpage

# Equipo y plan de trabajo {#sec-plan}

## Estructura del equipo {#equipo}

Diez personas. La composición no es decorativa: cada rol responde a una restricción concreta del
problema.

| ID | Rol | Persona | Responsabilidad principal | Riesgo que cubre |
|---|---|---|---|---|
| AR-01 | Arquitecto de solución | 1 | C4, decisiones transverse, cierre técnico | Que las piezas no encajen entre sí |
| AR-02 | Arquitecto de dominio y datos | 1 | Modelo, ciclo de 52 semanas, MTD | Modelar el negocio equivocado |
| AR-03 | Arquitecto móvil | 1 | Offline-first, caché, captura en campo | Que la app no funcione sin señal |
| AR-04 | Arquitecto de backend | 1 | API, sincronización, contratos | Interfaz imposible de implementar |
| AR-05 | Arquitecto geospatial | 1 | Geometría, retícula, imagen satelital | El mapa no sirve para el trámite |
| AN-01 | Analista de negocio (proceso ICA) | 1 | Descubrimiento, normativa, validación con técnicos | Construir lo que el ICA no pidió |
| AN-02 | Analista de requisitos | 1 | Trazabilidad, historias, priorización | Pérdida de requisitos en el camino |
| AR-07 | Calidad de arquitectura | 1 | Contratos ejecutables, pruebas de invariantes | Una arquitectura que no se puede verificar |
| AR-09 | Seguridad y plataforma | 1 | Datos personales, despliegue, observabilidad | Falla de datos o de acceso |
| PM-01 | PMO de arquitectura | 1 | Gobierno, ADR, handoff, documentación | Que el equipo entregue sin registro |

## Plan de once semanas {#gantt}

Una semana de descubrimiento (S0) y cinco sprints de dos semanas: once semanas en total.

| Sprint | Semanas | Foco | Hitos entregables |
|---|---|---|---|
| **S0** | 1 | Descubrimiento y arranque | Proceso actual documentado; preguntas al ICA abiertas; modelo preliminar |
| **S1** | 2–3 | Dominio y contratos base | Modelo de dominio v1; contrato temporal (SK-03); C0 aprobado |
| **S2** | 4–5 | Arquitectura de contenedores y temporal | C1 aprobado; ADR-01, 02, 03 aceptados; esqueleto de API |
| **S3** | 6–7 | Offline-first y vista dinámica | Diseño offline; escenario de visita validado; C2 del registro |
| **S4** | 8–9 | Sincronización y conflictos | Protocolo idempotente; ADR-04, 05; casos de prueba temporales |
| **S5** | 10–11 | Geometría, configuración, validación y entrega | Geometría versionada; programa de inspección; ADR-06, 07; C4 completo; suite de contratos verde; roadmap del equipo de desarrollo |

**Hito de decisión a mitad de proyecto (semana 5).** Si en S2 no está cerrado el contrato temporal,
el proyecto se replantea: sin ese contrato, el resto de la arquitectura es decorativa. Este es el
punto de control más importante del plan.

## Asignación de esfuerzo por sprint {#esfuerzo}

| Sprint | AR-01 | AR-02 | AR-03 | AR-04 | AR-05 | AN-01 | AN-02 | AR-07 | AR-09 | PM-01 |
|---|---|---|---|---|---|---|---|---|---|---|
| S0 | 2 | 2 | 1 | 1 | 1 | 4 | 3 | 1 | 1 | 3 |
| S1 | 2 | 4 | 2 | 2 | 2 | 3 | 3 | 1 | 1 | 2 |
| S2 | 4 | 3 | 2 | 3 | 2 | 2 | 2 | 2 | 1 | 2 |
| S3 | 3 | 2 | 4 | 2 | 2 | 2 | 1 | 2 | 1 | 2 |
| S4 | 3 | 3 | 2 | 4 | 1 | 1 | 1 | 3 | 1 | 2 |
| **S5** | 5 | 5 | 4 | 4 | 5 | 4 | 3 | 5 | 3 | 6 |
| **Total** | **19** | **19** | **15** | **16** | **13** | **16** | **13** | **14** | **8** | **17** |

Los números son días-persona por sprint. La carga no es uniforme a propósito: AN-01 y AR-07 concentran
esfuerzo donde el riesgo de equivoco es mayor (entender el proceso y verificar lo construido), y AR-09
aparece poco porque su trabajo se concentra en decisiones tempranas.

## Gobierno {#gobierno}

- **Los diagramas son código.** Cada figura tiene su fuente SVG en `diagrams/` y se revisa igual que
  una línea de código. Un cambio de frontera es un Pull Request.
- **Toda decisión estructural es un ADR.** Sin ADR, la decisión no se aplica: se discute y se vuelve a
  discutir.
- **Trazabilidad viva.** La matriz requisito → decisión → diagrama → sprint se mantiene en cada cierre
  de sprint (skill SK-15). Si un `R-0x` no tiene decisión, se reporta en la retrospectiva.
- **Revisión cruzada.** Cada diagrama lo revisa al menos una persona que no lo produjo.
- **Ritmo de sincronización.** Una sesión de quince minutos por día entre AR-01, AR-02,
  AR-03 y AR-04; el resto se comunica por escrito.

# Lo que se entrega y cómo lo recibe el equipo de desarrollo {#sec-handoff}

## Definición de terminado de la fase de arquitectura {#dod}

La fase termina cuando **todo** lo siguiente es cierto:

1. C0, C1, C2 selectivo, vista dinámica y vista de despliegue están modelados, versionados como SVG
   y revisados por al menos dos personas.
2. Los doce ADR están en estado «Aceptada» con sus consecuencias escritas.
3. El contrato de datos incluye las tres columnas temporales y la versión, con sus claves e índices.
4. El contrato de API (OpenAPI) cubre el envío de mediciones y la respuesta por operación.
5. Existe una suite de contratos ejecutables que demuestra las seis reglas temporales, incluida la
   del alta retroactiva.
6. La matriz de trazabilidad cubre `R-01` a `R-12` sin huecos.
7. El backlog del equipo de desarrollo está priorizado, estimado y escrito en el mismo formato de
   historia de usuario.
8. La sesión de traspaso se realizó y quedó un documento de preguntas frecuentes con las respuestas
   del equipo de arquitectura.

## Paquete de traspaso {#paquete}

El equipo de desarrollo recibe, no un documento, un **paquete versionado**:

- Diagramas en SVG y su fuente, con licencia de uso interno.
- Contrato de API y de datos, en formato legible por herramienta.
- Suite de contratos ejecutable, con las reglas temporales como casos de prueba.
- Catálogo de skills del proyecto, que es a la vez documentación y guía de estilo.
- Registro de decisiones.
- Backlog priorizado con dependencias señaladas.
- Lista de preguntas abiertas, con el responsable de resolverlas.

## Riesgos de la entrega {#riesgos-entrega}

| Riesgo | Mitigación prevista |
|---|---|
| El equipo de desarrollo no puede reconstruir el porqué de una decisión | ADR obligatorio; revisión cruzada |
| Los diagramas quedan desactualizados respecto a las decisiones | Diagramas como código, revisión en Pull Request |
| La arquitectura se documenta pero no se verifica | Skill SK-13: contratos ejecutables como criterio de aceptación |

\newpage

# Riesgos del proyecto {#sec-riesgos}

| ID | Riesgo | Prob. | Impacto | Mitigación |
|---|---|---|---|---|
| RK-01 | Definición oficial de MTD no entregada a tiempo | Alta | Alto | Parámetro sin valor por defecto; se bloquea la emisión de concepto en vez de inventar (P-01) |
| RK-02 | Desfase entre el proceso real y el proceso documentado | Media | Alto | Descubrimiento en S0 con observación directa de dos visitas |
| RK-03 | Alcance disfrazado de «sistema genérico» | Alta | Medio | ADR-07 y skill SK-08 hacen imposible el `if (predio == ...)` |
| RK-04 | Consumo de imagen satelital no permitido por el contrato | Media | Alto | Validación legal en S0; alternativa de imagen ortométrica propia |
| RK-05 | Tamaño de la caché offline inaceptable en el dispositivo | Media | Medio | Resolución de retícula por configuración; predescarga por zona, no por predio completo |
| RK-06 | Deriva del reloj de los dispositivos falsea series | Media | Alto | Regla R-T6 y skill SK-03 |
| RK-07 | Un técnico omite una visita o sube datos del cuaderno mucho después | Media | Medio | Alta retroactiva (R-T2) lo resuelve: el dato entra donde corresponde |
| RK-08 | Datos personales expuestos por fotografías | Baja | Alto | ADR-11, política de retención, control de acceso |
| RK-09 | Un solo diseñador de tiempo insuficiente para geo, temporal y despliegue | Media | Alto | Refuerzo de AR-05 en S5; el temporal no depende de él |
| RK-10 | El equipo de desarrollo arranca antes de que la arquitectura esté estable | Media | Medio | Hito de cierre formal en la semana 11; no hay implementación en esta fase |

# Preguntas abiertas {#sec-preguntas}

Estas preguntas se resuelven con el ICA o con el productor. Cada una tiene un responsable y una
fecha límite; una pregunta abierta sin responsable es una decisión que se toman más tarde sin
información.

| ID | Pregunta | Responsable | Límite |
|---|---|---|---|
| P-01 | Fórmula oficial del índice MTD, unidad y expresión numérica del umbral | AN-01 | Fin de S1 |
| P-02 | Periodo de trampeo y número de trampas por lote y por área | AN-01 | Fin de S1 |
| P-03 | Tabla de etapas fenológicas del ciclo de 52 semanas por variedad | AN-02 | Fin de S1 |
| P-04 | Campos exactos del checklist de buenas prácticas y su obligatoriedad | AN-01 | Fin de S2 |
| P-05 | Catálogo de enfermedades a detectar y escala de severidad | AN-01 | Fin de S2 |
| P-06 | Resolución de la retícula: tamaño de celda en metros | AR-05 | Fin de S4 |
| P-07 | Proveedor de imagen con licencia compatible con caché en dispositivo | AR-05 | Fin de S0 |
| P-08 | Número de predios, técnicos activos y frecuencia de visita | AN-01 | Fin de S2 |
| P-09 | Tiempo máximo aceptable entre la captura y la disponibilidad en el histórico | AN-02 | Fin de S3 |
| P-10 | Formato y periodicidad del reporte que consume el ICA | AN-02 | Fin de S4 |

# Anexos {#sec-anexos}

## Glosario {#glosario}

**APTITUD** — Condición de un lote para ser habilitado a exportar, determinada por el contraste de
sus índices de monitoreo contra los umbrales vigentes.

**APTO / NO APTO** — Resultado del contraste de un lote contra el umbral en un periodo determinado.

**BPA** — Buenas Prácticas Agrícolas. Conjunto de criterios agronómicos que se verifican en la visita.

**C4** — Modelo de documentación de software en cuatro niveles de zoom: contexto, contenedores,
componentes y código.

**CICLO DE 52 SEMANAS** — Periodo productivo de un lote de durazno, desde la floración hasta el
postcosecha, que permite escalonar lotes para tener producción todo el año.

**MTD** — Índice de monitoreo de moscas de la fruta, calculado sobre el muestreo de un lote en un
periodo y comparado contra un umbral. Definición oficial pendiente de confirmación por el ICA (P-01).

**MTD** *(definición operativa asumida)* — Cociente entre el número de moscas capturadas y el
producto del número de trampas por los días de exposición.

**PREDIO** — Unidad productiva inscrita ante el ICA, sobre la que se realiza la inspección.

**LOTE** — Subdivisión del predio con etapa de crecimiento propia dentro del ciclo.

**ALTA RETROACTIVA** — Inserción de una medición cuya fecha de observación es anterior a la de datos
ya sincronizados, aceptada sin sobrescribir nada y colocada en su posición cronológica real.

**BITEMPORAL** — Modelo de datos que almacena por separado el momento en que un hecho ocurrió y el
momento en que el sistema lo supe.

**ADR** — Registro de Decisión de Arquitectura (*Architecture Decision Record*): registro de una decisión, sus alternativas y sus
consecuencias.

**RPO / RTO** — Punto de recuperación objetivo y tiempo de recuperación objetivo, es decir, cuánta
información se puede perder y en cuánto tiempo se restaura el servicio.

**RETRÍCULA (GRID)** — Cuadrícula regular superpuesta sobre la imagen satelital para dividir el
predio en celdas de trabajo y de referencia.

**SIN COBERTURA** — Zona sin señal de datos celulares ni wifi, condición normal de la mayoría de los
predios.

## Plantilla de ADR {#plantilla-adr}

```text
# ADR-NN · Título de la decisión
Estado:      Propuesta | Aceptada | Reemplazada por ADR-MM
Fecha:       AAAA-MM-DD
Autores:     AR-XX, AR-YY
Afecta a:    R-0x, SK-NN, diagramas C4-N

## Contexto
Qué fuerza o restricción obliga a decidir.

## Opciones consideradas
- Opción A: descripción, y lo bueno y lo malo
- Opción B: descripción
- Opción C: descripción

## Decisión
Qué se decide, en una frase.

## Consecuencias
- Consecuencia positiva
- Consecuencia negativa que aceptamos
- Qué queda prohibido hacer a partir de ahora
```

## Referencias {#referencias}

- Simon Brown. *Visualising Software Architecture*. C4 Model.
- agentskills.io — especificación del formato de skills (nombre, description, estructura de
  directorios y buenas prácticas de redacción).
- Instituto Colombiano Agropecuario. Resolución 995 de 2019: medidas fitosanitarias para el control
  de la mosca del Mediterráneo en predios productores de durazno y plantas empacadoras.
- Instituto Colombiano Agropecuario. Resolución 106407 de 2021: medidas de manejo de moscas de la
fruta.
- Ministerio de Comercio, Industria y Turismo. Ley 1581 de 2012: protección de datos personales.

\vfill
\begin{center}
\small\itshape
Fin del documento. Versión 1.0. Los artefactos asociados —diagramas, contratos, catálogo de
skills y registro de decisiones— se entregan en el repositorio del proyecto.
\end{center}