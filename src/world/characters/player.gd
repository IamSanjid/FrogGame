extends CharacterBody2D

class_name Player

# Player Movement Settings

##The max speed the player will move
@export_range(50, 500) var max_speed: float = 175.0
##How fast the player will reach max speed from rest (in seconds)
@export_range(-4, 4) var time_to_reach_max_speed: float = 0.0
##How fast the player will reach zero speed from max speed (in seconds)
@export_range(-4, 4) var time_to_reach_zero_speed: float = 0.1
##If true, player will instantly move and switch directions. Overrides the "timeToReach" variables, setting them to 0.
@export var directional_snap: bool = false
##If enabled, the default movement speed will by 1/2 of the maxSpeed and the player must hold a "run" button to accelerate to max speed. Assign "run" (case sensitive) in the project input settings.
@export var running_modifier: bool = false

##The peak height of the player's jump
@export_range(0, 20) var jump_height: float = 2.1
##How many jumps the character can do before needing to touch the ground again. Giving more than 1 jump disables jump buffering and coyote time.
@export_range(0, 4) var jumps: int = 2
##The strength at which the character will be pulled to the ground.
@export_range(0, 100) var gravity_scale: float = 23.0
##The fastest player can fall
@export_range(0, 1000) var terminal_velocity: float = 700.0
##Player will move this amount faster when falling providing a less floaty jump curve.
@export_range(0.5, 3) var descending_gravity_factor: float = 2.0
##Enabling this toggle makes it so that when the player releases the jump key while still ascending, their vertical velocity will cut by the height cut, providing variable jump height.
@export var short_hop: bool = true
##How much the jump height is cut by.
@export_range(1, 10) var jump_variable: float = 5
##How much extra time (in seconds) the player will be given to jump after falling off an edge.
@export_range(0, 0.5) var coyote_time: float = 0.2
##The window of time (in seconds) that the player can press the jump button before hitting the ground and still have their input registered as a jump.
@export_range(0, 0.5) var jump_buffering: float = 0.2
##How many pixels the player will be pushed (per frame) if corner cutting is needed to correct a jump.
@export_range(1, 5) var correction_amount: float = 1.5

##Bullet fire cooldown
@export var bullet_fire_cooldown: float = 0.35
##Health regen settings
@export var regen_delay: float = 5.0
@export var regen_amount: float = 5.0

const jump_sound: AudioStream = preload("res://assets/sounds/jump_01.wav")
const BulletScene = preload("res://world/objects/bullet.tscn")

# Onready variable to reference the Sprite2D node for animations.
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var collision_shape: CollisionShape2D = $CollisionShape
@onready var left_ray_cast: RayCast2D = $LeftRayCast
@onready var middle_ray_cast: RayCast2D = $MiddleRayCast
@onready var right_ray_cast: RayCast2D = $RightRayCast
@onready var bullet_spawn_point: Node2D = $BulletSpawnPoint
@onready var camera: Camera2D = $Camera
@onready var health_comp = $HealthComponent

var bullet_fire_timer: float = 0.0

var applied_gravity: float
var acceleration: float
var deceleration: float
var jump_magnitude: float
var jump_count: int
var max_speed_lock: float
var applied_terminal_velocity := terminal_velocity

var instant_accel := false
var instant_stop := false

var anim_scale_lock : Vector2
var collider_scale_lock_y: float
var collider_pos_lock_y: float

var gravity_active := true

class _Input:
	var left_hold: bool
	var right_hold: bool
	var left_tap: bool
	var right_tap: bool
	var left_release: bool
	var right_release: bool
	var jump_tap: bool
	var jump_release: bool
	var run_hold: bool
	var fire_hold: bool

	func poll() -> void:
		left_hold    = Input.is_action_pressed("left")
		right_hold   = Input.is_action_pressed("right")
		left_tap     = Input.is_action_just_pressed("left")
		right_tap    = Input.is_action_just_pressed("right")
		left_release = Input.is_action_just_released("left")
		right_release= Input.is_action_just_released("right")
		jump_tap     = Input.is_action_just_pressed("jump")
		jump_release = Input.is_action_just_released("jump")
		run_hold     = Input.is_action_pressed("run")
		fire_hold    = Input.is_action_pressed("fire")

# collect inputs from physics process
var phy_input_cache := _Input.new()

enum _MOVEMENT_DIR {
	LEFT, RIGHT
}
var prev_movement_dir = _MOVEMENT_DIR.RIGHT
var coyote_activate := false

var jump_was_press := false

var regen_timer: SceneTreeTimer = null
var is_regening: bool = false

