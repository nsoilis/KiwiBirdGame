extends Area3D

signal kiwi_in_nest  # Signal to notify Kiwi

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
	if body is CharacterBody3D:
		print("Kiwi entered DropZone!")
		body._deposit_eggs()  # Directly tell the Kiwi to deposit eggs

	if body == null:
		print("Error: Null object entered the nest.")
		return

	print("Object entered the nest:", body.name, "Type:", body.get_class())

	# Check if the object is an egg
	if body is Node3D and "is_egg" in body:  # Check if the eWgg variable exists
		if body.is_egg:
			print("Valid egg entered the nest:", body.name)

			# Find the Kiwi character
			var kiwi = get_tree().get_first_node_in_group("kiwi")  # Make sure Kiwi is in the "kiwi" group

			if kiwi:
				kiwi._on_egg_deposited(body)  # Tell the Kiwi to remove it from inventory

			# Remove the egg from its current parent and add it to the nest
			if body.get_parent():
				body.get_parent().call_deferred("remove_child", body)

			call_deferred("add_child", body)
			body.global_position = global_transform.origin + Vector3(0, 0.5, 0)

			# Play animation if available
			var anim = body.get_node_or_null("AnimationPlayer")
			if anim:
				anim.play("BounceAnimation")

			emit_signal("egg_deposited", body)
	else:
		print("Object is not a valid egg:", body.name, "| Type:", body.get_class())
