@tool
extends SceneTree

const BATH_OUTPUT := "res://scenes/levels/ashdown/rooms/BathroomLaundryContent.tscn"
const KITCHEN_OUTPUT := "res://scenes/levels/ashdown/rooms/KitchenContent.tscn"
const BATH_CONTROLLER := preload("res://scripts/level/bathroom_laundry_content.gd")
const KITCHEN_CONTROLLER := preload("res://scripts/level/kitchen_content.gd")
const INTERACTABLE := preload("res://scripts/interaction/interactable_3d.gd")

var mats: Dictionary = {}

func _initialize() -> void: call_deferred("_build")

func _build() -> void:
	_materials()
	var bath := _bathroom_scene()
	var kitchen := _kitchen_scene()
	var result := _save(bath, BATH_OUTPUT)
	if result == OK: result = _save(kitchen, KITCHEN_OUTPUT)
	print("WET_SERVICE_ROOMS_BUILT: %s" % error_string(result))
	bath.free(); kitchen.free(); quit(0 if result == OK else 1)

func _materials() -> void:
	mats = {
		"plaster": _mat("ServicePlaster", Color("48504e"), 0.96),
		"tile": _mat("CrackedTile", Color("697572"), 0.72),
		"tile_dark": _mat("TileGrout", Color("303938"), 0.92),
		"floor": _mat("WetTileFloor", Color("354441"), 0.42),
		"wood": _mat("ServiceWood", Color("5b3d2b"), 0.88),
		"wood_dark": _mat("PantryWood", Color("332219"), 0.90),
		"metal": _mat("ServiceMetal", Color("343c3d"), 0.52, 0.48),
		"iron": _mat("BlackIron", Color("202526"), 0.64, 0.58),
		"porcelain": _mat("OldPorcelain", Color("b6b7aa"), 0.48),
		"mirror": _mat("FoggedMirror", Color("66777a"), 0.20, 0.18),
		"paper": _mat("DampPaper", Color("b8a273"), 0.98),
		"cloth": _mat("WetCloth", Color("526b65"), 0.68),
		"cloth_sana": _mat("SanaCloth", Color("477064"), 0.72),
		"shoe": _mat("LeelaShoe", Color("673f38"), 0.92),
		"brass": _mat("TarnishedBrass", Color("80633a"), 0.55, 0.30),
		"red": _mat("BurnedRed", Color("7a2924"), 0.86),
		"food": _mat("PantryTin", Color("69634c"), 0.80, 0.12),
		"chalk": _emit("MirrorWriting", Color("c9d3c9"), 0.60),
		"soot": _mat("Soot", Color("131110"), 1.0),
	}

