# Análisis del Dominio, Narrativa y Reglas de Negocio — Congreso ConectaTech

## 1. Narrativa del Dominio

ConectaTech organiza congresos profesionales presenciales, virtuales e híbridos en distintas ciudades. Cada edición posee nombre, año, fechas y un estado de preparación. Una edición presencial o híbrida utiliza una sede con varias salas; una sesión virtual puede no tener sala, pero necesita información de transmisión. Una sala tiene nombre y capacidad, y no debe alojar dos sesiones cuyos horarios se superpongan.

Las personas se registran con nombre, correo y país. Dentro de una edición pueden participar como asistentes, ponentes o en ambos roles. Los asistentes eligen un tipo de acreditación. Los ponentes mantienen una biografía profesional. Toda persona inscrita en una edición debe desempeñar al menos uno de esos roles.

El programa contiene sesiones con título, resumen, fecha, hora inicial y hora final. Toda sesión se clasifica exactamente como charla o taller. Las charlas reservan minutos para preguntas; los talleres tienen un cupo práctico y requisitos de materiales. Algunas sesiones requieren haber completado una o más sesiones previas, pero ninguna puede ser prerrequisito de sí misma.

Un asistente puede inscribirse en varias sesiones y una sesión recibe muchos asistentes. De cada inscripción se conoce la fecha, el estado y, después del evento, si hubo asistencia. No puede existir dos veces la misma inscripción. Cada sesión puede tener varios ponentes y un ponente puede intervenir en varias sesiones; la asignación conserva el rol del ponente y el orden en que aparecerá en el programa.

Empresas patrocinadoras apoyan distintas ediciones. El acuerdo registra categoría, monto y fecha de confirmación. Una misma empresa puede participar en varias ediciones, pero solo debe existir un acuerdo vigente por empresa y edición.

---

## 2. Identificación de Entidades, Atributos, Dominios e Identificadores

| # | Entidad | Clasificación | Identificador (PK) | Claves Candidatas (UK) | Atributos y Dominios |
|---|---|---|---|---|---|
| 1 | **Sede** | Fuerte | `id` (`INT IDENTITY`) | `nombre` (`VARCHAR(150)`) | `nombre`, `ciudad` (`VARCHAR(100)`), `direccion` (`TEXT`) |
| 2 | **Edicion** | Fuerte | `id` (`INT IDENTITY`) | `nombre` (`VARCHAR(150)`) | `nombre`, `anio` (`INT >= 2000`), `ciudad`, `modalidad` (`Presencial`, `Virtual`, `Hibrida`), `fecha_inicio` (`DATE`), `fecha_fin` (`DATE`), `estado` (`VARCHAR(30)`), `sede_id` (`INT NULL`) |
| 3 | **Sala** | Dependiente de Sede | `id` (`INT IDENTITY`) | `(sede_id, nombre)` | `sede_id` (`INT`), `nombre` (`VARCHAR(100)`), `capacidad` (`INT > 0`) |
| 4 | **Persona** | Supertipo | `id` (`INT IDENTITY`) | `correo` (`VARCHAR(150)`) | `nombre` (`VARCHAR(150)`), `correo` (formato email), `pais` (`VARCHAR(100)`) |
| 5 | **Asistente** | Subtipo (Solapada) | `persona_id` (`INT PK/FK`) | `persona_id` | `tipo_acreditacion` (`General`, `VIP`, `Estudiante`, `Prensa`) |
| 6 | **Ponente** | Subtipo (Solapada) | `persona_id` (`INT PK/FK`) | `persona_id` | `biografia` (`TEXT`), `especialidad` (`VARCHAR(120)`) |
| 7 | **Sesion** | Supertipo | `id` (`INT IDENTITY`) | `(id, tipo_sesion)` | `edicion_id` (`INT`), `sala_id` (`INT NULL`), `titulo` (`VARCHAR(200)`), `resumen` (`TEXT`), `fecha` (`DATE`), `hora_inicio` (`TIME`), `hora_fin` (`TIME`), `tipo_sesion` (`Charla`, `Taller`) |
| 8 | **Charla** | Subtipo (Disjunta) | `sesion_id` (`INT PK/FK`) | `sesion_id` | `tipo_sesion` (`'Charla'`), `minutos_preguntas` (`INT 0..120`) |
| 9 | **Taller** | Subtipo (Disjunta) | `sesion_id` (`INT PK/FK`) | `sesion_id` | `tipo_sesion` (`'Taller'`), `cupo_practico` (`INT > 0`), `requisitos_materiales` (`TEXT`) |
| 10 | **TransmisionVirtual** | Extensión 1:1 | `sesion_id` (`INT PK/FK`) | `enlace` (`VARCHAR(255)`) | `plataforma` (`VARCHAR(100)`), `enlace` (`VARCHAR(255)`), `codigo_acceso` (`VARCHAR(50) NULL`) |
| 11 | **Prerrequisito** | Asociativa Recursiva | `(sesion_id, prerrequisito_id)` | `(sesion_id, prerrequisito_id)` | `sesion_id` (`INT`), `prerrequisito_id` (`INT`), `obligatorio` (`BOOLEAN`) |
| 12 | **Inscripcion** | Asociativa N:M | `(asistente_id, sesion_id)` | `(asistente_id, sesion_id)` | `fecha_registro` (`TIMESTAMP`), `estado` (`VARCHAR(30)`), `asistio` (`BOOLEAN NULL`) |
| 13 | **AsignacionPonente** | Asociativa N:M | `(ponente_id, sesion_id)` | `(sesion_id, orden)` | `rol` (`Principal`, `Co-ponente`, `Moderador`, `Instructor`), `orden` (`INT > 0`) |
| 14 | **Empresa** | Fuerte | `id` (`INT IDENTITY`) | `nombre` (`VARCHAR(150)`) | `nombre`, `sector` (`VARCHAR(100)`), `sitio_web` (`VARCHAR(255) NULL`) |
| 15 | **AcuerdoPatrocinio** | Asociativa N:M | `id` (`INT IDENTITY`) | `(empresa_id, edicion_id)` | `empresa_id` (`INT`), `edicion_id` (`INT`), `categoria` (`VARCHAR(50)`), `monto` (`NUMERIC(12,2)`), `fecha_confirmacion` (`DATE`), `vigente` (`BOOLEAN`) |

