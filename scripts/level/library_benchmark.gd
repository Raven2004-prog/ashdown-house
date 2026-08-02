class_name AshdownLibraryBenchmark
extends Node3D

const FLOOR_ALBEDO: Texture2D = preload("res://assets/materials/ambientcg/library/Planks021_1K-JPG_Color.jpg")
const FLOOR_NORMAL: Texture2D = preload("res://assets/materials/ambientcg/library/Planks021_1K-JPG_NormalGL.jpg")
const FLOOR_ROUGHNESS: Texture2D = preload("res://assets/materials/ambientcg/library/Planks021_1K-JPG_Roughness.jpg")
const WALL_ALBEDO: Texture2D = preload("res://assets/materials/ambientcg/library/Plaster005_1K-JPG_Color.jpg")
const WALL_NORMAL: Texture2D = preload("res://assets/materials/ambientcg/library/Plaster005_1K-JPG_NormalGL.jpg")
const WALL_ROUGHNESS: Texture2D = preload("res://assets/materials/ambientcg/library/Plaster005_1K-JPG_Roughness.jpg")

const TABLE_SCENE: PackedScene = preload("res://assets/furniture/kenney_furniture_kit/library/table.glb")
const CHAIR_SCENE: PackedScene = preload("res://assets/furniture/kenney_furniture_kit/library/chair.glb")
const DESK_SCENE: PackedScene = preload("res://assets/furniture/kenney_furniture_kit/library/desk.glb")
const BOOKS_SCENE: PackedScene = preload("res://assets/furniture/kenney_furniture_kit/library/books.glb")
const WALL_LAMP_SCENE: PackedScene = preload("res://assets/furniture/kenney_furniture_kit/library/lampWall.glb")
const CEILING_LAMP_SCENE: PackedScene = preload("res://assets/furniture/kenney_furniture_kit/library/lampSquareCeiling.glb")
const RUG_SCENE: PackedScene = preload("res://assets/furniture/kenney_furniture_kit/library/rugRectangle.glb")

const BOOK_COLORS: Array[Color] = [
	Color(0.25, 0.33, 0.30),
	Color(0.40, 0.20, 0.16),
	Color(0.34, 0.28, 0.18),
	Color(0.18, 0.25, 0.36),
	Color(0.42, 0.38, 0.27),
	Color(0.22, 0.19, 0.18)
]

var architecture: Node3D
var furniture: Node3D
var anchors: Node3D
var lighting: Node3D
var atmosphere: Node3D
var sliding_shelf: Node3D
var sliding_shelf_closed_position := Vector3.ZERO
var shelf_open := false
var built := false

var floor_material: StandardMaterial3D
var wall_material: StandardMaterial3D
var ceiling_material: StandardMaterial3D
var dark_wood: StandardMaterial3D
var mid_wood: StandardMaterial3D
var brass: StandardMaterial3D
var aged_paper: StandardMaterial3D
var iron: StandardMaterial3D
var smoke_blue: StandardMaterial3D

func _ready() -> void:
	build_if_needed()

func build_if_needed() -> void:
	if built:
		return
	built = true
	_create_roots()
	_create_materials()
	_build_shell()
	_build_bookcases()
	_build_reading_area()
	_build_catalog_zone()
	_build_windows_and_details()
	_build_interaction_props()
	_build_lighting()
	_build_atmosphere()

func apply_gameplay_state(flags: Dictionary) -> void:
	if sliding_shelf == null:
		return
	var should_open := bool(flags.get("library_bookcase_open", false)) or bool(flags.get("library_shelf_open", false))
	if should_open == shelf_open:
		return
	shelf_open = should_open
	var destination := sliding_shelf_closed_position + (Vector3(1.65, 0, 0) if shelf_open else Vector3.ZERO)
	if is_inside_tree():
		var tween := create_tween()
		tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(sliding_shelf, "position", destination, 0.8)
	else:
		sliding_shelf.position = destination

func _create_roots() -> void:
	architecture = Node3D.new()
	architecture.name = "Architecture"
	add_child(architecture)
	furniture = Node3D.new()
	furniture.name = "Furniture"
	add_child(furniture)
	anchors = Node3D.new()
	anchors.name = "InteractionAnchors"
	add_child(anchors)
	lighting = Node3D.new()
	lighting.name = "Lighting"
	add_child(lighting)
	atmosphere = Node3D.new()
	atmosphere.name = "Atmosphere"
	add_child(atmosphere)

