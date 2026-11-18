# Documentación de Brackety

Mapa de qué vive dónde. Un hecho está en un solo documento; los demás lo enlazan (`.claude/rules/docs-upkeep.md`).

## Qué leer
| Para… | Lee |
|---|---|
| Saber qué está hecho y qué toca | `estado.md` |
| Saber qué espera a alguien (preguntas, pruebas a mano, tareas) | `pendientes.md` |
| Trabajar en un módulo | `estado.md` → `modulos/<modulo>.md` → los `roles/` que nombre |
| Entender por qué algo es así | `decisiones.md` (noviembre) y `decisiones-2026-10.md` |
| El plan de las próximas semanas | `producto/roadmap.md` |
| Una palabra del proyecto (tapiz, comodín, fase…) | `glosario.md` |

## Carpetas
| Carpeta | Qué hay |
|---|---|
| raíz `00`-`10` | Fundamentos: visión, arquitectura, stack, git, tests, seguridad, RGPD, diseño, ejecución local, despliegue, entorno |
| `modulos/` | Un documento por módulo, siempre con las mismas secciones: Objetivo, Reglas, Datos, API, Pantallas, Offline, Tests, Estado |
| `producto/` | Planes y propuestas que cruzan módulos: hoja de ruta, calidad, auditoría y limpieza, modelo de datos, diseño, eventos, exportaciones, plantillas, gestión del club |
| `roles/` | Qué puede hacer cada tipo de usuario |
| `reglamentos/` | Reglamentos reales de los deportes (Yoseikan 2027) |
| `historico/` | Lo ya cerrado que se guarda como referencia (pruebas y revisión de la F1). No hace falta leerlo para trabajar |

## Reglas de escritura
- Español, frases cortas, listas. Sin relleno ni historia: la historia está en git y en las PR.
- `estado.md`: una línea por cosa, con su estado y su doc; el detalle, en el doc.
- `pendientes.md`: solo lo que espera a alguien; lo hecho se borra.
- Límites: 150 líneas y 12.000 caracteres por documento. Si crece, se divide o lo cerrado pasa a `historico/`.
