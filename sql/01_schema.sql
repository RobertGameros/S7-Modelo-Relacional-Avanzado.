-- =============================================================================
-- S7: De la narrativa al modelo relacional avanzado — Congreso ConectaTech
-- Archivo: sql/01_schema.sql
-- Motor: PostgreSQL 18.0
-- Descripción: Creación limpia del esquema relacional (15 tablas) con soporte
--              de jerarquías (solapada y disjunta), relaciones 1:1, 1:N, N:M,
--              autorrelación recursiva y exclusión de solapamiento de horarios.
-- =============================================================================

-- Limpieza previa para permitir reconstrucción idempotente
DROP TABLE IF EXISTS AcuerdoPatrocinio CASCADE;
DROP TABLE IF EXISTS Empresa CASCADE;
DROP TABLE IF EXISTS AsignacionPonente CASCADE;
DROP TABLE IF EXISTS Inscripcion CASCADE;
DROP TABLE IF EXISTS Prerrequisito CASCADE;
DROP TABLE IF EXISTS TransmisionVirtual CASCADE;
DROP TABLE IF EXISTS Taller CASCADE;
DROP TABLE IF EXISTS Charla CASCADE;
DROP TABLE IF EXISTS Sesion CASCADE;
DROP TABLE IF EXISTS Ponente CASCADE;
DROP TABLE IF EXISTS Asistente CASCADE;
DROP TABLE IF EXISTS Persona CASCADE;
DROP TABLE IF EXISTS Sala CASCADE;
DROP TABLE IF EXISTS Edicion CASCADE;
DROP TABLE IF EXISTS Sede CASCADE;

-- Extensión requerida para restricción de no solapamiento de horarios en salas
CREATE EXTENSION IF NOT EXISTS btree_gist;

-- -----------------------------------------------------------------------------
-- 1. SEDE
-- -----------------------------------------------------------------------------
CREATE TABLE Sede (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL UNIQUE,
    ciudad VARCHAR(100) NOT NULL,
    direccion TEXT NOT NULL
);

-- -----------------------------------------------------------------------------
-- 2. EDICION
-- Una edición presencial o híbrida utiliza una sede; una virtual puede no tener sede.
-- -----------------------------------------------------------------------------
CREATE TABLE Edicion (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL UNIQUE,
    anio INT NOT NULL CHECK (anio BETWEEN 2000 AND 2100),
    ciudad VARCHAR(100) NOT NULL,
    modalidad VARCHAR(20) NOT NULL DEFAULT 'Presencial'
        CHECK (modalidad IN ('Presencial', 'Virtual', 'Hibrida')),
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    estado VARCHAR(30) NOT NULL DEFAULT 'Planificacion'
        CHECK (estado IN ('Planificacion', 'En Curso', 'Finalizada', 'Cancelada')),
    sede_id INT REFERENCES Sede(id) ON DELETE RESTRICT,
    CONSTRAINT chk_edicion_fechas CHECK (fecha_fin >= fecha_inicio),
    CONSTRAINT chk_edicion_sede_modalidad CHECK (
        (modalidad IN ('Presencial', 'Hibrida') AND sede_id IS NOT NULL)
        OR (modalidad = 'Virtual' AND sede_id IS NULL)
    )
);

-- -----------------------------------------------------------------------------
-- 3. SALA (Relación 1:N desde Sede)
-- -----------------------------------------------------------------------------
CREATE TABLE Sala (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sede_id INT NOT NULL REFERENCES Sede(id) ON DELETE CASCADE,
    nombre VARCHAR(100) NOT NULL,
    capacidad INT NOT NULL CHECK (capacidad > 0),
    CONSTRAINT uq_sala_sede_nombre UNIQUE (sede_id, nombre)
);

-- -----------------------------------------------------------------------------
-- 4. PERSONA (Supertipo — Jerarquía Solapada y Total: Asistente / Ponente)
-- -----------------------------------------------------------------------------
CREATE TABLE Persona (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    correo VARCHAR(150) NOT NULL UNIQUE CHECK (correo LIKE '%_@_%.__%'),
    pais VARCHAR(100) NOT NULL DEFAULT 'Mexico'
);