func _create_materials() -> void:
	floor_material = _make_pbr_material(
		FLOOR_ALBEDO, FLOOR_NORMAL, FLOOR_ROUGHNESS,
		Color(0.46, 0.39, 0.30), Vector3(8.0, 7.0, 1.0)
	)
	wall_material = _make_pbr_material(
		WALL_ALBEDO, WALL_NORMAL, WALL_ROUGHNESS,
		Color(0.43, 0.45, 0.40), Vector3(5.0, 2.0, 1.0)
	)
	ceiling_material = _make_color_material(Color(0.29, 0.30, 0.28), 1.0)
	dark_wood = _make_color_material(Color(0.18, 0.095, 0.055), 0.88)
	mid_wood = _make_color_material(Color(0.32, 0.18, 0.10), 0.82)
	brass = _make_color_material(Color(0.45, 0.31, 0.10), 0.55)
	brass.metallic = 0.55
	aged_paper = _make_color_material(Color(0.62, 0.55, 0.39), 0.95)
	iron = _make_color_material(Color(0.075, 0.08, 0.085), 0.72)
	iron.metallic = 0.35
	smoke_blue = _make_color_material(Color(0.20, 0.26, 0.29), 0.94)

func _build_shell() -> void:
	_add_box(architecture, "LibraryFloorFinish", Vector3(-17.0, 0.015, 2.0), Vector3(15.70, 0.03, 13.70), floor_material, false)
	_add_box(architecture, "LibraryCeiling", Vector3(-17.0, 3.38, 2.0), Vector3(15.70, 0.08, 13.70), ceiling_material, false)
	_add_box(architecture, "NorthWallFinish", Vector3(-17.0, 1.70, 8.82), Vector3(15.70, 3.35, 0.04), wall_material, false)
	_add_box(architecture, "WestWallFinish", Vector3(-24.82, 1.70, 2.0), Vector3(0.04, 3.35, 13.70), wall_material, false)
	_add_box(architecture, "EastWallNorthFinish", Vector3(-9.18, 1.70, 6.15), Vector3(0.04, 3.35, 5.35), wall_material, false)
	_add_box(architecture, "EastWallSouthFinish", Vector3(-9.18, 1.70, -2.15), Vector3(0.04, 3.35, 5.35), wall_material, false)
	_add_box(architecture, "SouthWallWestFinish", Vector3(-21.6, 1.70, -4.82), Vector3(6.5, 3.35, 0.04), wall_material, false)
	_add_box(architecture, "SouthWallEastFinish", Vector3(-12.4, 1.70, -4.82), Vector3(6.5, 3.35, 0.04), wall_material, false)
	_add_baseboards()
	_add_door_frame("D03Frame", Vector3(-9.16, 0, 2.0), 90.0)
	_add_door_frame("D05Frame", Vector3(-17.0, 0, -4.81), 0.0)

func _add_baseboards() -> void:
	_add_box(architecture, "NorthSkirting", Vector3(-17.0, 0.10, 8.72), Vector3(15.5, 0.20, 0.12), dark_wood, false)
	_add_box(architecture, "WestSkirting", Vector3(-24.72, 0.10, 2.0), Vector3(0.12, 0.20, 13.5), dark_wood, false)
	_add_box(architecture, "EastSkirtingNorth", Vector3(-9.28, 0.10, 6.2), Vector3(0.12, 0.20, 5.2), dark_wood, false)
	_add_box(architecture, "EastSkirtingSouth", Vector3(-9.28, 0.10, -2.2), Vector3(0.12, 0.20, 5.2), dark_wood, false)
	_add_box(architecture, "SouthSkirtingWest", Vector3(-21.6, 0.10, -4.72), Vector3(6.3, 0.20, 0.12), dark_wood, false)
	_add_box(architecture, "SouthSkirtingEast", Vector3(-12.4, 0.10, -4.72), Vector3(6.3, 0.20, 0.12), dark_wood, false)

func _add_door_frame(node_name: String, pos: Vector3, yaw: float) -> void:
	var root := Node3D.new()
	root.name = node_name
	root.position = pos
	root.rotation_degrees.y = yaw
	architecture.add_child(root)
	_add_local_box(root, "LeftPost", Vector3(-0.68, 1.15, 0), Vector3(0.14, 2.30, 0.18), dark_wood)
	_add_local_box(root, "RightPost", Vector3(0.68, 1.15, 0), Vector3(0.14, 2.30, 0.18), dark_wood)
	_add_local_box(root, "Header", Vector3(0, 2.27, 0), Vector3(1.50, 0.16, 0.18), dark_wood)

