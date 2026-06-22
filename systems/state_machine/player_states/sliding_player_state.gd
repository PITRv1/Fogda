class_name SlidingPlayerState extends PlayerState

@export var inair_state : InAirPlayerState

@export var idle_state : IdlePlayerState

@export var crouch_state : CrouchingPlayerState
@export var walking_state : WalkingPlayerState

var saved_friction : float = 0.0
var slide_dir : Vector3
var desire_direction
var is_next_state_crouch_state := false

func enter(_prev_state)->void:
	saved_friction = owner_entity.ground_friction
	owner_entity.ground_friction = 1.0
	
	desire_direction = -owner_entity.camera_controller.main_camera.global_transform.basis.z
	
	var flat_speed = Vector3(owner_entity.velocity.x, 0, owner_entity.velocity.z).length()
	var boost_ratio = flat_speed / (owner_entity.sprint_speed + 1)
	var boost_flipped = 1.0 - boost_ratio
	
	var new_boost = owner_entity.slide_boost_power + owner_entity.slide_boost_power * boost_flipped
	
	owner_entity.velocity += desire_direction * new_boost
	
	owner_entity.is_crouched = true
	owner_entity.side_sway_on = false
	
	is_next_state_crouch_state = false

func exit()->void:
	owner_entity.is_crouched = false
	owner_entity.side_sway_on = true

	if is_next_state_crouch_state:
		owner_entity.is_crouched = true
		owner_entity.side_sway_on = false

	owner_entity.ground_friction = saved_friction
	
	owner_entity.can_slide = false
	get_tree().create_timer(0.001).timeout.connect(func(): owner_entity.can_slide = true)

func update(_delta: float)->void:
	if owner_entity.input_handeler.crouch_held and owner_entity.velocity.length() < owner_entity.slide_speed_threshold:
		is_next_state_crouch_state = true
		transition.emit(crouch_state)
		
	if not owner_entity.input_handeler.crouch_held and owner_entity._can_uncrouch():
		transition.emit(idle_state)

	
	#
	#if Global.player.get_floor_angle(Vector3.UP) == 0.0 and Global.player.get_floor_angle(Vector3.UP) < Global.player.floor_max_angle :
		#transition.emit(walking_state)
		#
	#if not Global.player.is_on_floor(): 
		#transition.emit(inair_state)
	#
	#if not Global.player.player_input_bus.is_crouching:
		#transition.emit(inair_state)

func physics_update(delta: float)->void:
	owner_entity.update_gravity(delta)
	owner_entity.update_input(delta)
	
	#Global.player.velocity.x = lerp(Global.player.velocity.x, desire_direction.x * Global.player.sliding_speed + Global.player.wish_dir.x * Global.player.deviation_power, delta * ((Global.player.get_floor_angle(Vector3.UP) + 1)))
	#Global.player.velocity.z = lerp(Global.player.velocity.z, desire_direction.z * Global.player.sliding_speed + Global.player.wish_dir.z * Global.player.deviation_power, delta * ((Global.player.get_floor_angle(Vector3.UP) + 1)))
	#
	owner_entity.update_velocity(delta)