-- -----------------------------------------------------------------------------
-- 5. ASISTENTE (Subtipo de Persona — conserva identidad persona_id)
-- -----------------------------------------------------------------------------
CREATE TABLE Asistente (
    persona_id INT PRIMARY KEY REFERENCES Persona(id) ON DELETE CASCADE,
    tipo_acreditacion VARCHAR(30) NOT NULL DEFAULT 'General'
        CHECK (tipo_acreditacion IN ('General', 'VIP', 'Estudiante', 'Prensa'))
);

-- -----------------------------------------------------------------------------
-- 6. PONENTE (Subtipo de Persona — conserva identidad persona_id)
-- -----------------------------------------------------------------------------
CREATE TABLE Ponente (
    persona_id INT PRIMARY KEY REFERENCES Persona(id) ON DELETE CASCADE,
    biografia TEXT NOT NULL CHECK (LENGTH(TRIM(biografia)) >= 10),
    especialidad VARCHAR(120) NOT NULL DEFAULT 'Tecnologia'
);

-- -----------------------------------------------------------------------------
-- 7. SESION (Supertipo — Jerarquía Disjunta y Total: Charla / Taller)
-- Incluye restricción EXCLUDE USING gist para impedir que una misma sala aloje
-- dos sesiones cuyos horarios se superpongan en la misma fecha.
-- -----------------------------------------------------------------------------
CREATE TABLE Sesion (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    edicion_id INT NOT NULL REFERENCES Edicion(id) ON DELETE CASCADE,
    sala_id INT REFERENCES Sala(id) ON DELETE SET NULL,
    titulo VARCHAR(200) NOT NULL,
    resumen TEXT NOT NULL,
    fecha DATE NOT NULL,
    hora_inicio TIME NOT NULL,
    hora_fin TIME NOT NULL,
    tipo_sesion VARCHAR(20) NOT NULL CHECK (tipo_sesion IN ('Charla', 'Taller')),
    CONSTRAINT uq_sesion_id_tipo UNIQUE (id, tipo_sesion),
    CONSTRAINT chk_sesion_horario CHECK (hora_fin > hora_inicio),
    CONSTRAINT excl_sala_sin_traslape EXCLUDE USING gist (
        sala_id WITH =,
        tsrange(fecha + hora_inicio, fecha + hora_fin) WITH &&
    ) WHERE (sala_id IS NOT NULL)
);

-- -----------------------------------------------------------------------------
-- 8. CHARLA (Subtipo Disjunto de Sesion — conserva identidad sesion_id)
-- La FK compuesta (sesion_id, tipo_sesion) garantiza disyunción total en SQL.
-- -----------------------------------------------------------------------------
CREATE TABLE Charla (
    sesion_id INT PRIMARY KEY,
    tipo_sesion VARCHAR(20) NOT NULL DEFAULT 'Charla' CHECK (tipo_sesion = 'Charla'),
    minutos_preguntas INT NOT NULL DEFAULT 15 CHECK (minutos_preguntas BETWEEN 0 AND 120),
    CONSTRAINT fk_charla_sesion FOREIGN KEY (sesion_id, tipo_sesion)
        REFERENCES Sesion(id, tipo_sesion) ON DELETE CASCADE
);

-- -----------------------------------------------------------------------------
-- 9. TALLER (Subtipo Disjunto de Sesion — conserva identidad sesion_id)
-- -----------------------------------------------------------------------------
CREATE TABLE Taller (
    sesion_id INT PRIMARY KEY,
    tipo_sesion VARCHAR(20) NOT NULL DEFAULT 'Taller' CHECK (tipo_sesion = 'Taller'),
    cupo_practico INT NOT NULL CHECK (cupo_practico > 0),
    requisitos_materiales TEXT NOT NULL DEFAULT 'Laptop personal',
    CONSTRAINT fk_taller_sesion FOREIGN KEY (sesion_id, tipo_sesion)
        REFERENCES Sesion(id, tipo_sesion) ON DELETE CASCADE
);

