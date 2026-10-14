-- Locales.lua
-- Multi-language localization dictionary for DistractionQoL
-- Automatically detects client language (esES / esMX vs English fallback)

local addonName, DQ = ...

local locale = GetLocale and GetLocale() or "enUS"
local isSpanish = (locale == "esES" or locale == "esMX")

local L = {}

if isSpanish then
    -- ==========================================================
    -- SPANISH (esES / esMX)
    -- ==========================================================
    L["ADDON_TITLE"] = "|cff00e5ffDistractionQoL|r"
    L["ADDON_SUBTITLE"] = "Kit Ultraligero de Calidad de Vida & Rendimiento para Raiders"

    -- Tabs
    L["TAB_RELEASE"] = "Liberación"
    L["TAB_RAIDFLOW"] = "Flujo de Raid"
    L["TAB_AUTOMATION"] = "Automatizaciones"
    L["TAB_PERFORMANCE"] = "Rendimiento"

    -- Section 1: Anti-Release
    L["SECTION_RELEASE_TITLE"] = "Protección Anti-Liberar (Spirit Release Guard)"
    L["SECTION_RELEASE_DESC"] = "Evita liberar espíritu por accidente en combate. Mantén SHIFT para liberar."
    L["DUNGEONS"] = "Mazmorras y Delves (M+ / Profundidades / Heroicas)"
    L["RAIDS"] = "Bandas (Raid - General)"
    L["NORMAL"] = "Dificultad Normal"
    L["HEROIC"] = "Dificultad Heroica"
    L["MYTHIC"] = "Dificultad Mítica"
    L["OPEN_WORLD"] = "Mundo Abierto"
    L["SOUND_ENABLED"] = "Sonido de Alerta de Liberación (Bane.ogg)"

    -- Section 2: Raid Flow & Anti-Distraction
    L["SECTION_RAIDFLOW_TITLE"] = "Flujo de Banda & Preparación (Anti-Distracción)"
    L["SECTION_RAIDFLOW_DESC"] = "Herramientas dirigidas por eventos para no perder llamadas mientras estás distraído."
    L["FLASH_TASKBAR"] = "Parpadear ventana en barra de tareas en Ready Check / Pull"
    L["READY_CHECK_SOUND"] = "Alerta sonora por canal Master en Ready Check"
    L["CHECK_CONSUMABLES"] = "Avisar si faltan consumibles (Comida, Frasco, Runas, Arma) en Ready Check"

    -- Section 3: Automations
    L["SECTION_AUTO_TITLE"] = "Automatizaciones de Calidad de Vida"
    L["SECTION_AUTO_DESC"] = "Acciones instantáneas sin spam de eventos ni sobrecoste de CPU."
    L["AUTO_RES"] = "Auto-aceptar Resurrección en wipes"
    L["AUTO_RES_COMBAT"] = "Permitir auto-aceptar en combate (Battle Rez)"
    L["AUTO_REPAIR"] = "Auto-reparar equipo al interactuar con mercader"
    L["GUILD_REPAIR"] = "Priorizar fondos de hermandad para reparaciones"
    L["AUTO_SELL_JUNK"] = "Auto-vender basura gris en mercader"
    L["AUTO_SKIP_MOVIES"] = "Auto-saltar cinemáticas ya vistas en bosses"
    L["BLOCK_DUELS"] = "Bloquear invitaciones a duelos dentro de mazmorras/raid"
    L["FAST_LOOT"] = "Despojo rápido instantáneo (Fast Loot a 0ms)"
    L["BAG_SORT_BUTTON"] = "Mostrar botón de Orden Inverso en la cabecera de las bolsas"
    L["OVERRIDE_ELLESMERE_SORT"] = "EllesmereUI: Reemplazar su botón de ordenar con DistractionQoL"
    L["BTN_SORT_BAGS"] = "Ordenar Bolsas Ahora"

    -- Section 4: Performance & FPS Optimizer
    L["SECTION_FPS_TITLE"] = "Optimización Gráfica & Rendimiento en Raid"
    L["FPS_STATUS_LABEL"] = "Modo Gráfico: %s"
    L["FPS_STATUS_OPT"] = "|cff00ff00MÁXIMO FPS ACTIVO|r"
    L["FPS_STATUS_NORMAL"] = "|cffaaaaaaOriginal / Estándar|r"
    L["FPS_BACKUP_LABEL"] = "Copia guardada: %s"
    L["FPS_BACKUP_SAVED"] = "|cff00ff00Sí (%d opciones)|r"
    L["FPS_BACKUP_NONE"] = "|cffffaa00No (automática al optimizar)|r"
    L["FPS_NOTE"] = "|cff00e5ff* Mantiene activas las proyecciones en el suelo para ver todas las áreas de mecánicas.|r"
    L["CLEAN_LOADING_GC"] = "Limpieza de memoria en pantallas de carga (evita micro-tirones en combate)"
    L["BTN_FPS_SAVE"] = "Guardar Actual"
    L["BTN_FPS_OPT"] = "Optimizar FPS"
    L["BTN_FPS_RESTORE"] = "Restaurar"

    -- Bottom Buttons
    L["BTN_MUTE"] = "Mutear Sonido"
    L["BTN_UNMUTE"] = "Activar Sonido"
    L["BTN_TEST"] = "Probar Alerta"
    L["BTN_SIM"] = "Simular Muerte"
    L["BTN_CLOSE"] = "Cerrar"
    L["BTN_OPEN_CONFIG"] = "Abrir Configuración"

    -- In-Game Messages
    L["ALERT_TITLE"] = "¡BURRO, SONSO, NO LIBERES!"
    L["ALERT_SUBTEXT"] = "¡Mantén presionado SHIFT y haz clic para liberar!"
    L["TOOLTIP_TITLE"] = "|cff00e5ffDistractionQoL|r"
    L["TOOLTIP_LINE1"] = "Mantén presionado |cffffcc00SHIFT|r para liberar."
    L["TOOLTIP_LINE2"] = "|cffff5555(¡No liberes por accidente!)|r"

    L["CONFIG_TITLE"] = "|cff00e5ffDistractionQoL|r"
    L["SETTINGS_DESC"] = "Herramientas de QoL y rendimiento ultraligero para Raiders.\nEscribe |cffffcc00/qol|r (o |cffffcc00/burro|r) para abrir el panel rápido:"

    L["MSG_LOADED"] = "Addon cargado (WoW 12.1.5 Midnight). Escribe |cffffcc00/qol|r (o |cffffcc00/burro|r) para abrir el panel."
    L["MSG_TESTING"] = "Probando aviso visual gigante y audio de alerta..."
    L["MSG_SIM_START"] = "|cffffcc00Modo simulación activo:|r Ventana de liberación abierta.\n1. Un clic normal será bloqueado y activará la alerta.\n2. Mantén presionado SHIFT y haz clic para cerrar."
    L["MSG_SIM_END"] = "Simulación finalizada correctamente (SHIFT+Clic detectado)."
    L["MSG_SOUND_PLAY"] = "Reproduciendo audio de alerta..."
    L["MSG_SOUND_HINT"] = "|cffffcc00Aviso:|r Si el sonido no suena, escribe |cffffcc00/reload|r o revisa el volumen del juego."
    L["MSG_SOUND_MUTED_HINT"] = "|cffff3333El sonido de alerta está silenciado (MUTE).|r Escribe |cffffcc00/qol mute|r o usa el panel para reactivarlo."
    L["MSG_MUTE_ON"] = "Sonido de alerta: |cffff3333SILENCIADO (MUTE)|r"
    L["MSG_MUTE_OFF"] = "Sonido de alerta: |cff00ff00ACTIVADO|r"
    L["MSG_STATUS"] = "Estado de protección: %s (Instancia: %s, Tipo: %s)"
    L["STATUS_ACTIVE"] = "|cff00ff00ACTIVADA|r"
    L["STATUS_INACTIVE"] = "|cffff3333DESACTIVADA|r"
    L["MSG_AUTO_RES_ACCEPTED"] = "Resurrección de |cffffcc00%s|r aceptada automáticamente."
    L["MSG_AUTO_RES_BLOCKED_COMBAT"] = "Resurrección de |cffffcc00%s|r recibida, pero omitida por estar en combate (Battle Rez)."
    L["MSG_FPS_SAVED"] = "Configuración gráfica actual guardada como copia de respaldo (%d opciones)."
    L["MSG_FPS_OPTIMIZED"] = "¡Opciones de Máximo FPS para Raid aplicadas con éxito! (%d ajustes optimizados)."
    L["MSG_FPS_RESTORED"] = "Configuración gráfica original restaurada con éxito (%d ajustes restablecidos)."
    L["MSG_FPS_NO_BACKUP"] = "No hay una copia de respaldo guardada para restaurar."

    -- Consumables & Automation Messages
    L["MSG_MISSING_CONSUMABLES"] = "|cffff3333[¡Aviso de Consumibles!]|r Te falta: %s"
    L["FOOD_BUFF"] = "Comida (Well Fed)"
    L["FLASK_BUFF"] = "Frasco / Poción"
    L["RUNE_BUFF"] = "Runa de Aumento"
    L["WEAPON_BUFF"] = "Encantamiento/Aceite de Arma"
    L["ALL_BUFFS_OK"] = "|cff00ff00¡Todos los consumibles activos! Listo para el pull.|r"
    L["MSG_REPAIRED"] = "Equipo reparado por: %s"
    L["MSG_GUILD_REPAIRED"] = "Equipo reparado con fondos de hermandad por: %s"
    L["MSG_JUNK_SOLD"] = "Basura gris vendida por: %s (%d objetos)"
    L["MSG_DUEL_BLOCKED"] = "Duelo bloqueado automáticamente por estar en instancia."
    L["MSG_MIGRATION_SUCCESS"] = "¡Migración completada con éxito! Tus opciones de BaneBurroReminder han sido transferidas a DistractionQoL y los datos antiguos fueron depurados."

    -- Bag Sorting Messages
    L["BAG_SORT_TITLE"] = "|cff00e5ffDistractionQoL — Orden Inverso & Materiales|r"
    L["BAG_SORT_DESC_1"] = "|cffffcc001.|r Mueve materiales de profesión a la bolsa de materiales (Bag 5)."
    L["BAG_SORT_DESC_2"] = "|cffffcc002.|r Si sobran materiales, los coloca arriba del todo en bolsas normales."
    L["BAG_SORT_DESC_3"] = "|cffffcc003.|r Resto de objetos (equipo, pociones, etc.) se agrupan abajo del todo."
    L["BAG_SORT_CLICK"] = "|cff00ff00Clic para ordenar inventario.|r"
    L["MSG_BAG_SORT_START"] = "Iniciando ordenamiento inverso de bolsas (%d movimientos)..."
    L["MSG_BAG_SORT_COMPLETE"] = "¡Bolsas organizadas con éxito! Materiales en bolsa de profesión, excedente arriba y resto abajo."
    L["MSG_BAG_SORT_COMBAT"] = "No se pueden ordenar las bolsas durante el combate."
    L["MSG_BAG_SORT_CURSOR"] = "Por favor suelta el objeto del cursor antes de ordenar."
    L["MSG_BAG_SORT_BUSY"] = "Ya hay un ordenamiento de bolsas en progreso..."
    L["MSG_BAG_SORT_ALREADY_SORTED"] = "Las bolsas ya están ordenadas correctamente."
