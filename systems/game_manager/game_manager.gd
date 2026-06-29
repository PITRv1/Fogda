class_name GameManager extends Node

@export var world_conatiner : Node3D

var current_map : Map

func _enter_tree() -> void: 
	Global.game_manager = self
	
func _ready() -> void:
	Network.game_started.connect(round_started)
	Network.round_ended.connect(reset_round)

func round_started() -> void: 
	for player : Player in get_tree().get_nodes_in_group("players"):
		if player.is_multiplayer_authority():
			player.disabled = false
			player.state_machine.disabled = false
	
	if multiplayer.is_server():
		pick_tagger.rpc_id(1)
	
@rpc("any_peer", "call_local")
func pick_tagger():
	var taggers = get_tree().get_nodes_in_group("players")
	var tagger = taggers.pick_random()
	
	set_tagger.rpc_id(tagger.name.to_int())

@rpc("authority", "reliable", "call_local")
func set_tagger():
	Global.get_player_by_id(multiplayer.get_unique_id()).tag_component.tagged = true

func load_map(map_scene : PackedScene):
	var map : Map = map_scene.instantiate() as Map
	
	world_conatiner.add_child(map)

	current_map = map
	
func reset_round() -> void:
	print("Resetting round variables and preparing next match...")
	
	for player : Player in get_tree().get_nodes_in_group("players"):
		player.disabled = true
		player.state_machine.disabled = true
		player.velocity = Vector3.ZERO
		
		if player.tag_component:
			player.tag_component.tagged = false
		
		if player.is_multiplayer_authority():
			Global.rpc_request_spawn.rpc_id(1)

	if multiplayer.is_server():
		for spawn_point in current_map.spawn_points:
			spawn_point.taken = false
			
		Network.check_lobby_capacity()
