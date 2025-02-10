extends CharacterBody3D

const SPEED = 7.0
const JUMP_VELOCITY = 4.5
const TURN_SPEED = 6.0  # Adjust to control how quickly the Kiwi turns

signal egg_collected_signal(egg_count)

var egg_count: int = 0  # Track collected eggs
var following_eggs: Array = []  # Stores eggs that will follow
const MAX_FOLLOWING_EGGS = 3  # Maximum eggs that can follow

@onready var animation_player: AnimationPlayer = $KiwiBirdSkeleWorking2/AnimationPlayer
@onready var egg_follow_point: Marker3D = $EggMarker

func _ready():
	# Connect to all eggs in the scene
	for egg in get_tree().get_nodes_in_group("eggs"):
		if egg.has_signal("egg_collected"):
			egg.connect("egg_collected", Callable(self, "_on_egg_collected"))

func _physics_process(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Handle movement
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := Vector3(input_dir.x, 0, input_dir.y).normalized()

	if direction.length() > 0:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED

		# Smoothly rotate the Kiwi
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
	egg_count += 1
	print("Eggs collected: %d" % egg_count)
	emit_signal("egg_collected_signal", egg_count)  # Notify the main scene

	# If we have room for following eggs, make it follow
	if following_eggs.size() < MAX_FOLLOWING_EGGS:
		egg_scene.get_parent().call_deferred("remove_child", egg_scene)
		call_deferred("_add_following_egg", egg_scene)
	else:
		egg_scene.get_parent().call_deferred("remove_child", egg_scene)

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
