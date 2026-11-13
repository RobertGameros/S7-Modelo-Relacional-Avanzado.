# Diccionario de Datos y Justificación del Modelo Lógico — ConectaTech

Este documento detalla las **15 relaciones (tablas)** del esquema ejecutable en **PostgreSQL 18**, incluyendo sus atributos, dominios, claves primarias (`PK`), claves foráneas (`FK`), claves candidatas (`UK`), valores por defecto (`DEFAULT`), restricciones de dominio (`CHECK`) y la justificación de transformación desde el modelo conceptual.

---

## 1. Justificación de Decisiones de Transformación

### 1.1 Estrategia para las Jerarquías
1. **Jerarquía Solapada y Total (`Persona` → `Asistente`, `Ponente`)**:
   - **Estrategia elegida**: *Supertipo con tablas por subtipo compartiendo clave primaria (`PK = FK`)*.
   - **Justificación**: Si se usara una sola tabla con columna discriminadora, habría columnas nulas y se requeriría un valor artificial como `'Ambos'`. Si se usaran solo tablas de subtipo sin supertipo, se duplicarían `nombre`, `correo` y `pais` cuando una persona es asistente y ponente a la vez, rompiendo la unicidad global de `correo`. Con 3 tablas (`Persona`, `Asistente`, `Ponente`) donde `persona_id` es `PRIMARY KEY` y `FOREIGN KEY REFERENCES Persona(id)`, los subtipos conservan exactamente la identidad del supertipo y una persona puede existir en ambas tablas sin redundancia.
2. **Jerarquía Disjunta y Total (`Sesion` → `Charla`, `Taller`)**:
   - **Estrategia elegida**: *Supertipo con discriminador `tipo_sesion` + tablas por subtipo con clave foránea compuesta `(sesion_id, tipo_sesion)`*.
   - **Justificación**: `Charla` y `Taller` poseen atributos específicos distintos (`minutos_preguntas` vs. `cupo_practico` y `requisitos_materiales`), mientras que todas las relaciones del programa (`Inscripcion`, `AsignacionPonente`, `Prerrequisito`, `TransmisionVirtual`) apuntan al supertipo `Sesion`. Al declarar `UNIQUE (id, tipo_sesion)` en `Sesion` y referenciar `(sesion_id, tipo_sesion)` desde `Charla` (`CHECK (tipo_sesion = 'Charla')`) y `Taller` (`CHECK (tipo_sesion = 'Taller')`), PostgreSQL impide declarativamente que una sesión de tipo `'Charla'` tenga fila en `Taller` o pertenezca a ambos subtipos.

### 1.2 Claves de las Entidades Asociativas y Relación 1:1
- **`Inscripcion` (N:M entre `Asistente` y `Sesion`)**: Clave primaria compuesta `PRIMARY KEY (asistente_id, sesion_id)`. Satisface directamente la regla de negocio *"No puede existir dos veces la misma inscripción"* sin necesidad de un ID artificial adicional.
- **`AsignacionPonente` (N:M entre `Ponente` y `Sesion`)**: Clave primaria compuesta `PRIMARY KEY (ponente_id, sesion_id)` y clave candidata `UNIQUE (sesion_id, orden)` para garantizar que un ponente no se asigne dos veces a la misma sesión y que dos ponentes no ocupen el mismo número de orden en el programa.
- **`Prerrequisito` (N:M Recursiva sobre `Sesion`)**: Clave primaria compuesta `PRIMARY KEY (sesion_id, prerrequisito_id)` acompañada de `CHECK (sesion_id <> prerrequisito_id)` para evitar ciclos reflexivos (una sesión como prerrequisito de sí misma).
- **`AcuerdoPatrocinio` (N:M entre `Empresa` y `Edicion`)**: Clave primaria subrogada `id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY` para facilitar referencias contables o de facturación al acuerdo, combinada con la clave candidata `UNIQUE (empresa_id, edicion_id)` que impone la regla *"solo debe existir un acuerdo vigente por empresa y edición"*.
- **`TransmisionVirtual` (1:1 con `Sesion`)**: Clave primaria `sesion_id INT PRIMARY KEY REFERENCES Sesion(id)`. Al ser la FK simultáneamente PK de la tabla, es imposible que existan dos transmisiones para la misma sesión (garantiza el máximo de uno).

