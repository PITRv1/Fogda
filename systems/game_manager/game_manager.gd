class_name GameManager extends Node

@export var world_conatiner : Node3D

func _enter_tree() -> void: 
	Global.game_manager = self
