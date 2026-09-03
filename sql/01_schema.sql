CREATE TABLE Edicion (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    anio INT NOT NULL CHECK (anio >= 2000),
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    estado VARCHAR(50) NOT NULL DEFAULT 'Planificacion',
    CHECK (fecha_fin >= fecha_inicio)
);

CREATE TABLE Sede (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    direccion TEXT NOT NULL
);

CREATE TABLE Sala (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sede_id INT NOT NULL REFERENCES Sede(id) ON DELETE CASCADE,
    nombre VARCHAR(100) NOT NULL,
    capacidad INT NOT NULL CHECK (capacidad > 0)
);

CREATE TABLE Persona (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    correo VARCHAR(150) NOT NULL UNIQUE,
    pais VARCHAR(100) NOT NULL
);

CREATE TABLE Asistente (
    persona_id INT PRIMARY KEY REFERENCES Persona(id) ON DELETE CASCADE,
    tipo_acreditacion VARCHAR(50) NOT NULL
);

CREATE TABLE Ponente (
    persona_id INT PRIMARY KEY REFERENCES Persona(id) ON DELETE CASCADE,
    biografia TEXT NOT NULL
);

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
    CHECK (hora_fin > hora_inicio)
);

CREATE TABLE Charla (
    sesion_id INT PRIMARY KEY REFERENCES Sesion(id) ON DELETE CASCADE,
    minutos_preguntas INT NOT NULL DEFAULT 15 CHECK (minutos_preguntas >= 0)
);

CREATE TABLE Taller (
    sesion_id INT PRIMARY KEY REFERENCES Sesion(id) ON DELETE CASCADE,
    cupo_practico INT NOT NULL CHECK (cupo_practico > 0),
    requisitos_materiales TEXT
);

CREATE TABLE TransmisionVirtual (
    sesion_id INT PRIMARY KEY REFERENCES Sesion(id) ON DELETE CASCADE,
    enlace VARCHAR(255) NOT NULL,
    plataforma VARCHAR(100) NOT NULL
);

CREATE TABLE Inscripcion (
    asistente_id INT NOT NULL REFERENCES Asistente(persona_id) ON DELETE CASCADE,
    sesion_id INT NOT NULL REFERENCES Sesion(id) ON DELETE CASCADE,
    fecha_registro TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    estado VARCHAR(50) NOT NULL DEFAULT 'Confirmada',
    asistio BOOLEAN,
    PRIMARY KEY (asistente_id, sesion_id)
);

CREATE TABLE AsignacionPonente (
    ponente_id INT NOT NULL REFERENCES Ponente(persona_id) ON DELETE CASCADE,
    sesion_id INT NOT NULL REFERENCES Sesion(id) ON DELETE CASCADE,
    rol VARCHAR(50) NOT NULL DEFAULT 'Principal',
    orden INT NOT NULL DEFAULT 1 CHECK (orden > 0),
    PRIMARY KEY (ponente_id, sesion_id)
);

CREATE TABLE Empresa (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL UNIQUE
);

CREATE TABLE AcuerdoPatrocinio (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    empresa_id INT NOT NULL REFERENCES Empresa(id) ON DELETE CASCADE,
    edicion_id INT NOT NULL REFERENCES Edicion(id) ON DELETE CASCADE,
    categoria VARCHAR(50) NOT NULL,
    monto NUMERIC(10, 2) NOT NULL CHECK (monto >= 0),
    fecha_confirmacion DATE NOT NULL,
    UNIQUE (empresa_id, edicion_id)
);

CREATE TABLE Prerrequisito (
    sesion_id INT NOT NULL REFERENCES Sesion(id) ON DELETE CASCADE,
    prerrequisito_id INT NOT NULL REFERENCES Sesion(id) ON DELETE CASCADE,
    PRIMARY KEY (sesion_id, prerrequisito_id),
    CHECK (sesion_id != prerrequisito_id)
);
