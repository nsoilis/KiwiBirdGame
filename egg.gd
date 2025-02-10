extends Node3D

var is_egg: bool = true
var is_on_floor: bool = true  # Tracks if the egg is on the ground

func check_if_on_floor() -> void:
	# Simple floor check (adjust Y value based on your game)
	if global_position.y <= 1.0:  # Change 1.0 to match ground level
		is_on_floor = true
	else:
		is_on_floor = false

func _process(_delta: float) -> void:  # Suppress unused parameter warning
	check_if_on_floor()
