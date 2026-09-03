INSERT INTO Edicion (nombre, anio, fecha_inicio, fecha_fin, estado) VALUES
('ConectaTech 2026', 2026, '2026-10-10', '2026-10-12', 'Activa'),
('ConectaTech 2027', 2027, '2027-11-05', '2027-11-07', 'Planificacion');

INSERT INTO Sede (nombre, direccion) VALUES
('Centro de Convenciones', 'Av. Principal 123'),
('Sede Virtual', 'N/A');

INSERT INTO Sala (sede_id, nombre, capacidad) VALUES
(1, 'Sala A', 100),
(1, 'Sala B', 50),
(1, 'Laboratorio', 30);

INSERT INTO Persona (nombre, correo, pais) VALUES
('Ana Lopez', 'ana@email.com', 'Mexico'),
('Carlos Ruiz', 'carlos@email.com', 'Espana'),
('Elena Gomez', 'elena@email.com', 'Colombia'),
('David Perez', 'david@email.com', 'Argentina'),
('Sofia Castro', 'sofia@email.com', 'Chile'),
('Luis Vega', 'luis@email.com', 'Peru');

INSERT INTO Asistente (persona_id, tipo_acreditacion) VALUES
(1, 'VIP'), (2, 'General'), (3, 'Estudiante'), (4, 'VIP'), (5, 'General');

INSERT INTO Ponente (persona_id, biografia) VALUES
(4, 'Experto en IA y bases de datos'),
(5, 'Especialista en ciberseguridad'),
(6, 'Arquitecto Cloud');

INSERT INTO Sesion (edicion_id, sala_id, titulo, resumen, fecha, hora_inicio, hora_fin, tipo_sesion) VALUES
(1, 1, 'Futuro de IA', 'Tendencias', '2026-10-10', '09:00', '10:30', 'Charla'),
(1, 3, 'Taller Postgres', 'Optimización', '2026-10-10', '11:00', '14:00', 'Taller'),
(1, 2, 'Seguridad 101', 'Bases', '2026-10-11', '10:00', '11:00', 'Charla'),
(1, 1, 'Hacking Etico', 'Demo', '2026-10-11', '14:00', '16:00', 'Taller'),
(2, NULL, 'Cloud Nativo', 'Virtual', '2027-11-05', '09:00', '10:00', 'Charla'),
(1, 3, 'Taller Avanzado', 'Postgres', '2026-10-12', '09:00', '12:00', 'Taller');

INSERT INTO Charla (sesion_id, minutos_preguntas) VALUES
(1, 15), (3, 10), (5, 20);

INSERT INTO Taller (sesion_id, cupo_practico, requisitos_materiales) VALUES
(2, 25, 'Laptop'), (4, 30, 'Kali'), (6, 20, 'Taller Previo');

INSERT INTO TransmisionVirtual (sesion_id, enlace, plataforma) VALUES
(5, 'https://zoom.us/j/12345', 'Zoom');

INSERT INTO Prerrequisito (sesion_id, prerrequisito_id) VALUES
(6, 2);

INSERT INTO Inscripcion (asistente_id, sesion_id, estado, asistio) VALUES
(1, 1, 'Confirmada', true),
(1, 2, 'Confirmada', true),
(2, 1, 'Confirmada', false),
(3, 3, 'Confirmada', null),
(3, 4, 'Confirmada', null),
(4, 5, 'Confirmada', null),
(5, 6, 'Confirmada', null),
(2, 5, 'Confirmada', null);

INSERT INTO AsignacionPonente (ponente_id, sesion_id, rol, orden) VALUES
(4, 1, 'Principal', 1),
(4, 2, 'Instructor', 1),
(5, 3, 'Principal', 1),
(6, 5, 'Principal', 1);

INSERT INTO Empresa (nombre) VALUES ('TechGlobal'), ('CloudNet'), ('DataSec');

INSERT INTO AcuerdoPatrocinio (empresa_id, edicion_id, categoria, monto, fecha_confirmacion) VALUES
(1, 1, 'Platino', 10000.00, '2026-01-15'),
(2, 1, 'Oro', 5000.00, '2026-03-20'),
(1, 2, 'Diamante', 15000.00, '2026-08-10');