func _ready():
	GameManager.player = self

	instant_accel = time_to_reach_max_speed == 0
	if instant_accel:
		time_to_reach_max_speed = 1
	time_to_reach_max_speed = abs(time_to_reach_max_speed)
	
	instant_stop = time_to_reach_zero_speed == 0
	if instant_stop:
		time_to_reach_zero_speed = 1
	time_to_reach_zero_speed = abs(time_to_reach_zero_speed)
	
	acceleration = max_speed / time_to_reach_max_speed
	deceleration = -max_speed / time_to_reach_zero_speed
	
	jump_magnitude = (10.0 * jump_height) * gravity_scale
	jump_count = jumps
	
	max_speed_lock = max_speed
	anim_scale_lock = abs(sprite.scale)
	collider_scale_lock_y = collision_shape.scale.y
	collider_pos_lock_y = collision_shape.position.y
	
	if jumps > 1:
		jump_buffering = 0
		coyote_time = 0
	
	coyote_time = abs(coyote_time)
	jump_buffering = abs(jump_buffering)
	
	if directional_snap:
		instant_accel = true
		instant_stop = true

## DEBUG ONLY
#func _draw() -> void:
	#if !OS.is_debug_build():
		#return
	#var raycasts := [left_ray_cast, right_ray_cast, middle_ray_cast]
	#for raycast in raycasts:
		#var ray_origin = to_local(raycast.global_position)
		#var ray_end = to_local(raycast.global_position + raycast.target_position.rotated(raycast.global_rotation))
		#var hit = raycast.is_colliding()
		#var hit_pos = to_local(raycast.get_collision_point()) if hit else ray_end
		#var color = Color.RED if hit else Color.GREEN
#
		#draw_line(ray_origin, hit_pos, color, 2.0)
		#if hit:
			#draw_circle(hit_pos, 4.0, Color.YELLOW)

func _process(_delta: float) -> void:
	if !health_comp.is_alive():
		return

	if phy_input_cache.right_hold:
		sprite.scale.x = anim_scale_lock.x
	if phy_input_cache.left_hold:
		sprite.scale.x = anim_scale_lock.x * -1
		
	if abs(velocity.x) > 0.1 and is_on_floor() and !is_on_wall():
		sprite.speed_scale = abs(velocity.x / 150)
		sprite.play("running")
	elif abs(velocity.x) < 0.1 and is_on_floor():
		sprite.speed_scale = 1
		sprite.play("default")
	
	if velocity.y < 0:
		sprite.speed_scale = 1
		sprite.play("jumping")
	elif velocity.y > 40:
		sprite.speed_scale = 1
		sprite.play("falling")

