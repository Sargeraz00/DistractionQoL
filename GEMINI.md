# Reglas Globales - Git, Arquitectura y Calidad

## Confirmación Obligatoria para Commits y Push a GitHub
- **NUNCA** ejecutar de forma autónoma comandos que realicen git commit, git push, o cualquier alteración en el historial o repositorio remoto en GitHub.
- **SIEMPRE PREGUNTAR AL USUARIO** de forma explícita y obtener su confirmación antes de ejecutar cualquier comando alusivo a:
  - Crear o modificar commits (git commit, git commit --amend, etc.).
  - Subir cambios o ramas al repositorio remoto (git push, git push origin <branch>, etc.).
  - Crear o subir tags / releases en Git.
- Antes de solicitar la confirmación, presentar un resumen claro de los cambios que se van a incluir (archivos afectados y mensaje propuesto para el commit).

## Conocimiento de Versión Actual (Midnight 12.x) y Cero Referencias Pasadas
- **Versión Activa del Juego:** El entorno de desarrollo y ejecución es **World of Warcraft: Midnight (12.x / Parche 12.1 / Temporada 2)**.
- **PROHIBIDO TERMINANTEMENTE USAR REFERENCIAS O ÍTEMS DE EXPANSIONES PASADAS:**
  - NUNCA usar nombres de ítems, bandas, mazmorras, consumibles o referencias de expansiones obsoletas (*The War Within / 11.x*, *Dragonflight / 10.x*, *Shadowlands*, etc.) en simulaciones, ejemplos, pruebas, mensajes o catálogo de datos.
  - Todo ejemplo o simulación debe ser 100% verosímil y ceñido a la temporada activa actual (ej. Banda *El Abismo Venenoso*, jefe final *Ula'tek*, mazmorras de temporada).
- **Squish de Nivel de Objeto (Ilvl Realista):** Midnight incorporó un squish masivo de estadísticas e ilvl. El techo máximo de equipo en Temporada 2 es **~344 ilvl** (Ula'tek Mítico 6/6), con raiders de alto nivel en torno a **335 ilvl**, y contenido Heroico en **305-328 ilvl**. PROHIBIDO mostrar o simular ilvls pre-squish (ej. 600+).
- **Prohibido Asumir Información:** NUNCA asumir datos, versiones o expansiones. SIEMPRE verificar en internet o consultar al usuario ante cualquier duda de contexto temporal o cambios del juego.

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

## Modernización de APIs de Blizzard y Blindaje en Combate (Midnight 12.x)
- **La API de WoW evoluciona continuamente:** Estar plenamente consciente de que parches recientes eliminaron múltiples funciones globales legacy (ej. `GetItemQualityColor` fue retirada; no existe en Midnight).
- **Adopción de Namespaces Modernos (`C_*`):** Priorizar siempre las APIs oficiales de Blizzard con namespace (`C_Item.*`, `C_Spell.*`, `C_Timer.*`, `C_ChallengeMode.*`), o verificar la existencia de cualquier función o tabla (`ITEM_QUALITY_COLORS`) antes de invocarla.
- **Cero errores en combate (`ADDON_ACTION_BLOCKED`):** Nunca alterar, anclar, redimensionar, mostrar u ocultar frames que contengan acciones protegidas (`SecureActionButtonTemplate`) o sus contenedores si `InCombatLockdown()` es verdadero; diferir la acción a `PLAYER_REGEN_ENABLED`.
- **Secret Values en Midnight:** Toda cadena proveniente de eventos de chat o LFG debe validarse con `issecretvalue()` antes de aplicar funciones de string (`:match()`, `string.find()`) para evitar caídas dentro de estancias en WoW Midnight.
- **Clicks Seguros:** Todo botón seguro debe registrar `btn:RegisterForClicks("AnyUp", "AnyDown")` para compatibilidad con `ActionButtonUseKeyDown=1`.

## Estándares Oficiales de Blizzard (Battle.net Developer Portal & In-Game APIs)
- **Separación de Entornos (Web API vs. In-Game Lua):**
  - La **Battle.net Developer Web API** (`https://{region}.api.blizzard.com`) es una API RESTful estructurada en:
    - `static-{region}`: Datos inmutables de catálogo (ítems, hechizos, medios de ítems).
    - `dynamic-{region}`: Datos en tiempo real (subastas, estado de reinos, leaderboards M+).
    - `profile-{region}`: Perfiles de personajes y hermandades (requiere OAuth 2.0 User Scopes).
  - **Seguridad Absoluta (Cero Filtración de Credenciales):** NUNCA incluir Client Secret o Client ID en código Lua de addons cliente. El entorno Lua de WoW es abierto y no compilado. Los addons operan exclusivamente mediante las APIs internas `C_*` y eventos de Blizzard.
  - **Eficiencia y Caché:** Las consultas a APIs oficiales deben respetar cuotas (36,000 req/hora por cliente) y usar encabezados condicionales `If-Modified-Since` para aprovechar respuestas `304 Not Modified`.

## Reglas de UI: Tipografía, Glifos y Espaciado de Botones
- **Cero Glifos Rotos (`[]`):** Las fuentes estándar del cliente de WoW (`GameFont*`, `FRIZQT__.TTF`) NO soportan glifos Unicode matemáticos o extendidos (como `▲`, `▼`, `✓`, `✔`). Su uso provoca la renderización de un cuadro vacío (`[]`).
  - **Obligatorio:** Usar únicamente caracteres ASCII seguros (`+`, `*`, `v`, `OK`) o texturas nativas integradas mediante `|TInterface\\...:12:12|t` o frames `Texture` dedicados.
- **Espaciado Obligatorio de Botones (Cero Solapamiento):** En modales o ventanas de decisión con múltiples botones horizontales, DEBE existir un margen/gap explícito (mínimo 6-8px) y dimensiones calculadas simétricamente para evitar que los bordes o fondos se toquen o sobrepongan.
- **Fidelidad Estricta de Iconos de Ítems (Item Media):** Los iconos deben reflejar fidedignamente la ranura y naturaleza del ítem:
  - Anillos (`INVTYPE_FINGER`): Texturas exclusivas de anillos (`inv_jewelry_ring_*`), NUNCA collares ni brazaletes.
  - Abalorios (`INVTYPE_TRINKET`): Texturas de talismanes o fetiches místicos (`inv_trinket_*` o `inv_jewelry_talisman_*`), NUNCA armas ni escudos de clase.

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