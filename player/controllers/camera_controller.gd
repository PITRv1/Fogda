class_name CameraController extends NetworkOwnedObj

@export var camera_controller_anchor: Marker3D 

@export var head: Node3D
@export var main_camera: Camera3D

@export_group("Head follow weights")
@export var spring_stiffness : float = 800.0  # How fast it snaps to the target
@export var spring_damping : float = 25.0     # Lower = more overshoot/bounciness. Higher = sluggish.
@export var max_distance : float = .3   # The maximum distance tether

var owner_player : Player
var mouse_input := Vector2.ZERO
var headbob_time := 0.0

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_input = event.relative

func setup(base_owner : Node):
	owner_player = base_owner
	main_camera.make_current()


func update_camera_controller(delta: float) -> void:
	if owner_player == null: return
	
	var new_y = calculate_spring_position(self.global_position,
	camera_controller_anchor.global_position,
	owner_player.velocity,
	spring_stiffness,
	spring_damping,
	max_distance,
	delta).position.y
	
	self.global_position = Vector3(camera_controller_anchor.global_position.x, new_y, camera_controller_anchor.global_position.z)
	
	_update_camera_rotation()
	_handle_active_camera_effects(delta)

func _update_camera_rotation():
	if not Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED: return
	
	owner_player.rotate_y(-mouse_input.x * owner_player.look_sensitivity)
	main_camera.rotate_x(-mouse_input.y * owner_player.look_sensitivity)
	main_camera.rotation.x = clamp(main_camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))
	mouse_input = Vector2.ZERO

func _handle_active_camera_effects(_delta) -> void:
	if owner_player.side_sway_on:
		side_sway_effect()

func side_sway_effect() -> void:
	if owner_player.input_dir.x > 0:
		head.rotation.z = lerp_angle(head.rotation.z, deg_to_rad(-owner_player.side_tilt_amount), 0.05)
	elif owner_player.input_dir.x < 0:
		head.rotation.z = lerp_angle(head.rotation.z, deg_to_rad(owner_player.side_tilt_amount), 0.05)
	else:
		head.rotation.z = lerp_angle(head.rotation.z, deg_to_rad(0), 0.05)

func headbob_effect(delta, speed_multiplier : float = 0.0) -> void:
	if owner_player == null: return
	if !owner_player.headbob_on: return
	if !owner_player.is_multiplayer_authority(): return
	
	headbob_time += delta * owner_player.velocity.length()

	main_camera.transform.origin = lerp(main_camera.transform.origin, 
		Vector3(
			cos(headbob_time * (owner_player.headbob_frequency + speed_multiplier) * 0.5) * owner_player.headbob_move_amount,
			sin(headbob_time * (owner_player.headbob_frequency + speed_multiplier)) * owner_player.headbob_move_amount,
			0
		),
	delta * 10.0
	)
	
	
	 

func calculate_spring_position(current_pos: Vector3, target_pos: Vector3, current_vel: Vector3, stiffness: float, damping: float, max_dist: float, delta: float) -> Dictionary:
	# 1. Physics Calculation
	var displacement = target_pos - current_pos
	var spring_force = (displacement * stiffness) - (current_vel * damping)
	var new_vel = current_vel + (spring_force * delta)
	var next_pos = current_pos + (new_vel * delta)
	
	# 2. Distance Tethering
	if max_dist > 0:
		var offset = next_pos - target_pos
		if offset.length() > max_dist:
			next_pos = target_pos + offset.limit_length(max_dist)
			# Kill outward momentum if at boundary to prevent jitters
			new_vel = Vector3.ZERO 
			
	# Return both the new position and the updated velocity 
	# (You MUST store the returned velocity in your object for the next frame!)
	return {"position": next_pos, "velocity": new_vel}
