-- =============================================================================
-- S7: De la narrativa al modelo relacional avanzado — Congreso ConectaTech
-- Archivo: sql/02_seed.sql
-- Descripción: Carga de datos semilla para validar:
--   - 2 ediciones (1 Híbrida con sede, 1 Virtual sin sede)
--   - 1 sede física con 3 salas
--   - 6 personas (3 solo asistentes, 2 asistentes+ponentes solapados, 1 solo ponente)
--   - 6 sesiones (3 charlas y 3 talleres; 2 con transmisión virtual; 1 prerrequisito)
--   - 8 inscripciones con distintos estados y control de asistencia
--   - 4 asignaciones de ponentes con rol y orden de aparición
--   - 3 empresas patrocinadoras y 3 acuerdos de patrocinio
-- =============================================================================

-- 1. Sedes
INSERT INTO Sede (nombre, ciudad, direccion) VALUES
('Centro de Convenciones Citibanamex', 'Ciudad de Mexico', 'Av. del Conscripto 311, Lomas de Sotelo');

-- 2. Ediciones (2 ediciones: 1 Híbrida con sede_id=1 y 1 Virtual con sede_id=NULL)
INSERT INTO Edicion (nombre, anio, ciudad, modalidad, fecha_inicio, fecha_fin, estado, sede_id) VALUES
('ConectaTech Summit 2026', 2026, 'Ciudad de Mexico', 'Hibrida', '2026-10-10', '2026-10-12', 'En Curso', 1),
('ConectaTech Cloud Global 2027', 2027, 'Monterrey', 'Virtual', '2027-11-05', '2027-11-07', 'Planificacion', NULL);

-- 3. Salas de la Sede 1
INSERT INTO Sala (sede_id, nombre, capacidad) VALUES
(1, 'Auditorio Magna A', 120),
(1, 'Sala Ejecutiva B', 60),
(1, 'Laboratorio Hands-On C', 30);

-- 4. Personas (6 personas registradas)
INSERT INTO Persona (nombre, correo, pais) VALUES
('Ana Lopez', 'ana.lopez@conectatech.org', 'Mexico'),
('Carlos Ruiz', 'carlos.ruiz@conectatech.org', 'Espana'),
('Elena Gomez', 'elena.gomez@conectatech.org', 'Colombia'),
('David Perez', 'david.perez@conectatech.org', 'Argentina'),
('Sofia Castro', 'sofia.castro@conectatech.org', 'Chile'),
('Luis Vega', 'luis.vega@conectatech.org', 'Peru');

-- 5. Asistentes (Personas 1, 2, 3, 4 y 5; David [4] y Sofia [5] también serán ponentes -> Solapamiento)
INSERT INTO Asistente (persona_id, tipo_acreditacion) VALUES
(1, 'VIP'),
(2, 'General'),
(3, 'Estudiante'),
(4, 'VIP'),
(5, 'General');

-- 6. Ponentes (Personas 4, 5 y 6 -> Toda persona 1..6 desempeña al menos un rol)
INSERT INTO Ponente (persona_id, biografia, especialidad) VALUES
(4, 'Doctor en Ciencias de la Computacion y arquitecto de motores relacionales distribuidos.', 'Bases de Datos e IA'),
(5, 'Lider de respuesta a incidentes y consultora internacional en seguridad ofensiva.', 'Ciberseguridad'),
(6, 'Principal Cloud Architect con 12 anios disenando plataformas Kubernetes multi-region.', 'Arquitectura Cloud');

-- 7. Sesiones (6 sesiones: 3 Charlas y 3 Talleres)
INSERT INTO Sesion (edicion_id, sala_id, titulo, resumen, fecha, hora_inicio, hora_fin, tipo_sesion) VALUES
(1, 1, 'Futuro de la IA Generativa Empresarial', 'Tendencias y gobierno de datos en modelos fundacionales.', '2026-10-10', '09:00', '10:30', 'Charla'),
(1, 3, 'Taller de PostgreSQL 18 Fundamentos', 'Modelado relacional avanzado, indices GiST y restricciones declarativas.', '2026-10-10', '11:00', '14:00', 'Taller'),
(1, 2, 'Ciberseguridad Zero-Trust 101', 'Principios de verificacion explicita y microsegmentacion en la nube.', '2026-10-11', '10:00', '11:30', 'Charla'),
(1, 1, 'Taller de Hacking Etico y Hardening', 'Laboratorio controlado de deteccion y mitigacion de vulnerabilidades web.', '2026-10-11', '14:00', '16:30', 'Taller'),
(2, NULL, 'Arquitecturas Cloud-Native Resilientes', 'Keynote virtual sobre sistemas distribuidos sin estado y alta disponibilidad.', '2027-11-05', '09:00', '10:30', 'Charla'),
(1, 3, 'Taller Avanzado de Tuning en PostgreSQL 18', 'Optimizacion de planes de ejecucion, particionamiento y concurrencia MVCC.', '2026-10-12', '09:00', '12:00', 'Taller');

