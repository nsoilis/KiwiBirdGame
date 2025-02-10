extends Area3D

# Signal to notify when an egg is deposited
signal egg_deposited(egg)

func _ready():
	# Connect the body_entered signal to handle eggs entering the area
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
	if body == null:
		print("Error: Null object entered the nest.")
		return

	print("Object entered the nest:", body.name, "Type:", body.get_class())

	# Check if the object is an egg using metadata
	if body is Node3D and body.has_meta("is_egg") and body.get_meta("is_egg"):
		print("Valid egg entered the nest:", body.name)

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
		print("Object is not a valid egg or lacks metadata:", body.name, "| Type:", body.get_class())
