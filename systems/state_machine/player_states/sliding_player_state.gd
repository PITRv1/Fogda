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
	owner_entity.ground_friction = 0.8
	
	# gl understanding this shit future me lmao
	desire_direction = -owner_entity.camera_controller.main_camera.global_transform.basis.z
	var flat_desire_dir = Vector3(desire_direction.x,0,desire_direction.z).normalized()
	var boost_dir = (flat_desire_dir + owner_entity.wish_dir).normalized()
	
	var flat_speed = Vector3(owner_entity.velocity.x, 0, owner_entity.velocity.z).length()
	var boost_ratio = flat_speed / (owner_entity.sprint_speed + 1)
	var boost_flipped = 1.0 - boost_ratio
	
	var new_boost = owner_entity.slide_boost_power + owner_entity.slide_boost_power * boost_flipped
	
	owner_entity.velocity += boost_dir * new_boost
	
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

func update(_delta: float)->void:
	if owner_entity.input_handeler.crouch_held and owner_entity.velocity.length() < owner_entity.slide_speed_threshold:
		is_next_state_crouch_state = true
		transition.emit(crouch_state)
		
	if not owner_entity.input_handeler.crouch_held and owner_entity._can_uncrouch():
		transition.emit(idle_state)

func physics_update(delta: float)->void:
	owner_entity.update_gravity(delta)
	owner_entity.update_input(delta)

	owner_entity.update_velocity(delta)
