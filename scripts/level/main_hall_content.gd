class_name AshdownMainHallContent
extends Node3D

@onready var smoke_particles: GPUParticles3D = $Atmosphere/SmokeParticles
@onready var fire_glow: OmniLight3D = $Atmosphere/FireGlow
@onready var hall_light: OmniLight3D = $Lighting/HallWarmLight

var fire_active := false

func apply_gameplay_state(flags: Dictionary) -> void:
	var should_burn := bool(flags.get("fire_started", false)) and not bool(flags.get("final_doll_placed", false))
	if should_burn == fire_active:
		return
	fire_active = should_burn
	smoke_particles.visible = should_burn
	smoke_particles.emitting = should_burn
	fire_glow.visible = should_burn
	hall_light.light_energy = 2.35 if should_burn else 3.20
