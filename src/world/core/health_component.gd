extends Node

class_name HealthComponent

@export var max_health := 100.0
var health := max_health

func get_health():
	return self.health

func is_alive():
	return self.health > 0.0

func apply_damage(damage: float):
	if is_alive():
		self.health -= damage
		if !is_alive():
			self.death.emit()
		else:
			self.damage_taken.emit()

func regen(regen_amount: float):
	if is_alive():
		self.health = minf(self.health + regen_amount, self.max_health)
		self.regained.emit()

signal death()
signal damage_taken()
signal regained()
