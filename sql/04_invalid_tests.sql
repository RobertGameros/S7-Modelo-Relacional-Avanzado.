-- =============================================================================
-- S7: De la narrativa al modelo relacional avanzado — Congreso ConectaTech
-- Archivo: sql/04_invalid_tests.sql
-- Descripción: Pruebas de operaciones inválidas que DEBEN ser rechazadas por
--              PostgreSQL 18 para demostrar que las restricciones protegen la
--              integridad de los datos.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- PRUEBA INVÁLIDA 1: Duplicado (Misma inscripción registrada dos veces)
-- Restricción que la rechaza: PRIMARY KEY (asistente_id, sesion_id) en Inscripcion
-- Error esperado: ERROR: duplicate key value violates unique constraint "inscripcion_pkey"
-- -----------------------------------------------------------------------------
INSERT INTO Inscripcion (asistente_id, sesion_id)
VALUES (1, 1);

-- -----------------------------------------------------------------------------
-- PRUEBA INVÁLIDA 2: Clave foránea inexistente (Sala 999 no existe en Sala)
-- Restricción que la rechaza: FOREIGN KEY (sala_id) REFERENCES Sala(id)
-- Error esperado: ERROR: insert or update on table "sesion" violates foreign key constraint "sesion_sala_id_fkey"
-- -----------------------------------------------------------------------------
INSERT INTO Sesion (edicion_id, sala_id, titulo, resumen, fecha, hora_inicio, hora_fin, tipo_sesion)
VALUES (1, 999, 'Sesion con Sala Inexistente', 'Prueba de integridad referencial', '2026-10-10', '17:00', '18:00', 'Charla');

-- -----------------------------------------------------------------------------
-- PRUEBA INVÁLIDA 3: Valor fuera de dominio (Fecha final anterior a fecha inicial)
-- Restricción que la rechaza: CHECK (fecha_fin >= fecha_inicio) -> chk_edicion_fechas
-- Error esperado: ERROR: new row for relation "edicion" violates check constraint "chk_edicion_fechas"
-- -----------------------------------------------------------------------------
INSERT INTO Edicion (nombre, anio, ciudad, modalidad, fecha_inicio, fecha_fin, estado, sede_id)
VALUES ('Edicion Fechas Invalidas', 2026, 'Bogota', 'Presencial', '2026-10-12', '2026-10-10', 'Planificacion', 1);

-- -----------------------------------------------------------------------------
-- PRUEBA INVÁLIDA 4: Dato obligatorio ausente (Persona sin correo electrónico)
-- Restricción que la rechaza: NOT NULL en columna Persona.correo
-- Error esperado: ERROR: null value in column "correo" of relation "persona" violates not-null constraint
-- -----------------------------------------------------------------------------
INSERT INTO Persona (nombre, correo, pais)
VALUES ('Usuario Sin Correo', NULL, 'Mexico');

-- -----------------------------------------------------------------------------
-- PRUEBA INVÁLIDA 5: Autorrelación inválida (Sesión prerrequisito de sí misma)
-- Restricción que la rechaza: CHECK (sesion_id <> prerrequisito_id) -> chk_prerrequisito_no_recursivo
-- Error esperado: ERROR: new row for relation "prerrequisito" violates check constraint "chk_prerrequisito_no_recursivo"
-- -----------------------------------------------------------------------------
INSERT INTO Prerrequisito (sesion_id, prerrequisito_id)
VALUES (1, 1);

-- -----------------------------------------------------------------------------
-- PRUEBA INVÁLIDA 6: Violación adicional — Acuerdo vigente duplicado por empresa y edición
-- Restricción que la rechaza: UNIQUE (empresa_id, edicion_id) -> uq_acuerdo_empresa_edicion
-- Error esperado: ERROR: duplicate key value violates unique constraint "uq_acuerdo_empresa_edicion"
-- -----------------------------------------------------------------------------
INSERT INTO AcuerdoPatrocinio (empresa_id, edicion_id, categoria, monto, fecha_confirmacion)
VALUES (1, 1, 'Plata', 2000.00, '2026-05-01');

-- -----------------------------------------------------------------------------
-- PRUEBA INVÁLIDA 7 (Extra): Solapamiento de horario en la misma sala y fecha
-- La Sala 1 ya aloja la Sesión 1 el 2026-10-10 de 09:00 a 10:30.
-- Restricción que la rechaza: EXCLUDE USING gist (excl_sala_sin_traslape)
-- Error esperado: ERROR: conflicting key value violates exclusion constraint "excl_sala_sin_traslape"
-- -----------------------------------------------------------------------------
INSERT INTO Sesion (edicion_id, sala_id, titulo, resumen, fecha, hora_inicio, hora_fin, tipo_sesion)
VALUES (1, 1, 'Sesion Traslapada en Sala 1', 'Intenta ocupar la Sala 1 de 09:30 a 11:00', '2026-10-10', '09:30', '11:00', 'Charla');

-- -----------------------------------------------------------------------------
-- PRUEBA INVÁLIDA 8 (Extra): Violación de Jerarquía Disjunta (Registrar una Charla como Taller)
-- La Sesión 1 está clasificada como 'Charla'; no puede insertarse en Taller.
-- Restricción que la rechaza: FOREIGN KEY (sesion_id, tipo_sesion) -> fk_taller_sesion
-- Error esperado: ERROR: insert or update on table "taller" violates foreign key constraint "fk_taller_sesion"
-- -----------------------------------------------------------------------------
INSERT INTO Taller (sesion_id, cupo_practico, requisitos_materiales)
VALUES (1, 25, 'Intento de violar jerarquia disjunta');
