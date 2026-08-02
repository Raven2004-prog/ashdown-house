class_name AshdownFinalVFX
extends Node3D

var fire_effects: Dictionary = {}
var soul_wisps: GPUParticles3D
var soul_light: OmniLight3D
var light_shafts: Array[SpotLight3D] = []
var active_flags: Dictionary = {}
var pressure_fraction := 0.0

func _ready() -> void:
	add_to_group("ashdown_final_vfx")
	_create_fire_effect(&"hall", Vector3(0, 0.18, -5.15), Color("d95521"))
	_create_fire_effect(&"classroom", Vector3(21.8, 0.18, 0.8), Color("e06925"))
	_create_fire_effect(&"kitchen", Vector3(21.5, 0.18, -12.0), Color("df4d1b"))
	_create_fire_effect(&"boiler", Vector3(0.5, 0.18, -13.0), Color("d63a18"))
	_create_release_effect()
	_create_light_shafts()
	_apply_quality()
	GraphicsSettings.settings_changed.connect(_apply_quality)

func apply_gameplay_state(flags: Dictionary, smoke_fraction: float) -> void:
	active_flags = flags
	pressure_fraction = clampf(smoke_fraction, 0.0, 1.0)
	var fire_started := bool(flags.get("fire_started", false)) and not bool(flags.get("final_doll_placed", false))
	_set_fire_active(&"hall", fire_started)
	_set_fire_active(&"classroom", fire_started and not bool(flags.get("classroom_fuses_solved", false)))
	_set_fire_active(&"kitchen", fire_started and not bool(flags.get("kitchen_fire_extinguished", false)))
	_set_fire_active(&"boiler", fire_started and not bool(flags.get("boiler_disabled", false)))
	var complete := bool(flags.get("final_doll_placed", false))
	soul_wisps.emitting = complete
	soul_wisps.visible = complete
	soul_light.visible = complete
	for effect in fire_effects.values():
		var smoke := effect.smoke as GPUParticles3D
		smoke.amount_ratio = 0.25 + pressure_fraction * 0.75

func _process(_delta: float) -> void:
	if GraphicsSettings.reduced_flashing:
		return
	var pulse := sin(Time.get_ticks_msec() * 0.009) * 0.16
	for effect in fire_effects.values():
		var light := effect.light as OmniLight3D
		if light.visible:
			light.light_energy = 2.4 + pulse
	if soul_light != null and soul_light.visible:
		soul_light.light_energy = 2.0 + pulse * 0.5

func get_fire_effect_count() -> int:
	return fire_effects.size()

func _create_fire_effect(id: StringName, position_value: Vector3, color: Color) -> void:
	var root := Node3D.new()
	root.name = "%sFireEffect" % String(id).capitalize()
	root.position = position_value
	add_child(root)
	var flame := GPUParticles3D.new()
	flame.name = "Flame"
	flame.amount = 26
	flame.lifetime = 1.1
	flame.visibility_aabb = AABB(Vector3(-2, -0.5, -2), Vector3(4, 4, 4))
	flame.process_material = _particle_process(Vector3(0.65, 0.12, 0.65), Vector3(0, 1.25, 0), color, 0.10, 0.36)
	flame.draw_pass_1 = _particle_quad(Color(color, 0.82), Vector2(0.18, 0.34), true)
	root.add_child(flame)
	var smoke := GPUParticles3D.new()
	smoke.name = "Smoke"
	smoke.amount = 34
	smoke.lifetime = 4.8
	smoke.position.y = 0.35
	smoke.visibility_aabb = AABB(Vector3(-3, -1, -3), Vector3(6, 7, 6))
	smoke.process_material = _particle_process(Vector3(0.8, 0.15, 0.8), Vector3(0, 0.38, 0), Color(0.11, 0.105, 0.10, 0.24), 0.32, 1.1)
	smoke.draw_pass_1 = _particle_quad(Color(0.09, 0.085, 0.08, 0.20), Vector2(0.65, 0.65), false)
	root.add_child(smoke)
	var light := OmniLight3D.new()
	light.name = "FireLight"
	light.position.y = 0.55
	light.light_color = color
	light.light_energy = 2.4
	light.omni_range = 5.4
	light.shadow_enabled = false
	root.add_child(light)
	fire_effects[id] = {"root": root, "flame": flame, "smoke": smoke, "light": light}
	_set_fire_active(id, false)

