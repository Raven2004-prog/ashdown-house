@tool
extends SceneTree

const OUTPUT := "res://scenes/levels/ashdown/rooms/ClassroomContent.tscn"
const CONTROLLER := preload("res://scripts/level/classroom_content.gd")
const INTERACTABLE := preload("res://scripts/interaction/interactable_3d.gd")

var mats: Dictionary = {}

func _initialize() -> void:
	call_deferred("_build")

func _build() -> void:
	_make_materials()
	var root := Node3D.new()
	root.name = "ClassroomContent"
	root.set_script(CONTROLLER)
	var architecture := _branch(root, "Architecture")
	var furniture := _branch(root, "Furniture")
	var anchors := _branch(root, "InteractionAnchors")
	var interactables := _branch(root, "Interactables")
	var lighting := _branch(root, "Lighting")
	var atmosphere := _branch(root, "Atmosphere")
	_build_architecture(architecture)
	_build_furniture(furniture)
	_build_interactions(anchors, interactables)
	_build_lighting(lighting)
	_build_atmosphere(atmosphere)
	_set_owner_recursive(root, root)
	var packed := PackedScene.new()
	var pack_result := packed.pack(root)
	if pack_result != OK:
		push_error("Could not pack Classroom: %s" % error_string(pack_result))
		quit(1)
		return
	var save_result := ResourceSaver.save(packed, OUTPUT)
	print("CLASSROOM_SCENE_BUILT: %s" % error_string(save_result))
	root.free()
	quit(0 if save_result == OK else 1)

func _make_materials() -> void:
	mats = {
		"plaster": _mat("SmokeIvoryPlaster", Color("514d42"), 0.96),
		"panel": _mat("SchoolGreenPanel", Color("2d3833"), 0.94),
		"trim": _mat("DarkWalnutTrim", Color("241912"), 0.86),
		"floor": _mat("WornSchoolFloor", Color("49382a"), 0.90),
		"wood": _mat("SchoolDeskOak", Color("75523a"), 0.82),
		"wood_dark": _mat("DeskFrame", Color("3b281d"), 0.86),
		"board": _mat("Chalkboard", Color("182622"), 0.98),
		"chalk": _emissive("Chalk", Color("d9d1b6"), 0.35),
		"paper": _mat("AgedPaper", Color("c5b488"), 0.96),
		"paper_red": _mat("RedCard", Color("8c3c34"), 0.94),
		"paper_blue": _mat("BlueCard", Color("40536d"), 0.94),
		"metal": _mat("PaintedSteel", Color("343a3a"), 0.62, 0.40),
		"brass": _mat("TarnishedBrass", Color("8a6c3d"), 0.58, 0.28),
		"ceramic": _mat("FuseCeramic", Color("dad4bd"), 0.72),
		"blue": _mat("FuseBlue", Color("3c6681"), 0.72),
		"red": _mat("ExtinguisherRed", Color("8b2822"), 0.72, 0.12),
		"glass": _mat("ProjectorGlass", Color("8093a0"), 0.30),
		"screen": _mat("ProjectionScreen", Color("aaa994"), 0.92),
		"soot": _mat("Soot", Color("11100f"), 1.0),
		"cloth": _mat("FoldedCloth", Color("5c6a63"), 1.0),
		"marble": _mat("BlueMarble", Color("244a85"), 0.22),
	}

