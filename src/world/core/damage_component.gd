extends Node

@export var base_damage: float = 10.0
var damage_multiplier: float = 1.0

func get_damage():
	return base_damage * damage_multiplier

func upgrade_damage(multiplier: float):
	damage_multiplier = multiplier
