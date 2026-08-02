@tool
extends SceneTree

const OUTPUT := "res://scenes/levels/ashdown/rooms/BoilerRecordsContent.tscn"
const CONTROLLER := preload("res://scripts/level/boiler_records_content.gd")
const INTERACTABLE := preload("res://scripts/interaction/interactable_3d.gd")

var mats: Dictionary = {}

func _initialize() -> void:
	call_deferred("_build")

func _build() -> void:
	_materials()
	var root := Node3D.new()
	root.name = "BoilerRecordsContent"
	root.set_script(CONTROLLER)
	var architecture := _branch(root, "Architecture")
	var furniture := _branch(root, "Furniture")
	var anchors := _branch(root, "InteractionAnchors")
	var areas := _branch(root, "Interactables")
	var lighting := _branch(root, "Lighting")
	var atmosphere := _branch(root, "Atmosphere")
	_architecture(architecture)
	_furniture(furniture)
	_interactions(anchors, areas)
	_lighting(lighting)
	_atmosphere(atmosphere)
	_set_owner_recursive(root, root)
	var packed := PackedScene.new()
	var result := packed.pack(root)
	if result == OK:
		result = ResourceSaver.save(packed, OUTPUT)
	print("BOILER_RECORDS_BUILT: %s" % error_string(result))
	root.free()
	quit(0 if result == OK else 1)

func _materials() -> void:
	mats = {
		"concrete": _mat("BoilerConcrete", Color("343331"), 0.96),
		"wall": _mat("SootedServicePlaster", Color("403b37"), 0.98),
		"iron": _mat("BoilerIron", Color("22282a"), 0.58, 0.55),
		"steel": _mat("BoilerSteel", Color("4c5657"), 0.48, 0.42),
		"copper": _mat("OxidizedCopper", Color("6b4b35"), 0.58, 0.45),
		"brass": _mat("GaugeBrass", Color("8b6b35"), 0.54, 0.32),
		"wood": _mat("RecordsWood", Color("4b3023"), 0.90),
		"paper": _mat("RecordsPaper", Color("b7a77c"), 0.98),
		"red": _mat("EmergencyRed", Color("7e2f28"), 0.80),
		"blue": _mat("BathBlue", Color("355a69"), 0.72),
		"green": _mat("KitchenGreen", Color("455f4c"), 0.72),
		"cream": _mat("RadiatorIvory", Color("9b8f68"), 0.78),
		"soot": _mat("BoilerSoot", Color("111111"), 1.0),
		"glass": _mat("GaugeGlass", Color(0.45, 0.56, 0.56, 0.45), 0.14),
		"hand": _emit("CondensationHandprint", Color("b6cbc5"), 0.48),
		"memory": _emit("MemorySilhouette", Color("b7d2cb"), 0.30),
	}
	(mats.glass as StandardMaterial3D).transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	(mats.memory as StandardMaterial3D).transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	(mats.memory as StandardMaterial3D).albedo_color.a = 0.34

func _architecture(parent: Node3D) -> void:
	_box(parent, "FloorFinish", Vector3(0, 0.03, -12), Vector3(15.7, 0.06, 9.7), mats.concrete)
	_box(parent, "Ceiling", Vector3(0, 3.38, -12), Vector3(15.7, 0.08, 9.7), mats.wall)
	_box(parent, "SouthWall", Vector3(0, 1.42, -16.82), Vector3(15.7, 2.65, 0.08), mats.wall)
	_box(parent, "WestNorth", Vector3(-7.82, 1.42, -9.0), Vector3(0.08, 2.65, 3.5), mats.wall)
	_box(parent, "WestSouth", Vector3(-7.82, 1.42, -14.2), Vector3(0.08, 2.65, 4.8), mats.wall)
	_box(parent, "EastNorth", Vector3(7.82, 1.42, -9.0), Vector3(0.08, 2.65, 3.5), mats.wall)
	_box(parent, "EastSouth", Vector3(7.82, 1.42, -14.2), Vector3(0.08, 2.65, 4.8), mats.wall)
	_box(parent, "NorthWest", Vector3(-4.4, 1.42, -7.18), Vector3(6.5, 2.65, 0.08), mats.wall)
	_box(parent, "NorthEast", Vector3(4.4, 1.42, -7.18), Vector3(6.5, 2.65, 0.08), mats.wall)
	_door_frame(parent, "HallDoorFrame", Vector3(0, 1.18, -7.25), false)
	_door_frame(parent, "DormitoryDoorFrame", Vector3(-7.7, 1.18, -11.5), true)
	_door_frame(parent, "BathroomDoorFrame", Vector3(7.7, 1.18, -11.5), true)
	for x in [-6.0, -3.0, 0.0, 3.0, 6.0]:
		_box(parent, "CeilingBeam_%s" % str(x), Vector3(x, 3.22, -12), Vector3(0.18, 0.28, 9.3), mats.iron)

