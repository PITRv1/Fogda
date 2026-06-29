class_name TagComponent extends NetworkOwnedObj

signal tagged_changed(new_state : bool)

@export var hit_power : float = 10.0
@export var tagged : bool = false:
	set(value):
		if tagged != value:
			tagged = value

			tagged_changed.emit(tagged)

var owner_player : Player


func setup(base_owner : Node):
	owner_player = base_owner as Player

func tagged_other(tagged_player_id : int):
	if not owner_player.is_multiplayer_authority(): return
	tagged = false
	
	#print("tagged some1")
	
	hit_other(tagged_player_id)

func hit_other(hit_player_id : int):
	if not owner_player.is_multiplayer_authority(): return
	pass

	
func receive_tag(tagger_player_id : int):
	if not owner_player.is_multiplayer_authority(): return
		
	#print("Tagged by Player #", tagger_player_id)
	tagged = true
	
	receive_hit(tagger_player_id)

func receive_hit(hitting_player_id : int):
	var hitting_player : Player = Global.get_player_by_id(hitting_player_id)
	
	var true_hitting_center : Vector3 = Vector3(hitting_player.global_position.x, hitting_player.global_position.y + hitting_player.collision.shape.height * 0.5 , hitting_player.global_position.z)
	var true_owner_center : Vector3 = Vector3(owner_player.global_position.x, owner_player.global_position.y + owner_player.collision.shape.height * 0.5 , owner_player.global_position.z)
	
	var hit_direction = true_hitting_center.direction_to(true_owner_center)
	
	owner_player.velocity += hit_direction * hitting_player.tag_component.hit_power
	
	
	#owner_player.velocity += -hitting_player.camera_controller.main_camera.global_transform.basis.z * hitting_player.tag_component.hit_power
	#print("Hit by Player #", hitting_player_id)
