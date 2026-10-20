# Matriz de integración — Revelar

| Capacidades | Antes (0.5) | Rama integración (0.6) | Estado de validación |
| --- | --- | --- | --- |
| Identificar foto seleccionada | Sí | Conservada, ID y catálogo obligatorios | Probada en 0.5 |
| Previsualización JPEG temporal | Sí | Conservada | Probada en 0.5 |
| Ajustes globales básicos y HSL | Sí | Lectura tras escritura y detección de rechazo | Requiere retest real 0.6 |
| Blanco y negro / color | Sí | Conservada | Probada en 0.5; retest pendiente 0.6 |
| Presets / WB / recorte | Parcial | Conservadas | Algunas acciones sin prueba individual |
| Curvas RGB por puntos | No | `curve_get`, `curve_set`, pares x:y validados | Pendiente de prueba real |
| Instantánea para restauración | No | `snapshot` (crear, no listar) | Pendiente de prueba real |
| Auto Tone / Auto WB nativos | No | `auto_tone`, `auto_wb`, comparación antes/después | Pendiente de prueba real |
| Parámetros de DevelopController | Sí | Sin transacción anidada; verifican valor leído | Pendiente de retest 0.6 |
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