func _build_bookcases() -> void:
	_add_bookcase("L01_WestShelfA", Vector3(-24.45, 0, 6.20), Vector3(3.10, 2.38, 0.48), 90.0, false)
	_add_bookcase("L02_WestShelfB", Vector3(-24.45, 0, 2.40), Vector3(3.10, 2.38, 0.48), 90.0, false)
	_add_bookcase("L03_WestShelfC", Vector3(-24.45, 0, -1.40), Vector3(3.10, 2.38, 0.48), 90.0, false)
	_add_bookcase("L04_NorthShelfA", Vector3(-21.80, 0, 8.45), Vector3(3.55, 2.42, 0.52), 180.0, false)
	sliding_shelf = _add_bookcase("L05_SlidingShelf", Vector3(-17.40, 0, 8.45), Vector3(3.55, 2.42, 0.52), 180.0, false)
	sliding_shelf_closed_position = sliding_shelf.position
	_add_local_box(sliding_shelf, "SequencePlate", Vector3(0, 1.88, 0.30), Vector3(0.72, 0.18, 0.05), brass)
	_add_local_box(sliding_shelf, "SequenceBook2", Vector3(-0.64, 1.30, 0.32), Vector3(0.16, 0.38, 0.12), _make_color_material(Color(0.43, 0.19, 0.15), 0.92))
	_add_local_box(sliding_shelf, "SequenceBook5", Vector3(0.02, 0.83, 0.32), Vector3(0.15, 0.36, 0.12), _make_color_material(Color(0.18, 0.29, 0.25), 0.92))
	_add_local_box(sliding_shelf, "SequenceBook1", Vector3(0.70, 1.30, 0.32), Vector3(0.17, 0.40, 0.12), _make_color_material(Color(0.28, 0.25, 0.42), 0.92))
	_add_bookcase("L06_NorthShelfC", Vector3(-13.00, 0, 8.45), Vector3(3.55, 2.42, 0.52), 180.0, false)
	_add_bookcase("CentralRangeA", Vector3(-18.5, 0, 0.20), Vector3(8.70, 2.30, 0.88), 0.0, true)
	_add_bookcase("CentralRangeB", Vector3(-18.5, 0, 3.80), Vector3(8.70, 2.30, 0.88), 0.0, true)
	_add_bookcase("CentralRangeC", Vector3(-18.5, 0, 6.40), Vector3(8.70, 2.30, 0.88), 0.0, true)
	var ladder := _add_rolling_ladder(Vector3(-19.9, 0, 7.78))
	_register_anchor(&"L07", Vector3(-19.9, 1.05, 7.58), ladder, false, false)
	_register_anchor(&"L05", Vector3(-17.4, 1.2, 7.95), sliding_shelf, false, false)

func _add_bookcase(node_name: String, pos: Vector3, size: Vector3, yaw: float, double_sided: bool) -> Node3D:
	var root := Node3D.new()
	root.name = node_name
	root.position = pos
	root.rotation_degrees.y = yaw
	furniture.add_child(root)
	var body := StaticBody3D.new()
	root.add_child(body)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	collision.position.y = size.y * 0.5
	body.add_child(collision)
	_add_local_box(root, "LeftFrame", Vector3(-size.x * 0.5 + 0.07, size.y * 0.5, 0), Vector3(0.14, size.y, size.z), dark_wood)
	_add_local_box(root, "RightFrame", Vector3(size.x * 0.5 - 0.07, size.y * 0.5, 0), Vector3(0.14, size.y, size.z), dark_wood)
	_add_local_box(root, "TopFrame", Vector3(0, size.y - 0.07, 0), Vector3(size.x, 0.14, size.z), dark_wood)
	_add_local_box(root, "Back", Vector3(0, size.y * 0.5, 0), Vector3(size.x - 0.16, size.y - 0.18, 0.07), mid_wood)
	var shelf_count := 5
	for level in range(shelf_count):
		var shelf_y := 0.08 + float(level) * (size.y - 0.16) / float(shelf_count)
		_add_local_box(root, "Shelf%02d" % level, Vector3(0, shelf_y, 0), Vector3(size.x, 0.10, size.z), dark_wood)
		if level < shelf_count - 1:
			_add_book_clusters(root, size, shelf_y + 0.10, level, -1.0)
			if double_sided:
				_add_book_clusters(root, size, shelf_y + 0.10, level, 1.0)
	return root

