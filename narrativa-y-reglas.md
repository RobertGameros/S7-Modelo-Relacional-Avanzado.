# Narrativa y Reglas de Negocio

## Supuestos y Decisiones
- Se asume que una edición ocurre en una sola sede a la vez (Relación 1:1 para Edición presencial/híbrida con Sede, en el modelo físico se manejó como 1:N genérico pero restringido en lógica o asumiendo que sede pertenece a edición). Corrección: Una sede tiene muchas salas.
- Se implementó una entidad TransmisionVirtual con relación 1:1 con Sesion (mismo PK) para asegurar que la sesión tenga o no transmisión.
- La jerarquía de Persona (Asistente/Ponente) es total y solapada.
- La jerarquía de Sesion (Charla/Taller) es total y disjunta.
- Se usaron tablas asociativas para todas las relaciones N:M.

## Reglas de Negocio (12 mínimas)
1. Una edición debe tener una fecha de fin igual o posterior a su fecha de inicio.
2. Cada persona debe registrar un correo electrónico único.
3. Una sesión pertenece exactamente a un tipo (Charla o Taller).
4. Un asistente no puede inscribirse dos veces a la misma sesión.
5. Ninguna sesión puede ser prerrequisito de sí misma.
6. Una empresa solo puede tener un acuerdo vigente por edición.
7. Toda persona registrada debe ser asistente, ponente o ambos (controlado a nivel aplicación, facilitado por modelo).
8. La sala no puede tener capacidad negativa o cero.
9. La hora final de la sesión debe ser mayor a la hora inicial.
10. Un taller debe tener un cupo práctico mayor a cero.
11. Los minutos de preguntas de una charla no pueden ser negativos.
12. El monto de un acuerdo de patrocinio no puede ser negativo.
