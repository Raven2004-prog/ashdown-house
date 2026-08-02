extends Node3D

const LEVEL_DATA_PATH := "res://data/levels/level_ashdown_house.json"
const INTERACTABLE_SCRIPT := preload("res://scripts/interaction/interactable_3d.gd")
const INTERACTION_MANAGER_SCRIPT := preload("res://scripts/interaction/interaction_manager.gd")
const INVENTORY_MANAGER_SCRIPT := preload("res://scripts/level/inventory_manager.gd")
const JOURNAL_MANAGER_SCRIPT := preload("res://scripts/level/journal_manager.gd")
const LEVEL_STATE_CONTROLLER_SCRIPT := preload("res://scripts/level/level_state_controller.gd")
const CHECKPOINT_MANAGER_SCRIPT := preload("res://scripts/level/checkpoint_manager.gd")
const INTERACTION_DISTANCE := 2.2
const WALL_HEIGHT := 3.40
const WALL_THICKNESS := 0.30
const BLOCKOUT_DOOR_GAP_WIDTH := 2.4

var level_data: Dictionary = {}
var code_entry := ""
var code_mode := false
var active_code_puzzle: Dictionary = {}
var interactables_by_id: Dictionary = {}
var authored_anchors_by_id: Dictionary = {}
var debug_labels_visible := false

var inventory_manager
var journal_manager
var level_state
var checkpoint_manager
var interaction_manager
@onready var geometry_root: Node3D = $BlockoutGeometry
@onready var content_root: Node3D = $AuthoredRoomContent
@onready var interactable_root: Node3D = $Interactables
@onready var marker_root: Node3D = $Labels
@onready var player: CharacterBody3D = $Player
@onready var ui_layer: CanvasLayer = $UI
var prompt_label: Label
var subtitle_label: Label
var reticle_label: Label
var journal_panel: Control
var journal_label: Label
var code_panel: Control
var code_label: Label

func _ready() -> void:
	_ensure_inputs()
	_load_level_data()
	_create_managers()
	_create_roots()
	_create_environment()
	_build_blockout()
	_spawn_player()
	_create_ui()
	_show_subtitle("Ashdown House is quiet. Find the register in the Main Hall.")
	if OS.get_cmdline_user_args().has("--library-benchmark-self-test"):
		call_deferred("_run_library_benchmark_self_test")

func _run_library_benchmark_self_test() -> void:
	var failures: Array[String] = []
	var required_level_nodes: Array[NodePath] = [
		^"BlockoutGeometry", ^"AuthoredRoomContent", ^"Interactables", ^"Labels",
		^"WorldEnvironment", ^"DirectionalLight3D", ^"Player", ^"UI"
	]
	for node_path in required_level_nodes:
		if get_node_or_null(node_path) == null:
			failures.append("missing authored level node %s" % node_path)
	var required_player_nodes: Array[NodePath] = [
		^"CollisionShape3D", ^"VisualRoot/PrototypeBody", ^"VisualRoot/Face",
		^"CameraYaw/CameraPitch/SpringArm3D",
		^"CameraYaw/CameraPitch/SpringArm3D/CameraSocket/Camera3D",
		^"CameraYaw/CameraPitch/SpringArm3D/CameraSocket/Camera3D/InteractionRay"
	]
	for node_path in required_player_nodes:
		if player.get_node_or_null(node_path) == null:
			failures.append("missing authored player node %s" % node_path)
	var library_content := content_root.get_node_or_null("LibraryContent")
	if library_content == null:
		failures.append("authored Library content was not instantiated")
	else:
		for branch in [^"Architecture", ^"Furniture", ^"InteractionAnchors", ^"Lighting", ^"Atmosphere"]:
			if library_content.get_node_or_null(branch) == null:
				failures.append("missing authored Library branch %s" % branch)
		if library_content.has_method("build_if_needed"):
			failures.append("Library runtime geometry builder is still active")
	var required_anchors: Array[StringName] = [
		&"L05", &"L07", &"L13", &"L14", &"L18", &"L19", &"L20",
		&"L21", &"L22", &"L23", &"L24", &"L25", &"L26", &"L27", &"L28",
		&"LIB_RADIATOR", &"LIB_RETURN_CHUTE", &"LIB_BOOK_CART_A", &"LIB_BOOK_CART_B",
		&"LIB_SHELF_PLAQUE", &"LIB_CHILD_MARKS", &"LIB_ASH_FOOTPRINTS", &"LIB_DAMAGED_LAMP"
	]
	for id in required_anchors:
		if not authored_anchors_by_id.has(id):
			failures.append("missing authored anchor %s" % id)
		if not interactables_by_id.has(id):
			failures.append("missing interactable %s" % id)
	var library_scene_found := false
	for room_variant in level_data.get("rooms", []):
		var room: Dictionary = room_variant
		if String(room.get("id", "")) == "library":
			library_scene_found = String(room.get("content_scene", "")) == "res://scenes/levels/ashdown/rooms/LibraryBenchmark.tscn"
	if not library_scene_found:
		failures.append("Library content_scene is not configured")
	if not is_equal_approx(float(player.get("normal_spring_length")), 2.65):
		failures.append("camera spring length is not 2.65 m")
	if not is_equal_approx(float(player.get("camera_pivot_height")), 1.48):
		failures.append("camera pivot is not 1.48 m")
	var evidence_before: int = journal_manager.discovered_clues.size()
	journal_manager.record_observation(&"SELF_TEST_OBSERVATION", "Optional inspection")
	if journal_manager.discovered_clues.size() != evidence_before:
		failures.append("optional observation changed progression evidence")
	level_state.complete_library_catalog()
	if not level_state.has_flag(&"library_catalog_solved"):
		failures.append("catalog completion flag was not set")
	level_state.set_flag(&"librarian_desk_opened", true)
	level_state.complete_library_code()
	if not level_state.has_flag(&"library_bookcase_open"):
		failures.append("sliding shelf completion flag was not set")
	var photo = interactables_by_id.get(&"L25")
	if photo == null or not photo.visible:
		failures.append("hidden-shelf clue did not become available")
	elif photo.authored_visual == null or not photo.authored_visual.visible:
		failures.append("hidden-shelf clue prop did not become visible")
	else:
		_collect_evidence(photo)
		if not inventory_manager.has_evidence(&"L25"):
			failures.append("collected clue was not stored")
		if photo.visible or photo.is_in_group("ashdown_interactable") or photo.authored_visual.visible:
			failures.append("collected clue remained visible or targetable")
	if failures.is_empty():
		print("LIBRARY_BENCHMARK_SELF_TEST: PASS")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error("Library benchmark self-test: %s" % failure)
		print("LIBRARY_BENCHMARK_SELF_TEST: FAIL (%d)" % failures.size())
		get_tree().quit(1)

