extends "res://scripts/towers/tower_base.gd"

# Sniper Tower - Long range, high damage, slow attack speed

func _ready():
	damage = 50.0
	attack_range = 300.0
	attack_speed = 0.5
	projectile_speed = 500.0
	cost = 200

	super._ready()
