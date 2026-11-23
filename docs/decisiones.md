# Decisiones

Formato: fecha · decisión · motivo. Las nuevas se añaden al final de este archivo; cuando pase de 12.000 caracteres,
lo anterior pasa a un archivo con la fecha de su primera decisión.

Anteriores:
- `decisiones-2026-10.md` y `decisiones-2026-10-b.md`: octubre (stack, arquitectura, reglas base).
- `decisiones-2026-11-01.md`: del 1 al 10 de noviembre (auth, prototipo, Pi).
- `decisiones-2026-11-11.md`: del 11 al 16 de noviembre (F1 y lo que salió de ella).
- `decisiones-2026-11-17.md`: del 17 al 24 de noviembre (modelo de datos, grappling, GR-1 a GR-5, plantillas).

- 2026-11-24 · Sesiones (GR-8): repetir una renovación cuya respuesta se perdió, hasta 12 h y mientras el par nuevo no se haya usado, devuelve el mismo token de renovación con un acceso nuevo; reusar uno cuando la sesión ya avanzó es robo (se revoca todo y se avisa) · regla de Raul: la sesión aguanta la fase con red perdida; antes, a los 10 s se cerraba. Riesgo aceptado: quien robe un token ya rotado comparte la sesión hasta que uno de los dos avance, y entonces salta el aviso.
