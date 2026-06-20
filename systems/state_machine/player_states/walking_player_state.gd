class_name WalkingPlayerState extends PlayerState

@export var idle_state : IdlePlayerState
@export var inair_state : InAirPlayerState


func enter(_prev_state):
	owner_entity.current_speed = owner_entity.walk_speed
	

func update(_delta : float) -> void:
	if owner_entity.velocity.length() <= 0:
		transition.emit(idle_state)
	
	if not owner_entity.is_on_floor():
		transition.emit(inair_state)
	
	#if Global.game_manager.input_handeler.crouch_held:
		#transition.emit(crouching_state)
		#
	#if Global.game_manager.input_handeler.sprint_held and owner_entity.can_use_stamina():
		#transition.emit(sprinting_state)
	#
	#if Global.game_manager.input_handeler.noclip_just_pressed and OS.is_debug_build():
		#transition.emit(noclip_state)

func physics_update(delta: float) -> void:
	owner_entity.update_gravity(delta)
	owner_entity.update_input(delta)
	owner_entity.update_velocity(delta)
	
	owner_entity.camera_controller.headbob_effect(delta)
	
	owner_entity.fill_stamina(delta)
