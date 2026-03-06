extends Node

const FLASH_MATERIAL = preload("res://world/core/flash.material")

@export var target: AnimatedSprite2D  # assign in inspector

var _default_material: Material

func _ready():
	_default_material = target.material

func flash(times: int = 3, interval: float = 0.1) -> void:
	for i in times * 2:
		target.material = FLASH_MATERIAL if target.material == _default_material else _default_material
		await get_tree().create_timer(interval).timeout
	target.material = _default_material
