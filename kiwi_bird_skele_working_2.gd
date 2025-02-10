extends CharacterBody3D

const SPEED = 7.0
const JUMP_VELOCITY = 4.5
const TURN_SPEED = 6.0  # Adjust to control how quickly the Kiwi turns


signal egg_collected_signal(egg_count, total_egg_count)

var egg_count: int = 0  # Current eggs in inventory
var total_egg_count: int = 0  # Total eggs collected (inventory + nest)
var following_eggs: Array = []  # List of eggs in inventory
const MAX_FOLLOWING_EGGS = 3  # Maximum eggs that can follow

@onready var animation_player: AnimationPlayer = $KiwiBirdSkeleWorking2/AnimationPlayer
@onready var egg_follow_point: Marker3D = $EggMarker

func _ready():
	var drop_zone = get_tree().get_first_node_in_group("nest")  # DropZone is in "nest" group
	if drop_zone:
		if drop_zone.has_signal("kiwi_in_nest"):
			drop_zone.connect("kiwi_in_nest", Callable(self, "_deposit_eggs"))
			print("Kiwi successfully connected to DropZone!")
		else:
			print("Error: DropZone is missing 'kiwi_in_nest' signal!")
	else:
		print("Error: DropZone not found in the scene!")

	
	egg_count = 0  # Replace with saved value if loading
	total_egg_count = 0  # Replace with saved value if loading
	# Connect to all eggs in the scene
	for egg in get_tree().get_nodes_in_group("eggs"):
		if egg.has_signal("egg_collected"):
			egg.connect("egg_collected", Callable(self, "_on_egg_collected"))

func _physics_process(delta: float) -> void:
	# Add gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump
	if Input.is_action_just_pressed("A") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get input direction
	var input_dir = Vector2.ZERO

	# Combine arrow keys and WASD
	input_dir.x += Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_dir.y += Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")

	# Convert 2D input direction to 3D
	var direction = Vector3(input_dir.x, 0, input_dir.y).normalized()

	if direction.length() > 0:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED

		# Rotate Kiwi
		var target_rotation = Vector3(velocity.x, 0, velocity.z).normalized()
		var current_forward = -global_transform.basis.z
		var angle = current_forward.angle_to(target_rotation)
		if current_forward.cross(target_rotation).y < 0:
			angle = -angle
		rotation.y = lerp_angle(rotation.y, rotation.y + angle, TURN_SPEED * delta)

		# Play walking animation
		if not animation_player.is_playing() or animation_player.current_animation != "Walking":
			animation_player.play("Walking")
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

		# Play idle animation
		if not animation_player.is_playing() or animation_player.current_animation != "IdleAnimationUpdate":
			animation_player.play("IdleAnimationUpdate")

	move_and_slide()
	_update_following_eggs(delta)

func _on_egg_collected(egg_scene: Node3D):
	egg_count += 1  # Update the inventory count
	print("Eggs collected! Inventory:", egg_count)

	# Emit signal with updated counts (only updating inventory here)
	emit_signal("egg_collected_signal", egg_count, total_egg_count)

	# Add the egg to the following list if there's room
	if following_eggs.size() < MAX_FOLLOWING_EGGS:
		egg_scene.get_parent().call_deferred("remove_child", egg_scene)
		call_deferred("_add_following_egg", egg_scene)
	else:
		egg_scene.get_parent().call_deferred("remove_child", egg_scene)
		egg_scene.queue_free()


func _add_following_egg(egg_scene: Node3D):
	add_child(egg_scene)
	following_eggs.append(egg_scene)

	# Position the egg at an offset behind the Kiwi
	var initial_offset = -global_transform.basis.z * (1.5 * following_eggs.size())
	egg_scene.global_position = global_transform.origin + initial_offset

	# Scale the egg
	egg_scene.scale = Vector3(0.5, 0.5, 0.5)

	# Play the bouncing animation
	var anim = egg_scene.get_node("AnimationPlayer")
	if anim:
		anim.play("BounceAnimation")

func _update_following_eggs(delta: float):
	# Start with the position of the egg follow point
	var _base_position = egg_follow_point.global_position

	for i in following_eggs.size():
		var egg = following_eggs[i]
		if not is_instance_valid(egg):
			continue

		# Calculate the target position for this egg
		var target_offset = egg_follow_point.global_transform.basis.z * 1.2 * (i + 1)
		var target_position = egg_follow_point.global_transform.origin + target_offset

		# Smoothly move the egg toward its target position
		egg.global_position = egg.global_position.lerp(target_position, 5 * delta)
		
func deposit_eggs():
	if egg_count == 0:
		print("No eggs to deposit!")
		return  # Nothing to deposit

	var nest = get_tree().get_first_node_in_group("nest")  # Find the Nest
	if not nest:
		print("Nest not found!")
		return

	print("Depositing", egg_count, "eggs into the nest!")

	var nest_area_size = 3.0  # Increase area so eggs have more room
	var min_spacing = 1.2  # Increase spacing so eggs are further apart

	# Ensure we deposit all eggs, even if they aren't trailing
	for i in range(egg_count):
		var egg

		# Use following eggs first
		if following_eggs.size() > 0:
			egg = following_eggs.pop_front()  # Remove an egg from the list
			egg.get_parent().call_deferred("remove_child", egg)  # Remove from Kiwi
		else:
			# Spawn a new egg since it's in the inventory but not following
			egg = preload("res://Egg.tscn").instantiate()
			egg.scale = Vector3(0.5, 0.5, 0.5)  # Set new eggs to 50% size
			var anim_player = egg.get_node_or_null("AnimationPlayer")
			if anim_player:
				anim_player.play("BounceAnimation")

		# Add the egg to the nest
		nest.call_deferred("add_child", egg)
		await get_tree().process_frame  # Ensure it's added before setting position

		# Prevent deposited eggs from being picked up again
		egg.remove_from_group("eggs") 
		
		# Disable `EggArea` so it no longer detects collisions
		var egg_area = egg.get_node_or_null("EggArea")  # Find the `EggArea` inside the egg
		if egg_area:
			egg_area.set_deferred("monitoring", false)  # Turn off area collision detection


		# Try random positions until we find one that doesn't overlap
		var random_x
		var random_z
		var valid_position = false
		var max_attempts = 10  # Prevent infinite loop
		var attempt = 0

		while not valid_position and attempt < max_attempts:
			random_x = randf_range(-nest_area_size, nest_area_size)
			random_z = randf_range(-nest_area_size, nest_area_size)
			valid_position = true

			# Check if this position is too close to another egg
			for other_egg in nest.get_children():
				if egg != other_egg and egg.global_position.distance_to(other_egg.global_position) < min_spacing:
					valid_position = false
					break  # Stop checking, try again

			attempt += 1  # Increase attempt count

		if attempt >= max_attempts:
			print("Warning: Could not find a perfect position, placing egg anyway!")

		# Apply the non-overlapping position
		var nest_position = nest.global_transform.origin  # Get nest's global position
		egg.global_position = nest_position + Vector3(random_x, 0.5, random_z)

		print("Egg added at position:", egg.global_position)

	# Update total eggs collected
	total_egg_count += egg_count

	# Reset inventory
	egg_count = 0
	emit_signal("egg_collected_signal", egg_count, total_egg_count)
	

	print("All eggs deposited into the nest!")
