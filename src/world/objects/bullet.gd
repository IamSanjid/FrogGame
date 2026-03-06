extends Area2D

class_name Bullet

@export var death_timer: float = 0.2
@export var direction: Vector2 = Vector2.RIGHT
@export var speed: float = 600.0

@onready var sprite = $Sprite
@onready var damage_comp = $DamageComponent

const explosion_sound: AudioStreamWAV = preload("res://assets/sounds/explosion.wav")

func _ready() -> void:
	sprite.play("default")
	SoundManager.play("SFX", explosion_sound, true)

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Enemies"):
		_do_damage(body)
	if !body.is_in_group("Collectibles") and !body.is_in_group("Player"):
		queue_free()

func _on_visible_screen_exited() -> void:
	await _kill_self()

func _kill_self() -> void:
	await get_tree().create_timer(death_timer).timeout
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("Enemies"):
		_do_damage(area)
		return

	var parent = area.get_parent()
	if parent != null and parent.is_in_group("Enemies"):
		_do_damage(parent)

func _do_damage(node: Node2D) -> void:
	if node.has_node("FlashComponent"):
		node.get_node("FlashComponent").flash()

	if node.has_node("HealthComponent"):
		node.get_node("HealthComponent").apply_damage(damage_comp.get_damage())
		queue_free()
