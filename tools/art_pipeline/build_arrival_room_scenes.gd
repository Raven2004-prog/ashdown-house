@tool
extends SceneTree

const OUTPUT_DIR := "res://scenes/levels/ashdown/rooms"
const MAIN_HALL_SCRIPT := preload("res://scripts/level/main_hall_content.gd")

var materials: Dictionary = {}

func _initialize() -> void:
	call_deferred("_build")

func _build() -> void:
	_build_materials()
	var vestibule := _create_vestibule()
	_save_scene(vestibule, "%s/VestibuleContent.tscn" % OUTPUT_DIR)
	vestibule.free()
	var hall := _create_main_hall()
	_save_scene(hall, "%s/MainHallContent.tscn" % OUTPUT_DIR)
	hall.free()
	print("ARRIVAL_ROOM_SCENES_BUILT")
	quit(0)

func _build_materials() -> void:
	materials = {
		"plaster": _material("AgedIvoryPlaster", Color("4b473d"), 0.96),
		"panel": _material("SmokeGreenPanel", Color("24302d"), 0.92),
		"trim": _material("CharredWalnutTrim", Color("241710"), 0.84),
		"wood": _material("AgedWalnut", Color("4a2e1c"), 0.80),
		"wood_light": _material("WornOak", Color("765039"), 0.78),
		"floor": _material("DarkHerringboneFloor", Color("30251c"), 0.88),
		"runner": _material("FadedBurgundyRunner", Color("4b2022"), 0.96),
		"brass": _material("TarnishedBrass", Color("80643a"), 0.58, 0.25),
		"iron": _material("BlackenedIron", Color("17191a"), 0.64, 0.55),
		"paper": _material("AgedPaper", Color("c1ae7e"), 0.94),
		"glass": _material("SmokedGlass", Color("607078"), 0.34, 0.12),
		"fabric": _material("DustyFabric", Color("62504b"), 1.0),
		"soot": _material("Soot", Color("100e0d"), 1.0),
		"red": _material("AlarmRed", Color("6d2420"), 0.88),
		"doll_cloth": _material("DollAgedCloth", Color("8d8068"), 0.98),
		"doll_skin": _material("DollPaintedPorcelain", Color("b6aa8c"), 0.86),
		"doll_dark": _material("DollSootDamage", Color("292321"), 1.0),
		"doll_blue": _material("DollFadedBlue", Color("334b68"), 0.94),
		"doll_teal": _material("DollWashedTeal", Color("426a68"), 0.94),
		"doll_red": _material("DollFadedRed", Color("7f3540"), 0.94),
		"doll_amber": _material("DollMustard", Color("8c6c32"), 0.94),
		"doll_violet": _material("DollBruisedViolet", Color("5a4668"), 0.94),
		"doll_green": _material("DollMossGreen", Color("40533f"), 0.94),
	}

