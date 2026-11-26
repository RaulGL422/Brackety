# Cambios

Lo que trae cada versión, para saber qué probar. Cada PR añade su línea en «Sin publicar»; en la release,
esa sección pasa a llamarse como la versión. Debug enseña su compilación junto a la versión
(«Versión 0.8.2-dev.87 (8c525af)»): el número sube con cada fusión en `development`.

## Sin publicar (en debug)

### Nuevo
- El menú de la cuenta dice quién está dentro y separa «Mi cuenta» (email, acceso, perfiles, tus datos, textos legales) de «Ajustes de la app» (idioma, apariencia, licencias y versión). «Automático» pasa a llamarse «Sistema».
- Mis eventos rediseñado: «En curso», «Próximos» y «Finalizados»; fases de la liga en una fila deslizable que abre cada una; un botón según lo que haces en el evento (o «Entrar al evento» si haces varias cosas); «Nuevo evento» solo para clubes y entidades.
- Los rechazos del servidor (fecha bloqueada, categoría en uso, reglamento que no es PDF…) dicen el motivo concreto en tu idioma, en vez de «No se pudo guardar» (#207).
- La pestaña del panel del club va en la dirección (`…/club/mats`): recargar la web o volver de otra pantalla abre la misma pestaña (#207).
- Registro, «Revisa tu email», contraseña olvidada, nueva contraseña, enlace caducado y entrar con QR rediseñados: tipo de cuenta en desplegable, requisitos de contraseña que se marcan al escribir, aviso de cuántas cosas faltan y textos más claros.
- Textos legales rediseñados: resumen al principio, índice «En esta página», letra más grande, tablas legibles en el móvil y la versión como fecha. «Han cambiado los textos» marca lo que ya has leído y nombra los textos que aceptas.
- Pantalla de entrada (y las demás sin sesión) rediseñada: sin barra, título y textos más claros, pie legal ordenado y la versión aparte; mejoras de accesibilidad (#204).
- Cuentas de soporte: el superadmin las activa en la ficha del usuario; solo ellas (y debug) ven Conexión, ahora al final de Ajustes (#203).
- Debug: pantalla «Cambios» con esta lista y un buscador por palabras (app: menú de la cuenta; admin: pestaña) (#201).
- Si cambian los términos o la privacidad, quien los aceptó debe aceptarlos de nuevo al entrar (#199).
- Al salir una versión nueva, la web y el admin avisan y obligan a actualizar (esperan si hay acciones sin enviar) (#200).
- Exportar a medida: elegir datos, columnas, orden, filtros, «Separar por», CSV, Excel o PDF, con vista previa (#186, #188, #191).
- Exportar: permiso «Descargar datos personales» y opción «Para publicar» (nombre e inicial del apellido) (#195).
- Exportar: auditoría de cada descarga con datos personales, en Configuración → Personal (#196).
- Acceso por QR con usuario y contraseña; pasa a la fase siguiente con su tapiz; aviso al sustituir a otro árbitro (#172).
- Árbitro por QR que pierde la sesión: vuelve a entrar solo con la contraseña (#173, #193).
- Grupos de cualquier tamaño dentro del rango de la categoría y vuelta opcional (#174, #175).
- Grupos por tapiz: tablero y mover grupos arrastrando; permiso «Mover grupos entre tapices» (#176).
- Marcador del árbitro: cada +N con su −N y la sumisión como botón propio (#177).
- Ajustes: diferencia de superioridad y sin límite de puntos (#165).
- Deportes como plantillas en la base de datos (#178).
- El permiso «Participantes» también importa listas y ve las categorías (#192).
- Repaso de diseño de grupos por tapiz, tamaños de grupo y entrada por QR (#193).

### Arreglos
- Pantallas sin sesión: «Crear una cuenta», «Entrar» y los demás botones secundarios vuelven a ser compactos junto a su pregunta, como en el diseño; bajan debajo solo si no caben.
- Entrar: el formulario queda centrado en vertical, el pie legal cabe en una fila en el móvil y los errores salen como aviso bajo el título (también en el resto de formularios).
- Recargar la pantalla de entrada ya no repite «login?from=» en la dirección; recargar el registro se queda en el registro (#202).
- Puerta legal: sin `PRIVACY_CONTACT_EMAIL` el servidor no deja empezar ni crear una fase, y la app dice por qué (#198).
- Un tapiz sin árbitro admite grupos (#169).
- Ajustes se guardan con un botón y preguntan antes de salir (#170).
- Subir el PDF del reglamento en la web avisa de cómo fue (#171).
- La sesión no se cierra si se pierde la respuesta de una renovación (#179).
- Ningún combate empieza ni se reabre en una fase ya terminada (#183).
- Doble entrada por QR a la vez (#182).

### Interno
- Batería del servidor: matriz de permisos, día completo de torneo, concurrencia, ataques y migración (#180-#184, #187, #190).
- CI: en PR a `development`, solo los tests de los módulos tocados (#185).
- Limpieza L1: piezas y textos comunes en `brackety_core`, índices de claves foráneas (#194).
- Debug numera cada compilación y `deploy.sh` dice cuál ha desplegado; este archivo (#197).

## 0.8.2 y anteriores
En las etiquetas de GitHub (`v0.8.2`, `v0.8.1`, `v0.8.0`…) y en `docs/estado.md`.