---

## 3. Relaciones, Cardinalidades y Opcionalidad

| Relación | Tipo | Entidad A (Opcionalidad) | Entidad B (Opcionalidad) | Implementación Relacional |
|---|---|---|---|---|
| **Sesion — TransmisionVirtual** | **1:1** | `Sesion` (Obligatoria para la transmisión: `1..1`) | `TransmisionVirtual` (Opcional para sesiones presenciales: `0..1`) | `TransmisionVirtual.sesion_id` es `PRIMARY KEY` y `FOREIGN KEY` hacia `Sesion(id)`, garantizando máximo 1 transmisión por sesión. |
| **Sede — Edicion** | **1:N** | `Sede` (Opcional si la edición es virtual: `0..1`) | `Edicion` (Una sede puede albergar `0..N` ediciones a lo largo de los años) | `Edicion.sede_id` (`FK NULL`) + `CHECK` según `modalidad`. |
| **Sede — Sala** | **1:N** | `Sede` (Obligatoria: `1..1`) | `Sala` (Una sede contiene `1..N` salas) | `Sala.sede_id NOT NULL REFERENCES Sede(id)`. |
| **Edicion — Sesion** | **1:N** | `Edicion` (Obligatoria: `1..1`) | `Sesion` (Una edición organiza `1..N` sesiones) | `Sesion.edicion_id NOT NULL REFERENCES Edicion(id)`. |
| **Sala — Sesion** | **1:N** | `Sala` (Opcional para sesiones virtuales: `0..1`) | `Sesion` (Una sala aloja `0..N` sesiones sin solaparse) | `Sesion.sala_id NULL REFERENCES Sala(id)` + `EXCLUDE USING gist`. |
| **Asistente — Sesion** | **N:M** | `Asistente` (`0..N` sesiones) | `Sesion` (`0..N` asistentes) | Entidad asociativa **Inscripcion** con `PK (asistente_id, sesion_id)`. |
| **Ponente — Sesion** | **N:M** | `Ponente` (`1..N` sesiones) | `Sesion` (`1..N` ponentes) | Entidad asociativa **AsignacionPonente** con `PK (ponente_id, sesion_id)` y `UNIQUE (sesion_id, orden)`. |
| **Empresa — Edicion** | **N:M** | `Empresa` (`0..N` ediciones) | `Edicion` (`0..N` empresas) | Entidad asociativa **AcuerdoPatrocinio** con `PK (id)` y clave candidata `UNIQUE (empresa_id, edicion_id)`. |
| **Sesion — Sesion (Prerrequisito)** | **Recursiva N:M** | `Sesion` posterior (`0..N` prerrequisitos) | `Sesion` previa (`0..N` sesiones dependientes) | Entidad asociativa **Prerrequisito** con `PK (sesion_id, prerrequisito_id)` y `CHECK (sesion_id <> prerrequisito_id)`. |