func _unhandled_input(event: InputEvent) -> void:
	if code_mode:
		_handle_code_input(event)
		return
	if event.is_action_pressed("toggle_debug_labels"):
		_toggle_debug_labels()
	elif event.is_action_pressed("open_journal"):
		_toggle_journal()
	elif event.is_action_pressed("release_mouse") and journal_panel != null and journal_panel.visible:
		_close_journal()

func _ensure_inputs() -> void:
	var actions := {
		"move_forward": [KEY_W],
		"move_back": [KEY_S],
		"move_left": [KEY_A],
		"move_right": [KEY_D],
		"sprint": [KEY_SHIFT],
		"crouch": [KEY_CTRL],
		"interact": [KEY_E],
		"open_journal": [KEY_J],
		"toggle_debug_labels": [KEY_F3],
		"release_mouse": [KEY_ESCAPE]
	}
	for action in actions.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for keycode in actions[action]:
			var event := InputEventKey.new()
			event.physical_keycode = keycode
			if not InputMap.action_has_event(action, event):
				InputMap.action_add_event(action, event)

func _load_level_data() -> void:
	var text := FileAccess.get_file_as_string(LEVEL_DATA_PATH)
	level_data = JSON.parse_string(text) as Dictionary
	if level_data == null:
		push_error("Could not parse Ashdown level data.")
		level_data = {}

func _create_managers() -> void:
	inventory_manager = INVENTORY_MANAGER_SCRIPT.new()
	inventory_manager.name = "InventoryManager"
	add_child(inventory_manager)
	journal_manager = JOURNAL_MANAGER_SCRIPT.new()
	journal_manager.name = "JournalManager"
	add_child(journal_manager)
	journal_manager.configure_dolls(level_data.get("dolls", []))
	level_state = LEVEL_STATE_CONTROLLER_SCRIPT.new()
	level_state.name = "LevelStateController"
	add_child(level_state)
	checkpoint_manager = CHECKPOINT_MANAGER_SCRIPT.new()
	checkpoint_manager.name = "CheckpointManager"
	add_child(checkpoint_manager)
	interaction_manager = INTERACTION_MANAGER_SCRIPT.new()
	interaction_manager.name = "InteractionManager"
	add_child(interaction_manager)
	inventory_manager.inventory_changed.connect(_update_journal_text)
	journal_manager.journal_changed.connect(_update_journal_text)
	level_state.flags_changed.connect(_update_journal_text)
	level_state.flags_changed.connect(_refresh_interactable_visibility)

func _create_roots() -> void:
	marker_root.visible = debug_labels_visible

func _create_environment() -> void:
	# Environment and baseline lighting are authored in AshdownLevel.tscn.
	pass

func _build_blockout() -> void:
	for room in level_data.get("rooms", []):
		_add_room(room as Dictionary)
	_add_wall_network()
	for door in level_data.get("doors", []):
		_add_door(door as Dictionary)
	_add_door_floor_bridges()
	_add_room_blockers()
	_add_room_content_scenes()
	for doll in level_data.get("dolls", []):
		_add_doll(doll as Dictionary)
	for placement in level_data.get("placements", []):
		_add_placement(placement as Dictionary)
	_refresh_interactable_visibility()

