extends Area2D

#===================  Explanation of Changes:
#Singleton: The GameManager node gets always instantiated as a Singleton before any other scene, allowing for interaction with the game manager's functions globally.
#Preload: Pre-Loading resources.
#Body Entered Function: The _on_body_entered(body) function is called when another body enters the Area2D:
#Body Check: if body.is_in_group("Player") checks if the body entering the area is in a Global Group called "Player".
#Free Node: queue_free() removes the current Area2D node from the scene tree, effectively "destroying" it.
#Add Points: GameManager.add_points() calls the add_points function from the game manager to increase the player's points.
#====================================

# Collecting sound preloading
const points_collect = preload("res://assets/sounds/eating_chips.wav")

# Function called when a body enters the Area2D.
func _on_body_entered(body):
	# Check if the body that entered is in "Player" group.
	if body.is_in_group("Player"):
		# Free the current Area2D node from the scene tree.
		queue_free()
		# Call the add_points function from the GameManager to increase the points.
		# GameManager is kind of works as a singleton and always loaded before scenes.
		GameManager.add_points()
		# SoundManager is also a singleton for managing/playing sounds on different Audio buses.
		SoundManager.play("UI", points_collect, true)
