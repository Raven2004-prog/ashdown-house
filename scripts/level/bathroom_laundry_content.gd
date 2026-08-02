class_name AshdownBathroomLaundryContent
extends Node3D

@onready var mirror_message: Node3D = $Furniture/B03_SteamedMirror/Message
@onready var cabinet_door: Node3D = $Furniture/B10_TowelCabinet/Door
@onready var drain_lever: Node3D = $Furniture/B08_DrainLever/Handle
@onready var wringer_handle: Node3D = $Furniture/B12_Wringer/Handle
@onready var steam: GPUParticles3D = $Atmosphere/Steam

var cabinet_closed := Vector3.ZERO

func _ready() -> void:
	cabinet_closed = cabinet_door.rotation_degrees
	_hide_legacy_visuals()

func _hide_legacy_visuals() -> void:
	var blocker := get_parent().get_parent().get_node_or_null("HouseBlockout/BlockoutGeometry/BathroomStalls")
	if blocker != null:
		for mesh in blocker.find_children("*", "MeshInstance3D", true, false):
			(mesh as MeshInstance3D).visible = false

func apply_gameplay_state(flags: Dictionary) -> void:
	var steam_active := bool(flags.get("steam_routed_to_bathroom", false))
	steam.visible = steam_active
	steam.emitting = steam_active
	mirror_message.visible = bool(flags.get("mirror_message_revealed", false))
	cabinet_door.rotation_degrees = cabinet_closed + Vector3(0, -68 if bool(flags.get("towel_cabinet_opened", false)) else 0, 0)
	drain_lever.rotation_degrees.x = -55 if bool(flags.get("drain_closed", false)) else 18
	wringer_handle.rotation_degrees.z = 120 if bool(flags.get("wringer_operated", false)) else 0

