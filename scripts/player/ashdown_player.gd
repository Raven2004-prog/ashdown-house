extends CharacterBody3D

signal interaction_requested(target)
signal target_changed(target)

@export var walk_speed := 3.4
@export var sprint_speed := 5.1
@export var crouch_speed := 1.65
@export var mouse_sensitivity := 0.003
@export var gravity := 18.0
@export var normal_spring_length := 2.65
@export var tight_spring_length := 2.15
@export var camera_pivot_height := 1.48
@export var camera_shoulder_offset := 0.35
@export var interaction_distance := 2.2
@export var camera_ray_distance := 12.0

var input_locked := false
var mouse_captured := false
var current_target = null
var yaw := 0.0
var pitch := -0.14

var camera_yaw: Node3D
var camera_pitch: Node3D
var spring_arm: SpringArm3D
var camera_socket: Node3D
var camera: Camera3D
var interaction_ray: RayCast3D
var visual_root: Node3D

func _ready() -> void:
	_build_runtime_nodes()
	_capture_mouse()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and mouse_captured and not input_locked:
		var motion := event as InputEventMouseMotion
		yaw -= motion.relative.x * mouse_sensitivity
		pitch = clampf(pitch - motion.relative.y * mouse_sensitivity, -0.85, 0.25)
		camera_yaw.rotation.y = yaw
		camera_pitch.rotation.x = pitch
	elif event.is_action_pressed("interact") and not input_locked:
		interaction_ray.force_raycast_update()
		var target = _find_target()
		if target != null:
			interaction_requested.emit(target)
	elif event.is_action_pressed("release_mouse"):
		_release_mouse()
	elif event is InputEventMouseButton and not mouse_captured and not input_locked:
		_capture_mouse()

func _physics_process(delta: float) -> void:
	if input_locked:
		clear_current_target()
		velocity.x = move_toward(velocity.x, 0.0, sprint_speed)
		velocity.z = move_toward(velocity.z, 0.0, sprint_speed)
		_apply_gravity(delta)
		move_and_slide()
		return
	_update_target()
	_apply_movement(delta)
	_adjust_camera_arm(delta)
	move_and_slide()

func set_input_locked(value: bool) -> void:
	input_locked = value
	if input_locked:
		clear_current_target()

func set_start_yaw_degrees(value: float) -> void:
	yaw = deg_to_rad(value)
	if camera_yaw != null:
		camera_yaw.rotation.y = yaw

func get_current_target():
	return current_target

func clear_current_target() -> void:
	if current_target == null:
		return
	if current_target != null and is_instance_valid(current_target):
		current_target.set_highlighted(false)
	current_target = null
	target_changed.emit(null)

