extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const TURN_SPEED = 5.0  # Adjust this to control how quickly the Kiwi turns

signal egg_collected_signal(egg_count)

var egg_count: int = 0  # Keep track of collected eggs
@onready var animation_player: AnimationPlayer = $KiwiBirdSkeleWorking2/AnimationPlayer

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

		# Rotate the Kiwi toward the movement direction
		

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

	move_and_slide()
		
func _on_egg_collected():
	egg_count += 1
	print("Eggs collected: %d" % egg_count)
	emit_signal("egg_collected_signal", egg_count)  # Notify the main scene
	
