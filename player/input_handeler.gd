class_name InputHandeler extends NetworkOwnedObj

signal jump_pressed
signal m_left_clicked

@export var invert_sprint : bool = false

var input_dir := Vector2.ZERO

var crouch_held : bool = false
var sprint_held : bool = false

func _physics_process(_delta: float) -> void:
	if owner_entity == null : return
	if !owner_entity.is_multiplayer_authority(): return
	
	input_dir = Input.get_vector("left", "right", "forward", "back").normalized()
	
	crouch_held = Input.is_action_pressed("crouch") 
	sprint_held = !Input.is_action_pressed("sprint") if invert_sprint else Input.is_action_pressed("sprint")
	
	if Input.is_action_just_pressed("jump"):
		jump_pressed.emit()
	
	if Input.is_action_just_pressed("hit"):
		m_left_clicked.emit()
