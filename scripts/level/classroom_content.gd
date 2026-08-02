class_name AshdownClassroomContent
extends Node3D

@onready var classroom_smoke: GPUParticles3D = $Atmosphere/ClassroomSmoke
@onready var doorway_fire: Node3D = $Atmosphere/DoorwayFire
@onready var fire_light: OmniLight3D = $Atmosphere/DoorwayFire/FireLight
@onready var projector_light: SpotLight3D = $Lighting/ProjectorLight
@onready var screen_glow: MeshInstance3D = $Furniture/C05_ProjectorScreen/PoweredGlow
@onready var projection_stars: Node3D = $Furniture/C05_ProjectorScreen/ProjectionStars
@onready var teacher_drawer: Node3D = $Furniture/TeacherDesk/RewardDrawer

var drawer_closed_position := Vector3.ZERO
var drawer_open := false

func _ready() -> void:
	drawer_closed_position = teacher_drawer.position
	_hide_legacy_blockout_visuals()

func _hide_legacy_blockout_visuals() -> void:
	var level_root := get_parent().get_parent()
	for node_name in ["ClassroomTeacherDesk", "ClassroomDesks"]:
		var blocker := level_root.get_node_or_null("HouseBlockout/BlockoutGeometry/%s" % node_name)
		if blocker == null:
			continue
		for mesh in blocker.find_children("*", "MeshInstance3D", true, false):
			(mesh as MeshInstance3D).visible = false

func apply_gameplay_state(flags: Dictionary) -> void:
	var fire_started := bool(flags.get("fire_started", false))
	var kitchen_clear := bool(flags.get("kitchen_fire_extinguished", false))
	var projector_powered := bool(flags.get("projector_revealed", false))
	var seating_solved := bool(flags.get("classroom_seating_solved", false))
	classroom_smoke.visible = fire_started
	classroom_smoke.emitting = fire_started
	doorway_fire.visible = fire_started and not kitchen_clear
	fire_light.visible = fire_started and not kitchen_clear
	projector_light.visible = projector_powered
	screen_glow.visible = projector_powered
	projection_stars.visible = projector_powered
	if seating_solved != drawer_open:
		drawer_open = seating_solved
		var destination := drawer_closed_position + Vector3(0, 0, -0.42 if drawer_open else 0)
		if is_inside_tree():
			create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT).tween_property(teacher_drawer, "position", destination, 0.45)
		else:
			teacher_drawer.position = destination
