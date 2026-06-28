class_name GameManager extends Node

@export var world_conatiner : Node3D

func _enter_tree() -> void: 
	Global.game_manager = self
	
func _ready() -> void:
	Network.game_started.connect(round_started)

func round_started() -> void: 
	for player : Player in get_tree().get_nodes_in_group("players"):
		if player.is_multiplayer_authority():
			player.disabled = false
	
	pick_tagger.rpc_id(1)
	
@rpc("any_peer", "call_local")
func pick_tagger():
	var taggers = get_tree().get_nodes_in_group("players")
	var tagger = taggers.pick_random()
	
	set_tagger.rpc_id(tagger.name.to_int())

@rpc("any_peer", "reliable", "call_local")
func set_tagger():
	Global.get_player_by_id(multiplayer.get_unique_id()).tag_component.tagged = true
