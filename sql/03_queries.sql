-- =============================================================================
-- S7: De la narrativa al modelo relacional avanzado — Congreso ConectaTech
-- Archivo: sql/03_queries.sql
-- Descripción: Consultas de negocio para verificar relaciones (1:1, 1:N, N:M,
--              jerarquías y recursividad), consultar el programa, los cupos y
--              la participación de asistentes y ponentes.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- CONSULTA 1: Participación e inscripciones atravesando 5 tablas
-- (Persona -> Asistente -> Inscripcion -> Sesion -> Edicion)
-- -----------------------------------------------------------------------------
SELECT
    p.nombre AS asistente,
    a.tipo_acreditacion,
    s.titulo AS sesion,
    s.tipo_sesion,
    e.nombre AS edicion,
    i.estado AS estado_inscripcion,
    COALESCE(CASE WHEN i.asistio THEN 'Asistio' WHEN i.asistio = FALSE THEN 'No asistio' END, 'Por realizar') AS asistencia
FROM Persona p
JOIN Asistente a ON p.id = a.persona_id
JOIN Inscripcion i ON a.persona_id = i.asistente_id
JOIN Sesion s ON i.sesion_id = s.id
JOIN Edicion e ON s.edicion_id = e.id
ORDER BY e.fecha_inicio, s.fecha, s.hora_inicio, p.nombre;

-- -----------------------------------------------------------------------------
-- CONSULTA 2: Programa completo del congreso con sede, sala, modalidad de
-- transmisión virtual (1:1) y ponentes asignados en orden (N:M)
-- -----------------------------------------------------------------------------
SELECT
    e.nombre AS edicion,
    s.fecha,
    s.hora_inicio,
    s.hora_fin,
    s.titulo AS sesion,
    s.tipo_sesion,
    COALESCE(sa.nombre, 'Sin sala (Virtual)') AS sala,
    COALESCE(tv.plataforma || ' (' || tv.enlace || ')', 'Solo presencial') AS transmision,
    p.nombre AS ponente,
    ap.rol AS rol_ponente,
    ap.orden AS orden_programa
FROM Sesion s
JOIN Edicion e ON s.edicion_id = e.id
LEFT JOIN Sala sa ON s.sala_id = sa.id
LEFT JOIN TransmisionVirtual tv ON s.id = tv.sesion_id
LEFT JOIN AsignacionPonente ap ON s.id = ap.sesion_id
LEFT JOIN Ponente po ON ap.ponente_id = po.persona_id
LEFT JOIN Persona p ON po.persona_id = p.id
ORDER BY s.fecha, s.hora_inicio, ap.orden;

-- -----------------------------------------------------------------------------
-- CONSULTA 3: Control de cupos en Talleres y capacidad de Salas vs. Inscritos
-- (Jerarquía Disjunta Sesion -> Taller + Sala + Conteo de Inscripcion)
-- -----------------------------------------------------------------------------
SELECT
    s.id AS sesion_id,
    s.titulo AS taller,
    sa.nombre AS sala,
    sa.capacidad AS capacidad_sala,
    t.cupo_practico,
    COUNT(i.asistente_id) FILTER (WHERE i.estado = 'Confirmada') AS inscritos_confirmados,
    (t.cupo_practico - COUNT(i.asistente_id) FILTER (WHERE i.estado = 'Confirmada')) AS cupos_disponibles,
    t.requisitos_materiales
FROM Taller t
JOIN Sesion s ON t.sesion_id = s.id
LEFT JOIN Sala sa ON s.sala_id = sa.id
LEFT JOIN Inscripcion i ON s.id = i.sesion_id
GROUP BY s.id, s.titulo, sa.nombre, sa.capacidad, t.cupo_practico, t.requisitos_materiales
ORDER BY s.id;

-- -----------------------------------------------------------------------------
-- CONSULTA 4: Demostración de Jerarquía Solapada (Personas que son Asistentes,
-- Ponentes o AMBOS roles simultáneamente)
-- -----------------------------------------------------------------------------
SELECT
    p.id,
    p.nombre,
    p.correo,
    p.pais,
    CASE WHEN a.persona_id IS NOT NULL THEN 'Si (' || a.tipo_acreditacion || ')' ELSE 'No' END AS rol_asistente,
    CASE WHEN po.persona_id IS NOT NULL THEN 'Si (' || po.especialidad || ')' ELSE 'No' END AS rol_ponente,
    CASE
        WHEN a.persona_id IS NOT NULL AND po.persona_id IS NOT NULL THEN 'AMBOS (Solapado)'
        WHEN a.persona_id IS NOT NULL THEN 'Solo Asistente'
        WHEN po.persona_id IS NOT NULL THEN 'Solo Ponente'
    END AS clasificacion_jerarquia
FROM Persona p
LEFT JOIN Asistente a ON p.id = a.persona_id
LEFT JOIN Ponente po ON p.id = po.persona_id
ORDER BY p.id;

-- -----------------------------------------------------------------------------
-- CONSULTA 5: Cadena de prerrequisitos entre sesiones (Relación Recursiva)
-- y resumen de patrocinios por edición (Empresa -> AcuerdoPatrocinio -> Edicion)
-- -----------------------------------------------------------------------------
SELECT
    s_actual.titulo AS sesion_avanzada,
    s_previa.titulo AS sesion_prerrequisito,
    pr.obligatorio
FROM Prerrequisito pr
JOIN Sesion s_actual ON pr.sesion_id = s_actual.id
JOIN Sesion s_previa ON pr.prerrequisito_id = s_previa.id;

SELECT
    e.nombre AS edicion,
    em.nombre AS empresa_patrocinadora,
    ap.categoria,
    ap.monto,
    ap.fecha_confirmacion
FROM AcuerdoPatrocinio ap
JOIN Empresa em ON ap.empresa_id = em.id
JOIN Edicion e ON ap.edicion_id = e.id
ORDER BY e.anio, ap.monto DESC;
