extends Node

var game_manager : GameManager

@rpc("any_peer", "reliable", "call_local")
func server_process_hit_attempt(target_id : int, hitter_velocity : Vector3):
	if not multiplayer.is_server(): return
	
	var tagger_id := multiplayer.get_remote_sender_id()
	
	var tagger_player : Player = get_player_by_id(tagger_id)
	var target_player : Player = get_player_by_id(target_id)
	if tagger_player == null or target_player == null: 
		push_error("Either the tagger player or the target player can not be found")
		return 
	
	var tag_happened := tagger_player.tag_component.tagged and not target_player.tag_component.tagged
	
	client_hit_confirmed.rpc_id(tagger_id, tagger_id, target_id, tag_happened)
	client_you_were_hit.rpc_id(target_id, target_id, tagger_id, hitter_velocity, tag_happened)

func _is_from_server() -> bool:
	return multiplayer.is_server() or multiplayer.get_remote_sender_id() == 1
 
 
@rpc("any_peer", "reliable", "call_local")
func client_hit_confirmed(tagger_id : int, tagged_id : int, tag_happened : bool) -> void:
	if not _is_from_server(): return
	
	var tag_component := get_player_by_id(tagger_id).tag_component
	if tag_happened:
		tag_component.tagged_other(tagged_id)
	else:
		tag_component.hit_other(tagged_id)
 
 
@rpc("any_peer", "reliable", "call_local")
func client_you_were_hit(tagged_id : int, tagger_id : int, hitter_velocity : Vector3, tag_happened : bool) -> void:
	if not _is_from_server(): return
	
	var tag_component := get_player_by_id(tagged_id).tag_component
	if tag_happened:
		tag_component.receive_tag(tagger_id, hitter_velocity)
	else:
		tag_component.receive_hit(tagger_id, hitter_velocity)
 
	
func get_player_by_id(id : int) -> Player:
	var players := get_tree().get_nodes_in_group("players")
	var player_index : int = players.find_custom(func(item): return item.name == str(id))
	
	if player_index == -1:
		return null
	
	var player : Player = players[player_index]
	return player






func query_space(on_this_node : Node3D, from : Vector3, to : Vector3) -> Dictionary:
	var space_state = on_this_node.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	
	return space_state.intersect_ray(query)
	

@rpc("any_peer", "call_local", "reliable")
func rpc_request_spawn():
	var sender_id = multiplayer.get_remote_sender_id()
	
	var available_points = Global.game_manager.current_map.spawn_points.filter(
		func(item : SpawnPoint): return not item.taken
	)
	
	if available_points.size() > 0:
		var chosen_point = available_points.pick_random()
		chosen_point.taken = true
		
		rpc_receive_spawn_position.rpc_id(sender_id, chosen_point.global_position)
	else:
		push_warning("Server: Out of spawn points!")
		rpc_receive_spawn_position.rpc_id(sender_id, Vector3.ZERO)

@rpc("authority", "call_local", "reliable")
func rpc_receive_spawn_position(spawn_pos : Vector3):
	var my_id = multiplayer.get_unique_id()
	var my_player = Global.get_player_by_id(my_id)
	
	if is_instance_valid(my_player):
		my_player.global_position = spawn_pos
		#print("Client: Successfully spawned at assigned position: ", spawn_pos)
	
