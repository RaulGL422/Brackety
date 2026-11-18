# Calidad: código legible, pantallas ordenadas y tests

Pedido de Raul (2026-11-16): optimizar mucho el código para que se lea mejor, ordenar las pantallas y hacer una revisión de diseño a fondo siempre que se pueda.

## 1. Código legible
### Objetivo
Que cualquier pantalla o servicio se entienda sin haberlo escrito. El prototipo F1 se hizo con prisa: hay que convertirlo en los módulos reales.

### Puntos conocidos (`revision-f1.md` y F1)
- Servicios largos: `MatBoardService.board` (~100 líneas), `LocalMatch.project` (~120), `StandingsService` (con el CSV dentro).
- Pantallas largas: `team_category_screen.dart` (586 líneas) y el resto de pantallas del club.
- Duplicados: nombre del competidor en 3 servicios; comprobación "club o árbitro del tapiz" repetida.
- La vista del combate carga todo el directorio del evento, cuando solo necesita a 2 competidores.
- Textos fijos en el servidor ("Equipo "); `maxGroupsPerMat` ya quitado (rama `chore/drop-max-groups-per-mat`, 2026-11-18).
- Código del prototipo en `features/` provisionales que solapan con `eventos`, `puntuacion`, `liga-fases` y `marcador-tapiz`.

### Método
1. **Inventario** con números: archivos de más de 400 líneas (Dart) o 300 (Java), métodos de más de 40 líneas, duplicados y dependencias entre features. Se repite al final para medir la mejora.
2. **Primero tests de caracterización** de lo que se toca (fijan lo que hace hoy), después refactor.
3. Una PR por módulo, **sin cambios de comportamiento** (lo que cambie el comportamiento va en otra PR).
4. Orden: lo que más se va a tocar después (marcador, grupos, tablero, configuración del evento).
5. Reglas automáticas para que no vuelva a pasar: `tools/code_metrics.py` (hecho, 2026-11-18) mide archivos largos, métodos de 60 líneas o más, features de la app en un ciclo de imports y código duplicado; el CI (trabajo `metrics`) falla si una cifra supera su límite en `tools/code_metrics.json`, y los límites solo bajan. Después: lints más estrictos en Flutter y ArchUnit en Java (fase L0 de `plan-limpieza.md`).

## 2. Pantallas ordenadas y revisión de diseño
- Toda PR que cambie una pantalla pasa **la skill `frontend-design`** (plugin del proyecto) y capturas con Playwright en 360×800, 800×1280 y 1440×900 antes de pedir revisión (`.claude/rules/frontend-flutter.md`).
- Revisión completa (una vez, tras el refactor): todas las pantallas de app y admin contra `07-diseno.md`. Salida: lista priorizada y maquetas antes de programar.
- Ya pendiente en `pendientes.md` (Diseño tras la Fase 1): anchos de escritorio, más información por pantalla, previsión del día por tapiz, sistema neutro en todas las pantallas y "Tapiz" según el deporte.
- Arquitectura de la información del evento: `eventos-ux.md`.

## 3. Política de tests (decisión de Raul, 2026-11-16)
| Momento | Qué se ejecuta |
|---|---|
| Mientras se desarrolla | Solo los tests del módulo tocado |
| PR a `development` | Solo los componentes tocados (server, app, admin, core) + docs |
| Release `release/vX.Y.Z` → `main` | **Batería completa**: todos los tests, E2E de flujos críticos, prueba de despliegue y de restauración del backup |
| Cierre de módulo | Suite completa del componente + checklist de `04-testing.md` |

### Cambios en el CI (hecho, 2026-11-17, rama `chore/ci-components`)
- Trabajo `changes`: mira qué archivos cambia la PR. `server/**` → server; `packages/**` → core, app y admin; `app/**` → app; `admin/**` → admin. Tocar `ci.yml` prueba todo.
- `docs` corre siempre (es rápido). Las imágenes (`images.yml`) no se construyen en PRs solo de docs.
- Trabajo final `ci-ok`: los saltados cuentan como verdes, los fallidos o cancelados no. Es el único check que debe pedir la protección de rama.
- PRs hacia `main` (releases) y pushes: sin filtros, corre todo. Los E2E llegarán con la tarea 5 de la etapa 3.
- E2E con **Playwright** sobre la web (Raul, 2026-11-16): login, inscripción, crear grupo, marcador con y sin red, sincronización. Usan el árbol de semántica de Flutter web (`08-ejecucion-local.md`) y corren solo en la batería completa de cada release, no en cada PR.

## Estado
Tarea 1 (CI por componentes) en pruebas (2026-11-17). Tarea 2 (inventario) hecha: `auditoria-codigo.md` (2026-11-18), con el plan por fases en `plan-limpieza.md` y la revisión de diseño en `diseno-revision.md` (propuestas). Resto pendiente; tareas en `roadmap.md`, etapa 3.
