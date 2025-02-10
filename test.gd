extends Node3D  # This is the root node of your main scene.

@onready var egg_counter_label: Label = $CanvasLayer/EggCounterLabel
@onready var player: CharacterBody3D = $CharacterBody3D2  # Adjust path to match your player node.

func _ready():
	var player = $CharacterBody3D2
	# Initialize the egg counter display to 0
	egg_counter_label.text = "Eggs in Inventory: %d\nTotal Eggs Collected: %d" % [
		player.egg_count,
		player.total_egg_count
		]
	# Connect the player's egg collected signal to this script's method.
	player.connect("egg_collected_signal", Callable(self, "_update_egg_counter"))
	

func _update_egg_counter(inventory_count: int, total_count: int):
	egg_counter_label.text = "Eggs in Inventory: %d 
	Total Eggs Collected: %d" % [inventory_count, total_count]
