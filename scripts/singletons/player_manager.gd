extends Node

# PlayerManager - Manages player data (resources, stats, etc.)
# This singleton tracks individual player resources and information

signal player_gold_changed(peer_id: int, gold: int)
signal player_score_changed(peer_id: int, score: int)

# Player data structure
class PlayerData:
	var peer_id: int
	var name: String
	var gold: int = 500  # Starting gold
	var score: int = 0
	var kills: int = 0
	var towers_placed: int = 0
	var color: Color = Color.WHITE

	func _init(id: int, info: Dictionary):
		peer_id = id
		name = info.get("name", "Player")

		# Assign a random color for this player
		var colors = [
			Color.ROYAL_BLUE,
			Color.CRIMSON,
			Color.FOREST_GREEN,
			Color.ORANGE
		]
		color = colors[id % colors.size()]

# Dictionary of peer_id -> PlayerData
var players: Dictionary = {}

func _ready():
	pass

# Add a new player
func add_player(peer_id: int, info: Dictionary):
	if players.has(peer_id):
		return

	var player_data = PlayerData.new(peer_id, info)
	players[peer_id] = player_data

	print("Player added: ", player_data.name, " (ID: ", peer_id, ")")

# Remove a player
func remove_player(peer_id: int):
	if players.has(peer_id):
		var player_name = players[peer_id].name
		players.erase(peer_id)
		print("Player removed: ", player_name, " (ID: ", peer_id, ")")

# Clear all players
func clear_players():
	players.clear()

# Get player data
func get_player(peer_id: int) -> PlayerData:
	return players.get(peer_id)

# Get local player data
func get_local_player() -> PlayerData:
	var peer_id = NetworkManager.get_peer_id()
	return get_player(peer_id)

# Add gold to a specific player
func add_gold(peer_id: int, amount: int):
	if not NetworkManager.is_host():
		# Clients must request from server
		rpc_id(1, "_request_add_gold", peer_id, amount)
		return

	if not players.has(peer_id):
		return

	players[peer_id].gold += amount
	rpc("_sync_player_gold", peer_id, players[peer_id].gold)
	player_gold_changed.emit(peer_id, players[peer_id].gold)

# Spend gold for a specific player
func spend_gold(peer_id: int, amount: int) -> bool:
	if not NetworkManager.is_host():
		# This should be called via RPC from client
		push_error("Clients cannot call spend_gold directly")
		return false

	if not players.has(peer_id):
		return false

	if players[peer_id].gold < amount:
		return false

	players[peer_id].gold -= amount
	rpc("_sync_player_gold", peer_id, players[peer_id].gold)
	player_gold_changed.emit(peer_id, players[peer_id].gold)

	return true

# Add gold to all players (wave rewards)
func add_gold_to_all_players(amount: int):
	if not NetworkManager.is_host():
		return

	for peer_id in players:
		add_gold(peer_id, amount)

# Add score to a player
func add_score(peer_id: int, amount: int):
	if not NetworkManager.is_host():
		return

	if not players.has(peer_id):
		return

	players[peer_id].score += amount
	rpc("_sync_player_score", peer_id, players[peer_id].score)
	player_score_changed.emit(peer_id, players[peer_id].score)

# Increment kills for a player
func increment_kills(peer_id: int):
	if not NetworkManager.is_host():
		return

	if not players.has(peer_id):
		return

	players[peer_id].kills += 1

# Increment towers placed for a player
func increment_towers_placed(peer_id: int):
	if not NetworkManager.is_host():
		return

	if not players.has(peer_id):
		return

	players[peer_id].towers_placed += 1

# RPC handlers
@rpc("any_peer", "reliable")
func _request_add_gold(peer_id: int, amount: int):
	add_gold(peer_id, amount)

@rpc("authority", "call_local", "reliable")
func _sync_player_gold(peer_id: int, gold: int):
	if players.has(peer_id):
		players[peer_id].gold = gold
		player_gold_changed.emit(peer_id, gold)

@rpc("authority", "call_local", "reliable")
func _sync_player_score(peer_id: int, score: int):
	if players.has(peer_id):
		players[peer_id].score = score
		player_score_changed.emit(peer_id, score)

# Get total team gold
func get_total_team_gold() -> int:
	var total = 0
	for peer_id in players:
		total += players[peer_id].gold
	return total

# Get player count
func get_player_count() -> int:
	return players.size()

# Get all players
func get_all_players() -> Array:
	return players.values()
