extends "res://scripts/towers/tower_base.gd"

# Basic Tower - Balanced stats

func _ready():
	damage = 15.0
	attack_range = 150.0
	attack_speed = 1.0
	projectile_speed = 300.0
	cost = 100

	super._ready()
