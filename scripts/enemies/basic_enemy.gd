extends "res://scripts/enemies/enemy_base.gd"

# Basic Enemy - Standard enemy with balanced stats

func _ready():
	max_health = 100.0
	move_speed = 80.0
	gold_reward = 15
	score_reward = 10
	damage_to_base = 1

	super._ready()

	# Set sprite color to distinguish from other enemies
	if sprite:
		sprite.modulate = Color(0.8, 0.4, 0.4)  # Reddish
