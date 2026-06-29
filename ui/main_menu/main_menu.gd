extends CanvasLayer

@export var example_map_checkbox : CheckBox

@onready var button_host: Button = %ButtonHost
@onready var line_edit_lobby_id: LineEdit = %LineEditLobbyId
@onready var button_join: Button = %ButtonJoin

@onready var button_host_local: Button = %ButtonHostLocal
@onready var button_join_local: Button = %ButtonJoinLocal

const MAP_BUTTON_GROUP = preload("uid://b82a4hk0b3av")
const MAP_UI_RESOURCE_DIR = "res://assets/maps/map_ui_resources/"

var map_select_buttons : Array[CheckBox]

func _ready() -> void:
	example_map_checkbox.hide()
	
	button_host_local.pressed.connect(_on_host_local_pressed)
	button_join_local.pressed.connect(_on_join_local_pressed)
	
	button_host.pressed.connect(_on_host_pressed)
	line_edit_lobby_id.text_changed.connect(_on_lobby_id_changed)
	button_join.pressed.connect(_on_join_pressed)
	
	for file in DirAccess.get_files_at(MAP_UI_RESOURCE_DIR):
		var new_button : CheckBox = example_map_checkbox.duplicate()
		var map_ui_resource : MapUiResource = ResourceLoader.load(MAP_UI_RESOURCE_DIR + file)
		
		new_button.button_down.connect(_on_choose_map_pressed.bind(map_ui_resource))
		new_button.text = map_ui_resource.name
		
		if file == DirAccess.get_files_at(MAP_UI_RESOURCE_DIR)[0]:
			new_button.button_pressed = true
			_on_choose_map_pressed(map_ui_resource)
		
		new_button.show()
		
		example_map_checkbox.get_parent().add_child(new_button)
		
func _on_host_local_pressed():
	Network.host_local()
	hide()

func _on_join_local_pressed():
	Network.join_local() 
	hide()

func _on_host_pressed():
	Network.host_lobby()
	hide()
	
func _on_lobby_id_changed(new_id : String):
	button_join.disabled = (new_id.length() == 0)
	
func _on_join_pressed():
	Network.join_lobby(line_edit_lobby_id.text.to_int())
	DisplayServer.clipboard_set(str(Network.lobby_id))
	hide()
	
func _on_choose_map_pressed(selected_map : MapUiResource):
	Network.current_selected_map = selected_map
