# Roles

Una cuenta puede tener varios perfiles activables. Combinaciones permitidas:
- **Alumno + Ayudante**
- **Externo + Ayudante**
- **Club** y **Entidad Externa** son cuentas organizadoras y **no pueden tener perfil Ayudante**. Su personal entra como cuentas Ayudante propias.
- **Externo no puede ser Alumno.** Un Externo se vincula a Alumnos (hijos u otros) y ve lo que el evento permite.
- Un tutor es una cuenta Externo que crea y gestiona perfiles Alumno de menores (ver `06-legal-rgpd.md`). El perfil del menor es suyo, no del tutor.

Registro: al crear la cuenta se elige perfil inicial (Club, Entidad Externa, Ayudante, Externo, Alumno). Se pueden activar más desde ajustes. Se pueden vincular varias identidades (email, Google, Apple) a la misma cuenta.

| Rol | Resumen | Archivo |
|---|---|---|
| Entidad Externa | Crea y administra eventos; sin clubes ni alumnos propios | `entidad-externa.md` |
| Club | Todo lo de Entidad + alumnos/ayudantes por defecto y participar en eventos ajenos | `club.md` |
| Ayudante | Staff de evento con roles, ubicaciones y permisos | `ayudante.md` |
| Alumno | Participante | `alumno.md` |
| Externo | Espectador o tutor vinculado a alumnos; también entrenador | `externo.md` |

Entrenadores y suplentes no son un rol de cuenta: son **función dentro de un equipo** (titular, suplente, entrenador). El entrenador es un perfil Externo (y puede ser también Ayudante o Alumno si compite).
