# Módulo · torneo

## Objetivo
Cuadros de eliminación sin fase de grupos.

## Reglas
- Eliminación simple, doble eliminación y repesca clásica (judo/taekwondo/karate): **investigar formatos y tamaños de cuadro al empezar el módulo** y dejarlas como plantillas.
- Siembra: aleatoria con semilla guardada (por defecto); manual por organizador; por ranking (opcional).
- Rondas con byes cuando el número no es potencia de 2; avance automático del ganador.
- Combate por 3.er puesto configurable en el evento.
- **Amistosos** entre inscritos: no influyen en el torneo ni en rankings.
- Marcador y tiempo comparten pantalla con `marcador-tapiz.md`.
- Equipos: un enfrentamiento puede ser entre equipos con titulares y suplentes (modelo por cerrar).

## Datos
`bracket`, `bracket_slot`, `match` (ronda, posición), `friendly_match`.

## Pantallas
Cuadro en directo, editor de siembra, historial de amistosos.

## Tests
Cuadros de 2 a 64, byes, doble eliminación, repesca, semilla reproducible, reasignación si un participante se retira.

## Estado
Pendiente. Investigar formatos al llegar.
