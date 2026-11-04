# Módulo · perfiles-menores

## Objetivo
Gestionar perfiles de alumnos menores, tutores y la independización a los 14 años.

## Reglas
- Menor = menos de 14 años (consentimiento del tutor). Entre 14 y 17: puede tener cuenta propia, con tutor vinculado como Externo.
- Crea el perfil: (a) tutor Externo con **declaración responsable** (casilla con fecha), o (b) club con aceptación del tutor por invitación (email o app). Mientras no acepte: estado `pendiente`, no puede inscribirse ni competir.
- Inscripción de un menor **sin cuenta** por organizador: casilla obligatoria "el tutor está de acuerdo"; no se crea cuenta.
- Independización a los 14: el alumno vincula su perfil a una cuenta propia (email/Google/Apple). El tutor queda vinculado como Externo: ve resultados, puede solicitar borrado, no edita datos.
- Foto opcional, nunca pública. Peso/estatura según evento.
- Sin datos de salud.
- Cumpleaños: al cumplir 14 se ofrece la independización; no es automática.
- Tutor vinculado a varios menores y menor con varios tutores permitidos.

## Datos
`student_profile` (nombre, apellidos, nacimiento, estatura, género, foto opcional, estado), `guardian_link` (tutor, alumno, fecha declaración, texto versionado).

## API (borrador)
`POST /students` (tutor), `POST /clubs/{id}/students` (invitación), `POST /students/{id}/accept`, `POST /students/{id}/emancipate`, `GET /me/children`.

## Pantallas
Alta de menor, bandeja de invitaciones de tutor, ajustes del menor, flujo de independización.

## Tests
Estados del perfil, bloqueo de inscripción pendiente, independización, permisos del tutor tras los 14, anonimizado al borrar.

## Estado
Pendiente.
