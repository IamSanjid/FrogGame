extends Node2D

@export var gained_points := 10

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var left_raycast: RayCast2D = $LeftRaycast
@onready var right_raycast: RayCast2D = $RightRaycast
@onready var down_left_raycast: RayCast2D = $DownLeftRaycast
@onready var down_right_raycast: RayCast2D = $DownRightRaycast

@onready var health_comp := $HealthComponent

@export var base_speed := 80.0

var direction := 1
var speed := base_speed

func _ready() -> void:
	sprite.play("default")
	health_comp.death.connect(self._oh_death)
	health_comp.damage_taken.connect(self._on_damage_taken)

func _physics_process(delta: float) -> void:
	if !down_left_raycast.is_colliding() or left_raycast.is_colliding():
		direction = 1
		sprite.flip_h = false
	if !down_right_raycast.is_colliding() or right_raycast.is_colliding():
		direction = -1
		sprite.flip_h = true

	position.x += direction * speed * delta

func _oh_death():
	GameManager.add_points(gained_points)
	queue_free()

func _on_damage_taken():
	var percentage = health_comp.get_health() / health_comp.max_health
	if percentage <= 0.4:
		# increase speed when below 40% hp
		speed *= 1.6
		# face to player immidiately and chase
		direction = sign(GameManager.player.global_position.x - global_position.x)
		if direction == 1:
			sprite.flip_h = false
		else:
			sprite.flip_h = true