func _add_book_clusters(root: Node3D, size: Vector3, shelf_y: float, level: int, side: float) -> void:
	var cluster_count := maxi(4, int(size.x / 0.70))
	var usable_width := size.x - 0.28
	for index in range(cluster_count):
		var width := usable_width / float(cluster_count) * (0.72 + 0.10 * float((index + level) % 3))
		var height := 0.30 + 0.055 * float((index * 2 + level) % 4)
		var x := -usable_width * 0.5 + (float(index) + 0.5) * usable_width / float(cluster_count)
		var z := side * (size.z * 0.5 - 0.105)
		var mat := _make_color_material(BOOK_COLORS[(index + level * 2) % BOOK_COLORS.size()], 0.90)
		_add_local_box(root, "Books_%02d_%02d_%s" % [level, index, "F" if side < 0 else "B"], Vector3(x, shelf_y + height * 0.5, z), Vector3(width, height, 0.16), mat)

func _add_rolling_ladder(pos: Vector3) -> Node3D:
	var root := Node3D.new()
	root.name = "L07_RollingLadder"
	root.position = pos
	root.rotation_degrees.z = -7.0
	furniture.add_child(root)
	_add_local_box(root, "LeftRail", Vector3(-0.24, 1.0, 0), Vector3(0.07, 2.0, 0.08), mid_wood)
	_add_local_box(root, "RightRail", Vector3(0.24, 1.0, 0), Vector3(0.07, 2.0, 0.08), mid_wood)
	for rung in range(6):
		_add_local_box(root, "Rung%02d" % rung, Vector3(0, 0.22 + rung * 0.29, 0), Vector3(0.52, 0.055, 0.08), mid_wood)
	return root

func _build_reading_area() -> void:
	var rug := _add_kenney_prop("ReadingRug", RUG_SCENE, Vector3(-17.0, 0.035, -3.10), 0.0, 4.25, Vector3.ZERO)
	rug.scale.z *= 1.25
	var table_a := _add_kenney_prop("L08_ReadingTableA", TABLE_SCENE, Vector3(-21.35, 0, -3.15), 0.0, 2.35, Vector3(2.0, 0.82, 1.05))
	var table_b := _add_kenney_prop("L09_ReadingTableB", TABLE_SCENE, Vector3(-12.65, 0, -3.15), 0.0, 2.35, Vector3(2.0, 0.82, 1.05))
	_add_kenney_prop("L10_ChairA", CHAIR_SCENE, Vector3(-22.15, 0, -2.15), 180.0, 1.82, Vector3(0.52, 0.86, 0.52))
	_add_kenney_prop("L11_ChairB", CHAIR_SCENE, Vector3(-20.55, 0, -4.05), 0.0, 1.82, Vector3(0.52, 0.86, 0.52))
	_add_kenney_prop("L12_ChairC", CHAIR_SCENE, Vector3(-13.45, 0, -2.15), 180.0, 1.82, Vector3(0.52, 0.86, 0.52))
	_add_kenney_prop("ReadingChairD", CHAIR_SCENE, Vector3(-11.85, 0, -4.05), 0.0, 1.82, Vector3(0.52, 0.86, 0.52))
	_add_book_stack("TableBooksA", table_a.position + Vector3(0.35, 0.86, 0.12), 12.0)
	_add_book_stack("TableBooksB", table_b.position + Vector3(-0.35, 0.86, -0.12), -9.0)

func _build_catalog_zone() -> void:
	var desk := _add_kenney_prop("L13_LibrarianDesk", DESK_SCENE, Vector3(-11.2, 0, 6.05), 270.0, 2.15, Vector3(1.30, 0.84, 1.65))
	_register_anchor(&"L13", Vector3(-11.2, 0.92, 6.05), desk, false, false)
	var cabinet := _add_catalog_cabinet(Vector3(-12.20, 0, 4.15))
	_register_anchor(&"L14", Vector3(-12.20, 0.95, 4.15), cabinet, false, false)
	var key := _add_key_prop("L21_ClassroomKey", Vector3(-11.05, 0.86, 5.92))
	_register_anchor(&"L21", key.position, key, true, true)
	var arun_card := _add_document("L22_ArunCard", Vector3(-11.28, 0.86, 6.10), -12.0, Color(0.53, 0.56, 0.49))
	_register_anchor(&"L22", arun_card.position, arun_card, true, true)
	var ledger := _add_document("L23_KabirLedger", Vector3(-12.18, 0.88, 4.12), 7.0, Color(0.35, 0.19, 0.13))
	_register_anchor(&"L23", ledger.position, ledger, true, true)
	var strip := _add_document("L24_ShelfStrip", Vector3(-11.18, 0.87, 5.78), 18.0, Color(0.66, 0.57, 0.37), Vector2(0.40, 0.12))
	_register_anchor(&"L24", strip.position, strip, true, true)

