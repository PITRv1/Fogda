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
				
				client_tag_confirmed.rpc_id(tagger_id, tagger_id, target_id)
				client_you_were_tagged.rpc_id(target_id, target_id, tagger_id)
	# TODO : Implament Normal hit mechanics and optimize this "if" hellscape c


@rpc("any_peer", "reliable", "call_local")
func client_tag_confirmed(tagger_id : int, tagged_id: int) -> void:
	if not multiplayer.is_server() and multiplayer.get_remote_sender_id() != 1: 
		return
		
	get_player_by_id(tagger_id).tag_component.tagged_other(tagged_id)


@rpc("any_peer", "reliable", "call_local")
func client_you_were_tagged(tagged_id : int,tagger_id: int) -> void:
	if not multiplayer.is_server() and multiplayer.get_remote_sender_id() != 1: 
		return
	
	get_player_by_id(tagged_id).tag_component.got_tagged(tagger_id)
	
	
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
