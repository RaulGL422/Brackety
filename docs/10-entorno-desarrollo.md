# 10 · Entorno de desarrollo

Guía para Claude sobre la máquina donde se trabaja. No son datos sensibles; es contexto de trabajo.

## Máquina
- Claude Code corre en el PC de Raul (Windows 11; a veces Linux). Shell principal PowerShell; Bash (Git Bash) disponible.
- La Raspberry Pi solo despliega con `deploy/deploy.sh`; nunca se desarrolla en ella.
- Sin Docker en el PC: tests y ejecución local usan Postgres embebido; el compose se prueba en CI.

## Herramientas
- Flutter en `C:\dev\flutter` (canal stable). Gradle de Android con JDK 21 (`flutter config --jdk-dir`).
- JDK 25 para el servidor en `~/.jdks/ms-25.*` (lo detecta `run-server.ps1`).
- Android SDK en `%LOCALAPPDATA%\Android\Sdk`.
- IDEs: IntelliJ para el servidor; Android Studio para `app/` y `admin/` (cada uno abierto como proyecto propio). Detalle en `08-ejecucion-local.md`.

## Git
- Hooks del repo activos en este clon (`git config core.hooksPath .githooks`): Graphify se actualiza solo tras cada commit.

## Avisos conocidos
- En Windows, texto con tildes por Bash heredoc se corrompe: usar Write/Edit.
- Portátil (Intel Wi-Fi AX200, sin red hospedada): el PATH de sistema tiene una entrada entre comillas (`"C:\WINDOWS;…;jdk-22\bin"`) y desde Git Bash `flutter` falla con "pwsh.exe no se reconoce". Lanzar Flutter desde PowerShell. Java por defecto es el 22: para `./mvnw`, `JAVA_HOME=~/.jdks/openjdk-25`. Hay un Flutter 3.29 antiguo en `Documents\flutter`; manda `C:\dev\flutter` (primero en el PATH de usuario).
- Graphify se instala con `python -m pip install graphifyy` y se usa como `python -m graphify`.
- El antivirus (Surfshark) pone en cuarentena ejecutables de desarrollo (`dart.exe`, `git.exe`, `java.exe`…) como `Drop.Win64.RoamingSelfRun`. Si desaparece un `.exe`, mirar su cuarentena; las carpetas de herramientas y del repo deben estar excluidas.