---

## 2. Detalle de Tablas y Columnas (15 Tablas)

### 2.1 Tabla `Sede`
Representa el recinto físico donde se celebra una edición presencial o híbrida.

| Columna | Tipo de Dato | Nulabilidad | Default | Restricciones | Descripción |
|---|---|---|---|---|---|
| `id` | `INT` | `NOT NULL` | `IDENTITY` | `PRIMARY KEY` | Identificador único de la sede. |
| `nombre` | `VARCHAR(150)` | `NOT NULL` | — | `UNIQUE` | Nombre oficial del centro de convenciones o recinto. |
| `ciudad` | `VARCHAR(100)` | `NOT NULL` | — | — | Ciudad donde se ubica la sede. |
| `direccion` | `TEXT` | `NOT NULL` | — | — | Dirección física completa. |

### 2.2 Tabla `Edicion`
Representa cada edición anual del congreso ConectaTech.

| Columna | Tipo de Dato | Nulabilidad | Default | Restricciones | Descripción |
|---|---|---|---|---|---|
| `id` | `INT` | `NOT NULL` | `IDENTITY` | `PRIMARY KEY` | Identificador único de la edición. |
| `nombre` | `VARCHAR(150)` | `NOT NULL` | — | `UNIQUE` | Nombre comercial de la edición (ej. `ConectaTech Summit 2026`). |
| `anio` | `INT` | `NOT NULL` | — | `CHECK (anio BETWEEN 2000 AND 2100)` | Año de celebración. |
| `ciudad` | `VARCHAR(100)` | `NOT NULL` | — | — | Ciudad sede o ciudad organizadora. |
| `modalidad` | `VARCHAR(20)` | `NOT NULL` | `'Presencial'` | `CHECK (modalidad IN ('Presencial','Virtual','Hibrida'))` | Modalidad del congreso. |
| `fecha_inicio` | `DATE` | `NOT NULL` | — | — | Fecha de apertura de la edición. |
| `fecha_fin` | `DATE` | `NOT NULL` | — | `CHECK (fecha_fin >= fecha_inicio)` | Fecha de clausura de la edición. |
| `estado` | `VARCHAR(30)` | `NOT NULL` | `'Planificacion'` | `CHECK (estado IN ('Planificacion','En Curso','Finalizada','Cancelada'))` | Estado operativo de la edición. |
| `sede_id` | `INT` | `NULL` | `NULL` | `FK -> Sede(id)`, `CHECK (chk_edicion_sede_modalidad)` | Sede obligatoria si es Presencial/Híbrida; nula si es Virtual. |

### 2.3 Tabla `Sala`
Salas o auditorios pertenecientes a una `Sede`.

| Columna | Tipo de Dato | Nulabilidad | Default | Restricciones | Descripción |
|---|---|---|---|---|---|
| `id` | `INT` | `NOT NULL` | `IDENTITY` | `PRIMARY KEY` | Identificador único de la sala. |
| `sede_id` | `INT` | `NOT NULL` | — | `FK -> Sede(id) ON DELETE CASCADE`, `UNIQUE(sede_id, nombre)` | Sede a la que pertenece la sala. |
| `nombre` | `VARCHAR(100)` | `NOT NULL` | — | `UNIQUE(sede_id, nombre)` | Nombre de la sala dentro de la sede. |
| `capacidad` | `INT` | `NOT NULL` | — | `CHECK (capacidad > 0)` | Aforo máximo de personas. |

### 2.4 Tabla `Persona` (Supertipo)
Datos generales de cualquier participante registrado en ConectaTech.