func _furniture(parent: Node3D) -> void:
	_make_boiler(parent)
	_make_pressure_board(parent)
	_make_valve(parent, "R03_BathValve", Vector3(-3.0, 1.0, -13.9), mats.blue, "B")
	_make_valve(parent, "R04_KitchenValve", Vector3(0.0, 1.0, -13.9), mats.green, "K")
	_make_valve(parent, "R05_RadiatorValve", Vector3(3.0, 1.0, -13.9), mats.cream, "R")
	_make_gauge(parent)
	_make_wheel_socket(parent)
	_make_records_cabinet(parent, "R08_RecordsCabinetA", Vector3(-6.75, 0, -9.0), true)
	_make_records_cabinet(parent, "R09_RecordsCabinetB", Vector3(-6.75, 0, -12.0), false)
	_make_workbench(parent)
	_make_evidence(parent)
	_make_handprints(parent)
	_make_memory(parent)
	_make_pipe_network(parent)

func _make_boiler(parent: Node3D) -> void:
	var boiler := _prop(parent, "R01_MainBoiler", Vector3(0, 0, -15.0))
	_cylinder(boiler, "Tank", Vector3(0, 1.25, 0), 1.55, 2.5, mats.iron)
	_cylinder(boiler, "Top", Vector3(0, 2.55, 0), 1.25, 0.32, mats.steel)
	_box(boiler, "Firebox", Vector3(0, 0.62, 1.22), Vector3(1.25, 0.92, 0.25), mats.steel)
	_box(boiler, "FireboxDoor", Vector3(0, 0.62, 1.38), Vector3(0.88, 0.64, 0.08), mats.red)
	for x in [-0.95, 0.95]:
		_box(boiler, "Foot_%s" % str(x), Vector3(x, 0.18, 0), Vector3(0.35, 0.36, 0.6), mats.iron)

func _make_pressure_board(parent: Node3D) -> void:
	var board := _prop(parent, "R02_PressureBoard", Vector3(0, 0, -13.6))
	_box(board, "Panel", Vector3(0, 1.18, 0), Vector3(5.6, 1.75, 0.22), mats.steel)
	for x in [-1.8, -0.6, 0.6, 1.8]:
		_cylinder(board, "Indicator_%s" % str(x), Vector3(x, 1.45, 0.16), 0.11, 0.06, mats.brass, Vector3(90, 0, 0))
	var lever := _prop(board, "MasterLever", Vector3(2.2, 0.92, 0.2))
	_box(lever, "Arm", Vector3(0, 0.32, 0), Vector3(0.10, 0.72, 0.10), mats.red)
	_cylinder(lever, "Grip", Vector3(0, 0.72, 0), 0.13, 0.30, mats.wood, Vector3(90, 0, 0))

func _make_valve(parent: Node3D, name: String, pos: Vector3, accent: Material, label: String) -> void:
	var valve := _prop(parent, name, pos)
	_cylinder(valve, "Pipe", Vector3(0, 0, -0.12), 0.16, 2.0, mats.copper, Vector3(0, 0, 90))
	var wheel := _prop(valve, "Wheel", Vector3.ZERO)
	var rim := _torus(wheel, "Rim", Vector3.ZERO, 0.055, 0.36, accent)
	rim.rotation_degrees.x = 90
	for i in range(6):
		var spoke := _box(wheel, "Spoke_%d" % i, Vector3.ZERO, Vector3(0.58, 0.045, 0.045), accent)
		spoke.rotation_degrees.z = i * 30
	_box(valve, "Label_%s" % label, Vector3(0, 0.62, 0), Vector3(0.34, 0.34, 0.06), accent)

func _make_gauge(parent: Node3D) -> void:
	var gauge := _prop(parent, "R07_PressureGauge", Vector3(0, 1.85, -13.42))
	_cylinder(gauge, "Body", Vector3.ZERO, 0.46, 0.12, mats.brass, Vector3(90, 0, 0))
	_cylinder(gauge, "Face", Vector3(0, 0, 0.08), 0.38, 0.03, mats.glass, Vector3(90, 0, 0))
	var needle := _prop(gauge, "Needle", Vector3(0, 0, 0.11))
	_box(needle, "Pointer", Vector3(0, 0.16, 0), Vector3(0.035, 0.34, 0.025), mats.red)

