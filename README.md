# Co-op Tower Defense

A cooperative multiplayer tower defense game built with Godot 4.3 and GDScript.

## Features

### Multiplayer
- **Cooperative gameplay**: Up to 4 players defend together against waves of enemies
- **Host & Join system**: Easy lobby system for creating and joining games
- **LAN/Local network**: Uses Godot's high-level multiplayer API with ENet
- **Synchronized gameplay**: All players see the same game state in real-time

### Gameplay
- **10 Waves** of increasing difficulty
- **3 Enemy types**:
  - **Basic**: Balanced stats (100 HP, 80 speed, 15 gold)
  - **Fast**: Low health, high speed (50 HP, 150 speed, 12 gold)
  - **Tank**: High health, slow (300 HP, 50 speed, 30 gold)

- **3 Tower types**:
  - **Basic Tower** (100 gold): Balanced damage and range (15 dmg, 150 range)
  - **Sniper Tower** (200 gold): Long range, high damage (50 dmg, 300 range)
  - **Cannon Tower** (300 gold): Area of effect damage (30 dmg, 180 range, 80 AoE)

- **Resource system**: Players earn gold by defeating enemies and completing waves
- **Shared base health**: All players defend the same base (100 HP)

## How to Play

### Starting the Game

1. **Open in Godot**: Open the project in Godot 4.3 or later
2. **Run the project**: Press F5 or click the Play button
3. **Enter your name**: Type your player name in the main menu

### Hosting a Game

1. Click **"Host Game"**
2. Choose a port (default: 7777)
3. Click **"Create Server"**
4. Wait for players to join in the lobby
5. Click **"Start Game"** when ready

### Joining a Game

1. Click **"Join Game"**
2. Enter the host's IP address (use `127.0.0.1` for local testing)
3. Enter the port number (default: 7777)
4. Click **"Connect"**
5. Wait in the lobby for the host to start

### Playing the Game

1. **Place towers**: Click a tower button on the right panel, then click on the map to place it
   - Green tiles can have towers
   - Brown tiles are the enemy path
   - Towers cost gold

2. **Start waves**: Click **"Start Next Wave"** (host only)

3. **Defend the base**: Towers automatically target and shoot enemies
   - Each player earns gold for kills
   - Wave completion gives bonus gold to all players

4. **Win condition**: Complete all 10 waves
5. **Lose condition**: Base health reaches 0

### Controls

- **Left click**: Place selected tower
- **Right click**: Cancel tower selection
- **ESC**: Open menu (return to main menu)

## Project Structure

```
tower-defense/
├── scripts/
│   ├── singletons/          # Core game managers
│   │   ├── network_manager.gd    # Multiplayer networking
│   │   ├── game_manager.gd       # Game state & waves
│   │   └── player_manager.gd     # Player resources & stats
│   ├── systems/             # Game systems
│   │   ├── main_game.gd          # Main game controller
│   │   └── game_map.gd           # Grid & pathfinding
│   ├── towers/              # Tower classes
│   │   ├── tower_base.gd         # Base tower class
│   │   ├── basic_tower.gd
│   │   ├── sniper_tower.gd
│   │   └── cannon_tower.gd
│   ├── enemies/             # Enemy classes
│   │   ├── enemy_base.gd         # Base enemy class
│   │   ├── basic_enemy.gd
│   │   ├── fast_enemy.gd
│   │   └── tank_enemy.gd
│   └── ui/                  # User interface
│       ├── main_menu.gd
│       └── game_hud.gd
├── scenes/                  # Scene files
│   ├── game/
│   │   └── main_game.tscn
│   ├── ui/
│   │   ├── main_menu.tscn
│   │   └── game_hud.tscn
│   ├── towers/
│   │   ├── basic_tower.tscn
│   │   ├── sniper_tower.tscn
│   │   └── cannon_tower.tscn
│   └── enemies/
│       ├── basic_enemy.tscn
│       ├── fast_enemy.tscn
│       └── tank_enemy.tscn
└── assets/                  # Game assets
    ├── sprites/
    ├── sounds/
    └── fonts/
```

## Technical Details

### Architecture

**Singleton Pattern**: Core managers (NetworkManager, GameManager, PlayerManager) are autoloaded singletons that persist across scenes and manage global game state.

**Authority Model**: The host (server) has authority over:
- Enemy spawning and pathfinding
- Damage calculations
- Resource management
- Wave progression

**RPC Synchronization**: All clients receive synchronized updates via RPCs for:
- Tower placement
- Enemy spawning
- Player gold/score changes
- Wave state
- Base health

### Multiplayer Implementation

- **High-level multiplayer API**: Uses Godot's built-in multiplayer with ENet
- **Authoritative server**: Host validates all actions and broadcasts state
- **Client prediction**: Clients show immediate feedback for local actions
- **Reliable RPCs**: Critical game state changes use reliable RPC mode

### Wave System

Waves are defined in `game_manager.gd` with configuration for:
- Number of enemies
- Enemy type
- Spawn interval
- Gold reward

## Extending the Game

### Adding New Towers

1. Create a new script in `scripts/towers/` extending `tower_base.gd`
2. Override stats in `_ready()` function
3. Create a corresponding scene in `scenes/towers/`
4. Add to `_get_tower_scene()` in `main_game.gd`
5. Add a button in `game_hud.tscn`

### Adding New Enemies

1. Create a new script in `scripts/enemies/` extending `enemy_base.gd`
2. Override stats in `_ready()` function
3. Create a corresponding scene in `scenes/enemies/`
4. Add to `_get_enemy_scene()` in `main_game.gd`
5. Use in wave configuration in `game_manager.gd`

### Customizing Waves

Edit the `wave_config` array in `game_manager.gd`:

```gdscript
var wave_config = [
    {"enemies": 10, "enemy_type": "basic", "spawn_interval": 1.0, "reward": 100},
    # Add more waves...
]
```

## Beginner Tips

Since you're new to Godot, here are some helpful tips:

### Understanding the Editor
- **Scene tree**: Shows the hierarchy of nodes in your current scene
- **Inspector**: Shows properties of the selected node
- **FileSystem**: Navigate project files
- **Console**: Shows print statements and errors

### Testing Multiplayer Locally

1. Run two instances of the game:
   - Export the project or run from command line: `godot --path . &`
   - Or use "Debug > Run Multiple Instances" (Godot 4.2+)

2. Host on one instance (127.0.0.1)
3. Join from the second instance

### Common Issues

**Can't connect to server**: Make sure both instances use the same port and the IP is correct (127.0.0.1 for local testing)

**Towers not shooting**: Make sure enemies are spawning and in range (you can see this in the remote scene tree)

**Sync issues**: The host controls all game logic - clients just display the state

### Learning Resources

- **Godot Docs**: https://docs.godotengine.org/
- **GDScript Reference**: https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/
- **Multiplayer Tutorial**: https://docs.godotengine.org/en/stable/tutorials/networking/

## License

This is a learning project - feel free to modify and extend it however you like!
