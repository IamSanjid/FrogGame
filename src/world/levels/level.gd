extends Node

class_name Level

const InLevel = preload("res://ui/in_level.tscn")

func _ready() -> void:
	var in_level = InLevel.instantiate()
	add_child.call_deferred(in_level)
