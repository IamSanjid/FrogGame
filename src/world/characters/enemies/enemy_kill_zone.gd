extends Area2D

const MIN_DAMAGE_MUL: float = 1.0
const MAX_DAMAGE_MUL: float = 3.0

@onready var damage_comp: DamageComponent = $DamageComponent

func _ready() -> void:
	# Increases damage as level goes up
	var t = clampf(float(GameManager.get_current_level()) / GameManager.get_max_level(), 0.0, 1.0)
	var damage_mul = lerp(MIN_DAMAGE_MUL, MAX_DAMAGE_MUL, smoothstep(0.0, 1.0, t))
	damage_comp.upgrade_damage(damage_mul)

func _on_body_entered(body: Node2D) -> void:
	if !body.is_in_group("Player"):
		return
	var h_comp = body.get_node("HealthComponent")
	h_comp.apply_damage(damage_comp.get_damage())
