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
var authored_index_errors: Array[String] = []
var debug_labels_visible := false

var inventory_manager
var journal_manager
var level_state
var checkpoint_manager
var interaction_manager
@onready var geometry_root: Node3D = $HouseBlockout/BlockoutGeometry
@onready var content_root: Node3D = $AuthoredRoomContent
@onready var interactable_root: Node3D = $HouseBlockout/Interactables
@onready var marker_root: Node3D = $HouseBlockout/Labels
@onready var player: CharacterBody3D = $Player
@onready var ui_layer: CanvasLayer = $UI
@onready var hud: AshdownHUD = $UI/AshdownHUD
@onready var prompt_label: Label = $UI/AshdownHUD/BottomMargin/VBox/PromptLabel
@onready var subtitle_label: Label = $UI/AshdownHUD/BottomMargin/VBox/SubtitleLabel
@onready var reticle_label: Label = $UI/AshdownHUD/ReticleLabel
@onready var journal_panel: Control = $UI/AshdownHUD/JournalPanel
@onready var journal_label: Label = $UI/AshdownHUD/JournalPanel/Margin/VBox/JournalLabel
@onready var code_panel: Control = $UI/AshdownHUD/CodePanel
@onready var code_label: Label = $UI/AshdownHUD/CodePanel/Margin/CodeLabel

func _ready() -> void:
	_ensure_inputs()
	_load_level_data()
	_create_managers()
	_create_roots()
	_create_environment()
	_build_blockout()
	_spawn_player()
	_setup_ui()
	_apply_graphics_settings()
	_show_subtitle("Ashdown House is quiet. Find the register in the Main Hall.")
	if OS.get_cmdline_user_args().has("--library-benchmark-self-test"):
		call_deferred("_run_library_benchmark_self_test")
	elif OS.get_cmdline_user_args().has("--classroom-slice-self-test"):
		call_deferred("_run_classroom_slice_self_test")
	elif OS.get_cmdline_user_args().has("--capture-hd2d-ui"):
		call_deferred("_capture_hd2d_ui")
	elif OS.get_cmdline_user_args().has("--capture-library-phase2"):
		call_deferred("_capture_library_phase2")
	elif OS.get_cmdline_user_args().has("--capture-arrival-phase3"):
		call_deferred("_capture_arrival_phase3")
	elif OS.get_cmdline_user_args().has("--capture-classroom-phase4"):
		call_deferred("_capture_classroom_phase4")

