extends "res://scripts/enemies/enemy_base.gd"

# Fast Enemy - Low health, high speed

func _ready():
	max_health = 50.0
	move_speed = 150.0
	gold_reward = 12
	score_reward = 15
	damage_to_base = 1

	super._ready()

	# Set sprite color
	if sprite:
		sprite.modulate = Color(0.4, 0.8, 0.4)  # Greenish
		sprite.scale = Vector2(0.8, 0.8)  # Smaller
