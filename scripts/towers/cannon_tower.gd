extends "res://scripts/towers/tower_base.gd"

# Cannon Tower - Area damage, slow attack speed

func _ready():
	damage = 30.0
	attack_range = 180.0
	attack_speed = 0.7
	projectile_speed = 250.0
	cost = 300

	super._ready()

# Override shooting to do area damage
func _shoot_at_target():
	if not current_target:
		return

	var target_pos = current_target.global_position

	# Spawn projectile visual
	_spawn_projectile(target_pos)

	# Apply area damage
	var enemies = get_tree().get_nodes_in_group("enemies")
	var explosion_radius = 80.0

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue

		var distance = target_pos.distance_to(enemy.global_position)

		if distance <= explosion_radius and enemy.has_method("take_damage"):
			# Damage falls off with distance
			var damage_multiplier = 1.0 - (distance / explosion_radius)
			var final_damage = damage * damage_multiplier
			enemy.take_damage(final_damage, owner_id)
