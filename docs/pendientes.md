# Pendientes

## Entorno de desarrollo (Raul)
- [ ] Android: instalar *cmdline-tools* (SDK Manager de Android Studio) y aceptar licencias con `flutter doctor --android-licenses`.
- [ ] Autorizar la depuración USB en el móvil conectado (aparece como "not authorized").
- [ ] Docker Desktop: solo hará falta para probar `deploy/` en Windows; tests y ejecución local no lo necesitan.

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

## Producto
- [ ] Grupo con sobrante: opciones (promedio por combate / puntos brutos / decidir caso a caso) y respuesta final del organizador; será opción del evento.
- [ ] Modelo exacto de equipos en torneos por equipos (plantilla, suplentes, entrenadores).
- [ ] Plantillas de deporte adicionales (judo, karate, taekwondo, fútbol…): investigar al llegar a `puntuacion`.
- [ ] Doble eliminación y repesca (judo, taekwondo, karate): investigar al llegar a `torneo`.
- [ ] Registro de tratamientos y plantilla de registro de brechas.

## Hecho
- 2026-10-28 · Graphify configurado a partir de ClipHive (`CLAUDE.md`, `.gitignore`).
