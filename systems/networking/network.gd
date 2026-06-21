extends Node

var lobby_id : int = 0
var peer : SteamMultiplayerPeer

var is_host : bool = false
var is_joining : bool = false

func _ready() -> void:
	print("Steam initialized: ", Steam.steamInit(480, true))
	Steam.initRelayNetworkAccess()
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_joined.connect(_on_lobby_joined)
	
func host_lobby():
	Steam.createLobby(Steam.LobbyType.LOBBY_TYPE_PUBLIC, 16)
	is_host = true

func _on_lobby_created(results : int, lobby_id : int):
	if results == Steam.Result.RESULT_OK:
		self.lobby_id = lobby_id
		
		peer = SteamMultiplayerPeer.new()
		peer.server_relay = true
		peer.create_host()
		
		multiplayer.multiplayer_peer = peer
		multiplayer.peer_connected.connect(_on_peer_connected)
		multiplayer.peer_disconnected.connect(remove_player)
		add_player(1)
		DisplayServer.clipboard_set(str(Network.lobby_id))

func _on_peer_connected(id : int):
	if not multiplayer.is_server():
		return
	
	add_player(id)

func join_lobby(lobby_id : int):
	is_joining = true
	Steam.joinLobby(lobby_id)
	
func _on_lobby_joined(lobby_id : int, permissions : int, locked : bool, response : int):
	if !is_joining: return
	
	self.lobby_id = lobby_id
	peer = SteamMultiplayerPeer.new()
	peer.server_relay = true
	peer.create_client(Steam.getLobbyOwner(lobby_id))
	multiplayer.multiplayer_peer = peer
	
	is_joining = false

func add_player(id : int = 1):
	if not multiplayer.is_server():
		return
	
	var player = GlobalAssets.PLAYER.instantiate()
	player.name = str(id)
	Global.game_manager.world_conatiner.add_child.call_deferred(player, true)

func remove_player(id : int):
	if not multiplayer.is_server():
		return

	var players := get_tree().get_nodes_in_group("players")
	var player_to_remove : int = players.find_custom(func(item): return item.name == str(id))
	
	if player_to_remove != -1:
		players[player_to_remove].queue_free()
	
