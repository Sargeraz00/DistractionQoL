# Reglas Globales - Git, Arquitectura y Calidad

## Confirmación Obligatoria para Commits y Push a GitHub
- **NUNCA** ejecutar de forma autónoma comandos que realicen git commit, git push, o cualquier alteración en el historial o repositorio remoto en GitHub.
- **SIEMPRE PREGUNTAR AL USUARIO** de forma explícita y obtener su confirmación antes de ejecutar cualquier comando alusivo a:
  - Crear o modificar commits (git commit, git commit --amend, etc.).
  - Subir cambios o ramas al repositorio remoto (git push, git push origin <branch>, etc.).
  - Crear o subir tags / releases en Git.
- Antes de solicitar la confirmación, presentar un resumen claro de los cambios que se van a incluir (archivos afectados y mensaje propuesto para el commit).

## Verificación de Datos y Prohibido Asumir Información
- **NUNCA asumir datos, versiones, expansiones o estados del juego/entorno.**
- **SIEMPRE verificar en internet**, consultar el código fuente o **preguntar directamente al usuario** ante cualquier duda sobre el contexto temporal, versiones de software, expansiones activas o cambios recientes para evitar datos desfasados.
- Mantener los datos permanentemente sincronizados con la versión y expansión activa actual (ej. WoW: Midnight / 12.x).

## Política de Versionado Semántico (SemVer)
- En CADA sesión o tarea donde se realice un cambio de código, una feature, una mejora o un bugfix, se DEBE incrementar el número de versión según su impacto antes de solicitar confirmación para commitear:
  - **MAJOR (`+1.0.0`)**: Rediseños visuales o de navegación globales, saltos de expansión de WoW, o cambios estructurales en la base de datos (SavedVariables). Resetea MINOR y PATCH a 0.
  - **MINOR (`0.+1.0`)**: Incorporación de nuevos módulos, nuevas pestañas o features significativas compatibles hacia atrás. Resetea PATCH a 0.
  - **PATCH (`0.0.+1`)**: Corrección de bugs, hotfixes de APIs de Blizzard, pulidos de diseño, micro-optimizaciones o cambios de localización.
- La **única fuente de verdad** de la versión es el campo `## Version:` en `DistractionQoL/DistractionQoL.toc`. El código en runtime debe consumirla dinámicamente mediante `DQ.Util.GetVersion()`.

## Desacoplamiento Estricto: Lógica de Negocio vs. UI (`*Logic.lua`)
- Toda lógica de negocio compleja (algoritmos de ordenamiento, filtros, cálculo de compatibilidad, estadísticas o comparaciones) **DEBE residir en un submódulo puro `*Logic.lua`**, completamente desacoplada de la creación visual de frames y dependencias directas de la UI.
- Cada nueva lógica desacoplada debe acompañarse de sus pruebas unitarias en `tests/run_tests.lua`.

## Uso Obligatorio del Design System (`DQ.UI.Theme` y `DQ.UI:CreateWindow`)
- **PROHIBIDO duplicar tablas de backdrop manuales, barras de título o colores RGB literales inline.**
- Todo nuevo panel, modal o elemento visual debe construirse utilizando la factoría centralizada `DQ.UI:CreateWindow(...)` y los tokens de color/fuentes definidos en `DQ.UI.Theme`.

## Límite de Longitud y Responsabilidad Única (Anti-God Functions)
- Ninguna función nueva o modificada debe superar las **~80-100 líneas**.
- Si una función o vista excede este límite, debe subdividirse en sub-constructores temáticos (ej. pestañas separadas en `UI/Tabs/`, generadores de tarjetas o helpers específicos).

## Blindaje en Combate y APIs Modernas de Midnight (12.x)
- **Cero errores en combate (`ADDON_ACTION_BLOCKED`):** Nunca alterar, anclar, redimensionar, mostrar u ocultar frames que contengan acciones protegidas (`SecureActionButtonTemplate`) o sus contenedores si `InCombatLockdown()` es verdadero; diferir la acción a `PLAYER_REGEN_ENABLED`.
- **Secret Values:** Toda cadena proveniente de eventos de chat o LFG debe validarse con `issecretvalue()` antes de aplicar funciones de string (`:match()`, `string.find()`) para evitar caídas dentro de estancias en WoW Midnight.
- **Clicks Seguros:** Todo botón seguro debe registrar `btn:RegisterForClicks("AnyUp", "AnyDown")` para compatibilidad con `ActionButtonUseKeyDown=1`.

## Registro Declarativo (Zero Acoplamiento en `Core.lua`)
- Todo nuevo módulo debe integrarse mediante el registro declarativo `DQ.Modules:Register(id, priority, initFn)`.
- Todo comando slash debe registrarse mediante `DQ.Commands:Register(cmd, desc, handlerFn, aliases)`.
- `Core.lua` permanece inmutable y como un cableado mínimo de arranque.

## Localización Rigurosa Obligatoria (esES / esMX y resto enUS)
- **PROHIBIDO mezclar idiomas en una misma vista, botón, mensaje o descripción** (ej. "Comida (Well Fed)" o mezclar botones en español con tooltips o textos en inglés).
- **SIEMPRE verificar que toda nueva feature, frame, opción o mensaje de chat esté 100% localizado** para los idiomas soportados:
  - `esES` y `esMX`: Español completo, natural y gramaticalmente correcto.
  - `enUS` (y fallback universal para cualquier otro cliente): Inglés completo, limpio y preciso.
- **PROHIBIDO hardcodear cadenas de texto visibles al usuario inline.** Todo texto debe registrarse y consumirse a través del diccionario centralizado `Core/Locales.lua` (`DQ.L`).

## Garantía de Calidad Offline Pre-Commit (Tests + Sintaxis)
- Antes de dar por concluida cualquier sesión o solicitar confirmación para commit, se DEBE ejecutar obligatoriamente:
  1. La suite de pruebas unitarias offline (`lua tests/run_tests.lua`), debiendo aprobar el 100% de los tests.
  2. Verificación de sintaxis limpia en todos los archivos del proyecto con `luac -p`.