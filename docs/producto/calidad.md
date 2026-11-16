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
- Textos fijos en el servidor ("Equipo ") y `maxGroupsPerMat` sin uso.
- Código del prototipo en `features/` provisionales que solapan con `eventos`, `puntuacion`, `liga-fases` y `marcador-tapiz`.

### Método
1. **Inventario** con números: archivos de más de 400 líneas (Dart) o 300 (Java), métodos de más de 40 líneas, duplicados y dependencias entre features. Se repite al final para medir la mejora.
2. **Primero tests de caracterización** de lo que se toca (fijan lo que hace hoy), después refactor.
3. Una PR por módulo, **sin cambios de comportamiento** (lo que cambie el comportamiento va en otra PR).
4. Orden: lo que más se va a tocar después (marcador, grupos, tablero, configuración del evento).
5. Reglas automáticas para que no vuelva a pasar (propuesta): lints más estrictos en Flutter, un test que prohíba dependencias entre features en Java (ArchUnit) y un aviso del CI por archivo de más de 400 líneas.

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

### Cambios en el CI (tarea)
- Filtros por ruta: `server/**` → server; `app/**` o `packages/**` → app; `admin/**` o `packages/**` → admin.
- Un trabajo final `ci-ok` que resume a los demás: los saltados cuentan como verdes, así la protección de rama sigue pidiendo un solo check.
- En PRs hacia `main` (releases) no hay filtros: corre todo, más los E2E.
- E2E con **Playwright** sobre la web (Raul, 2026-11-16): login, inscripción, crear grupo, marcador con y sin red, sincronización. Usan el árbol de semántica de Flutter web (`08-ejecucion-local.md`) y corren solo en la batería completa de cada release, no en cada PR.

## Estado
Pendiente (2026-11-16). Tareas en `roadmap.md`, etapa 3.
