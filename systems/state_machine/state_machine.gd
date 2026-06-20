class_name StateMachine

extends Node

@export var CURRENT_STATE : State
var states : Dictionary[String, State] = {}

var disabled : bool :
	set(value):
		if value == true:
			set_process(false)
			set_physics_process(false)
		else:
			set_process(true)
			set_physics_process(true)


func _ready():
	for child in get_children():
		if child is State:
			states[child.name.to_lower()] = child
			child.transition.connect(on_child_transition)
		else:
			push_warning("State machine contains incompatible child")
		
	await owner.ready
	
	CURRENT_STATE.is_updating = true
	CURRENT_STATE.enter(CURRENT_STATE)
	
func _process(delta):
	CURRENT_STATE.update(delta)

func _physics_process(delta):
	CURRENT_STATE.physics_update(delta)


func setup_state_machine(state_machine_owner):
	for state : State in states.values():
		state.state_owner = state_machine_owner

func on_child_transition(new_state: State)->void:
	#var new_state = states.get(new_state_name.to_lower())
	
	if new_state != null:
		if new_state != CURRENT_STATE:
			CURRENT_STATE.exit()
			CURRENT_STATE.is_updating = false
			#print("------------")
			#print(new_state)
			#print("------------")
			var old_state : State = CURRENT_STATE ## Save old state reference so I can pass it to the new state later. Need to turn on the is_updating flag so the enter function already has it on
			CURRENT_STATE = new_state
			CURRENT_STATE.is_updating = true
			new_state.enter(old_state)
	else:
		push_warning("State does not exist")