func _make_wheel_socket(parent: Node3D) -> void:
	var socket := _prop(parent, "R06_WheelSocket", Vector3(0, 1.0, -7.28))
	var rim := _torus(socket, "InstalledWheel", Vector3.ZERO, 0.06, 0.42, mats.brass)
	rim.rotation_degrees.x = 90
	for i in range(6):
		var spoke := _box(socket, "Spoke_%d" % i, Vector3.ZERO, Vector3(0.68, 0.05, 0.05), mats.brass)
		spoke.rotation_degrees.z = i * 30

func _make_records_cabinet(parent: Node3D, name: String, pos: Vector3, opening: bool) -> void:
	var cabinet := _prop(parent, name, pos)
	_box(cabinet, "Body", Vector3(0, 1.15, 0), Vector3(1.25, 2.3, 0.72), mats.wood)
	for y in [0.42, 0.88, 1.34, 1.80]:
		_box(cabinet, "Shelf_%s" % str(y), Vector3(0, y, -0.15), Vector3(1.10, 0.06, 0.48), mats.paper)
	var door := _prop(cabinet, "Door", Vector3(0.60, 1.15, -0.39))
	_box(door, "Panel", Vector3(-0.60, 0, 0), Vector3(1.18, 2.18, 0.08), mats.wood)
	if not opening:
		door.name = "FixedDoor"

func _make_workbench(parent: Node3D) -> void:
	var bench := _prop(parent, "R10_MaintenanceWorkbench", Vector3(5.8, 0, -9.0))
	_box(bench, "Top", Vector3(0, 0.88, 0), Vector3(3.2, 0.16, 1.0), mats.wood)
	for x in [-1.35, 1.35]:
		for z in [-0.36, 0.36]:
			_box(bench, "Leg_%s_%s" % [str(x), str(z)], Vector3(x, 0.42, z), Vector3(0.14, 0.84, 0.14), mats.iron)
	for i in range(7):
		_box(bench, "Tool_%d" % i, Vector3(-1.1 + i * 0.35, 1.02, -0.1 + (i % 2) * 0.22), Vector3(0.28, 0.04, 0.08), mats.steel)

func _make_evidence(parent: Node3D) -> void:
	var report := _prop(parent, "R11_DevReport", Vector3(-6.6, 1.08, -9.0)); _box(report, "Paper", Vector3.ZERO, Vector3(0.56, 0.025, 0.72), mats.paper)
	var inspection := _prop(parent, "R12_FireInspection", Vector3(-6.6, 0.88, -9.0)); _box(inspection, "Paper", Vector3.ZERO, Vector3(0.52, 0.025, 0.68), mats.paper)
	var invoice := _prop(parent, "R13_RepairInvoice", Vector3(5.8, 0.96, -9.0)); _box(invoice, "Paper", Vector3.ZERO, Vector3(0.56, 0.025, 0.72), mats.paper)
	var battery := _prop(parent, "R16_AlarmBattery", Vector3(5.2, 0.15, -10.3)); _box(battery, "Case", Vector3.ZERO, Vector3(0.55, 0.28, 0.34), mats.red)
	var hook := _prop(parent, "R17_ExitHook", Vector3(-7.62, 1.3, -15.4)); _torus(hook, "Hook", Vector3.ZERO, 0.08, 0.30, mats.iron).rotation_degrees.y = 90
	var marks := _prop(parent, "R15_CountingMarks", Vector3(6.65, 1.05, -14.2))
	for i in range(7):
		for j in range(4):
			_box(marks, "Mark_%d_%d" % [i, j], Vector3(0, (i - 3) * 0.19, (j - 1.5) * 0.10), Vector3(0.025, 0.13, 0.025), mats.soot)

func _make_handprints(parent: Node3D) -> void:
	var prints := _prop(parent, "R14_Handprints", Vector3(7.68, 1.2, -15.1))
	prints.rotation_degrees.y = 90
	prints.visible = false
	for i in range(7):
		var hand := _prop(prints, "Hand_%d" % i, Vector3(0, -0.34 + i * 0.12, -1.0 + i * 0.33))
		_cylinder(hand, "Palm", Vector3.ZERO, 0.12 if i < 6 else 0.14, 0.025, mats.hand, Vector3(90, 0, 0))
		for finger in range(5):
			_box(hand, "Finger_%d" % finger, Vector3(-0.10 + finger * 0.05, 0.16 + abs(2 - finger) * 0.015, 0), Vector3(0.025, 0.18, 0.018), mats.hand)

