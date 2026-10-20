# Matriz de integración — Revelar

| Capacidades | Antes (0.5) | Rama integración (0.6) | Estado de validación |
| --- | --- | --- | --- |
| Identificar foto seleccionada | Sí | Conservada, ID y catálogo obligatorios | Probada en 0.5 |
| Previsualización JPEG temporal | Sí | Conservada | Probada en 0.5 |
| Ajustes globales básicos y HSL | Sí | Lectura tras escritura y detección de rechazo | Probados lectura/escritura en 0.5; nueva verificación específica pendiente |
| Blanco y negro / color | Sí | Conservada; preserva ProcessVersion original | 0.6: prueba real superada, 165 valores idénticos y hash RAW estable |
| Presets / WB / recorte | Parcial | Conservadas | Algunas acciones sin prueba individual |
| Curvas RGB por puntos | No | `curve_get`, `curve_set`, pares x:y validados | 0.6: canal principal probado, personalizado y restaurado a lineal; canales RGB sólo leídos |
| Instantánea para restauración | No | `snapshot` (crear, no listar) | 0.6: creada por SDK; sin API de lectura para confirmar listado |
| Auto Tone / Auto WB nativos | No | `auto_tone`, `auto_wb`, comparación antes/después | Pendiente de prueba real |
| Parámetros de DevelopController | Sí | Sin transacción anidada; verifican valor leído | Corrección incluida; test de escritura propio pendiente en 0.6 |
| Máscaras de IA | Parcial | Se verifica ID o crecimiento de máscaras | No certificadas para todas las variantes |
| Borrar/editar máscara por píxel | No | No incorporado: alto riesgo / API parcial | No disponible |
| Eliminación generativa / IA | No | No incorporada: depende de interacción gráfica | No disponible |
| Servidor MCP | No | Excluido deliberadamente | No aplica |
| Copias virtuales automáticas | No | No se agregan | Cumplido |

## Decisiones y límites técnicos

1. El único canal de comunicación sigue siendo el puente de archivos y el cliente
   PowerShell ejecutado en el equipo con Lightroom mediante Desktop Commander.
2. Los métodos de `LrDevelopController` manejan la sesión de Revelar y no se
   envuelven en `catalog:withWriteAccessDo`. Las operaciones de `LrPhoto`
   sí utilizan acceso de escritura al catálogo cuando el SDK lo requiere.
3. El SDK no ofrece una interfaz universal para pintar máscaras, seleccionar
   objetos arbitrarios o usar eliminaciones generativas con precisión de píxel.
   Una integración local no debe declarar estas funciones como completadas.
4. Los métodos `createDevelopSnapshot` y `getDevelopSettings` permiten
   puntos de recuperación, pero el SDK no ofrece recuperación de la instantánea
   por nombre como método general. Verificar en el panel Instantáneas.
5. La previsualización se almacena localmente y no debe subir al repositorio.

## Criterios obligatorios para integrar en main

- Sin detección de datos privados en el árbol de archivos y commits a publicar.
- Validación de sintaxis Lua y PowerShell.
- Pruebas funcionales con Lightroom activo; todas las funciones nuevas deben
  probarse o quedar explícitamente marcadas como beta y fuera del uso predeterminado.
- Prueba color → blanco y negro → color, comparar ajustes y hash del archivo.
- Documentación y atribuciones MIT verificadas.

## Evidencia de pruebas locales 0.6

- Lightroom Classic Windows, complemento QA separado para no sustituir la versión principal.
- Fotografía real seleccionada por su ID interno, sin publicar imágenes ni rutas.
- Prueba color → blanco y negro → color: **PASS** tras la corrección de `ProcessVersion`.
- Diferencias entre 165 ajustes escalares iniciales y finales: **0**.
- SHA-256 del archivo original antes y después: **idéntico**.
- Se detectó previamente que Quick Develop actualizaba `ProcessVersion`; se restauró el estado y se incorporó una protección verificada en la segunda prueba.
- Lectura de curvas RGB: **PASS**; escritura de curva principal personalizada y restauración lineal: **PASS**.
- Instantánea: creación confirmada por la llamada SDK, pero sin readback de nombres disponible.
- Auto Tone / Auto WB, máscaras nuevas y eliminación avanzada: **no probadas**; requieren `confirm=experimental` y no deben considerarse compatibles sin verificación.
- El cliente sigue usando Desktop Commander; no existe conexión MCP directa con la conversación.
