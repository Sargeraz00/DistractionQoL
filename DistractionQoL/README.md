# DistractionQoL — World of Warcraft Addon (WoW 12.1.5 Midnight)

An **ultra-lightweight**, event-driven Quality-of-Life (QoL) and performance toolkit engineered specifically for Raiders, Mythic+, and Delve players. Originally born as an anti-accidental spirit release reminder ("BaneBurro"), **DistractionQoL** has evolved into a zero-bloat, high-efficiency suite designed to solve everyday raid frustrations with virtually 0% CPU and memory footprint.

---

## ⚡ Why "Lightweight"? Zero Bloat Philosophy
- **Zero continuous `OnUpdate` polling**: Everything is strictly event-driven (`READY_CHECK`, `MERCHANT_SHOW`, `PLAYER_DEAD`, `RESURRECT_REQUEST`, etc.).
- **Zero runtime garbage collection churn**: No table creation in combat paths. Memory cleanup is executed on loading screens (`PLAYER_ENTERING_WORLD`), avoiding combat frame drops.
- **Ultra-low memory footprint**: Under ~100 KB total memory usage across all modules.
- **Taint-safe in modern WoW**: Built and tested specifically for WoW 12.1.5 (Midnight) and modern retail UI architecture.

---

## 🚀 Modular Features

### 1. 🛡️ Anti-Release Guard (Spirit Release Protection)
- **Accidental Release Prevention**: Intercepts clicks on "Release Spirit" during combat, raid bosses, or M+ keys to avoid wasting battle resurrections or dungeon timers.
- **Emergency Wipe Bypass**: Hold the `SHIFT` key and click "Release Spirit" to immediately release normally when your raid leader calls for a wipe.
- **Visual Banner & Audio**: Signature high-contrast warning banner and alert audio (`Bane.ogg`), with instant muting via `/qol mute`.

### 2. ⏱️ Raid Flow & Readiness (Anti-Distraction)
- **Taskbar Flash on Ready Check & Pull Timers**: Calls native `FlashClientIcon()` when a Ready Check is started or a DBM/BigWigs pull timer begins, alerting players looking at Discord, YouTube, or a second monitor.
- **Master Channel Audio Ping**: Plays an audible ping through the Master sound channel on Ready Check so you never miss a pull.
- **Pre-Pull Consumables Check**: Automatically checks if you have **Food (Well Fed)**, **Flask / Phial**, **Augment Rune**, and **Weapon Enchant / Oil** when a Ready Check is called. Zero polling overhead.

### 3. ⚡ Quality-of-Life Automations
- **Smart Auto-Resurrection**: Automatically accepts resurrections after wipes without manual clicking. Blocks Battle Resurrections during active combat by default to protect player positioning.
- **Auto-Repair**: Repairs gear automatically when interacting with repair vendors, with support for Guild Bank funds.
- **Auto-Sell Junk**: Instantly sells grey trash items upon speaking to merchants, printing gold earned to chat.
- **Auto-Skip Watched Cinematics**: Automatically skips in-raid cutscenes and movies you have already seen.
- **Block Duels in Instances**: Silently blocks annoying duel requests and pet battle challenges during dungeon or raid runs.
- **Fast Loot**: Instant zero-delay loot pickup at 0ms latency.
- **Reverse Bag Sort & Reagent Stash**: Inverted inventory sorting that automatically detects profession/crafting reagents, stashes them into your Reagent Bag (Bag 5), places overflow reagents at the top, and groups all other items (gear, consumables, junk) at the bottom. Fully integrates with Blizzard native bags and **EllesmereUI Bags** (either seamlessly overriding its sort button without confirmation popups, or displaying a dedicated cyan button).

### 4. 🚀 Raid Performance & FPS Optimizer
- **One-Click Raid Graphics Optimizer**: Applies proven CVars specifically tuned for 20-30 player raids and Mythic+ dungeons to eliminate single-threaded CPU bottlenecks.
- **Mechanics Visibility Guaranteed**: **Projected Textures (`raidGraphicsProjectedTextures`) remain strictly enabled** so floor swirlies and ground telegraphs remain 100% visible.
- **Full Reversibility**: Includes instant **Guardar Actual (Backup)** and **Restaurar (Restore)**.
- **Loading Screen Memory Cleanup**: Cleans Lua garbage collection (`collectgarbage("collect")`) during loading screens, preventing combat frame stutter.

