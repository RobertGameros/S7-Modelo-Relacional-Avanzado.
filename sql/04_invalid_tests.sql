-- 1. Duplicado (Misma persona inscrita dos veces en la misma sesión - PK/UNIQUE)
INSERT INTO Inscripcion (asistente_id, sesion_id) VALUES (1, 1);

-- 2. FK inexistente (Sesion asignada a sala que no existe)
INSERT INTO Sesion (edicion_id, sala_id, titulo, resumen, fecha, hora_inicio, hora_fin, tipo_sesion)
VALUES (1, 999, 'Test FK', 'Test', '2026-10-10', '09:00', '10:00', 'Charla');

-- 3. Valor fuera de dominio (CHECK fecha_fin >= fecha_inicio)
INSERT INTO Edicion (nombre, anio, fecha_inicio, fecha_fin, estado)
VALUES ('Bad Edition', 2026, '2026-10-12', '2026-10-10', 'Activa');

-- 4. Dato obligatorio ausente (Persona sin correo - NOT NULL)
INSERT INTO Persona (nombre, correo, pais) VALUES ('Sin Correo', NULL, 'Mexico');

-- 5. Autorrelación inválida (Sesión es prerrequisito de sí misma - CHECK custom)
INSERT INTO Prerrequisito (sesion_id, prerrequisito_id) VALUES (1, 1);

-- 6. Violación adicional (Acuerdo de patrocinio duplicado para la misma empresa y edición - UNIQUE)
INSERT INTO AcuerdoPatrocinio (empresa_id, edicion_id, categoria, monto, fecha_confirmacion)
VALUES (1, 1, 'Plata', 2000.00, '2026-05-01');
