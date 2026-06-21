class_name SprintingPlayerState extends PlayerState

@export var idle_state : IdlePlayerState
@export var inair_state : InAirPlayerState
@export var walking_state : WalkingPlayerState


func enter(_prev_state):
	owner_entity.current_speed = owner_entity.sprint_speed


func update(_delta : float) -> void:
	if owner_entity.velocity.length() <= 0:
		transition.emit(idle_state)
	
	if not Global.game_manager.input_handeler.sprint_held:
		transition.emit(walking_state)
	
	if not owner_entity.is_on_floor():
		transition.emit(inair_state)

	if not owner_entity.can_use_stamina():
		transition.emit(walking_state)

func physics_update(delta: float) -> void:
	owner_entity.update_gravity(delta)
	owner_entity.update_input(delta)
	owner_entity.update_velocity(delta)
	
	owner_entity.camera_controller.headbob_effect(delta, .5)
	
	owner_entity.depleat_stamina(delta)
