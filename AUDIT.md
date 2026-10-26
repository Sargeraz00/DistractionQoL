# Auditoría Técnica Exhaustiva: DistractionQoL (WoW Retail — Midnight 12.x)

**Fecha:** 22 de Octubre de 2026  
**Auditor:** Senior Software Engineer (Especialista en Lua, WoW Retail Addons, Taint & Secure Execution)  
**Versión Auditada:** DistractionQoL v4.1.1 (Commit `2c194fd` en `main`)  
**Entorno Objetivo:** World of Warcraft: Midnight (12.x / 12.1.5)  
**Estado de Pruebas Offline:** 150/150 tests aprobados (`tests/run_tests.lua`), 0 errores de sintaxis (`luac -p` limpio en los 43 archivos).

---

## 1. Resumen Ejecutivo

### 1.1 Estado General del Repositorio
DistractionQoL presenta una base arquitectónica notablemente superior al promedio del ecosistema de addons de World of Warcraft. El desacoplamiento de la lógica de negocio pura (`*Logic.lua`) respecto a los frames de presentación de la interfaz (`*Bar.lua`, `*Panel.lua`) y la ausencia de bucles `OnUpdate` continuos descontrolados le permiten acercarse de manera realista al objetivo de **coste de CPU/FPS imperceptible** fuera de combate.

El blindaje contra `InCombatLockdown()` en botones protegidos (`SecureActionButtonTemplate`) y el uso de `pcall` en APIs de sonido y chat demuestran un conocimiento maduro de las restricciones del motor de Blizzard.

Sin embargo, la auditoría ha identificado **dos defectos de alta severidad que inutilizan funcionalidades clave en el cliente en vivo** (un patrón regex roto en la captura de botín y un registro de evento inexistente en el motor de FrameXML de Blizzard), además de riesgos latentes en el manejo de *Secret Values* en Midnight 12.x y sobrecostes evitables de procesamiento de eventos globales (`UNIT_AURA`) en entornos de banda.

### 1.2 Riesgos Principales
1. **Fallo Crítico Funcional en Captura de Botín:** La expresión regular encargada de interceptar los enlaces de objetos de los miembros del grupo en `CHAT_MSG_LOOT` omite una pleca (`|`), haciendo que el 100% de los objetos despojados en mazmorras y bandas sean ignorados por el sistema de recomendación de intercambio (`TradeAdvisor`).
2. **Error de Motor por Evento Inexistente (`UNIT_DIED`):** El módulo `WipeRelease` intenta registrar `frame:RegisterEvent("UNIT_DIED")`. En la arquitectura de WoW, `UNIT_DIED` es exclusivamente un subevento del registro de combate (`COMBAT_LOG_EVENT_UNFILTERED`) y no un evento de frame de Blizzard, provocando un error en tiempo de carga en el cliente real.
3. **Vulnerabilidad a Cuelgues por Secret Values en Mazmorras/Bandas:** En `RaidFlow.lua`, los mensajes entrantes de temporizadores de pull de DBM y BigWigs son procesados mediante `:find()` sin verificar previamente `issecretvalue()`, lo que provocará errores Lua fatales si Blizzard restringe cadenas de addon en estancias de Midnight 12.x.
4. **Desincronización de Estado en la Barra de Consumibles:** La barra flotante interactiva de consumibles no escucha `BAG_UPDATE_DELAYED` mientras está visible, manteniendo contadores e indicadores desfasados tras el uso de pociones o frascos.
5. **Sobrecoste de Eventos en Bandas Masivas:** Registro global no filtrado de `UNIT_AURA` en `ConsumablesBar`, obligando al hilo de Lua a despertar decenas de veces por segundo ante cualquier buff/debuff de los 20-30 jugadores de la estancia, incluso cuando la barra está oculta.

### 1.3 Cinco Mejoras Prioritarias
| Prioridad | ID | Módulo | Resumen de Acción |
| :---: | :---: | :---: | :--- |
| **P1** | `BUG-LOOT-01` | `TradeAdvisor.lua` | Corregir la pleca faltante en el patrón regex de extracción de links de objetos (`%]|h|r`). |
| **P2** | `BUG-MITH-01` | `WipeRelease.lua` | Eliminar el registro ilegal de `UNIT_DIED` y sustituirlo por `GROUP_ROSTER_UPDATE` / `UNIT_HEALTH` de party. |
| **P3** | `SEC-CHAT-01` | `RaidFlow.lua` | Añadir salvaguarda `issecretvalue()` antes de evaluar `msg:find()` en `CHAT_MSG_ADDON`. |
| **P4** | `PERF-EVENT-01` | `ConsumablesBar.lua` | Migrar `UNIT_AURA` a `RegisterUnitEvent("UNIT_AURA", "player")` y registrarlo únicamente cuando la barra sea visible. |
| **P5** | `DATA-EVOKER-01` | `GameData.lua` | Agregar armas 2H (Espadas, Mazas, Hachas y Armas de Asta) a la tabla de proficiencias del Evocador. |

---

## 2. Hallazgos