func _mat(name: String, color: Color, roughness: float, metallic := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new(); m.resource_name = name; m.albedo_color = color; m.roughness = roughness; m.metallic = metallic; return m

func _emit(name: String, color: Color, energy: float) -> StandardMaterial3D:
	var m := _mat(name, color, 1.0); m.emission_enabled = true; m.emission = color; m.emission_energy_multiplier = energy; return m

func _bathroom_scene() -> Node3D:
	var root := Node3D.new(); root.name = "BathroomLaundryContent"; root.set_script(BATH_CONTROLLER)
	var architecture := _branch(root, "Architecture"); var furniture := _branch(root, "Furniture")
	var anchors := _branch(root, "InteractionAnchors"); var areas := _branch(root, "Interactables")
	var lighting := _branch(root, "Lighting"); var atmosphere := _branch(root, "Atmosphere")
	_bath_architecture(architecture); _bath_furniture(furniture); _bath_interactions(anchors, areas); _bath_lighting(lighting); _bath_atmosphere(atmosphere)
	return root

func _bath_architecture(parent: Node3D) -> void:
	_box(parent, "FloorFinish", Vector3(13, 0.03, -11.5), Vector3(7.7, 0.06, 10.7), mats.floor)
	_box(parent, "Ceiling", Vector3(13, 3.38, -11.5), Vector3(7.7, 0.08, 10.7), mats.plaster)
	_box(parent, "WestWall", Vector3(9.18, 1.42, -14.25), Vector3(0.08, 2.65, 4.2), mats.tile)
	_box(parent, "WestNorth", Vector3(9.18, 1.42, -8.75), Vector3(0.08, 2.65, 4.2), mats.tile)
	_box(parent, "EastWall", Vector3(16.82, 1.42, -8.75), Vector3(0.08, 2.65, 4.2), mats.tile)
	_box(parent, "EastSouth", Vector3(16.82, 1.42, -14.25), Vector3(0.08, 2.65, 4.2), mats.tile)
	_box(parent, "SouthWall", Vector3(13, 1.42, -16.82), Vector3(7.7, 2.65, 0.08), mats.tile)
	_box(parent, "NorthWest", Vector3(10.45, 1.42, -6.18), Vector3(2.3, 2.65, 0.08), mats.tile)
	_box(parent, "NorthEast", Vector3(15.55, 1.42, -6.18), Vector3(2.3, 2.65, 0.08), mats.tile)
	for z in [-15.5, -13.0, -10.5, -8.0]:
		_box(parent, "TileBand_%s" % str(z), Vector3(13, 1.05, z), Vector3(7.5, 0.08, 0.06), mats.tile_dark)
	_door_frame(parent, "ClassroomDoor", Vector3(13, 1.18, -6.30), false)
	_door_frame(parent, "BoilerDoor", Vector3(9.30, 1.18, -11.5), true)
	_door_frame(parent, "KitchenDoor", Vector3(16.70, 1.18, -11.5), true)

func _bath_furniture(parent: Node3D) -> void:
	_make_sink(parent, "SinkA", Vector3(9.55, 0, -8.2), 90)
	_make_sink(parent, "SinkB", Vector3(9.55, 0, -10.2), 90)
	_make_mirror(parent)
	_make_stall(parent, "StallA", Vector3(10.8, 0, -15.5))
	_make_stall(parent, "StallB", Vector3(13.0, 0, -15.5))
	_make_tub(parent)
	_make_drain(parent)
	_make_drain_lever(parent)
	_make_towel_cabinet(parent)
	_make_wringer(parent)
	_make_baskets(parent)
	_make_bath_clues(parent)
	for z in [-8.5, -13.5]: _make_service_lamp(parent, "Lamp_%s" % str(z), Vector3(13, 3.16, z))

func _make_sink(parent: Node, name: String, pos: Vector3, yaw: float) -> void:
	var sink := _prop(parent, name, pos); sink.rotation_degrees.y = yaw
	_box(sink, "Pedestal", Vector3(0, 0.42, 0), Vector3(0.42, 0.84, 0.40), mats.porcelain)
	_box(sink, "Basin", Vector3(0, 0.88, 0), Vector3(0.92, 0.20, 0.58), mats.porcelain)
	_cylinder(sink, "Tap", Vector3(0, 1.08, 0.14), 0.055, 0.34, mats.brass)

func _make_mirror(parent: Node) -> void:
	var mirror := _prop(parent, "B03_SteamedMirror", Vector3(9.25, 1.62, -9.2)); mirror.rotation_degrees.y = 90
	_box(mirror, "Frame", Vector3.ZERO, Vector3(0.10, 1.75, 2.45), mats.metal)
	_box(mirror, "Glass", Vector3(-0.07, 0, 0), Vector3(0.025, 1.52, 2.20), mats.mirror)
	var msg := _prop(mirror, "Message", Vector3(-0.10, 0, 0)); msg.visible = false
	for i in range(7):
		var circle := _torus(msg, "Circle_%d" % i, Vector3(0, 0.42 - (i % 2) * 0.48, -0.82 + i * 0.27), 0.018, 0.06 + (i % 3) * 0.025, mats.chalk); circle.rotation_degrees.z = 90
	_box(msg, "CountLine", Vector3(0, -0.48, 0), Vector3(0.02, 0.06, 1.25), mats.chalk)

func _make_stall(parent: Node, name: String, pos: Vector3) -> void:
	var stall := _prop(parent, name, pos)
	_box(stall, "Left", Vector3(-0.9, 1.0, 0), Vector3(0.08, 2.0, 2.5), mats.metal)
	_box(stall, "Right", Vector3(0.9, 1.0, 0), Vector3(0.08, 2.0, 2.5), mats.metal)
	_box(stall, "Door", Vector3(0, 1.0, -1.18), Vector3(1.68, 2.0, 0.08), mats.metal)
	_cylinder(stall, "Bowl", Vector3(0, 0.38, 0.35), 0.34, 0.48, mats.porcelain)

func _make_tub(parent: Node) -> void:
	var tub := _prop(parent, "BathTub", Vector3(15.9, 0, -14.8)); tub.rotation_degrees.y = 90
	_box(tub, "Body", Vector3(0, 0.42, 0), Vector3(2.25, 0.78, 0.95), mats.porcelain)
	_box(tub, "Water", Vector3(0, 0.77, 0), Vector3(1.85, 0.05, 0.62), mats.mirror)
	_cylinder(tub, "Tap", Vector3(-0.82, 0.95, 0), 0.06, 0.42, mats.brass)

func _make_drain(parent: Node) -> void:
	var drain := _prop(parent, "B07_FloorDrain", Vector3(13.8, 0.07, -10.8))
	_cylinder(drain, "Rim", Vector3.ZERO, 0.34, 0.06, mats.iron)
	for i in range(6): _box(drain, "Bar_%d" % i, Vector3(-0.24 + i * 0.095, 0.05, 0), Vector3(0.035, 0.03, 0.54), mats.metal)

func _make_drain_lever(parent: Node) -> void:
	var root := _prop(parent, "B08_DrainLever", Vector3(16.68, 1.05, -10.8)); root.rotation_degrees.y = -90
	_box(root, "Plate", Vector3.ZERO, Vector3(0.42, 0.52, 0.10), mats.metal)
	var handle := _prop(root, "Handle", Vector3(0, 0, -0.14))
	_cylinder(handle, "Rod", Vector3(0, -0.16, 0), 0.035, 0.52, mats.brass)
	_cylinder(handle, "Grip", Vector3(0, -0.42, 0), 0.08, 0.22, mats.wood)

func _make_towel_cabinet(parent: Node) -> void:
	var cabinet := _prop(parent, "B10_TowelCabinet", Vector3(16.55, 0, -7.3)); cabinet.rotation_degrees.y = -90
	_box(cabinet, "Body", Vector3(0, 1.0, 0), Vector3(1.35, 2.0, 0.60), mats.wood)
	var door := _prop(cabinet, "Door", Vector3(-0.62, 1.0, -0.34))
	_box(door, "Panel", Vector3(0.62, 0, 0), Vector3(1.24, 1.86, 0.08), mats.wood_dark)
	_cylinder(door, "Knob", Vector3(1.10, 0, -0.08), 0.04, 0.07, mats.brass, Vector3(90, 0, 0))

func _make_wringer(parent: Node) -> void:
	var wringer := _prop(parent, "B12_Wringer", Vector3(15.8, 0, -12.0)); wringer.rotation_degrees.y = -90
	_box(wringer, "Stand", Vector3(0, 0.45, 0), Vector3(1.35, 0.90, 0.72), mats.wood)
	for y in [0.88, 1.10]: _cylinder(wringer, "Roll_%s" % str(y), Vector3(0, y, 0), 0.14, 1.15, mats.metal, Vector3(0, 0, 90))
	var handle := _prop(wringer, "Handle", Vector3(0.72, 0.98, 0))
	_box(handle, "Arm", Vector3(0.22, 0, 0), Vector3(0.44, 0.05, 0.05), mats.iron)
	_cylinder(handle, "Grip", Vector3(0.46, 0, 0), 0.06, 0.22, mats.wood, Vector3(0, 0, 90))

func _make_baskets(parent: Node) -> void:
	for i in range(2):
		var basket := _prop(parent, "LaundryBasket_%d" % i, Vector3(14.8 + i * 1.4, 0, -16.1))
		_box(basket, "Base", Vector3(0, 0.25, 0), Vector3(0.95, 0.50, 0.70), mats.wood)
		for x in [-0.35, 0, 0.35]: _box(basket, "Slat_%s" % str(x), Vector3(x, 0.42, -0.37), Vector3(0.10, 0.70, 0.05), mats.wood_dark)

func _make_bath_clues(parent: Node) -> void:
	var shoe := _prop(parent, "B09_LeelaShoe", Vector3(13.8, 0.12, -10.8)); _box(shoe, "Shoe", Vector3.ZERO, Vector3(0.42, 0.16, 0.22), mats.shoe)
	var cloth := _prop(parent, "B11_SanaCloth", Vector3(16.15, 1.05, -7.3)); _box(cloth, "Folded", Vector3.ZERO, Vector3(0.52, 0.16, 0.38), mats.cloth_sana)
	var slip := _prop(parent, "B14_NilaWageSlip", Vector3(15.8, 1.18, -12.0)); _box(slip, "Paper", Vector3.ZERO, Vector3(0.44, 0.02, 0.58), mats.paper)
	var wet := _prop(parent, "B17_SevenWetCloths", Vector3(11.2, 0.55, -7.15))
	for i in range(7): _box(wet, "Cloth_%d" % i, Vector3(0, i * 0.045, 0), Vector3(0.62 - i * 0.035, 0.05, 0.42), mats.cloth)

func _make_service_lamp(parent: Node, name: String, pos: Vector3) -> void:
	var lamp := _prop(parent, name, pos); _cylinder(lamp, "Canopy", Vector3.ZERO, 0.18, 0.08, mats.brass); _cylinder(lamp, "Shade", Vector3(0, -0.30, 0), 0.30, 0.22, mats.porcelain)

func _bath_interactions(anchors: Node3D, areas: Node3D) -> void:
	var existing := {
		"B03": [Vector3(9.35, 1.50, -9.2), "../../Furniture/B03_SteamedMirror", false, false],
		"B09": [Vector3(13.8, 0.22, -10.8), "../../Furniture/B09_LeelaShoe", true, true],
	}
	var authored := {
		"B07": [Vector3(13.8, 0.25, -10.8), "../../Furniture/B07_FloorDrain", false, false],
		"B08": [Vector3(16.55, 1.05, -10.8), "../../Furniture/B08_DrainLever", false, false],
		"B10": [Vector3(16.45, 1.0, -7.3), "../../Furniture/B10_TowelCabinet", false, false],
		"B11": [Vector3(16.15, 1.08, -7.3), "../../Furniture/B11_SanaCloth", true, true],
		"B12": [Vector3(15.8, 1.0, -12.0), "../../Furniture/B12_Wringer", false, false],
		"B13": [Vector3(15.45, 0.82, -12.0), "../../Furniture/B12_Wringer", false, false],
		"B14": [Vector3(15.8, 1.18, -12.0), "../../Furniture/B14_NilaWageSlip", true, true],
		"B17": [Vector3(11.2, 0.68, -7.15), "../../Furniture/B17_SevenWetCloths", false, false],
	}
	_add_interaction_set(anchors, areas, existing, authored)

func _bath_lighting(parent: Node3D) -> void:
	for i in range(2): _omni(parent, "BathPool_%d" % i, Vector3(13, 2.7, -8.5 - i * 5.0), Color("a9c0bd"), 1.7, 5.6)

func _bath_atmosphere(parent: Node3D) -> void:
	_particles(parent, "Steam", Vector3(13, 0.4, -9.5), Vector3(3.2, 0.2, 2.6), Color(0.72, 0.78, 0.78, 0.16), 34)

func _kitchen_scene() -> Node3D:
	var root := Node3D.new(); root.name = "KitchenContent"; root.set_script(KITCHEN_CONTROLLER)
	var architecture := _branch(root, "Architecture"); var furniture := _branch(root, "Furniture")
	var anchors := _branch(root, "InteractionAnchors"); var areas := _branch(root, "Interactables")
	var lighting := _branch(root, "Lighting"); var atmosphere := _branch(root, "Atmosphere")
	_kitchen_architecture(architecture); _kitchen_furniture(furniture); _kitchen_interactions(anchors, areas); _kitchen_lighting(lighting); _kitchen_atmosphere(atmosphere)
	return root

func _kitchen_architecture(parent: Node3D) -> void:
	_box(parent, "FloorFinish", Vector3(21.5, 0.03, -11.5), Vector3(6.7, 0.06, 10.7), mats.floor)
	_box(parent, "Ceiling", Vector3(21.5, 3.38, -11.5), Vector3(6.7, 0.08, 10.7), mats.plaster)
	_box(parent, "EastWall", Vector3(24.82, 1.42, -11.5), Vector3(0.08, 2.65, 10.7), mats.tile)
	_box(parent, "SouthWall", Vector3(21.5, 1.42, -16.82), Vector3(6.7, 2.65, 0.08), mats.tile)
	_box(parent, "WestNorth", Vector3(18.18, 1.42, -8.75), Vector3(0.08, 2.65, 4.2), mats.tile)
	_box(parent, "WestSouth", Vector3(18.18, 1.42, -14.25), Vector3(0.08, 2.65, 4.2), mats.tile)
	_box(parent, "NorthWest", Vector3(19.7, 1.42, -6.18), Vector3(2.8, 2.65, 0.08), mats.tile)
	_box(parent, "NorthEast", Vector3(23.8, 1.42, -6.18), Vector3(2.0, 2.65, 0.08), mats.tile)
	_door_frame(parent, "ClassroomDoor", Vector3(22, 1.18, -6.3), false); _door_frame(parent, "BathroomDoor", Vector3(18.3, 1.18, -11.5), true)

func _kitchen_furniture(parent: Node3D) -> void:
	_make_stove(parent); _make_kitchen_sink(parent); _make_prep_table(parent); _make_pantry(parent); _make_scale(parent); _make_weights(parent); _make_pantry_rewards(parent); _make_dumbwaiter(parent); _make_burned_curtain(parent)
	for z in [-8.5, -13.5]: _make_service_lamp(parent, "KitchenLamp_%s" % str(z), Vector3(21.5, 3.16, z))

func _make_stove(parent: Node) -> void:
	var stove := _prop(parent, "Stove", Vector3(24.2, 0, -8.2)); stove.rotation_degrees.y = -90
	_box(stove, "Body", Vector3(0, 0.48, 0), Vector3(1.4, 0.96, 0.75), mats.metal)
	for x in [-0.42, 0.42]: for z in [-0.20, 0.20]: _cylinder(stove, "Burner_%s_%s" % [str(x), str(z)], Vector3(x, 1.0, z), 0.18, 0.05, mats.iron)

func _make_kitchen_sink(parent: Node) -> void:
	var sink := _prop(parent, "KitchenSink", Vector3(24.2, 0, -11.2)); sink.rotation_degrees.y = -90
	_box(sink, "Cabinet", Vector3(0, 0.45, 0), Vector3(1.8, 0.90, 0.78), mats.wood_dark)
	_box(sink, "Basin", Vector3(0, 0.94, 0), Vector3(1.5, 0.18, 0.68), mats.metal)
	_cylinder(sink, "Tap", Vector3(0, 1.15, 0.22), 0.055, 0.38, mats.brass)

func _make_prep_table(parent: Node) -> void:
	var table := _prop(parent, "PrepTable", Vector3(21.5, 0, -11.2)); _box(table, "Top", Vector3(0, 0.82, 0), Vector3(3.0, 0.14, 1.25), mats.wood)
	for x in [-1.25, 1.25]: for z in [-0.45, 0.45]: _box(table, "Leg_%s_%s" % [str(x), str(z)], Vector3(x, 0.40, z), Vector3(0.12, 0.80, 0.12), mats.wood_dark)

func _make_pantry(parent: Node) -> void:
	var pantry := _prop(parent, "K04_Pantry", Vector3(19.0, 0, -15.9)); _box(pantry, "Body", Vector3(0, 1.15, 0), Vector3(1.8, 2.3, 0.75), mats.wood_dark)
	for y in [0.42, 0.92, 1.42, 1.92]: _box(pantry, "Shelf_%s" % str(y), Vector3(0, y, -0.10), Vector3(1.62, 0.08, 0.55), mats.wood)
	var left := _prop(pantry, "LeftDoor", Vector3(-0.86, 1.15, -0.42)); _box(left, "Panel", Vector3(0.43, 0, 0), Vector3(0.82, 2.18, 0.08), mats.wood)
	var right := _prop(pantry, "RightDoor", Vector3(0.86, 1.15, -0.42)); _box(right, "Panel", Vector3(-0.43, 0, 0), Vector3(0.82, 2.18, 0.08), mats.wood)
	for i in range(12): _box(pantry, "Tin_%d" % i, Vector3(-0.55 + (i % 4) * 0.36, 0.50 + (i / 4) * 0.50, -0.35), Vector3(0.24, 0.30, 0.25), mats.food)

func _make_scale(parent: Node) -> void:
	var scale := _prop(parent, "K05_Scale", Vector3(20.2, 0.90, -15.8)); _box(scale, "Base", Vector3(0, 0, 0), Vector3(0.70, 0.16, 0.48), mats.metal)
	_box(scale, "Post", Vector3(0, 0.45, 0), Vector3(0.08, 0.80, 0.08), mats.brass)
	var beam := _prop(scale, "Beam", Vector3(0, 0.82, 0)); _box(beam, "Bar", Vector3.ZERO, Vector3(1.65, 0.06, 0.06), mats.brass)
	for x in [-0.72, 0.72]: _cylinder(beam, "Pan_%s" % str(x), Vector3(x, -0.28, 0), 0.30, 0.06, mats.metal)

func _make_weights(parent: Node) -> void:
	var data := [["K06_Weight5", 21.1, 0.22], ["K07_Weight3", 21.7, 0.18], ["K08_Weight2", 22.3, 0.15], ["K09_WeightHalf", 23.9, 0.11]]
	for item in data:
		var root := _prop(parent, item[0], Vector3(item[1], 0.90, -11.2)); _cylinder(root, "Weight", Vector3.ZERO, item[2], 0.28, mats.iron); _torus(root, "Handle", Vector3(0, 0.22, 0), 0.025, item[2] * 0.65, mats.brass)
	var false_weight := _prop(parent, "K10_FalseWeight", Vector3(24.0, 0.90, -8.2)); _cylinder(false_weight, "Weight", Vector3.ZERO, 0.20, 0.28, mats.soot)

func _make_pantry_rewards(parent: Node) -> void:
	var roster := _prop(parent, "K11_DutyRoster", Vector3(19.0, 1.15, -15.8)); _box(roster, "Paper", Vector3.ZERO, Vector3(0.46, 0.02, 0.62), mats.paper)
	var wheel := _prop(parent, "K12_ValveWheel", Vector3(19.3, 0.62, -15.9)); var ring := _torus(wheel, "Rim", Vector3.ZERO, 0.055, 0.28, mats.brass); ring.rotation_degrees.x = 90
	for i in range(6): _box(wheel, "Spoke_%d" % i, Vector3.ZERO, Vector3(0.46, 0.04, 0.04), mats.brass).rotation_degrees.y = i * 30
	var crank := _prop(parent, "K13_WringerCrank", Vector3(19.65, 0.62, -15.9)); _box(crank, "Arm", Vector3(0.18, 0, 0), Vector3(0.38, 0.05, 0.05), mats.iron); _cylinder(crank, "Grip", Vector3(0.40, 0, 0), 0.06, 0.22, mats.wood, Vector3(0, 0, 90))
	var note := _prop(parent, "K15_MealNote", Vector3(21.45, 0.91, -11.05)); _box(note, "Paper", Vector3.ZERO, Vector3(0.40, 0.02, 0.52), mats.paper)

func _make_dumbwaiter(parent: Node) -> void:
	var dw := _prop(parent, "Dumbwaiter", Vector3(18.35, 0.4, -8.3)); dw.rotation_degrees.y = 90; _box(dw, "Frame", Vector3(0, 0.8, 0), Vector3(0.18, 1.6, 1.3), mats.wood_dark); _box(dw, "Door", Vector3(-0.12, 0.8, 0), Vector3(0.08, 1.42, 1.12), mats.wood)

func _make_burned_curtain(parent: Node) -> void:
	var curtain := _prop(parent, "K17_BurnedCurtain", Vector3(22, 1.1, -6.22)); _box(curtain, "Rod", Vector3(0, 1.0, 0), Vector3(2.1, 0.05, 0.05), mats.iron)
	for i in range(5): _box(curtain, "Strip_%d" % i, Vector3(-0.8 + i * 0.4, 0.25 + (i % 2) * 0.15, 0), Vector3(0.32, 1.35 - (i % 3) * 0.25, 0.04), mats.soot)

func _kitchen_interactions(anchors: Node3D, areas: Node3D) -> void:
	var existing := {
		"K11": [Vector3(19.0, 1.15, -15.8), "../../Furniture/K11_DutyRoster", true, true],
		"K12": [Vector3(19.3, 0.68, -15.9), "../../Furniture/K12_ValveWheel", true, true],
	}
	var authored := {
		"K05": [Vector3(20.2, 1.15, -15.8), "../../Furniture/K05_Scale", false, false],
		"K06": [Vector3(21.1, 0.95, -11.2), "../../Furniture/K06_Weight5", true, false],
		"K07": [Vector3(21.7, 0.95, -11.2), "../../Furniture/K07_Weight3", true, false],
		"K08": [Vector3(22.3, 0.95, -11.2), "../../Furniture/K08_Weight2", true, false],
		"K09": [Vector3(23.9, 0.95, -11.2), "../../Furniture/K09_WeightHalf", true, false],
		"K10": [Vector3(24.0, 0.95, -8.2), "../../Furniture/K10_FalseWeight", false, false],
		"K13": [Vector3(19.65, 0.68, -15.9), "../../Furniture/K13_WringerCrank", true, true],
		"K15": [Vector3(21.45, 0.95, -11.05), "../../Furniture/K15_MealNote", true, false],
		"K17": [Vector3(22.0, 1.1, -6.3), "../../Furniture/K17_BurnedCurtain", false, false],
	}
	_add_interaction_set(anchors, areas, existing, authored)

func _kitchen_lighting(parent: Node3D) -> void:
	for i in range(2): _omni(parent, "KitchenPool_%d" % i, Vector3(21.5, 2.7, -8.5 - i * 5.0), Color("d0a66d"), 1.8, 5.3)

func _kitchen_atmosphere(parent: Node3D) -> void:
	_particles(parent, "KitchenSmoke", Vector3(21.5, 0.3, -11.5), Vector3(2.8, 0.2, 4.6), Color(0.15, 0.14, 0.13, 0.17), 32)

func _add_interaction_set(anchors: Node3D, areas: Node3D, existing: Dictionary, authored: Dictionary) -> void:
	for id in existing: _anchor(anchors, id, existing[id])
	for id in authored: _anchor(anchors, id, authored[id]); _area(areas, id, authored[id][0])

func _anchor(parent: Node, id: String, data: Array) -> void:
	var marker := Marker3D.new(); marker.name = id + "Anchor"; marker.position = data[0]; marker.add_to_group("ashdown_interaction_anchor", true)
	marker.set_meta("interaction_id", StringName(id)); marker.set_meta("visual_path", NodePath(data[1])); marker.set_meta("hide_visual_on_collect", data[2]); marker.set_meta("hide_visual_when_unavailable", data[3]); parent.add_child(marker)

func _area(parent: Node, id: String, pos: Vector3) -> void:
	var area := Area3D.new(); area.name = id; area.position = pos; area.set_script(INTERACTABLE); area.set("interaction_id", StringName(id)); area.set("interaction_radius", 0.62); area.add_to_group("ashdown_interactable", true)
	var collision := CollisionShape3D.new(); collision.name = "CollisionShape3D"; var shape := SphereShape3D.new(); shape.radius = 0.62; collision.shape = shape; area.add_child(collision); parent.add_child(area)

func _particles(parent: Node, name: String, pos: Vector3, extents: Vector3, color: Color, amount: int) -> void:
	var p := GPUParticles3D.new(); p.name = name; p.position = pos; p.amount = amount; p.lifetime = 7.0; p.visible = false; p.emitting = false; p.visibility_aabb = AABB(-extents, extents * 2.0 + Vector3(0, 4, 0))
	var process := ParticleProcessMaterial.new(); process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX; process.emission_box_extents = extents; process.direction = Vector3(0, 1, 0); process.spread = 24; process.initial_velocity_min = 0.08; process.initial_velocity_max = 0.25; process.scale_min = 0.8; process.scale_max = 2.2; process.color = color; p.process_material = process
	var quad := QuadMesh.new(); quad.size = Vector2(0.9, 0.9); var m := _mat(name + "Material", color, 1.0); m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED; m.vertex_color_use_as_albedo = true; quad.material = m; p.draw_pass_1 = quad; parent.add_child(p)

func _omni(parent: Node, name: String, pos: Vector3, color: Color, energy: float, range_value: float) -> void:
	var light := OmniLight3D.new(); light.name = name; light.position = pos; light.light_color = color; light.light_energy = energy; light.omni_range = range_value; light.shadow_enabled = true; parent.add_child(light)

func _door_frame(parent: Node, name: String, pos: Vector3, side: bool) -> void:
	var frame := _prop(parent, name, pos); frame.rotation_degrees.y = 90 if side else 0
	_box(frame, "Left", Vector3(-0.86, 0, 0), Vector3(0.16, 2.36, 0.22), mats.wood_dark); _box(frame, "Right", Vector3(0.86, 0, 0), Vector3(0.16, 2.36, 0.22), mats.wood_dark); _box(frame, "Lintel", Vector3(0, 1.12, 0), Vector3(1.88, 0.18, 0.22), mats.wood_dark)

func _branch(parent: Node, name: String) -> Node3D: var n := Node3D.new(); n.name = name; parent.add_child(n); return n
func _prop(parent: Node, name: String, pos: Vector3) -> Node3D: var n := Node3D.new(); n.name = name; n.position = pos; parent.add_child(n); return n
func _box(parent: Node, name: String, pos: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var n := MeshInstance3D.new(); n.name = name; n.position = pos; var mesh := BoxMesh.new(); mesh.size = size; mesh.material = material; n.mesh = mesh; parent.add_child(n); return n
func _cylinder(parent: Node, name: String, pos: Vector3, radius: float, height: float, material: Material, rotation := Vector3.ZERO) -> MeshInstance3D:
	var n := MeshInstance3D.new(); n.name = name; n.position = pos; n.rotation_degrees = rotation; var mesh := CylinderMesh.new(); mesh.top_radius = radius; mesh.bottom_radius = radius; mesh.height = height; mesh.radial_segments = 10; mesh.material = material; n.mesh = mesh; parent.add_child(n); return n
func _torus(parent: Node, name: String, pos: Vector3, inner: float, outer: float, material: Material) -> MeshInstance3D:
	var n := MeshInstance3D.new(); n.name = name; n.position = pos; var mesh := TorusMesh.new(); mesh.inner_radius = inner; mesh.outer_radius = outer; mesh.rings = 10; mesh.ring_segments = 8; mesh.material = material; n.mesh = mesh; parent.add_child(n); return n
func _save(root: Node, path: String) -> Error:
	_set_owner_recursive(root, root); var packed := PackedScene.new(); var result := packed.pack(root); return ResourceSaver.save(packed, path) if result == OK else result
func _set_owner_recursive(node: Node, root: Node) -> void:
	for child in node.get_children(): child.owner = root; _set_owner_recursive(child, root)
