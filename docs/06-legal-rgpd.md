# 06 · Legal y protección de datos (RGPD / LOPDGDD, España)

> Documento de trabajo, no asesoría jurídica. Claude redacta; antes de abrir al público conviene revisión profesional (`pendientes.md`).

## Responsable
Raul (persona física). Contacto de privacidad: `PRIVACY_CONTACT_EMAIL` (pendiente). Sin él, no se puede publicar ni avanzar de fase.
Encargados de tratamiento: Cloudflare (red/acceso), Resend (email), Firebase/Google (push, login), Apple (login).

## Minimización
Datos del alumno: nombre, apellidos, fecha de nacimiento, estatura (aprox.), género, foto (opcional), peso (según configuración del evento). Sin datos de salud ni lesiones. Sin cobros ni datos de pago.

## Menores
- Menor de 14: el perfil lo crea un tutor (cuenta Externo) con declaración responsable, o un club con aceptación del tutor por invitación. Hasta aceptar, perfil "pendiente" y no puede competir.
- Inscripción de un menor sin cuenta: casilla "el tutor está de acuerdo" obligatoria.
- A los 14 el alumno puede independizar su perfil a su propia cuenta; el tutor queda como Externo vinculado (solo lectura de resultados; puede pedir borrado).
- Fotos: nunca públicas. Solo las ve un ayudante con permiso de marcador, dentro de su evento y su tapiz.

## Derechos y ciclo de vida
- Exportar y borrar cuenta desde ajustes. Al borrar, resultados pasados quedan anonimizados en rankings y eventos.
- Superadmin puede borrar por petición RGPD con registro de auditoría. Borrado lógico y definitivo a los 30 días.
- Registro de tratamientos y política de retención (por definir con el reglamento de la liga).

## Brechas
Detectar → contener → evaluar riesgo → avisar a la AEPD en 72 h si hay riesgo → avisar a afectados si el riesgo es alto → registrar. Plantilla de registro en `docs/pendientes.md` hasta crearla.

## Páginas públicas (módulo `legal-paginas`)
Política de privacidad, términos de uso, cookies (solo técnicas; sin analítica sin consentimiento), aviso legal, canal de contacto/reportes. ES y EN. Cláusula expresa: la app no gestiona pagos.

## Reglas de código derivadas
Sin datos personales en logs; consentimientos con fecha y versión del texto; borrado/anonimizado probado en tests.
