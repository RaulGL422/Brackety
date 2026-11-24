# Estado del proyecto

Última actualización: 2026-11-22. Única fuente de "qué está hecho". El detalle de cada cosa vive en su doc; aquí solo el estado.

- **Momento**: Fase 1 de la liga jugada el 2026-11-14 con éxito. Pausa para organizarse y limpiar (`producto/roadmap.md`).
- **Próximos hitos**: competición el 2026-12-20 y Fase 2 el 2027-01-24.
- **Producción**: v0.7.0 en la Pi (`brackety.rgal.dev`). Todo lo de abajo está fusionado en `development` salvo que diga otra cosa.

Estados: **pendiente** · **en curso** · **en pruebas** (hecho; falta la prueba a mano de Raul, lista en `pendientes.md`) · **cerrado**.

## Ahora
- Calidad (`producto/plan-limpieza.md`): L0 completa (2026-11-20): métricas en el CI (#137), ArchUnit (#138), lints estrictos (#139), casos de reglas compartidos (#142) y comprobación de oro (#143, #149). Destapó el orden de nombres con acento en Linux (#144). Siguiente: L1.
- Grappling FELODA (`producto/grappling.md`): G1-G5 fusionadas (#151, #153-#159); release v0.8.0 (#160).
- Acceso por QR para ayudantes y árbitros sin cuenta (`modulos/ayudantes-permisos.md`): fusionado (#162), release v0.8.1.
- Tras el grappling del 2026-11-21: superioridad en Ajustes (#165). Arreglos GR-1 a GR-12 para el 20-12 (`producto/feedback-grappling.md`): GR-3 (#169), GR-11 (#170), GR-10 (#171) y GR-2 (#172, #173) hechos; GR-5 (#174, #175), GR-4 (grupos por tapiz), GR-1 (marcador del árbitro), GR-8 sesiones (#179) y matriz de permisos; resto pendiente. L1 espera.
- Exportaciones a medida (`producto/exportaciones.md`): aprobadas en lo básico, por programar.
- Esperando a Raul: detalles de la competición del 20-12, puntuación de la F2 y las preguntas de `pendientes.md`.

## Módulos
| Módulo | Estado | Nota |
|---|---|---|
| `infra-deploy` | cerrado (2026-10-30) | |
| `entornos` | en curso | Producción y debug en la Pi; falta pasar los datos de la F1 a producción |
| `auth` | en pruebas | Tareas 1-9 de 9 |
| `perfiles-menores` | pendiente | |
| `legal-paginas` | en pruebas | Pasos 1-2; falta la puerta legal al publicar y pasar de fase |
| `eventos` | pendiente | Adelantado: comenzar, finalizar y reabrir la fase (#129); rediseño en `producto/eventos-ux.md` |
| `inscripciones` | pendiente | Adelantado por el prototipo y la importación |
| `ayudantes-permisos` | pendiente | Adelantado: invitaciones (#122) y permisos por persona (#130, #131, #133) |
| `puntuacion` | pendiente | Tambo y grappling como plantillas de datos (paso 1); plan en `producto/plantillas-deporte.md` |
| `liga` | pendiente | |
| `liga-fases` | en pruebas | Fases, reinscripción, puntos por asistir, podios |
| `torneo` | pendiente | Lo pide la competición del 20-12 |
| `marcador-tapiz` | pendiente | Adelantado por el prototipo |
| `tiempo-real` | en pruebas | Avisos por WebSocket con sondeo de respaldo |
| `offline` | pendiente | Adelanto de la F1 (marcador, web del pabellón) en pruebas |
| `ranking` | pendiente | Adelantado: global opcional (#123), CSV y PDF por categoría, nombres de archivo (#132) |
| `notificaciones` | pendiente | Propuesta de correos a Raul |
| `superadmin-reportes` | en curso | Operaciones de evento, métricas y usuarios; faltan reportes |

## Fuera de los módulos
| Qué | Doc | Estado |
|---|---|---|
| Sistema de diseño (tokens, página Diseño) | `07-diseno.md` | cerrado (2026-10-30) |
| Diseño neutro multideporte | `07-diseno.md` | en pruebas: pantallas de la F1; el resto, en `producto/diseno-revision.md` |
| Prototipo F1 (grupos, tablero, marcador, panel del club) | `modulos/prototipo-f1.md` | en pruebas; usado en la F1 |
| Prototipo F1: equipos y comodines | `modulos/prototipo-f1-equipos.md` | en pruebas |
| Importación masiva de alumnos | `modulos/importacion-alumnos.md` | en pruebas; falta el DPA |
| Servidor del pabellón y paquete del evento | `modulos/servidor-local.md` | en curso: pasos 1-3 de 4; falta el ensayo con varios dispositivos |
| Arreglos tras la F1 (F1-1 a F1-7, F2-1, F2-2, F2-4) | `producto/feedback-f1.md` | en pruebas; F2-3 pasa a exportaciones |
| Modelo de datos | `producto/modelo-datos.md` | M1 y M2a-c hechos; falta M2d; M3-M6 en la etapa 3 |
| CI por componentes | `producto/calidad.md` | cerrado (#124) |
| Auditoría y plan de limpieza | `producto/auditoria-codigo.md` | L0 en curso |
| Servidor: banner y estado al arrancar | `09-despliegue.md` | en pruebas (#128) |
| Fuera `maxGroupsPerMat` | `producto/calidad.md` | cerrado (#134) |
| Plugins `playwright` y `frontend-design` | `08-ejecucion-local.md` | cerrado (#54) |
| Plantillas de deporte y arbitraje | `producto/plantillas-deporte.md` | paso 1 hecho (deportes como plantillas en BD); sin editor; preguntas en `pendientes.md` |
| Grappling FELODA (G1-G5) | `producto/grappling.md` | G1-G4 fusionadas (#151, #153-#158); G5 hecha |
