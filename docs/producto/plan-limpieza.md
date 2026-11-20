# Plan de limpieza del código

Arreglo de lo que encontró `auditoria-codigo.md`, por fases. Sigue el método de `calidad.md`: tests de caracterización antes, una PR por paso, sin mezclar cambios de comportamiento.

## Principios
- **Primero lo que quita trabajo a todo lo demás**: la red de seguridad (L0) y el modelo único de competidor (M3) valen más que pulir pantallas que van a cambiar.
- **No pulir lo que se va a sustituir**: `TamboMatch` (motor de reglas por datos, L7) y el formulario de Configuración (rediseño de `eventos-ux.md`) se parten por sus secciones nuevas, no dos veces.
- **Calendario manda**: antes del 20-12 y del 24-01 solo fases pequeñas y sin riesgo (L0-L2), en paralelo a lo urgente.
- Cada fase termina repitiendo la medición (`auditoria-codigo.md`) y anotando la mejora.

## Fases
| Fase | Qué | Cuándo | Tamaño |
|---|---|---|---|
| L0 | Red de seguridad y medición automática | Ya | S |
| L1 | Arreglos rápidos sin cambio de comportamiento | Ya | S |
| L2 | Romper los ciclos de la app | Antes del 24-01 | M |
| L3 | Errores con código y pestañas como rutas | Antes del 24-01 | M |
| L4 | Panel de control único (app y admin) | Tras el 24-01 | M |
| L5 | Servidor: subpaquetes y métodos cortos | Tras el 24-01, con M3-M4 | L |
| L6 | Modelo de datos M2d-M6 (ya planificado) | `modelo-datos-migracion.md` | L |
| L7 | Motor de reglas por datos (base de las plantillas) | Etapa 3-4, con `puntuacion` | L |
| L8 | Pantallas: dividir y rediseñar (`diseno-revision.md`) | Por sección, tras L2-L3 | L |

### L0 · Red de seguridad
1. `tools/code_metrics.py`: archivos > 400 (Dart) o > 300 (Java), métodos ≥ 60 líneas, ventanas duplicadas y ciclos entre features. En el CI como informe (no rompe), con un umbral que solo baja.
2. Lints más estrictos en app, admin y core: `strict-casts`, `strict-raw-types`, `strict-inference`; reglas `unawaited_futures`, `prefer_final_locals`, `avoid_dynamic_calls`, `use_super_parameters`, `prefer_const_constructors`. Se arreglan los avisos en la misma PR (cambios mecánicos).
3. ArchUnit en el servidor: sin ciclos entre paquetes, los controllers solo llaman a services, ningún paquete de producto depende de `demo`.
4. Comprobación de oro: `EventExportsGoldenTest` juega una jornada con guion fijo y datos ficticios (grupos individuales con comodín, equipos con bote; límite, tiempo, advertencias, descalificación, corrección, deshacer, cancelar y punto fuera de tiempo) y compara byte a byte todas las descargas del club con `server/src/test/resources/golden/` (`GoldenFiles`). Un cambio buscado se acepta con `-Dgolden.update=true` y se revisa el diff en la PR. La jornada al azar de `EventDaySimulationTest` no sirve: no se repite igual (punto 5 técnico de `../pendientes.md`).
5. Casos JSON compartidos de las reglas del marcador: `spec/scoring/tambo.json` (36 casos) lo pasan `TamboMatch` en Java (`TamboSharedCasesTest`) y en Dart (`tambo_shared_cases_test.dart`). Un caso nuevo de reglas se añade ahí, no en un solo lado. Fija el comportamiento antes de L7.

### L1 · Arreglos rápidos
1. A `brackety_core`: `AsyncView`, diálogos de confirmar y de motivo, ejecutar acción con aviso. App y admin los importan.
2. Textos comunes (Cancelar, Guardar, Reintentar, Cerrar…) a la ARB de `brackety_core`; fuera las claves repetidas dentro de cada ARB.
3. Migración con índices para las claves foráneas que se consultan (lista en `auditoria-codigo.md`, punto 8).
4. `eventpackage` sin depender de `demo`: lo que comparten pasa a quien lo posee.
5. `club_models.dart` en un archivo por tema (personal, categorías, ajustes, inscritos, clasificación, ficha).