func _mat(name: String, color: Color, roughness: float, metallic := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.resource_name = name
	m.albedo_color = color
	m.roughness = roughness
	m.metallic = metallic
	return m

func _emissive(name: String, color: Color, energy: float) -> StandardMaterial3D:
	var m := _mat(name, color, 1.0)
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	return m

func _build_architecture(parent: Node3D) -> void:
	_box(parent, "ClassroomFloorFinish", Vector3(17, 0.025, 2), Vector3(15.7, 0.05, 13.7), mats.floor)
	_box(parent, "ClassroomCeiling", Vector3(17, 3.38, 2), Vector3(15.7, 0.08, 13.7), mats.plaster)
	_box(parent, "NorthWallFinish", Vector3(17, 1.42, 8.82), Vector3(15.7, 2.65, 0.08), mats.panel)
	_box(parent, "EastWallFinish", Vector3(24.82, 1.42, 2), Vector3(0.08, 2.65, 13.7), mats.panel)
	_side_wall_gap(parent, "WestWall", 9.18, -5.0, 9.0, 2.0, 1.65)
	_south_wall(parent)
	for y in [0.16, 1.05, 2.70]:
		_box(parent, "NorthTrim_%s" % str(y), Vector3(17, y, 8.73), Vector3(15.5, 0.10, 0.10), mats.trim)
		_box(parent, "EastTrim_%s" % str(y), Vector3(24.73, y, 2), Vector3(0.10, 0.10, 13.5), mats.trim)
		_box(parent, "WestTrim_%s" % str(y), Vector3(9.27, y, 2), Vector3(0.10, 0.10, 13.5), mats.trim)
		_box(parent, "SouthTrim_%s" % str(y), Vector3(17, y, -4.73), Vector3(15.5, 0.10, 0.10), mats.trim)
	_door_frame(parent, "HallDoorFrame", Vector3(9.30, 1.18, 2), true)
	_door_frame(parent, "BathroomDoorFrame", Vector3(13, 1.18, -4.70), false)
	_door_frame(parent, "KitchenDoorFrame", Vector3(22, 1.18, -4.70), false)

func _side_wall_gap(parent: Node, prefix: String, x: float, z_min: float, z_max: float, gap: float, width: float) -> void:
	var south := gap - width * 0.5 - z_min
	var north := z_max - (gap + width * 0.5)
	_box(parent, prefix + "South", Vector3(x, 1.42, z_min + south * 0.5), Vector3(0.08, 2.65, south), mats.panel)
	_box(parent, prefix + "North", Vector3(x, 1.42, gap + width * 0.5 + north * 0.5), Vector3(0.08, 2.65, north), mats.panel)

func _south_wall(parent: Node) -> void:
	_box(parent, "SouthWest", Vector3(10.95, 1.42, -4.82), Vector3(3.9, 2.65, 0.08), mats.panel)
	_box(parent, "SouthMiddle", Vector3(17.5, 1.42, -4.82), Vector3(7.3, 2.65, 0.08), mats.panel)
	_box(parent, "SouthEast", Vector3(23.85, 1.42, -4.82), Vector3(2.3, 2.65, 0.08), mats.panel)

func _door_frame(parent: Node, name: String, pos: Vector3, side: bool) -> void:
	var frame := _prop(parent, name, pos)
	if side: frame.rotation_degrees.y = 90
	_box(frame, "Left", Vector3(-0.86, 0, 0), Vector3(0.16, 2.36, 0.22), mats.trim)
	_box(frame, "Right", Vector3(0.86, 0, 0), Vector3(0.16, 2.36, 0.22), mats.trim)
	_box(frame, "Lintel", Vector3(0, 1.12, 0), Vector3(1.88, 0.18, 0.22), mats.trim)

func _build_furniture(parent: Node3D) -> void:
	_make_blackboard(parent)
	_make_teacher_desk(parent)
	_make_projector(parent)
	_make_fuse_panel(parent)
	_make_name_board(parent)
	var desk_data := [
		["C10_MiraDesk", Vector3(13, 0, 3.3), "M"],
		["C11_ArunDesk", Vector3(17, 0, 3.3), "A"],
		["C12_DevDesk", Vector3(21, 0, 3.3), "D"],
		["C13_LeelaDesk", Vector3(13, 0, -0.2), "L"],
		["C14_SanaDesk", Vector3(17, 0, -0.2), "S"],
		["C15_KabirDesk", Vector3(21, 0, -0.2), "K"],
		["SpareDesk", Vector3(13, 0, -3.3), ""],
	]
	for data in desk_data:
		_make_pupil_desk(parent, data[0], data[1], data[2], false)
	_make_pupil_desk(parent, "C16_UnnamedSeventhDesk", Vector3(23.2, 0, -3.2), "", true)
	_make_fuse(parent, "C07_Fuse5A", Vector3(23.8, 0.82, 4.25), mats.ceramic)
	_make_fuse(parent, "C08_Fuse8A", Vector3(19.8, 0.82, 6.15), mats.blue)
	_make_fuse(parent, "C09_Fuse13A", Vector3(10.3, 0.36, -3.8), mats.ceramic)
	_make_cards(parent)
	_make_slide(parent)
	_make_marble(parent)
	_make_teacher_rewards(parent)
	_make_wire_repair(parent)
	_make_extinguisher(parent)
	_make_wall_clock(parent)
	_make_cubbies(parent)
	for x in [12.5, 17.0, 21.5]:
		_make_ceiling_lamp(parent, "CeilingLamp_%s" % str(x), Vector3(x, 3.16, 2.0))

func _make_blackboard(parent: Node) -> void:
	var board := _prop(parent, "C01_Blackboard", Vector3(17, 1.72, 8.55))
	_box(board, "Frame", Vector3.ZERO, Vector3(5.8, 1.68, 0.14), mats.trim)
	_box(board, "Board", Vector3(0, 0, -0.085), Vector3(5.5, 1.40, 0.04), mats.board)
	var rows := [[-0.38, 1.15, 0.95], [0.02, 0.85, 0.75], [0.42, 1.35, 1.05]]
	for i in range(rows.size()):
		var y: float = rows[i][0]
		var left: float = rows[i][1]
		var right: float = rows[i][2]
		_box(board, "Equation_%d_A" % i, Vector3(-1.15, y, -0.12), Vector3(left, 0.045, 0.02), mats.chalk)
		_box(board, "Equation_%d_B" % i, Vector3(0.55, y, -0.12), Vector3(right, 0.045, 0.02), mats.chalk)
	_box(board, "ChalkTray", Vector3(0, -0.82, -0.04), Vector3(5.6, 0.10, 0.24), mats.wood_dark)

func _make_teacher_desk(parent: Node) -> void:
	var desk := _prop(parent, "TeacherDesk", Vector3(21.7, 0, 6.15))
	_box(desk, "Top", Vector3(0, 0.82, 0), Vector3(2.1, 0.14, 0.9), mats.wood)
	_box(desk, "LeftCabinet", Vector3(-0.75, 0.42, 0), Vector3(0.48, 0.76, 0.78), mats.wood_dark)
	_box(desk, "RightCabinet", Vector3(0.75, 0.42, 0), Vector3(0.48, 0.76, 0.78), mats.wood_dark)
	var drawer := _prop(desk, "RewardDrawer", Vector3(0.75, 0.66, -0.43))
	_box(drawer, "Front", Vector3.ZERO, Vector3(0.42, 0.22, 0.10), mats.wood)
	_cylinder(drawer, "Pull", Vector3(0, 0, -0.08), 0.035, 0.06, mats.brass, Vector3(90, 0, 0))
	_make_chair(parent, "TeacherChair", Vector3(21.7, 0, 7.15), 180, true)

func _make_projector(parent: Node) -> void:
	var projector := _prop(parent, "C04_Projector", Vector3(17, 0, 4.2))
	_box(projector, "Stand", Vector3(0, 0.68, 0), Vector3(0.72, 1.30, 0.58), mats.metal)
	_box(projector, "Body", Vector3(0, 1.32, 0), Vector3(0.88, 0.40, 0.72), mats.metal)
	_cylinder(projector, "Lens", Vector3(0, 1.34, -0.43), 0.17, 0.25, mats.glass, Vector3(90, 0, 0))
	var screen := _prop(parent, "C05_ProjectorScreen", Vector3(17, 1.75, 7.98))
	_box(screen, "Frame", Vector3.ZERO, Vector3(4.5, 2.15, 0.12), mats.trim)
	_box(screen, "Screen", Vector3(0, 0, -0.08), Vector3(4.2, 1.86, 0.035), mats.screen)
	var glow_mat := _emissive("PoweredProjection", Color("73828a"), 1.4)
	glow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow_mat.albedo_color.a = 0.48
	var glow := _box(screen, "PoweredGlow", Vector3(0, 0, -0.11), Vector3(4.08, 1.74, 0.02), glow_mat)
	glow.visible = false
	var stars := _prop(screen, "ProjectionStars", Vector3.ZERO)
	stars.visible = false
	for i in range(7):
		_box(stars, "Star_%d" % i, Vector3(-1.5 + i * 0.48, 0.45 - (i % 3) * 0.34, -0.14), Vector3(0.06, 0.06, 0.02), mats.chalk)

func _make_fuse_panel(parent: Node) -> void:
	var panel := _prop(parent, "C06_FusePanel", Vector3(24.68, 1.42, 5.3))
	panel.rotation_degrees.y = 90
	_box(panel, "Cabinet", Vector3.ZERO, Vector3(1.20, 1.45, 0.18), mats.metal)
	_box(panel, "OpenDoor", Vector3(0.68, 0, -0.16), Vector3(1.05, 1.32, 0.08), mats.metal).rotation_degrees.y = -38
	for i in range(3):
		_cylinder(panel, "Socket_%d" % i, Vector3(-0.36 + i * 0.36, 0.18, -0.15), 0.11, 0.12, mats.ceramic, Vector3(90, 0, 0))
		_box(panel, "Label_%d" % i, Vector3(-0.36 + i * 0.36, -0.30, -0.15), Vector3(0.25, 0.12, 0.025), mats.paper)

func _make_name_board(parent: Node) -> void:
	var board := _prop(parent, "C18_NameCardBoard", Vector3(11, 1.35, 8.55))
	_box(board, "Back", Vector3.ZERO, Vector3(2.6, 1.35, 0.10), mats.wood_dark)
	for row in range(2):
		for col in range(3):
			_box(board, "Slot_%d_%d" % [row, col], Vector3(-0.82 + col * 0.82, 0.30 - row * 0.58, -0.08), Vector3(0.62, 0.30, 0.035), mats.paper)

func _make_pupil_desk(parent: Node, name: String, pos: Vector3, initial: String, mismatched: bool) -> void:
	var desk := _prop(parent, name, pos)
	if mismatched: desk.rotation_degrees.y = 15
	var top_mat: Material = mats.wood_dark if mismatched else mats.wood
	_box(desk, "Top", Vector3(0, 0.70, 0), Vector3(1.35, 0.12, 0.72), top_mat)
	_box(desk, "Shelf", Vector3(0, 0.40, 0.10), Vector3(1.18, 0.08, 0.52), mats.wood_dark)
	for x in [-0.54, 0.54]:
		_box(desk, "Leg_%s" % str(x), Vector3(x, 0.34, 0), Vector3(0.09, 0.68, 0.60), mats.wood_dark)
	if initial != "":
		_box(desk, "NamePlate", Vector3(0, 0.77, -0.29), Vector3(0.42, 0.07, 0.10), mats.brass)
	_make_chair(parent, name + "Chair", pos + Vector3(0, 0, 0.95), 0, mismatched)
	if mismatched:
		_box(desk, "FoldedCloth", Vector3(-0.52, 0.08, 0.24), Vector3(0.32, 0.12, 0.28), mats.cloth)

func _make_chair(parent: Node, name: String, pos: Vector3, yaw: float, mismatched: bool) -> void:
	var chair := _prop(parent, name, pos)
	chair.rotation_degrees.y = yaw + (7 if mismatched else 0)
	_box(chair, "Seat", Vector3(0, 0.45, 0), Vector3(0.62, 0.12, 0.58), mats.wood)
	_box(chair, "Back", Vector3(0, 0.88, 0.25), Vector3(0.62, 0.72, 0.10), mats.wood_dark)
	for x in [-0.24, 0.24]:
		for z in [-0.20, 0.20]:
			_box(chair, "Leg_%s_%s" % [str(x), str(z)], Vector3(x, 0.22, z), Vector3(0.07, 0.44, 0.07), mats.wood_dark)

func _make_fuse(parent: Node, name: String, pos: Vector3, band: Material) -> void:
	var fuse := _prop(parent, name, pos)
	_cylinder(fuse, "Body", Vector3.ZERO, 0.10, 0.36, mats.ceramic, Vector3(0, 0, 90))
	for x in [-0.17, 0.17]:
		_cylinder(fuse, "Cap_%s" % str(x), Vector3(x, 0, 0), 0.105, 0.08, mats.brass, Vector3(0, 0, 90))
	_cylinder(fuse, "Band", Vector3.ZERO, 0.104, 0.08, band, Vector3(0, 0, 90))

func _make_cards(parent: Node) -> void:
	var cards := _prop(parent, "C19_SixNameCards", Vector3(11.3, 0.84, 6.6))
	for i in range(6):
		var mat: Material = mats.paper_red if i % 2 == 0 else mats.paper_blue
		_box(cards, "Card_%d" % i, Vector3((i % 3) * 0.22, i * 0.008, (i / 3) * 0.18), Vector3(0.28, 0.018, 0.14), mat)

func _make_slide(parent: Node) -> void:
	var slide := _prop(parent, "C20_ArunStarSlide", Vector3(17, 1.18, 4.08))
	_box(slide, "Frame", Vector3.ZERO, Vector3(0.28, 0.025, 0.28), mats.paper)
	_box(slide, "Film", Vector3(0, 0.018, 0), Vector3(0.19, 0.018, 0.19), mats.glass)

func _make_marble(parent: Node) -> void:
	var marble := _prop(parent, "C21_KabirBlueMarble", Vector3(20.92, 0.16, -0.10))
	var mesh := SphereMesh.new()
	mesh.radius = 0.11
	mesh.height = 0.22
	mesh.radial_segments = 12
	mesh.rings = 6
	mesh.material = mats.marble
	var visual := MeshInstance3D.new()
	visual.name = "Marble"
	visual.mesh = mesh
	marble.add_child(visual)

func _make_teacher_rewards(parent: Node) -> void:
	var attendance := _prop(parent, "C22_AttendanceSheet", Vector3(21.62, 0.86, 6.05))
	_box(attendance, "Paper", Vector3.ZERO, Vector3(0.44, 0.02, 0.56), mats.paper)
	for i in range(7):
		_box(attendance, "Line_%d" % i, Vector3(0, 0.018, -0.21 + i * 0.07), Vector3(0.32, 0.008, 0.012), mats.board)
	var key := _prop(parent, "C23_BathroomKey", Vector3(21.85, 0.86, 6.25))
	_torus(key, "Ring", Vector3.ZERO, 0.035, 0.105, mats.brass)
	_box(key, "Stem", Vector3(0.16, 0, 0), Vector3(0.28, 0.035, 0.035), mats.brass)
	_box(key, "Tooth", Vector3(0.28, 0, 0.05), Vector3(0.08, 0.035, 0.12), mats.brass)
	var pointer := _prop(parent, "C24_HookedPointer", Vector3(10.1, 0.70, 8.0))
	_box(pointer, "Shaft", Vector3(0.85, 0, 0), Vector3(1.7, 0.045, 0.045), mats.wood)
	_torus(pointer, "Hook", Vector3(1.72, 0, 0), 0.025, 0.09, mats.brass)
	var code := _prop(parent, "C25_DormitoryCode", Vector3(21.75, 0.87, 6.15))
	_box(code, "Paper", Vector3.ZERO, Vector3(0.34, 0.02, 0.22), mats.paper_red)
	for i in range(4):
		_box(code, "Symbol_%d" % i, Vector3(-0.12 + i * 0.08, 0.018, 0), Vector3(0.035, 0.008, 0.06), mats.chalk)

func _make_wire_repair(parent: Node) -> void:
	var repair := _prop(parent, "C26_WireRepair", Vector3(24.70, 1.36, 5.30))
	for i in range(4):
		var wire := _box(repair, "Wire_%d" % i, Vector3(0, -0.35 + i * 0.22, -0.12), Vector3(0.025, 0.55, 0.025), mats.brass)
		wire.rotation_degrees.z = -18 + i * 11

func _make_extinguisher(parent: Node) -> void:
	var ext := _prop(parent, "C29_FireExtinguisher", Vector3(22, 0.35, -4.55))
	_cylinder(ext, "Tank", Vector3(0, 0.35, 0), 0.22, 0.72, mats.red)
	_cylinder(ext, "Valve", Vector3(0, 0.78, 0), 0.07, 0.18, mats.brass)
	_box(ext, "Handle", Vector3(0.13, 0.88, 0), Vector3(0.30, 0.07, 0.10), mats.metal)
	var hose := _torus(ext, "Hose", Vector3(0.18, 0.58, 0), 0.025, 0.25, mats.metal)
	hose.rotation_degrees.x = 90

func _make_wall_clock(parent: Node) -> void:
	var clock := _prop(parent, "WallClock", Vector3(19.7, 2.45, 8.68))
	clock.rotation_degrees.y = 180
	_cylinder(clock, "Face", Vector3.ZERO, 0.28, 0.08, mats.paper, Vector3(90, 0, 0))
	_box(clock, "HourHand", Vector3(0.05, 0.04, -0.06), Vector3(0.16, 0.025, 0.02), mats.board).rotation_degrees.z = 25
	_box(clock, "MinuteHand", Vector3(-0.02, 0.08, -0.06), Vector3(0.025, 0.22, 0.02), mats.board).rotation_degrees.z = -35

func _make_cubbies(parent: Node) -> void:
	var cubbies := _prop(parent, "WestCubbies", Vector3(9.55, 0, 6.0))
	_box(cubbies, "Back", Vector3(0, 0.90, 0), Vector3(0.42, 1.80, 2.8), mats.wood_dark)
	for i in range(5):
		_box(cubbies, "Shelf_%d" % i, Vector3(-0.24, 0.22 + i * 0.34, 0), Vector3(0.48, 0.06, 2.8), mats.wood)
	for z in [-1.0, -0.5, 0, 0.5, 1.0]:
		_box(cubbies, "Divider_%s" % str(z), Vector3(-0.24, 0.90, z), Vector3(0.48, 1.65, 0.05), mats.wood)

func _make_ceiling_lamp(parent: Node, name: String, pos: Vector3) -> void:
	var lamp := _prop(parent, name, pos)
	_cylinder(lamp, "Canopy", Vector3.ZERO, 0.18, 0.08, mats.brass)
	_cylinder(lamp, "Stem", Vector3(0, -0.16, 0), 0.03, 0.30, mats.brass)
	_cylinder(lamp, "Shade", Vector3(0, -0.38, 0), 0.30, 0.20, mats.glass)

func _build_interactions(anchors: Node3D, areas: Node3D) -> void:
	var existing := {
		"C01": [Vector3(17, 1.55, 8.25), "../../Furniture/C01_Blackboard", false, false],
		"C22": [Vector3(21.62, 0.90, 6.05), "../../Furniture/C22_AttendanceSheet", true, true],
		"C23": [Vector3(21.85, 0.90, 6.25), "../../Furniture/C23_BathroomKey", true, true],
		"C29": [Vector3(22, 0.75, -4.55), "../../Furniture/C29_FireExtinguisher", true, false],
	}
	var authored := {
		"C04": [Vector3(17, 1.30, 4.20), "../../Furniture/C04_Projector", false, false],
		"C06": [Vector3(24.45, 1.40, 5.30), "../../Furniture/C06_FusePanel", false, false],
		"C07": [Vector3(23.80, 0.82, 4.25), "../../Furniture/C07_Fuse5A", true, true],
		"C08": [Vector3(19.80, 0.82, 6.15), "../../Furniture/C08_Fuse8A", true, true],
		"C09": [Vector3(10.30, 0.36, -3.80), "../../Furniture/C09_Fuse13A", true, true],
		"C16": [Vector3(23.20, 0.72, -3.20), "../../Furniture/C16_UnnamedSeventhDesk", false, false],
		"C18": [Vector3(11.00, 1.25, 7.90), "../../Furniture/C18_NameCardBoard", false, false],
		"C19": [Vector3(11.30, 0.84, 6.60), "../../Furniture/C19_SixNameCards", true, true],
		"C20": [Vector3(17.00, 1.18, 4.08), "../../Furniture/C20_ArunStarSlide", true, true],
		"C21": [Vector3(20.92, 0.16, -0.10), "../../Furniture/C21_KabirBlueMarble", true, true],
		"C24": [Vector3(10.10, 0.70, 8.00), "../../Furniture/C24_HookedPointer", true, true],
		"C25": [Vector3(21.75, 0.88, 6.15), "../../Furniture/C25_DormitoryCode", true, true],
		"C26": [Vector3(24.20, 1.36, 5.30), "../../Furniture/C26_WireRepair", false, false],
	}
	for id in existing:
		_add_anchor(anchors, id, existing[id])
	for id in authored:
		_add_anchor(anchors, id, authored[id])
		_add_area(areas, id, authored[id][0])

func _add_anchor(parent: Node, id: String, data: Array) -> void:
	var anchor := Marker3D.new()
	anchor.name = id + "Anchor"
	anchor.position = data[0]
	anchor.add_to_group("ashdown_interaction_anchor", true)
	anchor.set_meta("interaction_id", StringName(id))
	anchor.set_meta("visual_path", NodePath(data[1]))
	anchor.set_meta("hide_visual_on_collect", data[2])
	anchor.set_meta("hide_visual_when_unavailable", data[3])
	parent.add_child(anchor)

func _add_area(parent: Node, id: String, pos: Vector3) -> void:
	var area := Area3D.new()
	area.name = id
	area.position = pos
	area.set_script(INTERACTABLE)
	area.set("interaction_id", StringName(id))
	area.set("interaction_radius", 0.62)
	area.add_to_group("ashdown_interactable", true)
	var shape := CollisionShape3D.new()
	shape.name = "CollisionShape3D"
	var sphere := SphereShape3D.new()
	sphere.radius = 0.62
	shape.shape = sphere
	area.add_child(shape)
	parent.add_child(area)

func _build_lighting(parent: Node3D) -> void:
	for index in range(3):
		var light := OmniLight3D.new()
		light.name = "CeilingPool_%d" % index
		light.position = Vector3(12.5 + index * 4.5, 2.72, 2.0)
		light.light_color = Color("d7b77f")
		light.light_energy = 1.45
		light.omni_range = 5.3
		light.shadow_enabled = true
		parent.add_child(light)
	var projector := SpotLight3D.new()
	projector.name = "ProjectorLight"
	projector.position = Vector3(17, 1.35, 4.0)
	projector.rotation_degrees.x = -90
	projector.light_color = Color("aabcc5")
	projector.light_energy = 4.0
	projector.spot_range = 5.0
	projector.spot_angle = 34.0
	projector.shadow_enabled = true
	projector.visible = false
	parent.add_child(projector)

func _build_atmosphere(parent: Node3D) -> void:
	var smoke := GPUParticles3D.new()
	smoke.name = "ClassroomSmoke"
	smoke.position = Vector3(17, 0.25, 0.6)
	smoke.amount = 40
	smoke.lifetime = 7.0
	smoke.emitting = false
	smoke.visible = false
	smoke.visibility_aabb = AABB(Vector3(-8, -0.5, -7), Vector3(16, 4, 14))
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(7, 0.1, 5.8)
	process.direction = Vector3(0, 1, 0)
	process.spread = 28
	process.initial_velocity_min = 0.08
	process.initial_velocity_max = 0.24
	process.scale_min = 1.2
	process.scale_max = 3.0
	process.color = Color(0.13, 0.13, 0.14, 0.18)
	smoke.process_material = process
	var quad := QuadMesh.new()
	quad.size = Vector2(1.1, 1.1)
	var smoke_mat := _mat("ClassroomSmokeMaterial", Color(0.16, 0.16, 0.17, 0.16), 1.0)
	smoke_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smoke_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smoke_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	smoke_mat.vertex_color_use_as_albedo = true
	quad.material = smoke_mat
	smoke.draw_pass_1 = quad
	parent.add_child(smoke)
	var fire := _prop(parent, "DoorwayFire", Vector3(22, 0, -4.75))
	for i in range(7):
		var flame_mat := _emissive("Flame_%d" % i, Color("d65a20") if i % 2 == 0 else Color("e7aa3f"), 2.2)
		var flame := _cylinder(fire, "Flame_%d" % i, Vector3(-0.8 + i * 0.26, 0.28 + (i % 3) * 0.10, 0), 0.13, 0.48 + (i % 3) * 0.20, flame_mat)
		flame.rotation_degrees.z = -12 + i * 4
	var light := OmniLight3D.new()
	light.name = "FireLight"
	light.position = Vector3(0, 0.65, 0)
	light.light_color = Color("e45c20")
	light.light_energy = 2.8
	light.omni_range = 5.5
	light.shadow_enabled = true
	fire.add_child(light)
	fire.visible = false

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
