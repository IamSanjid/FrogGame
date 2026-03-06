extends Area2D
##The next scene to show
@export var next_scene: PackedScene = preload("res://ui/next_level_scene.tscn")

const level_completed_sound: AudioStreamWAV = preload("res://assets/sounds/level_completed.wav")

func _on_body_entered(body):
	if body.is_in_group("Player"):
		SoundManager.play("SFX", level_completed_sound, true)
		get_tree().change_scene_to_packed.call_deferred(next_scene)
