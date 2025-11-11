# Folder Structure Enhancement Proposal
## For 4-Developer Team Collaboration

### Current Issues Identified:
1. **Mixed concerns**: `models/` contains both 3D assets and game logic
2. **Unclear utility organization**: `utils/` mixes combat, state machines, waves, and spawners
3. **No clear managers/singletons**: Game managers scattered across different folders
4. **Asset organization**: Could be better separated by type and purpose
5. **Level organization**: Levels could have better structure for parallel work

---

## Proposed New Structure

```
project-z/
├── assets/                          # All non-code assets
│   ├── audio/
│   │   ├── music/
│   │   ├── sfx/
│   │   └── voice/
│   ├── graphics/
│   │   ├── sprites/
│   │   ├── textures/
│   │   ├── ui/
│   │   └── icons/
│   ├── models/                      # 3D models only (no scripts)
│   │   ├── characters/
│   │   ├── environment/
│   │   ├── props/
│   │   └── effects/
│   └── animations/                  # Animation files
│
├── core/                            # Core game systems (shared by all)
│   ├── autoload/                    # ⭐ AUTOLOAD SINGLETONS (Project Settings → Autoload)
│   │   ├── game_config.gd           # Game configuration (autoload as "GameConfig")
│   │   ├── game_manager.gd          # Main game manager (autoload as "GameManager")
│   │   ├── audio_manager.gd         # Audio manager (autoload as "AudioManager")
│   │   ├── ui_manager.gd            # UI manager (autoload as "UIManager")
│   │   └── wave_manager.gd          # Wave manager (autoload as "WaveManager")
│   ├── managers/                    # Scene-based managers (NOT autoload)
│   │   ├── enemy_wave_manager.gd   # Moved from utils/enemy_waves/
│   │   └── level_manager.gd         # Level-specific managers
│   ├── systems/                     # Core game systems (classes, not singletons)
│   │   ├── state_machine.gd         # Moved from utils/state/
│   │   ├── state.gd                 # Moved from utils/state/
│   │   └── input_handler.gd
│   ├── data/                        # Static data classes (NOT autoload)
│   │   ├── constants.gd             # Static constants class
│   │   └── game_data.gd             # Static data structures
│   └── utils/                       # Global utility functions (optional)
│       ├── math_utils.gd            # Math helper functions
│       └── string_utils.gd          # String helper functions
│
├── gameplay/                        # Gameplay-specific code
│   ├── combat/
│   │   ├── attackable_body.gd       # Moved from utils/combat/
│   │   ├── damage_area.gd           # Moved from utils/combat/
│   │   └── healthbar.gd             # Moved from utils/combat/
│   ├── entities/                    # All game entities
│   │   ├── player/
│   │   │   ├── player.gd
│   │   │   ├── player.tscn
│   │   │   └── player_abilities/
│   │   ├── enemies/
│   │   │   ├── base_enemy.gd        # Base class if exists
│   │   │   ├── crab/
│   │   │   │   ├── crab.gd
│   │   │   │   ├── crab.tscn
│   │   │   │   └── states/          # Enemy-specific states
│   │   │   │       ├── crab_attack_state.gd
│   │   │   │       └── walk_towards_player_state.gd
│   │   │   └── goblin/
│   │   └── npcs/
│   │       └── suzanne/
│   ├── environment/                 # Environment interactables
│   │   ├── ship/
│   │   │   ├── ship.gd              # Moved from models/ship/
│   │   │   ├── ship.tscn
│   │   │   ├── ship_swaying.gd
│   │   │   └── shippart.gd
│   │   ├── wave/                    # Water wave logic
│   │   │   ├── wave.gd              # Moved from models/wave/
│   │   │   └── wave.tscn
│   │   ├── rocks/
│   │   │   └── rockspawner.gd       # Moved from utils/rock/
│   │   └── fence/
│   └── spawners/                    # All spawner logic
│       ├── enemy_spawner.gd         # Moved from characters/enemies/
│       └── rock_spawner.gd
│
├── ui/                              # UI system
│   ├── screens/                     # Full screen UIs
│   │   ├── main_menu.tscn
│   │   ├── game_hud.tscn
│   │   └── pause_menu.tscn
│   ├── components/                  # Reusable UI components
│   │   ├── health_bar.tscn
│   │   ├── water_level_bar.tscn
│   │   └── stamina_bar.tscn
│   └── ui_controller.gd             # Main UI controller
│
├── levels/                          # Level scenes
│   ├── ocean/
│   │   ├── ocean.tscn
│   │   └── ocean_config.gd          # Level-specific config
│   └── riverdale/
│       ├── riverdale.tscn
│       └── riverdale_config.gd
│
├── shaders/                         # Shader files (keep as is)
│
├── addons/                          # Third-party addons (keep as is)
│
└── bin/                             # Compiled binaries (keep as is)
```