func _build_windows_and_details() -> void:
	var window_a := _add_barred_window("L27_BarredWindowA", Vector3(-24.76, 1.72, 5.05))
	_register_anchor(&"L27", Vector3(-24.42, 1.55, 5.05), window_a, false, false)
	var window_b := _add_barred_window("L28_BarredWindowB", Vector3(-24.76, 1.72, 0.05))
	_register_anchor(&"L28", Vector3(-24.42, 1.55, 0.05), window_b, false, false)
	var radiator := _add_radiator(Vector3(-24.35, 0, -3.35))
	_register_anchor(&"LIB_RADIATOR", Vector3(-24.1, 0.65, -3.35), radiator, false, false)
	var return_chute := _add_return_chute(Vector3(-9.35, 0.82, 5.15))
	_register_anchor(&"LIB_RETURN_CHUTE", Vector3(-9.55, 1.05, 5.15), return_chute, false, false)
	var cart_a := _add_book_cart("BookCartA", Vector3(-15.45, 0, -0.75), 15.0)
	_register_anchor(&"LIB_BOOK_CART_A", Vector3(-15.45, 0.82, -0.75), cart_a, false, false)
	var cart_b := _add_book_cart("BookCartB", Vector3(-22.8, 0, 7.0), -12.0)
	_register_anchor(&"LIB_BOOK_CART_B", Vector3(-22.8, 0.82, 7.0), cart_b, false, false)
	var plaque := _add_document("ShelfPlaque", Vector3(-17.55, 1.48, 7.93), 0.0, brass, Vector2(0.55, 0.18))
	_register_anchor(&"LIB_SHELF_PLAQUE", plaque.position, plaque, false, false)
	var marks := _add_wall_marks(Vector3(-9.30, 1.10, -1.35))
	_register_anchor(&"LIB_CHILD_MARKS", Vector3(-9.55, 1.1, -1.35), marks, false, false)
	var footprints := _add_footprints(Vector3(-18.0, 0.04, -1.25))
	_register_anchor(&"LIB_ASH_FOOTPRINTS", Vector3(-18.0, 0.3, -1.25), footprints, false, false)
	var broken_lamp := _add_kenney_prop("DamagedWallLamp", WALL_LAMP_SCENE, Vector3(-9.35, 2.05, -2.7), 90.0, 2.1, Vector3.ZERO)
	_register_anchor(&"LIB_DAMAGED_LAMP", Vector3(-9.60, 1.95, -2.7), broken_lamp, false, false)

func _build_interaction_props() -> void:
	var moon := _add_book_prop("L18_MoonBook", Vector3(-19.9, 0.91, -3.12), 4.0, Color(0.18, 0.25, 0.40))
	_register_anchor(&"L18", moon.position, moon, false, false)
	var bird := _add_book_prop("L19_BirdBook", Vector3(-14.0, 0.91, -3.12), -11.0, Color(0.34, 0.29, 0.16))
	_register_anchor(&"L19", bird.position, bird, false, false)
	var train := _add_book_prop("L20_TrainBook", Vector3(-23.9, 1.45, -1.40), 90.0, Color(0.35, 0.17, 0.14))
	_register_anchor(&"L20", train.position, train, false, false)
	var photo := _add_document("L25_MiraPhoto", Vector3(-17.4, 1.44, 8.02), 0.0, Color(0.34, 0.31, 0.25), Vector2(0.46, 0.34))
	_register_anchor(&"L25", photo.position, photo, true, true)
	var code := _add_document("L26_BoilerCode", Vector3(-17.4, 0.48, 7.92), -8.0, aged_paper, Vector2(0.48, 0.28))
	_register_anchor(&"L26", code.position, code, true, true)
	var smoke_trigger := Marker3D.new()
	smoke_trigger.name = "L30_SmokeMemoryTrigger"
	smoke_trigger.position = Vector3(-17.0, 0, 4.0)
	add_child(smoke_trigger)

