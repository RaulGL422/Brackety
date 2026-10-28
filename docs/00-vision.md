# 00 · Visión

## Qué es
Brackety organiza competiciones deportivas: inscribe participantes, crea grupos y cuadros, lleva el marcador en directo, calcula puntuaciones y mantiene rankings. Primer cliente: **Liga Yoseikan Budo Andalucía 2027** (artes marciales, 4 fases, categorías por edad). Diseñada para servir a cualquier deporte, liga o torneo.

## Alcance MVP
- Cuentas con login Google, Apple y email/contraseña; perfiles múltiples.
- Roles: Entidad Externa, Club, Ayudante, Alumno, Externo.
- Eventos: Liga, Liga en fases, Torneo, con inscripción por QR, manual o invitación.
- Ayudantes con roles de evento, ubicaciones (p. ej. tapiz) y permisos.
- Marcador/tiempo/amonestaciones por modalidad, con modo offline.
- Puntuación configurable por plantilla de deporte; rankings por entidad, temporada y categoría, y global.
- Superadmin (solo Raul): métricas, usuarios, eventos, reportes.
- Español e inglés. España. Android + web pública. Sin iOS nativo (la web/PWA cubre iOS).

## Fuera de alcance (de momento)
Cobros (la app solo marca pagado/no pagado), iOS nativo, vídeo en directo (idea futura: enlazar directos a ubicaciones), otros países.

## Principios
1. La app no cobra ni gestiona dinero.
2. Datos mínimos; menores protegidos por diseño.
3. Funciona sin internet donde hay competición (tapiz).
4. Un único desarrollador humano decide; Claude programa.
5. Todo configurable por evento antes que fijado en código, salvo reglamento oficial por modalidad/fase/categoría.

## Contexto de uso
Raul es persona física, sin entidad jurídica, servicio gratuito. Hosting propio en Raspberry Pi 5 (16 GB) con Cloudflare Tunnel; carga objetivo inicial: 20 usuarios simultáneos.

Siguiente: `01-arquitectura.md`.