---

## Developer Responsibility Split

### **Developer 1: Core Systems & Managers**
- `core/managers/` - All game managers
- `core/systems/` - State machines, input handling
- `core/data/` - Game configuration and constants
- **Low conflict potential** - Foundation systems

### **Developer 2: Player & Combat**
- `gameplay/entities/player/` - Player logic
- `gameplay/combat/` - Combat system
- `ui/components/` - Combat-related UI (health bars, etc.)
- **Medium conflict potential** - May interact with enemies

### **Developer 3: Enemies & Spawners**
- `gameplay/entities/enemies/` - All enemy types
- `gameplay/spawners/` - Enemy spawners
- `core/managers/enemy_wave_manager.gd` - Enemy wave logic
- **Medium conflict potential** - May interact with player/combat

### **Developer 4: Environment & Levels**
- `gameplay/environment/` - Ship, waves, rocks, props
- `levels/` - Level scenes and configs
- `assets/models/environment/` - Environment 3D models
- **Low conflict potential** - Mostly isolated

---

## Migration Strategy

### Phase 1: Create New Structure (Low Risk)
1. Create new folders without moving files
2. Update `.gitignore` if needed
3. Document the new structure

### Phase 2: Move Core Systems (Low Risk)
1. Move `utils/state/` → `core/systems/`
2. Move managers to `core/managers/`
3. Update all references

### Phase 3: Reorganize Gameplay (Medium Risk)
1. Move `utils/combat/` → `gameplay/combat/`
2. Move `characters/` → `gameplay/entities/`
3. Move logic from `models/` to `gameplay/environment/`
4. Update all scene references

### Phase 4: Reorganize Assets (Low Risk)
1. Move assets to new structure
2. Update import paths

---

## Benefits

### 1. **Reduced Merge Conflicts**
- Clear separation of responsibilities
- Each developer works in distinct folders
- Shared code in `core/` is minimal and well-defined

### 2. **Better Code Discovery**
- Logical grouping by functionality
- Easy to find related files
- Clear ownership boundaries

### 3. **Scalability**
- Easy to add new enemy types
- Easy to add new levels
- Easy to add new UI screens

### 4. **Maintainability**
- Clear separation of concerns
- Models separated from logic
- Assets organized by type

### 5. **Onboarding**
- New developers can quickly understand structure
- Clear ownership makes it easy to ask questions
- Documentation-friendly structure

---

## Additional Recommendations

### 1. **Naming Conventions**
- Scripts: `snake_case.gd`
- Scenes: `snake_case.tscn`
- Classes: `PascalCase` (already following)
- Constants: `UPPER_SNAKE_CASE`

### 2. **Scene Organization**
- Keep `.tscn` files next to their `.gd` scripts
- Use descriptive folder names
- Group related scenes together

### 3. **Asset Organization**
- Separate by type (audio, graphics, models)
- Use subfolders for categories
- Keep `.import` files with assets (Godot requirement)

### 4. **Documentation**
- Add `README.md` in each major folder explaining its purpose
- Document manager responsibilities
- Document level structure

### 5. **Version Control**
- Consider `.gitattributes` for line ending consistency
- Use `.gitignore` for build artifacts
- Consider Git LFS for large assets

