class_name GameManager extends Node

@export var world_conatiner : Node3D

var current_map_ui_resource : MapUiResource
var current_map : Map
var subround : int = 0

var next_tagger_id : int = -1

func _enter_tree() -> void: 
	Global.game_manager = self
	
func _ready() -> void:
	Network.game_started.connect(round_started)
	Network.round_ended.connect(reset_round)

func prepare_round():
	var players = get_tree().get_nodes_in_group("players")
	if players.is_empty(): return
	
	var tagger = players.pick_random()
	next_tagger_id = tagger.name.to_int()
	
	sync_tagger_id.rpc(next_tagger_id)

@rpc("authority", "call_local", "reliable")
func sync_tagger_id(id : int):
	next_tagger_id = id
	if multiplayer.get_unique_id() == next_tagger_id:
		var me = Global.get_player_by_id(next_tagger_id)
		if me and me.tag_component:
			me.tag_component.tagged = true

func round_started() -> void: 
	if multiplayer.is_server():
		Global.game_manager.prepare_round()

	for player : Player in get_tree().get_nodes_in_group("players"):
		if player.is_multiplayer_authority():
			player.disabled = false
			player.state_machine.disabled = false
		
func load_map(map_resource : MapUiResource):
	if current_map:
		current_map.queue_free()
	
	var map : Map = map_resource.map_scene.instantiate() as Map
	
	world_conatiner.add_child(map)
	current_map_ui_resource = map_resource
	current_map = map
	
func reset_round() -> void:
	if multiplayer.is_server():
		subround += 1
		
		if subround >= 2:
			var possible_new_map_list : Array[MapUiResource] = []
			
			for value in GlobalAssets.MAPS.values():
				if value == current_map_ui_resource:
					continue
				possible_new_map_list.append(value)
			
			var new_map_ui_resource : MapUiResource = possible_new_map_list.pick_random()
			load_map(new_map_ui_resource)
			subround = 0
		
		for spawn_point in current_map.spawn_points:
			spawn_point.taken = false

	for player : Player in get_tree().get_nodes_in_group("players"):
		player.disabled = true
		player.state_machine.disabled = true
		player.velocity = Vector3.ZERO
		
		if player.tag_component:
			player.tag_component.tagged = false
		
		if player.is_multiplayer_authority():
			Global.rpc_request_spawn.rpc_id(1)
		
		Network.check_lobby_capacity()
