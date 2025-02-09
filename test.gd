extends Node3D  # This is the root node of your main scene.

@onready var egg_counter_label: Label = $CanvasLayer/EggCounterLabel
@onready var player: CharacterBody3D = $CharacterBody3D2  # Adjust path to match your player node.

func _ready():
	# Initialize the egg counter display to 0
	egg_counter_label.text = "Eggs Collected: 0"
	# Connect the player's egg collected signal to this script's method.
	player.connect("egg_collected_signal", Callable(self, "_update_egg_counter"))

func _update_egg_counter(new_egg_count: int):
	# Update the text in the label.
	egg_counter_label.text = "Eggs Collected: %d" % new_egg_count