---

## 4. Jerarquías de Especialización / Generalización

1. **Jerarquía de `Persona` (`Asistente` / `Ponente`) — SOLAPADA y TOTAL**:
   - **Por qué es Solapada (Overlapping)**: La narrativa indica que *"Dentro de una edición pueden participar como asistentes, ponentes o en ambos roles"*. Una misma persona puede estar registrada simultáneamente en `Asistente` y en `Ponente`.
   - **Por qué es Total**: La narrativa exige que *"Toda persona inscrita en una edición debe desempeñar al menos uno de esos roles"*.
   - **Estrategia de transformación**: Tabla de supertipo (`Persona`) + tablas de subtipo (`Asistente`, `Ponente`) donde la clave primaria del subtipo (`persona_id`) es a la vez clave foránea hacia `Persona(id)`. Así los subtipos conservan la identidad de su supertipo y se permite la pertenencia simultánea a ambos subtipos.
2. **Jerarquía de `Sesion` (`Charla` / `Taller`) — DISJUNTA y TOTAL**:
   - **Por qué es Disjunta (Disjoint)**: La narrativa establece que *"Toda sesión se clasifica exactamente como charla o taller"*. Ninguna sesión puede ser charla y taller al mismo tiempo.
   - **Por qué es Total**: No existen sesiones genéricas sin clasificar; toda sesión es o bien `Charla` o bien `Taller`.
   - **Estrategia de transformación**: Tabla de supertipo (`Sesion`) con discriminador `tipo_sesion CHECK IN ('Charla', 'Taller')` y restricción `UNIQUE (id, tipo_sesion)`, más tablas de subtipo (`Charla`, `Taller`) cuya PK es `sesion_id` y cuya FK compuesta `(sesion_id, tipo_sesion)` referencia a `Sesion(id, tipo_sesion)` con `CHECK (tipo_sesion = 'Charla')` y `CHECK (tipo_sesion = 'Taller')` respectivamente. Esto garantiza declarativamente en PostgreSQL tanto la conservación de identidad como la disyunción estricta.

---

## 5. Distinción entre Hechos Explícitos, Supuestos y Decisiones Propias

- **Hechos explícitos (extraídos literalmente de la narrativa)**:
  - Existen congresos presenciales, virtuales e híbridos en distintas ciudades.
  - Una edición presencial o híbrida utiliza una sede con varias salas; una sesión virtual puede carecer de sala pero requiere datos de transmisión.
  - Una sala no debe alojar dos sesiones cuyos horarios se superpongan.
  - Toda persona puede ser asistente, ponente o ambos (jerarquía solapada y total).
  - Toda sesión es exactamente charla o taller (jerarquía disjunta y total).
  - Ninguna sesión puede ser prerrequisito de sí misma.
  - No puede existir dos veces la misma inscripción de un asistente a una sesión.
  - Solo debe existir un acuerdo vigente por empresa patrocinadora y edición.
- **Supuestos del dominio (asumidos razonablemente a partir del contexto)**:
  - Una misma sede física (p. ej. un Centro de Convenciones) puede reutilizarse en distintas ediciones a lo largo de los años, pero cada edición presencial o híbrida se celebra en una única sede principal (`Edicion.sede_id`).
  - Los horarios de una sesión (`hora_inicio` y `hora_fin`) ocurren dentro de la misma `fecha` calendario de la sesión.
  - El atributo `asistio` en `Inscripcion` es `NULL` antes de que ocurra la sesión y pasa a `TRUE` o `FALSE` después del evento.
  - Dos ponentes asignados a una misma sesión no deben compartir el mismo número de `orden` en el programa (`UNIQUE (sesion_id, orden)`).
