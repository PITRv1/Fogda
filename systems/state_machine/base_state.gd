class_name State extends Node
@warning_ignore("unused_signal")
signal transition(new_state_signal: StringName)
signal state_owner_set

var is_updating : bool
var state_owner : Node :
	set(value):
		state_owner = value
		state_owner_set.emit()

@warning_ignore("unused_parameter")
func enter(prev_state)->void:
	pass

func exit()->void:
	pass
	
@warning_ignore("unused_parameter")
func update(delta: float)->void:
	pass
	
@warning_ignore("unused_parameter")
func physics_update(delta: float)->void:
	pass