# Function called every physics frame. delta is the elapsed time since the previous frame.
func _physics_process(delta):
	if !health_comp.is_alive():
		velocity.y += applied_gravity
		move_and_slide()
		return

	phy_input_cache.poll()
	
	if phy_input_cache.left_hold and phy_input_cache.right_hold:
		if !instant_stop:
			_decelerate(delta, false)
		else:
			velocity.x = -0.1

	elif phy_input_cache.right_hold:
		if velocity.x > max_speed or instant_accel:
			velocity.x = max_speed
		else:
			velocity.x += acceleration * delta
		if velocity.x < 0:
			if !instant_stop:
				_decelerate(delta, false)
			else:
				velocity.x = -0.1
	
	elif phy_input_cache.left_hold:
		if velocity.x < -max_speed or instant_accel:
			velocity.x = -max_speed
		else:
			velocity.x -= acceleration * delta
		if velocity.x > 0:
			if !instant_stop:
				_decelerate(delta, false)
			else:
				velocity.x = 0.1

	var last_dir = prev_movement_dir
	if velocity.x > 0:
		prev_movement_dir = _MOVEMENT_DIR.RIGHT
	elif velocity.x < 0:
		prev_movement_dir = _MOVEMENT_DIR.LEFT

	# Flip back when movement Dir has just changed
	if last_dir != prev_movement_dir:
		sprite.flip_h = false
	
	if running_modifier and !phy_input_cache.run_hold:
		max_speed = max_speed_lock / 2
	elif is_on_floor():
		max_speed = max_speed_lock

	if !(phy_input_cache.left_hold or phy_input_cache.right_hold):
		if !instant_stop:
			_decelerate(delta, false)
		else:
			velocity.x = 0
	
	if !running_modifier or (running_modifier and phy_input_cache.run_hold):
		max_speed = max_speed_lock
		collision_shape.scale.y = collider_scale_lock_y
		collision_shape.position.y = collider_pos_lock_y
	
	if velocity.y > 0:
		applied_gravity = gravity_scale * descending_gravity_factor
	else:
		applied_gravity = gravity_scale
	
	if !is_on_wall():
		applied_terminal_velocity = terminal_velocity
	
	if gravity_active:
		if velocity.y < applied_terminal_velocity:
			velocity.y += applied_gravity
		elif velocity.y > applied_terminal_velocity:
			velocity.y = applied_terminal_velocity
	
	if short_hop and phy_input_cache.jump_release and velocity.y < 0:
		velocity.y = velocity.y / jump_variable

	if jumps == 1:
		if !is_on_floor() and !is_on_wall():
			if coyote_time > 0:
				coyote_activate = true
				_coyote_time()

		if phy_input_cache.jump_tap and !is_on_wall():
			if coyote_activate:
				coyote_activate = false
				_jump()
			if jump_buffering > 0:
				jump_was_press = true
				_buffer_jump()
			elif jump_buffering == 0 and coyote_time == 0 and is_on_floor():
				_jump()
		elif phy_input_cache.jump_tap and is_on_floor():
			_jump()

		if is_on_floor():
			jump_count = jumps
			if coyote_time > 0:
				coyote_activate = true
			else:
				coyote_activate = false
			if jump_was_press:
				_jump()

	elif jumps > 1:
		if is_on_floor():
			jump_count = jumps

		if phy_input_cache.jump_tap and jump_count > 0:
			velocity.y = -jump_magnitude
			jump_count = jump_count - 1
			_post_jump()
			_end_on_floor()

	if velocity.y < 0 and left_ray_cast.is_colliding() and !right_ray_cast.is_colliding() and !middle_ray_cast.is_colliding():
		position.x += correction_amount
	if velocity.y < 0 and !left_ray_cast.is_colliding() and right_ray_cast.is_colliding() and !middle_ray_cast.is_colliding():
		position.x -= correction_amount
	
	if bullet_fire_timer > 0:
		bullet_fire_timer -= delta
	elif phy_input_cache.fire_hold:
		bullet_fire_timer = bullet_fire_cooldown
		_spawn_bullet()

	# Move the character and handle collisions.
	move_and_slide()
	#if OS.is_debug_build():
		#queue_redraw()

func _decelerate(delta, vertical):
	if !vertical:
		if (abs(velocity.x) > 0) and (abs(velocity.x) <= abs(deceleration * delta)):
			velocity.x = 0 
		elif velocity.x > 0:
			velocity.x += deceleration * delta
		elif velocity.x < 0:
			velocity.x -= deceleration * delta
	elif vertical and velocity.y > 0:
		velocity.y += deceleration * delta

func _coyote_time():
	await get_tree().create_timer(coyote_time).timeout
	coyote_activate = false
	jump_count += -1

func _jump():
	if jump_count > 0:
		velocity.y = -jump_magnitude
		jump_count += -1
		jump_was_press = false
		_post_jump()

func _post_jump():
	SoundManager.play("SFX", jump_sound, true)

func _buffer_jump():
	await get_tree().create_timer(jump_buffering).timeout
	jump_was_press = false

func _end_on_floor():
	applied_terminal_velocity = terminal_velocity
	gravity_active = true

func _spawn_bullet():
	var bullet: Bullet = BulletScene.instantiate()
	bullet.global_position = bullet_spawn_point.global_position
	if prev_movement_dir == _MOVEMENT_DIR.LEFT:
		bullet.direction = Vector2.LEFT
	else:
		bullet.direction = Vector2.RIGHT
	get_parent().add_child(bullet)

func _on_damage_taken() -> void:
	is_regening = false
	_start_regen_timer()

func _start_regen_timer() -> void:
	# reset timer if hit again before regen starts
	if regen_timer != null:
		regen_timer.timeout.disconnect(_on_regen_timeout)
	regen_timer = get_tree().create_timer(regen_delay)
	regen_timer.timeout.connect(_on_regen_timeout)

func _on_regen_timeout() -> void:
	regen_timer = null
	is_regening = true
	while health_comp.get_health() < health_comp.max_health and is_regening:
		health_comp.regen(regen_amount)
		await get_tree().create_timer(1).timeout
	is_regening = false

func _on_death() -> void:
	gravity_scale *= 0.60 # 60%
	collision_shape.set_deferred("disabled", true)
	var cam_global_transform = camera.global_transform
	camera.set_deferred("top_level", true)
	camera.set_deferred("global_transform", cam_global_transform)
