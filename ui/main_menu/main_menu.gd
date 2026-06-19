extends CanvasLayer

@onready var button_host: Button = %ButtonHost
@onready var line_edit_lobby_id: LineEdit = %LineEditLobbyId
@onready var button_join: Button = %ButtonJoin


func _ready() -> void:
	button_host.pressed.connect(_on_host_pressed)
	line_edit_lobby_id.text_changed.connect(_on_lobby_id_changed)
	button_join.pressed.connect(_on_join_pressed)

func _on_host_pressed():
	Network.host_lobby()
	hide()
	
func _on_lobby_id_changed(new_id : String):
	button_join.disabled = (new_id.length() == 0)
	
func _on_join_pressed():
	Network.join_lobby(line_edit_lobby_id.text.to_int())
	DisplayServer.clipboard_set(str(Network.lobby_id))
	hide()