func _spawn_player() -> void:
	var start: Dictionary = level_data.get("player_start", {"x": 0.0, "y": 0.05, "z": 12.0})
	var args := OS.get_cmdline_user_args()
	if args.has("--library-benchmark"):
		start = {"x": -10.6, "y": 0.05, "z": 2.0, "yaw": 90.0}
	elif args.has("--library-benchmark-central"):
		start = {"x": -14.5, "y": 0.05, "z": 2.0, "yaw": 90.0}
	elif args.has("--library-benchmark-reading"):
		start = {"x": -17.0, "y": 0.05, "z": -4.0, "yaw": 101.0}
	elif args.has("--library-benchmark-shelf"):
		start = {"x": -13.4, "y": 0.05, "z": 7.4, "yaw": 105.0}
	player.position = Vector3(float(start["x"]), float(start["y"]), float(start["z"]))
	if player.has_method("set_start_yaw_degrees"):
		player.set_start_yaw_degrees(float(start.get("yaw", 180.0)))

func _create_ui() -> void:
	var prompt_bg := ColorRect.new()
	prompt_bg.position = Vector2(0, 304)
	prompt_bg.size = Vector2(640, 56)
	prompt_bg.color = Color(0.025, 0.025, 0.030, 0.88)
	ui_layer.add_child(prompt_bg)
	prompt_label = Label.new()
	prompt_label.position = Vector2(18, 309)
	prompt_label.size = Vector2(604, 18)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.add_theme_font_size_override("font_size", 13)
	prompt_label.add_theme_color_override("font_color", Color(0.94, 0.92, 0.84))
	ui_layer.add_child(prompt_label)
	subtitle_label = Label.new()
	subtitle_label.position = Vector2(34, 330)
	subtitle_label.size = Vector2(572, 24)
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle_label.add_theme_font_size_override("font_size", 12)
	subtitle_label.add_theme_color_override("font_color", Color(0.98, 0.96, 0.88))
	ui_layer.add_child(subtitle_label)
	reticle_label = Label.new()
	reticle_label.position = Vector2(312, 166)
	reticle_label.size = Vector2(16, 16)
	reticle_label.text = "+"
	reticle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reticle_label.add_theme_font_size_override("font_size", 12)
	reticle_label.add_theme_color_override("font_color", Color(0.82, 0.82, 0.78, 0.52))
	ui_layer.add_child(reticle_label)
	_create_journal_panel()
	_create_code_panel()
	interaction_manager.setup(player, prompt_label)
	interaction_manager.interaction_selected.connect(_handle_interaction)
	player.target_changed.connect(_on_reticle_target_changed)

func _create_journal_panel() -> void:
	journal_panel = Control.new()
	journal_panel.visible = false
	journal_panel.position = Vector2(72, 34)
	journal_panel.size = Vector2(496, 260)
	ui_layer.add_child(journal_panel)
	var bg := ColorRect.new()
	bg.size = journal_panel.size
	bg.color = Color(0.84, 0.78, 0.62, 0.98)
	journal_panel.add_child(bg)
	journal_label = Label.new()
	journal_label.position = Vector2(18, 16)
	journal_label.size = Vector2(460, 230)
	journal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	journal_label.add_theme_font_size_override("font_size", 12)
	journal_label.add_theme_color_override("font_color", Color(0.12, 0.10, 0.08))
	journal_panel.add_child(journal_label)

func _create_code_panel() -> void:
	code_panel = Control.new()
	code_panel.visible = false
	code_panel.position = Vector2(96, 104)
	code_panel.size = Vector2(448, 128)
	ui_layer.add_child(code_panel)
	var bg := ColorRect.new()
	bg.size = code_panel.size
	bg.color = Color(0.035, 0.032, 0.030, 0.96)
	code_panel.add_child(bg)
	code_label = Label.new()
	code_label.position = Vector2(12, 12)
	code_label.size = Vector2(424, 104)
	code_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	code_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	code_label.add_theme_font_size_override("font_size", 13)
	code_label.add_theme_color_override("font_color", Color(0.94, 0.88, 0.72))
	code_panel.add_child(code_label)

func _add_room(room: Dictionary) -> void:
	var x_min := float(room["x_min"])
	var x_max := float(room["x_max"])
	var z_min := float(room["z_min"])
	var z_max := float(room["z_max"])
	var floor_y := float(room["floor_y"])
	var center := Vector3((x_min + x_max) * 0.5, floor_y - 0.05, (z_min + z_max) * 0.5)
	var size := Vector3(x_max - x_min, 0.10, z_max - z_min)
	_add_box(geometry_root, "%sFloor" % String(room["id"]), center, size, _color_from_hex(String(room["color"])), true)
	_add_label3d(String(room["name"]), Vector3(center.x, floor_y + 0.08, center.z), Color(0.86, 0.82, 0.66))

