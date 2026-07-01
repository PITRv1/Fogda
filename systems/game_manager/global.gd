extends Node

var game_manager : GameManager

@rpc("any_peer", "reliable", "call_local")
func server_process_hit_attempt(target_id : int):
	if not multiplayer.is_server(): return
	
	var tagger_id := multiplayer.get_remote_sender_id()
	
	var tagger_player : Player = get_player_by_id(tagger_id)
	var target_player : Player = get_player_by_id(target_id)
	if tagger_player == null or target_player == null: 
		push_error("Either the tagger player or the target player can not be found")
		return 
	
	if target_player:
		if tagger_player.tag_component.tagged:
			if not target_player.tag_component.tagged:
				
				client_hit_confirmed.rpc_id(tagger_id, tagger_id, target_id, true)
				client_you_were_hit.rpc_id(target_id, target_id, tagger_id, true)
				
			else:
				client_hit_confirmed.rpc_id(tagger_id, tagger_id, target_id, false)
				client_you_were_hit.rpc_id(target_id, target_id, tagger_id, false)
			
		else:
			client_hit_confirmed.rpc_id(tagger_id, tagger_id, target_id, false)
			client_you_were_hit.rpc_id(target_id, target_id, tagger_id, false)
			
	# TODO : Implament Normal hit mechanics and optimize this "if" hellscape c


@rpc("any_peer", "reliable", "call_local")
func client_hit_confirmed(tagger_id : int, tagged_id: int, tag_happened : bool) -> void:
	if not multiplayer.is_server() and multiplayer.get_remote_sender_id() != 1: 
		return
	
	if tag_happened:
		get_player_by_id(tagger_id).tag_component.tagged_other(tagged_id)
	else:
		get_player_by_id(tagger_id).tag_component.hit_other(tagged_id)
		

@rpc("any_peer", "reliable", "call_local")
func client_you_were_hit(tagged_id : int,tagger_id: int, tag_happened : bool) -> void:
	if not multiplayer.is_server() and multiplayer.get_remote_sender_id() != 1: 
		return
	
	if tag_happened:
		get_player_by_id(tagged_id).tag_component.receive_tag(tagger_id)
	else:
		get_player_by_id(tagged_id).tag_component.receive_hit(tagger_id)

	
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
	