func _apply_movement(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var forward := -camera_yaw.global_transform.basis.z
	var right := camera_yaw.global_transform.basis.x
	forward.y = 0.0
	right.y = 0.0
	forward = forward.normalized()
	right = right.normalized()
	var direction := (right * input.x + forward * -input.y).normalized() if input.length() > 0.0 else Vector3.ZERO
	var crouching := Input.is_action_pressed("crouch")
	var sprinting := Input.is_action_pressed("sprint") and not crouching
	var speed := crouch_speed if crouching else (sprint_speed if sprinting else walk_speed)
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	_apply_gravity(delta)
	if direction.length() > 0.05:
		visual_root.rotation.y = atan2(-direction.x, -direction.z)

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = -0.1

func _update_target() -> void:
	interaction_ray.force_raycast_update()
	var next_target = _find_target()
	if next_target == current_target:
		return
	if current_target != null and is_instance_valid(current_target):
		current_target.set_highlighted(false)
	current_target = next_target
	if current_target != null:
		current_target.set_highlighted(true)
	target_changed.emit(current_target)

func _target_from_ray():
	if not interaction_ray.is_colliding():
		return null
	var collider := interaction_ray.get_collider()
	if collider != null and collider.has_method("set_highlighted") and _target_in_reach(collider):
		return collider
	return null

func _find_target():
	var ray_target = _target_from_ray()
	if ray_target != null:
		return ray_target
	return _nearest_facing_target()

func _nearest_facing_target():
	var best = null
	var best_score := INF
	var forward := -camera_yaw.global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	for node in get_tree().get_nodes_in_group("ashdown_interactable"):
		if node == null or not is_instance_valid(node) or not node.visible:
			continue
		var to_target: Vector3 = node.global_position - global_position
		to_target.y = 0.0
		var distance := to_target.length()
		if distance > interaction_distance or distance <= 0.01:
			continue
		var facing := forward.dot(to_target.normalized())
		if facing < 0.25:
			continue
		if not _has_line_of_sight(node):
			continue
		var score := distance - facing
		if score < best_score:
			best_score = score
			best = node
	return best

func _target_in_reach(target) -> bool:
	return target != null and target.global_position.distance_to(global_position) <= interaction_distance + 0.35

func _has_line_of_sight(target) -> bool:
	if camera == null:
		return true
	var from := camera.global_position
	var to: Vector3 = target.global_position + Vector3(0, 0.35, 0)
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.exclude = [self]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return true
	return from.distance_to(hit["position"]) >= from.distance_to(to) - 0.15

func _adjust_camera_arm(delta: float) -> void:
	var crouching := Input.is_action_pressed("crouch")
	var target_length := tight_spring_length if crouching else normal_spring_length
	spring_arm.spring_length = move_toward(spring_arm.spring_length, target_length, delta * 6.0)
	var target_height := 1.08 if crouching else camera_pivot_height
	camera_pitch.position.y = move_toward(camera_pitch.position.y, target_height, delta * 4.5)

func _capture_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	mouse_captured = true

func _release_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	mouse_captured = false

func _build_runtime_nodes() -> void:
	var shape := CollisionShape3D.new()
	shape.name = "CollisionShape3D"
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.32
	capsule.height = 1.55
	shape.shape = capsule
	shape.position = Vector3(0, 0.82, 0)
	add_child(shape)

	visual_root = Node3D.new()
	visual_root.name = "VisualRoot"
	add_child(visual_root)
	var body := MeshInstance3D.new()
	body.name = "PrototypeBody"
	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = 0.28
	body_mesh.height = 1.35
	body.mesh = body_mesh
	body.position = Vector3(0, 0.82, 0)
	body.material_override = _make_material(Color(0.58, 0.66, 0.76), false)
	visual_root.add_child(body)
	var face := MeshInstance3D.new()
	var face_mesh := BoxMesh.new()
	face_mesh.size = Vector3(0.18, 0.08, 0.04)
	face.mesh = face_mesh
	face.position = Vector3(0, 1.18, -0.28)
	face.material_override = _make_material(Color(0.12, 0.11, 0.10), false)
	visual_root.add_child(face)

	camera_yaw = Node3D.new()
	camera_yaw.name = "CameraYaw"
	add_child(camera_yaw)
	camera_pitch = Node3D.new()
	camera_pitch.name = "CameraPitch"
	camera_pitch.position = Vector3(0, camera_pivot_height, 0)
	camera_yaw.add_child(camera_pitch)
	spring_arm = SpringArm3D.new()
	spring_arm.name = "SpringArm3D"
	spring_arm.spring_length = normal_spring_length
	spring_arm.margin = 0.12
	camera_pitch.add_child(spring_arm)
	camera_socket = Node3D.new()
	camera_socket.name = "CameraSocket"
	camera_socket.position.x = camera_shoulder_offset
	spring_arm.add_child(camera_socket)
	camera = Camera3D.new()
	camera.name = "Camera3D"
	camera.fov = 60.0
	camera.current = true
	camera_socket.add_child(camera)
	interaction_ray = RayCast3D.new()
	interaction_ray.name = "InteractionRay"
	interaction_ray.target_position = Vector3(0, 0, -camera_ray_distance)
	interaction_ray.collide_with_areas = true
	interaction_ray.collide_with_bodies = true
	interaction_ray.collision_mask = 1
	camera.add_child(interaction_ray)

func _make_material(color: Color, unshaded: bool) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED if unshaded else BaseMaterial3D.SHADING_MODE_PER_PIXEL
	return mat
