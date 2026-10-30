# Pendientes

## Entorno de desarrollo (Raul)
- [ ] Autorizar la depuración USB en el móvil conectado (aparece como "not authorized").
- [ ] Docker Desktop: solo hará falta para probar `deploy/` en Windows; tests y ejecución local no lo necesitan.

## Despliegue (infra-deploy)
- [ ] Variable de repositorio `API_BASE_URL` en GitHub (Settings → Variables) cuando haya dominio; sin ella fallan las imágenes web/admin al publicar.
- [ ] Paquetes GHCR: hacerlos públicos o `docker login ghcr.io` en la Pi con un token de solo lectura (decidir).
- [ ] Copia de los backups en la nube (doc 05): elegir proveedor barato; se añadiría con `rclone` al final de `backup.sh`.
- [ ] Generar la clave age de backups y guardar la privada fuera de la Pi (`09-despliegue.md`).
- [ ] Backup en Windows si llega a ser el servidor (hoy `backup.sh` es solo Linux).
- [ ] Cabecera Content-Security-Policy en nginx: probarla contra el despliegue real antes de activarla.

## Repositorio público
- [ ] `docs/` es planificación temporal y se eliminará en el futuro. Antes de hacerlo: pasar a `CLAUDE.md` (o un README) lo imprescindible que hoy solo vive en `docs/` y quitar sus enlaces.

## Bloquean el lanzamiento público
- [ ] Firma release de Android (keystore propio en secretos de CI); ahora `app/android/app/build.gradle.kts` firma release con la clave debug de la plantilla.
- [ ] Email de privacidad (`PRIVACY_CONTACT_EMAIL`, p. ej. `privacidad@rgal.dev`). Sin él, la API no deja publicar ni pasar de fase.
- [ ] SSD USB/NVMe para la base de datos (la SD no es fiable).
- [ ] Backups cifrados + prueba de restauración.
- [ ] Revisión legal profesional de privacidad, términos y cookies.
- [ ] Google Play: 12 testers × 14 días en pruebas cerradas (Raul tiene las personas).
- [ ] Marca: comprobar "Brackety" en OEPM y dominio `brackety.rgal.dev` (existe una app llamada Brackify, parecida).

## Reglamento Yoseikan (ver `reglamentos/yoseikan-2027.md`)
- [ ] Tiempo de ronda de lucha en suelo (Raul consultando).
- [ ] Escala de puntuación de cada prueba de Expresión Técnica (kata, derribos al muñeco, saco, arco).
- [ ] Puntos de asistencia por fase: 10 por ahora, candidato a cambio.
- [ ] Reglas de amonestación del tambo por categoría: fijarlas por modalidad/fase/categoría.
- [ ] Recopilar el reglamento completo en PDF para consulta cerca del marcador.
- [ ] Confirmar orden de fases: deducido del Registro general (F1 suelo, F2 armas, F3 expresión técnica, F4 derribos).

## Diseño (sistema de diseño)
- [ ] Validar en la página Sistema de diseño del admin: elegir paleta (Eléctrico/Fuego/Noche), revisar tipografía Barlow y componentes en claro/oscuro y móvil.

## Producto
- [ ] Grupo con sobrante: opciones (promedio por combate / puntos brutos / decidir caso a caso) y respuesta final del organizador; será opción del evento.
- [ ] Modelo exacto de equipos en torneos por equipos (plantilla, suplentes, entrenadores).
- [ ] Plantillas de deporte adicionales (judo, karate, taekwondo, fútbol…): investigar al llegar a `puntuacion`.
- [ ] Doble eliminación y repesca (judo, taekwondo, karate): investigar al llegar a `torneo`.
- [ ] Registro de tratamientos y plantilla de registro de brechas.

## Hecho
- 2026-10-28 · Android cmdline-tools instaladas; `flutter doctor` sin errores para Android y web.
- 2026-10-28 · Graphify configurado a partir de ClipHive (`CLAUDE.md`, `.gitignore`).
