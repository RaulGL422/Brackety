# Ampliación: gestión del club (investigación)

Idea de Raul (2026-11-16): ampliar Brackety a clases, alumnado, inscripciones, pagos, facturas y redes sociales. Investigación de producto; **nada decidido**.

## Oportunidad
- El club ya usa Brackety en competición; su día a día (alumnos, grados, cuotas, asistencia) suele vivir en Excel y WhatsApp.
- Unirlo da algo que la competición sola no da: inscribir a un evento con un toque desde la ficha, historial de grados y resultados en un sitio, y menos datos repetidos.
- Riesgo: es otro producto, con más soporte y obligaciones legales y fiscales.

## Competencia (2026-11)
| Producto | Enfoque | Lo relevante |
|---|---|---|
| Smoothcomp | Torneos de artes marciales (BJJ) | Inscripción, pesaje, cuadros y resultados; muy usado en BJJ |
| Kicksite, Zen Planner, Gymdesk, Mindbody | Escuelas de artes marciales | Clases, asistencia, cinturones y cobro automático; en inglés y pensados para EE. UU. |
| Clupik, Playoff Informática, SportMember | Clubes deportivos en España | Socios, cuotas, comunicación; sin competición de artes marciales |
| Spond | Equipos y clubes (Europa) | Gratis, cobra comisión por cada pago |
- Hueco (hipótesis): nadie junta **gestión de un club pequeño de artes marciales + competición de liga o federación en español + funcionamiento sin red en el pabellón**.

## Módulos candidatos (de menos a más riesgo)
1. **Alumnos y familias**: ficha, tutores, grados o cinturones con historial, documentos y consentimientos (imagen incluida). Base de todo; reutiliza `perfiles-menores` e `importacion-alumnos`.
2. **Clases y asistencia**: horarios, grupos y pase de lista en el móvil (sin red, como el marcador). Avisos de ausencias repetidas.
3. **Inscripciones**: a temporada, clases o cursillos, con formulario, plazas y lista de espera. Reutiliza `inscripciones`.
4. **Cuotas (control)**: cuotas por alumno, pagado o no pagado, recordatorios y resumen de impagos. Encaja con el principio actual (la app no toca dinero).
5. **Cobro online**: el dinero va **directo a la cuenta del club** por un proveedor (Stripe, GoCardless o Mollie: domiciliación SEPA, tarjeta y Bizum según proveedor). Brackety nunca guarda fondos; si los guardara, sería una entidad de pago (PSD2).
6. **Facturas**: el software que emite facturas en España debe cumplir el reglamento VeriFactu (RD 1007/2023): obligatorio desde el 1-1-2027 para sociedades y el 1-7-2027 para el resto (RDL 15/2025; se habla de otro aplazamiento a 2028 sin norma publicada). Quien fabrica el software firma una declaración responsable. Muchos clubes son asociaciones con exenciones de IVA: lo que les toca lo confirma un asesor fiscal.
7. **Comunicación y redes**: primero avisos dentro de la app (push y email). En redes: generar imágenes de resultados y podios para compartir desde el móvil (no necesita API). Publicar directo en Instagram exige cuenta Business o Creator, revisión de la app y verificación del negocio por Meta, permisos de publicación y límites diarios.

## Implicaciones
- Cambia la visión (`00-vision.md`: "Fuera de alcance: cobros"). El principio "la app no cobra ni gestiona dinero" puede mantenerse si el dinero va siempre del alumno al club.
- Raul es persona física sin entidad: cobrar a clubes por el servicio, emitir facturas o pasar la verificación de negocio de Meta pide probablemente forma jurídica, contratos de encargado del tratamiento con cada club y asesoría.
- Menores: fotos nunca públicas (regla actual). Las imágenes para redes, sin fotos y con nombres solo con consentimiento.
- Soporte: un club que factura y cobra con Brackety lo necesita todos los días, no solo en competición.

## Recomendación
1. No empezar hasta cerrar las etapas 1-4 de `roadmap.md`.
2. **Descubrimiento** (2-3 semanas): entrevistas al club Yoseikan y a 2-3 clubes más: qué usan hoy, qué les duele y cuánto pagarían.
3. Si se confirma: MVP con **1 Alumnos + 2 Asistencia + 4 Cuotas (control)**. Mucho valor, poco riesgo legal y sin tocar dinero.
4. Cobro online y facturas solo con entidad jurídica, asesor fiscal y un proveedor ya certificado (integrar, no fabricar el VeriFactu).
5. Redes: empezar por compartir imágenes; la API de Meta solo si hay demanda.

## Fuentes (consultadas el 2026-11-16)
- VeriFactu: [Infoautónomos](https://www.infoautonomos.com/blog/verifactu-cuando-es-obligatorio-a-quien-afecta/), [Grant Thornton](https://www.grantthornton.es/en/insights/tax/verifactu-postpones-its-entry-into-force-to-2027/), [posible aplazamiento a 2028](https://asesores-consultores.com/nuevo-aplazamiento-de-verifactu-con-la-vista-puesta-en-2028/).
- Instagram: [Meta, publicación de contenido](https://developers.facebook.com/docs/instagram-platform/content-publishing/), [límite de publicación](https://developers.facebook.com/docs/instagram-platform/instagram-graph-api/reference/ig-user/content_publishing_limit).
- Pagos: [Stripe vs GoCardless](https://www.heropay.eu/en/blog/gocardless-stripe), [pasarelas para SaaS](https://hackceleration.com/es/labs/mejor/pasarela-de-pago-saas). Tarifas a confirmar con cada proveedor.
- Competencia: [Capterra, artes marciales](https://www.capterra.es/directory/30779/martial-arts/deployment-options/windows/software), [gestión de socios](https://hackceleration.com/es/labs/mejor/gestion-socios-clubes), [Smoothcomp](https://support.smoothcomp.com/article/71-how-to-create-and-work-with-brackets).
