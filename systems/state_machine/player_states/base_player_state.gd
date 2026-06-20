class_name PlayerState extends State

var owner_entity : Player

func _ready() -> void:
	state_owner_set.connect( func(): owner_entity = state_owner as Player )
