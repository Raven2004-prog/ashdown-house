@tool
extends SceneTree

const OUTPUT := "res://scenes/levels/ashdown/rooms/DormitoryContent.tscn"
const CONTROLLER := preload("res://scripts/level/dormitory_content.gd")
const INTERACTABLE := preload("res://scripts/interaction/interactable_3d.gd")

var mats: Dictionary = {}

func _initialize() -> void:
	call_deferred("_build")

func _build() -> void:
	_materials()
	var root := Node3D.new()
	root.name = "DormitoryContent"
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
	print("DORMITORY_SCENE_BUILT: %s" % error_string(result))
	root.free()
	quit(0 if result == OK else 1)

func _materials() -> void:
	mats = {
		"plaster": _mat("DormitoryPlaster", Color("514840"), 0.97),
		"panel": _mat("DormitoryPanel", Color("343535"), 0.95),
		"trim": _mat("DarkTrim", Color("241813"), 0.88),
		"floor": _mat("WornBoards", Color("38271e"), 0.93),
		"wood": _mat("BunkWood", Color("543422"), 0.86),
		"wood_light": _mat("DresserWood", Color("74503a"), 0.82),
		"iron": _mat("BedIron", Color("24292a"), 0.68, 0.44),
		"mattress": _mat("OldMattress", Color("777267"), 1.0),
		"blanket_red": _mat("MiraBlanket", Color("713a3b"), 1.0),
		"blanket_blue": _mat("ArunBlanket", Color("344d63"), 1.0),
		"blanket_green": _mat("SanaBlanket", Color("40584b"), 1.0),
		"blanket_wet": _mat("WetBlanket", Color("354a4d"), 0.56),
		"sheet": _mat("LaundrySheet", Color("9b988a"), 1.0),
		"paper": _mat("RosterPaper", Color("c3ae7c"), 0.96),
		"brass": _mat("MusicBoxBrass", Color("8b6b3d"), 0.55, 0.28),
		"ribbon": _mat("MiraRibbon", Color("a3383c"), 0.88),
		"train": _mat("TrainBlue", Color("314b6f"), 0.80),
		"soot": _mat("Soot", Color("12100f"), 1.0),
		"chalk": _emit("PaleMark", Color("c9c1a7"), 0.25),
	}

