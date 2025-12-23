extends Node2D

# Base class for all towers

# Tower stats (override in child classes)
var damage: float = 10.0
var attack_range: float = 150.0
var attack_speed: float = 1.0  # Attacks per second
var projectile_speed: float = 300.0
var cost: int = 100

# Runtime variables
var owner_id: int = -1  # Player who owns this tower
var current_target: CharacterBody2D = null
var can_attack: bool = true
var attack_timer: Timer

# Nodes
@onready var sprite = $Sprite2D
@onready var range_indicator = $RangeIndicator
@onready var turret = $Turret

func _ready():
	# Create attack timer
	attack_timer = Timer.new()
	attack_timer.one_shot = false
	attack_timer.wait_time = 1.0 / attack_speed
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	add_child(attack_timer)
	attack_timer.start()

	# Setup range indicator
	if range_indicator:
		range_indicator.hide()
		_draw_range_indicator()

	# Set owner color
	_set_owner_color()

func _process(_delta):
	# Only host processes tower logic
	if not NetworkManager.is_host():
		return

	# Find and track target
	if current_target == null or not is_instance_valid(current_target) or not _is_in_range(current_target):
		_find_target()

	# Rotate turret toward target
	if current_target and turret:
		var direction = (current_target.global_position - global_position).normalized()
		turret.rotation = direction.angle()

func _find_target():
	current_target = null
	var closest_distance = attack_range
	var enemies = get_tree().get_nodes_in_group("enemies")

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue

		var distance = global_position.distance_to(enemy.global_position)

		if distance <= attack_range and distance < closest_distance:
			current_target = enemy
			closest_distance = distance

func _is_in_range(target: Node2D) -> bool:
	if not is_instance_valid(target):
		return false

	return global_position.distance_to(target.global_position) <= attack_range

func _on_attack_timer_timeout():
	if not NetworkManager.is_host():
		return

	if current_target and is_instance_valid(current_target) and _is_in_range(current_target):
		_shoot_at_target()

func _shoot_at_target():
	if not current_target:
		return

	# Create projectile
	_spawn_projectile(current_target.global_position)

	# Apply damage directly for simple towers
	if current_target.has_method("take_damage"):
		current_target.take_damage(damage, owner_id)

func _spawn_projectile(target_pos: Vector2):
	# Spawn projectile visual on all clients
	rpc("_client_spawn_projectile", global_position, target_pos)

@rpc("authority", "call_local", "reliable")
func _client_spawn_projectile(from_pos: Vector2, to_pos: Vector2):
	# Create a simple projectile visual
	var projectile = Line2D.new()
	projectile.add_point(Vector2.ZERO)
	projectile.add_point(to_pos - from_pos)
	projectile.width = 2
	projectile.default_color = Color(1, 1, 0, 1)
	projectile.global_position = from_pos

	get_tree().root.add_child(projectile)

	# Animate and remove
	await get_tree().create_timer(0.1).timeout
	projectile.queue_free()

func _draw_range_indicator():
	if range_indicator and range_indicator is Polygon2D:
		var points = PackedVector2Array()
		var segments = 32

		for i in range(segments + 1):
			var angle = (i / float(segments)) * TAU
			var point = Vector2(cos(angle), sin(angle)) * attack_range
			points.append(point)

		range_indicator.polygon = points

func _set_owner_color():
	if owner_id >= 0:
		var player_data = PlayerManager.get_player(owner_id)
		if player_data and sprite:
			sprite.modulate = player_data.color

func show_range():
	if range_indicator:
		range_indicator.show()

func hide_range():
	if range_indicator:
		range_indicator.hide()
