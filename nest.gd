extends StaticBody3D  # Use StaticBody3D or your appropriate node type

# Signal to notify when eggs are deposited
signal eggs_deposited(amount)

@onready var nest_position = $MeshInstance3D  # Change to your mesh or central node for the nest

func _on_body_entered(body):
	if body is CharacterBody3D:
		print("Player touched the nest:", body.name)

		# Access the player's inventory
		var inventory = body.get("following_eggs")  # Adjust based on your player script
		if inventory.size() == 0:
			print("No eggs in inventory to deposit!")
			return

		# Get the number of eggs to deposit
		var deposit_count = inventory.size()

		# Update counters on the player
		body.set("egg_count", 0)  # Reset inventory count
		body.set("total_egg_count", body.get("total_egg_count", 0) + deposit_count)

		# Place the eggs visually in the nest
		place_eggs_in_nest(deposit_count)

		# Emit signal to notify eggs were deposited
		emit_signal("eggs_deposited", deposit_count)

		# Clear the inventory list
		inventory.clear()

func place_eggs_in_nest(count):
	for i in range(count):
		# Create a new egg instance (adjust to your egg scene)
		var egg_scene = preload("res://egg.tscn").instantiate()
		add_child(egg_scene)

		# Position eggs randomly in the nest (adjust for better placement logic)
		var random_x = randf_range(-1.5, 1.5)
		var random_z = randf_range(-1.5, 1.5)
		egg_scene.global_position = nest_position.global_position + Vector3(random_x, 0.5, random_z)

		# Play the idle animation for the egg
		var anim = egg_scene.get_node_or_null("AnimationPlayer")
		if anim:
			anim.play("IdleAnimation")
