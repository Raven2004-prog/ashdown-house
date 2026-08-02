class_name AshdownDormitoryContent
extends Node3D

@onready var trunk_lid: Node3D = $Furniture/DR09_ToyTrunk/Lid
@onready var music_lid: Node3D = $Furniture/DR08_MusicBox/Lid
@onready var smoke: GPUParticles3D = $Atmosphere/DormitorySmoke

var trunk_closed_rotation := Vector3.ZERO
var music_closed_rotation := Vector3.ZERO
var solved := false

func _ready() -> void:
	trunk_closed_rotation = trunk_lid.rotation_degrees
	music_closed_rotation = music_lid.rotation_degrees
	_hide_legacy_blockout_visuals()

func _hide_legacy_blockout_visuals() -> void:
	var level_root := get_parent().get_parent()
	for node_name in ["DormitoryBunksWest", "DormitoryBunksSouth"]:
		var blocker := level_root.get_node_or_null("HouseBlockout/BlockoutGeometry/%s" % node_name)
		if blocker == null:
			continue
		for mesh in blocker.find_children("*", "MeshInstance3D", true, false):
			(mesh as MeshInstance3D).visible = false

func apply_gameplay_state(flags: Dictionary) -> void:
	var should_open := bool(flags.get("dormitory_music_solved", false))
	var fire_started := bool(flags.get("fire_started", false))
	smoke.visible = fire_started
	smoke.emitting = fire_started
	if should_open == solved:
		return
	solved = should_open
	var trunk_target := trunk_closed_rotation + Vector3(-72 if solved else 0, 0, 0)
	var music_target := music_closed_rotation + Vector3(-48 if solved else 0, 0, 0)
	create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT).tween_property(trunk_lid, "rotation_degrees", trunk_target, 0.65)
	create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT).tween_property(music_lid, "rotation_degrees", music_target, 0.45)

