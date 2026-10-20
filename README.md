# PhotobridgeIA

**Puente local para editar fotografías en Adobe Lightroom Classic (Windows) mediante instrucciones conversacionales.**

**Versión de integración:** 0.6 beta. **Sin servidor MCP, sin Node.js en ejecución y sin cuotas de API adicionales.** El puente se comunica por archivos locales; ChatGPT puede operarlo a través de un equipo conectado a Desktop Commander. No es una conexión nativa permanente de ChatGPT al complemento.

## Funcionalidades de Revelar

- Identificación de la fotografía seleccionada por ID y catálogo; previsualizaciones temporales JPEG.
- Lectura completa de valores escalares de Revelar y controles numéricos: luz, color, HSL, textura, claridad, neblina, enfoque, ruido, efectos y geometría, según compatibilidad del SDK.
- Aplicación de ajustes no destructivos con verificación de los valores almacenados.
- Blanco y negro ↔ color, conservando la versión de proceso original del revelado.
- Curvas tonales por puntos con canales principal, rojo, verde y azul. Puntos \`x:y\` (0–255) en orden creciente. Permite restaurar la curva \`Linear\`.
- Instantáneas de Revelar para recuperación manual.
- Ajustes preestablecidos, balance de blancos y recorte según las operaciones que soporte Lightroom.
- Comandos de Auto Tone, Auto WB y creación/inversión de máscaras **experimentales**: requieren \`confirm=experimental\`, y no están certificados en todas las versiones o fotografías.
- Consulta de máscaras y de operaciones de eliminación puntual existentes.

## Instalación (Windows)

1. Descargá el código del repositorio y colocá la carpeta \`PhotobridgeIA.lrplugin\` en el equipo con Lightroom Classic.
2. Lightroom Classic → **Archivo > Gestor de plugins > Añadir** → seleccioná esa carpeta.
3. Habilitá PhotobridgeIA y abrí una fotografía en Revelar.
4. Desde ChatGPT, utilizá Desktop Commander conectado a esa computadora; el cliente \`PhotobridgeIAClient.ps1\` puede ejecutar las órdenes del plugin localmente sin servidor MCP.

La configuración \`Info.lua\` solicita iniciar con Lightroom. En algunas sesiones, el puente no se inicializa hasta visitar Biblioteca; el cliente PowerShell tiene un mecanismo de activación bajo demanda. No necesita una consola abierta permanentemente.

Ejemplos:

\`\`\`powershell
.\PhotobridgeIAClient.ps1 -Action inspect
.\PhotobridgeIAClient.ps1 -Action develop_get -Options 'parameter=Exposure2012'
.\PhotobridgeIAClient.ps1 -Action treatment -Options 'value=grayscale'
.\PhotobridgeIAClient.ps1 -Action curve_get
.\PhotobridgeIAClient.ps1 -Action curve_set -Options 'channel=main;points=0:0,128:140,255:255'
.\PhotobridgeIAClient.ps1 -Action curve_set -Options 'channel=main;points=0:0,255:255;name=Linear'
.\PhotobridgeIAClient.ps1 -Action snapshot -Options 'name=Checkpoint antes de editar'
\`\`\`

Las funciones experimentales requieren autorización explícita en las opciones. Probá cualquier máscara nueva o comando automático en una fotografía de prueba y verificá el resultado.

## Protección de fotografías

Lightroom Classic utiliza revelado no destructivo. PhotobridgeIA modifica los ajustes en el catálogo, **no sobrescribe los píxeles originales** y no crea copias virtuales automáticamente.

Cada comando de edición comprueba la fotografía y catálogo seleccionados. El cambio color/blanco y negro también conserva \`ProcessVersion\`; este mecanismo se verificó sobre un RAW antiguo para evitar actualizaciones silenciosas del motor de revelado.

### Pruebas

- La integración QA 0.6 se cargó en Lightroom Classic Windows.
- Prueba real color → blanco y negro → color: **PASS**.
- Comparación de 165 ajustes escalares antes/después: **0 diferencias**.
- SHA-256 del archivo RAW original antes/después: **idéntico**.
- Lectura de curvas RGB y escritura de curva principal personalizada seguida de restauración lineal: **PASS**.
- Instantánea: solicitud al SDK satisfactoria; Lightroom no ofrece lectura general de la lista de instantáneas mediante el SDK.
- Máscaras avanzadas, Auto Tone y Auto WB todavía **no certificadas** y protegidas como experimentales.
- CI valida sintaxis Lua 5.1, sintaxis PowerShell y controles básicos de privacidad.
- Prueba opcional: \`tests/LiveRoundTrip.ps1 -ConfirmLive\` (modifica temporalmente la foto seleccionada y exige poder leer el archivo original).

## Privacidad

La carpeta \`bridge/\` contiene rutas internas, metadatos y JPEG temporales. Está ignorada por Git y nunca debe publicarse. No hay servicio web expuesto, conexión MCP, ni credenciales integradas al código. No subas los catálogos, RAW ni previsualizaciones al repositorio.

## Limitaciones técnicas

El SDK no permite automatizar íntegramente todos los pinceles, borrados generativos, selección precisa de objetos y máscaras con geometrías complejas. PhotobridgeIA no anuncia compatibilidad plena donde no se verificó. No implementa funcionalidades de Biblioteca, exportación, impresión, publicación ni gestión de catálogos.

## Referencias y atribuciones

Mejoras selectivas adaptadas a partir de proyectos MIT, sin integrar sus servidores:

- [lightroom-mcp (Automaat)](https://github.com/Automaat/lightroom-mcp)
- [Lightroom MCP AI (par4987)](https://github.com/par4987/lightroom-mcp)

Consultá [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) y [la matriz de integración](docs/INTEGRATION_MATRIX.md) para el aviso de licencia, alcance, pruebas y decisiones técnicas.