-- -----------------------------------------------------------------------------
-- 10. TRANSMISION_VIRTUAL (Relación 1:1 con Sesion mediante PK = FK)
-- -----------------------------------------------------------------------------
CREATE TABLE TransmisionVirtual (
    sesion_id INT PRIMARY KEY REFERENCES Sesion(id) ON DELETE CASCADE,
    plataforma VARCHAR(100) NOT NULL DEFAULT 'Zoom',
    enlace VARCHAR(255) NOT NULL UNIQUE,
    codigo_acceso VARCHAR(50)
);

-- -----------------------------------------------------------------------------
-- 11. PRERREQUISITO (Entidad Asociativa Recursiva N:M sobre Sesion)
-- -----------------------------------------------------------------------------
CREATE TABLE Prerrequisito (
    sesion_id INT NOT NULL REFERENCES Sesion(id) ON DELETE CASCADE,
    prerrequisito_id INT NOT NULL REFERENCES Sesion(id) ON DELETE CASCADE,
    obligatorio BOOLEAN NOT NULL DEFAULT TRUE,
    PRIMARY KEY (sesion_id, prerrequisito_id),
    CONSTRAINT chk_prerrequisito_no_recursivo CHECK (sesion_id <> prerrequisito_id)
);

-- -----------------------------------------------------------------------------
-- 12. INSCRIPCION (Entidad Asociativa N:M entre Asistente y Sesion)
-- -----------------------------------------------------------------------------
CREATE TABLE Inscripcion (
    asistente_id INT NOT NULL REFERENCES Asistente(persona_id) ON DELETE CASCADE,
    sesion_id INT NOT NULL REFERENCES Sesion(id) ON DELETE CASCADE,
    fecha_registro TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    estado VARCHAR(30) NOT NULL DEFAULT 'Confirmada'
        CHECK (estado IN ('Pendiente', 'Confirmada', 'Cancelada', 'ListaEspera')),
    asistio BOOLEAN DEFAULT NULL,
    PRIMARY KEY (asistente_id, sesion_id)
);

-- -----------------------------------------------------------------------------
-- 13. ASIGNACION_PONENTE (Entidad Asociativa N:M entre Ponente y Sesion)
-- -----------------------------------------------------------------------------
CREATE TABLE AsignacionPonente (
    ponente_id INT NOT NULL REFERENCES Ponente(persona_id) ON DELETE CASCADE,
    sesion_id INT NOT NULL REFERENCES Sesion(id) ON DELETE CASCADE,
    rol VARCHAR(50) NOT NULL DEFAULT 'Principal'
        CHECK (rol IN ('Principal', 'Co-ponente', 'Moderador', 'Instructor')),
    orden INT NOT NULL DEFAULT 1 CHECK (orden > 0),
    PRIMARY KEY (ponente_id, sesion_id),
    CONSTRAINT uq_sesion_orden_ponente UNIQUE (sesion_id, orden)
);

-- -----------------------------------------------------------------------------
-- 14. EMPRESA (Patrocinador)
-- -----------------------------------------------------------------------------
CREATE TABLE Empresa (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL UNIQUE,
    sector VARCHAR(100) NOT NULL DEFAULT 'Tecnologia',
    sitio_web VARCHAR(255)
);

-- -----------------------------------------------------------------------------
-- 15. ACUERDO_PATROCINIO (Entidad Asociativa N:M entre Empresa y Edicion)
-- Solo debe existir un acuerdo vigente por empresa y edición: UNIQUE(empresa_id, edicion_id)
-- -----------------------------------------------------------------------------
CREATE TABLE AcuerdoPatrocinio (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    empresa_id INT NOT NULL REFERENCES Empresa(id) ON DELETE CASCADE,
    edicion_id INT NOT NULL REFERENCES Edicion(id) ON DELETE CASCADE,
    categoria VARCHAR(50) NOT NULL
        CHECK (categoria IN ('Diamante', 'Platino', 'Oro', 'Plata', 'Bronce')),
    monto NUMERIC(12, 2) NOT NULL CHECK (monto > 0),
    fecha_confirmacion DATE NOT NULL DEFAULT CURRENT_DATE,
    vigente BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT uq_acuerdo_empresa_edicion UNIQUE (empresa_id, edicion_id)
);
