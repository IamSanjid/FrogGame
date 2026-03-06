extends Node2D

# Function called when the yes button is pressed.
func _on_yes_button_pressed():
	# Change the current scene to 'level2.tscn'.
	GameManager.load_level(GameManager.current_level + 1)
	SoundManager.stop_all()

# Function called when the back button is pressed.
func _on_back_button_pressed():
	# Change the current scene to 'main_menu.tscn'.
	GameManager.load_level(0)
	SoundManager.stop_all()
