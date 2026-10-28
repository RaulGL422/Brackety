# 02 · Stack y versiones

Verificado el 2026-10-28 en fuentes oficiales o documentación vigente.

| Tecnología | Versión | Estado |
|---|---|---|
| Java | 25 (LTS) | Verificada; compatible con Spring Boot 4 |
| Spring Boot | 4.1.0 (o última 4.1.x) | Verificada como estable; exige Java 17+ y Maven 3.6.3+ |
| Maven | 3.9.x | Spring Boot pide ≥ 3.6.3; fijar versión al crear el wrapper |
| PostgreSQL | 18.x (última menor) | PG 19 solo vista en beta; no usar hasta GA estable |
| Flutter | 3.47.1 (Dart 3.13.1) | Verificada (agosto 2026) |
| Docker / Compose | última estable | Fijar al montar `deploy/` |
| Kotlin Multiplatform web | descartado | Compose para web (Wasm) sigue en beta |

## Reglas de versionado
- Antes de añadir una dependencia, comprobar su última versión estable y compatibilidad con Spring Boot 4.1 / Flutter 3.47 en su documentación oficial. No fiarse de memoria.
- Fijar versiones exactas en `pom.xml` y `pubspec.yaml`; actualizar en ramas `chore/` propias.
- Cada dependencia nueva se anota en `decisiones.md` con el motivo.

## Librerías previstas (versiones por fijar al crear los proyectos)
- Backend: spring-boot-starter-web, -data-jpa, -security, -validation, -websocket, -actuator, springdoc-openapi, Flyway, Testcontainers, cliente HTTP para Resend y FCM.
- Front: flutter_riverpod, go_router, dio, drift, intl, flutter_localizations, firebase_messaging, google_sign_in, sign_in_with_apple, mobile_scanner (QR), qr_flutter, pdf viewer para reglamentos.
- Sin generación de código obligatoria al inicio; evaluar OpenAPI → cliente Dart al cerrar el módulo auth.

## Plataformas objetivo
Android (Google Play, ver `pendientes.md`: 12 testers × 14 días), web moderna (Chrome, Edge, Safari/iOS como PWA), servidor Linux Debian/arm64 y Windows (Docker).
