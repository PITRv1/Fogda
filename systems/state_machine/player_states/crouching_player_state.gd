class_name CrouchingPlayerState extends PlayerState
	
@export var idle_state : IdlePlayerState
@export var inair_state : InAirPlayerState
@export var sprinting_state : SprintingPlayerState

	
func enter(_prev_state):
	owner_entity.current_speed = owner_entity.crouch_speed
	owner_entity.is_crouched = true
	owner_entity.side_sway_on = false

func exit():
	owner_entity.is_crouched = false
	owner_entity.side_sway_on = true
	
func update(_delta : float) -> void:
	if not owner_entity.is_on_floor():
		transition.emit(inair_state)
#
	if not owner_entity.input_handeler.crouch_held and owner_entity._can_uncrouch():
		transition.emit(idle_state)

func physics_update(delta: float) -> void:
	owner_entity.update_gravity(delta)
	owner_entity.update_input(delta)
	owner_entity.update_velocity(delta)
	
	owner_entity.fill_stamina(delta)