func _add_wall_network() -> void:
	for line_variant in level_data.get("wall_lines", []):
		var line: Dictionary = line_variant
		var axis := String(line.get("axis", "z"))
		var value := float(line.get("value", 0.0))
		var start := float(line.get("min", 0.0))
		var finish := float(line.get("max", 0.0))
		var gaps: Array = line.get("gaps", [])
		if axis == "x":
			_add_wall_x(value, start, finish, 0.0, gaps)
		else:
			_add_wall_z(value, start, finish, 0.0, gaps)

func _add_wall_x(x: float, z_min: float, z_max: float, floor_y: float, gaps: Array) -> void:
	var cursor := z_min
	var sorted_gaps := gaps.duplicate(true)
	sorted_gaps.sort_custom(func(a, b): return float(a["center"]) < float(b["center"]))
	for gap_variant in sorted_gaps:
		var gap: Dictionary = gap_variant
		var width := maxf(float(gap["width"]), BLOCKOUT_DOOR_GAP_WIDTH)
		var start := float(gap["center"]) - width * 0.5
		var finish := float(gap["center"]) + width * 0.5
		_add_wall_x_segment(x, cursor, start, floor_y)
		cursor = finish
	_add_wall_x_segment(x, cursor, z_max, floor_y)

func _add_wall_z(z: float, x_min: float, x_max: float, floor_y: float, gaps: Array) -> void:
	var cursor := x_min
	var sorted_gaps := gaps.duplicate(true)
	sorted_gaps.sort_custom(func(a, b): return float(a["center"]) < float(b["center"]))
	for gap_variant in sorted_gaps:
		var gap: Dictionary = gap_variant
		var width := maxf(float(gap["width"]), BLOCKOUT_DOOR_GAP_WIDTH)
		var start := float(gap["center"]) - width * 0.5
		var finish := float(gap["center"]) + width * 0.5
		_add_wall_z_segment(z, cursor, start, floor_y)
		cursor = finish
	_add_wall_z_segment(z, cursor, x_max, floor_y)

func _add_wall_x_segment(x: float, z_min: float, z_max: float, floor_y: float) -> void:
	if z_max - z_min <= 0.05:
		return
	var center := Vector3(x, floor_y + WALL_HEIGHT * 0.5, (z_min + z_max) * 0.5)
	var size := Vector3(WALL_THICKNESS, WALL_HEIGHT, z_max - z_min)
	_add_box(geometry_root, "WallX", center, size, Color(0.15, 0.13, 0.12), true)

func _add_wall_z_segment(z: float, x_min: float, x_max: float, floor_y: float) -> void:
	if x_max - x_min <= 0.05:
		return
	var center := Vector3((x_min + x_max) * 0.5, floor_y + WALL_HEIGHT * 0.5, z)
	var size := Vector3(x_max - x_min, WALL_HEIGHT, WALL_THICKNESS)
	_add_box(geometry_root, "WallZ", center, size, Color(0.15, 0.13, 0.12), true)

func _add_door(door: Dictionary) -> void:
	var pos := Vector3(float(door["x"]), float(door["y"]) + 1.15, float(door["z"]))
	var state := String(door["state"])
	var yaw := float(door.get("yaw", 0.0))
	var needs_blocker := _door_needs_blocker(state)
	var blocker: Node3D = null
	if needs_blocker:
		var horizontal := int(round(yaw)) % 180 == 0
		var size := Vector3(1.35, 2.2, 0.30) if horizontal else Vector3(0.30, 2.2, 1.35)
		blocker = _add_box(geometry_root, "%sBlocker" % String(door["id"]), pos, size, Color(0.22, 0.10, 0.08), true)
	var area = _add_interactable(StringName(door["id"]), &"door", String(door["name"]), "Inspect door", pos, 0.95, Color(0.58, 0.40, 0.24))
	area.set_meta("debug_marker", true)
	var door_marker := area.get_node_or_null("Marker") as Node3D
	if door_marker != null:
		door_marker.visible = debug_labels_visible
	area.set_meta("state", state)
	area.rotation_degrees.y = yaw
	if blocker != null:
		area.set_meta("blocker_path", blocker.get_path())
		_apply_door_state(area)

func _door_needs_blocker(state: String) -> bool:
	return not state.begins_with("open") and not state.begins_with("available")

func _add_door_floor_bridges() -> void:
	for door_variant in level_data.get("doors", []):
		var door: Dictionary = door_variant
		var yaw := int(round(float(door.get("yaw", 0.0)))) % 180
		var pos := Vector3(float(door["x"]), -0.045, float(door["z"]))
		var size := Vector3(1.8, 0.08, 1.05) if yaw == 0 else Vector3(1.05, 0.08, 1.8)
		_add_box(geometry_root, "%sFloorBridge" % String(door["id"]), pos, size, Color(0.39, 0.42, 0.43), true)