func _build_lighting() -> void:
	for data in [
		[Vector3(-21.0, 3.05, 4.8), Color(0.76, 0.66, 0.48), 1.55],
		[Vector3(-17.0, 3.05, 1.8), Color(0.68, 0.63, 0.50), 1.45],
		[Vector3(-13.0, 3.05, -2.2), Color(0.72, 0.60, 0.43), 1.50]
	]:
		_add_ceiling_light(data[0], data[1], data[2])
	var cool_window_light := OmniLight3D.new()
	cool_window_light.name = "WindowFill"
	cool_window_light.position = Vector3(-23.3, 1.9, 2.5)
	cool_window_light.light_color = Color(0.36, 0.47, 0.56)
	cool_window_light.light_energy = 0.70
	cool_window_light.omni_range = 6.5
	cool_window_light.shadow_enabled = true
	lighting.add_child(cool_window_light)
	var desk_lamp := _add_kenney_prop("DeskLamp", WALL_LAMP_SCENE, Vector3(-11.1, 1.02, 6.0), 270.0, 1.2, Vector3.ZERO)
	var desk_light := OmniLight3D.new()
	desk_light.name = "DeskLight"
	desk_light.position = Vector3(-11.65, 1.28, 6.0)
	desk_light.light_color = Color(1.0, 0.61, 0.28)
	desk_light.light_energy = 0.85
	desk_light.omni_range = 3.2
	lighting.add_child(desk_light)

func _add_ceiling_light(pos: Vector3, color: Color, energy: float) -> void:
	_add_kenney_prop("CeilingFixture", CEILING_LAMP_SCENE, pos + Vector3(0, 0.15, 0), 0.0, 2.0, Vector3.ZERO)
	var light := OmniLight3D.new()
	light.position = pos
	light.light_color = color
	light.light_energy = energy
	light.omni_range = 7.0
	light.shadow_enabled = true
	lighting.add_child(light)

func _build_atmosphere() -> void:
	var particles := GPUParticles3D.new()
	particles.name = "DustMotes"
	particles.position = Vector3(-17.0, 1.55, 2.0)
	particles.amount = 46
	particles.lifetime = 8.0
	particles.randomness = 0.75
	particles.visibility_aabb = AABB(Vector3(-8, -1.5, -7), Vector3(16, 3, 14))
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(7.4, 1.2, 6.4)
	process.gravity = Vector3(0, 0.012, 0)
	process.initial_velocity_min = 0.005
	process.initial_velocity_max = 0.025
	process.scale_min = 0.6
	process.scale_max = 1.35
	particles.process_material = process
	var mote := SphereMesh.new()
	mote.radius = 0.009
	mote.height = 0.018
	mote.material = _make_unshaded_transparent(Color(0.76, 0.70, 0.52, 0.42))
	particles.draw_pass_1 = mote
	atmosphere.add_child(particles)

func _add_catalog_cabinet(pos: Vector3) -> Node3D:
	var root := Node3D.new()
	root.name = "L14_CatalogCabinet"
	root.position = pos
	furniture.add_child(root)
	_add_local_box(root, "Cabinet", Vector3(0, 0.52, 0), Vector3(0.92, 1.04, 1.35), dark_wood)
	for index in range(3):
		var y := 0.28 + index * 0.27
		_add_local_box(root, "L%02d_Drawer" % (15 + index), Vector3(-0.475, y, 0), Vector3(0.04, 0.20, 1.05), mid_wood)
		_add_local_box(root, "Handle%02d" % index, Vector3(-0.51, y, 0), Vector3(0.04, 0.05, 0.22), brass)
	var body := StaticBody3D.new()
	root.add_child(body)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.92, 1.04, 1.35)
	shape.shape = box
	shape.position.y = 0.52
	body.add_child(shape)
	return root

