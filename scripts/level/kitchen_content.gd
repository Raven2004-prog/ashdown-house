class_name AshdownKitchenContent
extends Node3D

@onready var pantry_left: Node3D = $Furniture/K04_Pantry/LeftDoor
@onready var pantry_right: Node3D = $Furniture/K04_Pantry/RightDoor
@onready var scale_beam: Node3D = $Furniture/K05_Scale/Beam
@onready var smoke: GPUParticles3D = $Atmosphere/KitchenSmoke

func _ready() -> void:
	var blocker := get_parent().get_parent().get_node_or_null("HouseBlockout/BlockoutGeometry/KitchenPrepTable")
	if blocker != null:
		for mesh in blocker.find_children("*", "MeshInstance3D", true, false):
			(mesh as MeshInstance3D).visible = false

func apply_gameplay_state(flags: Dictionary) -> void:
	var pantry_open := bool(flags.get("pantry_opened", false))
	pantry_left.rotation_degrees.y = 72 if pantry_open else 0
	pantry_right.rotation_degrees.y = -72 if pantry_open else 0
	scale_beam.rotation_degrees.z = 0 if bool(flags.get("kitchen_weight_solved", false)) else -8
	var fire_started := bool(flags.get("fire_started", false))
	smoke.visible = fire_started
	smoke.emitting = fire_started

