extends Node

class_name FlashComponent

const flash_material = preload("res://world/core/flash.material")

@export var target: AnimatedSprite2D  # assign in inspector
@export var health_component: HealthComponent  # optional override
@export var flash_times: int = 3 # how many time to flash
@export var flash_interval: float = 0.1 # wait time between each flash

var _default_material: Material

func _ready():
	_default_material = target.material
	if !health_component:
		health_component = get_parent().find_child("HealthComponent")
	if health_component:
		health_component.damage_taken.connect(func(): flash())

func flash() -> void:
	for i in flash_times * 2:
		target.material = flash_material if target.material == _default_material else _default_material
		await get_tree().create_timer(flash_interval).timeout
	target.material = _default_material