else
    -- ==========================================================
    -- ENGLISH (enUS / enGB and all other locales)
    -- ==========================================================
    L["ADDON_TITLE"] = "|cff00e5ffDistractionQoL|r"
    L["ADDON_SUBTITLE"] = "Ultra-Lightweight Quality-of-Life & Performance Toolkit for Raiders"

    -- Tabs
    L["TAB_RELEASE"] = "Release"
    L["TAB_RAIDFLOW"] = "Raid Flow"
    L["TAB_AUTOMATION"] = "Automation"
    L["TAB_PERFORMANCE"] = "Performance"

    -- Section 1: Anti-Release
    L["SECTION_RELEASE_TITLE"] = "Anti-Release Protection (Spirit Release Guard)"
    L["SECTION_RELEASE_DESC"] = "Prevents accidental spirit release during combat encounters. Hold SHIFT to release."
    L["DUNGEONS"] = "Dungeons & Delves (M+ / Delves / Heroic)"
    L["RAIDS"] = "Raids (Master Toggle)"
    L["NORMAL"] = "Normal Difficulty"
    L["HEROIC"] = "Heroic Difficulty"
    L["MYTHIC"] = "Mythic Difficulty"
    L["OPEN_WORLD"] = "Open World"
    L["SOUND_ENABLED"] = "Release Alert Sound (Bane.ogg)"

    -- Section 2: Raid Flow & Anti-Distraction
    L["SECTION_RAIDFLOW_TITLE"] = "Raid Flow & Readiness (Anti-Distraction)"
    L["SECTION_RAIDFLOW_DESC"] = "Pure event-driven helpers so you never miss calls when focused elsewhere."
    L["FLASH_TASKBAR"] = "Flash Windows taskbar on Ready Check / Pull timers"
    L["READY_CHECK_SOUND"] = "Play distinct audio alert via Master channel on Ready Check"
    L["CHECK_CONSUMABLES"] = "Check missing consumables (Food, Flask, Rune, Weapon) on Ready Check"

    -- Section 3: Automations
    L["SECTION_AUTO_TITLE"] = "Quality-of-Life Automations"
    L["SECTION_AUTO_DESC"] = "Instant, event-driven actions with zero CPU or memory overhead."
    L["AUTO_RES"] = "Auto-accept Resurrection after wipes"
    L["AUTO_RES_COMBAT"] = "Allow auto-accept in combat (Battle Rez)"
    L["AUTO_REPAIR"] = "Auto-repair gear when speaking to vendors"
    L["GUILD_REPAIR"] = "Prioritize guild bank funds for repairs"
    L["AUTO_SELL_JUNK"] = "Auto-sell grey junk items at vendors"
    L["AUTO_SKIP_MOVIES"] = "Auto-skip watched cutscenes and boss cinematics"
    L["BLOCK_DUELS"] = "Block duel challenges while inside instances"
    L["FAST_LOOT"] = "Instant zero-delay fast loot"
    L["BAG_SORT_BUTTON"] = "Show Reverse Sort & Reagent button on bag frame"
    L["OVERRIDE_ELLESMERE_SORT"] = "EllesmereUI: Override its sort button with DistractionQoL"
    L["BTN_SORT_BAGS"] = "Sort Bags Now"

    -- Section 4: Performance & FPS Optimizer
    L["SECTION_FPS_TITLE"] = "Raid Performance & FPS Optimizer"
    L["FPS_STATUS_LABEL"] = "Graphics Mode: %s"
    L["FPS_STATUS_OPT"] = "|cff00ff00MAX FPS ACTIVE|r"
    L["FPS_STATUS_NORMAL"] = "|cffaaaaaaOriginal / Standard|r"
    L["FPS_BACKUP_LABEL"] = "Backup status: %s"
    L["FPS_BACKUP_SAVED"] = "|cff00ff00Yes (%d options)|r"
    L["FPS_BACKUP_NONE"] = "|cffffaa00None (auto on optimize)|r"
    L["FPS_NOTE"] = "|cff00e5ff* Projected textures remain strictly enabled so all boss mechanics stay visible.|r"
    L["CLEAN_LOADING_GC"] = "Clean Lua memory on loading screens (prevents combat micro-stutter)"
    L["BTN_FPS_SAVE"] = "Save Current"
    L["BTN_FPS_OPT"] = "Optimal FPS"
    L["BTN_FPS_RESTORE"] = "Restore"

    -- Bottom Buttons
    L["BTN_MUTE"] = "Mute Sound"
    L["BTN_UNMUTE"] = "Unmute Sound"
    L["BTN_TEST"] = "Test Alert"
    L["BTN_SIM"] = "Simulate Death"
    L["BTN_CLOSE"] = "Close"
    L["BTN_OPEN_CONFIG"] = "Open Configuration"

    -- In-Game Messages
    L["ALERT_TITLE"] = "YOU FOOL, DO NOT RELEASE!"
    L["ALERT_SUBTEXT"] = "Hold SHIFT and click if you intend to release!"
    L["TOOLTIP_TITLE"] = "|cff00e5ffDistractionQoL|r"
    L["TOOLTIP_LINE1"] = "Hold |cffffcc00SHIFT|r to release spirit."
    L["TOOLTIP_LINE2"] = "|cffff5555(Do not release by accident!)|r"

    L["CONFIG_TITLE"] = "|cff00e5ffDistractionQoL|r"
    L["SETTINGS_DESC"] = "Ultra-lightweight QoL and performance toolkit for Raiders.\nType |cffffcc00/qol|r (or |cffffcc00/burro|r) to open the quick config panel:"

    L["MSG_LOADED"] = "Addon loaded (WoW 12.1.5 Midnight). Type |cffffcc00/qol|r (or |cffffcc00/burro|r) to open configuration."
    L["MSG_TESTING"] = "Testing giant visual warning banner and alert audio..."
    L["MSG_SIM_START"] = "|cffffcc00Simulation mode active:|r Release Spirit dialog opened.\n1. Normal click will be blocked and trigger alert.\n2. Hold SHIFT and click to dismiss dialog."
    L["MSG_SIM_END"] = "Simulation completed successfully (SHIFT+Click detected)."
    L["MSG_SOUND_PLAY"] = "Playing alert audio clip..."
    L["MSG_SOUND_HINT"] = "|cffffcc00Notice:|r If you hear no sound, type |cffffcc00/reload|r or check your master game volume."
    L["MSG_SOUND_MUTED_HINT"] = "|cffff3333Alert sound is currently muted.|r Type |cffffcc00/qol mute|r or use the panel to unmute."
    L["MSG_MUTE_ON"] = "Alert sound: |cffff3333MUTED|r"
    L["MSG_MUTE_OFF"] = "Alert sound: |cff00ff00ENABLED|r"
    L["MSG_STATUS"] = "Protection status: %s (Instance: %s, Type: %s)"
    L["STATUS_ACTIVE"] = "|cff00ff00ACTIVE|r"
    L["STATUS_INACTIVE"] = "|cffff3333INACTIVE|r"
    L["MSG_AUTO_RES_ACCEPTED"] = "Resurrection from |cffffcc00%s|r automatically accepted."
    L["MSG_AUTO_RES_BLOCKED_COMBAT"] = "Resurrection from |cffffcc00%s|r received, but skipped due to combat (Battle Rez)."
    L["MSG_FPS_SAVED"] = "Current graphics settings saved as backup (%d options)."
    L["MSG_FPS_OPTIMIZED"] = "Optimal Raid FPS settings applied successfully! (%d settings optimized)."
    L["MSG_FPS_RESTORED"] = "Original graphics settings restored successfully (%d settings reverted)."
    L["MSG_FPS_NO_BACKUP"] = "No saved backup found to restore."

    -- Consumables & Automation Messages
    L["MSG_MISSING_CONSUMABLES"] = "|cffff3333[Consumables Alert]|r Missing: %s"
    L["FOOD_BUFF"] = "Food (Well Fed)"
    L["FLASK_BUFF"] = "Flask / Phial"
    L["RUNE_BUFF"] = "Augment Rune"
    L["WEAPON_BUFF"] = "Weapon Enchant / Oil"
    L["ALL_BUFFS_OK"] = "|cff00ff00All consumables active! Ready for pull.|r"
    L["MSG_REPAIRED"] = "Gear repaired for: %s"
    L["MSG_GUILD_REPAIRED"] = "Gear repaired using guild funds for: %s"
    L["MSG_JUNK_SOLD"] = "Grey junk sold for: %s (%d items)"
    L["MSG_DUEL_BLOCKED"] = "Duel challenge automatically blocked inside instance."
    L["MSG_MIGRATION_SUCCESS"] = "Migration completed successfully! Your settings from BaneBurroReminder have been transferred to DistractionQoL and legacy data was purged."

    -- Bag Sorting Messages
    L["BAG_SORT_TITLE"] = "|cff00e5ffDistractionQoL — Reverse Sort & Reagents|r"
    L["BAG_SORT_DESC_1"] = "|cffffcc001.|r Stashes crafting & profession reagents into the Reagent Bag (Bag 5)."
    L["BAG_SORT_DESC_2"] = "|cffffcc002.|r Places overflow reagents at the very top of normal bags."
    L["BAG_SORT_DESC_3"] = "|cffffcc003.|r Places all other items (gear, consumables, etc.) at the bottom."
    L["BAG_SORT_CLICK"] = "|cff00ff00Click to sort inventory.|r"
    L["MSG_BAG_SORT_START"] = "Starting reverse bag sort (%d moves)..."
    L["MSG_BAG_SORT_COMPLETE"] = "Bags sorted successfully! Reagents stashed, overflow at top, rest at bottom."
    L["MSG_BAG_SORT_COMBAT"] = "Cannot sort bags during combat lockdown."
    L["MSG_BAG_SORT_CURSOR"] = "Please release the item on your cursor before sorting."
    L["MSG_BAG_SORT_BUSY"] = "Bag sorting is already in progress..."
    L["MSG_BAG_SORT_ALREADY_SORTED"] = "Bags are already correctly organized."
end

DQ.L = L
DQ.BBR = DQ -- Backward-compatible internal reference