---

## Quick Reference: Where Does X Go?

| Current Location | New Location | Reason |
|-----------------|--------------|--------|
| `utils/state/` | `core/systems/` | Core system, used by many |
| `utils/combat/` | `gameplay/combat/` | Gameplay-specific |
| `utils/wave/` | `core/managers/` | Manager system |
| `utils/enemy_waves/` | `core/managers/` | Manager system |
| `utils/rock/` | `gameplay/environment/rocks/` | Environment logic |
| `characters/player/` | `gameplay/entities/player/` | Entity organization |
| `characters/enemies/` | `gameplay/entities/enemies/` | Entity organization |
| `models/ship/` (scripts) | `gameplay/environment/ship/` | Separate logic from assets |
| `models/wave/` (scripts) | `gameplay/environment/wave/` | Separate logic from assets |
| `models/` (assets only) | `assets/models/` | Asset organization |

---

## Autoload Scripts vs Global Scripts

### ⭐ Autoload Scripts (`core/autoload/`)

**What are they?**
- Scripts registered in **Project Settings → Autoload**
- Loaded automatically when the game starts
- Accessible globally from any script
- Persistent throughout the game session

**Examples:**
- `GameConfig` - Game configuration values
- `GameManager` - Main game state manager
- `AudioManager` - Audio playback control
- `UIManager` - UI state management
- `WaveManager` - Wave spawning system

**How to use:**
```gdscript
# In any script, access directly:
GameConfig.player_move_speed
AudioManager.play_sound("jump")
UIManager.show_menu()
```

**Setup:**
1. Create script in `core/autoload/`
2. Go to **Project → Project Settings → Autoload**
3. Add script with path: `res://core/autoload/your_script.gd`
4. Set Node Name (e.g., "GameConfig")
5. ✅ Enable "Singleton"

### 📦 Global Scripts (Static Classes)

**What are they?**
- Static classes that don't need to be autoloaded
- Accessed via class name, not as a singleton
- No instance needed, just use the class directly

**Examples:**
- `Constants` - Immutable constants
- `GameData` - Static data structures
- Utility classes with static functions

**How to use:**
```gdscript
# Access static class directly:
Constants.GROUP_PLAYERS
Constants.INPUT_ATTACK

# Or use short alias:
const C = Constants
C.GROUP_PLAYERS
```

**Location:**
- `core/data/` - For data classes like Constants
- `core/utils/` - For utility functions

### 🔄 Scene-Based Managers (`core/managers/`)

**What are they?**
- Managers that are part of a scene tree
- NOT autoloaded, instantiated in scenes
- Used for level-specific or scene-specific management

**Examples:**
- `EnemyWaveManager` - Spawns enemies in a level
- `LevelManager` - Manages level-specific logic

**How to use:**
```gdscript
# Access via scene tree:
var manager = get_node("/root/Level/EnemyWaveManager")
# Or via group:
var managers = get_tree().get_nodes_in_group("managers")
```

---

## Quick Reference: Where Does X Go?

| Type | Location | Example |
|------|----------|---------|
| **Autoload Singleton** | `core/autoload/` | `GameConfig`, `AudioManager` |
| **Static Constants** | `core/data/` | `Constants.gd` |
| **Static Utilities** | `core/utils/` | `MathUtils.gd` |
| **Scene Manager** | `core/managers/` | `EnemyWaveManager` |
| **Core System Class** | `core/systems/` | `StateMachine`, `State` |

---

## Questions to Consider

1. **Do you have a base enemy class?** If so, it should go in `gameplay/entities/enemies/base_enemy.gd`
2. **Are there shared utilities?** Consider `core/utils/` for truly shared code
3. **Do you have save/load system?** Consider `core/systems/save_system.gd`
4. **Network multiplayer?** Consider `core/systems/network/` if needed
5. **Settings/Options?** Consider `core/data/settings.gd`

---

## Next Steps

1. Review this proposal with the team
2. Discuss and adjust based on team needs
3. Create migration plan
4. Execute migration in phases
5. Update documentation

