# DistractionQoL — World of Warcraft Addon (WoW 12.x Midnight)

![Version](https://img.shields.io/badge/version-4.1.1-00e5ff) ![WoW](https://img.shields.io/badge/WoW-Midnight%2012.x-8a2be2) ![Locales](https://img.shields.io/badge/locales-esES%20%7C%20esMX%20%7C%20enUS-00ff88) ![Tests](https://img.shields.io/badge/offline%20tests-150%20passing-brightgreen)

An **ultra-lightweight**, event-driven Quality-of-Life (QoL) and performance toolkit engineered specifically for Raiders, Mythic+, and Delve players. Originally born as an anti-accidental spirit release reminder ("BaneBurro"), **DistractionQoL** has evolved into a zero-bloat, high-efficiency suite designed to solve everyday raid frustrations with virtually 0% CPU and memory footprint.

---

## ⚡ Why "Lightweight"? Zero Bloat Philosophy
- **Zero continuous `OnUpdate` polling**: Everything is strictly event-driven (`READY_CHECK`, `MERCHANT_SHOW`, `PLAYER_DEAD`, `RESURRECT_REQUEST`, `UNIT_AURA`, etc.).
- **Zero runtime garbage collection churn**: No table creation in combat paths. Memory cleanup is executed on loading screens (`PLAYER_ENTERING_WORLD`), avoiding combat frame drops.
- **Ultra-low memory footprint**: Minimal memory usage across all modules.
- **Taint-safe & Midnight-hardened**: Built for WoW 12.x (Midnight). All chat, unit, tooltip, and combat-log strings are validated with `issecretvalue()` before any string operation, and protected frames are never touched during `InCombatLockdown()`.

---

## 🆕 What's New in 4.1.x

| Area | Highlights |
| :--- | :--- |
| 🧪 **Interactive Consumables HUD** | Clickable secure bar for Flask, Food, Augment Rune and Weapon Oil, with **mouse wheel rotation** between carried items. |
| 🍷 **Midnight Consumables Catalog** | Only current-expansion items are offered (e.g. *Flask of the Shattered Sun*, *Void-Touched Augment Rune*, Midnight cooking). Older TWW/Dragonflight items are ignored. |
| 📦 **Stack Consolidation** | Multiple stacks of the same item are merged into a single entry with a total count. |
| 🤝 **EllesmereUI Handover** | When entering a raid/dungeon with EllesmereUI's consumables reminder active, you choose who manages the feature. |
| 🛡️ **Secret Values Hardening** | Fixed `UNIT_DIED` secret-string crash in M+ Wipe Release; `TargetedBy` and `ItemCounts` tooltips are fully shielded. |
| 🌐 **Strict Localization** | 100% `esES` / `esMX` Spanish and `enUS` English (universal fallback). Zero language mixing. |
| 🎨 **UI Polish** | Material-style consumables bar, re-laid-out Tooltips tab without clipping, LFG radar badges no longer overlap Blizzard data. |

---

## 🚀 Modular Features

### 1. 🛡️ Anti-Release Guard (Spirit Release Protection)
- **Accidental Release Prevention**: Intercepts clicks on "Release Spirit" during combat, raid bosses, or M+ keys to avoid wasting battle resurrections or dungeon timers.
- **Emergency Wipe Bypass**: Hold `SHIFT` and click "Release Spirit" to release normally when your raid leader calls the wipe.
- **Visual Banner & Audio**: High-contrast warning banner and alert audio (`Bane.ogg`), instantly mutable via `/qol mute`.

### 2. ⏱️ Raid Flow & Readiness (Anti-Distraction)
- **Taskbar Flash on Ready Check & Pull Timers**: Calls `FlashClientIcon()` on Ready Check or DBM/BigWigs pull timers.
- **Master Channel Audio Ping**: Audible ping through the Master channel on Ready Check.
- **Pre-Pull Consumables Check**: On Ready Check, verifies **Food**, **Flask**, **Augment Rune** and **Weapon Enchant**, prints the missing list to chat and flashes a raid warning banner.

### 3. 🧪 Interactive Consumables HUD *(new)*
- **One-click consumption**: Secure action buttons (`SecureActionButtonTemplate`) use the item straight from your bags. Compatible with `ActionButtonUseKeyDown`.
- **Mouse wheel rotation**: Hover a slot and scroll to cycle between every flask / food / rune / oil you carry — perfect for alternate specs or saving top-rank consumables on lower keys. A `1/3` badge shows the current position.
- **Weapon oils on both hands**: Left-click applies to Main Hand, right-click to Off-Hand.
- **Live buff indicators**: Active buffs get a green border and checkmark; missing ones stay neutral. Auto-hides when everything is active (unless opened manually).
- **Combat-safe**: All updates, shows and hides are deferred to `PLAYER_REGEN_ENABLED` while in combat.
- **Draggable & persistent**: Position is saved per account in `DistractionQoLDB`.

### 4. ⚡ Quality-of-Life Automations
- **Smart Auto-Resurrection**: Accepts resurrections after wipes; blocks Battle Rez auto-accept during active combat by default.
- **Auto-Repair** (with Guild Bank funds support) and **Auto-Sell Junk**.
- **Auto-Skip Watched Cinematics** and **Block Duels in Instances**.
- **Fast Loot**: Instant zero-delay loot pickup.
- **Reverse Bag Sort & Reagent Stash**: Stashes profession reagents into the Reagent Bag and groups other items at the bottom. Integrates with Blizzard bags and **EllesmereUI Bags**.
- **Chat History Recall**: Arrow Up / Arrow Down recalls previous commands and messages, persisted across reloads.

### 5. 🗝️ Mythic+ Toolkit
- **Full Wipe Auto-Release**: Detects a full party wipe in M+ after combat and releases immediately to save precious timer seconds (secret-value safe).
- **Great Vault Shortcut** (`/qol vault`): Opens the Great Vault instantly from anywhere.

### 6. 💰 Loot & Tooltips
- **Tradeable Loot Advisor**: At dungeon end or boss kill, detects tradeable party loot usable by your class, calculates ilvl upgrades (`+X ilvl (¡Mejora!)`), and offers a polite 1-click whisper to request the piece.
- **Instant Test Simulator** (`/qol loot`): Instantly simulates 3 realistic dungeon drops (tailored to your class armor, rings, and trinkets) with functional whisper buttons.
- **Item Counts Tooltip**: Breakdown across Bags, Bank, and Warband Bank, plus crafting reagent expansion tag.
- **Targeted By Tooltip**: Shows how many tanks, healers, and DPS in your group are targeting the hovered NPC.

### 7. 🚀 Raid Performance & FPS Optimizer
- **One-Click Raid Graphics Optimizer** tuned for 20-30 player raids and Mythic+.
- **Mechanics Visibility Guaranteed**: `raidGraphicsProjectedTextures` stays enabled so ground telegraphs remain visible.
- **Full Reversibility** with Backup / Restore snapshots.
- **Loading Screen Memory Cleanup** to prevent combat stutter.

### 8. 🤝 Intelligent Conflict Resolution & EllesmereUI Enhancer
- **EllesmereUI Consumables Enhancer**: When `EllesmereUIAuraBuffReminders` is loaded, DistractionQoL automatically hooks into its reminder icons (`EABR_Icon*`), injecting mouse-wheel rotary cycling between carried consumables, stack consolidation, and smart MH/OH weapon application without duplicate bars or conflict prompts.
- **Standalone Mode**: If EllesmereUI is absent, DistractionQoL provides a sleek, modern Obsidian HUD bar.
- **EllesmereUI & ElvUI Overlap Detection**: Auto-Repair, Auto-Sell Junk, Fast Loot, Auto-Skip Cinematics, and Bag Sorting.
- **Live Compatibility Dashboard**: Available under `/qol` → **Compatibility**.

### 9. 🧙 First-Time Setup Wizard
- Step-by-step onboarding (`/qol install`) with plain-language explanations, fully localized.

---

## 🕹️ Available Commands

Primary commands: `/qol` (or `/dqol`, `/distraction`). The legendary `/burro` alias is preserved for the memes!

| Command | Description |
| :--- | :--- |
| `/qol` *(or `/burro`)* | Opens or closes the tabbed configuration console. |
| `/consumables` *(or `/consumible`, `/frascos`)* | Opens the Consumables HUD (or activates Ellesmere Enhancer). Use `/consumables bar` for standalone. |
| `/qol check` *(or `buffs`, `consumables`)* | Checks raid consumables status and opens manager. |
| `/qol install` | Opens the first-time setup wizard. |
| `/qol vault` | Opens the Great Vault from anywhere. |
| `/qol sort` | Reverse bag sort & moves reagents to the reagent bag. |
| `/qol loot` | Simulates and tests the Tradeable Loot Advisor popup. |
| `/qol fps` | Toggles Optimal Raid FPS ↔ original settings (`save` / `restore` sub-commands). |
| `/qol mute` | Mutes or unmutes the alert audio. |
| `/qol autores` | Toggles auto-accepting resurrections. |
| `/qol test` | Triggers the giant warning banner and audio. |
| `/qol sim` | Simulates the death dialog to test click blocking (`stop` to close). |
| `/qol sound` | Tests audio playback. |
| `/qol status` | Displays protection, auto-res, sound, and FPS status in chat. |

---

## ⚙️ Configuration Console

Type `/qol` in chat or open **Game Menu (ESC) → Options → AddOns → DistractionQoL**.

The interface features an **Obsidian & Neon Cyan** design system (`DQ.UI.Theme`) with sidebar navigation:
- **Release**: Dungeons, Raids (Normal / Heroic / Mythic), Open World, alert sound.
- **Raid Flow**: Taskbar flash, Ready Check audio, consumables check.
- **Automation**: Auto-Res, Auto-Repair, Auto-Sell, Skip Cinematics, Block Duels, Fast Loot, Bag Sort.
- **Tooltips**: Item counts, reagent expansion tag, Targeted By, Loot Advisor filters.
- **Performance**: Backup, Max FPS, Restore, loading-screen memory cleanup.
- **Compatibility**: Real-time conflict monitor with EllesmereUI / ElvUI, per-feature selectors and prompt reset.

All labels follow the client language: **Spanish** for `esES` / `esMX`, **English** for every other locale.

---

## 📂 Repository & Addon Structure

```
DistractionQoL/ (Repository Root)
├── AGENTS.md / GEMINI.md        # Engineering rules (Git, SemVer, architecture, localization, QA)
├── .luacheckrc                  # Static analysis configuration
├── .pkgmeta / package.ps1       # CurseForge packaging
├── tests/
│   ├── mock_wow.lua             # Minimal WoW API mocks for offline testing
│   └── run_tests.lua            # Offline unit test suite (150 tests)
└── DistractionQoL/              # Pure addon folder (release package)
    ├── DistractionQoL.toc       # Metadata & load order (single source of truth for version)
    ├── Core/                    # Locales, GameData, Migration, Config, Util, Detection, Modules, Commands, Core
    ├── Modules/
    │   ├── Compatibility/       # ConflictResolver (EllesmereUI / ElvUI handover)
    │   ├── ReleaseGuard/        # Alert, Hook (taint-free release interception)
    │   ├── RaidFlow/            # RaidFlow, ConsumablesLogic (pure), ConsumablesBar (secure HUD & Ellesmere Enhancer)
    │   ├── Automations/         # Vendor, FastLoot, Cinematics, SafeResurrect, Automation
    │   ├── Optimizer/           # Raid FPS & CVar optimizer
    │   ├── BagSort/             # BagSortLogic (pure), BagSort
    │   ├── Chat/                # ChatHistory (with classic command fallbacks)
    │   ├── MythicPlus/          # WipeRelease (full wipe auto-release)
    │   ├── Tooltip/             # TargetedBy, ItemCounts
    │   └── Loot/                # TradeAdvisorLogic (pure), TradeAdvisor (with instant DBC & simulator)
    ├── UI/                      # Theme, Components, ConfigPanel, Wizard, Tabs/
    └── Media/                   # Sounds (Bane.ogg/.mp3) & Textures (sound_on/off)
```

---

## 🧑‍💻 Development & Quality Assurance

- **Business logic is decoupled** into pure `*Logic.lua` modules (consumables, bag sort, loot, LFG) and covered by offline tests.
- **Declarative registration**: modules via `DQ.Modules:Register(...)`, slash commands via `DQ:RegisterCommand(...)`.
- **Localization policy**: every user-facing string lives in `Core/Locales.lua` (`DQ.L`), fully translated for `esES` / `esMX` and `enUS`. Mixing languages in a single view is forbidden, and a dedicated test suite validates both locales.
- **Pre-commit checks**:

```powershell
lua tests/run_tests.lua                                                   # must pass 100%
Get-ChildItem -Recurse -Filter *.lua DistractionQoL | % { luac -p $_.FullName }   # syntax check
```

- **Versioning**: Semantic Versioning, with `## Version:` in `DistractionQoL.toc` as the single source of truth (read at runtime via `DQ.Util.GetVersion()`).
