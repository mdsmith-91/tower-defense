extends CanvasLayer

# Game HUD - Displays game info and tower selection

@onready var gold_label = $TopBar/GoldLabel
@onready var wave_label = $TopBar/WaveLabel
@onready var health_label = $TopBar/HealthLabel

@onready var tower_panel = $TowerPanel
@onready var basic_tower_button = $TowerPanel/VBoxContainer/BasicTowerButton
@onready var sniper_tower_button = $TowerPanel/VBoxContainer/SniperTowerButton
@onready var cannon_tower_button = $TowerPanel/VBoxContainer/CannonTowerButton

@onready var wave_button = $WaveButton
@onready var menu_button = $MenuButton

var main_game: Node2D

func _ready():
	# Connect signals
	PlayerManager.player_gold_changed.connect(_on_player_gold_changed)
	GameManager.wave_started.connect(_on_wave_started)
	GameManager.wave_completed.connect(_on_wave_completed)
	GameManager.base_health_changed.connect(_on_base_health_changed)

	# Connect buttons
	basic_tower_button.pressed.connect(_on_basic_tower_pressed)
	sniper_tower_button.pressed.connect(_on_sniper_tower_pressed)
	cannon_tower_button.pressed.connect(_on_cannon_tower_pressed)
	wave_button.pressed.connect(_on_wave_button_pressed)
	menu_button.pressed.connect(_on_menu_button_pressed)

	# Get reference to main game
	main_game = get_parent()

	# Initial update
	_update_display()

	# Only host can start waves
	if not NetworkManager.is_host():
		wave_button.disabled = true
		wave_button.text = "Host controls waves"

func _process(_delta):
	_update_display()

func _update_display():
	# Update gold
	var local_player = PlayerManager.get_local_player()
	if local_player:
		gold_label.text = "Gold: " + str(local_player.gold)

		# Update tower button states based on gold
		_update_tower_buttons(local_player.gold)

	# Update wave
	wave_label.text = "Wave: " + str(GameManager.get_current_wave())

	# Update health
	health_label.text = "Base HP: " + str(GameManager.get_base_health())

func _update_tower_buttons(gold: int):
	basic_tower_button.disabled = gold < 100
	sniper_tower_button.disabled = gold < 200
	cannon_tower_button.disabled = gold < 300

func _on_basic_tower_pressed():
	if main_game and main_game.has_method("select_tower"):
		main_game.select_tower("basic")

func _on_sniper_tower_pressed():
	if main_game and main_game.has_method("select_tower"):
		main_game.select_tower("sniper")

func _on_cannon_tower_pressed():
	if main_game and main_game.has_method("select_tower"):
		main_game.select_tower("cannon")

func _on_wave_button_pressed():
	if NetworkManager.is_host() and main_game and main_game.has_method("start_wave"):
		main_game.start_wave()

func _on_menu_button_pressed():
	# Return to main menu
	NetworkManager.disconnect_from_game()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _on_player_gold_changed(peer_id: int, gold: int):
	# Update display when local player's gold changes
	if peer_id == NetworkManager.get_peer_id():
		_update_display()

func _on_wave_started(wave_number: int):
	# Disable wave button during wave
	if NetworkManager.is_host():
		wave_button.disabled = true
		wave_button.text = "Wave in Progress..."

func _on_wave_completed(wave_number: int):
	# Re-enable wave button after wave is complete
	if NetworkManager.is_host():
		wave_button.disabled = false
		wave_button.text = "Start Next Wave"

func _on_base_health_changed(health: int):
	_update_display()