func _add_room_blockers() -> void:
	_add_box(geometry_root, "VestibuleReceptionTable", Vector3(-2.9, 0.42, 11.3), Vector3(1.8, 0.84, 0.75), Color(0.34, 0.24, 0.17), true)
	_add_box(geometry_root, "MainHallWestConsole", Vector3(-6.25, 0.42, 7.05), Vector3(0.75, 0.84, 2.0), Color(0.34, 0.24, 0.17), true)
	_add_box(geometry_root, "MainHallEastConsole", Vector3(6.25, 0.42, 7.05), Vector3(0.75, 0.84, 2.0), Color(0.34, 0.24, 0.17), true)
	_add_box(geometry_root, "MainHallWestBench", Vector3(-5.7, 0.32, -4.65), Vector3(0.70, 0.64, 2.2), Color(0.30, 0.22, 0.16), true)
	_add_box(geometry_root, "MainHallEastBench", Vector3(5.7, 0.32, -4.65), Vector3(0.70, 0.64, 2.2), Color(0.30, 0.22, 0.16), true)
	_add_box(geometry_root, "ClassroomTeacherDesk", Vector3(21.7, 0.42, 6.15), Vector3(2.1, 0.84, 1.1), Color(0.35, 0.25, 0.16), true)
	_add_box(geometry_root, "ClassroomDesks", Vector3(17.0, 0.36, 1.55), Vector3(9.6, 0.72, 4.6), Color(0.31, 0.25, 0.18), true)
	_add_box(geometry_root, "DormitoryBunksWest", Vector3(-22.8, 0.65, -11.0), Vector3(1.2, 1.3, 5.4), Color(0.31, 0.24, 0.20), true)
	_add_box(geometry_root, "DormitoryBunksSouth", Vector3(-17.5, 0.65, -16.0), Vector3(5.0, 1.3, 1.2), Color(0.31, 0.24, 0.20), true)
	_add_box(geometry_root, "Boiler", Vector3(0.0, 1.25, -14.7), Vector3(2.4, 2.5, 1.8), Color(0.28, 0.10, 0.07), true)
	_add_box(geometry_root, "BathroomStalls", Vector3(11.9, 0.85, -15.5), Vector3(4.0, 1.7, 1.6), Color(0.31, 0.36, 0.36), true)
	_add_box(geometry_root, "KitchenPrepTable", Vector3(21.5, 0.42, -11.2), Vector3(3.5, 0.84, 1.2), Color(0.34, 0.27, 0.18), true)

func _add_room_content_scenes() -> void:
	for room_variant in level_data.get("rooms", []):
		var room: Dictionary = room_variant
		var scene_path := String(room.get("content_scene", ""))
		if scene_path.is_empty():
			continue
		var content_name := "%sContent" % String(room.get("id", "Room")).to_pascal_case()
		if content_root.get_node_or_null(content_name) != null:
			continue
		var packed := load(scene_path) as PackedScene
		if packed == null:
			push_error("Could not load authored room content: %s" % scene_path)
			continue
		var content := packed.instantiate()
		content.name = content_name
		content_root.add_child(content)
	_index_authored_anchors()

func _index_authored_anchors() -> void:
	authored_anchors_by_id.clear()
	for node in get_tree().get_nodes_in_group("ashdown_interaction_anchor"):
		if node == null or not is_instance_valid(node):
			continue
		var id := StringName(node.get_meta("interaction_id", &""))
		if id != &"":
			authored_anchors_by_id[id] = node
	if OS.get_cmdline_user_args().has("--library-benchmark-report"):
		print("Library authored anchors: ", authored_anchors_by_id.size())

func _bind_authored_interactable(area, id: StringName) -> void:
	if not authored_anchors_by_id.has(id):
		return
	var anchor: Node3D = authored_anchors_by_id[id]
	area.position = interactable_root.to_local(anchor.global_position)
	var marker: Node = area.get_node_or_null("Marker")
	if marker != null:
		if marker is Node3D:
			(marker as Node3D).visible = false
		marker.queue_free()
	var visual: Node3D = null
	if anchor.has_meta("visual_path"):
		var visual_path := NodePath(String(anchor.get_meta("visual_path")))
		visual = (get_node_or_null(visual_path) if visual_path.is_absolute() else anchor.get_node_or_null(visual_path)) as Node3D
	if visual != null and area.has_method("bind_authored_visual"):
		area.bind_authored_visual(
			visual,
			bool(anchor.get_meta("hide_visual_on_collect", false)),
			bool(anchor.get_meta("hide_visual_when_unavailable", false))
		)
	if OS.get_cmdline_user_args().has("--library-benchmark-report"):
		print("Bound ", id, " visual=", visual != null, " path=", visual.get_path() if visual != null else "")
	if area.has_meta("label_path"):
		var label := get_node_or_null(NodePath(String(area.get_meta("label_path")))) as Label3D
		if label != null:
			label.position = anchor.global_position + Vector3(0, area.interaction_radius + 0.28, 0)

