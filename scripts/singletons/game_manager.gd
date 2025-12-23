extends Node

# GameManager - Manages game state, waves, and win/loss conditions
# This singleton controls the overall game flow

signal game_started
signal game_ended(victory: bool)
signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)
signal base_health_changed(new_health: int)

enum GameState {
	MENU,
	LOBBY,
	PLAYING,
	PAUSED,
	GAME_OVER
}

var current_state: GameState = GameState.MENU
var current_wave: int = 0
var base_health: int = 100
var max_base_health: int = 100

# Wave configuration
var wave_config = [
	{"enemies": 10, "enemy_type": "basic", "spawn_interval": 1.0, "reward": 100},
	{"enemies": 15, "enemy_type": "basic", "spawn_interval": 0.8, "reward": 150},
	{"enemies": 12, "enemy_type": "fast", "spawn_interval": 0.6, "reward": 200},
	{"enemies": 20, "enemy_type": "basic", "spawn_interval": 0.7, "reward": 250},
	{"enemies": 8, "enemy_type": "tank", "spawn_interval": 1.5, "reward": 300},
	{"enemies": 25, "enemy_type": "mixed", "spawn_interval": 0.5, "reward": 400},
	{"enemies": 15, "enemy_type": "fast", "spawn_interval": 0.4, "reward": 500},
	{"enemies": 10, "enemy_type": "tank", "spawn_interval": 1.2, "reward": 600},
	{"enemies": 30, "enemy_type": "mixed", "spawn_interval": 0.4, "reward": 800},
	{"enemies": 1, "enemy_type": "boss", "spawn_interval": 0, "reward": 1000},
]

func _ready():
	pass

# Start a new game
func start_game():
	if not NetworkManager.is_host():
		push_error("Only the host can start the game")
		return

	current_state = GameState.PLAYING
	current_wave = 0
	base_health = max_base_health

	# Notify all clients
	rpc("_sync_game_start")
	game_started.emit()

	print("Game started!")

# End the game
func end_game(victory: bool):
	if not NetworkManager.is_host():
		return

	current_state = GameState.GAME_OVER
	rpc("_sync_game_end", victory)
	game_ended.emit(victory)

	print("Game ended. Victory: ", victory)

# Start the next wave
func start_next_wave():
	if not NetworkManager.is_host():
		push_error("Only the host can start waves")
		return

	if current_state != GameState.PLAYING:
		push_error("Cannot start wave - game not in playing state")
		return

	current_wave += 1

	if current_wave > wave_config.size():
		# All waves completed - victory!
		end_game(true)
		return

	rpc("_sync_wave_start", current_wave)
	wave_started.emit(current_wave)

	print("Wave ", current_wave, " started!")

# Called when a wave is completed
func complete_wave():
	if not NetworkManager.is_host():
		return

	rpc("_sync_wave_complete", current_wave)
	wave_completed.emit(current_wave)

	# Give wave reward to all players
	var reward = wave_config[current_wave - 1]["reward"]
	PlayerManager.add_gold_to_all_players(reward)

	print("Wave ", current_wave, " completed! Reward: ", reward)

# Damage the base
func damage_base(amount: int):
	if not NetworkManager.is_host():
		return

	base_health -= amount
	base_health = max(0, base_health)

	rpc("_sync_base_health", base_health)
	base_health_changed.emit(base_health)

	if base_health <= 0:
		end_game(false)

	print("Base health: ", base_health, "/", max_base_health)

# Get current wave configuration
func get_wave_config(wave_num: int) -> Dictionary:
	if wave_num < 1 or wave_num > wave_config.size():
		return {}

	return wave_config[wave_num - 1]

# RPC Sync functions
@rpc("authority", "call_local", "reliable")
func _sync_game_start():
	current_state = GameState.PLAYING
	current_wave = 0
	base_health = max_base_health
	game_started.emit()

@rpc("authority", "call_local", "reliable")
func _sync_game_end(victory: bool):
	current_state = GameState.GAME_OVER
	game_ended.emit(victory)

@rpc("authority", "call_local", "reliable")
func _sync_wave_start(wave_num: int):
	current_wave = wave_num
	wave_started.emit(current_wave)

@rpc("authority", "call_local", "reliable")
func _sync_wave_complete(wave_num: int):
	wave_completed.emit(wave_num)

@rpc("authority", "call_local", "reliable")
func _sync_base_health(health: int):
	base_health = health
	base_health_changed.emit(base_health)

# Getters
func get_current_wave() -> int:
	return current_wave

func get_base_health() -> int:
	return base_health

func get_game_state() -> GameState:
	return current_state

func is_game_active() -> bool:
	return current_state == GameState.PLAYING
