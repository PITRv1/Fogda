extends Node

signal countdown_updated(time_left : int)
signal countdown_canceled()
signal game_started()

signal round_time_updated(time_left : int)
signal round_ended()

var lobby_id : int = 0
var peer : SteamMultiplayerPeer

var is_host : bool = false
var is_joining : bool = false

var lobby_timer : Timer
var countdown_time : int = 3

var round_timer : Timer
var round_time_left : int = 5 # Default match length: 180 seconds (3 minutes)

var current_selected_map : MapUiResource

## For ENet
const LOCAL_PORT := 8080
const LOCAL_IP := "127.0.0.1"

func _ready() -> void:
	print("Steam initialized: ", Steam.steamInit(480, true))
	Steam.initRelayNetworkAccess()
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_joined.connect(_on_lobby_joined)
	
	lobby_timer = Timer.new()
	lobby_timer.wait_time = 1.0
	lobby_timer.timeout.connect(_on_lobby_timer_tick)
	add_child(lobby_timer)
	
	round_timer = Timer.new()
	round_timer.wait_time = 1.0
	round_timer.timeout.connect(_on_round_timer_tick)
	add_child(round_timer)
	
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
	check_lobby_capacity()

func remove_player(id : int):
	if not multiplayer.is_server():
		return

	var players := get_tree().get_nodes_in_group("players")
	var player_to_remove : int = players.find_custom(func(item): return item.name == str(id))
	
	if player_to_remove != -1:
		players[player_to_remove].queue_free()
	
	check_lobby_capacity()

func host_local():
	var enet_peer := ENetMultiplayerPeer.new()
	var err = enet_peer.create_server(LOCAL_PORT)
	if err != OK:
		print("Failed to host local server: ", err)
		return
		
	multiplayer.multiplayer_peer = enet_peer
	
	if not multiplayer.peer_connected.is_connected(_on_peer_connected):
		multiplayer.peer_connected.connect(_on_peer_connected)
	if not multiplayer.peer_disconnected.is_connected(remove_player):
		multiplayer.peer_disconnected.connect(remove_player)
	
	is_host = true
	
	Global.game_manager.load_map(current_selected_map.map_scene)
	
	add_player(1)
	
	print("Local ENet server started on port ", LOCAL_PORT)
	
func join_local(ip_address : String = LOCAL_IP):
	var enet_peer := ENetMultiplayerPeer.new()
	var err = enet_peer.create_client(ip_address, LOCAL_PORT)
	
	if err != OK:
		print("Failed to join local server: ", err)
		return
		
	multiplayer.multiplayer_peer = enet_peer
	print("Joined local ENet server at ", ip_address)
	
func check_lobby_capacity():
	var total_players = multiplayer.get_peers().size() + 1
	
	if total_players >= 2:
		
		if lobby_timer.is_stopped():
			countdown_time = 5 
			lobby_timer.start()
			rpc_update_countdown.rpc(countdown_time)
	else:
		if not lobby_timer.is_stopped():
			lobby_timer.stop()
			rpc_cancel_countdown.rpc()


func _on_lobby_timer_tick():
	countdown_time -= 1
	rpc_update_countdown.rpc(countdown_time)
	
	if countdown_time <= 0:
		lobby_timer.stop()
		rpc_start_game.rpc()
		
func _on_round_timer_tick():
	round_time_left -= 1
	rpc_update_round_countdown.rpc(round_time_left)
	
	if round_time_left <= 0:
		round_timer.stop()
		rpc_end_round.rpc()

func stop_round_early():
	if multiplayer.is_server() and not round_timer.is_stopped():
		round_timer.stop()
		rpc_end_round.rpc()

@rpc("authority", "call_local", "reliable")
func rpc_update_countdown(time : int):
	countdown_updated.emit(time)

@rpc("authority", "call_local", "reliable")
func rpc_cancel_countdown():
	countdown_canceled.emit()

@rpc("authority", "call_local", "reliable")
func rpc_start_game():
	print('game started')
	game_started.emit()
	
	if multiplayer.is_server():
		round_time_left = 180
		round_timer.start()
		rpc_update_round_countdown.rpc(round_time_left)
	
@rpc("authority", "call_local", "reliable")
func rpc_update_round_countdown(time : int):
	round_time_updated.emit(time)

@rpc("authority", "call_local", "reliable")
func rpc_end_round():
	print('round ended')
	round_ended.emit()