| Columna | Tipo de Dato | Nulabilidad | Default | Restricciones | Descripción |
|---|---|---|---|---|---|
| `id` | `INT` | `NOT NULL` | `IDENTITY` | `PRIMARY KEY` | Identificador único de la persona. |
| `nombre` | `VARCHAR(150)` | `NOT NULL` | — | — | Nombre completo del participante. |
| `correo` | `VARCHAR(150)` | `NOT NULL` | — | `UNIQUE`, `CHECK (correo LIKE '%_@_%.__%')` | Correo electrónico único. |
| `pais` | `VARCHAR(100)` | `NOT NULL` | `'Mexico'` | — | País de procedencia. |

### 2.5 Tabla `Asistente` (Subtipo Solapado de `Persona`)
Rol de asistente que elige un tipo de acreditación.

| Columna | Tipo de Dato | Nulabilidad | Default | Restricciones | Descripción |
|---|---|---|---|---|---|
| `persona_id` | `INT` | `NOT NULL` | — | `PRIMARY KEY`, `FK -> Persona(id) ON DELETE CASCADE` | Identificador heredado de `Persona`. |
| `tipo_acreditacion` | `VARCHAR(30)` | `NOT NULL` | `'General'` | `CHECK (tipo_acreditacion IN ('General','VIP','Estudiante','Prensa'))` | Categoría de acreditación del asistente. |

### 2.6 Tabla `Ponente` (Subtipo Solapado de `Persona`)
Rol de expositor o instructor que mantiene una biografía profesional.

| Columna | Tipo de Dato | Nulabilidad | Default | Restricciones | Descripción |
|---|---|---|---|---|---|
| `persona_id` | `INT` | `NOT NULL` | — | `PRIMARY KEY`, `FK -> Persona(id) ON DELETE CASCADE` | Identificador heredado de `Persona`. |
| `biografia` | `TEXT` | `NOT NULL` | — | `CHECK (LENGTH(TRIM(biografia)) >= 10)` | Resumen curricular profesional del ponente. |
| `especialidad` | `VARCHAR(120)` | `NOT NULL` | `'Tecnologia'` | — | Área técnica principal del ponente. |

### 2.7 Tabla `Sesion` (Supertipo)
Actividad académica del programa de una edición (Charla o Taller).

| Columna | Tipo de Dato | Nulabilidad | Default | Restricciones | Descripción |
|---|---|---|---|---|---|
| `id` | `INT` | `NOT NULL` | `IDENTITY` | `PRIMARY KEY`, `UNIQUE(id, tipo_sesion)` | Identificador único de la sesión. |
| `edicion_id` | `INT` | `NOT NULL` | — | `FK -> Edicion(id) ON DELETE CASCADE` | Edición a la que pertenece la sesión. |
| `sala_id` | `INT` | `NULL` | `NULL` | `FK -> Sala(id) ON DELETE SET NULL`, `EXCLUDE USING gist (excl_sala_sin_traslape)` | Sala física asignada (nula si es 100% virtual). No permite solapamiento de horarios. |
| `titulo` | `VARCHAR(200)` | `NOT NULL` | — | — | Título oficial de la sesión. |
| `resumen` | `TEXT` | `NOT NULL` | — | — | Descripción del contenido de la sesión. |
| `fecha` | `DATE` | `NOT NULL` | — | — | Día en que se imparte la sesión. |
| `hora_inicio` | `TIME` | `NOT NULL` | — | — | Hora de inicio programada. |
| `hora_fin` | `TIME` | `NOT NULL` | — | `CHECK (hora_fin > hora_inicio)` | Hora de finalización programada. |
| `tipo_sesion` | `VARCHAR(20)` | `NOT NULL` | — | `CHECK (tipo_sesion IN ('Charla','Taller'))`, `UNIQUE(id, tipo_sesion)` | Discriminador de la jerarquía disjunta. |

### 2.8 Tabla `Charla` (Subtipo Disjunto de `Sesion`)
Subtipo para sesiones expositivas con espacio de preguntas.

