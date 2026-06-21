class_name CameraController extends Node3D

@export var camera_controller_anchor: Marker3D 

@onready var main_camera: Camera3D = %Camera
@onready var head: Node3D = $Head

var owner_player : Player

var mouse_input := Vector2.ZERO
var headbob_time := 0.0

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_input = event.relative

func setup_camera_controller(owner_entity : Player):
	owner_player = owner_entity
	main_camera.make_current()


func update_camera_controller(delta: float) -> void:
	self.global_transform = camera_controller_anchor.get_global_transform_interpolated()
	
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
	if !owner_player.headbob_on: return
	if !owner_player.is_multiplayer_authority() : return
	
	
	headbob_time += delta * owner_player.velocity.length()

	main_camera.transform.origin = lerp(main_camera.transform.origin, 
		Vector3(
			cos(headbob_time * (owner_player.headbob_frequency + speed_multiplier) * 0.5) * owner_player.headbob_move_amount,
			sin(headbob_time * (owner_player.headbob_frequency + speed_multiplier)) * owner_player.headbob_move_amount,
			0
		),
	delta * 10.0
	)