func _make_memory(parent: Node3D) -> void:
	var memory := _prop(parent, "R22_ShutdownMemory", Vector3(0, 0, -10.3))
	memory.visible = false
	for i in range(7):
		var child := _prop(memory, "Child_%d" % i, Vector3(-2.4 + i * 0.8, 0, -0.4 + abs(3 - i) * 0.22))
		_cylinder(child, "Body", Vector3(0, 0.55, 0), 0.18, 0.78, mats.memory)
		_cylinder(child, "Head", Vector3(0, 1.08, 0), 0.23, 0.34, mats.memory)

func _make_pipe_network(parent: Node3D) -> void:
	for x in [-5.5, -3.0, 0.0, 3.0, 5.5]:
		_cylinder(parent, "VerticalPipe_%s" % str(x), Vector3(x, 2.15, -16.35), 0.12, 2.2, mats.copper)
	for y in [2.3, 2.75]:
		_cylinder(parent, "CrossPipe_%s" % str(y), Vector3(0, y, -16.35), 0.12, 11.0, mats.copper, Vector3(0, 0, 90))

func _interactions(anchors: Node3D, areas: Node3D) -> void:
	var existing := {
		"R02": [Vector3(0, 1.15, -13.45), "../../Furniture/R02_PressureBoard", false, false],
		"R11": [Vector3(-6.6, 1.08, -9.0), "../../Furniture/R11_DevReport", true, true],
		"R14": [Vector3(7.55, 1.2, -15.1), "../../Furniture/R14_Handprints", false, true],
	}
	var authored := {
		"R03": [Vector3(-3.0, 1.0, -13.7), "../../Furniture/R03_BathValve", false, false],
		"R04": [Vector3(0.0, 1.0, -13.7), "../../Furniture/R04_KitchenValve", false, false],
		"R05": [Vector3(3.0, 1.0, -13.7), "../../Furniture/R05_RadiatorValve", false, false],
		"R06": [Vector3(0.0, 1.0, -7.35), "../../Furniture/R06_WheelSocket", false, true],
		"R08": [Vector3(-6.35, 1.0, -9.0), "../../Furniture/R08_RecordsCabinetA", false, false],
		"R12": [Vector3(-6.6, 0.88, -9.0), "../../Furniture/R12_FireInspection", false, true],
		"R13": [Vector3(5.8, 0.96, -9.0), "../../Furniture/R13_RepairInvoice", false, true],
		"R15": [Vector3(7.45, 1.05, -14.2), "../../Furniture/R15_CountingMarks", false, true],
		"R16": [Vector3(5.2, 0.25, -10.3), "../../Furniture/R16_AlarmBattery", false, true],
		"R17": [Vector3(-7.45, 1.3, -15.4), "../../Furniture/R17_ExitHook", false, true],
		"R22": [Vector3(0.0, 0.9, -10.3), "../../Furniture/R22_ShutdownMemory", false, true],
	}
	for id in existing:
		_anchor(anchors, id, existing[id])
	for id in authored:
		_anchor(anchors, id, authored[id])
		_area(areas, id, authored[id][0])

func _lighting(parent: Node3D) -> void:
	_omni(parent, "BoilerGlow", Vector3(0, 1.2, -14.6), Color("dd6938"), 2.8, 6.5)
	_omni(parent, "RecordsPool", Vector3(-5.5, 2.65, -10.0), Color("b49a72"), 2.3, 5.5)
	_omni(parent, "WorkbenchPool", Vector3(5.5, 2.65, -10.0), Color("9aab9f"), 2.1, 5.4)
	_omni(parent, "CentralServiceLight", Vector3(0, 2.75, -10.8), Color("a79b82"), 1.45, 5.5)

func _atmosphere(parent: Node3D) -> void:
	_particles(parent, "BoilerSmoke", Vector3(0, 0.5, -13.5), Vector3(5.5, 0.3, 3.2), Color(0.12, 0.11, 0.10, 0.20), 40)
	_particles(parent, "PressureSteam", Vector3(0, 0.8, -14.2), Vector3(3.0, 0.2, 1.0), Color(0.65, 0.70, 0.68, 0.18), 28)