func _add_pedestal() -> void:
	var pedestal := _add_box(geometry_root, "MemorialPedestal", Vector3(0, 0.25, 0), Vector3(1.6, 0.5, 1.6), Color(0.33, 0.31, 0.38), true)
	var top := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 1.05
	cylinder.bottom_radius = 1.05
	cylinder.height = 0.18
	top.mesh = cylinder
	top.position = Vector3(0, 0.62, 0)
	top.material_override = _make_material(Color(0.45, 0.42, 0.52), false)
	pedestal.add_child(top)
	var area = _add_interactable(&"pedestal", &"pedestal", "Memorial pedestal", "Inspect pedestal", Vector3(0, 0.95, 0), 1.15, Color(0.55, 0.48, 0.68))
	area.observation = "Seven shallow hand recesses surround a dark center."

func _add_doll(doll: Dictionary) -> void:
	var id := StringName(doll["id"])
	var pos := Vector3(float(doll["x"]), float(doll["y"]), float(doll["z"]))
	var area = _add_interactable(id, &"doll", String(doll["name"]), "Listen", pos, 0.65, _doll_color(String(id)))
	area.observation = String(doll["initial_line"])
	area.rotation_degrees.y = float(doll["rotation_y"])
	area.set_meta("age", int(doll["age"]))

func _add_placement(placement: Dictionary) -> void:
	var id := StringName(placement["id"])
	var kind := StringName(placement.get("kind", "clue"))
	var pos := Vector3(float(placement["x"]), float(placement["y"]), float(placement["z"]))
	var area = _add_interactable(
		id,
		kind,
		String(placement.get("title", id)),
		String(placement.get("prompt", "Inspect")),
		pos,
		_radius_for_kind(kind),
		_color_for_kind(kind)
	)
	area.observation = String(placement.get("observation", ""))
	if placement.has("requirements"):
		area.set_meta("requirements", placement["requirements"])
	if placement.has("flag"):
		area.set_meta("flag", StringName(placement["flag"]))
	if placement.has("puzzle_id"):
		area.set_meta("puzzle_id", String(placement["puzzle_id"]))
	if placement.has("code"):
		area.set_meta("code", String(placement["code"]))
	if placement.has("category"):
		area.set_meta("category", String(placement["category"]))
	_bind_authored_interactable(area, id)

func _add_interactable(id: StringName, kind: StringName, display_name: String, prompt_text: String, pos: Vector3, radius: float, color: Color):
	var area = INTERACTABLE_SCRIPT.new()
	area.name = String(id)
	area.interaction_id = id
	area.kind = kind
	area.display_name = display_name
	area.prompt = prompt_text
	area.position = pos
	area.interaction_radius = radius
	interactable_root.add_child(area)
	var mesh := MeshInstance3D.new()
	mesh.name = "Marker"
	var sphere := SphereMesh.new()
	sphere.radius = radius * 0.32
	sphere.height = radius * 0.64
	mesh.mesh = sphere
	mesh.material_override = _make_material(color, false)
	area.add_child(mesh)
	var label := _add_label3d(display_name, pos + Vector3(0, radius + 0.28, 0), Color(0.95, 0.92, 0.78))
	area.set_meta("label_path", label.get_path())
	interactables_by_id[id] = area
	return area

func _radius_for_kind(kind: StringName) -> float:
	match kind:
		&"door":
			return 0.95
		&"doll":
			return 0.65
		&"pedestal":
			return 1.10
		&"puzzle", &"container", &"trigger":
			return 0.75
		_:
			return 0.55

func _color_for_kind(kind: StringName) -> Color:
	match kind:
		&"door":
			return Color(0.58, 0.40, 0.24)
		&"doll":
			return Color(0.50, 0.50, 0.50)
		&"pedestal":
			return Color(0.55, 0.48, 0.68)
		&"puzzle":
			return Color(0.64, 0.55, 0.30)
		&"container":
			return Color(0.50, 0.34, 0.18)
		&"trigger":
			return Color(0.70, 0.64, 0.42)
		&"item":
			return Color(0.34, 0.55, 0.75)
		_:
			return Color(0.62, 0.58, 0.42)

func _refresh_interactable_visibility() -> void:
	if content_root != null:
		for content in content_root.get_children():
			if content.has_method("apply_gameplay_state"):
				content.apply_gameplay_state(level_state.flags)
	for area in interactables_by_id.values():
		if area != null and is_instance_valid(area):
			_apply_interactable_visibility(area)
			if area.kind == &"door":
				_apply_door_state(area)

func _apply_interactable_visibility(area) -> void:
	if area.has_meta("collected") and bool(area.get_meta("collected")):
		return
	var requirements_met := true
	for requirement in area.get_meta("requirements", []):
		if not level_state.has_flag(StringName(requirement)):
			requirements_met = false
			break
	area.visible = requirements_met
	area.monitoring = requirements_met
	area.monitorable = requirements_met
	area.input_ray_pickable = requirements_met
	if area.has_method("set_visual_available"):
		area.set_visual_available(requirements_met)
	if area.has_meta("label_path"):
		var label := get_node_or_null(NodePath(String(area.get_meta("label_path"))))
		if label != null:
			label.visible = requirements_met and debug_labels_visible

