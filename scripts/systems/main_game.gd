extends Node2D

# MainGame - Core game scene that manages gameplay

@onready var game_map = $GameMap
@onready var towers_container = $Towers
@onready var enemies_container = $Enemies
@onready var hud = $HUD

var selected_tower_type: String = ""
var wave_active: bool = false
var enemies_in_wave: int = 0
var enemies_spawned: int = 0
var spawn_timer: Timer

func _ready():
	# Connect to game manager signals
	GameManager.game_started.connect(_on_game_started)
	GameManager.wave_started.connect(_on_wave_started)
	GameManager.wave_completed.connect(_on_wave_completed)
	GameManager.game_ended.connect(_on_game_ended)

	# Create spawn timer
	spawn_timer = Timer.new()
	spawn_timer.one_shot = false
	add_child(spawn_timer)
	spawn_timer.timeout.connect(_spawn_enemy)

	# Start the game if we're the host
	if NetworkManager.is_host():
		GameManager.start_game()

func _process(_delta):
	# Handle tower placement preview
	if not selected_tower_type.is_empty():
		_show_tower_preview()

func _input(event):
	# Handle tower placement
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT and not selected_tower_type.is_empty():
			# Convert mouse position to game map's local space
			var mouse_pos = get_global_mouse_position()
			var map_local_pos = game_map.to_local(mouse_pos)
			_try_place_tower(map_local_pos)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			# Cancel tower selection
			selected_tower_type = ""

func _show_tower_preview():
	# Visual feedback for tower placement (will be enhanced with actual preview)
	var mouse_pos = get_global_mouse_position()
	var map_local_pos = game_map.to_local(mouse_pos)
	var grid_pos = game_map.world_to_grid(map_local_pos)

	if game_map.can_place_tower(grid_pos):
		# Valid placement - show green indicator
		pass
	else:
		# Invalid placement - show red indicator
		pass

func _try_place_tower(map_local_pos: Vector2):
	var grid_pos = game_map.world_to_grid(map_local_pos)

	if not game_map.can_place_tower(grid_pos):
		print("Cannot place tower here!")
		return

	# Get world position for tower (in map's local space)
	var tower_local_pos = game_map.grid_to_world(grid_pos)

	# Convert to global position for tower placement
	var tower_global_pos = game_map.to_global(tower_local_pos)

	# Request tower placement from server
	_request_place_tower(selected_tower_type, tower_global_pos, grid_pos)

	selected_tower_type = ""

func _request_place_tower(tower_type: String, world_pos: Vector2, grid_pos: Vector2i):
	# Get tower cost
	var cost = _get_tower_cost(tower_type)
	var peer_id = NetworkManager.get_peer_id()

	# Request from server
	rpc_id(1, "_server_place_tower", peer_id, tower_type, world_pos, grid_pos, cost)

@rpc("any_peer", "reliable")
func _server_place_tower(peer_id: int, tower_type: String, world_pos: Vector2, grid_pos: Vector2i, cost: int):
	if not NetworkManager.is_host():
		return

	# Check if player has enough gold
	if not PlayerManager.spend_gold(peer_id, cost):
		print("Player ", peer_id, " doesn't have enough gold")
		return

	# Place tower on all clients
	rpc("_client_place_tower", peer_id, tower_type, world_pos, grid_pos)

@rpc("authority", "call_local", "reliable")
func _client_place_tower(owner_id: int, tower_type: String, world_pos: Vector2, grid_pos: Vector2i):
	# Occupy the tile
	game_map.occupy_tile(grid_pos)

	# Create tower instance
	var tower_scene = _get_tower_scene(tower_type)
	if tower_scene:
		var tower = tower_scene.instantiate()
		tower.position = world_pos
		tower.owner_id = owner_id
		towers_container.add_child(tower)

		PlayerManager.increment_towers_placed(owner_id)
		print("Tower placed at ", grid_pos)

func _get_tower_cost(tower_type: String) -> int:
	match tower_type:
		"basic":
			return 100
		"sniper":
			return 200
		"cannon":
			return 300
		_:
			return 100