func _anchor(parent: Node, id: String, data: Array) -> void:
	var marker := Marker3D.new()
	marker.name = id + "Anchor"
	marker.position = data[0]
	marker.add_to_group("ashdown_interaction_anchor", true)
	marker.set_meta("interaction_id", StringName(id))
	marker.set_meta("visual_path", NodePath(data[1]))
	marker.set_meta("hide_visual_on_collect", data[2])
	marker.set_meta("hide_visual_when_unavailable", data[3])
	parent.add_child(marker)

func _area(parent: Node, id: String, pos: Vector3) -> void:
	var area := Area3D.new()
	area.name = id
	area.position = pos
	area.set_script(INTERACTABLE)
	area.set("interaction_id", StringName(id))
	area.set("interaction_radius", 0.62)
	area.add_to_group("ashdown_interactable", true)
	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	var shape := SphereShape3D.new()
	shape.radius = 0.62
	collision.shape = shape
	area.add_child(collision)
	parent.add_child(area)

func _particles(parent: Node, name: String, pos: Vector3, extents: Vector3, color: Color, amount: int) -> void:
	var particles := GPUParticles3D.new()
	particles.name = name
	particles.position = pos
	particles.amount = amount
	particles.lifetime = 7.0
	particles.visible = false
	particles.emitting = false
	particles.visibility_aabb = AABB(-extents, extents * 2.0 + Vector3(0, 4, 0))
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = extents
	process.direction = Vector3(0, 1, 0)
	process.spread = 24
	process.initial_velocity_min = 0.08
	process.initial_velocity_max = 0.28
	process.scale_min = 0.8
	process.scale_max = 2.2
	process.color = color
	particles.process_material = process
	var quad := QuadMesh.new()
	quad.size = Vector2(0.9, 0.9)
	var material := _mat(name + "Material", color, 1.0)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.vertex_color_use_as_albedo = true
	quad.material = material
	particles.draw_pass_1 = quad
	parent.add_child(particles)

func _omni(parent: Node, name: String, pos: Vector3, color: Color, energy: float, range_value: float) -> void:
	var light := OmniLight3D.new()
	light.name = name
	light.position = pos
	light.light_color = color
	light.light_energy = energy
	light.omni_range = range_value
	light.shadow_enabled = true
	parent.add_child(light)

func _door_frame(parent: Node, name: String, pos: Vector3, side: bool) -> void:
	var frame := _prop(parent, name, pos)
	frame.rotation_degrees.y = 90 if side else 0
	_box(frame, "Left", Vector3(-0.86, 0, 0), Vector3(0.16, 2.36, 0.22), mats.wood)
	_box(frame, "Right", Vector3(0.86, 0, 0), Vector3(0.16, 2.36, 0.22), mats.wood)
	_box(frame, "Lintel", Vector3(0, 1.12, 0), Vector3(1.88, 0.18, 0.22), mats.wood)

func _mat(name: String, color: Color, roughness: float, metallic := 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.resource_name = name
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material

func _emit(name: String, color: Color, energy: float) -> StandardMaterial3D:
	var material := _mat(name, color, 1.0)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	return material

func _branch(parent: Node, name: String) -> Node3D:
	var node := Node3D.new()
	node.name = name
	parent.add_child(node)
	return node

func _prop(parent: Node, name: String, pos: Vector3) -> Node3D:
	var node := Node3D.new()
	node.name = name
	node.position = pos
	parent.add_child(node)
	return node

func _box(parent: Node, name: String, pos: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = name
	node.position = pos
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	node.mesh = mesh
	parent.add_child(node)
	return node

func _cylinder(parent: Node, name: String, pos: Vector3, radius: float, height: float, material: Material, rotation := Vector3.ZERO) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = name
	node.position = pos
	node.rotation_degrees = rotation
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 10
	mesh.material = material
	node.mesh = mesh
	parent.add_child(node)
	return node

func _torus(parent: Node, name: String, pos: Vector3, inner: float, outer: float, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = name
	node.position = pos
	var mesh := TorusMesh.new()
	mesh.inner_radius = inner
	mesh.outer_radius = outer
	mesh.rings = 10
	mesh.ring_segments = 8
	mesh.material = material
	node.mesh = mesh
	parent.add_child(node)
	return node

func _set_owner_recursive(node: Node, root: Node) -> void:
	for child in node.get_children():
		child.owner = root
		_set_owner_recursive(child, root)