func _add_barred_window(node_name: String, pos: Vector3) -> Node3D:
	var root := Node3D.new()
	root.name = node_name
	root.position = pos
	furniture.add_child(root)
	var glass := _make_unshaded_transparent(Color(0.17, 0.26, 0.32, 0.48))
	_add_local_box(root, "Glass", Vector3(0, 0, 0), Vector3(0.045, 1.32, 1.55), glass)
	_add_local_box(root, "TopFrame", Vector3(0.03, 0.72, 0), Vector3(0.12, 0.12, 1.78), dark_wood)
	_add_local_box(root, "BottomFrame", Vector3(0.03, -0.72, 0), Vector3(0.12, 0.12, 1.78), dark_wood)
	_add_local_box(root, "LeftFrame", Vector3(0.03, 0, -0.83), Vector3(0.12, 1.55, 0.12), dark_wood)
	_add_local_box(root, "RightFrame", Vector3(0.03, 0, 0.83), Vector3(0.12, 1.55, 0.12), dark_wood)
	for bar in [-0.50, 0.0, 0.50]:
		_add_local_box(root, "Bar", Vector3(-0.05, 0, bar), Vector3(0.08, 1.48, 0.055), iron)
	return root

func _add_radiator(pos: Vector3) -> Node3D:
	var root := Node3D.new()
	root.name = "LibraryRadiator"
	root.position = pos
	furniture.add_child(root)
	for index in range(7):
		_add_local_box(root, "Fin%02d" % index, Vector3(0, 0.48, -0.54 + index * 0.18), Vector3(0.22, 0.88, 0.11), iron)
	return root

func _add_return_chute(pos: Vector3) -> Node3D:
	var root := Node3D.new()
	root.name = "LibraryReturnChute"
	root.position = pos
	furniture.add_child(root)
	_add_local_box(root, "Frame", Vector3(0, 0, 0), Vector3(0.16, 0.65, 0.92), dark_wood)
	_add_local_box(root, "Slot", Vector3(-0.09, 0.08, 0), Vector3(0.03, 0.14, 0.64), iron)
	return root

func _add_book_cart(node_name: String, pos: Vector3, yaw: float) -> Node3D:
	var root := Node3D.new()
	root.name = node_name
	root.position = pos
	root.rotation_degrees.y = yaw
	furniture.add_child(root)
	_add_local_box(root, "Base", Vector3(0, 0.18, 0), Vector3(1.05, 0.10, 0.52), iron)
	_add_local_box(root, "LowerShelf", Vector3(0, 0.42, 0), Vector3(1.05, 0.08, 0.52), mid_wood)
	_add_local_box(root, "UpperShelf", Vector3(0, 0.78, 0), Vector3(1.05, 0.08, 0.52), mid_wood)
	_add_local_box(root, "LeftRail", Vector3(-0.48, 0.55, 0), Vector3(0.06, 0.82, 0.52), iron)
	_add_local_box(root, "RightRail", Vector3(0.48, 0.55, 0), Vector3(0.06, 0.82, 0.52), iron)
	_add_book_stack("CartBooks", pos + Vector3(0, 0.88, 0), yaw)
	return root

func _add_wall_marks(pos: Vector3) -> Node3D:
	var root := Node3D.new()
	root.name = "ChildHeightMarks"
	root.position = pos
	furniture.add_child(root)
	for index in range(5):
		_add_local_box(root, "Mark%02d" % index, Vector3(-0.03, -0.40 + index * 0.20, 0), Vector3(0.025, 0.025, 0.34 + index * 0.04), dark_wood)
	return root

func _add_footprints(pos: Vector3) -> Node3D:
	var root := Node3D.new()
	root.name = "AshFootprints"
	root.position = pos
	furniture.add_child(root)
	var soot := _make_color_material(Color(0.055, 0.05, 0.045), 1.0)
	for index in range(5):
		var foot := _add_local_box(root, "Foot%02d" % index, Vector3(-0.32 + index * 0.18, 0, -0.55 + index * 0.28), Vector3(0.16, 0.018, 0.31), soot)
		foot.rotation_degrees.y = -14.0 if index % 2 == 0 else 12.0
	return root

func _add_book_stack(node_name: String, pos: Vector3, yaw: float) -> Node3D:
	var root := Node3D.new()
	root.name = node_name
	root.position = pos
	root.rotation_degrees.y = yaw
	furniture.add_child(root)
	for index in range(3):
		var model := BOOKS_SCENE.instantiate() as Node3D
		model.position.y = index * 0.10
		model.rotation_degrees.y = index * 7.0
		model.scale = Vector3.ONE * 0.85
		root.add_child(model)
		_configure_model_materials(model)
	return root