func _run_library_benchmark_self_test() -> void:
	var failures: Array[String] = []
	failures.append_array(_collect_authored_validation_errors())
	var required_level_nodes: Array[NodePath] = [
		^"HouseBlockout/BlockoutGeometry", ^"AuthoredRoomContent",
		^"HouseBlockout/Interactables", ^"HouseBlockout/Labels",
		^"WorldEnvironment", ^"DirectionalLight3D", ^"Player", ^"UI"
	]
	for node_path in required_level_nodes:
		if get_node_or_null(node_path) == null:
			failures.append("missing authored level node %s" % node_path)
	if hud == null:
		failures.append("authored native-resolution HUD was not instantiated")
	if get_viewport().scaling_3d_mode != Viewport.SCALING_3D_MODE_NEAREST:
		failures.append("3D scaling mode is not nearest")
	if not is_equal_approx(get_viewport().scaling_3d_scale, GraphicsSettings.get_world_scale()):
		failures.append("3D scaling does not match the selected graphics preset")
	if ProjectSettings.get_setting("display/window/size/viewport_width", 0) != 1280:
		failures.append("root viewport width is not 1280")
	if ProjectSettings.get_setting("display/window/stretch/mode", "") != "canvas_items":
		failures.append("native-resolution CanvasItem stretch is not configured")
	for collection_name in ["doors", "dolls", "placements"]:
		for entry_variant in level_data.get(collection_name, []):
			var entry: Dictionary = entry_variant
			var authored_id := StringName(entry.get("id", ""))
			if authored_id != &"" and not interactables_by_id.has(authored_id):
				failures.append("missing authored %s interactable %s" % [collection_name, authored_id])
	var required_player_nodes: Array[NodePath] = [
		^"CollisionShape3D", ^"VisualRoot/PrototypeBody", ^"VisualRoot/Face",
		^"VisualRoot/InvestigatorVisual", ^"VisualRoot/LanternLight",
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
		var book_dressing := library_content.get_node_or_null(^"Furniture/HD2DBookDressing")
		if book_dressing == null or book_dressing.get_child_count() < 8:
			failures.append("HD-2D Library book dressing is missing or incomplete")
		for old_books in library_content.find_children("Books_*", "MeshInstance3D", true, false):
			if (old_books as MeshInstance3D).visible:
				failures.append("old Library filler block is still visible: %s" % old_books.get_path())
				break
		var ceiling := library_content.get_node_or_null(^"Architecture/LibraryCeiling") as Node3D
		if ceiling == null or not is_equal_approx(ceiling.position.y, 4.18):
			failures.append("Library ceiling is not aligned to the 4.2 m shell")
		for wall_path in [
			^"Architecture/NorthWallFinish", ^"Architecture/WestWallFinish",
			^"Architecture/EastWallNorthFinish", ^"Architecture/EastWallSouthFinish",
			^"Architecture/SouthWallWestFinish", ^"Architecture/SouthWallEastFinish"
		]:
			var wall := library_content.get_node_or_null(wall_path) as Node3D
			if wall == null or not is_equal_approx(wall.position.y, 2.1):
				failures.append("Library wall is not aligned to raised ceiling: %s" % wall_path)
		for fixture_path in [^"Furniture/CeilingFixture", ^"Furniture/@Node3D@65", ^"Furniture/@Node3D@67"]:
			var fixture := library_content.get_node_or_null(fixture_path) as Node3D
			if fixture == null or not is_equal_approx(fixture.position.y, 4.0):
				failures.append("Library ceiling fixture is shifted: %s" % fixture_path)
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
		elif authored_anchors_by_id.has(id):
			var anchor := authored_anchors_by_id[id] as Node3D
			var interactable = interactables_by_id[id]
			if anchor != null and interactable.authored_visual != null:
				var anchor_gap := anchor.global_position.distance_to(interactable.authored_visual.global_position)
				if anchor_gap > 1.6:
					failures.append("interaction anchor %s is %.2f m from its prop" % [id, anchor_gap])
	var library_scene_found := false
	for room_variant in level_data.get("rooms", []):
		var room: Dictionary = room_variant
		if String(room.get("id", "")) == "library":
			library_scene_found = String(room.get("content_scene", "")) == "res://scenes/levels/ashdown/rooms/LibraryBenchmark.tscn"
	if not library_scene_found:
		failures.append("Library content_scene is not configured")
	var vestibule_content := content_root.get_node_or_null("VestibuleContent")
	var main_hall_content := content_root.get_node_or_null("MainHallContent")
	for content_pair in [
		["Vestibule", vestibule_content],
		["Main Hall", main_hall_content]
	]:
		var content_name: String = content_pair[0]
		var content: Node = content_pair[1]
		if content == null:
			failures.append("authored %s content was not instantiated" % content_name)
			continue
		for branch in [^"Architecture", ^"Furniture", ^"InteractionAnchors", ^"Lighting", ^"Atmosphere"]:
			if content.get_node_or_null(branch) == null:
				failures.append("missing authored %s branch %s" % [content_name, branch])
	var arrival_anchors: Array[StringName] = [&"V03", &"V08", &"V09", &"H01", &"H04", &"H09", &"H10"]
	for id in arrival_anchors:
		if not authored_anchors_by_id.has(id):
			failures.append("missing authored arrival anchor %s" % id)
		elif interactables_by_id.has(id) and interactables_by_id[id].authored_visual == null:
			failures.append("arrival anchor %s did not bind its visible prop" % id)
	var register = interactables_by_id.get(&"H04")
	if register == null:
		failures.append("house register interactable is missing")
	else:
		_handle_trigger(register)
		if not level_state.has_flag(&"fire_started"):
			failures.append("taking the register did not start the fire phase")
		if register.visible or register.is_in_group("ashdown_interactable"):
			failures.append("taken register remained visible or targetable")
		if register.authored_visual != null and register.authored_visual.visible:
			failures.append("taken register prop remained visible")
		if main_hall_content != null:
			var smoke := main_hall_content.get_node_or_null(^"Atmosphere/SmokeParticles") as GPUParticles3D
			var glow := main_hall_content.get_node_or_null(^"Atmosphere/FireGlow") as OmniLight3D
			if smoke == null or not smoke.visible or not smoke.emitting:
				failures.append("register trigger did not activate Main Hall smoke")
			if glow == null or not glow.visible:
				failures.append("register trigger did not activate Main Hall fire glow")
	if not is_equal_approx(float(player.get("normal_spring_length")), 2.65):
		failures.append("camera spring length is not 2.65 m")
	if not is_equal_approx(float(player.get("camera_pivot_height")), 1.48):
		failures.append("camera pivot is not 1.48 m")
	var player_visual_root := player.get_node_or_null(^"VisualRoot") as Node3D
	if player_visual_root == null or not is_equal_approx(player_visual_root.position.y, -0.14):
		failures.append("player visual root is not using the lowered presentation offset")
	var player_collision := player.get_node_or_null(^"CollisionShape3D") as CollisionShape3D
	if player_collision == null or not is_equal_approx(player_collision.position.y, 0.82):
		failures.append("player collision moved during the presentation-only scale correction")
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

func _run_classroom_slice_self_test() -> void:
	var failures: Array[String] = []
	failures.append_array(_collect_authored_validation_errors())
	var classroom := content_root.get_node_or_null("ClassroomContent")
	if classroom == null:
		failures.append("authored Classroom content was not instantiated")
	else:
		for branch in [^"Architecture", ^"Furniture", ^"InteractionAnchors", ^"Interactables", ^"Lighting", ^"Atmosphere"]:
			if classroom.get_node_or_null(branch) == null:
				failures.append("missing authored Classroom branch %s" % branch)
	var required: Array[StringName] = [
		&"C01", &"C04", &"C06", &"C07", &"C08", &"C09", &"C16",
		&"C18", &"C19", &"C20", &"C21", &"C22", &"C23", &"C24",
		&"C25", &"C26", &"C29"
	]
	for id in required:
		if not authored_anchors_by_id.has(id):
			failures.append("missing Classroom anchor %s" % id)
		if not interactables_by_id.has(id):
			failures.append("missing Classroom interactable %s" % id)
		elif interactables_by_id[id].authored_visual == null:
			failures.append("Classroom interactable %s has no bound prop" % id)
	level_state.set_flag(&"classroom_unlocked", true)
	_refresh_interactable_visibility()
	for fuse_id in [&"C07", &"C08", &"C09"]:
		var fuse = interactables_by_id.get(fuse_id)
		if fuse == null or not fuse.visible:
			failures.append("Classroom fuse %s did not become collectible" % fuse_id)
		else:
			_collect_evidence(fuse)
	var fuse_panel = interactables_by_id.get(&"C06")
	if fuse_panel == null or not fuse_panel.visible:
		failures.append("fuse panel did not unlock after all three fuses")
	level_state.complete_classroom_fuses()
	_refresh_interactable_visibility()
	var projector = interactables_by_id.get(&"C04")
	if projector == null or not projector.visible:
		failures.append("projector did not become usable after fuse solution")
	else:
		_handle_container(projector)
	if not level_state.has_flag(&"projector_revealed"):
		failures.append("projector interaction did not reveal the projection")
	if classroom != null:
		var projector_light := classroom.get_node_or_null(^"Lighting/ProjectorLight") as SpotLight3D
		var stars := classroom.get_node_or_null(^"Furniture/C05_ProjectorScreen/ProjectionStars") as Node3D
		if projector_light == null or not projector_light.visible:
			failures.append("projector light did not activate")
		if stars == null or not stars.visible:
			failures.append("projected star evidence did not appear")
	var cards = interactables_by_id.get(&"C19")
	if cards == null or not cards.visible:
		failures.append("name cards were not available")
	else:
		_collect_evidence(cards)
	level_state.complete_classroom_seating()
	_refresh_interactable_visibility()
	for reward_id in [&"C22", &"C23", &"C24", &"C25"]:
		var reward = interactables_by_id.get(reward_id)
		if reward == null or not reward.visible:
			failures.append("teacher drawer reward %s did not unlock" % reward_id)
	var bathroom_key = interactables_by_id.get(&"C23")
	var dormitory_code = interactables_by_id.get(&"C25")
	var extinguisher = interactables_by_id.get(&"C29")
	if bathroom_key != null: _collect_evidence(bathroom_key)
	if dormitory_code != null: _collect_evidence(dormitory_code)
	if extinguisher != null: _collect_evidence(extinguisher)
	for flag in [&"bathroom_unlocked", &"dormitory_unlocked", &"kitchen_fire_extinguished"]:
		if not level_state.has_flag(flag):
			failures.append("Classroom progression did not set %s" % flag)
	if failures.is_empty():
		print("CLASSROOM_SLICE_SELF_TEST: PASS")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error("Classroom slice self-test: %s" % failure)
		print("CLASSROOM_SLICE_SELF_TEST: FAIL (%d)" % failures.size())
		get_tree().quit(1)

func _unhandled_input(event: InputEvent) -> void:
	if code_mode:
		_handle_code_input(event)
		return
	if event.is_action_pressed("release_mouse"):
		get_viewport().set_input_as_handled()
		if journal_panel != null and journal_panel.visible:
			_close_journal()
		elif hud != null:
			_set_pause_visible(not hud.is_pause_visible())
		return
	if hud != null and hud.is_pause_visible():
		return
	if event.is_action_pressed("toggle_debug_labels"):
		_toggle_debug_labels()
	elif event.is_action_pressed("open_journal"):
		_toggle_journal()

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
	_add_room_content_scenes()
	_index_authored_interactables()
	_apply_level_data_to_interactables()
	for id in interactables_by_id:
		_bind_authored_interactable(interactables_by_id[id], id)
	_refresh_interactable_visibility()

func _index_authored_interactables() -> void:
	interactables_by_id.clear()
	authored_index_errors.clear()
	for node in get_tree().get_nodes_in_group("ashdown_interactable"):
		if node == null or not is_instance_valid(node):
			continue
		var id := StringName(node.get("interaction_id"))
		if id == &"":
			authored_index_errors.append("authored interactable %s has no persistent ID" % node.get_path())
		elif interactables_by_id.has(id):
			authored_index_errors.append("duplicate authored interactable ID %s" % id)
		else:
			interactables_by_id[id] = node

func _apply_level_data_to_interactables() -> void:
	for collection_name in ["doors", "dolls", "placements"]:
		for entry_variant in level_data.get(collection_name, []):
			var entry: Dictionary = entry_variant
			var id := StringName(entry.get("id", ""))
			if id == &"" or not interactables_by_id.has(id):
				continue
			var area = interactables_by_id[id]
			if collection_name == "doors":
				area.kind = &"door"
			elif collection_name == "dolls":
				area.kind = &"doll"
			elif entry.has("kind"):
				area.kind = StringName(entry["kind"])
			area.display_name = String(entry.get("title", entry.get("name", area.display_name)))
			area.prompt = String(entry.get("prompt", area.prompt))
			area.observation = String(entry.get("observation", entry.get("initial_line", area.observation)))
			for key in [&"requirements", &"flag", &"puzzle_id", &"code", &"state"]:
				if entry.has(String(key)):
					area.set_meta(key, entry[String(key)])
				elif area.has_meta(key):
					area.remove_meta(key)

func _collect_authored_validation_errors() -> Array[String]:
	var errors := authored_index_errors.duplicate()
	for id in interactables_by_id:
		var area: Node = interactables_by_id[id]
		if area.find_children("*", "CollisionShape3D", true, false).is_empty():
			errors.append("authored interactable %s has no collision shape" % id)
		for key in [&"blocker_path", &"label_path"]:
			if area.has_meta(key) and _resolve_metadata_node(area, key) == null:
				errors.append("authored interactable %s has unresolved %s" % [id, key])
	return errors

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
	elif args.has("--arrival-vestibule"):
		start = {"x": 0.0, "y": 0.05, "z": 14.7, "yaw": 180.0}
	elif args.has("--arrival-main-hall"):
		start = {"x": 0.0, "y": 0.05, "z": 6.7, "yaw": 0.0}
	elif args.has("--classroom-benchmark"):
		start = {"x": 12.2, "y": 0.05, "z": 2.0, "yaw": 270.0}
	player.position = Vector3(float(start["x"]), float(start["y"]), float(start["z"]))
	if player.has_method("set_start_yaw_degrees"):
		player.set_start_yaw_degrees(float(start.get("yaw", 180.0)))

func _setup_ui() -> void:
	interaction_manager.setup(player, prompt_label)
	interaction_manager.interaction_selected.connect(_handle_interaction)
	player.target_changed.connect(_on_reticle_target_changed)
	if hud != null:
		hud.resume_requested.connect(func(): _set_pause_visible(false))
	GraphicsSettings.settings_changed.connect(_apply_graphics_settings)

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
	area.global_position = anchor.global_position
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
		var label := _resolve_metadata_node(area, &"label_path") as Label3D
		if label != null:
			label.position = anchor.global_position + Vector3(0, area.interaction_radius + 0.28, 0)

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
		var label := _resolve_metadata_node(area, &"label_path")
		if label != null:
			label.visible = requirements_met and debug_labels_visible

func _apply_door_state(area) -> void:
	if not area.has_meta("blocker_path"):
		return
	var blocker := _resolve_metadata_node(area, &"blocker_path")
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
		var label := _resolve_metadata_node(target, &"label_path")
		if label != null:
			label.visible = false
	if interaction_manager != null:
		interaction_manager.clear_target()
		call_deferred("_clear_interaction_target_deferred")

func _resolve_metadata_node(source: Node, key: StringName) -> Node:
	if source == null or not source.has_meta(key):
		return null
	var path := NodePath(String(source.get_meta(key)))
	return get_node_or_null(path) if path.is_absolute() else source.get_node_or_null(path)

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
		get_viewport().set_input_as_handled()
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
		"classroom_fuses":
			level_state.complete_classroom_fuses()
			_close_code_panel("The 5A, 8A, and 13A fuses seat correctly. The projector circuit hums awake.")
		"classroom_seating":
			level_state.complete_classroom_seating()
			_close_code_panel("Six cards settle into two rows. The unlabelled seventh desk remains, and the teacher drawer opens.")
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
	if player.has_method("set_mouse_captured"):
		player.set_mouse_captured(false)
	journal_panel.visible = true
	_update_journal_text()

func _close_journal() -> void:
	journal_panel.visible = false
	_set_player_input_locked(false)
	if player.has_method("set_mouse_captured"):
		player.set_mouse_captured(true)

func _update_journal_text() -> void:
	if journal_label == null:
		return
	journal_label.text = journal_manager.build_text(inventory_manager, level_state.flags)

func _set_player_input_locked(value: bool) -> void:
	if player != null:
		player.set_input_locked(value)
	if interaction_manager != null:
		interaction_manager.set_interaction_enabled(not value)

func _set_pause_visible(value: bool) -> void:
	if hud == null:
		return
	hud.set_pause_visible(value)
	_set_player_input_locked(value)
	if player != null and player.has_method("set_mouse_captured"):
		player.set_mouse_captured(not value)

func _apply_graphics_settings() -> void:
	var world_environment := $WorldEnvironment as WorldEnvironment
	if world_environment != null and world_environment.environment != null:
		world_environment.environment.adjustment_enabled = true
		world_environment.environment.adjustment_brightness = GraphicsSettings.brightness
	var key_light := $DirectionalLight3D as DirectionalLight3D
	if key_light != null:
		key_light.shadow_enabled = GraphicsSettings.shadows_enabled
	for fog_node in get_tree().get_nodes_in_group("ashdown_fog"):
		if fog_node is Node3D:
			(fog_node as Node3D).visible = GraphicsSettings.fog_enabled
	if hud != null:
		hud.sync_settings()

func _capture_hd2d_ui() -> void:
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = Vector2i(1280, 720)
	_set_pause_visible(true)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://captures"))
	var path := ProjectSettings.globalize_path("res://captures/phase1_native_ui.png")
	var error := get_viewport().get_texture().get_image().save_png(path)
	print("HD2D_UI_CAPTURE: %s (%s)" % [path, error_string(error)])
	get_tree().quit(0 if error == OK else 1)

func _capture_library_phase2() -> void:
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = Vector2i(1280, 720)
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://captures"))
	var args := OS.get_cmdline_user_args()
	var view := "entrance"
	if args.has("--library-benchmark-central"):
		view = "central"
	elif args.has("--library-benchmark-reading"):
		view = "reading"
	elif args.has("--library-benchmark-shelf"):
		view = "shelf"
	var path := ProjectSettings.globalize_path("res://captures/phase2_library_%s.png" % view)
	var error := get_viewport().get_texture().get_image().save_png(path)
	print("LIBRARY_PHASE2_CAPTURE: %s (%s)" % [path, error_string(error)])
	get_tree().quit(0 if error == OK else 1)

func _capture_arrival_phase3() -> void:
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = Vector2i(1280, 720)
	var args := OS.get_cmdline_user_args()
	var view := "vestibule"
	if args.has("--arrival-main-hall"):
		view = "main_hall"
	if args.has("--arrival-fire"):
		view += "_fire"
		level_state.start_fire()
		await get_tree().create_timer(1.2).timeout
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://captures"))
	var path := ProjectSettings.globalize_path("res://captures/phase3_%s.png" % view)
	var error := get_viewport().get_texture().get_image().save_png(path)
	print("ARRIVAL_PHASE3_CAPTURE: %s (%s)" % [path, error_string(error)])
	get_tree().quit(0 if error == OK else 1)

func _capture_classroom_phase4() -> void:
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = Vector2i(1280, 720)
	var args := OS.get_cmdline_user_args()
	var view := "entrance"
	level_state.set_flag(&"classroom_unlocked", true)
	if args.has("--classroom-powered"):
		view = "powered"
		level_state.start_fire()
		level_state.complete_classroom_fuses()
		level_state.set_flag(&"projector_revealed", true)
		level_state.complete_classroom_seating()
	_refresh_interactable_visibility()
	if args.has("--classroom-powered"):
		await get_tree().create_timer(0.8).timeout
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://captures"))
	var path := ProjectSettings.globalize_path("res://captures/phase4_classroom_%s.png" % view)
	var error := get_viewport().get_texture().get_image().save_png(path)
	print("CLASSROOM_PHASE4_CAPTURE: %s (%s)" % [path, error_string(error)])
	get_tree().quit(0 if error == OK else 1)

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