### 5. 🤝 Intelligent Conflict Resolution & External Addon Compatibility
- **EllesmereUI & ElvUI Overlap Detection**: Detects overlapping features (*Auto-Repair, Auto-Sell Junk, Fast Loot, Auto-Skip Cinematics, and Bag Sorting*).
- **Interactive Decision Modal**: When an overlapping action is triggered, a sleek obsidian prompt asks whether **DistractionQoL** or the external suite (**EllesmereUI** or **ElvUI**) should manage that specific feature.
- **"Don't Ask Again" Checkbox**: Saves your preference permanently with one click.
- **Live Compatibility Dashboard**: View active conflicts, switch preferences between addons, or reset prompts anytime under `/qol` -> **[Compatibilidad / Compatibility]**.

---

## 🕹️ Available Commands

Primary commands: `/qol` (or `/dqol`, `/distraction`). The legendary `/burro` command is preserved as an alias for the memes!

| Command | Description |
| :--- | :--- |
| `/qol` *(or `/burro`)* | Opens or closes the tabbed configuration console. |
| `/qol sort` | Sorts bags in reverse order & moves profession materials to reagent bag. |
| `/qol check` | Manually checks active raid consumables (Food, Flask, Rune, Weapon). |
| `/qol fps` | Toggles between Optimal Raid FPS Mode and your original graphics. |
| `/qol fps save` | Saves current graphics settings as the backup snapshot. |
| `/qol fps restore` | Restores original graphics settings from backup. |
| `/qol mute` | Mutes or unmutes the warning alert audio. |
| `/qol autores` | Toggles auto-accepting resurrection prompts. |
| `/qol test` | Instantly triggers the giant warning banner and audio. |
| `/qol sim` | Simulates the death dialog to test live click blocking (SHIFT+Click to close). |
| `/qol sound` | Tests audio playback. |
| `/qol status` | Displays protection, auto-res, sound, and FPS status in chat. |

---

## ⚙️ Configuration Console

Type `/qol` (or `/burro`) in chat or access it via **Game Menu (ESC) -> Options -> AddOns -> DistractionQoL**.

The interface features an **Obsidian & Neon Cyan** design with tabbed navigation:
- **[Liberación / Release]**: Dungeons, Raids (Normal, Heroico, Mítico), Mundo Abierto, Sonido Bane.
- **[Flujo Raid / Raid Flow]**: Parpadear en barra de tareas, Audio en Ready Check, Chequeo de Consumibles.
- **[Automatizaciones / Automation]**: Auto-Res, Auto-Reparar (Fondos de Hermandad), Auto-Vender Basura, Saltar Cinemáticas, Bloquear Duelos, Fast Loot.
- **[Rendimiento / Performance]**: Guardar Actual, Máximo FPS, Restaurar, Limpieza de memoria en pantallas de carga.
- **[Compatibilidad / Compatibility]**: Monitor de conflictos en tiempo real con EllesmereUI y ElvUI, selectores directos por función y botón de restablecer avisos.

Seamlessly skins with **EllesmereUI** (Official Skinning API) and **ElvUI**.

---

## 📂 Modular Architecture

```
DistractionQoL/
├── DistractionQoL.toc       # Addon metadata & load order (Interface: 120105)
├── Locales.lua             # Multi-language dictionary (esES, esMX, enUS)
├── Migration.lua           # Backward-compatible database migration from BaneBurro
├── Config.lua              # Central configuration store, defaults, and conflict persistence
├── Detection.lua           # Content, difficulty, combat, and consumable detection logic
├── Alert.lua               # Giant visual frame renderer and audio player
├── Hook.lua                # Taint-free release interception (GameDialogMixin & OnButton1)
├── ConflictResolver.lua    # Real-time conflict detector & prompt resolver for EllesmereUI/ElvUI
├── RaidFlow.lua            # Taskbar flash, Ready Check audio ping, and pre-pull consumables check
├── Automation.lua          # Auto-Res, Auto-Repair, Auto-Sell, Auto-Skip Movies, Duel block, Fast Loot
├── Optimizer.lua           # Raid FPS & CVars optimizer with backup/restore & loading GC cleanup
├── BagSort.lua             # Reverse bag sorting & profession reagent stasher with bag frame button
├── UI.lua                  # 5-tab obsidian settings window with EllesmereUI & ElvUI skinning
├── Core.lua                # Addon lifecycle events and slash command dispatcher (/qol, /burro)
├── Bane.ogg                # Audio alert asset
└── README.md               # Addon documentation
```

