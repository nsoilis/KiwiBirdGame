extends CharacterBody3D

const SPEED = 3.0
const JUMP_VELOCITY = 4.5
const TURN_SPEED = 3.0  # Adjust this to control how quickly the Kiwi turns

signal egg_collected_signal(egg_count)

var egg_count: int = 0  # Keep track of collected eggs
var following_eggs: Array = []  # Stores the eggs that will follow
const MAX_FOLLOWING_EGGS = 3  # Maximum eggs that can follow

@onready var animation_player: AnimationPlayer = $KiwiBirdSkeleWorking2/AnimationPlayer
@onready var egg_follow_point: Marker3D = $EggMarker

func _ready():
	# Loop through all nodes in the "eggs" group
	for egg in get_tree().get_nodes_in_group("eggs"):
		# Connect the signal if the node has the signal
		if egg.has_signal("egg_collected"):
			egg.connect("egg_collected", Callable(self, "_on_egg_collected"))
			
			
func _physics_process(delta: float) -> void:
	# Add gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := Vector3(input_dir.x, 0, input_dir.y).normalized()  # Use world axes for movement

	if direction.length() > 0:
		# Move in the direction of input
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED

		# Calculate the target facing direction and rotate the bird smoothly
		var target_rotation = Vector3(velocity.x, 0, velocity.z).normalized()
		var forward = Vector3.FORWARD
		var angle = forward.angle_to(target_rotation)
		
		# Correct rotation direction based on cross product
		if forward.cross(target_rotation).y < 0:
			angle = -angle
		rotation.y = lerp_angle(rotation.y, angle, TURN_SPEED * delta)

		# Play walking animation
		if not animation_player.is_playing() or animation_player.current_animation != "Walking":
			animation_player.play("Walking")
	else:
		# Decelerate when no input
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

		# Play idle animation if not moving
		if not animation_player.is_playing() or animation_player.current_animation != "IdleAnimationUpdate":
			animation_player.play("IdleAnimationUpdate")

	# Apply movement
	move_and_slide()
	_update_following_eggs(delta)


	# Apply movement
	move_and_slide()
	_update_following_eggs(delta)


	move_and_slide()
	_update_following_eggs(delta)
		
func _on_egg_collected(egg_scene: Node3D):
	egg_count += 1
	print("Eggs collected: %d" % egg_count)
	emit_signal("egg_collected_signal", egg_count)  # Notify the main scene

	# If we have room for following eggs, make it follow
	if following_eggs.size() < MAX_FOLLOWING_EGGS:
		# Defer removing the egg from its current parent
		egg_scene.get_parent().call_deferred("remove_child", egg_scene)
		
		# Defer adding the egg to the Kiwi so it doesn’t interfere with physics updates
		call_deferred("_add_following_egg", egg_scene)
	else:
		egg_scene.get_parent().call_deferred("remove_child", egg_scene)
		
		# Defer adding the egg to the Kiwi so it doesn’t interfere with physics updates
		

# Function to add the egg safely after the physics update
func _add_following_egg(egg_scene: Node3D):
	add_child(egg_scene)
	following_eggs.append(egg_scene)  # Add the egg to the list of followers

	# Position the egg at an offset behind the Kiwi
	var initial_offset = -global_transform.basis.z * (1.5 * following_eggs.size())  # 1.5 = spacing multiplier
	egg_scene.global_position = global_transform.origin + initial_offset

	# Scale the egg (adjust if necessary)
	egg_scene.scale = Vector3(0.5, 0.5, 0.5)

	# Play the bouncing animation
	var anim = egg_scene.get_node("AnimationPlayer")
	if anim:
		anim.play("BounceAnimation")

		
func _update_following_eggs(delta: float):
	# Start with the position of the egg follow point
	var base_position = egg_follow_point.global_position

	for i in following_eggs.size():
		var egg = following_eggs[i]
		if not is_instance_valid(egg):
			continue

		# Calculate the target position for this egg
		var target_offset = egg_follow_point.global_transform.basis.z * 1.2 * (i + 1)
		var target_position = egg_follow_point.global_transform.origin + target_offset
		egg.global_position = egg.global_position.lerp(target_position, 5 * delta)

		# Smoothly move each egg toward its target position
		egg.global_position = egg.global_position.lerp(target_position, 5 * delta)

		# Update the base position for the next egg
		base_position = target_position
