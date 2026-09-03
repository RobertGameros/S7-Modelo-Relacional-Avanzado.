-- Consulta que atraviesa al menos tres tablas (Persona -> Inscripcion -> Sesion -> Edicion)
SELECT 
    p.nombre AS asistente, 
    s.titulo AS sesion, 
    e.nombre AS edicion,
    i.fecha_registro
FROM Persona p
JOIN Asistente a ON p.id = a.persona_id
JOIN Inscripcion i ON a.persona_id = i.asistente_id
JOIN Sesion s ON i.sesion_id = s.id
JOIN Edicion e ON s.edicion_id = e.id
ORDER BY e.fecha_inicio, s.hora_inicio;