| Columna | Tipo de Dato | Nulabilidad | Default | Restricciones | Descripción |
|---|---|---|---|---|---|
| `sesion_id` | `INT` | `NOT NULL` | — | `PRIMARY KEY`, `FK (sesion_id, tipo_sesion) -> Sesion(id, tipo_sesion)` | Identificador heredado de `Sesion`. |
| `tipo_sesion` | `VARCHAR(20)` | `NOT NULL` | `'Charla'` | `CHECK (tipo_sesion = 'Charla')` | Fija el subtipo a `'Charla'`. |
| `minutos_preguntas` | `INT` | `NOT NULL` | `15` | `CHECK (minutos_preguntas BETWEEN 0 AND 120)` | Minutos reservados para Q&A. |

### 2.9 Tabla `Taller` (Subtipo Disjunto de `Sesion`)
Subtipo para sesiones prácticas con cupo limitado y materiales requeridos.

| Columna | Tipo de Dato | Nulabilidad | Default | Restricciones | Descripción |
|---|---|---|---|---|---|
| `sesion_id` | `INT` | `NOT NULL` | — | `PRIMARY KEY`, `FK (sesion_id, tipo_sesion) -> Sesion(id, tipo_sesion)` | Identificador heredado de `Sesion`. |
| `tipo_sesion` | `VARCHAR(20)` | `NOT NULL` | `'Taller'` | `CHECK (tipo_sesion = 'Taller')` | Fija el subtipo a `'Taller'`. |
| `cupo_practico` | `INT` | `NOT NULL` | — | `CHECK (cupo_practico > 0)` | Cupo máximo de participantes prácticos. |
| `requisitos_materiales` | `TEXT` | `NOT NULL` | `'Laptop personal'` | — | Software o equipo previo requerido. |

### 2.10 Tabla `TransmisionVirtual` (Relación 1:1 con `Sesion`)
Datos de streaming para sesiones virtuales o híbridas.

| Columna | Tipo de Dato | Nulabilidad | Default | Restricciones | Descripción |
|---|---|---|---|---|---|
| `sesion_id` | `INT` | `NOT NULL` | — | `PRIMARY KEY`, `FK -> Sesion(id) ON DELETE CASCADE` | Garantiza relación 1:1 con `Sesion`. |
| `plataforma` | `VARCHAR(100)` | `NOT NULL` | `'Zoom'` | — | Plataforma de transmisión. |
| `enlace` | `VARCHAR(255)` | `NOT NULL` | — | `UNIQUE` | URL única de acceso a la transmisión. |
| `codigo_acceso` | `VARCHAR(50)` | `NULL` | `NULL` | — | Código o contraseña de acceso opcional. |

### 2.11 Tabla `Prerrequisito` (Asociativa Recursiva sobre `Sesion`)
Representa las sesiones previas que deben completarse antes de otra sesión.

| Columna | Tipo de Dato | Nulabilidad | Default | Restricciones | Descripción |
|---|---|---|---|---|---|
| `sesion_id` | `INT` | `NOT NULL` | — | `PK (sesion_id, prerrequisito_id)`, `FK -> Sesion(id)` | Sesión avanzada que exige el prerrequisito. |
| `prerrequisito_id` | `INT` | `NOT NULL` | — | `PK (sesion_id, prerrequisito_id)`, `FK -> Sesion(id)`, `CHECK (sesion_id <> prerrequisito_id)` | Sesión previa requerida. |
| `obligatorio` | `BOOLEAN` | `NOT NULL` | `TRUE` | — | Indica si el prerrequisito es estricto. |

### 2.12 Tabla `Inscripcion` (Asociativa N:M entre `Asistente` y `Sesion`)
Registro de inscripción y asistencia de un asistente a una sesión.