- **Decisiones propias de diseño técnico**:
  - Uso de la extensión oficial `btree_gist` de PostgreSQL 18 con `EXCLUDE USING gist (sala_id WITH =, tsrange(fecha + hora_inicio, fecha + hora_fin) WITH &&) WHERE (sala_id IS NOT NULL)` para hacer cumplir a nivel motor el no solapamiento de horarios en una misma sala.
  - Uso de clave foránea compuesta `(sesion_id, tipo_sesion)` en `Charla` y `Taller` para impedir a nivel DDL que una `Charla` se inserte en `Taller` o viceversa.
  - Uso de `GENERATED ALWAYS AS IDENTITY` en las entidades fuertes (`Sede`, `Edicion`, `Sala`, `Persona`, `Sesion`, `Empresa`, `AcuerdoPatrocinio`).

---

## 6. Catálogo de Reglas de Negocio (14 Reglas Implementadas)

| Código | Regla de Negocio | Clasificación | Mecanismo en PostgreSQL 18 (`01_schema.sql`) |
|---|---|---|---|
| **RN-01** | La fecha de cierre de una edición no puede ser anterior a su fecha de inicio. | Hecho explícito | `CONSTRAINT chk_edicion_fechas CHECK (fecha_fin >= fecha_inicio)` |
| **RN-02** | Una edición presencial o híbrida debe tener sede asignada; una virtual no tiene sede física. | Hecho explícito | `CONSTRAINT chk_edicion_sede_modalidad CHECK (...)` |
| **RN-03** | El correo electrónico de cada persona registrada es único y obligatorio. | Hecho explícito | `correo VARCHAR(150) NOT NULL UNIQUE CHECK (correo LIKE '%_@_%.__%')` |
| **RN-04** | Toda persona registrada desempeña el rol de Asistente, Ponente o ambos. | Hecho explícito | Jerarquía solapada `Asistente(persona_id)` y `Ponente(persona_id)` |
| **RN-05** | Toda sesión se clasifica exactamente como `Charla` o `Taller` (disjunta). | Hecho explícito | `CHECK (tipo_sesion IN ('Charla', 'Taller'))` + FK compuesta `(sesion_id, tipo_sesion)` |
| **RN-06** | La hora final de toda sesión debe ser estrictamente posterior a su hora inicial. | Hecho explícito | `CONSTRAINT chk_sesion_horario CHECK (hora_fin > hora_inicio)` |
| **RN-07** | Una sala no puede alojar dos sesiones cuyos horarios se superpongan en la misma fecha. | Hecho explícito | `CONSTRAINT excl_sala_sin_traslape EXCLUDE USING gist (...)` |
| **RN-08** | Una sesión tiene como máximo una configuración de transmisión virtual (relación 1:1). | Decisión propia | `TransmisionVirtual(sesion_id PRIMARY KEY REFERENCES Sesion(id))` |
| **RN-09** | Ninguna sesión puede ser prerrequisito de sí misma. | Hecho explícito | `CONSTRAINT chk_prerrequisito_no_recursivo CHECK (sesion_id <> prerrequisito_id)` |
| **RN-10** | Un asistente no puede inscribirse dos veces en la misma sesión. | Hecho explícito | `PRIMARY KEY (asistente_id, sesion_id)` en `Inscripcion` |
| **RN-11** | En una sesión con varios ponentes, no puede repetirse el orden de aparición en el programa. | Supuesto | `CONSTRAINT uq_sesion_orden_ponente UNIQUE (sesion_id, orden)` |
| **RN-12** | Solo puede existir un acuerdo de patrocinio vigente por empresa y edición. | Hecho explícito | `CONSTRAINT uq_acuerdo_empresa_edicion UNIQUE (empresa_id, edicion_id)` |
| **RN-13** | La capacidad de una sala y el cupo práctico de un taller deben ser enteros mayores que cero. | Supuesto | `CHECK (capacidad > 0)` y `CHECK (cupo_practico > 0)` |
| **RN-14** | Los minutos para preguntas en charlas son entre 0 y 120, y el monto de patrocinio es mayor a 0. | Decisión propia | `CHECK (minutos_preguntas BETWEEN 0 AND 120)` y `CHECK (monto > 0)` |
