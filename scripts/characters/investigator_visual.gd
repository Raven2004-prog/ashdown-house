class_name InvestigatorVisual
extends Node3D

signal footstep(surface_hint: StringName)

const STEP_FPS := 10.0

var locomotion_state: StringName = &"idle"
var one_shot_state: StringName = &""
var one_shot_remaining := 0.0
var animation_clock := 0.0
var last_step_bucket := -1
var rest_transforms: Dictionary = {}

@onready var model: Node3D = $InvestigatorModel

func _ready() -> void:
	_cache_rest_transforms(model)

func set_locomotion(moving: bool, sprinting: bool, crouching: bool) -> void:
	if one_shot_remaining > 0.0:
		return
	if crouching:
		locomotion_state = &"crouch"
	elif not moving:
		locomotion_state = &"idle"
	elif sprinting:
		locomotion_state = &"sprint"
	else:
		locomotion_state = &"walk"

func play_interaction(kind: StringName, interaction_id: StringName = &"") -> void:
	if kind == &"door":
		_start_one_shot(&"door", 0.72)
	elif kind == &"doll":
		_start_one_shot(&"inspect", 0.82)
	elif kind == &"puzzle" and (String(interaction_id).contains("valve") or String(interaction_id).begins_with("R")):
		_start_one_shot(&"valve", 0.92)
	elif kind in [&"clue", &"item", &"container"]:
		_start_one_shot(&"pickup", 0.78)
	else:
		_start_one_shot(&"inspect", 0.72)

func play_lantern_raise() -> void:
	_start_one_shot(&"lantern", 0.82)

func play_stumble() -> void:
	_start_one_shot(&"stumble", 1.05)

func play_ending() -> void:
	_start_one_shot(&"ending", 2.4)

func _process(delta: float) -> void:
	animation_clock += delta
	if one_shot_remaining > 0.0:
		one_shot_remaining = maxf(0.0, one_shot_remaining - delta)
		if one_shot_remaining <= 0.0:
			one_shot_state = &""
	var state := one_shot_state if one_shot_remaining > 0.0 else locomotion_state
	var stepped_time := floorf(animation_clock * STEP_FPS) / STEP_FPS
	_apply_pose(state, stepped_time)

func _start_one_shot(state: StringName, duration: float) -> void:
	one_shot_state = state
	one_shot_remaining = duration
	animation_clock = 0.0
	last_step_bucket = -1

func _apply_pose(state: StringName, time: float) -> void:
	_reset_pose()
	var left_arm := _part("M_LeftArm")
	var right_arm := _part("M_RightArm")
	var left_boot := _part("M_LeftBoot")
	var right_boot := _part("M_RightBoot")
	var satchel := _part("M_Satchel")
	var lantern := _part("M_LanternBody")
	var phase := sin(time * (11.0 if state == &"sprint" else 7.0))
	match state:
		&"idle":
			model.position.y = sin(time * 2.0) * 0.008
			_set_rotation(left_arm, Vector3(1.5, 0, -2.0))
			_set_rotation(right_arm, Vector3(-1.5, 0, 2.0))
		&"walk", &"sprint":
			var amplitude := 25.0 if state == &"sprint" else 16.0
			_set_rotation(left_arm, Vector3(phase * amplitude, 0, -3.0))
			_set_rotation(right_arm, Vector3(-phase * amplitude, 0, 3.0))
			_set_rotation(left_boot, Vector3(-phase * amplitude * 0.42, 0, 0))
			_set_rotation(right_boot, Vector3(phase * amplitude * 0.42, 0, 0))
			model.position.y = abs(phase) * (0.028 if state == &"sprint" else 0.016)
			if satchel != null:
				satchel.rotation_degrees.z += phase * 4.0
			_emit_step_if_needed(time, 4.0 if state == &"sprint" else 2.8)
		&"crouch":
			model.position.y = -0.22 + abs(phase) * 0.008
			model.rotation_degrees.x = -7.0
			_set_rotation(left_arm, Vector3(-12.0, 0, -6.0))
			_set_rotation(right_arm, Vector3(-12.0, 0, 6.0))
		&"inspect":
			var reach := sin(minf(time / 0.72, 1.0) * PI)
			_set_rotation(right_arm, Vector3(-58.0 * reach, 0, 10.0))
			model.rotation_degrees.x = -5.0 * reach
		&"pickup":
			var bend := sin(minf(time / 0.78, 1.0) * PI)
			model.position.y = -0.22 * bend
			model.rotation_degrees.x = -18.0 * bend
			_set_rotation(right_arm, Vector3(-76.0 * bend, 0, 12.0))
		&"door":
			var push := sin(minf(time / 0.72, 1.0) * PI)
			_set_rotation(right_arm, Vector3(-82.0 * push, 0, 16.0))
			model.rotation_degrees.y = -5.0 * push
		&"valve":
			var turn := sin(minf(time / 0.92, 1.0) * PI)
			_set_rotation(left_arm, Vector3(-70.0 * turn, 0, -15.0))
			_set_rotation(right_arm, Vector3(-70.0 * turn, 0, 15.0))
			model.rotation_degrees.z = sin(time * 9.0) * 3.0 * turn
		&"lantern":
			var raise := sin(minf(time / 0.82, 1.0) * PI)
			_set_rotation(left_arm, Vector3(-72.0 * raise, 0, -12.0))
			if lantern != null:
				lantern.position.y += 0.28 * raise
		&"stumble":
			var stagger := sin(minf(time / 1.05, 1.0) * PI)
			model.rotation_degrees = Vector3(-9.0 * stagger, 0, 12.0 * stagger)
			_set_rotation(left_arm, Vector3(35.0 * stagger, 0, -28.0 * stagger))
			_set_rotation(right_arm, Vector3(-20.0 * stagger, 0, 32.0 * stagger))
		&"ending":
			var settle := clampf(time / 2.4, 0.0, 1.0)
			model.position.y = -0.26 * settle
			model.rotation_degrees.x = -13.0 * settle
			_set_rotation(left_arm, Vector3(-42.0 * settle, 0, -8.0))
			_set_rotation(right_arm, Vector3(-42.0 * settle, 0, 8.0))

func _cache_rest_transforms(node: Node) -> void:
	if node is Node3D:
		rest_transforms[node.name] = (node as Node3D).transform
	for child in node.get_children():
		_cache_rest_transforms(child)

func _reset_pose() -> void:
	for node_name in rest_transforms:
		var node := _part(String(node_name))
		if node != null:
			node.transform = rest_transforms[node_name]
	model.transform = rest_transforms.get(model.name, model.transform)

func _part(part_name: String) -> Node3D:
	return model.find_child(part_name, true, false) as Node3D

func _set_rotation(node: Node3D, degrees: Vector3) -> void:
	if node != null:
		node.rotation_degrees += degrees

func _emit_step_if_needed(time: float, cadence: float) -> void:
	var bucket := int(floor(time * cadence))
	if bucket != last_step_bucket:
		last_step_bucket = bucket
		footstep.emit(&"default")