| Columna | Tipo de Dato | Nulabilidad | Default | Restricciones | Descripción |
|---|---|---|---|---|---|
| `asistente_id` | `INT` | `NOT NULL` | — | `PK (asistente_id, sesion_id)`, `FK -> Asistente(persona_id)` | Asistente inscrito. |
| `sesion_id` | `INT` | `NOT NULL` | — | `PK (asistente_id, sesion_id)`, `FK -> Sesion(id)` | Sesión en la que se inscribe. |
| `fecha_registro` | `TIMESTAMP` | `NOT NULL` | `CURRENT_TIMESTAMP` | — | Fecha y hora de la inscripción. |
| `estado` | `VARCHAR(30)` | `NOT NULL` | `'Confirmada'` | `CHECK (estado IN ('Pendiente','Confirmada','Cancelada','ListaEspera'))` | Estado de la inscripción. |
| `asistio` | `BOOLEAN` | `NULL` | `NULL` | — | `TRUE`/`FALSE` tras el evento; `NULL` antes del evento. |

### 2.13 Tabla `AsignacionPonente` (Asociativa N:M entre `Ponente` y `Sesion`)
Asignación de ponentes a sesiones con su rol y orden de aparición.

| Columna | Tipo de Dato | Nulabilidad | Default | Restricciones | Descripción |
|---|---|---|---|---|---|
| `ponente_id` | `INT` | `NOT NULL` | — | `PK (ponente_id, sesion_id)`, `FK -> Ponente(persona_id)` | Ponente asignado. |
| `sesion_id` | `INT` | `NOT NULL` | — | `PK (ponente_id, sesion_id)`, `FK -> Sesion(id)`, `UNIQUE(sesion_id, orden)` | Sesión impartida. |
| `rol` | `VARCHAR(50)` | `NOT NULL` | `'Principal'` | `CHECK (rol IN ('Principal','Co-ponente','Moderador','Instructor'))` | Rol del ponente en la sesión. |
| `orden` | `INT` | `NOT NULL` | `1` | `CHECK (orden > 0)`, `UNIQUE(sesion_id, orden)` | Orden de aparición en el programa de la sesión. |

### 2.14 Tabla `Empresa`
Empresas patrocinadoras vinculadas a ConectaTech.

| Columna | Tipo de Dato | Nulabilidad | Default | Restricciones | Descripción |
|---|---|---|---|---|---|
| `id` | `INT` | `NOT NULL` | `IDENTITY` | `PRIMARY KEY` | Identificador único de la empresa. |
| `nombre` | `VARCHAR(150)` | `NOT NULL` | — | `UNIQUE` | Razón social o nombre comercial único. |
| `sector` | `VARCHAR(100)` | `NOT NULL` | `'Tecnologia'` | — | Sector industrial de la empresa. |
| `sitio_web` | `VARCHAR(255)` | `NULL` | `NULL` | — | URL corporativa. |

### 2.15 Tabla `AcuerdoPatrocinio` (Asociativa N:M entre `Empresa` y `Edicion`)
Convenio económico de patrocinio de una empresa hacia una edición específica.

| Columna | Tipo de Dato | Nulabilidad | Default | Restricciones | Descripción |
|---|---|---|---|---|---|
| `id` | `INT` | `NOT NULL` | `IDENTITY` | `PRIMARY KEY` | Identificador único del acuerdo. |
| `empresa_id` | `INT` | `NOT NULL` | — | `FK -> Empresa(id) ON DELETE CASCADE`, `UNIQUE(empresa_id, edicion_id)` | Empresa patrocinadora. |
| `edicion_id` | `INT` | `NOT NULL` | — | `FK -> Edicion(id) ON DELETE CASCADE`, `UNIQUE(empresa_id, edicion_id)` | Edición patrocinada. |
| `categoria` | `VARCHAR(50)` | `NOT NULL` | — | `CHECK (categoria IN ('Diamante','Platino','Oro','Plata','Bronce'))` | Nivel de patrocinio. |
| `monto` | `NUMERIC(12,2)` | `NOT NULL` | — | `CHECK (monto > 0)` | Monto aportado en USD. |
| `fecha_confirmacion` | `DATE` | `NOT NULL` | `CURRENT_DATE` | — | Fecha de firma/confirmación del acuerdo. |
| `vigente` | `BOOLEAN` | `NOT NULL` | `TRUE` | — | Indica si el acuerdo se encuentra vigente. |
