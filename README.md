# PhotobridgeIA

Complemento experimental para **Adobe Lightroom Classic** orientado al módulo **Revelar**. Permite consultar la fotografía seleccionada y aplicar ajustes desde un cliente local mediante el SDK Lua de Lightroom.

**Versión:** 0.5 beta. **Edición no destructiva:** trabaja sobre los ajustes del catálogo sin sobrescribir los píxeles del archivo fuente y sin crear copias virtuales obligatorias.

## Funciones

- Consultar foto activa y una previsualización JPEG.
- Leer todos los ajustes escalares de revelado y los rangos de parámetros compatibles.
- Modificar exposición, contraste, sombras, luces, color, HSL, detalle y demás parámetros que soporte el SDK.
- Cambiar entre color y blanco y negro.
- Listar y aplicar presets.
- Ajustar balance de blancos, recorte y orientación.
- Abrir paneles y herramientas de Revelar; consultar máscaras y operaciones puntuales de retoque.
- Enviar acciones de máscaras compatibles con el SDK, sujetas a las restricciones de cada tipo.

**Límite:** el SDK no expone todo el control visual o generativo de Lightroom Classic. Algunas máscaras, retoques por IA y operaciones precisas de interfaz no están implementadas ni garantizadas. No es una API remota ni un editor de imágenes externo.

## Instalación

1. Copiar `PhotobridgeIA.lrplugin` a una carpeta local.
2. En Lightroom Classic, abrir **Archivo > Gestor de plugins > Añadir** y seleccionar la carpeta.
3. Verificar que aparezca **PhotobridgeIA** como activado.
4. `Info.lua` solicita la carga automática (`LrInitPlugin` y `LrForceInitPlugin`). En la configuración probada, si Lightroom abre directamente en Revelar, la carga se difiere hasta entrar en Biblioteca.
5. Utilizar `PhotobridgeIAClient.ps1` desde PowerShell en la carpeta del complemento.

Ejemplos:

```powershell
.\PhotobridgeIAClient.ps1 -Action inspect
.\PhotobridgeIAClient.ps1 -Action develop_get -Options "parameter=Exposure2012"
.\PhotobridgeIAClient.ps1 -Action apply -Options "Exposure2012=0.3;Contrast2012=10"
.\PhotobridgeIAClient.ps1 -Action treatment -Options "value=grayscale"
.\PhotobridgeIAClient.ps1 -Action mask_list
```

El cliente acepta los parámetros adicionales mediante `-Options`, separados por punto y coma. Para las acciones de escritura, el puente verifica la identidad de la foto y del catálogo antes de ejecutar.

## Comunicación y seguridad

El complemento utiliza exclusivamente archivos locales en `PhotobridgeIA.lrplugin/bridge/`, que se crea en ejecución. Allí pueden guardarse **rutas privadas, ajustes y previsualizaciones**, por lo que nunca deben publicarse. La carpeta está excluida mediante `.gitignore`.

No hay servidor HTTP, token, credenciales ni conexión directa a la nube de Adobe. El programa que transmite órdenes locales debe contar con la autorización del usuario y los permisos del directorio. El cliente usa un bloqueo para evitar comandos simultáneos.

## Estado de pruebas

La versión 0.5 se cargó en Lightroom Classic y pasó pruebas de inspección, capacidades, lectura de ajustes, presets, máscaras y retoque, además de ajustes de revelado y tratamiento de color aplicados con valores que no alteraron el aspecto de la fotografía (10 operaciones). No se ha realizado aún una validación exhaustiva de todas las herramientas avanzadas. La prueba de reinicio detectó que al abrir en Revelar el plugin puede quedar habilitado pero sin ejecutar su inicialización hasta entrar en Biblioteca.


## Activación de respaldo (Windows)

Si el pulso de actividad del plugin no se reanuda al abrir Lightroom en Revelar, `PhotobridgeIAClient.ps1` intenta activarlo al recibir la primera orden. Solicita temporalmente el módulo Biblioteca y vuelve a Revelar si ese era el módulo activo. En la instalación de referencia utiliza comandos internos de menú de Lightroom Classic 15.x; esos identificadores pueden variar entre versiones y el mecanismo debe verificarse en otras instalaciones. La carga en Biblioteca está probada; la activación automática del cliente después de un reinicio aún no cuenta con una prueba completa.

## Licencia

Por el momento no se concede una licencia de uso o redistribución adicional. El titular podrá incorporarla posteriormente.
