# Módulo · superadmin-reportes

## Objetivo
Panel exclusivo de Raul (web `admin`) y sistema de reportes de usuarios.

## Acceso
Usuario único definido por variables de entorno + Cloudflare Access. Sin otro registro. Auditoría de cada acción.

## Funciones
- Métricas: usuarios, eventos, actividad, errores.
- Usuarios: listar, buscar, bloquear/desbloquear, borrado RGPD con auditoría.
- Entidades y clubes: **verificar** (insignia) para evitar suplantación.
- Eventos: listar, bloquear, modificar, borrar (borrado lógico y definitivo a los 30 días), con motivo y auditoría.
- Rankings: recálculo.
- **Reportes**: listado con quién lo envió, tipo, estado y notas.

## Reportes
- Se puede reportar: usuario, evento, contenido, error técnico.
- Campos: tipo, motivo, descripción, autor, objeto reportado, estado (abierto / en revisión / cerrado).
- Al crear un reporte llega un email a Raul (Resend) y aparece en el panel.
- El autor ve el estado de su reporte.

## Datos
`report`, `admin_audit`, `verification`.

## Tests
Acceso solo con Access y credenciales, auditoría, bloqueo de usuario/evento, flujo de reportes, borrado diferido.

## Estado
Pendiente.