func _material(name: String, color: Color, roughness: float, metallic := 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.resource_name = name
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material

func _create_vestibule() -> Node3D:
	var root := Node3D.new()
	root.name = "VestibuleContent"
	var architecture := _branch(root, "Architecture")
	var furniture := _branch(root, "Furniture")
	var anchors := _branch(root, "InteractionAnchors")
	var lighting := _branch(root, "Lighting")
	_branch(root, "Atmosphere")

	_box(architecture, "VestibuleFloorFinish", Vector3(0, 0.025, 13), Vector3(9.7, 0.05, 7.7), materials.floor)
	_box(architecture, "VestibuleCeiling", Vector3(0, 3.38, 13), Vector3(9.7, 0.08, 7.7), materials.plaster)
	_box(architecture, "WestWallPanel", Vector3(-4.82, 1.42, 13), Vector3(0.08, 2.65, 7.55), materials.panel)
	_box(architecture, "EastWallPanel", Vector3(4.82, 1.42, 13), Vector3(0.08, 2.65, 7.55), materials.panel)
	_wall_with_gap(architecture, "NorthWall", 16.82, 10.0, 0.0, 1.65)
	_wall_with_gap(architecture, "SouthWall", 9.18, 10.0, 0.0, 1.65)
	_add_room_trim(architecture, -4.74, 4.74, 9.24, 16.76)
	_box(architecture, "Runner", Vector3(0, 0.065, 13.05), Vector3(2.2, 0.025, 6.1), materials.runner)
	_add_door_frame(architecture, "ExteriorDoorFrame", Vector3(0, 1.18, 16.70), false)
	_add_door_frame(architecture, "HallDoorFrame", Vector3(0, 1.18, 9.30), false)

	var front_door := _prop(furniture, "ExteriorDoor", Vector3(0, 1.16, 16.78))
	_box_part(front_door, "DoorSlab", Vector3.ZERO, Vector3(1.42, 2.22, 0.12), materials.wood)
	_box_part(front_door, "UpperPanel", Vector3(0, 0.44, -0.07), Vector3(1.02, 0.72, 0.04), materials.wood_light)
	_box_part(front_door, "LowerPanel", Vector3(0, -0.48, -0.07), Vector3(1.02, 0.70, 0.04), materials.wood_light)
	_cylinder_part(front_door, "DoorKnob", Vector3(0.48, 0.0, -0.13), 0.07, 0.08, materials.brass, Vector3(90, 0, 0))

	var chain := _prop(furniture, "V03_Chain", Vector3(0, 1.2, 16.62))
	for index in range(11):
		var x := -0.58 + index * 0.116
		var y := sin(float(index) * 0.62) * -0.13
		var link := _torus_part(chain, "Link_%02d" % index, Vector3(x, y, 0), materials.iron)
		link.rotation_degrees = Vector3(90, 0, 90 if index % 2 == 0 else 0)

	var table := _make_table(furniture, "ReceptionTable", Vector3(-2.9, 0.0, 11.3), Vector3(1.65, 0.72, 0.7))
	var lantern := _make_lantern(furniture, "V08_PlayerLantern", Vector3(-3.08, 0.77, 11.28))
	var floorplan := _prop(furniture, "V09_Floorplan", Vector3(-2.68, 0.755, 11.18))
	_box_part(floorplan, "Paper", Vector3.ZERO, Vector3(0.44, 0.018, 0.32), materials.paper)
	floorplan.rotation_degrees.y = -12

	_make_bench(furniture, "WaitingBench", Vector3(2.8, 0, 12.25), 2.4, 90)
	_make_umbrella_stand(furniture, "UmbrellaStand", Vector3(4.1, 0, 15.75))
	_make_coat_hooks(furniture, "CoatHooks", Vector3(4.70, 1.78, 13.6), -90)
	_make_picture(furniture, "BurnedHousePortrait", Vector3(-4.70, 1.85, 14.2), 90)
	_make_picture(furniture, "ChildrenPortrait", Vector3(-4.70, 1.65, 12.7), 90)

	_add_anchor(anchors, "V03", Vector3(0, 1.2, 16.62), "../../Furniture/V03_Chain", false)
	_add_anchor(anchors, "V08", Vector3(-3.08, 0.88, 11.28), "../../Furniture/V08_PlayerLantern", true)
	_add_anchor(anchors, "V09", Vector3(-2.68, 0.78, 11.18), "../../Furniture/V09_Floorplan", true)

	_add_omni(lighting, "VestibuleWarmLight", Vector3(0, 2.85, 13), Color("e3b06e"), 2.1, 7.5)
	_add_omni(lighting, "DoorColdLight", Vector3(0, 2.1, 16.4), Color("8ca7bf"), 1.25, 4.2)
	_make_ceiling_fixture(furniture, "VestibuleFixture", Vector3(0, 3.18, 13))
	return root

func _create_main_hall() -> Node3D:
	var root := Node3D.new()
	root.name = "MainHallContent"
	root.set_script(MAIN_HALL_SCRIPT)
	var architecture := _branch(root, "Architecture")
	var furniture := _branch(root, "Furniture")
	var anchors := _branch(root, "InteractionAnchors")
	var lighting := _branch(root, "Lighting")
	var atmosphere := _branch(root, "Atmosphere")

	_box(architecture, "HallFloorFinish", Vector3(0, 0.025, 1.5), Vector3(15.7, 0.05, 14.7), materials.floor)
	_box(architecture, "MainHallCeiling", Vector3(0, 3.38, 1.5), Vector3(15.7, 0.08, 14.7), materials.plaster)
	_wall_with_gap(architecture, "NorthWall", 8.82, 16.0, 0.0, 1.65)
	_wall_with_gap(architecture, "SouthWall", -5.82, 16.0, 0.0, 1.65)
	_side_wall_with_gap(architecture, "WestWall", -7.82, 15.0, 2.0, 1.65)
	_side_wall_with_gap(architecture, "EastWall", 7.82, 15.0, 2.0, 1.65)
	_add_room_trim(architecture, -7.74, 7.74, -5.74, 8.74)
	_box(architecture, "CenterRunner", Vector3(0, 0.065, 1.45), Vector3(2.6, 0.025, 12.2), materials.runner)
	_add_door_frame(architecture, "VestibuleDoorFrame", Vector3(0, 1.18, 8.70), false)
	_add_door_frame(architecture, "BoilerDoorFrame", Vector3(0, 1.18, -5.70), false)
	_add_door_frame(architecture, "LibraryDoorFrame", Vector3(-7.70, 1.18, 2), true)
	_add_door_frame(architecture, "ClassroomDoorFrame", Vector3(7.70, 1.18, 2), true)

	var cradle := _make_cradle(furniture, "H01_CentralCradle", Vector3(0, 0, 1.7))
	var register_stand := _make_lectern(furniture, "RegisterLectern", Vector3(0, 0, 3.4))
	var register := _prop(furniture, "H04_HouseRegister", Vector3(0, 1.04, 3.37))
	_box_part(register, "Cover", Vector3.ZERO, Vector3(0.54, 0.07, 0.72), materials.wood)
	_box_part(register, "Pages", Vector3(0, 0.045, 0), Vector3(0.48, 0.055, 0.66), materials.paper)
	_box_part(register, "Spine", Vector3(-0.25, 0.055, 0), Vector3(0.055, 0.085, 0.7), materials.brass)

	_make_console(furniture, "WestConsole", Vector3(-6.25, 0, 7.05), 90)
	_make_console(furniture, "EastConsole", Vector3(6.25, 0, 7.05), 90)
	_make_bench(furniture, "WestBench", Vector3(-5.7, 0, -4.65), 2.6, 0)
	_make_bench(furniture, "EastBench", Vector3(5.7, 0, -4.65), 2.6, 0)
	_make_bench(furniture, "WestWaitingBench", Vector3(-7.1, 0, 4.6), 2.2, 90)
	_make_bench(furniture, "EastWaitingBench", Vector3(7.1, 0, 4.6), 2.2, 90)

	var dolls := _branch(furniture, "Dolls")
	_make_doll(dolls, "Mira", Vector3(-6.8, 0, 5.45), "mira")
	_make_doll(dolls, "Leela", Vector3(-6.8, 0, 1.75), "leela")
	_make_doll(dolls, "Arun", Vector3(-6.8, 0, -2.0), "arun")
	_make_doll(dolls, "Dev", Vector3(6.8, 0, 5.45), "dev")
	_make_doll(dolls, "Sana", Vector3(6.8, 0, 1.75), "sana")
	_make_doll(dolls, "Kabir", Vector3(6.8, 0, -2.0), "kabir")
	_make_doll(dolls, "Nila", Vector3(0, 0, -5.25), "nila")

	var alarm := _prop(furniture, "H09_AlarmBell", Vector3(-7.64, 2.2, 7.2))
	_cylinder_part(alarm, "Bell", Vector3.ZERO, 0.23, 0.22, materials.red, Vector3(0, 0, 90))
	_cylinder_part(alarm, "Clapper", Vector3(0.0, -0.16, 0), 0.045, 0.25, materials.iron)
	var battery := _prop(furniture, "H10_BatteryBox", Vector3(-7.64, 1.65, 6.65))
	_box_part(battery, "Box", Vector3.ZERO, Vector3(0.12, 0.48, 0.6), materials.iron)
	_box_part(battery, "OpenDoor", Vector3(0.13, 0, -0.22), Vector3(0.04, 0.42, 0.48), materials.iron)
	battery.get_node("OpenDoor").rotation_degrees.y = -35

	for i in range(6):
		var z := 6.9 - i * 2.3
		_make_picture(furniture, "WestMemorial_%02d" % i, Vector3(-7.69, 1.75, z), 90)
		_make_picture(furniture, "EastMemorial_%02d" % i, Vector3(7.69, 1.75, z), -90)
	_make_chandelier(furniture, "HallChandelier", Vector3(0, 2.85, 1.4))
	_make_ceiling_fixture(furniture, "NorthFixture", Vector3(0, 3.18, 6.5))
	_make_ceiling_fixture(furniture, "SouthFixture", Vector3(0, 3.18, -3.5))
	_make_wall_sconce(furniture, "WestSconce", Vector3(-7.67, 2.05, 1.35), 90)
	_make_wall_sconce(furniture, "EastSconce", Vector3(7.67, 2.05, 1.35), -90)

	for i in range(12):
		var z := -4.8 + i * 1.18
		var stain := _prop(atmosphere, "SootStain_%02d" % i, Vector3(-7.735 if i % 2 == 0 else 7.735, 2.5 - (i % 3) * 0.25, z))
		_box_part(stain, "Stain", Vector3.ZERO, Vector3(0.016, 0.35 + (i % 2) * 0.18, 0.45), materials.soot)

	_add_anchor(anchors, "H01", Vector3(0, 0.95, 1.7), "../../Furniture/H01_CentralCradle", false)
	_add_anchor(anchors, "H04", Vector3(0, 1.08, 3.37), "../../Furniture/H04_HouseRegister", true)
	_add_anchor(anchors, "H09", Vector3(-7.58, 2.2, 7.2), "../../Furniture/H09_AlarmBell", false)
	_add_anchor(anchors, "H10", Vector3(-7.58, 1.65, 6.65), "../../Furniture/H10_BatteryBox", false)
	_add_anchor(anchors, "mira", Vector3(-6.8, 0.72, 5.45), "../../Furniture/Dolls/Mira", false)
	_add_anchor(anchors, "leela", Vector3(-6.8, 0.72, 1.75), "../../Furniture/Dolls/Leela", false)
	_add_anchor(anchors, "arun", Vector3(-6.8, 0.72, -2.0), "../../Furniture/Dolls/Arun", false)
	_add_anchor(anchors, "dev", Vector3(6.8, 0.72, 5.45), "../../Furniture/Dolls/Dev", false)
	_add_anchor(anchors, "sana", Vector3(6.8, 0.72, 1.75), "../../Furniture/Dolls/Sana", false)
	_add_anchor(anchors, "kabir", Vector3(6.8, 0.72, -2.0), "../../Furniture/Dolls/Kabir", false)
	_add_anchor(anchors, "nila", Vector3(0, 0.72, -5.25), "../../Furniture/Dolls/Nila", false)

	_add_omni(lighting, "HallWarmLight", Vector3(0, 2.65, 1.4), Color("e0a45b"), 3.20, 10.5)
	_add_omni(lighting, "NorthPool", Vector3(0, 2.55, 6.5), Color("c79762"), 1.85, 6.5)
	_add_omni(lighting, "SouthPool", Vector3(0, 2.55, -3.6), Color("9aa9b6"), 1.45, 6.0)
	_add_omni(lighting, "WestSconcePool", Vector3(-6.6, 1.95, 1.35), Color("d49a5c"), 1.15, 5.2)
	_add_omni(lighting, "EastSconcePool", Vector3(6.6, 1.95, 1.35), Color("d49a5c"), 1.15, 5.2)
	_add_smoke(atmosphere)
	return root

func _branch(parent: Node, name: String) -> Node3D:
	var node := Node3D.new()
	node.name = name
	parent.add_child(node)
	return node

func _prop(parent: Node, name: String, position: Vector3) -> Node3D:
	var node := Node3D.new()
	node.name = name
	node.position = position
	parent.add_child(node)
	return node

func _box(parent: Node, name: String, position: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = name
	mesh_instance.position = position
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	mesh_instance.mesh = mesh
	parent.add_child(mesh_instance)
	return mesh_instance

func _box_part(parent: Node, name: String, position: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	return _box(parent, name, position, size, material)

func _cylinder_part(parent: Node, name: String, position: Vector3, radius: float, height: float, material: Material, rotation := Vector3.ZERO) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = name
	mesh_instance.position = position
	mesh_instance.rotation_degrees = rotation
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 10
	mesh.material = material
	mesh_instance.mesh = mesh
	parent.add_child(mesh_instance)
	return mesh_instance

func _sphere_part(parent: Node, name: String, position: Vector3, radius: float, material: Material, scale := Vector3.ONE) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = name
	mesh_instance.position = position
	mesh_instance.scale = scale
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 12
	mesh.rings = 6
	mesh.material = material
	mesh_instance.mesh = mesh
	parent.add_child(mesh_instance)
	return mesh_instance

func _make_doll(parent: Node, name: String, position: Vector3, variant: String) -> Node3D:
	var doll := _prop(parent, name, position)
	doll.set_meta("doll_variant", StringName(variant))
	var palette: Material = {
		"mira": materials.doll_red,
		"leela": materials.doll_violet,
		"arun": materials.doll_blue,
		"dev": materials.doll_amber,
		"sana": materials.doll_teal,
		"kabir": materials.doll_green,
		"nila": materials.doll_cloth,
	}.get(variant, materials.doll_cloth)
	var body := _branch(doll, "HandmadeBody")
	_cylinder_part(body, "Torso", Vector3(0, 0.47, 0), 0.15, 0.34, palette)
	_sphere_part(body, "Head", Vector3(0, 0.78, 0), 0.17, materials.doll_skin, Vector3(0.92, 1.04, 0.88))
	_box_part(body, "DressHem", Vector3(0, 0.29, 0), Vector3(0.38, 0.20, 0.26), palette)
	_box_part(body, "LeftEye", Vector3(-0.055, 0.81, -0.145), Vector3(0.028, 0.035, 0.018), materials.doll_dark)
	_box_part(body, "RightEye", Vector3(0.055, 0.81, -0.145), Vector3(0.028, 0.035, 0.018), materials.doll_dark)
	var left_arm := _cylinder_part(body, "LeftArm", Vector3(-0.20, 0.51, 0), 0.045, 0.38, materials.doll_skin, Vector3(0, 0, -20))
	var right_arm := _cylinder_part(body, "RightArm", Vector3(0.20, 0.51, 0), 0.045, 0.38, materials.doll_skin, Vector3(0, 0, 20))
	var left_leg := _cylinder_part(body, "LeftLeg", Vector3(-0.09, 0.13, 0), 0.052, 0.28, materials.doll_skin)
	var right_leg := _cylinder_part(body, "RightLeg", Vector3(0.09, 0.13, 0), 0.052, 0.28, materials.doll_skin)
	_box_part(body, "RightShoe", Vector3(0.09, 0.025, -0.045), Vector3(0.12, 0.07, 0.19), materials.doll_dark)
	if variant != "leela":
		_box_part(body, "LeftShoe", Vector3(-0.09, 0.025, -0.045), Vector3(0.12, 0.07, 0.19), materials.doll_dark)
	match variant:
		"mira":
			left_arm.rotation_degrees = Vector3(72, 0, -38)
			right_arm.rotation_degrees = Vector3(58, 0, 32)
			_box_part(body, "RedRibbonTailLeft", Vector3(-0.11, 0.92, 0), Vector3(0.05, 0.18, 0.035), materials.doll_red).rotation_degrees.z = 32
			_box_part(body, "RedRibbonTailRight", Vector3(0.0, 0.92, 0), Vector3(0.05, 0.18, 0.035), materials.doll_red).rotation_degrees.z = -32
			_box_part(body, "FaceCrack", Vector3(0.045, 0.77, -0.161), Vector3(0.018, 0.16, 0.012), materials.doll_dark).rotation_degrees.z = 24
		"leela":
			doll.rotation_degrees.z = 4
			left_arm.rotation_degrees = Vector3(78, 0, -62)
			right_arm.rotation_degrees = Vector3(70, 0, 58)
			left_leg.rotation_degrees.x = 72
			right_leg.rotation_degrees.x = 72
		"arun":
			body.rotation_degrees.x = -5
			var star := _box_part(body, "BrassStar", Vector3(0.075, 0.55, -0.145), Vector3(0.09, 0.09, 0.025), materials.brass)
			star.rotation_degrees.z = 45
		"dev":
			left_leg.rotation_degrees.x = 68
			right_leg.rotation_degrees.x = 32
			_sphere_part(body, "SootLeftHand", Vector3(-0.25, 0.35, 0), 0.06, materials.doll_dark)
			_sphere_part(body, "SootRightHand", Vector3(0.25, 0.35, 0), 0.06, materials.doll_dark)
			var wheel := _torus_part(body, "TrainWheel", Vector3(0.25, 0.33, -0.08), materials.iron)
			wheel.scale = Vector3(1.6, 1.6, 1.6)
			wheel.rotation_degrees.x = 90
		"sana":
			left_arm.rotation_degrees = Vector3(68, 0, -32)
			right_arm.rotation_degrees = Vector3(68, 0, 32)
			_box_part(body, "FoldedCloth", Vector3(0, 0.30, -0.21), Vector3(0.34, 0.055, 0.24), materials.fabric)
			_cylinder_part(body, "WhistleCord", Vector3(0, 0.61, -0.15), 0.012, 0.28, materials.brass)
		"kabir":
			body.position.y = -0.10
			left_leg.rotation_degrees.x = 55
			right_leg.rotation_degrees.x = 55
			_sphere_part(body, "BlueMarble", Vector3(0.25, 0.34, -0.08), 0.055, materials.doll_blue)
			_box_part(body, "LeftKneeScrape", Vector3(-0.09, 0.13, -0.052), Vector3(0.07, 0.08, 0.015), materials.doll_dark)
		"nila":
			right_arm.rotation_degrees = Vector3(74, 0, 26)
			_box_part(body, "BlankTag", Vector3(-0.15, 0.52, -0.16), Vector3(0.15, 0.11, 0.02), materials.paper)
			for bead_index in range(7):
				_sphere_part(body, "CountingBead_%d" % bead_index, Vector3(-0.18 + bead_index * 0.06, 0.25, -0.18), 0.026, materials.brass)
	return doll

func _torus_part(parent: Node, name: String, position: Vector3, material: Material) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = name
	mesh_instance.position = position
	var mesh := TorusMesh.new()
	mesh.inner_radius = 0.025
	mesh.outer_radius = 0.065
	mesh.rings = 8
	mesh.ring_segments = 6
	mesh.material = material
	mesh_instance.mesh = mesh
	parent.add_child(mesh_instance)
	return mesh_instance

func _wall_with_gap(parent: Node, prefix: String, z: float, width: float, gap_center: float, gap_width: float) -> void:
	var side := (width - gap_width) * 0.5
	_box(parent, prefix + "West", Vector3(-width * 0.5 + side * 0.5, 1.42, z), Vector3(side, 2.65, 0.08), materials.panel)
	_box(parent, prefix + "East", Vector3(width * 0.5 - side * 0.5, 1.42, z), Vector3(side, 2.65, 0.08), materials.panel)

func _side_wall_with_gap(parent: Node, prefix: String, x: float, length: float, gap_center: float, gap_width: float) -> void:
	var south_length := gap_center - gap_width * 0.5 - (-6.0)
	var north_length := 9.0 - (gap_center + gap_width * 0.5)
	_box(parent, prefix + "South", Vector3(x, 1.42, -6.0 + south_length * 0.5), Vector3(0.08, 2.65, south_length), materials.panel)
	_box(parent, prefix + "North", Vector3(x, 1.42, gap_center + gap_width * 0.5 + north_length * 0.5), Vector3(0.08, 2.65, north_length), materials.panel)

func _add_room_trim(parent: Node, x_min: float, x_max: float, z_min: float, z_max: float) -> void:
	for y in [0.16, 1.08, 2.70]:
		_box(parent, "WestTrim_%s" % str(y), Vector3(x_min, y, (z_min + z_max) * 0.5), Vector3(0.10, 0.10, z_max - z_min), materials.trim)
		_box(parent, "EastTrim_%s" % str(y), Vector3(x_max, y, (z_min + z_max) * 0.5), Vector3(0.10, 0.10, z_max - z_min), materials.trim)
		_box(parent, "NorthTrim_%s" % str(y), Vector3(0, y, z_max), Vector3(x_max - x_min, 0.10, 0.10), materials.trim)
		_box(parent, "SouthTrim_%s" % str(y), Vector3(0, y, z_min), Vector3(x_max - x_min, 0.10, 0.10), materials.trim)

func _add_door_frame(parent: Node, name: String, position: Vector3, side: bool) -> void:
	var frame := _prop(parent, name, position)
	if side:
		frame.rotation_degrees.y = 90
	_box_part(frame, "Left", Vector3(-0.86, 0, 0), Vector3(0.16, 2.36, 0.22), materials.trim)
	_box_part(frame, "Right", Vector3(0.86, 0, 0), Vector3(0.16, 2.36, 0.22), materials.trim)
	_box_part(frame, "Lintel", Vector3(0, 1.12, 0), Vector3(1.88, 0.18, 0.22), materials.trim)

func _make_table(parent: Node, name: String, position: Vector3, size: Vector3) -> Node3D:
	var table := _prop(parent, name, position)
	_box_part(table, "Top", Vector3(0, size.y, 0), Vector3(size.x, 0.12, size.z), materials.wood_light)
	for x in [-size.x * 0.42, size.x * 0.42]:
		for z in [-size.z * 0.38, size.z * 0.38]:
			_box_part(table, "Leg_%s_%s" % [str(x), str(z)], Vector3(x, size.y * 0.5, z), Vector3(0.10, size.y, 0.10), materials.wood)
	return table

func _make_bench(parent: Node, name: String, position: Vector3, length: float, yaw: float) -> Node3D:
	var bench := _prop(parent, name, position)
	bench.rotation_degrees.y = yaw
	_box_part(bench, "Seat", Vector3(0, 0.48, 0), Vector3(length, 0.16, 0.52), materials.wood_light)
	_box_part(bench, "Back", Vector3(0, 0.86, 0.22), Vector3(length, 0.66, 0.12), materials.wood)
	for x in [-length * 0.40, length * 0.40]:
		_box_part(bench, "Leg_%s" % str(x), Vector3(x, 0.25, 0), Vector3(0.12, 0.50, 0.42), materials.wood)
	return bench

func _make_console(parent: Node, name: String, position: Vector3, yaw: float) -> Node3D:
	var console := _make_table(parent, name, position, Vector3(1.4, 0.76, 0.42))
	console.rotation_degrees.y = yaw
	_box_part(console, "Drawer", Vector3(0, 0.64, 0), Vector3(1.16, 0.24, 0.36), materials.wood)
	for x in [-0.28, 0.28]:
		_cylinder_part(console, "Pull_%s" % str(x), Vector3(x, 0.64, -0.21), 0.035, 0.06, materials.brass, Vector3(90, 0, 0))
	return console

func _make_lantern(parent: Node, name: String, position: Vector3) -> Node3D:
	var lantern := _prop(parent, name, position)
	_cylinder_part(lantern, "Base", Vector3(0, 0.04, 0), 0.14, 0.08, materials.brass)
	_cylinder_part(lantern, "Glass", Vector3(0, 0.22, 0), 0.11, 0.30, materials.glass)
	_cylinder_part(lantern, "Cap", Vector3(0, 0.40, 0), 0.12, 0.07, materials.brass)
	var handle := _torus_part(lantern, "Handle", Vector3(0, 0.48, 0), materials.brass)
	handle.scale = Vector3(2.3, 2.3, 2.3)
	handle.rotation_degrees.x = 90
	return lantern

func _make_umbrella_stand(parent: Node, name: String, position: Vector3) -> void:
	var stand := _prop(parent, name, position)
	_cylinder_part(stand, "Stand", Vector3(0, 0.28, 0), 0.24, 0.56, materials.iron)
	for i in range(3):
		var shaft := _box_part(stand, "Umbrella_%d" % i, Vector3(-0.10 + i * 0.10, 0.72, 0), Vector3(0.035, 0.92, 0.035), materials.wood)
		shaft.rotation_degrees.z = -8 + i * 8

func _make_coat_hooks(parent: Node, name: String, position: Vector3, yaw: float) -> void:
	var hooks := _prop(parent, name, position)
	hooks.rotation_degrees.y = yaw
	_box_part(hooks, "Rail", Vector3.ZERO, Vector3(1.5, 0.12, 0.10), materials.wood)
	for i in range(5):
		_cylinder_part(hooks, "Hook_%d" % i, Vector3(-0.60 + i * 0.30, -0.10, -0.08), 0.025, 0.22, materials.brass, Vector3(90, 0, 0))

func _make_picture(parent: Node, name: String, position: Vector3, yaw: float) -> void:
	var picture := _prop(parent, name, position)
	picture.rotation_degrees.y = yaw
	_box_part(picture, "Frame", Vector3.ZERO, Vector3(0.72, 0.58, 0.07), materials.trim)
	_box_part(picture, "Image", Vector3(0, 0, -0.045), Vector3(0.58, 0.44, 0.025), materials.paper)
	_box_part(picture, "Soot", Vector3(0.12, 0.04, -0.065), Vector3(0.22, 0.32, 0.012), materials.soot)

func _make_cradle(parent: Node, name: String, position: Vector3) -> Node3D:
	var cradle := _prop(parent, name, position)
	_box_part(cradle, "Base", Vector3(0, 0.22, 0), Vector3(1.55, 0.16, 0.82), materials.wood)
	_box_part(cradle, "Mattress", Vector3(0, 0.42, 0), Vector3(1.30, 0.20, 0.62), materials.fabric)
	for x in [-0.72, 0.72]:
		_box_part(cradle, "End_%s" % str(x), Vector3(x, 0.67, 0), Vector3(0.12, 0.88, 0.82), materials.wood_light)
		for z in [-0.30, -0.10, 0.10, 0.30]:
			_box_part(cradle, "Rail_%s_%s" % [str(x), str(z)], Vector3(x, 0.70, z), Vector3(0.10, 0.60, 0.055), materials.wood)
	for x in [-0.72, 0.72]:
		var rocker := _torus_part(cradle, "Rocker_%s" % str(x), Vector3(x, 0.10, 0), materials.wood)
		rocker.scale = Vector3(4.8, 1.0, 5.8)
		rocker.rotation_degrees = Vector3(90, 0, 0)
	return cradle

func _make_lectern(parent: Node, name: String, position: Vector3) -> Node3D:
	var lectern := _prop(parent, name, position)
	_box_part(lectern, "Foot", Vector3(0, 0.08, 0), Vector3(0.72, 0.16, 0.72), materials.wood)
	_box_part(lectern, "Post", Vector3(0, 0.52, 0), Vector3(0.20, 0.90, 0.20), materials.wood)
	var top := _box_part(lectern, "Top", Vector3(0, 0.98, 0), Vector3(0.88, 0.12, 0.86), materials.wood_light)
	top.rotation_degrees.x = -8
	return lectern

func _make_ceiling_fixture(parent: Node, name: String, position: Vector3) -> void:
	var fixture := _prop(parent, name, position)
	_cylinder_part(fixture, "Canopy", Vector3.ZERO, 0.22, 0.10, materials.brass)
	_cylinder_part(fixture, "Stem", Vector3(0, -0.18, 0), 0.035, 0.35, materials.brass)
	_cylinder_part(fixture, "Shade", Vector3(0, -0.42, 0), 0.28, 0.22, materials.glass)

func _make_wall_sconce(parent: Node, name: String, position: Vector3, yaw: float) -> void:
	var sconce := _prop(parent, name, position)
	sconce.rotation_degrees.y = yaw
	_cylinder_part(sconce, "Backplate", Vector3.ZERO, 0.16, 0.06, materials.brass, Vector3(90, 0, 0))
	_box_part(sconce, "Arm", Vector3(0, -0.08, -0.16), Vector3(0.05, 0.05, 0.32), materials.brass)
	_cylinder_part(sconce, "Shade", Vector3(0, -0.10, -0.34), 0.16, 0.22, materials.glass)

func _make_chandelier(parent: Node, name: String, position: Vector3) -> void:
	var chandelier := _prop(parent, name, position)
	_cylinder_part(chandelier, "Stem", Vector3(0, 0.18, 0), 0.035, 0.65, materials.brass)
	_cylinder_part(chandelier, "Hub", Vector3(0, -0.18, 0), 0.16, 0.16, materials.brass)
	for i in range(6):
		var angle := TAU * i / 6.0
		var arm_position := Vector3(cos(angle) * 0.52, -0.18, sin(angle) * 0.52)
		var arm := _box_part(chandelier, "Arm_%d" % i, arm_position * 0.5, Vector3(0.58, 0.045, 0.045), materials.brass)
		arm.rotation_degrees.y = -rad_to_deg(angle)
		_cylinder_part(chandelier, "Lamp_%d" % i, arm_position + Vector3(0, -0.12, 0), 0.12, 0.22, materials.glass)

func _add_anchor(parent: Node, id: String, position: Vector3, visual_path: String, hide_on_collect: bool) -> void:
	var anchor := Marker3D.new()
	anchor.name = id + "Anchor"
	anchor.position = position
	anchor.add_to_group("ashdown_interaction_anchor", true)
	anchor.set_meta("interaction_id", StringName(id))
	anchor.set_meta("visual_path", NodePath(visual_path))
	anchor.set_meta("hide_visual_on_collect", hide_on_collect)
	anchor.set_meta("hide_visual_when_unavailable", false)
	parent.add_child(anchor)

func _add_omni(parent: Node, name: String, position: Vector3, color: Color, energy: float, range_value: float) -> OmniLight3D:
	var light := OmniLight3D.new()
	light.name = name
	light.position = position
	light.light_color = color
	light.light_energy = energy
	light.omni_range = range_value
	light.shadow_enabled = true
	light.shadow_bias = 0.08
	parent.add_child(light)
	return light

func _add_smoke(parent: Node) -> void:
	var particles := GPUParticles3D.new()
	particles.name = "SmokeParticles"
	particles.position = Vector3(0, 0.20, -4.8)
	particles.amount = 54
	particles.lifetime = 8.0
	particles.visibility_aabb = AABB(Vector3(-8, -0.5, -3), Vector3(16, 4, 12))
	particles.emitting = false
	particles.visible = false
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(6.8, 0.12, 0.7)
	process.direction = Vector3(0, 1, 0)
	process.spread = 22.0
	process.initial_velocity_min = 0.12
	process.initial_velocity_max = 0.38
	process.gravity = Vector3(0, 0.07, 0)
	process.scale_min = 1.4
	process.scale_max = 3.6
	process.color = Color(0.13, 0.13, 0.14, 0.28)
	particles.process_material = process
	var quad := QuadMesh.new()
	quad.size = Vector2(1.2, 1.2)
	quad.orientation = PlaneMesh.FACE_Z
	var smoke_material := StandardMaterial3D.new()
	smoke_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smoke_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smoke_material.albedo_color = Color(0.18, 0.18, 0.20, 0.18)
	smoke_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	smoke_material.vertex_color_use_as_albedo = true
	quad.material = smoke_material
	particles.draw_pass_1 = quad
	parent.add_child(particles)
	var glow := _add_omni(parent, "FireGlow", Vector3(0, 0.55, -5.2), Color("d64f19"), 3.2, 8.5)
	glow.visible = false

func _save_scene(root: Node, path: String) -> void:
	_set_owner_recursive(root, root)
	var packed := PackedScene.new()
	var pack_result := packed.pack(root)
	if pack_result != OK:
		push_error("Could not pack %s: %s" % [path, error_string(pack_result)])
		quit(1)
		return
	var save_result := ResourceSaver.save(packed, path)
	if save_result != OK:
		push_error("Could not save %s: %s" % [path, error_string(save_result)])
		quit(1)

func _set_owner_recursive(node: Node, scene_root: Node) -> void:
	for child in node.get_children():
		child.owner = scene_root
		_set_owner_recursive(child, scene_root)
