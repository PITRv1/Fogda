class_name Player extends CharacterBody3D

@export var dummy : bool = false

@export_category("Controllers")
@export var camera_controller : CameraController
@export var input_handeler : InputHandeler
@export var visual_controller : VisualController

@export_category("Components")
@export var state_machine : StateMachine
@export var tag_component : TagComponent

@export_category("Camera")
@export_range(.0001,.003,.0001) var look_sensitivity := 0.01
@export_group("Side Sway Effect")
@export var side_sway_on : bool = true
@export var side_tilt_amount : float = 1.5
@export_group("Headbob Effects") 
@export var headbob_on : bool = true
@export var headbob_move_amount := 0.04 
@export var headbob_frequency := 1.4

@export_category("Global movement variables")
@export var local_gravity := 16.0
@export var jump_power := 5.0

@export_group("Ground")
@export var walk_speed := 6.0
@export var sprint_speed := 9.0

@export var crouch_speed := 5.0

@export var max_stamina := 1.0

@export var ground_accel := 14.0
@export var ground_decel := 10.0
@export var ground_friction := 6.0

@export_subgroup("Slide")
@export var slide_boost_power := 5.0
@export var slide_speed_threshold := 8.0
@export var vel_cam_allignment_allowed_deviation := 0.3

@export_subgroup("Stamina")
@export var use_stamina := true
@export var stamina_full_refill_time_s := 5.0
@export var stamina_minimum := -0.4
@export var stamina_depleat_multiplier := 1.5

@export_group("Air")
@export var max_vertical_velocity := 100.0
@export_range(1,2,.1) var falling_gravity_multiplier := 1.1
@export var air_cap := 0.85
@export var air_accel := 5.0
@export var air_move_speed := 5.0
@export var airstrafe_penalty_start := 7.0   # kicks in just before walk speed
@export var airstrafe_penalty_exp := 4.0       # exponent, higher = harsher curve

@onready var stairs_ahead_raycast: RayCast3D = %StairsAheadRayCast
@onready var stairs_below_raycast: RayCast3D = %StairsBelowRayCast

#Saved inputs and directions
var input_dir := Vector2.ZERO
var wish_dir := Vector3.ZERO

#Stair movment variables
const MAX_STEP_HEIGHT := 0.5
var _snapped_to_stairs_last_frame := false
var _last_frame_was_on_floor = -INF

var current_speed : float = walk_speed

var crouch_translate := 0.5
var is_crouched := false
var can_slide := true

var jump_avalible := false
var jump_buffer_running := false
var coyote_timer_running := false

var stamina := 1.0
var is_depleted := false

var is_dead : bool = false


func _enter_tree() -> void:
	if dummy: 
		push_warning("A dummy exists on the server on id: 9999")
		self.name = str(9999)
	
	set_multiplayer_authority(name.to_int())
	add_to_group("players")

func _ready() -> void:
	if dummy:
		state_machine.disabled = true
		set_process(false)
		set_physics_process(false)
		
		tag_component.setup(self)
		visual_controller.setup(self)
		return
	
	if is_multiplayer_authority():
		camera_controller.setup(self)
		state_machine.setup(self)
		input_handeler.setup(self)
		tag_component.setup(self)
		visual_controller.setup(self)
		
		var rnd_x = randf_range(-5,5)
		var rnd_z = randf_range(-5,5)
		self.global_position = Vector3(rnd_x, 2, rnd_z)
		
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		
		input_handeler.jump_pressed.connect(start_jump_buffer)
		input_handeler.m_left_clicked.connect(hit)
	else:
		set_process(false)
		set_physics_process(false)
		state_machine.disabled = true


func _physics_process(delta: float) -> void:
	if is_multiplayer_authority():
		camera_controller.update_camera_controller(delta)


#region Stairs && Slope checks && Movement

func is_surface_too_steep(normal : Vector3) -> bool:
	return normal.angle_to(Vector3.UP) > self.floor_max_angle

