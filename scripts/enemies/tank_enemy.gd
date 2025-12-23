extends "res://scripts/enemies/enemy_base.gd"

# Tank Enemy - High health, slow speed

func _ready():
	max_health = 300.0
	move_speed = 50.0
	gold_reward = 30
	score_reward = 25
	damage_to_base = 2

	super._ready()

	# Set sprite color
	if sprite:
		sprite.modulate = Color(0.5, 0.5, 0.8)  # Blueish
		sprite.scale = Vector2(1.3, 1.3)  # Larger
