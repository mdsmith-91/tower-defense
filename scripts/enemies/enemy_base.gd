extends CharacterBody2D

# Base class for all enemies

signal enemy_died(enemy, killer_id: int)
signal reached_goal(enemy)

# Enemy stats (override in child classes)
var max_health: float = 100.0
var current_health: float = 100.0
var move_speed: float = 100.0
var gold_reward: int = 10
var score_reward: int = 10
var damage_to_base: int = 1

# Pathfinding
var path: Array[Vector2] = []
var current_waypoint_index: int = 0
var path_follow_threshold: float = 5.0

# Visual
@onready var sprite = $Sprite2D
@onready var health_bar = $HealthBar

func _ready():
	# Add to enemies group so towers can find us
	add_to_group("enemies")

	current_health = max_health
	_update_health_bar()

func _physics_process(delta):
	if path.is_empty():
		return

	# Follow the path
	_follow_path(delta)

func _follow_path(delta):
	if current_waypoint_index >= path.size():
		# Reached the end
		_reach_goal()
		return

	var target = path[current_waypoint_index]
	var direction = (target - global_position).normalized()
	var distance = global_position.distance_to(target)

	if distance < path_follow_threshold:
		# Move to next waypoint
		current_waypoint_index += 1
	else:
		# Move toward current waypoint
		velocity = direction * move_speed
		move_and_slide()

		# Rotate sprite to face movement direction
		if sprite:
			sprite.rotation = direction.angle()

func take_damage(amount: float, attacker_id: int = -1):
	current_health -= amount
	current_health = max(0, current_health)

	_update_health_bar()

	# Show damage effect
	_flash_damage()

	if current_health <= 0:
		_die(attacker_id)

func _die(killer_id: int):
	# Emit death signal only on server
	if NetworkManager.is_host():
		enemy_died.emit(self, killer_id)

	# Play death effect
	_play_death_effect()

	# Remove enemy
	queue_free()

func _reach_goal():
	# Emit reached goal signal only on server
	if NetworkManager.is_host():
		reached_goal.emit(self)
	else:
		queue_free()

func _update_health_bar():
	if health_bar:
		var health_percent = current_health / max_health
		health_bar.scale.x = health_percent

func _flash_damage():
	if sprite:
		# Flash white
		sprite.modulate = Color(2, 2, 2, 1)
		await get_tree().create_timer(0.1).timeout
		sprite.modulate = Color(1, 1, 1, 1)

func _play_death_effect():
	# Simple fade out effect
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate:a", 0.0, 0.2)

# Set the path this enemy should follow
func set_path(new_path: Array[Vector2]):
	path = new_path
	current_waypoint_index = 0