func snap_down_to_stairs_check() -> void:
	var did_snap := false
	
	stairs_below_raycast.force_raycast_update()
	var _floor_below : bool = stairs_below_raycast.is_colliding() and not is_surface_too_steep(stairs_below_raycast.get_collision_normal())
	var was_on_floor_last_frame = Engine.get_physics_frames() == _last_frame_was_on_floor

	if not is_on_floor() and velocity.y <= 0 and (was_on_floor_last_frame or _snapped_to_stairs_last_frame):
		var body_test_result = KinematicCollision3D.new()
		if self.test_move(self.global_transform, Vector3(0,-MAX_STEP_HEIGHT,0), body_test_result):
			var translate_y = body_test_result.get_travel().y
			self.position.y += translate_y
			apply_floor_snap()

			did_snap = true
	_snapped_to_stairs_last_frame = did_snap

func snap_up_to_stairs_check(delta) -> bool:
	if not is_on_floor() and not _snapped_to_stairs_last_frame: return false
	if self.velocity.y > 0 or (self.velocity * Vector3(1,0,1)).length() == 0: return false
	var expected_move_motion = self.velocity * Vector3(1,0,1) * delta
	var step_pos_with_clearance = self.global_transform.translated(expected_move_motion + Vector3(0, MAX_STEP_HEIGHT * 2, 0))
	var down_check_result = KinematicCollision3D.new()
	if (self.test_move(step_pos_with_clearance, Vector3(0,-MAX_STEP_HEIGHT*2,0), down_check_result)
	and (down_check_result.get_collider().is_class("StaticBody3D") or down_check_result.get_collider().is_class("CSGShape3D"))):
		var step_height = ((step_pos_with_clearance.origin + down_check_result.get_travel()) - self.global_position).y
		if step_height > MAX_STEP_HEIGHT or step_height <= 0.01 or (down_check_result.get_position() - self.global_position).y > MAX_STEP_HEIGHT: return false
		stairs_below_raycast.global_position = down_check_result.get_position() + Vector3(0,MAX_STEP_HEIGHT,0) + expected_move_motion.normalized() * 0.1
		stairs_below_raycast.force_raycast_update()
		if stairs_below_raycast.is_colliding() and not is_surface_too_steep(stairs_below_raycast.get_collision_normal()):

			self.global_position = step_pos_with_clearance.origin + down_check_result.get_travel()
			apply_floor_snap()
			_snapped_to_stairs_last_frame = true
			
			return true
	return false
#endregion

#region Player Physics

func friction(target_speed, applied_friction, delta:float) ->void:
	var control = max(self.velocity.length(), ground_decel)
	var drop = control * applied_friction * delta
	var new_speed = max(self.velocity.length() - drop, target_speed)
	if self.velocity.length() > 0:
		new_speed /= self.velocity.length()
	self.velocity *= new_speed


func _handle_ground_physics(delta: float) -> void:
	var add_speed_till_cap = current_speed - Vector3(self.velocity.x, 0, self.velocity.z).length()
	
	if add_speed_till_cap > 0:
		var accel_speed = ground_accel * delta * current_speed

		self.velocity += accel_speed * wish_dir  
	
	friction(0.0, ground_friction, delta)
	
func _handle_air_physics(delta: float) -> void:
	var cur_speed_in_wish_dir = self.velocity.dot(wish_dir)
	var capped_speed = min((air_move_speed * wish_dir).length(), air_cap)
	var add_speed_till_cap = capped_speed - cur_speed_in_wish_dir
	if add_speed_till_cap > 0:
		# Calculate penalty based on horizontal speed
		var flat_speed = Vector3(self.velocity.x, 0, self.velocity.z).length()
		var excess = max(flat_speed - airstrafe_penalty_start, 0.0)
		var penalty = 1.0 / (1.0 + pow(excess / airstrafe_penalty_start, airstrafe_penalty_exp))

		var accel_speed = air_accel * air_move_speed * delta * penalty
		accel_speed = min(accel_speed, add_speed_till_cap)
		self.velocity += accel_speed * wish_dir
#endregion


func _handle_jump():
	if is_on_floor():
		jump_avalible = true
		
		if jump_buffer_running:
			jump()
	
	if Input.is_action_just_pressed("jump") and coyote_timer_running and jump_avalible:
		jump()