func _create_release_effect() -> void:
	soul_wisps = GPUParticles3D.new()
	soul_wisps.name = "ReleaseWisps"
	soul_wisps.position = Vector3(0, 0.55, 1.7)
	soul_wisps.amount = 49
	soul_wisps.lifetime = 4.0
	soul_wisps.one_shot = false
	soul_wisps.visibility_aabb = AABB(Vector3(-4, -1, -4), Vector3(8, 7, 8))
	soul_wisps.process_material = _particle_process(Vector3(0.75, 0.18, 0.75), Vector3(0, 0.62, 0), Color("93c9c5"), 0.08, 0.22)
	soul_wisps.draw_pass_1 = _particle_quad(Color(0.58, 0.84, 0.82, 0.58), Vector2(0.14, 0.30), true)
	soul_wisps.visible = false
	soul_wisps.emitting = false
	add_child(soul_wisps)
	soul_light = OmniLight3D.new()
	soul_light.name = "ReleaseLight"
	soul_light.position = Vector3(0, 1.0, 1.7)
	soul_light.light_color = Color("86c4be")
	soul_light.light_energy = 2.0
	soul_light.omni_range = 7.5
	soul_light.visible = false
	add_child(soul_light)

func _create_light_shafts() -> void:
	for index in range(3):
		var shaft := SpotLight3D.new()
		shaft.name = "ColdWindowShaft_%d" % index
		shaft.position = Vector3(-7.1 + index * 7.1, 3.05, -1.0 + index * 2.4)
		shaft.rotation_degrees = Vector3(-72, 0, -10 + index * 10)
		shaft.light_color = Color("8faeb9")
		shaft.light_energy = 0.72
		shaft.spot_range = 7.0
		shaft.spot_angle = 18.0
		shaft.shadow_enabled = false
		add_child(shaft)
		light_shafts.append(shaft)

func _set_fire_active(id: StringName, active: bool) -> void:
	if not fire_effects.has(id):
		return
	var effect: Dictionary = fire_effects[id]
	(effect.root as Node3D).visible = active
	(effect.flame as GPUParticles3D).emitting = active
	(effect.smoke as GPUParticles3D).emitting = active
	(effect.light as OmniLight3D).visible = active

func _apply_quality() -> void:
	var amount_ratio := 0.55
	match GraphicsSettings.world_quality:
		GraphicsSettings.WorldQuality.PERFORMANCE:
			amount_ratio = 0.35
		GraphicsSettings.WorldQuality.NATIVE:
			amount_ratio = 1.0
	for effect in fire_effects.values():
		(effect.flame as GPUParticles3D).amount_ratio = amount_ratio
		(effect.smoke as GPUParticles3D).amount_ratio = amount_ratio
	if soul_wisps != null:
		soul_wisps.amount_ratio = amount_ratio
	for shaft in light_shafts:
		shaft.visible = GraphicsSettings.fog_enabled

func _particle_process(extents: Vector3, velocity: Vector3, color: Color, scale_min: float, scale_max: float) -> ParticleProcessMaterial:
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = extents
	process.direction = velocity.normalized()
	process.initial_velocity_min = velocity.length() * 0.75
	process.initial_velocity_max = velocity.length() * 1.25
	process.gravity = Vector3(0, 0.08, 0)
	process.spread = 28.0
	process.scale_min = scale_min
	process.scale_max = scale_max
	process.color = color
	return process

func _particle_quad(color: Color, size: Vector2, emissive: bool) -> QuadMesh:
	var quad := QuadMesh.new()
	quad.size = size
	quad.orientation = PlaneMesh.FACE_Z
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.vertex_color_use_as_albedo = true
	if emissive:
		material.emission_enabled = true
		material.emission = Color(color.r, color.g, color.b)
		material.emission_energy_multiplier = 1.6
	quad.material = material
	return quad