func _get_tower_scene(tower_type: String) -> PackedScene:
	match tower_type:
		"basic":
			return load("res://scenes/towers/basic_tower.tscn")
		"sniper":
			return load("res://scenes/towers/sniper_tower.tscn")
		"cannon":
			return load("res://scenes/towers/cannon_tower.tscn")
		_:
			return null

# Select a tower type for placement
func select_tower(tower_type: String):
	selected_tower_type = tower_type
	print("Selected tower: ", tower_type)

# Wave management
func _on_game_started():
	print("Game started!")

func start_wave():
	if NetworkManager.is_host():
		GameManager.start_next_wave()

func _on_wave_started(wave_number: int):
	wave_active = true
	enemies_spawned = 0

	var wave_config = GameManager.get_wave_config(wave_number)

	if wave_config.is_empty():
		return

	enemies_in_wave = wave_config["enemies"]
	var spawn_interval = wave_config["spawn_interval"]

	print("Wave ", wave_number, " started! Enemies: ", enemies_in_wave)

	# Only host spawns enemies
	if NetworkManager.is_host():
		if spawn_interval > 0:
			spawn_timer.wait_time = spawn_interval
			spawn_timer.start()
		else:
			# Spawn all at once (boss wave)
			for i in range(enemies_in_wave):
				_spawn_enemy()

func _spawn_enemy():
	if not NetworkManager.is_host():
		return

	if enemies_spawned >= enemies_in_wave:
		spawn_timer.stop()
		return

	var wave_config = GameManager.get_wave_config(GameManager.get_current_wave())
	var enemy_type = wave_config.get("enemy_type", "basic")

	# Spawn enemy on all clients
	rpc("_client_spawn_enemy", enemy_type)

	enemies_spawned += 1

@rpc("authority", "call_local", "reliable")
func _client_spawn_enemy(enemy_type: String):
	var enemy_scene = _get_enemy_scene(enemy_type)

	if enemy_scene:
		var enemy = enemy_scene.instantiate()
		enemy.position = game_map.get_spawn_position()
		enemy.path = game_map.get_enemy_path()
		enemies_container.add_child(enemy)

		# Connect to enemy death signal
		if NetworkManager.is_host():
			enemy.enemy_died.connect(_on_enemy_died)
			enemy.reached_goal.connect(_on_enemy_reached_goal)

func _get_enemy_scene(enemy_type: String) -> PackedScene:
	match enemy_type:
		"basic":
			return load("res://scenes/enemies/basic_enemy.tscn")
		"fast":
			return load("res://scenes/enemies/fast_enemy.tscn")
		"tank":
			return load("res://scenes/enemies/tank_enemy.tscn")
		_:
			return load("res://scenes/enemies/basic_enemy.tscn")

func _on_enemy_died(enemy, killer_id: int):
	if not NetworkManager.is_host():
		return

	# Give gold and score reward
	var reward = enemy.gold_reward
	PlayerManager.add_gold(killer_id, reward)
	PlayerManager.add_score(killer_id, enemy.score_reward)
	PlayerManager.increment_kills(killer_id)

	_check_wave_complete()

func _on_enemy_reached_goal(enemy):
	if not NetworkManager.is_host():
		return

	# Damage the base
	GameManager.damage_base(enemy.damage_to_base)

	# Remove enemy
	enemy.queue_free()

	_check_wave_complete()

func _check_wave_complete():
	if not NetworkManager.is_host():
		return

	# Wait a frame for enemy count to update
	await get_tree().process_frame

	# Check if all enemies are dead
	if enemies_container.get_child_count() == 0 and enemies_spawned >= enemies_in_wave:
		wave_active = false
		GameManager.complete_wave()

func _on_wave_completed(wave_number: int):
	print("Wave ", wave_number, " completed!")

func _on_game_ended(victory: bool):
	if victory:
		print("Victory! All waves completed!")
	else:
		print("Defeat! Base destroyed!")

	# Return to main menu after a delay
	await get_tree().create_timer(5.0).timeout
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
