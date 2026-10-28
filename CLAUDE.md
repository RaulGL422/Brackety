# Brackety

Plataforma multideporte de ligas, ligas por fases y torneos (primer cliente: Liga Yoseikan Budo Andalucía 2027). Monorepo: `server/` (Spring Boot), `app/` (Flutter: Android + web pública), `admin/` (Flutter web superadmin), `deploy/` (Docker), `docs/`.

## Cómo trabajar (obligatorio)
1. Lee `docs/estado.md` primero. Después SOLO el MD del módulo en el que trabajas (`docs/modulos/<modulo>.md`) y los roles implicados (`docs/roles/`). No cargues el resto de `docs/` salvo que el módulo lo enlace.
2. Si falta una decisión, no la inventes: añádela a `docs/pendientes.md` y pregunta a Raul.
3. Rama nueva desde `development` por tarea (`docs/03-git-workflow.md`). Nunca commits directos a `development` ni `main`.
4. Al terminar una tarea: tests verdes, skill `close-task`, actualizar `docs/estado.md`.
5. Reglas por tecnología en `.claude/rules/` (se aplican según la carpeta que toques).

## Principios de código
- Simple y legible, como lo escribiría un desarrollador humano. Sin abstracciones "por si acaso".
- Sin comentarios salvo el porqué no obvio. Sin código duplicado: busca antes de crear.
- Un módulo = una carpeta por feature, nunca por capa técnica global.
- Ahorra tokens: lee archivos por rango, no repitas contenido de docs en respuestas, no generes archivos que nadie pidió.
- Idiomas: código, commits y nombres en inglés; docs y textos de UI en español (i18n ES/EN desde el inicio, nunca strings fijos en widgets).

## Datos y legal (nunca saltarse)
- Pagos NO pasan por la app: solo marca pagado/no pagado.
- Fotos nunca públicas. Menores: ver `docs/06-legal-rgpd.md`.
- Sin `PRIVACY_CONTACT_EMAIL` definido, la API rechaza publicar eventos y pasar de fase.
- Secretos solo en variables de entorno; `.env.example` siempre actualizado.

## Graphify
Pendiente de configurar: Raul pasará los archivos de ClipHive antes de la primera fase. Ver `docs/pendientes.md`. Hasta entonces, no inventes comandos de Graphify.

## Entorno
Claude Code corre en el PC de Raul (Windows/Linux). La Raspberry (SD, sin backups aún) solo despliega con `deploy/deploy.sh`.