### L2 · Ciclos de la app
- Nuevo `features/match/` con el modelo del combate (`Side`, `Corner`, `MatchView`, `TimelineEntry`, acciones). `scoreboard`, `mat` y `offline` lo importan; ninguno importa a otro.
- `offline` pasa a `core/offline`: la cola, la caché y la sincronización. Cada feature registra lo suyo; `core` no importa features.
- `club ↔ league`: los modelos del evento que usan los dos pasan a `events/data`.
- Test que falle si aparece un ciclo (en `tools/code_metrics.py`, modo estricto).

### L3 · Errores y navegación (cambian comportamiento visible)
1. Todo error 4xx del servidor con `code` estable (`EVENT_FINISHED`, `CATEGORY_HAS_GROUPS`…); la app y el admin traducen el código y solo usan un texto genérico si no lo conocen. Un test recorre los códigos del servidor y comprueba que la ARB los tiene.
2. Pestañas del panel del club como rutas (`StatefulShellRoute`): `/events/:id/club/standings`, `/mats`, `/participants`, `/settings`. Recargar y volver atrás mantienen la pestaña.

### L4 · Panel de control único
- La UI del panel (mover grupos y combates, reordenar, cambiar de equipo, saltar descanso) a `brackety_core` con una interfaz `ControlApi` que implementan app y admin. Ahorro: ~500 líneas y un solo sitio para los arreglos.
- Lo mismo para el patrón lista + detalle del admin (usuarios, eventos, organizadores).

### L5 · Servidor
- Subpaquetes como `auth`: `event/{phase,category,staff,mat,modality,rulebook}`, `grouping/{group,team,board,control}`, `scoreboard/{live,offline,review}`.
- Métodos de más de 40 líneas divididos (lista en la auditoría, punto 2), empezando por `EventResultsTransfer`, `MatPlanner.simulate` y `EventPackageService.load`.
- Va **junto con M3-M4**: tras `entry` y `location`, la mitad de las ramas desaparecen y dividir es más fácil. Hacerlo antes sería trabajo doble.

### L6 · Base de datos
Plan `modelo-datos-migracion.md` (M2d-M6) sin cambios, más:
- M6 añade `updated_at` a las tablas de negocio y quita los `check` de listas que crecen (`admin_audit.action`): el enum de Java ya valida. Los `check` de estados fijos se quedan.
- Decidir con Raul las reglas del backend que no se cumplen (`pendientes.md`): borrado lógico de eventos y paginación (propuesta: solo en los listados del superadmin, que crecen; las listas de un evento están acotadas).

### L7 · Motor de reglas por datos
- `SportTemplate` en JSON versionado (acciones que puntúan, límites, duración, descanso, advertencias, desempates, papeles del arbitraje) que interpretan **un** motor en Java y **uno** en Dart, probados con los casos de L0.
- Sustituye a `Discipline` y a `TamboMatch`. Tambo es la primera plantilla; las de la F2 y F3 (armas, expresión técnica) se escriben como datos, no como código.
- Es la base de `plantillas-deporte.md`. Diseño detallado en `modulos/puntuacion.md` antes de programar.

### L8 · Pantallas
Ver `diseno-revision.md`. Regla al tocar una pantalla: `build` ≤ 60 líneas, archivo ≤ 400, un widget privado por bloque con nombre de lo que muestra.

## Metas medibles
| Medida | Hoy | Meta |
|---|---|---|
| Archivos Dart > 400 / Java > 300 | 13 / 8 | 0 / 0 (salvo generados) |
| Métodos y `build` ≥ 60 líneas | 67 | < 10 |
| Features de la app en un ciclo de imports | 14 de 14 | 0 (lo vigila el CI) |
| Ramas individual/equipos en el servidor | 70 | < 10 (tras M3) |
| Panel de control escrito | 2 veces | 1 |
| Errores 4xx con `code` | 17 de ~127 | todos |
| Claves foráneas consultadas sin índice | 8 | 0 |

## Estado
Aprobado por Raul (2026-11-18); L0 en curso, en paralelo a la competición del 20-12.
