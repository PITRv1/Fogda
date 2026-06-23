class_name TagComponent extends Node3D

@export var tagged : bool = false

func tag_self():
	tagged = true
	
func clear_self_tag():
	tagged = false