func _apply_door_state(area) -> void:
	if not area.has_meta("blocker_path"):
		return
	var blocker := get_node_or_null(NodePath(String(area.get_meta("blocker_path"))))
	if blocker == null:
		return
	var blocks := _door_state_blocks(String(area.get_meta("state", "")))
	blocker.visible = blocks
	_set_collision_enabled(blocker, blocks)

func _door_state_blocks(state: String) -> bool:
	match state:
		"locks_after_trigger":
			return level_state.has_flag(&"fire_started")
		"requires_brass_key":
			return not level_state.has_flag(&"classroom_unlocked")
		"four_symbol_lock":
			return not level_state.has_flag(&"dormitory_unlocked")
		"requires_valve_wheel":
			return not level_state.has_flag(&"boiler_wheel_installed")
		"requires_bathroom_key":
			return not level_state.has_flag(&"bathroom_unlocked")
		"fire_blocked":
			return not level_state.has_flag(&"kitchen_fire_extinguished")
		"opens_from_boiler_side":
			return not level_state.has_flag(&"dormitory_unlocked")
		"opens_after_shutdown":
			return not level_state.has_flag(&"boiler_disabled")
		"jammed_until_pushed":
			return not level_state.has_flag(&"bathroom_unlocked")
		_:
			return not state.begins_with("open") and not state.begins_with("available")

func _set_collision_enabled(node: Node, enabled: bool) -> void:
	for child in node.get_children():
		if child is CollisionShape3D:
			(child as CollisionShape3D).disabled = not enabled
		_set_collision_enabled(child, enabled)

func _handle_interaction(target) -> void:
	match target.kind:
		&"doll":
			journal_manager.record_whisper(target.interaction_id, target.display_name)
			_show_subtitle('%s: "%s"' % [target.display_name, target.observation])
		&"pedestal":
			_show_subtitle(target.observation)
		&"door":
			_handle_door(target)
		&"puzzle":
			_open_code_panel(target)
		&"container":
			_handle_container(target)
		&"trigger":
			_handle_trigger(target)
		&"item":
			_collect_evidence(target)
		&"clue":
			_collect_evidence(target)
		&"observation":
			journal_manager.record_observation(target.interaction_id, target.display_name)
			_show_subtitle(target.observation)
		_:
			_show_subtitle(target.observation)
	_update_journal_text()

func _collect_evidence(target) -> void:
	var added: bool = inventory_manager.collect_evidence(target.interaction_id, target.display_name, target.observation)
	journal_manager.record_clue(target.interaction_id, target.display_name, target.observation)
	if target.has_meta("flag"):
		level_state.set_flag(StringName(target.get_meta("flag")), true)
	_hide_collected_interactable(target)
	if added:
		_show_subtitle("Recorded evidence: %s. %s" % [target.display_name, target.observation])
	else:
		_show_subtitle("%s is already recorded." % target.display_name)

func _hide_collected_interactable(target) -> void:
	target.visible = false
	target.monitoring = false
	target.monitorable = false
	target.input_ray_pickable = false
	target.set_meta("collected", true)
	target.remove_from_group("ashdown_interactable")
	_set_collision_enabled(target, false)
	target.set_highlighted(false)
	if target.has_method("collect_visual"):
		target.collect_visual()
	if target.has_meta("label_path"):
		var label := get_node_or_null(NodePath(String(target.get_meta("label_path"))))
		if label != null:
			label.visible = false
	if interaction_manager != null:
		interaction_manager.clear_target()
		call_deferred("_clear_interaction_target_deferred")

func _clear_interaction_target_deferred() -> void:
	if interaction_manager != null:
		interaction_manager.clear_target()

func _handle_door(target) -> void:
	var state := String(target.get_meta("state", "unknown"))
	_show_subtitle(level_state.describe_door(target.display_name, state))

func _handle_container(target) -> void:
	if target.has_meta("flag") and not level_state.has_flag(StringName(target.get_meta("flag"))):
		level_state.set_flag(StringName(target.get_meta("flag")), true)
	_show_subtitle(target.observation)
	_refresh_interactable_visibility()

func _handle_trigger(target) -> void:
	if target.interaction_id == &"H04":
		if not level_state.has_flag(&"fire_started"):
			level_state.start_fire()
			_collect_evidence(target)
			_show_subtitle(target.observation)
		else:
			_show_subtitle("The register is already in your journal.")
		return
	if target.has_meta("flag"):
		level_state.set_flag(StringName(target.get_meta("flag")), true)
	_show_subtitle(target.observation)

func _open_code_panel(target) -> void:
	active_code_puzzle = {
		"id": String(target.get_meta("puzzle_id", target.interaction_id)),
		"title": target.display_name,
		"code": String(target.get_meta("code", "")),
		"observation": target.observation
	}
	code_mode = true
	code_entry = ""
	_set_player_input_locked(true)
	code_panel.visible = true
	_update_code_text()

