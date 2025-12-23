# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Running the Game

```bash
# Run the game in Godot editor (from project directory)
godot --path .

# Or press F5 in the Godot editor

# Run multiple instances for multiplayer testing
godot --path . &
godot --path . &
```

## Architecture Overview

### Authoritative Server Model

This is a **multiplayer tower defense game** using an **authoritative server** architecture. The host (peer ID 1) has complete authority over game state:

- **Host authority**: All game logic (enemy spawning, damage calculations, wave progression, resource changes) executes ONLY on the host
- **Client role**: Clients are thin display layers that send requests and receive state updates via RPCs
- **Critical pattern**: Check `NetworkManager.is_host()` before executing any game logic that affects state

### Singleton Architecture

Three autoloaded singletons (defined in `project.godot`) manage all global state:

**NetworkManager** (`scripts/singletons/network_manager.gd`):
- Handles ENet multiplayer connections (host/join)
- Manages player list and peer tracking
- Provides RPC helper functions
- Exposes: `is_host()`, `get_peer_id()`, signals for connection events

**GameManager** (`scripts/singletons/game_manager.gd`):
- Controls game state machine (MENU, LOBBY, PLAYING, GAME_OVER)
- Manages wave configuration and progression
- Tracks base health and win/loss conditions
- **Host-only execution**: All public methods check `is_host()` internally
- Uses `@rpc("authority", "call_local", "reliable")` to sync state to clients

**PlayerManager** (`scripts/singletons/player_manager.gd`):
- Tracks per-player resources (gold, score, kills, towers placed)
- Manages economy: `add_gold()`, `spend_gold()` (host validates)
- Uses `PlayerData` class instances stored in `players` dictionary (keyed by peer_id)
- **Important**: Local player access via `get_local_player()` returns `PlayerData` object

### RPC Communication Pattern

**Tower Placement Flow** (example of the standard pattern):
1. Client: User clicks → `main_game.gd` calls `rpc_id(1, "_server_place_tower", ...)`
2. Host: Receives request → validates (gold check) → executes action
3. Host: Broadcasts result via `rpc("_client_place_tower", ...)` to ALL clients (including itself via `call_local`)
4. All peers: Receive RPC → instantiate tower → update local state

**Key RPC annotations**:
- `@rpc("any_peer", "reliable")`: Client→Server requests
- `@rpc("authority", "call_local", "reliable")`: Server→All broadcasts (call_local ensures host also executes)

### Scene Architecture

**Main Game Flow**:
- Entry point: `scenes/ui/main_menu.tscn` (hosts lobby, handles connections)
- Game scene: `scenes/game/main_game.tscn` (loaded when host starts game)
- Scene transition: `get_tree().change_scene_to_file()` disconnects networking cleanly

**MainGame** (`scripts/systems/main_game.gd`):
- Central coordinator that connects singletons to game objects
- Contains node references: `game_map`, `towers_container`, `enemies_container`, `hud`
- Handles tower placement validation and RPC orchestration
- Manages wave spawning via `spawn_timer` (host-only)
- **Enemy lifecycle**: Connects `enemy_died` and `reached_goal` signals to track wave completion

**GameMap** (`scripts/systems/game_map.gd`):
- Manages 20x12 grid (64px tiles) with placeable/path tiles
- Stores enemy path as `world_waypoints: Array[Vector2]` (converted from grid coords)
- Provides: `can_place_tower()`, `grid_to_world()`, `world_to_grid()`
- Path tiles marked non-placeable in `_create_path()`

### Entity Systems

**Inheritance Pattern**: All towers/enemies inherit from base classes with stat overrides

**Towers** (`scripts/towers/tower_base.gd`):
- Autonomous targeting: Each tower finds closest enemy in `attack_range` every frame
- Shooting: `_on_attack_timer_timeout()` fires projectile + applies damage
- **Owner tracking**: `owner_id` stores peer_id for kill credit
- Visual: `turret` node rotates toward target, `range_indicator` shows attack radius

**Enemies** (`scripts/enemies/enemy_base.gd`):
- Path following: Uses `path: Array[Vector2]` from GameMap, advances via `current_waypoint_index`
- Lifecycle signals: `enemy_died(enemy, killer_id)`, `reached_goal(enemy)` (host-only)
- **Must add to "enemies" group** in `_ready()` for tower targeting
- Health bar: `health_bar` node scaled by health percentage

### Adding New Content

**New Tower Type**:
1. Create `scripts/towers/my_tower.gd` extending `tower_base.gd`
2. Override stats in `_ready()`: `damage`, `attack_range`, `attack_speed`, `cost`
3. Create scene `scenes/towers/my_tower.tscn` with Sprite2D, Turret, RangeIndicator nodes
4. Add to `_get_tower_scene()` match in `main_game.gd`
5. Add to `_get_tower_cost()` match in `main_game.gd`
6. Add button in `scenes/ui/game_hud.tscn` and wire to `game_hud.gd`

**New Enemy Type**:
1. Create `scripts/enemies/my_enemy.gd` extending `enemy_base.gd`
2. Override stats: `max_health`, `move_speed`, `gold_reward`, `damage_to_base`
3. Create scene with Sprite2D (Polygon2D), CollisionPolygon2D, HealthBar
4. Add to `_get_enemy_scene()` match in `main_game.gd`
5. Reference in `wave_config` array in `game_manager.gd`

**Wave Configuration** (`game_manager.gd:25`):
```gdscript
var wave_config = [
    {"enemies": 10, "enemy_type": "basic", "spawn_interval": 1.0, "reward": 100},
    # Each entry creates a wave
]
```

### Multiplayer Debugging

**Common issues**:
- Towers not shooting → Check enemies have "enemies" group, check host is processing tower logic
- Desyncs → Verify all state changes go through RPCs, check `call_local` on broadcasts
- Gold not updating → Ensure client calls `rpc_id(1, ...)` to request, not direct modification

**Testing locally**:
- Use "Debug > Run Multiple Instances > Run 2 Instances" in Godot editor
- First instance hosts, second joins 127.0.0.1:7777
- Monitor both consoles for RPC traffic (print statements help)

**Remote debugging**:
- Use Godot's Remote tab to inspect host's scene tree from client editor
- Check peer_id assignments: Host is always 1, clients are 2+

## Key Godot Patterns Used

- **Autoload singletons**: Persist across scenes, accessed globally via name (e.g., `NetworkManager`)
- **@onready**: Node references initialized when scene enters tree
- **Signals**: Used for event-driven communication (e.g., `GameManager.wave_started`)
- **Groups**: Enemies tagged with `add_to_group("enemies")` for tower queries
- **Multiplayer API**: `multiplayer.is_server()`, `multiplayer.get_unique_id()`, RPC decorators
