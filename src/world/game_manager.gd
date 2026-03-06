extends Node

@export var player: Player = null : set = _set_player

@export var levels: Dictionary[int, PackedScene]
@export var main_menu: PackedScene = preload("res://ui/main_menu.tscn")

func _set_player(value: Player):
	player = value
	player_changed.emit.call_deferred(value)

var points: int = 0
var current_level: int = 0
var max_level: int = 0

func _ready() -> void:
	for level in levels:
		max_level = max(level, max_level)

func get_current_level() -> int:
	return current_level

func get_max_level() -> int:
	return max_level

# Function to add points and emit event whoever interested.
func add_points(e: int = 1):
	points += e
	update_points.emit(points)

# Function to load a specific level, the level scenes are set from the editor.
func load_level(level: int):
	points = 0
	if !levels.has(level):
		current_level = 0
		get_tree().change_scene_to_packed.call_deferred(main_menu)
		return
	current_level = level
	get_tree().change_scene_to_packed.call_deferred(levels.get(level))

# Events, what the manager is doing
signal update_points(new_points: int)
signal player_changed(new_player: Player)
