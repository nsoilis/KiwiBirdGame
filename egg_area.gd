extends Area3D  # `EggArea` is still an `Area3D` type under the hood

# Signal to notify when the egg is collected
signal egg_collected

func _ready():
	# Connect the `body_entered` signal to detect when the player enters the area
	connect("body_entered", Callable(self, "_on_body_entered"))

# Trigger when something enters the egg's area
func _on_body_entered(body):
	if body is CharacterBody3D:  # Adjust to match your player node's type
		emit_signal("egg_collected")  # Notify the game about the collection
		self.get_parent().queue_free()  # Remove the egg instance

func _on_egg_collected():
	get_node("CharacterBody3D").collect_egg()
	
