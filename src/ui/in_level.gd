extends CanvasLayer

@onready var points_label: Label = %PointsLabel
@onready var health_label: Label = %HealthLabel
@onready var game_over_panel: Panel = %GameOverPanel

func _ready() -> void:
	GameManager.update_points.connect(self._on_update_points)
	GameManager.player_changed.connect(self._on_new_player)
	if GameManager.player != null:
		_on_new_player(GameManager.player)

func _on_update_points(new_points: int):
	points_label.text = str(new_points)

func _wait_for_any_just_pressed() -> void:
	while true:
		await get_tree().process_frame
		if Input.is_anything_pressed():
			return

func _on_new_player(player: Player):
	var hp_comp = player.get_node("HealthComponent")
	hp_comp.damage_taken.connect(
		func():
			health_label.text = str(int(hp_comp.get_health()))
	)
	hp_comp.regained.connect(
		func():
			health_label.text = str(int(hp_comp.get_health()))
	)
	hp_comp.death.connect(
		func():
			game_over_panel.visible = true
			health_label.text = "0"
			Engine.time_scale = 0.5
			
			# Waiting for some amount
			await get_tree().create_timer(0.5).timeout
			await _wait_for_any_just_pressed()

			Engine.time_scale = 1.0
			GameManager.load_level(0)
	)
	health_label.text = str(int(hp_comp.get_health()))
