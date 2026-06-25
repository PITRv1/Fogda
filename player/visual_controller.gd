class_name VisualController extends NetworkOwnedObj

@export var tag_component : TagComponent
@export var mesh : MeshInstance3D

const OUTLINE_MAT : BaseMaterial3D = preload("uid://dkxj8d86s1h8n")

func _ready() -> void:
	tag_component.tagged_changed.connect(set_outline_state)

func setup(base_owner : Node):
	owner_entity = base_owner as Player
	
	set_outline_state(owner_entity.tag_component.tagged)

func set_outline_state(state : bool):
	if safety_check_invalid(): return

	print("I shoudl paint myself")

	if state == true:
		mesh.material_overlay = OUTLINE_MAT
	else:
		mesh.material_overlay = null


func safety_check_invalid() -> bool:
	if not is_instance_valid(mesh):
		push_error("VisualController: MeshInstance3D is missing or destroyed!")
		return true
	return false
