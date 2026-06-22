class_name IdlePlayerState extends PlayerState

@export var walking_state : WalkingPlayerState
@export var crouching_state : CrouchingPlayerState

func update(_delta: float) -> void:
	if owner_entity.input_handeler.crouch_held:
		transition.emit(crouching_state)

	if owner_entity.velocity.length() > 0:
		transition.emit(walking_state)


func physics_update(delta: float) -> void:
	owner_entity.update_gravity(delta)
	owner_entity.update_input(delta)
	owner_entity.update_velocity(delta)
	
	owner_entity.fill_stamina(delta)
