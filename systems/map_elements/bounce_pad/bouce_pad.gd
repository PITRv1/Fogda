class_name BouncePad extends Area3D

@export var bounce_power : float = 30.0
@export var addative : bool = false

func _on_body_entered(body: Node3D) -> void:
	if body is Player and body.is_multiplayer_authority():
		bouce_player(body)

func bouce_player(target_palyer : Player):
	target_palyer.velocity.y = 0
	
	if addative:
		target_palyer.velocity.y += bounce_power
	else:
	
		target_palyer.velocity.y = bounce_power
	
