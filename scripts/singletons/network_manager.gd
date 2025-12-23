extends Node

# NetworkManager - Handles all multiplayer networking
# This singleton manages connections, peer discovery, and network events

signal player_connected(peer_id, player_info)
signal player_disconnected(peer_id)
signal server_disconnected

const DEFAULT_PORT = 7777
const MAX_PLAYERS = 4

var players = {}
var player_info = {"name": "Player"}

func _ready():
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

# Host a new game
func create_server(port: int = DEFAULT_PORT) -> bool:
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, MAX_PLAYERS)

	if error != OK:
		push_error("Failed to create server: " + str(error))
		return false

	multiplayer.multiplayer_peer = peer

	# Add ourselves to the player list
	players[1] = player_info
	PlayerManager.add_player(1, player_info)

	print("Server created on port ", port)
	return true

# Join an existing game
func join_server(address: String, port: int = DEFAULT_PORT) -> bool:
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(address, port)

	if error != OK:
		push_error("Failed to connect to server: " + str(error))
		return false

	multiplayer.multiplayer_peer = peer
	print("Connecting to ", address, ":", port)
	return true

# Disconnect from current game
func disconnect_from_game():
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null

	players.clear()
	PlayerManager.clear_players()
	print("Disconnected from game")

# Set local player info
func set_player_info(info: Dictionary):
	player_info = info

# Called when a peer connects (on all peers including server)
func _on_player_connected(id: int):
	print("Player connected: ", id)

	# If we're the server, send our player list to the new player
	if multiplayer.is_server():
		# Send existing players to new player
		rpc_id(id, "_receive_player_list", players)

# Called when a peer disconnects
func _on_player_disconnected(id: int):
	print("Player disconnected: ", id)

	if players.has(id):
		players.erase(id)
		PlayerManager.remove_player(id)
		player_disconnected.emit(id)

# Called on client when successfully connected to server
func _on_connected_ok():
	print("Successfully connected to server")

	# Send our player info to the server
	var peer_id = multiplayer.get_unique_id()
	rpc_id(1, "_register_player", peer_id, player_info)

# Called on client when connection fails
func _on_connected_fail():
	push_error("Failed to connect to server")
	multiplayer.multiplayer_peer = null

# Called on client when server disconnects
func _on_server_disconnected():
	print("Server disconnected")
	multiplayer.multiplayer_peer = null
	players.clear()
	PlayerManager.clear_players()
	server_disconnected.emit()

# RPC to register a new player with the server
@rpc("any_peer", "reliable")
func _register_player(id: int, info: Dictionary):
	if not multiplayer.is_server():
		return

	players[id] = info
	PlayerManager.add_player(id, info)

	# Broadcast to all clients (including host via call_local)
	rpc("_add_player", id, info)

	# Emit signal on host as well
	player_connected.emit(id, info)

# RPC to add a player to all clients
@rpc("authority", "reliable")
func _add_player(id: int, info: Dictionary):
	players[id] = info
	PlayerManager.add_player(id, info)
	player_connected.emit(id, info)

# RPC to receive full player list (sent to new clients)
@rpc("authority", "reliable")
func _receive_player_list(player_list: Dictionary):
	players = player_list

	for peer_id in players:
		PlayerManager.add_player(peer_id, players[peer_id])
		player_connected.emit(peer_id, players[peer_id])

# Check if we're the server/host
func is_host() -> bool:
	return multiplayer.is_server()

# Get our peer ID
func get_peer_id() -> int:
	return multiplayer.get_unique_id()
