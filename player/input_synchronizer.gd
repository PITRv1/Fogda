extends MultiplayerSynchronizer

var input_dir := Vector2.ZERO

func _ready() -> void:
	
	if get_multiplayer_authority() != multiplayer.get_unique_id():
		set_process(false)
		set_physics_process(false)
		
	input_dir = Input.get_vector("left", "right", "forward", "back").normalized()

func _physics_process(_delta: float) -> void:
	input_dir = Input.get_vector("left", "right", "forward", "back").normalized()
	