func jump() -> void:
	jump_avalible = false
	self.velocity.y = 0 
	self.velocity.y += jump_power


func start_jump_buffer():
	if jump_buffer_running: return
	
	get_tree().create_timer(0.15).timeout.connect(_on_jump_buffer_timer_timeout)
	jump_buffer_running = true
	
func start_coyote_timer():
	if coyote_timer_running: return
	
	get_tree().create_timer(0.1).timeout.connect(_on_coyote_timer_timeout)
	coyote_timer_running = true

func _on_jump_buffer_timer_timeout() -> void:
	jump_buffer_running = false
	
func _on_coyote_timer_timeout() -> void:
	coyote_timer_running = false



@onready var _original_capsule_height = %PlayerCollision.shape.height
func _handle_crouch(delta) -> void:
	camera_controller.head.position.y =  lerp(camera_controller.head.position.y, -crouch_translate if is_crouched else 0.0, 25.0 * delta)
	%PlayerCollision.shape.height = _original_capsule_height - crouch_translate if is_crouched else _original_capsule_height
	%PlayerCollision.position.y = %PlayerCollision.shape.height / 2

func _can_uncrouch():
	return not test_move(transform, Vector3(0,crouch_translate,0))


func _is_velocity_aligned_with_camera():
	var desire_direction = -camera_controller.main_camera.global_transform.basis.z
	
	var flat_desire_dir = Vector3(desire_direction.x,0,desire_direction.y).normalized()
	
	return 1.0 - vel_cam_allignment_allowed_deviation < clampf(flat_desire_dir.dot(wish_dir),-1,1)


##################################

func fill_stamina(delta):
	if not use_stamina:
		return
	
	stamina += delta / stamina_full_refill_time_s
	stamina = min(stamina, 1.0)
	
	if stamina >= 0.0:
		is_depleted = false

func depleat_stamina(delta):
	if not use_stamina:
		return
	
	if is_depleted:
		return
	
	var depletion_rate = (delta / stamina_full_refill_time_s) * stamina_depleat_multiplier
	stamina -= depletion_rate
	
	if stamina <= stamina_minimum:
		stamina = stamina_minimum
		is_depleted = true

func can_use_stamina() -> bool:
	return not is_depleted
	
####################################################

#Callables for the movement states
func update_gravity(delta, gravity : float = local_gravity) -> void:
	self.velocity.y -= gravity * delta
	self.velocity.y = max(self.velocity.y, -max_vertical_velocity)


func update_input(delta) -> void:
	if not is_multiplayer_authority(): return

	if is_on_floor(): _last_frame_was_on_floor = Engine.get_physics_frames()

	# Read local inputs directly
	input_dir = input_handeler.input_dir
	wish_dir = self.global_transform.basis * Vector3(input_dir.x, 0., input_dir.y)
	can_slide = _is_velocity_aligned_with_camera() and input_handeler.crouch_held
	
	_handle_crouch(delta)

	if is_on_floor() or _snapped_to_stairs_last_frame:
		_handle_ground_physics(delta)
	else:
		_handle_air_physics(delta)
	
	_handle_jump()
	
	
func update_velocity(delta) -> void:
	if not is_multiplayer_authority(): return
	
	if not snap_up_to_stairs_check(delta):
		move_and_slide()
		snap_down_to_stairs_check()


func hit():
	if not is_multiplayer_authority(): return

	var reach = 5.0
	var target_pos = camera_controller.main_camera.global_position - camera_controller.main_camera.global_transform.basis.z * reach
	var result : Dictionary = Global.query_space(self, camera_controller.main_camera.global_position, target_pos)
	
	if !result: return
	var collider : Node3D = result.collider
	
	
	if collider is Player:
		
		# Bypass the normal server logic for testdummy cause it wont work otherwise
		if collider.dummy:
			if self.tag_component.tagged:
				if not collider.tag_component.tagged:
					tag_component.tagged_other(collider.name.to_int())
					collider.tag_component.receive_tag(self.get_multiplayer_authority())
			return
		
		var target_peer_id = collider.get_multiplayer_authority()
		Global.server_process_hit_attempt.rpc_id(1, target_peer_id)
		
	else:
		print("I hate the floor")
