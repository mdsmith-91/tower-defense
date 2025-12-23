extends Control

# Main Menu - Handles hosting and joining games

@onready var menu_panel = $MenuPanel
@onready var host_panel = $HostPanel
@onready var join_panel = $JoinPanel
@onready var lobby_panel = $LobbyPanel

# Menu buttons
@onready var host_button = $MenuPanel/VBoxContainer/HostButton
@onready var join_button = $MenuPanel/VBoxContainer/JoinButton
@onready var quit_button = $MenuPanel/VBoxContainer/QuitButton

# Host panel
@onready var port_input = $HostPanel/VBoxContainer/PortInput
@onready var create_server_button = $HostPanel/VBoxContainer/CreateServerButton
@onready var host_back_button = $HostPanel/VBoxContainer/BackButton

# Join panel
@onready var ip_input = $JoinPanel/VBoxContainer/IPInput
@onready var join_port_input = $JoinPanel/VBoxContainer/PortInput
@onready var connect_button = $JoinPanel/VBoxContainer/ConnectButton
@onready var join_back_button = $JoinPanel/VBoxContainer/BackButton

# Lobby panel
@onready var player_list = $LobbyPanel/VBoxContainer/PlayerList
@onready var start_game_button = $LobbyPanel/VBoxContainer/StartGameButton
@onready var lobby_back_button = $LobbyPanel/VBoxContainer/BackButton
@onready var player_name_input = $MenuPanel/VBoxContainer/PlayerNameInput

func _ready():
	# Connect button signals
	host_button.pressed.connect(_on_host_button_pressed)
	join_button.pressed.connect(_on_join_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)

	create_server_button.pressed.connect(_on_create_server_pressed)
	host_back_button.pressed.connect(_show_main_menu)

	connect_button.pressed.connect(_on_connect_pressed)
	join_back_button.pressed.connect(_show_main_menu)

	start_game_button.pressed.connect(_on_start_game_pressed)
	lobby_back_button.pressed.connect(_on_lobby_back_pressed)

	# Connect network signals
	NetworkManager.player_connected.connect(_on_player_connected)
	NetworkManager.player_disconnected.connect(_on_player_disconnected)
	NetworkManager.server_disconnected.connect(_on_server_disconnected)

	# Show main menu
	_show_main_menu()

	# Set default values
	port_input.text = str(NetworkManager.DEFAULT_PORT)
	join_port_input.text = str(NetworkManager.DEFAULT_PORT)
	ip_input.text = "127.0.0.1"

func _on_host_button_pressed():
	menu_panel.hide()
	host_panel.show()

func _on_join_button_pressed():
	menu_panel.hide()
	join_panel.show()

func _on_quit_button_pressed():
	get_tree().quit()

func _on_create_server_pressed():
	# Set player name
	var player_name = player_name_input.text
	if player_name.is_empty():
		player_name = "Player"

	NetworkManager.set_player_info({"name": player_name})

	# Create server
	var port = int(port_input.text)
	if NetworkManager.create_server(port):
		host_panel.hide()
		lobby_panel.show()
		_update_lobby()

		# Host can start the game
		start_game_button.disabled = false
		start_game_button.text = "Start Game"

func _on_connect_pressed():
	# Set player name
	var player_name = player_name_input.text
	if player_name.is_empty():
		player_name = "Player"

	NetworkManager.set_player_info({"name": player_name})

	# Join server
	var ip = ip_input.text
	var port = int(join_port_input.text)

	if NetworkManager.join_server(ip, port):
		join_panel.hide()
		lobby_panel.show()
		_update_lobby()

		# Clients cannot start the game
		start_game_button.disabled = true
		start_game_button.text = "Waiting for host..."

func _on_start_game_pressed():
	if NetworkManager.is_host():
		# Load the main game scene
		get_tree().change_scene_to_file("res://scenes/game/main_game.tscn")

func _on_lobby_back_pressed():
	NetworkManager.disconnect_from_game()
	_show_main_menu()

func _show_main_menu():
	menu_panel.show()
	host_panel.hide()
	join_panel.hide()
	lobby_panel.hide()

func _on_player_connected(peer_id, player_info):
	_update_lobby()

func _on_player_disconnected(peer_id):
	_update_lobby()

func _on_server_disconnected():
	_show_main_menu()
	print("Disconnected from server")

func _update_lobby():
	# Clear player list
	player_list.clear()

	# Add all players
	for peer_id in NetworkManager.players:
		var player_info = NetworkManager.players[peer_id]
		var player_name = player_info.get("name", "Player")
		var is_host = peer_id == 1

		var text = player_name
		if is_host:
			text += " (Host)"
		if peer_id == NetworkManager.get_peer_id():
			text += " (You)"

		player_list.add_item(text)
