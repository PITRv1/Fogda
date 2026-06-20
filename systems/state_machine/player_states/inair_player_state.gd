class_name InAirPlayerState extends PlayerState

@export var idle_state : IdlePlayerState


func update(_delta : float) -> void:
	if owner_entity.is_on_floor():
		transition.emit(idle_state)

func physics_update(delta: float) -> void:
	if owner_entity.velocity < Vector3.ZERO:
		owner_entity.update_gravity(delta, owner_entity.local_gravity * owner_entity.falling_gravity_multiplier)
	else:
		owner_entity.update_gravity(delta)
	owner_entity.update_input(delta)
	owner_entity.update_velocity(delta)
	
	owner_entity.fill_stamina(delta)
