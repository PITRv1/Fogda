class_name InAirPlayerState extends PlayerState

@export var idle_state : IdlePlayerState
@export var sliding_state : SlidingPlayerState


var can_start_coyote_timer : bool = true

func enter(_prev_state)->void:
	can_start_coyote_timer = true

func update(_delta : float) -> void:	
	if owner_entity.input_handeler.crouch_held and Vector3(owner_entity.velocity.x,0,owner_entity.velocity.y).length() > owner_entity.slide_speed_threshold and owner_entity.can_slide:
		if owner_entity.is_on_floor():
			transition.emit(sliding_state)

	if owner_entity.is_on_floor():
		transition.emit(idle_state)
		
	if owner_entity.jump_avalible and can_start_coyote_timer and not owner_entity.coyote_timer_running:
		can_start_coyote_timer = false
		owner_entity.start_coyote_timer()
		
func physics_update(delta: float) -> void:
	if owner_entity.velocity < Vector3.ZERO:
		owner_entity.update_gravity(delta, owner_entity.local_gravity * owner_entity.falling_gravity_multiplier)
	else:
		owner_entity.update_gravity(delta)
	owner_entity.update_input(delta)
	owner_entity.update_velocity(delta)
	
	owner_entity.fill_stamina(delta)