func _handle_code_input(event: InputEvent) -> void:
	if event.is_action_pressed("release_mouse"):
		_close_code_panel("Code entry closed.")
		return
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		var key_event := event as InputEventKey
		var value := OS.get_keycode_string(key_event.keycode)
		if value in ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]:
			code_entry += value
			var needed := String(active_code_puzzle.get("code", ""))
			if code_entry.length() >= needed.length():
				if code_entry == needed:
					_complete_active_code_puzzle()
				else:
					_close_code_panel("%s rejects that sequence and resets." % String(active_code_puzzle.get("title", "The puzzle")))
			else:
				_update_code_text()

func _complete_active_code_puzzle() -> void:
	match String(active_code_puzzle.get("id", "")):
		"library_catalog":
			level_state.complete_library_catalog()
			_close_code_panel("The catalog drawers settle into Moon, Bird, Train. The librarian desk unlocks.")
		"library_shelf":
			level_state.complete_library_code()
			_close_code_panel("The shelf slides east. A photograph and inspection code are now reachable.")
		"dormitory_music":
			level_state.complete_dormitory_music()
			_close_code_panel("The toy trunk opens. Mira's ribbon and Dev's train wheel are now reachable.")
		"boiler_pressure":
			level_state.complete_boiler_pressure()
			_close_code_panel("Steam routes to the bathroom, then the service line shuts down. Boiler records are now reachable.")
		_:
			_close_code_panel("%s clicks open." % String(active_code_puzzle.get("title", "The puzzle")))

func _close_code_panel(message: String) -> void:
	code_mode = false
	code_panel.visible = false
	active_code_puzzle = {}
	_set_player_input_locked(false)
	_show_subtitle(message)
	_update_journal_text()

func _update_code_text() -> void:
	var title := String(active_code_puzzle.get("title", "Code"))
	var needed := String(active_code_puzzle.get("code", ""))
	var missing := maxi(0, needed.length() - code_entry.length())
	code_label.text = "%s\n%s\n[%s]" % [title, String(active_code_puzzle.get("observation", "Enter the sequence.")), code_entry + "_".repeat(missing)]

func _toggle_journal() -> void:
	if journal_panel.visible:
		_close_journal()
		return
	_set_player_input_locked(true)
	journal_panel.visible = true
	_update_journal_text()

func _close_journal() -> void:
	journal_panel.visible = false
	_set_player_input_locked(false)

func _update_journal_text() -> void:
	if journal_label == null:
		return
	journal_label.text = journal_manager.build_text(inventory_manager, level_state.flags)

func _set_player_input_locked(value: bool) -> void:
	if player != null:
		player.set_input_locked(value)
	if interaction_manager != null:
		interaction_manager.set_interaction_enabled(not value)

func _show_subtitle(text: String) -> void:
	if subtitle_label != null:
		subtitle_label.text = text

func _on_reticle_target_changed(target) -> void:
	if reticle_label == null:
		return
	var has_target := target != null and is_instance_valid(target)
	reticle_label.text = "+" if not has_target else "[+]"
	reticle_label.add_theme_color_override(
		"font_color",
		Color(1.0, 0.72, 0.24, 0.95) if has_target else Color(0.82, 0.82, 0.78, 0.52)
	)

func _toggle_debug_labels() -> void:
	debug_labels_visible = not debug_labels_visible
	if marker_root != null:
		marker_root.visible = debug_labels_visible
	for area in interactables_by_id.values():
		if area != null and is_instance_valid(area) and bool(area.get_meta("debug_marker", false)):
			var marker := area.get_node_or_null("Marker") as Node3D
			if marker != null:
				marker.visible = debug_labels_visible
	_refresh_interactable_visibility()
	_show_subtitle("Debug labels on." if debug_labels_visible else "Debug labels off.")

func _add_box(parent: Node, name: String, pos: Vector3, size: Vector3, color: Color, collision: bool) -> Node3D:
	var node: Node3D = StaticBody3D.new() if collision else Node3D.new()
	node.name = name
	node.position = pos
	parent.add_child(node)
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _make_material(color, false)
	node.add_child(mesh_instance)
	if collision:
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = size
		shape.shape = box
		node.add_child(shape)
	return node

func _add_label3d(text: String, pos: Vector3, color: Color) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.position = pos
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = color
	label.font_size = 24
	label.outline_size = 6
	label.outline_modulate = Color(0.02, 0.018, 0.015)
	marker_root.add_child(label)
	return label

func _make_material(color: Color, unshaded: bool) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED if unshaded else BaseMaterial3D.SHADING_MODE_PER_PIXEL
	return mat

func _color_from_hex(value: String) -> Color:
	return Color.html("#%s" % value)

func _doll_color(id: String) -> Color:
	match id:
		"mira":
			return Color(0.66, 0.22, 0.25)
		"leela":
			return Color(0.45, 0.35, 0.62)
		"arun":
			return Color(0.14, 0.22, 0.46)
		"dev":
			return Color(0.30, 0.28, 0.24)
		"sana":
			return Color(0.28, 0.48, 0.48)
		"kabir":
			return Color(0.25, 0.34, 0.70)
		"nila":
			return Color(0.82, 0.78, 0.58)
		_:
			return Color(0.50, 0.50, 0.50)
