class_name TagComponent extends NetworkOwnedObj

@export var tagged : bool = false
var owner_player : Player

func setup(base_owner : Node):
	owner_player = base_owner as Player

func tagged_other(tagged_player_id : int):
	print(" I tagged someone : ", tagged_player_id)

func got_tagged(tagger_player_id : int):
	print("I got tagged by", tagger_player_id)

func clear_self_tag():
	tagged = false


#func attempt_tag(on_player : Player):
	#
	#if on_player is Player:
		#var target_peer_id = on_player.get_multiplayer_authority()
		#Global.server_process_tag_attempt.rpc_id(1, target_peer_id)
