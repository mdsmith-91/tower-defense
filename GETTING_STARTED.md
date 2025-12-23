# Getting Started

Quick guide to get your co-op tower defense game running!

## Requirements

- Godot Engine 4.3 or later
- Download from: https://godotengine.org/download

## Opening the Project

1. Launch Godot Engine
2. Click **"Import"** in the Project Manager
3. Click **"Browse"** and navigate to this folder
4. Select the `project.godot` file
5. Click **"Import & Edit"**

## Running the Game

### Single Player Testing

1. Press **F5** or click the **Play button** (▶) at the top right
2. The game will launch with the main menu
3. Enter your name
4. Click **"Host Game"** to start
5. In the lobby, click **"Start Game"**
6. Click **"Start Next Wave"** to begin!

### Multiplayer Testing (2 Players on Same Computer)

**Method 1: Using Godot Editor**

1. With the project open, go to **Debug > Run Multiple Instances > Run 2 Instances**
2. Press F5 to run
3. In the first window: Host a game
4. In the second window: Join using IP `127.0.0.1`

**Method 2: Export and Run**

1. Go to **Project > Export**
2. Add a template for your platform (Windows, Mac, Linux)
3. Export the project
4. Run the exported executable - this is your first player
5. Press F5 in Godot - this is your second player
6. One hosts, one joins

**Method 3: Command Line** (Advanced)

```bash
# Terminal 1 (Host)
godot --path /path/to/tower-defense

# Terminal 2 (Client)
godot --path /path/to/tower-defense
```

## Testing on LAN (Different Computers)

1. **On Host Computer**:
   - Find your local IP address:
     - Windows: `ipconfig` in command prompt
     - Mac/Linux: `ifconfig` in terminal
   - Host a game
   - Share your IP address with other players

2. **On Client Computers**:
   - Join game
   - Enter host's IP address (e.g., `192.168.1.100`)
   - Connect

## Controls

- **Left Click**: Place tower (after selecting from right panel)
- **Right Click**: Cancel tower placement
- **Start Next Wave**: Begin the next enemy wave (host only)

## Tips for First Playthrough

1. Start with **Basic Towers** - they're cheap and effective early on
2. Place towers near corners in the path for maximum coverage
3. Save gold for stronger towers in later waves
4. The **Sniper Tower** is great for long, straight paths
5. Use **Cannon Towers** for clustered enemies
6. Watch your base health - if it reaches 0, game over!

## Troubleshooting

### Game won't start
- Make sure you're using Godot 4.3 or later
- Check the console for error messages

### Can't connect in multiplayer
- Both computers must be on the same network (LAN)
- Check firewall settings - allow Godot through
- Verify the IP address is correct
- Make sure both are using the same port (default: 7777)

### Towers not shooting
- Ensure enemies are spawning (you should see them moving)
- Check that towers are in range of the enemy path
- Host controls all game logic - make sure host is running

### Visual glitches
- Update your graphics drivers
- Try switching renderer in Project Settings

## Next Steps

Once you've played through the game:

1. Read the full README.md for details on extending the game
2. Try modifying wave configurations in `scripts/singletons/game_manager.gd`
3. Experiment with tower stats in the tower scripts
4. Add your own sprites in the `assets/sprites/` folder

## Need Help?

- Check the **README.md** for detailed documentation
- Review scripts in the `scripts/` folder
- Godot documentation: https://docs.godotengine.org/

Have fun defending together!
