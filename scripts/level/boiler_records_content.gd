class_name AshdownBoilerRecordsContent
extends Node3D

@onready var master_lever: Node3D = $Furniture/R02_PressureBoard/MasterLever
@onready var bath_valve: Node3D = $Furniture/R03_BathValve/Wheel
@onready var kitchen_valve: Node3D = $Furniture/R04_KitchenValve/Wheel
@onready var radiator_valve: Node3D = $Furniture/R05_RadiatorValve/Wheel
@onready var gauge_needle: Node3D = $Furniture/R07_PressureGauge/Needle
@onready var records_door: Node3D = $Furniture/R08_RecordsCabinetA/Door
@onready var handprints: Node3D = $Furniture/R14_Handprints
@onready var memory_silhouettes: Node3D = $Furniture/R22_ShutdownMemory
@onready var smoke: GPUParticles3D = $Atmosphere/BoilerSmoke
@onready var steam: GPUParticles3D = $Atmosphere/PressureSteam
@onready var hot_light: OmniLight3D = $Lighting/BoilerGlow

func _ready() -> void:
	var blocker := get_parent().get_parent().get_node_or_null("HouseBlockout/BlockoutGeometry/Boiler")
	if blocker != null:
		for mesh in blocker.find_children("*", "MeshInstance3D", true, false):
			(mesh as MeshInstance3D).visible = false

func apply_gameplay_state(flags: Dictionary) -> void:
	var fire_started := bool(flags.get("fire_started", false))
	var disabled := bool(flags.get("boiler_disabled", false))
	var records_open := bool(flags.get("records_cabinet_opened", false))
	master_lever.rotation_degrees.z = -58 if disabled else 18
	bath_valve.rotation_degrees.z = 90 if disabled else 0
	radiator_valve.rotation_degrees.z = -72 if disabled else 0
	kitchen_valve.rotation_degrees.z = -72 if disabled else 0
	gauge_needle.rotation_degrees.z = -42 if disabled else 38
	records_door.rotation_degrees.y = -76 if records_open else 0
	handprints.visible = disabled
	memory_silhouettes.visible = disabled
	smoke.visible = fire_started and not disabled
	smoke.emitting = fire_started and not disabled
	steam.visible = fire_started and not disabled
	steam.emitting = fire_started and not disabled
	hot_light.light_energy = 0.9 if disabled else (3.4 if fire_started else 1.8)
