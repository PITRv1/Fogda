class_name PlayerUI extends CanvasLayer

var owner_player : Player

@onready var label_game_start_coutdown: Label = %LabelGameStartCoutdown

func _ready() -> void:
	Network.countdown_updated.connect(func(time_left : int): label_game_start_coutdown.text = str(time_left))
	Network.countdown_canceled.connect(func(): label_game_start_coutdown.text = "")
	Network.game_started.connect(func(): label_game_start_coutdown.text = "")

	Network.round_time_updated.connect(_on_round_time_updated)

func _on_round_time_updated(time_left: int):
	if !owner_player.is_multiplayer_authority(): return
	
	var minutes = time_left / 60
	var seconds = time_left % 60
	label_game_start_coutdown.text = "%02d:%02d" % [minutes, seconds]