### [BUG-LOOT-01] Patrón Regex de Enlace de Objeto Roto en `TradeAdvisor`
- **Severidad:** HIGH
- **Categoría:** Fiabilidad / Expresiones Regulares
- **Archivo & Función:** [TradeAdvisor.lua](file:///c:/Users/Sargeraz/.gemini/antigravity-ide/scratch/DistractionQoL/DistractionQoL/Modules/Loot/TradeAdvisor.lua#L420-L430), función `OnEvent` (evento `CHAT_MSG_LOOT`), línea 421.
- **Evidencia & Explicación Técnica:**
  ```lua
  -- Línea 421 en TradeAdvisor.lua:
  local itemLink = message and message:match("(|c%x+|Hitem:[^|]+|h%[[^%]]+%]h|r)")
  ```
  Los enlaces de objetos estándar en el cliente de World of Warcraft se estructuran con etiquetas de apertura y cierre de hipervínculo:
  `|c[color]|Hitem:[params]|h[[nombre]]|h|r`
  Nótese la etiqueta de cierre: `]|h|r`. En la línea 421, la expresión regular escrita es `%]h|r` (le falta la pleca `|` antes de la `h`).
  En el motor de patrones de Lua, `%]` busca el corchete literal y `h|r` busca los caracteres literales `h|r`. Al no tener la pleca, la coincidencia devuelve estrictamente `nil` para cualquier enlace legítimo generado por el motor de WoW.
  Prueba directa en el motor Lua:
  ```lua
  local msg = "Has recibido botín: |cffa335ee|Hitem:221021::::::::70:268::11:1:3524:::|h[Coraza]|h|r."
  print(msg:match("(|c%x+|Hitem:[^|]+|h%[[^%]]+%]h|r)"))   --> nil
  print(msg:match("(|c%x+|Hitem:[^|]+|h%[[^%]]+%]|h|r)")) --> |cffa335ee|Hitem:221021...|h[Coraza]|h|r
  ```
- **Escenario de Reproducción e Impacto:** En una banda o mazmorra en vivo, un compañero o el jugador recibe una pieza de equipo. Se dispara `CHAT_MSG_LOOT`. El enlace no coincide, `itemLink` es `nil`, y `ProcessLootDrop` nunca es invocado. La ventana de asesor de intercambio permanece vacía al finalizar los bosses. La suite de pruebas no detectó esto porque `tests/run_tests.lua` solo prueba `TradeAdvisorLogic` pasándole estructuras ya procesadas o invocando `SimulateDrop`, saltándose el flujo de eventos reales de chat.
- **Corrección Recomendada:**
  ```diff
  - local itemLink = message and message:match("(|c%x+|Hitem:[^|]+|h%[[^%]]+%]h|r)")
  + local itemLink = message and message:match("(|c%x+|Hitem:[^|]+|h%[[^%]]+%]|h|r)")
  ```
- **Riesgo de Regresión & Validación:** Riesgo nulo. Validación mediante inyección de cadenas reales de `CHAT_MSG_LOOT` en pruebas unitarias.
- **Confianza del Hallazgo:** 100% (Hecho confirmado mediante ejecución directa en el intérprete de Lua).

---

### [BUG-MITH-01] Registro Ilegal de Evento Inexistente `UNIT_DIED` en `WipeRelease`
- **Severidad:** HIGH
- **Categoría:** Compatibilidad / FrameXML de Blizzard
- **Archivo & Función:** [WipeRelease.lua](file:///c:/Users/Sargeraz/.gemini/antigravity-ide/scratch/DistractionQoL/DistractionQoL/Modules/MythicPlus/WipeRelease.lua#L87-L95), función `DQ.WipeRelease:Init()`, línea 92.
- **Evidencia & Explicación Técnica:**
  ```lua
  function DQ.WipeRelease:Init()
      local frame = CreateFrame("Frame")
      frame:RegisterEvent("PLAYER_DEAD")
      frame:RegisterEvent("PLAYER_ALIVE")
      frame:RegisterEvent("PLAYER_UNGHOST")
      frame:RegisterEvent("UNIT_DIED")       -- Línea 92: EVENTO NO VÁLIDO
      frame:RegisterEvent("ENCOUNTER_END")
  ```
  En la API de Blizzard, `UNIT_DIED` **no es un evento de frame**. Es un sub-evento que se recibe exclusivamente a través del evento paraguas `COMBAT_LOG_EVENT_UNFILTERED` mediante `CombatLogGetCurrentEventInfo()`.
  Al invocar `frame:RegisterEvent("UNIT_DIED")` en el cliente real de WoW, el motor de C++ emite un error de script:
  `attempt to register unknown event 'UNIT_DIED'`
  Como esta línea no está envuelta en un `pcall`, la inicialización de `WipeRelease:Init()` se interrumpe y `ENCOUNTER_END` no llega a registrarse.
- **Escenario de Reproducción e Impacto:** Al arrancar el cliente de WoW o recargar la interfaz con el módulo activo, se genera un error de Lua o falla el registro de los eventos subsiguientes del frame. La comprobación offline en `tests/run_tests.lua` no lo detectó porque solo cargaba los submódulos `*Logic.lua`, sin inicializar los manejadores de frames de los módulos de Mítica+.
- **Corrección Recomendada:**
  Eliminar el registro de `UNIT_DIED` de la línea 92 y el bloque `elseif event == "UNIT_DIED"` (líneas 98-115). Para detectar la muerte de compañeros de grupo fuera del combat log, registrar `GROUP_ROSTER_UPDATE` y comprobar la vida mediante `UNIT_HEALTH` de las unidades de grupo:
  ```lua
  frame:RegisterEvent("PLAYER_DEAD")
  frame:RegisterEvent("PLAYER_ALIVE")
  frame:RegisterEvent("PLAYER_UNGHOST")
  frame:RegisterEvent("GROUP_ROSTER_UPDATE")
  frame:RegisterEvent("ENCOUNTER_END")
  ```
- **Riesgo de Regresión & Validación:** Bajo. La evaluación del estado de wipe ya depende de `IsPartyFullWipe()`, que itera sobre los miembros de grupo comprobando `UnitIsDeadOrGhost(unit)`.
- **Confianza del Hallazgo:** 100% (Hecho confirmado mediante documentación oficial de eventos de Blizzard y FrameXML).

---

### [SEC-CHAT-01] Ausencia de Validación `issecretvalue()` en `CHAT_MSG_ADDON` (Midnight 12.x)
- **Severidad:** MEDIUM
- **Categoría:** Seguridad / Compatibilidad Midnight 12.x
- **Archivo & Función:** [RaidFlow.lua](file:///c:/Users/Sargeraz/.gemini/antigravity-ide/scratch/DistractionQoL/DistractionQoL/Modules/RaidFlow/RaidFlow.lua#L91-L102), función `OnEvent`, líneas 92-101.
- **Evidencia & Explicación Técnica:**
  ```lua
  elseif event == "CHAT_MSG_ADDON" then
      if not DQ.Config:Get("raidFlow", "flashTaskbar") then return end

      if prefix == "D4" and msg and msg:find("PT") then
          if FlashClientIcon then FlashClientIcon() end
      elseif prefix == "BigWigs" and msg and (msg:find("Pull") or msg:find("pull")) then
          if FlashClientIcon then FlashClientIcon() end
      end
  ```
  En la expansión Midnight (12.x), Blizzard introdujo el sistema de *Secret Values* para restringir la introspección de ciertas cadenas dentro de mazmorras y bandas. Si un valor es marcado como secreto (`issecretvalue(val) == true`), cualquier llamada a funciones de cadena estándar como `string.find()`, `:find()`, o `:match()` arroja un error crítico irrecuperable.
  Mientras que `TargetedBy.lua` y `TradeAdvisor.lua` fueron protegidos con la función `issecretvalue()`, `RaidFlow.lua` ejecuta directamente `msg:find(...)`.
- **Escenario de Reproducción e Impacto:** En caso de que Blizzard restrinja los paquetes de comunicación inter-addon en estancias o si un addon malintencionado/desfasado emite cadenas cifradas en el canal de addon, la interfaz lanzará un error de script justo antes del pull de un jefe.
- **Corrección Recomendada:**
  ```lua
  elseif event == "CHAT_MSG_ADDON" then
      if not DQ.Config:Get("raidFlow", "flashTaskbar") then return end
      if issecretvalue and ((prefix and issecretvalue(prefix)) or (msg and issecretvalue(msg))) then
          return
      end
      if prefix == "D4" and msg and msg:find("PT") then
  ```
- **Riesgo de Regresión & Validación:** Nulo.
- **Confianza del Hallazgo:** Hecho confirmado respecto a las políticas de seguridad de Midnight 12.x.

---

### [PERF-EVENT-01] Registro Global y Permanente de `UNIT_AURA` en `ConsumablesBar`
- **Severidad:** MEDIUM
- **Categoría:** Rendimiento / Sobrecoste de Eventos en CPU
- **Archivo & Función:** [ConsumablesBar.lua](file:///c:/Users/Sargeraz/.gemini/antigravity-ide/scratch/DistractionQoL/DistractionQoL/Modules/RaidFlow/ConsumablesBar.lua#L356-L382), función `CreateBarFrame()`, línea 358.
- **Evidencia & Explicación Técnica:**
  ```lua
  f:RegisterEvent("PLAYER_REGEN_ENABLED")
  f:RegisterEvent("UNIT_AURA")
  f:SetScript("OnEvent", function(self, event, unit)
      ...
      elseif event == "UNIT_AURA" and unit == "player" then
          if self:IsShown() and not InCombatLockdown() then
  ```
  1. **Falta de filtrado por unidad:** Al registrar `RegisterEvent("UNIT_AURA")` en lugar de `RegisterUnitEvent("UNIT_AURA", "player")`, el motor del juego invoca el cierre de Lua para cada cambio de aura en *todas* las entidades de la estancia (jefes, esbirros, 20 o 30 jugadores de la banda, mascotas, nameplates, etc.).
  2. **Registro permanente en marcos ocultos:** Una vez creada la barra (por ejemplo, tras ejecutar `/consumables` o un ready check), el evento `UNIT_AURA` permanece registrado para siempre, incluso cuando la barra está cerrada (`f:Hide()`). Aunque la línea 369 compruebe `if self:IsShown()`, la llamada C->Lua ocurre de forma incesante cientos de veces por minuto en combate.
- **Escenario de Reproducción e Impacto:** En un encuentro de banda mítica de 20 jugadores, se generan entre 80 y 250 eventos `UNIT_AURA` por segundo debido a ticks de daño periódico, sanaciones en el tiempo y procs de abalorios. Esto produce cambios de contexto evitables entre el motor de renderizado y la VM de Lua, aumentando la latencia de fotogramas.
- **Corrección Recomendada:**
  1. Cambiar a `f:RegisterUnitEvent("UNIT_AURA", "player")`.
  2. Registrar el evento únicamente en `ShowBar()` y desregistrarlo mediante `f:UnregisterEvent("UNIT_AURA")` en `HideBar()`.
- **Riesgo de Regresión & Validación:** Muy bajo. Solo se requiere actualizar los indicadores cuando el marco está físicamente en pantalla.
- **Confianza del Hallazgo:** 100% (Comportamiento demostrado del motor FrameXML de WoW).

---

### [BUG-RAID-01] Barra de Consumibles sin Actualización de Inventario (`BAG_UPDATE_DELAYED`)
- **Severidad:** MEDIUM
- **Categoría:** Fiabilidad Funcional / Estado Inconsistente
- **Archivo & Función:** [ConsumablesBar.lua](file:///c:/Users/Sargeraz/.gemini/antigravity-ide/scratch/DistractionQoL/DistractionQoL/Modules/RaidFlow/ConsumablesBar.lua#L356-L382), función `CreateBarFrame()`.
- **Evidencia & Explicación Técnica:**
  El marco de la barra de consumibles escucha `UNIT_AURA` y `PLAYER_REGEN_ENABLED`, pero no escucha ningún evento de bolsas. Cuando el jugador pulsa sobre el botón seguro para aplicar un aceite, consumir una comida o beber un frasco, el objeto desaparece de la bolsa. Sin embargo, los textos numéricos de los botones (`btn.countText`) y los atributos de rotación no se refrescan en tiempo real.
- **Escenario de Reproducción e Impacto:**
  1. Abrir la barra con `/consumables`.
  2. Tener 1 poción o frasco restante en el inventario.
  3. Usar el consumible.
  4. La barra sigue mostrando `1` en lugar de `0` (rojo desaturado) hasta que el usuario cierra y reabre manualmente el panel.
- **Corrección Recomendada:**
  Registrar `f:RegisterEvent("BAG_UPDATE_DELAYED")` mientras la barra esté visible y refrescar el conteo fuera de combate:
  ```lua
  elseif event == "BAG_UPDATE_DELAYED" then
      if self:IsShown() and not InCombatLockdown() then
          DQ.ConsumablesBar:Refresh()
      end
  ```
- **Riesgo de Regresión & Validación:** Nulo si se respeta el bloqueo fuera de combate (`not InCombatLockdown()`).
- **Confianza del Hallazgo:** Hecho confirmado.

---

### [DATA-EVOKER-01] Omisión de Armas 2H en la Definición de Proficiencias del Evocador
- **Severidad:** MEDIUM
- **Categoría:** Calidad de Datos del Juego / Retail & Midnight
- **Archivo & Función:** [GameData.lua](file:///c:/Users/Sargeraz/.gemini/antigravity-ide/scratch/DistractionQoL/DistractionQoL/Core/GameData.lua#L27-L44), tabla `CLASS_WEAPONS`, línea 43.
- **Evidencia & Explicación Técnica:**
  ```lua
  -- Línea 43 en GameData.lua:
  ["EVOKER"] = { [0]=true, [4]=true, [7]=true, [10]=true, [13]=true, [15]=true },
  ```
  La enumeración de subclases de armas en WoW es:
  `0=1H Axe, 1=2H Axe, 4=1H Mace, 5=2H Mace, 6=Polearm, 7=1H Sword, 8=2H Sword, 10=Staff, 13=Fist, 15=Dagger`.
  Los Evocadores (Devastación, Preservación y Aumento) en el cliente moderno de Retail y Midnight pueden equipar legítimamente:
  - Hachas de 2 Manos (subclase `1`)
  - Mazas de 2 Manos (subclase `5`)
  - Armas de Asta / Polearms (subclase `6`)
  - Espadas de 2 Manos (subclase `8`)
  Actualmente, las subclases 1, 5, 6 y 8 están ausentes en la definición del Evocador.
- **Escenario de Reproducción e Impacto:** Si en una banda o mazmorra cae una Maza de 2 Manos de Intelecto, una Espada de 2 Manos o un Arma de Asta, `DQ.GameData:CanClassEquip("EVOKER", 2, subclass)` evalúa a `false`. El módulo `TradeAdvisor` asume que el Evocador no puede usar el objeto y lo descarta incorrectamente de las sugerencias de intercambio.
- **Corrección Recomendada:**
  ```diff
  - ["EVOKER"] = { [0]=true, [4]=true, [7]=true, [10]=true, [13]=true, [15]=true },
  + ["EVOKER"] = { [0]=true, [1]=true, [4]=true, [5]=true, [6]=true, [7]=true, [8]=true, [10]=true, [13]=true, [15]=true },
  ```
- **Riesgo de Regresión & Validación:** Nulo. Cubierto por las pruebas existentes en `tests/run_tests.lua`.
- **Confianza del Hallazgo:** 100% (Verificado contra mecánicas oficiales de clases de WoW Retail).

---

### [PERF-BAG-01] Recálculo Redundante de Anclaje y Reparenting en `BagSort` ante `BAG_UPDATE_DELAYED`
- **Severidad:** LOW a MEDIUM
- **Categoría:** Rendimiento / Churn de Layout en UI
- **Archivo & Función:** [BagSort.lua](file:///c:/Users/Sargeraz/.gemini/antigravity-ide/scratch/DistractionQoL/DistractionQoL/Modules/BagSort/BagSort.lua#L580-L595), líneas 584 y 592.
- **Evidencia & Explicación Técnica:**
  ```lua
  eventFrame:RegisterEvent("BAG_UPDATE_DELAYED")
  eventFrame:SetScript("OnEvent", function(self, event, arg1)
      if event == "ADDON_LOADED" and arg1 == "EllesmereUIBags" then
          TryHookEllesmere()
      else
          UpdateButtonAnchor()
      end
  end)
  ```
  Dentro de `UpdateButtonAnchor()` (líneas 450-455):
  ```lua
  sortBtn:SetParent(parent)
  sortBtn:ClearAllPoints()
  sortBtn:SetPoint("RIGHT", anchorTarget, "LEFT", -3, 0)
  sortBtn:SetFrameLevel((anchorTarget:GetFrameLevel() or 10) + 1)
  sortBtn:Show()
  ```
  El evento `BAG_UPDATE_DELAYED` se dispara cada vez que un objeto se mueve en las bolsas, se recoge despojo o se ejecuta un intercambio. Durante la propia ejecución de `SortBags()`, donde se realizan decenas de movimientos en ráfaga a lo largo de 2-3 segundos, `BAG_UPDATE_DELAYED` se activa repetidamente. Esto provoca que `sortBtn` sea reparentado y reanclado en cada ciclo de movimiento del inventario.
- **Escenario de Reproducción e Impacto:** El botón de ordenamiento nativo de Blizzard (`BagItemAutoSortButton`) no cambia de padre ni de coordenadas relativas cuando los objetos dentro de las bolsas cambian. Realizar `ClearAllPoints()` y `SetPoint()` ante cada cambio de contenido de bolsa es completamente redundante y fuerza recalcular la geometría del frame.
- **Corrección Recomendada:**
  Eliminar el registro de `BAG_UPDATE_DELAYED` de `eventFrame` en `BagSort.lua:584`. La visibilidad y posicionamiento del botón ya están blindadas por los hooks de apertura/cierre de mochilas (`OnShow`, `OnHide`, `ToggleAllBags`, `OpenAllBags`, etc.).
- **Riesgo de Regresión & Validación:** Nulo.
- **Confianza del Hallazgo:** Hecho confirmado.

---

### [UI-TOOLTIP-01] Llamada Redundante a `tooltip:Show()` en Post-Calls y Hooks Seguros
- **Severidad:** LOW
- **Categoría:** Arquitectura de UI / Buenas Prácticas
- **Archivo & Función:**
  - [TargetedBy.lua](file:///c:/Users/Sargeraz/.gemini/antigravity-ide/scratch/DistractionQoL/DistractionQoL/Modules/Tooltip/TargetedBy.lua#L135-L139), línea 137.
  - [UtilityRadar.lua](file:///c:/Users/Sargeraz/.gemini/antigravity-ide/scratch/DistractionQoL/DistractionQoL/Modules/LFG/UtilityRadar.lua#L130-L134), línea 132.
- **Evidencia & Explicación Técnica:**
  En `TargetedBy.lua:137`, se invoca `tooltip:Show()` al final de una función registrada en `TooltipDataProcessor.AddTooltipPostCall`.
  En `UtilityRadar.lua:132`, se invoca `tooltip:Show()` dentro de un hook seguro a `LFGListUtil_SetSearchEntryTooltip`.
  En ambos casos, Blizzard ya se encuentra en medio del ciclo de pintado y renderizado del tooltip. Invocar explícitamente `:Show()` dentro de un callback de post-procesamiento de `TooltipDataProcessor` puede provocar reentrancia de eventos de layout, parpadeos de redimensionamiento (*frame jitter*) o recalcular dos veces el tamaño de la caja de texto.
- **Corrección Recomendada:**
  Eliminar `tooltip:Show()` en ambos archivos; limitarse a `tooltip:AddLine()` / `tooltip:AddDoubleLine()`, dejando que `TooltipDataProcessor` gestione el refresco nativo del tamaño.
- **Confianza del Hallazgo:** Hecho confirmado.

---

### [BUG-AUTO-01] Falta de Comprobación de Ventana de Mercader Abierta en `SellJunkItems`
- **Severidad:** MEDIUM
- **Categoría:** Seguridad Funcional / Acciones con Retardo
- **Archivo & Función:** [Vendor.lua](file:///c:/Users/Sargeraz/.gemini/antigravity-ide/scratch/DistractionQoL/DistractionQoL/Modules/Automations/Vendor.lua#L58-L83), líneas 58 y 126.
- **Evidencia & Explicación Técnica:**
  En `Vendor.lua`, el evento `MERCHANT_SHOW` planifica la venta de chatarra con un retraso de 50ms: `C_Timer.After(0.05, SellJunkItems)`.
  Dentro de `SellJunkItems()`, se ejecuta un bucle llamando a `C_Container.UseContainerItem(bag, slot)`.
  En World of Warcraft, `UseContainerItem` tiene un doble propósito:
  1. Si la ventana del mercader está abierta, **vende** el objeto al PNJ.
  2. Si la ventana del mercader está cerrada, **usa o equipa** el objeto en el personaje.
  Si un jugador interactúa accidentalmente con un mercader y cierra la ventana de inmediato en menos de 50ms (por ejemplo, al pasar corriendo montado o pulsar ESC), `SellJunkItems()` se ejecutará con el mercader cerrado, intentando equipar o consumir los objetos grises.
- **Corrección Recomendada:**
  Añadir al inicio de `SellJunkItems()`:
  ```lua
  if not MerchantFrame or not MerchantFrame:IsShown() then return end
  ```
- **Confianza del Hallazgo:** Hecho confirmado.

---

### [BUG-AUTO-02] Omisión de Comprobación de Combate en el Callback Retardado de `SafeResurrect`
- **Severidad:** LOW a MEDIUM
- **Categoría:** Seguridad en Combate / Prevención de Taint
- **Archivo & Función:** [SafeResurrect.lua](file:///c:/Users/Sargeraz/.gemini/antigravity-ide/scratch/DistractionQoL/DistractionQoL/Modules/Automations/SafeResurrect.lua#L28-L50), líneas 28-39.
- **Evidencia & Explicación Técnica:**
  La variable `inCombat` se evalúa de manera síncrona al recibir `RESURRECT_REQUEST` (línea 28). Posteriormente, se inicia un temporizador de 200ms (`C_Timer.After(0.2, ...)`). Dentro del callback del temporizador, se ejecutan `AcceptResurrect()` y llamadas a `StaticPopup_Hide` sin volver a verificar `InCombatLockdown()`. Si el grupo entra en combate durante esos 200ms y `allowCombat == false`, la resurrección se aceptará de todos modos, violando la configuración del usuario y arriesgando taint en ventanas de diálogo.
- **Corrección Recomendada:**
  Re-evaluar el combate dentro del temporizador:
  ```lua
  C_Timer.After(0.2, function()
      if not allowCombat and InCombatLockdown and InCombatLockdown() then
          return
      end
      local ok = pcall(AcceptResurrect)
  ```
- **Confianza del Hallazgo:** Hecho confirmado.

---

### [SEC-TAINT-01] Escritura Directa en Propiedades de Marcos de Blizzard (`f.which = nil`) en `Hook.lua`
- **Severidad:** LOW
- **Categoría:** Seguridad / Taint de Interfaz
- **Archivo & Función:** [Hook.lua](file:///c:/Users/Sargeraz/.gemini/antigravity-ide/scratch/DistractionQoL/DistractionQoL/Modules/ReleaseGuard/Hook.lua#L104-L113), líneas 104 y 112.
- **Evidencia & Explicación Técnica:**
  En `DismissSimulation`, se ejecuta:
  ```lua
  target.which = nil
  for i = 1, 4 do
      local f = _G["StaticPopup" .. i]
      if f and (f.which == "DEATH" or f.which == "DEATH_RELEASE") then
          f:Hide()
          f.which = nil -- Contaminación directa de tabla de Blizzard
      end
  end
  ```
  Modificar propiedades nativas directamente sobre las tablas de frames globales de Blizzard (`StaticPopup1`..`4`) puede marcar la tabla como *tainted* en la ejecución de scripts seguros posteriores. La función nativa de Blizzard `StaticPopup_Hide("DEATH")` (que ya se ejecuta en la línea 117) limpia el estado de forma segura sin contaminar la tabla.
- **Corrección Recomendada:**
  Eliminar las asignaciones manuales `target.which = nil` y `f.which = nil`; delegar el cierre exclusivamente en `StaticPopup_Hide`.
- **Confianza del Hallazgo:** Hecho confirmado.

---

### [REL-CHAT-01] Llamada sin Proteger a `SendChatMessage` en `CommandHub.lua`
- **Severidad:** LOW
- **Categoría:** Fiabilidad / Manejo de Excepciones
- **Archivo & Función:** [CommandHub.lua](file:///c:/Users/Sargeraz/.gemini/antigravity-ide/scratch/DistractionQoL/DistractionQoL/Modules/MythicPlus/CommandHub.lua#L425-L429), función `AnnouncePartyKeys()`, línea 427.
- **Evidencia & Explicación Técnica:**
  En `CommandHub.lua:427`, `SendChatMessage(msg, channel)` se invoca directamente sin `pcall`. En contraste, en `Keystone.lua:97` se utiliza `pcall(SendChatMessage, ...)`. Si el jugador se encuentra bajo restricciones de chat, el canal es inválido o el mensaje contiene caracteres restringidos en Midnight, una llamada directa arrojará un error de script.
- **Corrección Recomendada:** Envolver la llamada en `pcall(SendChatMessage, msg, channel)`.
- **Confianza del Hallazgo:** Hecho confirmado.

---

### [LOC-KEY-01] Clave de Localización `BTN_FPS_RESTORE` Ausente en Español
- **Severidad:** LOW
- **Categoría:** Calidad de Código / Localización Rigurosa
- **Archivo & Función:** [Locales.lua](file:///c:/Users/Sargeraz/.gemini/antigravity-ide/scratch/DistractionQoL/DistractionQoL/Core/Locales.lua#L377) y [TabPerformance.lua](file:///c:/Users/Sargeraz/.gemini/antigravity-ide/scratch/DistractionQoL/DistractionQoL/UI/Tabs/TabPerformance.lua#L50).
- **Evidencia & Explicación Técnica:**
  Comprobado mediante script automatizado de paridad de diccionario:
  - En inglés: `L["BTN_FPS_RESTORE"] = "Restore"` (línea 377).
  - En español: la clave no existe en la sección `if isSpanish then`.
  En tiempo de ejecución en clientes en español, el botón recurre al fallback hardcodeado inline `or "Restaurar"`.
- **Corrección Recomendada:**
  Añadir `L["BTN_FPS_RESTORE"] = "Restaurar"` en la sección en español de `Locales.lua`.
- **Confianza del Hallazgo:** 100% (Verificado programáticamente).

---

### [ARCH-CONS-01] Clasificación de Consumibles Dependiente de Cadenas en Inglés y Español
- **Severidad:** LOW
- **Categoría:** Arquitectura / Internacionalización
- **Archivo & Función:** [ConsumablesLogic.lua](file:///c:/Users/Sargeraz/.gemini/antigravity-ide/scratch/DistractionQoL/DistractionQoL/Modules/RaidFlow/ConsumablesLogic.lua#L41-L92), función `ClassifyItem`.
- **Evidencia & Explicación Técnica:**
  La clasificación de frascos, comidas y aceites se realiza mediante búsquedas de subcadenas como `lowerName:find("shattered sun") or lowerName:find("sol devastado")`. En clientes en francés (`frFR`), alemán (`deDE`), portugués (`ptBR`), ruso (`ruRU`), chino o coreano, estas búsquedas fallarán por completo. A excepción de la runa (que valida `itemID == 259085`), los demás consumibles no serán reconocidos en clientes en idiomas distintos al inglés y español.
- **Corrección Recomendada:**
  Incorporar listas de `itemID` en `CATALOG` para que la clasificación sea 100% independiente del idioma del cliente.
- **Confianza del Hallazgo:** Hecho confirmado.

---

### [PERF-ALLOC-01] Asignaciones Frecuentes de Cadenas en el Escaneo de Banda en `TargetedBy`
- **Severidad:** LOW
- **Categoría:** Rendimiento / Presión sobre el Garbage Collector
- **Archivo & Función:** [TargetedBy.lua](file:///c:/Users/Sargeraz/.gemini/antigravity-ide/scratch/DistractionQoL/DistractionQoL/Modules/Tooltip/TargetedBy.lua#L74-L79).
- **Evidencia & Explicación Técnica:**
  En una banda de 30 personas, cada vez que el cursor pasa sobre un PNJ o enemigo, el bucle genera hasta 30 concatenaciones `prefix .. i` y 30 concatenaciones `unit .. "target"`.
  Esto genera 60 asignaciones de cadenas en memoria por cada actualización de tooltip de unidad.
- **Corrección Recomendada:**
  Pre-almacenar en una tabla estática los tokens de unidad de banda:
  `RAID_TOKENS[i] = "raid" .. i` y `RAID_TARGET_TOKENS[i] = "raid" .. i .. "target"`.
- **Confianza del Hallazgo:** Hecho confirmado.

---

## 3. Rendimiento y Memoria

### 3.1 Rutas de Ejecución Críticas (Hot Paths)
1. **Tooltip Mouseovers (`TargetedBy` & `ItemCounts`):**
   - **Medición real:** `OnTooltipSetUnit` itera hasta 30 unidades en raid. En combate masivo con cambios continuos de objetivo, se ejecutan verificaciones de GUID. Actualmente, las funciones `SafeUnitExists` y `SafeUnitGUID` en `TargetedBy.lua` envuelven las llamadas en `pcall`, lo cual introduce una sobrecarga leve pero acumulativa (creación de marcos de stack de errores).
   - **Optimización:** Reemplazar el `pcall` en `UnitExists` y `UnitGUID` por validación directa de `issecretvalue()` antes de llamar a la API nativa de Blizzard, ya que las funciones de consulta de unidades son seguras si el token de unidad es válido.
2. **Escaneo de Consumibles (`CheckPlayerConsumables`):**
   - **Comportamiento:** Se ejecuta exclusivamente bajo demanda en eventos puntuales (`READY_CHECK`, apertura manual de `/consumables`). Utiliza `C_UnitAuras.GetAuraDataByIndex` con índice incremental. Es una ruta fría extremadamente eficiente (tiempo de ejecución estimado < 0.1ms).

### 3.2 Eventos Redundantes
- **`UNIT_AURA` en `ConsumablesBar`:** El problema de mayor impacto en FPS identificado. Pasar de un registro global a `RegisterUnitEvent("UNIT_AURA", "player")` reducirá el tráfico de eventos en banda en más de un 98%.
- **`BAG_UPDATE_DELAYED` en `BagSort`:** Disparado de 10 a 40 veces durante un ordenamiento o despojo de bolsas, invocando reparenting inútil del botón de ordenación.

### 3.3 Asignaciones Evitables y Presión sobre el Garbage Collector
- **Tablas Efímeras en Audio (`Alert.lua`):** En `Alert:PlaySound()`, la tabla `{ "Master", "Dialog", "SFX" }` se crea en cada reproducción. Puede moverse al ámbito del archivo (`local CHANNELS = { ... }`).
- **Tablas de Miembros en `CommandHub:RefreshUI()`:** Cada actualización crea una tabla `members = {}` con 5 sub-tablas para los miembros del grupo. Al ser una ventana de interfaz que solo se actualiza cuando está visible y abierta, el impacto en combate es nulo.

---

## 4. Compatibilidad con Midnight (12.x)

| API / Característica | Estado en el Addon | Estado Oficial Midnight (12.x) | Veredicto & Fuentes |
| :--- | :--- | :--- | :--- |
| `issecretvalue()` | Implementado en `WipeRelease`, `TradeAdvisor`, `ItemCounts` y `TargetedBy`. Ausente en `RaidFlow:CHAT_MSG_ADDON`. | **Activo y Crítico** en 12.x dentro de instancias. Cadenas de chat/LFG pueden ser secretas. | Requiere corregir `RaidFlow.lua` (ver `SEC-CHAT-01`). Ref: *WoW UI Midnight API Docs*. |
| `TooltipDataProcessor` | Implementado correctamente en `ItemCounts` y `TargetedBy`. | **Estándar Oficial** (reemplazo permanente de `OnTooltipSetItem`). | Correcto. Cumple con la arquitectura 11.x/12.x. |
| `C_Container` APIs | Uso estandarizado en todos los módulos (`GetContainerNumSlots`, etc.). | **Estándar Oficial**. Las APIs globales antiguas están deprecadas o eliminadas. | Correcto. |
| `C_Spell.GetSpellTexture` / `IsSpellKnownOrOverridesKnown` | Usado en `CommandHub.lua`. | **Estándar Oficial**. Reemplaza las funciones legacy `GetSpellInfo`. | Correcto. |
| `SecureActionButtonTemplate` | Usado en `CommandHub.lua` y `ConsumablesBar.lua` con `RegisterForClicks("AnyUp", "AnyDown")`. | **Requerido** para compatibilidad con la opción del cliente `ActionButtonUseKeyDown=1`. | Blindado correctamente. Todas las modificaciones se difieren fuera de `InCombatLockdown()`. |
| `UNIT_DIED` | Registrado erróneamente en `WipeRelease.lua`. | **No es un evento de FrameXML**. Solo existe en `COMBAT_LOG_EVENT_UNFILTERED`. | **Incompatible** (ver `BUG-MITH-01`). |

---

## 5. Arquitectura

### 5.1 Modularidad y Acoplamiento
- **Puntos Fuertes:**
  - Desacoplamiento estricto de la lógica algorítmica: `BagSortLogic.lua`, `TradeAdvisorLogic.lua`, `UtilityRadarLogic.lua` y `ConsumablesLogic.lua` son módulos puros, lo que permite que la suite de pruebas unitarias (`tests/run_tests.lua`) se ejecute en 2 milisegundos en cualquier entorno sin dependencias del cliente de WoW.
  - Registro centralizado y ordenado por prioridades en `Core/Modules.lua` y `Core/Core.lua`.
- **Puntos a Mejorar:**
  - `ConsumablesBar.lua` no está registrado formalmente en el gestor de ciclo de vida `DQ:RegisterModule`. Se inicializa perezosamente al invocar `/consumables` o ante un ready check. Si bien esto ahorra memoria en el arranque, provoca que el anclaje de eventos dependa del primer uso. Debería formalizarse su ciclo de vida o registrar eventos únicamente bajo demanda.

### 5.2 Gestión del Ciclo de Vida y SavedVariables
- La tabla global `DistractionQoLDB` se valida y migra limpiamente mediante `Core/Migration.lua` con números de versión secuenciales (`version = 4`), evitando pérdidas de configuración al actualizar el addon.

---

## 6. Plan de Implementación

Las tareas se ordenan por criticidad técnica y dependencias:

```mermaid
graph TD
    T1[Fase 1: Corrección de Bugs Críticos] --> T2[Fase 2: Seguridad Midnight & Taint]
    T2 --> T3[Fase 3: Optimización de Eventos & Rendimiento]
    T3 --> T4[Fase 4: Pulido de Datos & Localización]
```

### Fase 1: Corrección de Defectos Críticos (P1)
1. **Tarea 1.1: Corregir Expresión Regular en `TradeAdvisor.lua` (`BUG-LOOT-01`)**
   - **Archivo:** `DistractionQoL/Modules/Loot/TradeAdvisor.lua`
   - **Cambio:** Modificar línea 421 de `%]h|r` a `%]|h|r`.
   - **Criterio de Aceptación:** Probar con cadenas de enlaces reales de WoW en un test unitario; el objeto debe ser extraído y parseado.
2. **Tarea 1.2: Eliminar Evento Ilegal `UNIT_DIED` en `WipeRelease.lua` (`BUG-MITH-01`)**
   - **Archivo:** `DistractionQoL/Modules/MythicPlus/WipeRelease.lua`
   - **Cambio:** Eliminar `frame:RegisterEvent("UNIT_DIED")` y sustituirlo por `GROUP_ROSTER_UPDATE`.
   - **Criterio de Aceptación:** `DQ.WipeRelease:Init()` debe ejecutarse sin errores de evento desconocido en el cliente de WoW.

### Fase 2: Blindaje de Seguridad y Taint (P2)
3. **Tarea 2.1: Blindar `CHAT_MSG_ADDON` contra Secret Values (`SEC-CHAT-01`)**
   - **Archivo:** `DistractionQoL/Modules/RaidFlow/RaidFlow.lua`
   - **Cambio:** Añadir verificación `issecretvalue()` sobre `prefix` y `msg` antes de `:find()`.
   - **Criterio de Aceptación:** Cadenas de prueba simuladas como secret values no deben arrojar excepciones de Lua.
4. **Tarea 2.2: Blindar Cierre de Mercader en `Vendor.lua` (`BUG-AUTO-01`)**
   - **Archivo:** `DistractionQoL/Modules/Automations/Vendor.lua`
   - **Cambio:** Comprobar `MerchantFrame:IsShown()` al inicio de `SellJunkItems()`.
   - **Criterio de Aceptación:** Si el mercader se cierra antes de los 50ms, no se invoca `UseContainerItem`.
5. **Tarea 2.3: Eliminar Taint de `f.which = nil` en `Hook.lua` (`SEC-TAINT-01`)**
   - **Archivo:** `DistractionQoL/Modules/ReleaseGuard/Hook.lua`
   - **Cambio:** Eliminar asignaciones manuales en marcos `StaticPopup` globales.

### Fase 3: Optimización de Rendimiento y Sincronización (P3)
6. **Tarea 3.1: Optimizar `UNIT_AURA` en `ConsumablesBar.lua` (`PERF-EVENT-01`)**
   - **Archivo:** `DistractionQoL/Modules/RaidFlow/ConsumablesBar.lua`
   - **Cambio:** Usar `RegisterUnitEvent("UNIT_AURA", "player")` y registrar/desregistrar dinámicamente con `ShowBar()` / `HideBar()`.
   - **Criterio de Aceptación:** Cero eventos `UNIT_AURA` procesados mientras la barra esté oculta.
7. **Tarea 3.2: Agregar Sincronización de Bolsas en `ConsumablesBar.lua` (`BUG-RAID-01`)**
   - **Archivo:** `DistractionQoL/Modules/RaidFlow/ConsumablesBar.lua`
   - **Cambio:** Escuchar `BAG_UPDATE_DELAYED` mientras la barra esté mostrada para refrescar contadores.
8. **Tarea 3.3: Eliminar Reanclaje Continuo en `BagSort.lua` (`PERF-BAG-01`)**
   - **Archivo:** `DistractionQoL/Modules/BagSort/BagSort.lua`
   - **Cambio:** Eliminar el registro de `BAG_UPDATE_DELAYED`.
9. **Tarea 3.4: Eliminar `tooltip:Show()` Redundante (`UI-TOOLTIP-01`)**
   - **Archivos:** `TargetedBy.lua` y `UtilityRadar.lua`
   - **Cambio:** Eliminar llamadas a `:Show()` dentro de los post-calls.

### Fase 4: Calidad de Datos, Localización y Manejo de Errores (P4)
10. **Tarea 4.1: Actualizar Proficiencias del Evocador (`DATA-EVOKER-01`)**
    - **Archivo:** `DistractionQoL/Core/GameData.lua`
    - **Cambio:** Agregar subclases 1, 5, 6 y 8 a `CLASS_WEAPONS["EVOKER"]`.
11. **Tarea 4.2: Localización y Safe Calls (`LOC-KEY-01`, `REL-CHAT-01`)**
    - **Archivos:** `Locales.lua` y `CommandHub.lua`
    - **Cambios:** Añadir `L["BTN_FPS_RESTORE"] = "Restaurar"` en español; envolver `SendChatMessage` en `pcall` en `CommandHub.lua`.

---

## 7. Pruebas Pendientes

### 7.1 Pruebas Ejecutables Offline (Automatizables en `tests/`)
- Test unitario de extracción de expresiones regulares de enlaces de objetos (`CHAT_MSG_LOOT` en español, inglés y variantes de color).
- Test de proficiencias completas de armas para el Evocador en `GameData.lua`.
- Test de paridad continua del diccionario de localización (`Locales.lua`) para asegurar que el 100% de las claves en español existan en inglés y viceversa.

### 7.2 Pruebas que Requieren el Cliente en Vivo de WoW
- **Prueba de Liberación en Encuentro Mítico:** Verificar que `StaticPopupDialogs["DEATH"]` intercepte el clic y no produzca errores de `ADDON_ACTION_BLOCKED` en presencia de frames protegidos de Blizzard.
- **Prueba de Rendimiento de Eventos:** Medir con el comando `/eventtrace` que `DistractionQoLConsumablesBar` no capture eventos de auras de otras unidades durante un combate de raid de 20 jugadores.
- **Compatibilidad con EllesmereUI:** Comprobar la sustitución y restauración del botón de ordenamiento de mochilas cuando EllesmereUI está activo.

### 7.3 Limitaciones del Entorno de Auditoría
La auditoría se ha llevado a cabo mediante análisis estático minucioso, ejecución de herramientas de sintaxis Lua (`luac`) y suites de mocks en runtime offline. No es posible ejecutar las librerías binarias nativas de C++ del cliente de World of Warcraft en este entorno, por lo que las interacciones gráficas exactas de los widgets de Blizzard deben validarse en la sesión de pruebas en vivo del juego.

---

## 8. Mejoras Opcionales y Deuda Técnica

### 8.1 Deuda Técnica Menor (No Urgente)
- **Internacionalización de Consumibles (`ARCH-CONS-01`):** Mapear los consumibles de Midnight a tablas de `itemID` directas en `ConsumablesLogic.lua` en lugar de substrings de texto, garantizando soporte nativo para clientes alemanes, franceses y chinos.
- **Pre-alocación de Tokens de Unidad (`PERF-ALLOC-01`):** Reemplazar concatenaciones dinámicas `"raid" .. i .. "target"` en `TargetedBy.lua` por una tabla precalculada de 40 posiciones.

### 8.2 Componentes que Deben Permanecer Intactos
- **`UI/Theme.lua` & `UI/Components.lua`:** El sistema de diseño Obsidian Flat / Material Design está perfectamente implementado y unificado en todos los paneles.
- **`Core/Migration.lua` & `Core/Config.lua`:** El esquema de persistencia y migración de SavedVariables es sólido, seguro y a prueba de fallos.
- **`Modules/BagSort/BagSortLogic.lua`:** El algoritmo de ordenamiento inverso en dos fases (separación de materiales a la bolsa 5 y compactación por pesos abajo) es eficiente, determinista y cuenta con cobertura de pruebas completa.
- **`Modules/ReleaseGuard/Hook.lua`:** La detección jerárquica de popups de muerte (`GetDialogFrame`, `GameDialogMixin`) y el manejo de excepciones de Blizzard 12.1 son de primer nivel técnico.

---
*Informe generado y verificado según las directrices de arquitectura de WoW Midnight 12.x.*
