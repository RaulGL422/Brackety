# Módulo · auth

## Objetivo
Cuentas, login y sesión compartidos entre web y Android.

## Reglas
- Métodos: Google, Apple, email + contraseña (respaldo). Una cuenta puede vincular varios métodos desde ajustes.
- Verificación de tokens de Google/Apple en servidor. Email: verificación con enlace (Resend).
- JWT de acceso 15 min + refresh rotatorio con detección de reutilización.
- Registro: elegir perfil inicial (Club, Entidad Externa, Ayudante, Externo, Alumno). Perfiles adicionales desde ajustes (combinaciones en `roles/README.md`).
- Aceptación de términos y privacidad con fecha y versión.
- Recuperación de contraseña por email. Límite de intentos y bloqueo temporal.
- Superadmin: usuario único por entorno, endpoint separado, solo tras Cloudflare Access.
- Borrado de cuenta y exportación de datos (`06-legal-rgpd.md`).

## Datos
`account`, `identity` (proveedor, id externo), `profile` (tipo, datos), `refresh_token`, `consent`.

## API (borrador)
`POST /auth/register`, `/auth/login`, `/auth/google`, `/auth/apple`, `/auth/refresh`, `/auth/logout`, `/auth/password/reset`, `/me`, `/me/profiles`, `/me/identities`, `DELETE /me`, `GET /me/export`.

## Pantallas
Inicio de sesión, registro con selector de perfil, ajustes de cuenta (identidades, perfiles, idioma, exportar/borrar).

## Tests
Login por cada método, refresh/reutilización, límites de tasa, vinculación de identidades, borrado y anonimizado.

## Estado
Pendiente.