func _mat(name: String, color: Color, roughness: float, metallic := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.resource_name = name
	m.albedo_color = color
	m.roughness = roughness
	m.metallic = metallic
	return m

func _emit(name: String, color: Color, energy: float) -> StandardMaterial3D:
	var m := _mat(name, color, 1.0)
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	return m

func _architecture(parent: Node3D) -> void:
	_box(parent, "FloorFinish", Vector3(-17, 0.025, -11.5), Vector3(15.7, 0.05, 10.7), mats.floor)
	_box(parent, "Ceiling", Vector3(-17, 3.38, -11.5), Vector3(15.7, 0.08, 10.7), mats.plaster)
	_box(parent, "WestWall", Vector3(-24.82, 1.42, -11.5), Vector3(0.08, 2.65, 10.7), mats.panel)
	_box(parent, "SouthWall", Vector3(-17, 1.42, -16.82), Vector3(15.7, 2.65, 0.08), mats.panel)
	_north_wall(parent)
	_east_wall(parent)
	for y in [0.16, 1.05, 2.70]:
		_box(parent, "WestTrim_%s" % str(y), Vector3(-24.73, y, -11.5), Vector3(0.10, 0.10, 10.5), mats.trim)
		_box(parent, "EastTrim_%s" % str(y), Vector3(-9.27, y, -11.5), Vector3(0.10, 0.10, 10.5), mats.trim)
		_box(parent, "NorthTrim_%s" % str(y), Vector3(-17, y, -6.27), Vector3(15.5, 0.10, 0.10), mats.trim)
		_box(parent, "SouthTrim_%s" % str(y), Vector3(-17, y, -16.73), Vector3(15.5, 0.10, 0.10), mats.trim)
	_door_frame(parent, "LibraryDoorFrame", Vector3(-17, 1.18, -6.30), false)
	_door_frame(parent, "BoilerDoorFrame", Vector3(-9.30, 1.18, -11.5), true)

func _north_wall(parent: Node) -> void:
	_box(parent, "NorthWest", Vector3(-21.4, 1.42, -6.18), Vector3(7.0, 2.65, 0.08), mats.panel)
	_box(parent, "NorthEast", Vector3(-12.6, 1.42, -6.18), Vector3(7.0, 2.65, 0.08), mats.panel)

func _east_wall(parent: Node) -> void:
	_box(parent, "EastNorth", Vector3(-9.18, 1.42, -8.75), Vector3(0.08, 2.65, 4.2), mats.panel)
	_box(parent, "EastSouth", Vector3(-9.18, 1.42, -14.25), Vector3(0.08, 2.65, 4.2), mats.panel)

func _door_frame(parent: Node, name: String, pos: Vector3, side: bool) -> void:
	var frame := _prop(parent, name, pos)
	if side: frame.rotation_degrees.y = 90
	_box(frame, "Left", Vector3(-0.86, 0, 0), Vector3(0.16, 2.36, 0.22), mats.trim)
	_box(frame, "Right", Vector3(0.86, 0, 0), Vector3(0.16, 2.36, 0.22), mats.trim)
	_box(frame, "Lintel", Vector3(0, 1.12, 0), Vector3(1.88, 0.18, 0.22), mats.trim)

func _furniture(parent: Node3D) -> void:
	_make_bunk(parent, "Bunk_Mira_Leela", Vector3(-22.8, 0, -9.0), 90, mats.blanket_red, mats.sheet)
	_make_bunk(parent, "Bunk_Arun_Dev", Vector3(-22.8, 0, -13.1), 90, mats.blanket_blue, mats.blanket_red)
	_make_bunk(parent, "Bunk_Sana_Kabir", Vector3(-17.5, 0, -16.0), 0, mats.blanket_green, mats.sheet)
	_make_wardrobe(parent, "WardrobeA", Vector3(-24.2, 0, -15.6), 90)
	_make_wardrobe(parent, "WardrobeB", Vector3(-13.4, 0, -16.1), 0)
	_make_dresser(parent)
	_make_music_box(parent)
	_make_trunk(parent)
	_make_hidden_pallet(parent)
	_make_roster(parent)
	_make_carvings(parent)
	_make_height_marks(parent)
	_make_wet_blanket(parent)
	_make_soot_silhouette(parent)
	_make_rewards(parent)
	_make_personal_clutter(parent)
	for x in [-21.0, -17.0, -13.0]:
		_make_ceiling_lamp(parent, "CeilingLamp_%s" % str(x), Vector3(x, 3.16, -11.2))

func _make_bunk(parent: Node, name: String, pos: Vector3, yaw: float, lower_mat: Material, upper_mat: Material) -> void:
	var bunk := _prop(parent, name, pos)
	bunk.rotation_degrees.y = yaw
	for y in [0.42, 1.48]:
		_box(bunk, "Frame_%s" % str(y), Vector3(0, y, 0), Vector3(2.8, 0.14, 1.05), mats.wood)
		_box(bunk, "Mattress_%s" % str(y), Vector3(0, y + 0.15, 0), Vector3(2.55, 0.18, 0.88), mats.mattress)
		_box(bunk, "Blanket_%s" % str(y), Vector3(0.55, y + 0.27, 0), Vector3(1.2, 0.08, 0.84), lower_mat if y < 1.0 else upper_mat)
	for x in [-1.32, 1.32]:
		_box(bunk, "Post_%s" % str(x), Vector3(x, 1.08, 0), Vector3(0.13, 2.16, 1.02), mats.wood)
	for y in [0.74, 1.12, 1.50, 1.88]:
		_box(bunk, "Ladder_%s" % str(y), Vector3(1.42, y, -0.58), Vector3(0.08, 0.08, 0.70), mats.iron)

func _make_wardrobe(parent: Node, name: String, pos: Vector3, yaw: float) -> void:
	var wardrobe := _prop(parent, name, pos)
	wardrobe.rotation_degrees.y = yaw
	_box(wardrobe, "Body", Vector3(0, 1.1, 0), Vector3(1.65, 2.2, 0.72), mats.wood_light)
	_box(wardrobe, "LeftDoor", Vector3(-0.40, 1.12, -0.38), Vector3(0.76, 2.02, 0.08), mats.wood)
	_box(wardrobe, "RightDoor", Vector3(0.40, 1.12, -0.38), Vector3(0.76, 2.02, 0.08), mats.wood)
	for x in [-0.10, 0.10]:
		_cylinder(wardrobe, "Knob_%s" % str(x), Vector3(x, 1.12, -0.46), 0.035, 0.06, mats.brass, Vector3(90, 0, 0))

func _make_dresser(parent: Node) -> void:
	var dresser := _prop(parent, "CentralDresser", Vector3(-17, 0, -10.7))
	_box(dresser, "Body", Vector3(0, 0.48, 0), Vector3(1.8, 0.96, 0.82), mats.wood_light)
	for i in range(3):
		_box(dresser, "Drawer_%d" % i, Vector3(0, 0.24 + i * 0.26, -0.43), Vector3(1.55, 0.21, 0.08), mats.wood)
		_cylinder(dresser, "Pull_%d" % i, Vector3(0, 0.24 + i * 0.26, -0.50), 0.035, 0.07, mats.brass, Vector3(90, 0, 0))

func _make_music_box(parent: Node) -> void:
	var box_root := _prop(parent, "DR08_MusicBox", Vector3(-17, 0.98, -10.7))
	_box(box_root, "Body", Vector3.ZERO, Vector3(0.68, 0.28, 0.48), mats.wood_light)
	var lid := _prop(box_root, "Lid", Vector3(0, 0.18, 0.22))
	_box(lid, "Panel", Vector3(0, 0, -0.22), Vector3(0.70, 0.10, 0.48), mats.wood)
	_cylinder(box_root, "Crank", Vector3(0.42, 0.02, 0), 0.035, 0.26, mats.brass, Vector3(0, 0, 90))

func _make_trunk(parent: Node) -> void:
	var trunk := _prop(parent, "DR09_ToyTrunk", Vector3(-12.2, 0, -14.8))
	trunk.rotation_degrees.y = 90
	_box(trunk, "Body", Vector3(0, 0.33, 0), Vector3(1.45, 0.66, 0.82), mats.wood_light)
	for x in [-0.58, 0.58]:
		_box(trunk, "Band_%s" % str(x), Vector3(x, 0.34, -0.02), Vector3(0.10, 0.72, 0.88), mats.iron)
	var lid := _prop(trunk, "Lid", Vector3(0, 0.70, 0.38))
	_box(lid, "Panel", Vector3(0, 0, -0.38), Vector3(1.50, 0.14, 0.86), mats.wood)
	_box(trunk, "Latch", Vector3(0, 0.46, -0.44), Vector3(0.20, 0.28, 0.08), mats.brass)

func _make_hidden_pallet(parent: Node) -> void:
	var pallet := _prop(parent, "DR04_SeventhPallet", Vector3(-10.3, 0.02, -15.6))
	pallet.rotation_degrees.y = 90
	_box(pallet, "Mattress", Vector3(0, 0.14, 0), Vector3(2.0, 0.22, 0.72), mats.mattress)
	_box(pallet, "Blanket", Vector3(0.40, 0.27, 0), Vector3(0.90, 0.08, 0.68), mats.sheet)
	var line := _box(pallet, "LaundryLine", Vector3(0, 1.82, -0.58), Vector3(2.6, 0.035, 0.035), mats.iron)
	line.rotation_degrees.z = 2
	for i in range(3):
		var sheet := _box(pallet, "HangingSheet_%d" % i, Vector3(-0.75 + i * 0.75, 1.05, -0.58), Vector3(0.66, 1.45 - i * 0.12, 0.035), mats.sheet)
		sheet.rotation_degrees.z = -3 + i * 3

func _make_roster(parent: Node) -> void:
	var roster := _prop(parent, "DR12_LeelaRoster", Vector3(-22.10, 0.32, -9.0))
	roster.rotation_degrees.y = 90
	_box(roster, "Paper", Vector3.ZERO, Vector3(0.42, 0.025, 0.56), mats.paper)
	for i in range(6):
		_box(roster, "Line_%d" % i, Vector3(0, 0.02, -0.20 + i * 0.07), Vector3(0.30, 0.008, 0.012), mats.soot)

func _make_carvings(parent: Node) -> void:
	var carvings := [
		["DR13_Low", Vector3(-22.50, 0.72, -8.80), 1],
		["DR14_High", Vector3(-22.50, 1.70, -9.10), 3],
		["DR15_Middle", Vector3(-22.50, 0.72, -12.90), 2],
		["DR16_Low", Vector3(-22.50, 1.70, -13.20), 1],
	]
	for data in carvings:
		var carving := _prop(parent, data[0], data[1])
		carving.rotation_degrees.y = 90
		_box(carving, "Bell", Vector3.ZERO, Vector3(0.20 + float(data[2]) * 0.04, 0.14 + float(data[2]) * 0.03, 0.018), mats.chalk)

func _make_height_marks(parent: Node) -> void:
	var marks := _prop(parent, "DR17_HeightMarks", Vector3(-9.22, 1.05, -14.3))
	marks.rotation_degrees.y = -90
	for i in range(7):
		_box(marks, "Mark_%d" % i, Vector3(-0.45 + i * 0.14, -0.25 + i * 0.10, -0.05), Vector3(0.10, 0.025, 0.02), mats.chalk)

func _make_wet_blanket(parent: Node) -> void:
	var blanket := _prop(parent, "DR18_WetBlanket", Vector3(-17.7, 0.18, -16.2))
	_box(blanket, "Folded", Vector3.ZERO, Vector3(1.1, 0.20, 0.80), mats.blanket_wet)
	_box(blanket, "DraggedEnd", Vector3(0.65, -0.06, 0.15), Vector3(0.72, 0.08, 0.52), mats.blanket_wet).rotation_degrees.y = 16

func _make_soot_silhouette(parent: Node) -> void:
	var soot := _prop(parent, "DR22_SootSilhouette", Vector3(-24.72, 1.1, -11.0))
	soot.rotation_degrees.y = 90
	_box(soot, "SootField", Vector3.ZERO, Vector3(0.02, 1.65, 2.35), mats.soot)
	for i in range(2):
		var clean := _emit("CleanShape_%d" % i, Color("5e5b52"), 0.10)
		_box(soot, "Child_%d" % i, Vector3(-0.02, -0.25 + i * 0.12, -0.45 + i * 0.65), Vector3(0.025, 0.95 - i * 0.15, 0.36), clean)

func _make_rewards(parent: Node) -> void:
	var ribbon := _prop(parent, "DR10_MiraRibbonBox", Vector3(-12.20, 0.52, -14.80))
	_box(ribbon, "Box", Vector3.ZERO, Vector3(0.34, 0.16, 0.28), mats.wood_light)
	_box(ribbon, "RibbonA", Vector3(0, 0.12, 0), Vector3(0.56, 0.04, 0.08), mats.ribbon).rotation_degrees.y = 18
	_box(ribbon, "RibbonB", Vector3(0, 0.12, 0), Vector3(0.56, 0.04, 0.08), mats.ribbon).rotation_degrees.y = -18
	var wheel := _prop(parent, "DR11_DevTrainWheel", Vector3(-12.05, 0.48, -14.65))
	var ring := _torus(wheel, "Wheel", Vector3.ZERO, 0.055, 0.16, mats.train)
	ring.rotation_degrees.x = 90
	for i in range(6):
		var spoke := _box(wheel, "Spoke_%d" % i, Vector3.ZERO, Vector3(0.23, 0.025, 0.025), mats.brass)
		spoke.rotation_degrees.y = i * 30

func _make_personal_clutter(parent: Node) -> void:
	for i in range(18):
		var x := -23.7 + (i % 6) * 2.5
		var z := -7.3 - (i / 6) * 3.9
		var mat: Material = mats.paper if i % 3 == 0 else (mats.train if i % 3 == 1 else mats.ribbon)
		var item := _box(parent, "Clutter_%02d" % i, Vector3(x, 0.10 + (i % 2) * 0.08, z), Vector3(0.24 + (i % 3) * 0.08, 0.08, 0.18), mat)
		item.rotation_degrees.y = i * 23

func _make_ceiling_lamp(parent: Node, name: String, pos: Vector3) -> void:
	var lamp := _prop(parent, name, pos)
	_cylinder(lamp, "Canopy", Vector3.ZERO, 0.17, 0.08, mats.brass)
	_cylinder(lamp, "Stem", Vector3(0, -0.16, 0), 0.03, 0.30, mats.brass)
	_cylinder(lamp, "Shade", Vector3(0, -0.38, 0), 0.28, 0.20, mats.sheet)

func _interactions(anchors: Node3D, areas: Node3D) -> void:
	var existing := {
		"DR08": [Vector3(-17, 0.98, -10.7), "../../Furniture/DR08_MusicBox", false, false],
		"DR10": [Vector3(-12.20, 0.58, -14.80), "../../Furniture/DR10_MiraRibbonBox", true, true],
		"DR11": [Vector3(-12.05, 0.52, -14.65), "../../Furniture/DR11_DevTrainWheel", true, true],
	}
	var authored := {
		"DR04": [Vector3(-10.30, 0.42, -15.60), "../../Furniture/DR04_SeventhPallet", false, false],
		"DR09": [Vector3(-12.20, 0.58, -14.80), "../../Furniture/DR09_ToyTrunk", false, false],
		"DR12": [Vector3(-22.10, 0.42, -9.00), "../../Furniture/DR12_LeelaRoster", true, false],
		"DR13": [Vector3(-22.50, 0.72, -8.80), "../../Furniture/DR13_Low", false, false],
		"DR14": [Vector3(-22.50, 1.70, -9.10), "../../Furniture/DR14_High", false, false],
		"DR15": [Vector3(-22.50, 0.72, -12.90), "../../Furniture/DR15_Middle", false, false],
		"DR16": [Vector3(-22.50, 1.70, -13.20), "../../Furniture/DR16_Low", false, false],
		"DR17": [Vector3(-9.25, 1.05, -14.30), "../../Furniture/DR17_HeightMarks", false, false],
		"DR18": [Vector3(-17.70, 0.34, -16.20), "../../Furniture/DR18_WetBlanket", false, false],
		"DR22": [Vector3(-24.65, 1.10, -11.00), "../../Furniture/DR22_SootSilhouette", false, false],
	}
	for id in existing: _anchor(anchors, id, existing[id])
	for id in authored:
		_anchor(anchors, id, authored[id])
		_area(areas, id, authored[id][0])

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
	area.set("interaction_radius", 0.64)
	area.add_to_group("ashdown_interactable", true)
	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	var shape := SphereShape3D.new()
	shape.radius = 0.64
	collision.shape = shape
	area.add_child(collision)
	parent.add_child(area)

func _lighting(parent: Node3D) -> void:
	for i in range(3):
		var light := OmniLight3D.new()
		light.name = "DormitoryPool_%d" % i
		light.position = Vector3(-21 + i * 4, 2.70, -11.2)
		light.light_color = Color("c99e6b")
		light.light_energy = 1.85 if i != 1 else 2.20
		light.omni_range = 5.5
		light.shadow_enabled = true
		parent.add_child(light)

func _atmosphere(parent: Node3D) -> void:
	var smoke := GPUParticles3D.new()
	smoke.name = "DormitorySmoke"
	smoke.position = Vector3(-17, 0.25, -11.5)
	smoke.amount = 36
	smoke.lifetime = 7.0
	smoke.emitting = false
	smoke.visible = false
	smoke.visibility_aabb = AABB(Vector3(-8, -0.5, -6), Vector3(16, 4, 12))
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(7, 0.1, 4.5)
	process.direction = Vector3(0, 1, 0)
	process.spread = 28
	process.initial_velocity_min = 0.07
	process.initial_velocity_max = 0.22
	process.scale_min = 1.2
	process.scale_max = 2.8
	process.color = Color(0.13, 0.13, 0.14, 0.18)
	smoke.process_material = process
	var quad := QuadMesh.new()
	quad.size = Vector2(1.0, 1.0)
	var smoke_mat := _mat("DormitorySmokeMat", Color(0.16, 0.16, 0.17, 0.15), 1.0)
	smoke_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smoke_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smoke_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	smoke_mat.vertex_color_use_as_albedo = true
	quad.material = smoke_mat
	smoke.draw_pass_1 = quad
	parent.add_child(smoke)

func _branch(parent: Node, name: String) -> Node3D:
	var n := Node3D.new(); n.name = name; parent.add_child(n); return n

func _prop(parent: Node, name: String, pos: Vector3) -> Node3D:
	var n := Node3D.new(); n.name = name; n.position = pos; parent.add_child(n); return n

func _box(parent: Node, name: String, pos: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var n := MeshInstance3D.new(); n.name = name; n.position = pos
	var mesh := BoxMesh.new(); mesh.size = size; mesh.material = material
	n.mesh = mesh; parent.add_child(n); return n

func _cylinder(parent: Node, name: String, pos: Vector3, radius: float, height: float, material: Material, rotation := Vector3.ZERO) -> MeshInstance3D:
	var n := MeshInstance3D.new(); n.name = name; n.position = pos; n.rotation_degrees = rotation
	var mesh := CylinderMesh.new(); mesh.top_radius = radius; mesh.bottom_radius = radius; mesh.height = height; mesh.radial_segments = 10; mesh.material = material
	n.mesh = mesh; parent.add_child(n); return n

func _torus(parent: Node, name: String, pos: Vector3, inner: float, outer: float, material: Material) -> MeshInstance3D:
	var n := MeshInstance3D.new(); n.name = name; n.position = pos
	var mesh := TorusMesh.new(); mesh.inner_radius = inner; mesh.outer_radius = outer; mesh.rings = 10; mesh.ring_segments = 8; mesh.material = material
	n.mesh = mesh; parent.add_child(n); return n

func _set_owner_recursive(node: Node, root: Node) -> void:
	for child in node.get_children(): child.owner = root; _set_owner_recursive(child, root)