func _add_book_prop(node_name: String, pos: Vector3, yaw: float, color: Color) -> Node3D:
	var root := Node3D.new()
	root.name = node_name
	root.position = pos
	root.rotation_degrees.y = yaw
	furniture.add_child(root)
	_add_local_box(root, "Book", Vector3.ZERO, Vector3(0.34, 0.08, 0.48), _make_color_material(color, 0.88))
	_add_local_box(root, "Pages", Vector3(0, 0.046, 0), Vector3(0.30, 0.018, 0.43), aged_paper)
	return root

func _add_key_prop(node_name: String, pos: Vector3) -> Node3D:
	var root := Node3D.new()
	root.name = node_name
	root.position = pos
	furniture.add_child(root)
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.055
	torus.outer_radius = 0.085
	ring.mesh = torus
	ring.rotation_degrees.x = 90.0
	ring.material_override = brass
	root.add_child(ring)
	_add_local_box(root, "Stem", Vector3(0.13, 0, 0), Vector3(0.22, 0.035, 0.045), brass)
	_add_local_box(root, "Tooth", Vector3(0.23, 0, 0.045), Vector3(0.06, 0.035, 0.09), brass)
	return root

func _add_document(node_name: String, pos: Vector3, yaw: float, material_or_color, size := Vector2(0.42, 0.30)) -> Node3D:
	var root := Node3D.new()
	root.name = node_name
	root.position = pos
	root.rotation_degrees.y = yaw
	furniture.add_child(root)
	var material: Material = material_or_color if material_or_color is Material else _make_color_material(material_or_color as Color, 0.95)
	_add_local_box(root, "Document", Vector3.ZERO, Vector3(size.x, 0.018, size.y), material)
	return root

func _add_kenney_prop(node_name: String, packed: PackedScene, pos: Vector3, yaw: float, scale_factor: float, collision_size: Vector3) -> Node3D:
	var root := Node3D.new()
	root.name = node_name
	root.position = pos
	root.rotation_degrees.y = yaw
	furniture.add_child(root)
	var model := packed.instantiate() as Node3D
	model.name = "Visual"
	model.scale = Vector3.ONE * scale_factor
	root.add_child(model)
	_configure_model_materials(model)
	if collision_size != Vector3.ZERO:
		var body := StaticBody3D.new()
		root.add_child(body)
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = collision_size
		collision.shape = shape
		collision.position.y = collision_size.y * 0.5
		body.add_child(collision)
	return root

func _configure_model_materials(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		for surface in range(mesh_instance.get_surface_override_material_count()):
			var source := mesh_instance.get_active_material(surface)
			if source is BaseMaterial3D:
				var material := (source as BaseMaterial3D).duplicate() as BaseMaterial3D
				material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
				mesh_instance.set_surface_override_material(surface, material)
	for child in node.get_children():
		_configure_model_materials(child)

func _register_anchor(id: StringName, pos: Vector3, visual: Node3D, hide_on_collect: bool, hide_when_unavailable: bool) -> Marker3D:
	var anchor := Marker3D.new()
	anchor.name = "%sAnchor" % String(id)
	anchor.position = pos
	anchor.set_meta("interaction_id", id)
	anchor.set_meta("hide_visual_on_collect", hide_on_collect)
	anchor.set_meta("hide_visual_when_unavailable", hide_when_unavailable)
	if visual != null:
		anchor.set_meta("visual_path", visual.get_path())
	anchor.add_to_group("ashdown_interaction_anchor")
	anchors.add_child(anchor)
	return anchor

func _add_box(parent: Node3D, node_name: String, pos: Vector3, size: Vector3, material: Material, collision: bool) -> Node3D:
	var root: Node3D = StaticBody3D.new() if collision else Node3D.new()
	root.name = node_name
	root.position = pos
	parent.add_child(root)
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	root.add_child(mesh_instance)
	if collision:
		var collision_shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = size
		collision_shape.shape = box
		root.add_child(collision_shape)
	return root

func _add_local_box(parent: Node3D, node_name: String, pos: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	mesh_instance.position = pos
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	parent.add_child(mesh_instance)
	return mesh_instance

func _make_pbr_material(albedo: Texture2D, normal: Texture2D, roughness: Texture2D, tint: Color, uv_scale: Vector3) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.albedo_texture = albedo
	material.normal_enabled = true
	material.normal_texture = normal
	material.normal_scale = 0.28
	material.roughness = 0.92
	material.roughness_texture = roughness
	material.uv1_scale = uv_scale
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	return material

func _make_color_material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	return material

func _make_unshaded_transparent(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	return material
