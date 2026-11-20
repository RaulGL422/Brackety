# Grappling: deporte nuevo y primer evento

Pedido de Raul (2026-11-20): un evento de grappling con grupos como la F1 individual, con el reglamento FELODA, todas las edades, con y sin gi. Va **antes que L1** (`plan-limpieza.md`). Reglamento resumido en `../reglamentos/grappling-feloda-2025.md`.

## Decisiones (Raul, 2026-11-20)
- Todas las edades (U13 a veteranos), con y sin gi.
- Grupos todos contra todos, clasificados con los **puntos de clasificación FELODA** (art. 39) y el criterio nórdico (art. 8).
- El evento se prepara como escenario en debug para revisarlo; en producción lo crea Raul con la cuenta de la entidad (no hay importación entre servidores).

## Cómo se hace
- **Reglas como datos de la modalidad**, no un segundo motor junto a `TamboMatch` (que pasa a llamarse `MatchState`): valor de cada punto, amonestaciones que dan punto (cada 1 o cada 2), cuántas descalifican, fin por límite o por diferencia, sumisión, puntos tras el tiempo y desempate. Es el primer paso del motor por datos (L7, `plan-limpieza.md`).
- Gi y sin gi puntúan igual: **un solo deporte** "Grappling"; cambia la lista de prohibiciones de cada categoría.
- El tambo no cambia: lo garantizan `spec/scoring/tambo.json` y la comprobación de oro.

## Pasos (una PR cada uno)
| Paso | Qué |
|---|---|
| G1 | Motor de reglas en Java y Dart: puntos de +1 a +4, amonestación con punto al rival, la 4.ª descalifica, superioridad por diferencia, sumisión, desempate (acciones de más valor, menos amonestaciones) y prórroga. Casos en `spec/scoring/grappling.json` |
| G2 | Deporte "Grappling" disponible: reglas, motivos de amonestación del reglamento, duración por categoría (4 o 5 min), puntos de clasificación y criterio nórdico en Puntuaciones, cómo acabó en los CSV |
| G3 | Marcador: botones +1 a +4 por esquina, amonestación con motivo, Sumisión, Prórroga; tests en 3 tamaños |
| G4 | Crear un evento suelto (nombre, fecha, deporte, tapices); hoy solo se crean fases de una liga |
| G5 | Escenario "Grappling" en debug: categorías U13 a veteranos, gi y sin gi, alumnos ficticios |

## Fuera por ahora
- Peso y sexo como filtros de la categoría (F2-4): el peso va en el nombre ("U15 M -46 kg") y el ayudante agrupa.
- Eliminación directa con repesca (8 o más por categoría): módulo `torneo`.
- Semifinales cruzadas con 6-7 inscritos: se hacen como dos grupos.
- Juez y jefe de tapiz con dispositivo propio: un árbitro por tapiz apunta lo que decide el equipo.

## Estado
G1 en curso (2026-11-20).