-- 8. Subtipo Charla (Sesiones 1, 3 y 5)
INSERT INTO Charla (sesion_id, minutos_preguntas) VALUES
(1, 20),
(3, 15),
(5, 25);

-- 9. Subtipo Taller (Sesiones 2, 4 y 6)
INSERT INTO Taller (sesion_id, cupo_practico, requisitos_materiales) VALUES
(2, 25, 'Laptop con Docker Desktop y cliente PostgreSQL 18'),
(4, 30, 'Maquina virtual Kali Linux 2026 con 8 GB de RAM'),
(6, 20, 'Haber completado el Taller de PostgreSQL 18 Fundamentos y entorno Docker activo');

-- 10. Transmisión Virtual (Relación 1:1 con Sesion: sesión híbrida 1 y sesión virtual 5)
INSERT INTO TransmisionVirtual (sesion_id, plataforma, enlace, codigo_acceso) VALUES
(1, 'YouTube Live Enterprise', 'https://stream.conectatech.org/2026/keynote-ia', 'CT2026-IA'),
(5, 'Zoom Webinars', 'https://zoom.us/j/9876543210', 'CLOUD-2027');

-- 11. Prerrequisitos entre Sesiones (Sesión 6 requiere haber completado Sesión 2; Sesión 4 requiere Sesión 3)
INSERT INTO Prerrequisito (sesion_id, prerrequisito_id, obligatorio) VALUES
(6, 2, TRUE),
(4, 3, TRUE);

-- 12. Inscripciones (8 inscripciones de asistentes a sesiones)
INSERT INTO Inscripcion (asistente_id, sesion_id, fecha_registro, estado, asistio) VALUES
(1, 1, '2026-09-15 10:15:00', 'Confirmada', TRUE),
(1, 2, '2026-09-15 10:20:00', 'Confirmada', TRUE),
(2, 1, '2026-09-18 14:30:00', 'Confirmada', FALSE),
(3, 3, '2026-09-20 09:00:00', 'Confirmada', TRUE),
(3, 4, '2026-09-20 09:05:00', 'Confirmada', TRUE),
(4, 5, '2026-10-01 11:45:00', 'Confirmada', NULL),
(5, 6, '2026-10-02 16:10:00', 'Confirmada', NULL),
(2, 5, '2026-10-03 18:00:00', 'Pendiente', NULL);

-- 13. Asignaciones de Ponentes (4 asignaciones con rol y orden de aparición en el programa)
INSERT INTO AsignacionPonente (ponente_id, sesion_id, rol, orden) VALUES
(4, 1, 'Principal', 1),
(4, 2, 'Instructor', 1),
(5, 3, 'Principal', 1),
(6, 5, 'Principal', 1);

-- 14. Empresas Patrocinadoras (3 empresas)
INSERT INTO Empresa (nombre, sector, sitio_web) VALUES
('TechGlobal Corp', 'Inteligencia Artificial', 'https://techglobal.example.com'),
('CloudNet Solutions', 'Infraestructura Cloud', 'https://cloudnet.example.com'),
('DataSec Guard', 'Ciberseguridad', 'https://datasec.example.com');

-- 15. Acuerdos de Patrocinio (3 acuerdos; TechGlobal apoya ambas ediciones, pero solo 1 acuerdo por edición)
INSERT INTO AcuerdoPatrocinio (empresa_id, edicion_id, categoria, monto, fecha_confirmacion, vigente) VALUES
(1, 1, 'Platino', 10000.00, '2026-01-15', TRUE),
(2, 1, 'Oro', 5000.00, '2026-03-20', TRUE),
(1, 2, 'Diamante', 15000.00, '2026-08-10', TRUE);
