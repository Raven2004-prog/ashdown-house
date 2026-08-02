extends Node2D

enum Phase {
	SAFE_EXPLORE,
	FIRE_STARTING,
	INVESTIGATION,
	PEDESTAL_READY,
	CARRYING_ANCHOR,
	RELEASE_CUTSCENE,
	COMPLETE,
	FAILED
}

enum TimingMode {
	STORY,
	STANDARD,
	DREAD
}

const TILE := 32
const ROOM_SIZE := Vector2(1024, 768)
const VIEW_SIZE := Vector2(640, 360)
const INTERACT_DISTANCE := 56.0
const PLAYER_START := Vector2(512, 690)
const NURSERY_ART_PATH := "res://art/approved/nursery_2_5d/"
const ITEM_ORDER := [&"ribbon", &"shoe", &"cloth", &"marble", &"storybook", &"key"]
const DOLL_ORDER := [&"mira", &"kabir", &"noor", &"sami", &"leela", &"tara", &"anchor"]
const RECORDED_NAMES := ["Mira", "Kabir", "Noor", "Sami", "Leela", "Tara"]
const ITEM_LOCATION := {
	&"ribbon": "bed",
	&"shoe": "wardrobe",
	&"cloth": "washstand",
	&"marble": "table",
	&"storybook": "bookshelf",
	&"key": "exit_key"
}
const DOLL_FLAMES := {
	&"mira": &"bed_fire",
	&"kabir": &"east_window_fire",
	&"noor": &"wash_fire",
	&"sami": &"table_fire",
	&"leela": &"shelf_fire",
	&"tara": &"exit_fire"
}
const TIMING_LABELS := {
	TimingMode.STORY: "Story",
	TimingMode.STANDARD: "Standard",
	TimingMode.DREAD: "Dread"
}
const INITIAL_CLUES := {
	&"entrance": "The corridor behind you is still there, but the air feels wrong.",
	&"exit": "The chain sits beyond the door. From this side, there is nothing to unlock.",
	&"alarm": "The alarm is open. The battery compartment is empty.",
	&"pedestal": "Seven shallow impressions surround the empty center.",
	&"vent": "A weak grey haze gathers around the eastern vent.",
	&"west_window": "The window is barred and too high for a child.",
	&"east_window": "The east window is barred. Small hand marks darken the sill."
}
const INVESTIGATION_CLUES := {
	&"photo": "The photograph shows seven indistinct children. The reverse lists only six names.",
	&"name_card": "Mira. Kabir. Noor. Sami. Leela. Tara. Six names for seven figures.",
	&"ledger": "The attendance ledger repeats the same six names. A pressed line dents the page below Tara.",
	&"alarm": "The alarm could not have sounded. Someone removed the battery before the fire.",
	&"exit": "Tara's key would fit the lock, but the chain is secured outside the room.",
	&"vent": "Smoke comes from the vent first, spreading low across the floor.",
	&"west_window": "The west window bars are old and bolted through the frame.",
	&"east_window": "The latch is above a child's reach. Kabir's doll still faces it.",
	&"pedestal": "Six outer marks wait for names. One center mark waits for the child the record forgot."
}
const EVIDENCE_TEXT := {
	&"ribbon": "A blue ribbon is tucked beneath the bed pillow. Mira hid where the air was cooler.",
	&"shoe": "A missing shoe rests at the bottom of the wardrobe. The scuffed toe points toward the high window.",
	&"cloth": "A wet cloth lies in the washstand basin. The stitched N is almost washed out.",
	&"marble": "A red marble waits beneath the activity table, exactly where a small hand might reach.",
	&"storybook": "A storybook is wedged behind the shelf. Leela's name is written inside the cover.",
	&"key": "A bent brass key lies beneath the chained exit. It fits the lock, not the chain."
}

@onready var map: Node2D = $Map
@onready var world: Node2D = $WorldYSort
@onready var effects: Node2D = $Effects
@onready var player: CharacterBody2D = $WorldYSort/Player
@onready var ui_layer: CanvasLayer = $UI

var phase: Phase = Phase.SAFE_EXPLORE
var timing_mode: TimingMode = TimingMode.STANDARD
var interactables: Array[AshInteractable] = []
var interactable_by_id: Dictionary = {}
var fire_nodes: Dictionary = {}
var items: Dictionary = {}
var dolls: Dictionary = {}
var inventory: Array[StringName] = []
var selected_index := 0
var resolved_dolls: Dictionary = {}
var discovered_clues: Dictionary = {}
var wrong_attempts_by_doll: Dictionary = {}
var has_music_box_open := false
var anchor_carried := false
var timer_max := 300.0
var time_remaining := 300.0
var timer_draining := false
var paused := false
var game_over := false
var current_interactable: AshInteractable = null
var active_doll: AshInteractable = null
var document_open := false
var journal_open := false
var settings_open := false
var credits_open := false
var main_menu_open := false
var pause_menu_open := false
var menu_hidden_by_overlay := ""
var hud_expanded := false
var reduced_flashing := false
var show_numeric_timer := true
var text_scale := 1.0
var smoke_stage := 0
var smoke_pulse_timer := 0.0
var checkpoint_data: Dictionary = {}
var font_sized_controls: Array[Control] = []

var objective_label: Label
var prompt_label: Label
var subtitle_label: Label
var controls_label: Label
var timing_label: Label
var smoke_label: Label
var timer_bar: ProgressBar
var timer_label: Label
var inventory_slots: Array[Label] = []
var journal_panel: Control
var journal_label: Label
var document_panel: Control
var document_title_label: Label
var document_body_label: Label
var doll_menu_panel: Control
var doll_menu_label: Label
var settings_panel: Control
var settings_label: Label
var credits_panel: Control
var credits_label: Label
var main_menu_panel: Control
var pause_menu_panel: Control
var failure_panel: Control
var top_hud_panel: ColorRect
var bottom_hud_panel: ColorRect
var hud_toggle_button: Button
var top_hud_controls: Array[Control] = []
var bottom_hud_controls: Array[Control] = []
var smoke_overlay: ColorRect
var fire_overlay: ColorRect

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_inputs()
	_load_data()
	_create_camera()
	_create_room()
	_create_effects()
	_create_ui()
	_set_timing_mode(TimingMode.STANDARD)
	_reset_run_state()
	_show_subtitle("The nursery waits. Find what began the fire.")
	_open_main_menu()

func _process(delta: float) -> void:
	if game_over:
		return
	_update_current_interactable()
	if smoke_pulse_timer > 0.0:
		smoke_pulse_timer = maxf(0.0, smoke_pulse_timer - delta)
		_update_effect_overlays()
	if _timer_should_drain():
		time_remaining = maxf(0.0, time_remaining - delta)
		_apply_timer_thresholds()
		if time_remaining <= 0.0 and timing_mode != TimingMode.STORY:
			_fail_level()
	_update_ui()

func _unhandled_input(event: InputEvent) -> void:
	if settings_open:
		_handle_settings_input(event)
		return
	if credits_open:
		if event.is_action_pressed("open_credits") or event.is_action_pressed("close_overlay") or event.is_action_pressed("pause"):
			_toggle_credits()
		return
	if game_over:
		return
	if event.is_action_pressed("pause"):
		_toggle_pause()
		return
	if main_menu_open:
		return
	if paused:
		return
	if event.is_action_pressed("close_overlay"):
		_close_top_overlay()
		return
	if document_open:
		if event.is_action_pressed("interact"):
			_close_top_overlay()
		return
	if journal_open and event.is_action_pressed("open_memory"):
		_toggle_journal()
		return
	if active_doll != null:
		_handle_doll_menu_input(event)
		return
	if event.is_action_pressed("interact"):
		_interact_current()
	elif event.is_action_pressed("offer_item"):
		_open_offer_for_current()
	elif event.is_action_pressed("open_inventory"):
		_show_inventory_details()
	elif event.is_action_pressed("open_memory"):
		_toggle_journal()
	elif event.is_action_pressed("request_hint"):
		_show_hint()
	elif event.is_action_pressed("cycle_inventory"):
		_cycle_inventory(1)
	elif event.is_action_pressed("cycle_inventory_back"):
		_cycle_inventory(-1)
	elif event.is_action_pressed("cycle_timing_mode"):
		_cycle_timing_mode()
	elif event.is_action_pressed("open_settings"):
		_toggle_settings()
	elif event.is_action_pressed("open_credits"):
		_toggle_credits()
	elif event.is_action_pressed("toggle_hud"):
		_toggle_hud()
	elif event.is_action_pressed("run_self_test"):
		_run_self_test()

func _ensure_inputs() -> void:
	var keys: Dictionary = {
		"move_up": [KEY_W, KEY_UP],
		"move_down": [KEY_S, KEY_DOWN],
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"interact": [KEY_E, KEY_ENTER],
		"offer_item": [KEY_F, KEY_SPACE],
		"open_inventory": [KEY_I],
		"open_memory": [KEY_M],
		"request_hint": [KEY_H],
		"pause": [KEY_ESCAPE, KEY_P],
		"close_overlay": [KEY_BACKSPACE],
		"cycle_inventory": [KEY_Q, KEY_TAB],
		"cycle_inventory_back": [KEY_Z],
		"cycle_timing_mode": [KEY_T],
		"open_settings": [KEY_O],
		"open_credits": [KEY_C],
		"toggle_hud": [KEY_U],
		"run_self_test": [KEY_F9],
		"toggle_numeric_timer": [KEY_N],
		"toggle_reduced_flashing": [KEY_R],
		"text_scale_up": [KEY_EQUAL, KEY_KP_ADD],
		"text_scale_down": [KEY_MINUS, KEY_KP_SUBTRACT]
	}
	for action_variant in keys.keys():
		var action := String(action_variant)
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var key_list: Array = keys[action] as Array
		for key_variant in key_list:
			var input_event := InputEventKey.new()
			input_event.physical_keycode = int(key_variant)
			if not InputMap.action_has_event(action, input_event):
				InputMap.action_add_event(action, input_event)

func _load_data() -> void:
	for id in ITEM_ORDER:
		items[id] = load("res://data/items/%s.tres" % String(id)) as ItemData
	for id in DOLL_ORDER:
		dolls[id] = load("res://data/dolls/%s.tres" % String(id)) as DollData

func _create_camera() -> void:
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.enabled = true
	camera.position_smoothing_enabled = true
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(ROOM_SIZE.x)
	camera.limit_bottom = int(ROOM_SIZE.y)
	player.add_child(camera)

func _create_room() -> void:
	_add_floor_grid()
	_add_walls()
	_add_zone_labels()
	_add_furniture()
	_add_interactables()
	player.global_position = PLAYER_START

func _add_floor_grid() -> void:
	for y in range(0, int(ROOM_SIZE.y / TILE)):
		for x in range(0, int(ROOM_SIZE.x / TILE)):
			var tile_path := "%sfloor_%s.png" % [NURSERY_ART_PATH, "a" if (x + y) % 2 == 0 else "b"]
			_add_texture_sprite(map, tile_path, Vector2(x * TILE, y * TILE) + Vector2(TILE, TILE) * 0.5)
	_add_static_rect("ScorchedRug", Rect2(Vector2(400, 280), Vector2(224, 224)), Color(0.19, 0.15, 0.13), false)

func _add_walls() -> void:
	_add_static_rect("NorthWall", Rect2(0, 0, 1024, 32), Color(0.070, 0.072, 0.082), true)
	_add_static_rect("SouthWall", Rect2(0, 736, 1024, 32), Color(0.070, 0.072, 0.082), true)
	_add_static_rect("WestWall", Rect2(0, 0, 32, 768), Color(0.070, 0.072, 0.082), true)
	_add_static_rect("EastWall", Rect2(992, 0, 32, 768), Color(0.070, 0.072, 0.082), true)
	_add_static_rect("EntranceDoor", Rect2(464, 736, 96, 32), Color(0.18, 0.13, 0.09), false)
	_add_static_rect("ChainedExit", Rect2(448, 0, 128, 32), Color(0.22, 0.18, 0.14), false)
	_add_static_rect("WestWindow", Rect2(0, 160, 32, 112), Color(0.08, 0.14, 0.22), false)
	_add_static_rect("EastWindow", Rect2(992, 144, 32, 112), Color(0.08, 0.14, 0.22), false)
	_add_static_rect("SmokeVent", Rect2(976, 584, 16, 80), Color(0.13, 0.14, 0.15), false)

func _add_zone_labels() -> void:
	_add_label("CHAINED EXIT", Vector2(512, 46), Color(0.92, 0.55, 0.38))
	_add_label("BED / HIDING PLACE", Vector2(208, 72), Color(0.78, 0.72, 0.62))
	_add_label("READING CORNER", Vector2(104, 294), Color(0.66, 0.70, 0.82))
	_add_label("ACTIVITY TABLE", Vector2(352, 304), Color(0.72, 0.68, 0.55))
	_add_label("WASHSTAND", Vector2(860, 326), Color(0.58, 0.72, 0.74))
	_add_label("ROCKING CHAIR", Vector2(864, 520), Color(0.72, 0.66, 0.78))
	_add_label("MUSIC BOX", Vector2(200, 560), Color(0.90, 0.78, 0.55))

func _add_furniture() -> void:
	_add_furniture_rect("Bed", Rect2(96, 96, 224, 128), Rect2(96, 96, 224, 104), Color(0.34, 0.27, 0.25))
	_add_furniture_rect("Wardrobe", Rect2(768, 80, 144, 160), Rect2(768, 80, 144, 144), Color(0.30, 0.24, 0.19))
	_add_furniture_rect("ToyChest", Rect2(704, 264, 128, 64), Rect2(704, 264, 128, 56), Color(0.38, 0.23, 0.17))
	_add_furniture_rect("Bookshelf", Rect2(48, 320, 64, 192), Rect2(48, 320, 64, 192), Color(0.25, 0.20, 0.16))
	_add_furniture_rect("ActivityTable", Rect2(240, 336, 224, 112), Rect2(240, 336, 224, 88), Color(0.45, 0.34, 0.22))
	_add_static_circle("MemoryPedestal", Vector2(512, 384), 40.0, Color(0.42, 0.39, 0.48), true)
	_add_furniture_rect("Washstand", Rect2(792, 352, 136, 80), Rect2(792, 352, 136, 64), Color(0.45, 0.57, 0.58))
	_add_furniture_rect("Crib", Rect2(608, 520, 176, 96), Rect2(608, 520, 176, 80), Color(0.46, 0.40, 0.46))
	_add_furniture_rect("RockingChair", Rect2(816, 544, 96, 112), Rect2(824, 552, 80, 88), Color(0.36, 0.28, 0.22))
	_add_furniture_rect("LowCabinet", Rect2(112, 576, 192, 80), Rect2(112, 576, 192, 64), Color(0.32, 0.27, 0.21))
	_add_furniture_rect("MusicBox", Rect2(176, 584, 48, 40), Rect2(176, 584, 48, 32), Color(0.54, 0.38, 0.21))
	_add_furniture_rect("BrokenAlarm", Rect2(32, 616, 32, 48), Rect2(32, 616, 24, 48), Color(0.45, 0.12, 0.12))

func _add_interactables() -> void:
	_add_interactable(&"music_box", &"music_box", "Music box", "Open music box", Vector2(200, 604), Vector2(48, 32), Color(0.58, 0.40, 0.20))
	_add_interactable(&"entrance", &"clue", "Entrance", "Inspect entrance", Vector2(512, 744), Vector2(96, 20), Color(0.18, 0.13, 0.09))
	_add_interactable(&"exit", &"clue", "Chained exit", "Inspect exit", Vector2(512, 26), Vector2(118, 20), Color(0.44, 0.36, 0.28))
	_add_interactable(&"alarm", &"clue", "Alarm", "Inspect alarm", Vector2(48, 640), Vector2(30, 42), Color(0.52, 0.18, 0.15))
	_add_interactable(&"pedestal", &"pedestal", "Pedestal", "Inspect pedestal", Vector2(512, 384), Vector2(82, 82), Color(0.45, 0.42, 0.52))
	_add_interactable(&"vent", &"clue", "Vent", "Inspect vent", Vector2(984, 624), Vector2(24, 72), Color(0.18, 0.19, 0.20))
	_add_interactable(&"west_window", &"clue", "West window", "Inspect window", Vector2(24, 216), Vector2(34, 82), Color(0.12, 0.18, 0.27))
	_add_interactable(&"east_window", &"clue", "East window", "Inspect window", Vector2(1000, 200), Vector2(34, 82), Color(0.12, 0.18, 0.27))
	_add_evidence_container(&"bed", "Bed pillow", "Search pillow", Vector2(146, 230), Vector2(86, 24), &"ribbon", Color(0.35, 0.27, 0.25))
	_add_evidence_container(&"wardrobe", "Wardrobe", "Open wardrobe", Vector2(848, 252), Vector2(94, 28), &"shoe", Color(0.32, 0.25, 0.20))
	_add_evidence_container(&"washstand", "Wash basin", "Search basin", Vector2(872, 448), Vector2(92, 26), &"cloth", Color(0.48, 0.60, 0.60))
	_add_evidence_container(&"table", "Table edge", "Reach under table", Vector2(258, 472), Vector2(94, 24), &"marble", Color(0.46, 0.34, 0.22))
	_add_evidence_container(&"bookshelf", "Fallen book", "Pull book free", Vector2(126, 528), Vector2(72, 24), &"storybook", Color(0.28, 0.22, 0.18))
	_add_evidence_container(&"exit_key", "Bent key", "Pick up key", Vector2(580, 70), Vector2(54, 20), &"key", Color(0.72, 0.58, 0.26))
	_add_doll(&"mira", Vector2(208, 184), Vector2(28, 24))
	_add_doll(&"kabir", Vector2(944, 208), Vector2(28, 24))
	_add_doll(&"noor", Vector2(752, 408), Vector2(28, 24))
	_add_doll(&"sami", Vector2(352, 416), Vector2(28, 24))
	_add_doll(&"leela", Vector2(136, 384), Vector2(28, 24))
	_add_doll(&"tara", Vector2(512, 72), Vector2(28, 24))
	_add_doll(&"anchor", Vector2(864, 584), Vector2(28, 24))

func _create_effects() -> void:
	fire_overlay = ColorRect.new()
	fire_overlay.color = Color(0.35, 0.08, 0.02, 0.0)
	fire_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(fire_overlay)
	smoke_overlay = ColorRect.new()
	smoke_overlay.color = Color(0.05, 0.05, 0.05, 0.0)
	smoke_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(smoke_overlay)
	_add_fire_source(&"bed_fire", Vector2(116, 110))
	_add_fire_source(&"east_window_fire", Vector2(964, 210))
	_add_fire_source(&"wash_fire", Vector2(910, 420))
	_add_fire_source(&"table_fire", Vector2(430, 440))
	_add_fire_source(&"shelf_fire", Vector2(70, 500))
	_add_fire_source(&"exit_fire", Vector2(560, 36))
	_add_fire_source(&"vent_fire", Vector2(984, 610))
	_set_smoke_stage(0)

func _create_ui() -> void:
	top_hud_panel = _add_panel(Vector2(0, 0), Vector2(VIEW_SIZE.x, 58), Color(0.04, 0.045, 0.05, 0.88))
	bottom_hud_panel = _add_panel(Vector2(0, 296), Vector2(VIEW_SIZE.x, 64), Color(0.035, 0.035, 0.04, 0.90))
	objective_label = _ui_label(Vector2(10, 6), Vector2(285, 16), 10)
	ui_layer.add_child(objective_label)
	top_hud_controls.append(objective_label)
	timing_label = _ui_label(Vector2(300, 6), Vector2(80, 16), 9)
	ui_layer.add_child(timing_label)
	top_hud_controls.append(timing_label)
	smoke_label = _ui_label(Vector2(386, 6), Vector2(80, 16), 9)
	ui_layer.add_child(smoke_label)
	top_hud_controls.append(smoke_label)
	timer_bar = ProgressBar.new()
	timer_bar.position = Vector2(472, 8)
	timer_bar.size = Vector2(118, 10)
	timer_bar.min_value = 0
	timer_bar.max_value = timer_max
	ui_layer.add_child(timer_bar)
	top_hud_controls.append(timer_bar)
	timer_label = _ui_label(Vector2(596, 5), Vector2(38, 18), 9)
	ui_layer.add_child(timer_label)
	top_hud_controls.append(timer_label)
	_create_inventory_panel()
	prompt_label = _ui_label(Vector2(180, 300), Vector2(280, 16), 10)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui_layer.add_child(prompt_label)
	bottom_hud_controls.append(prompt_label)
	subtitle_label = _ui_label(Vector2(28, 318), Vector2(584, 24), 10)
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui_layer.add_child(subtitle_label)
	bottom_hud_controls.append(subtitle_label)
	controls_label = _ui_label(Vector2(8, 345), Vector2(624, 12), 8)
	controls_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls_label.text = "E inspect/listen | F offer/carry | Q/Z item | I inventory | M journal | H hint | T mode | U HUD | O settings"
	ui_layer.add_child(controls_label)
	bottom_hud_controls.append(controls_label)
	_create_hud_toggle_button()
	_create_journal_panel()
	_create_document_panel()
	_create_doll_menu_panel()
	_create_settings_panel()
	_create_credits_panel()
	_create_main_menu_panel()
	_create_pause_menu_panel()
	_create_failure_panel()
	_apply_hud_visibility()

func _create_inventory_panel() -> void:
	for index in range(ITEM_ORDER.size()):
		var x := 10 + index * 100
		var slot_panel := _add_panel(Vector2(x, 26), Vector2(92, 24), Color(0.12, 0.13, 0.15, 0.94))
		top_hud_controls.append(slot_panel)
		var label := _ui_label(Vector2(x + 4, 29), Vector2(84, 18), 8)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		inventory_slots.append(label)
		ui_layer.add_child(label)
		top_hud_controls.append(label)

func _create_hud_toggle_button() -> void:
	hud_toggle_button = Button.new()
	hud_toggle_button.position = Vector2(4, 4)
	hud_toggle_button.size = Vector2(44, 16)
	hud_toggle_button.text = "HUD"
	hud_toggle_button.tooltip_text = "Show or hide the HUD panels (U)"
	_register_readable_text(hud_toggle_button, 12)
	hud_toggle_button.pressed.connect(_toggle_hud)
	ui_layer.add_child(hud_toggle_button)

func _create_journal_panel() -> void:
	journal_panel = Control.new()
	journal_panel.visible = false
	journal_panel.position = Vector2(36, 42)
	journal_panel.size = Vector2(568, 252)
	journal_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	ui_layer.add_child(journal_panel)
	var background := ColorRect.new()
	background.color = Color(0.05, 0.055, 0.065, 0.97)
	background.size = journal_panel.size
	journal_panel.add_child(background)
	journal_label = _ui_label(Vector2(10, 10), Vector2(548, 232), 8)
	journal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	journal_panel.add_child(journal_label)

func _create_document_panel() -> void:
	document_panel = Control.new()
	document_panel.visible = false
	document_panel.position = Vector2(72, 58)
	document_panel.size = Vector2(496, 232)
	document_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	ui_layer.add_child(document_panel)
	var background := ColorRect.new()
	background.color = Color(0.90, 0.86, 0.72, 0.99)
	background.size = document_panel.size
	document_panel.add_child(background)
	document_title_label = _ui_label(Vector2(16, 12), Vector2(464, 18), 12)
	document_title_label.add_theme_color_override("font_color", Color(0.11, 0.09, 0.07))
	_disable_text_shadow(document_title_label)
	document_panel.add_child(document_title_label)
	document_body_label = _ui_label(Vector2(16, 38), Vector2(464, 168), 10)
	document_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	document_body_label.add_theme_color_override("font_color", Color(0.12, 0.10, 0.08))
	_disable_text_shadow(document_body_label)
	document_panel.add_child(document_body_label)
	var close_label := _ui_label(Vector2(16, 210), Vector2(464, 14), 8)
	close_label.text = "E or Backspace closes this document. The timer is paused while reading."
	close_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	close_label.add_theme_color_override("font_color", Color(0.18, 0.14, 0.10))
	_disable_text_shadow(close_label)
	document_panel.add_child(close_label)

func _create_doll_menu_panel() -> void:
	doll_menu_panel = Control.new()
	doll_menu_panel.visible = false
	doll_menu_panel.position = Vector2(128, 236)
	doll_menu_panel.size = Vector2(384, 56)
	doll_menu_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	ui_layer.add_child(doll_menu_panel)
	var background := ColorRect.new()
	background.color = Color(0.045, 0.045, 0.055, 0.96)
	background.size = doll_menu_panel.size
	doll_menu_panel.add_child(background)
	doll_menu_label = _ui_label(Vector2(8, 8), Vector2(368, 40), 9)
	doll_menu_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	doll_menu_panel.add_child(doll_menu_label)

func _create_settings_panel() -> void:
	settings_panel = Control.new()
	settings_panel.visible = false
	settings_panel.position = Vector2(76, 68)
	settings_panel.size = Vector2(488, 204)
	settings_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	ui_layer.add_child(settings_panel)
	var background := ColorRect.new()
	background.color = Color(0.05, 0.055, 0.065, 0.96)
	background.size = settings_panel.size
	settings_panel.add_child(background)
	settings_label = _ui_label(Vector2(14, 12), Vector2(460, 180), 9)
	settings_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	settings_panel.add_child(settings_label)

func _create_credits_panel() -> void:
	credits_panel = Control.new()
	credits_panel.visible = false
	credits_panel.position = Vector2(82, 76)
	credits_panel.size = Vector2(476, 188)
	credits_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	ui_layer.add_child(credits_panel)
	var background := ColorRect.new()
	background.color = Color(0.045, 0.045, 0.055, 0.96)
	background.size = credits_panel.size
	credits_panel.add_child(background)
	credits_label = _ui_label(Vector2(14, 12), Vector2(448, 164), 9)
	credits_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	credits_panel.add_child(credits_label)
	credits_label.text = "Credits and licenses\n\nBurning Nursery greybox adapted from the supplied design PDF.\nPrototype art remains procedural rectangles and labels.\n\nFinal release should list every selected sprite, sound and font file used.\n\nPress C or Backspace to close."

func _create_main_menu_panel() -> void:
	main_menu_panel = Control.new()
	main_menu_panel.visible = false
	main_menu_panel.position = Vector2(140, 66)
	main_menu_panel.size = Vector2(360, 226)
	main_menu_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	ui_layer.add_child(main_menu_panel)
	var background := ColorRect.new()
	background.color = Color(0.035, 0.038, 0.045, 0.98)
	background.size = main_menu_panel.size
	main_menu_panel.add_child(background)
	var title := _ui_label(Vector2(18, 18), Vector2(324, 28), 18)
	title.text = "Burning Nursery"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_menu_panel.add_child(title)
	var subtitle := _ui_label(Vector2(28, 50), Vector2(304, 36), 9)
	subtitle.text = "A larger greybox puzzle room built from the new PDF plan."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	main_menu_panel.add_child(subtitle)
	_add_menu_button(main_menu_panel, "Start", Vector2(118, 96), _start_new_game)
	_add_menu_button(main_menu_panel, "Settings", Vector2(118, 128), _toggle_settings)
	_add_menu_button(main_menu_panel, "Credits", Vector2(118, 160), _toggle_credits)
	_add_menu_button(main_menu_panel, "Quit", Vector2(118, 192), _quit_game)

func _create_pause_menu_panel() -> void:
	pause_menu_panel = Control.new()
	pause_menu_panel.visible = false
	pause_menu_panel.position = Vector2(150, 74)
	pause_menu_panel.size = Vector2(340, 208)
	pause_menu_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	ui_layer.add_child(pause_menu_panel)
	var background := ColorRect.new()
	background.color = Color(0.035, 0.038, 0.045, 0.98)
	background.size = pause_menu_panel.size
	pause_menu_panel.add_child(background)
	var title := _ui_label(Vector2(18, 18), Vector2(304, 24), 15)
	title.text = "Paused"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_menu_panel.add_child(title)
	_add_menu_button(pause_menu_panel, "Resume", Vector2(108, 58), _resume_game)
	_add_menu_button(pause_menu_panel, "Restart Checkpoint", Vector2(108, 90), _restart_from_pause)
	_add_menu_button(pause_menu_panel, "Settings", Vector2(108, 122), _toggle_settings)
	_add_menu_button(pause_menu_panel, "Main Menu", Vector2(108, 154), _return_to_main_menu)

func _create_failure_panel() -> void:
	failure_panel = Control.new()
	failure_panel.visible = false
	failure_panel.position = Vector2(136, 96)
	failure_panel.size = Vector2(368, 168)
	failure_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	ui_layer.add_child(failure_panel)
	var background := ColorRect.new()
	background.color = Color(0.025, 0.025, 0.030, 0.98)
	background.size = failure_panel.size
	failure_panel.add_child(background)
	var title := _ui_label(Vector2(18, 16), Vector2(332, 24), 15)
	title.text = "The Nursery Fills"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	failure_panel.add_child(title)
	var failure_label := _ui_label(Vector2(26, 48), Vector2(316, 44), 9)
	failure_label.text = "The music box stops mid-note.\nRetry from the latest fair checkpoint."
	failure_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	failure_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	failure_panel.add_child(failure_label)
	_add_menu_button(failure_panel, "Retry Checkpoint", Vector2(110, 98), _retry_from_failure)
	_add_menu_button(failure_panel, "Main Menu", Vector2(110, 130), _return_to_main_menu)

func _add_menu_button(parent: Control, text: String, pos: Vector2, callback: Callable) -> Button:
	var button := Button.new()
	button.size = Vector2(150, 24)
	button.position = Vector2(round((parent.size.x - button.size.x) * 0.5), pos.y)
	button.text = text
	button.process_mode = Node.PROCESS_MODE_ALWAYS
	_register_readable_text(button, 14)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _ui_label(pos: Vector2, size: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.position = pos
	label.size = size
	_register_readable_text(label, font_size)
	label.add_theme_color_override("font_color", Color(0.94, 0.94, 0.88))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	return label

func _disable_text_shadow(label: Label) -> void:
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 0)

func _register_readable_text(control: Control, base_font_size: int) -> void:
	control.set_meta("base_font_size", base_font_size)
	if not font_sized_controls.has(control):
		font_sized_controls.append(control)
	_apply_readable_font_size(control)

func _apply_readable_font_size(control: Control) -> void:
	if control == null or not is_instance_valid(control):
		return
	var base_font_size := int(control.get_meta("base_font_size", 10))
	control.add_theme_font_size_override("font_size", _readable_font_size(base_font_size))

func _readable_font_size(base_font_size: int) -> int:
	var scaled := int(round(float(base_font_size) * text_scale))
	return maxi(9, scaled)

func _refresh_text_scale() -> void:
	for control in font_sized_controls:
		_apply_readable_font_size(control)
	if settings_label != null:
		_update_settings_text()
	_update_ui()

func _add_panel(pos: Vector2, size: Vector2, color: Color) -> ColorRect:
	var panel := ColorRect.new()
	panel.position = pos
	panel.size = size
	panel.color = color
	ui_layer.add_child(panel)
	return panel

func _add_static_rect(name: String, rect: Rect2, color: Color, collides: bool) -> Node2D:
	var node: Node2D = StaticBody2D.new() if collides else Node2D.new()
	node.name = name
	node.position = rect.position
	map.add_child(node)
	var art_path := _static_art_path(name)
	if art_path != "":
		_add_texture_sprite(node, art_path, rect.size * 0.5)
	else:
		if not name.ends_with("Wall"):
			_add_rect_visual(node, Vector2(3, 4), rect.size, Color(0.015, 0.012, 0.014, 0.42))
		var color_rect := ColorRect.new()
		color_rect.color = color
		color_rect.size = rect.size
		node.add_child(color_rect)
		_add_rect_visual(node, Vector2.ZERO, Vector2(rect.size.x, 1), color.lightened(0.18))
		_add_rect_visual(node, Vector2(0, rect.size.y - 2), Vector2(rect.size.x, 2), color.darkened(0.28))
	if collides:
		var shape := CollisionShape2D.new()
		var rect_shape := RectangleShape2D.new()
		rect_shape.size = rect.size
		shape.shape = rect_shape
		shape.position = rect.size * 0.5
		node.add_child(shape)
	return node

func _add_furniture_rect(name: String, visual_rect: Rect2, collision_rect: Rect2, color: Color) -> void:
	_add_static_rect(name, visual_rect, color, false)
	var body := StaticBody2D.new()
	body.name = "%sCollision" % name
	body.position = collision_rect.position
	map.add_child(body)
	var shape := CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = collision_rect.size
	shape.shape = rect_shape
	shape.position = collision_rect.size * 0.5
	body.add_child(shape)

func _add_static_circle(name: String, center: Vector2, radius: float, color: Color, collides: bool) -> void:
	var node: Node2D = StaticBody2D.new() if collides else Node2D.new()
	node.name = name
	node.position = center
	map.add_child(node)
	var art_path := _static_art_path(name)
	if art_path != "":
		_add_texture_sprite(node, art_path, Vector2.ZERO)
	else:
		var rect := ColorRect.new()
		rect.color = color
		rect.position = Vector2(-radius, -radius)
		rect.size = Vector2(radius * 2.0, radius * 2.0)
		node.add_child(rect)
		_add_rect_visual(node, Vector2(-radius + 8, -4), Vector2(radius * 2.0 - 16, 8), color.lightened(0.18))
	if collides:
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = radius * 0.9
		shape.shape = circle
		node.add_child(shape)

func _add_rect_visual(parent: Node, pos: Vector2, size: Vector2, color: Color) -> ColorRect:
	var rect := ColorRect.new()
	rect.position = pos
	rect.size = size
	rect.color = color
	parent.add_child(rect)
	return rect

func _add_texture_sprite(parent: Node, path: String, pos: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = load(path) as Texture2D
	sprite.centered = true
	sprite.position = pos
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	parent.add_child(sprite)
	return sprite

func _static_art_path(name: String) -> String:
	match name:
		"ScorchedRug":
			return "%sscorched_rug.png" % NURSERY_ART_PATH
		"NorthWall":
			return "%swall_north.png" % NURSERY_ART_PATH
		"SouthWall":
			return "%swall_south.png" % NURSERY_ART_PATH
		"WestWall":
			return "%swall_west.png" % NURSERY_ART_PATH
		"EastWall":
			return "%swall_east.png" % NURSERY_ART_PATH
		"EntranceDoor":
			return "%sentrance_door.png" % NURSERY_ART_PATH
		"ChainedExit":
			return "%schained_exit.png" % NURSERY_ART_PATH
		"WestWindow", "EastWindow":
			return "%swindow_barred.png" % NURSERY_ART_PATH
		"SmokeVent":
			return "%ssmoke_vent.png" % NURSERY_ART_PATH
		"Bed":
			return "%sbed.png" % NURSERY_ART_PATH
		"Wardrobe":
			return "%swardrobe.png" % NURSERY_ART_PATH
		"ToyChest":
			return "%stoy_chest.png" % NURSERY_ART_PATH
		"Bookshelf":
			return "%sbookshelf.png" % NURSERY_ART_PATH
		"ActivityTable":
			return "%sactivity_table.png" % NURSERY_ART_PATH
		"MemoryPedestal":
			return "%spedestal.png" % NURSERY_ART_PATH
		"Washstand":
			return "%swashstand.png" % NURSERY_ART_PATH
		"Crib":
			return "%scrib.png" % NURSERY_ART_PATH
		"RockingChair":
			return "%srocking_chair.png" % NURSERY_ART_PATH
		"LowCabinet":
			return "%slow_cabinet.png" % NURSERY_ART_PATH
		"MusicBox":
			return "%smusic_box.png" % NURSERY_ART_PATH
		"BrokenAlarm":
			return "%sbroken_alarm.png" % NURSERY_ART_PATH
		_:
			return ""

func _skin_interactable(node: AshInteractable) -> void:
	var art_path := _interactable_art_path(node.interaction_id)
	if art_path == "":
		return
	var sprite := _add_texture_sprite(node, art_path, Vector2.ZERO)
	sprite.name = "ArtSprite"
	if node.kind == &"doll":
		sprite.position = Vector2(0, -8)
		node.visual_alpha = 0.05
	elif node.kind == &"evidence":
		sprite.position = Vector2(0, -2)
		node.visual_alpha = 0.10
	else:
		node.visual_alpha = 0.16

func _interactable_art_path(id: StringName) -> String:
	match id:
		&"ribbon", &"bed":
			return "%sitem_ribbon.png" % NURSERY_ART_PATH
		&"shoe", &"wardrobe":
			return "%sitem_shoe.png" % NURSERY_ART_PATH
		&"cloth", &"washstand":
			return "%sitem_cloth.png" % NURSERY_ART_PATH
		&"marble", &"table":
			return "%sitem_marble.png" % NURSERY_ART_PATH
		&"storybook", &"bookshelf":
			return "%sitem_storybook.png" % NURSERY_ART_PATH
		&"key", &"exit_key":
			return "%sitem_key.png" % NURSERY_ART_PATH
		&"mira":
			return "%sdoll_mira.png" % NURSERY_ART_PATH
		&"kabir":
			return "%sdoll_kabir.png" % NURSERY_ART_PATH
		&"noor":
			return "%sdoll_noor.png" % NURSERY_ART_PATH
		&"sami":
			return "%sdoll_sami.png" % NURSERY_ART_PATH
		&"leela":
			return "%sdoll_leela.png" % NURSERY_ART_PATH
		&"tara":
			return "%sdoll_tara.png" % NURSERY_ART_PATH
		&"anchor":
			return "%sdoll_anchor.png" % NURSERY_ART_PATH
		_:
			return ""

func _add_label(text: String, pos: Vector2, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.position = pos - Vector2(96, 8)
	label.size = Vector2(192, 16)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_register_readable_text(label, 8)
	label.add_theme_color_override("font_color", color)
	map.add_child(label)

func _add_interactable(id: StringName, kind: StringName, label: String, prompt: String, pos: Vector2, size: Vector2, color: Color) -> AshInteractable:
	var node: AshInteractable = AshInteractable.new()
	node.interaction_id = id
	node.kind = kind
	node.display_label = label
	node.interaction_text = prompt
	node.body_size = size
	node.body_color = color
	node.position = pos
	world.add_child(node)
	_skin_interactable(node)
	interactables.append(node)
	interactable_by_id[id] = node
	return node

func _add_evidence_container(id: StringName, label: String, prompt: String, pos: Vector2, size: Vector2, item_id: StringName, color: Color) -> void:
	var node := _add_interactable(id, &"evidence", label, prompt, pos, size, color)
	node.set_meta("item_id", item_id)

func _add_doll(id: StringName, pos: Vector2, size: Vector2) -> void:
	var doll: DollData = dolls[id] as DollData
	var label := "Unknown" if doll.unnamed else doll.child_name
	var node := _add_interactable(id, &"doll", label, "Listen", pos, size, doll.color)
	node.set_meta("doll_id", id)

func _add_fire_source(id: StringName, pos: Vector2) -> void:
	var fire := Node2D.new()
	fire.name = String(id)
	fire.position = pos
	var glow := _add_texture_sprite(fire, "%sfire_glow.png" % NURSERY_ART_PATH, Vector2.ZERO)
	glow.name = "Glow"
	glow.modulate = Color(1.0, 0.68, 0.32, 0.68)
	var sprite := _add_texture_sprite(fire, "%sfire_0.png" % NURSERY_ART_PATH, Vector2(0, -6))
	sprite.name = "Flame"
	world.add_child(fire)
	fire_nodes[id] = fire

func _toggle_pause() -> void:
	if main_menu_open:
		return
	if pause_menu_open:
		_resume_game()
		return
	paused = true
	pause_menu_open = true
	get_tree().paused = true
	pause_menu_panel.visible = true
	_close_doll_menu()
	_show_subtitle("Paused")
	_update_ui()

func _resume_game() -> void:
	pause_menu_open = false
	paused = false
	get_tree().paused = false
	if pause_menu_panel != null:
		pause_menu_panel.visible = false
	_show_subtitle("Returned to the nursery.")
	_update_ui()

func _open_main_menu() -> void:
	main_menu_open = true
	pause_menu_open = false
	menu_hidden_by_overlay = ""
	game_over = false
	paused = true
	get_tree().paused = true
	if main_menu_panel != null:
		main_menu_panel.visible = true
	if pause_menu_panel != null:
		pause_menu_panel.visible = false
	_close_all_overlays()
	_update_ui()

func _start_new_game() -> void:
	_reset_run_state()
	main_menu_open = false
	menu_hidden_by_overlay = ""
	paused = false
	get_tree().paused = false
	if main_menu_panel != null:
		main_menu_panel.visible = false
	_show_subtitle("The nursery waits. Find what began the fire.")
	_update_ui()

func _return_to_main_menu() -> void:
	get_tree().paused = false
	pause_menu_open = false
	menu_hidden_by_overlay = ""
	paused = false
	game_over = false
	if pause_menu_panel != null:
		pause_menu_panel.visible = false
	if failure_panel != null:
		failure_panel.visible = false
	_reset_run_state()
	_open_main_menu()

func _restart_from_pause() -> void:
	_resume_game()
	_restore_checkpoint()

func _retry_from_failure() -> void:
	game_over = false
	paused = false
	get_tree().paused = false
	if failure_panel != null:
		failure_panel.visible = false
	_restore_checkpoint()

func _quit_game() -> void:
	get_tree().quit()

func _update_current_interactable() -> void:
	var best: AshInteractable = null
	var best_score := INF
	for node in interactables:
		if not is_instance_valid(node) or not node.visible:
			continue
		node.highlighted = false
		var distance := player.global_position.distance_to(node.global_position)
		if distance > INTERACT_DISTANCE:
			continue
		var to_node := (node.global_position - player.global_position).normalized()
		var facing_bonus := -10.0 if player.facing.dot(to_node) > 0.15 else 0.0
		var doll_priority: float = -12.0 if node.kind == &"doll" else 0.0
		var pedestal_priority: float = -36.0 if anchor_carried and node.kind == &"pedestal" else 0.0
		var score := distance + facing_bonus + doll_priority + pedestal_priority
		if score < best_score:
			best_score = score
			best = node
	current_interactable = best
	if current_interactable != null:
		current_interactable.highlighted = true

func _interact_current() -> void:
	if current_interactable == null:
		return
	match current_interactable.kind:
		&"music_box":
			_open_music_box()
		&"evidence":
			_handle_evidence_container(current_interactable)
		&"doll":
			_open_doll_menu(current_interactable)
		&"pedestal":
			_handle_pedestal()
		_:
			_inspect_clue(current_interactable)
	_update_ui()

func _open_offer_for_current() -> void:
	if current_interactable != null and current_interactable.kind == &"doll":
		_open_doll_menu(current_interactable)

func _open_music_box() -> void:
	if has_music_box_open:
		_open_document("Music box", "The lid is open. The photograph and six-name card remain in your journal.")
		return
	_change_phase(Phase.FIRE_STARTING)
	has_music_box_open = true
	_discover_clue(&"photo", String(INVESTIGATION_CLUES[&"photo"]))
	_discover_clue(&"name_card", String(INVESTIGATION_CLUES[&"name_card"]))
	_open_document("Music box", "The lid opens with a thin metallic click.\n\nInside: a group photograph of seven children and a card naming only six.\n\nThe entrance slams. Smoke begins to leave the eastern vent.")
	_start_investigation()

func _start_investigation() -> void:
	_change_phase(Phase.INVESTIGATION)
	time_remaining = timer_max
	timer_draining = timing_mode != TimingMode.STORY
	_set_smoke_stage(1)
	_save_checkpoint()
	_show_subtitle("The music box plays. The nursery remembers the fire.")

func _handle_evidence_container(node: AshInteractable) -> void:
	if not has_music_box_open:
		_show_subtitle("The furniture feels fixed in place. The music box has not opened yet.")
		return
	var item_id: StringName = StringName(node.get_meta("item_id"))
	if inventory.has(item_id) or _item_is_resolved(item_id):
		var duplicate_item: ItemData = items[item_id] as ItemData
		_show_subtitle("%s is already recorded in the journal." % duplicate_item.display_name)
		return
	inventory.append(item_id)
	selected_index = inventory.size() - 1
	var item: ItemData = items[item_id] as ItemData
	node.visible = false
	_discover_clue(item_id, String(EVIDENCE_TEXT[item_id]))
	if node.interaction_id == &"table":
		_discover_clue(&"ledger", String(INVESTIGATION_CLUES[&"ledger"]))
	_show_subtitle("Collected %s. %s" % [item.display_name, item.description])

func _open_doll_menu(node: AshInteractable) -> void:
	active_doll = node
	doll_menu_panel.visible = true
	var doll_id: StringName = StringName(node.get_meta("doll_id"))
	var doll: DollData = dolls[doll_id] as DollData
	if doll.unnamed:
		if phase == Phase.PEDESTAL_READY:
			doll_menu_label.text = "Unknown anchor\nE listen | F carry to pedestal | Backspace close"
		elif phase == Phase.COMPLETE:
			doll_menu_label.text = "The center mark is filled.\nE remember | Backspace close"
		else:
			doll_menu_label.text = "Unknown anchor\nE listen | Backspace close"
	elif resolved_dolls.has(doll_id):
		doll_menu_label.text = "%s is quiet now.\nE remember | Backspace close" % doll.child_name
	else:
		var selected_name := "no evidence"
		if not inventory.is_empty():
			var selected_item: ItemData = items[_selected_item_id()] as ItemData
			selected_name = selected_item.display_name
		doll_menu_label.text = "%s\nE listen | F offer selected: %s | Q/Z change item | Backspace close" % [doll.child_name, selected_name]

func _handle_doll_menu_input(event: InputEvent) -> void:
	if event.is_action_pressed("close_overlay"):
		_close_doll_menu()
	elif event.is_action_pressed("cycle_inventory"):
		_cycle_inventory(1)
		_open_doll_menu(active_doll)
	elif event.is_action_pressed("cycle_inventory_back"):
		_cycle_inventory(-1)
		_open_doll_menu(active_doll)
	elif event.is_action_pressed("interact"):
		_listen_to_active_doll()
	elif event.is_action_pressed("offer_item"):
		_offer_to_active_doll()

func _listen_to_active_doll() -> void:
	if active_doll == null:
		return
	var doll_id: StringName = StringName(active_doll.get_meta("doll_id"))
	var doll: DollData = dolls[doll_id] as DollData
	if doll.unnamed:
		if phase == Phase.PEDESTAL_READY:
			_show_subtitle("Unknown anchor: \"Six names. Seven breaths.\"")
		elif resolved_dolls.size() >= 3:
			_show_subtitle("Unknown anchor: \"Someone is missing.\"")
		else:
			_show_subtitle("Unknown anchor: \"%s\"" % doll.initial_line)
	elif resolved_dolls.has(doll_id):
		_show_subtitle("%s: \"%s\"" % [doll.child_name, doll.resolved_line])
	elif _has_item_for_doll(doll):
		_show_subtitle("%s: \"%s\"" % [doll.child_name, doll.late_line])
	else:
		_show_subtitle("%s: \"%s\"" % [doll.child_name, doll.initial_line])

func _offer_to_active_doll() -> void:
	if active_doll == null:
		return
	var doll_id: StringName = StringName(active_doll.get_meta("doll_id"))
	var doll: DollData = dolls[doll_id] as DollData
	if doll.unnamed:
		_handle_anchor_offer()
		return
	if not has_music_box_open:
		_show_subtitle("The dolls listen, but the nursery has not begun remembering yet.")
		return
	if resolved_dolls.has(doll_id):
		_show_subtitle("That memory has already been restored.")
		return
	if inventory.is_empty():
		_show_subtitle("You have no evidence item to offer.")
		return
	var selected_item := _selected_item_id()
	if selected_item == doll.required_item_id:
		_resolve_doll(active_doll, doll, selected_item)
		_close_doll_menu()
	else:
		var item: ItemData = items[selected_item] as ItemData
		wrong_attempts_by_doll[doll_id] = int(wrong_attempts_by_doll.get(doll_id, 0)) + 1
		smoke_pulse_timer = 1.2
		_update_effect_overlays()
		_show_subtitle("%s turns away from %s: \"Not mine.\"" % [doll.child_name, item.display_name])

func _handle_anchor_offer() -> void:
	if phase == Phase.PEDESTAL_READY:
		anchor_carried = true
		player.carrying_ari = true
		if active_doll != null:
			active_doll.visible = false
		_close_doll_menu()
		_change_phase(Phase.CARRYING_ANCHOR)
		_save_checkpoint()
		_show_subtitle("You lift the unnamed doll. It is lighter than ash.")
	else:
		_show_subtitle("The center mark has not opened yet.")

func _selected_item_id() -> StringName:
	if inventory.is_empty():
		return &""
	selected_index = clampi(selected_index, 0, inventory.size() - 1)
	return inventory[selected_index]

func _has_item_for_doll(doll: DollData) -> bool:
	return inventory.has(doll.required_item_id) or _item_is_resolved(doll.required_item_id)

func _resolve_doll(node: AshInteractable, doll: DollData, item_id: StringName) -> void:
	resolved_dolls[doll.id] = true
	inventory.erase(item_id)
	selected_index = min(selected_index, max(0, inventory.size() - 1))
	node.body_color = doll.color.lightened(0.25)
	node.interaction_text = "Remember"
	node.display_label = doll.child_name
	node.queue_redraw()
	if timing_mode == TimingMode.STANDARD and timer_draining:
		time_remaining = minf(timer_max, time_remaining + 20.0)
	_extinguish_doll_flame(doll.id)
	_discover_clue(StringName("resolved_%s" % String(doll.id)), "%s remembered: %s" % [doll.child_name, doll.resolved_line])
	if resolved_dolls.size() == 6:
		_change_phase(Phase.PEDESTAL_READY)
		_set_smoke_stage(maxi(smoke_stage, 4))
		_show_subtitle("Six named dolls are restored. The pedestal ring opens. Count again.")
	else:
		_show_subtitle("%s remembered. \"%s\"" % [doll.child_name, doll.resolved_line])
	_save_checkpoint()

func _handle_pedestal() -> void:
	if phase == Phase.CARRYING_ANCHOR and anchor_carried:
		_change_phase(Phase.RELEASE_CUTSCENE)
		timer_draining = false
		player.carrying_ari = false
		_set_smoke_stage(5)
		_open_document("Release", "The unnamed doll rests in the center.\n\nSix marks answer first: Mira, Kabir, Noor, Sami, Leela, Tara.\n\nThen the seventh mark lights without a name.\n\nThe attendance card gains a burned-away line.\n\nThe nursery remembers seven.")
		_change_phase(Phase.COMPLETE)
		_show_subtitle("The fire freezes. The record can no longer hold only six.")
	elif phase == Phase.PEDESTAL_READY:
		_show_subtitle("The center mark waits. Carry the one the record forgot.")
	else:
		_inspect_clue(interactable_by_id[&"pedestal"] as AshInteractable)

func _inspect_clue(node: AshInteractable) -> void:
	var id := node.interaction_id
	var text := ""
	if has_music_box_open and INVESTIGATION_CLUES.has(id):
		text = String(INVESTIGATION_CLUES[id])
	else:
		text = String(INITIAL_CLUES.get(id, "The nursery keeps this detail in place."))
	_discover_clue(id, text)
	_show_subtitle(text)

func _discover_clue(id: StringName, text: String) -> void:
	discovered_clues[id] = text

func _open_document(title: String, body: String) -> void:
	document_open = true
	document_panel.visible = true
	document_title_label.text = title
	document_body_label.text = body
	_close_doll_menu()
	_update_ui()

func _set_timing_mode(next_mode: TimingMode) -> void:
	_apply_timing_mode(next_mode, false)

func _apply_timing_mode(next_mode: TimingMode, preserve_ratio: bool) -> void:
	var previous_ratio := clampf(time_remaining / maxf(timer_max, 1.0), 0.0, 1.0)
	timing_mode = next_mode
	timer_max = _timer_max_for_mode(timing_mode)
	if preserve_ratio:
		time_remaining = timer_max * previous_ratio
	else:
		time_remaining = minf(time_remaining, timer_max)
		if time_remaining <= 0.0:
			time_remaining = timer_max
	timer_draining = timing_mode != TimingMode.STORY and _phase_can_fail_from_timer()
	if timer_bar != null:
		timer_bar.max_value = timer_max
	_update_ui()

func _timer_max_for_mode(mode: int) -> float:
	if mode == TimingMode.DREAD:
		return 240.0
	return 300.0

func _cycle_timing_mode() -> void:
	var next_mode: TimingMode
	if timing_mode == TimingMode.STORY:
		next_mode = TimingMode.STANDARD
	elif timing_mode == TimingMode.STANDARD:
		next_mode = TimingMode.DREAD
	else:
		next_mode = TimingMode.STORY
	_apply_timing_mode(next_mode, _phase_can_fail_from_timer())
	_show_subtitle("Timing mode: %s" % TIMING_LABELS[timing_mode])

func _timer_should_drain() -> bool:
	if timing_mode == TimingMode.STORY:
		return false
	if not timer_draining or paused or document_open or journal_open or settings_open or credits_open:
		return false
	return _phase_can_fail_from_timer()

func _phase_can_fail_from_timer() -> bool:
	return phase == Phase.INVESTIGATION or phase == Phase.PEDESTAL_READY or phase == Phase.CARRYING_ANCHOR

func _apply_timer_thresholds() -> void:
	var ratio := time_remaining / maxf(timer_max, 1.0)
	if timing_mode == TimingMode.DREAD:
		if ratio <= 0.20:
			_set_smoke_stage(5)
		elif ratio <= 0.38:
			_set_smoke_stage(4)
		elif ratio <= 0.58:
			_set_smoke_stage(3)
		elif ratio <= 0.80:
			_set_smoke_stage(2)
		else:
			_set_smoke_stage(maxi(smoke_stage, 1))
	else:
		if ratio <= 0.10:
			_set_smoke_stage(5)
		elif ratio <= 0.25:
			_set_smoke_stage(4)
		elif ratio <= 0.50:
			_set_smoke_stage(3)
		elif ratio <= 0.75:
			_set_smoke_stage(2)
		else:
			_set_smoke_stage(maxi(smoke_stage, 1))

func _set_smoke_stage(next_stage: int) -> void:
	smoke_stage = clampi(next_stage, 0, 5)
	for fire_id_variant in fire_nodes.keys():
		var fire_id: StringName = StringName(fire_id_variant)
		var fire: CanvasItem = fire_nodes[fire_id] as CanvasItem
		fire.visible = smoke_stage > 0 and smoke_stage < 5
		if smoke_stage == 1:
			fire.visible = fire_id in [&"bed_fire", &"east_window_fire", &"vent_fire"]
		elif smoke_stage == 2:
			fire.visible = fire_id != &"table_fire"
		elif smoke_stage >= 3:
			fire.visible = true
	_update_effect_overlays()

func _update_effect_overlays() -> void:
	if fire_overlay == null or smoke_overlay == null:
		return
	var fire_alpha := 0.0
	var smoke_alpha := 0.0
	match smoke_stage:
		1:
			fire_alpha = 0.06
			smoke_alpha = 0.05
		2:
			fire_alpha = 0.10
			smoke_alpha = 0.14
		3:
			fire_alpha = 0.14
			smoke_alpha = 0.26
		4:
			fire_alpha = 0.18
			smoke_alpha = 0.38
		5:
			fire_alpha = 0.12
			smoke_alpha = 0.48
	if timing_mode == TimingMode.DREAD and _phase_can_fail_from_timer():
		fire_alpha *= 1.15
		smoke_alpha *= 1.25
	if reduced_flashing:
		fire_alpha *= 0.45
		smoke_alpha *= 0.65
	if smoke_pulse_timer > 0.0:
		smoke_alpha += 0.12 * (smoke_pulse_timer / 1.2)
	fire_overlay.color = Color(0.35, 0.08, 0.02, clampf(fire_alpha, 0.0, 0.45))
	smoke_overlay.color = Color(0.05, 0.05, 0.05, clampf(smoke_alpha, 0.0, 0.62))

func _extinguish_doll_flame(doll_id: StringName) -> void:
	if not DOLL_FLAMES.has(doll_id):
		return
	var fire_id: StringName = StringName(DOLL_FLAMES[doll_id])
	if fire_nodes.has(fire_id):
		var fire: CanvasItem = fire_nodes[fire_id] as CanvasItem
		fire.visible = false

func _fail_level() -> void:
	game_over = true
	_change_phase(Phase.FAILED)
	timer_draining = false
	paused = true
	get_tree().paused = true
	_close_all_overlays()
	if pause_menu_panel != null:
		pause_menu_panel.visible = false
	_show_subtitle("The music box stops mid-note. Choose a retry from the latest checkpoint.")
	smoke_overlay.color = Color(0.02, 0.02, 0.02, 0.55)
	if failure_panel != null:
		failure_panel.visible = true
		failure_panel.move_to_front()

func _save_checkpoint() -> void:
	checkpoint_data = {
		"phase": phase,
		"inventory": inventory.duplicate(),
		"resolved": resolved_dolls.duplicate(),
		"clues": discovered_clues.duplicate(),
		"wrong_attempts": wrong_attempts_by_doll.duplicate(),
		"music_open": has_music_box_open,
		"anchor_carried": anchor_carried,
		"timing_mode": timing_mode,
		"timer_max": timer_max,
		"time_remaining": time_remaining,
		"timer_draining": timer_draining,
		"smoke_stage": smoke_stage,
		"player_position": player.global_position
	}

func _restore_checkpoint() -> void:
	if checkpoint_data.is_empty():
		_reset_run_state()
	else:
		phase = int(checkpoint_data["phase"])
		inventory.clear()
		var restored_inventory: Array = checkpoint_data["inventory"] as Array
		for item_variant in restored_inventory:
			inventory.append(StringName(item_variant))
		resolved_dolls = (checkpoint_data["resolved"] as Dictionary).duplicate()
		discovered_clues = (checkpoint_data["clues"] as Dictionary).duplicate()
		wrong_attempts_by_doll = (checkpoint_data["wrong_attempts"] as Dictionary).duplicate()
		has_music_box_open = bool(checkpoint_data["music_open"])
		anchor_carried = bool(checkpoint_data["anchor_carried"])
		timing_mode = int(checkpoint_data["timing_mode"])
		timer_max = _timer_max_for_mode(timing_mode)
		time_remaining = clampf(float(checkpoint_data["time_remaining"]), 0.0, timer_max)
		timer_draining = bool(checkpoint_data["timer_draining"]) and timing_mode != TimingMode.STORY and _phase_can_fail_from_timer()
		smoke_stage = int(checkpoint_data["smoke_stage"])
		if checkpoint_data.has("player_position"):
			player.global_position = checkpoint_data["player_position"]
	player.carrying_ari = anchor_carried
	if timer_bar != null:
		timer_bar.max_value = timer_max
	_refresh_world_state_from_progress()
	_set_smoke_stage(smoke_stage if phase >= Phase.INVESTIGATION else 0)
	_show_subtitle("Retry from checkpoint. Restored dolls stay remembered.")
	_update_ui()

func _reset_run_state() -> void:
	inventory.clear()
	selected_index = 0
	resolved_dolls.clear()
	discovered_clues.clear()
	wrong_attempts_by_doll.clear()
	has_music_box_open = false
	anchor_carried = false
	timer_max = _timer_max_for_mode(timing_mode)
	time_remaining = timer_max
	timer_draining = false
	game_over = false
	smoke_pulse_timer = 0.0
	active_doll = null
	current_interactable = null
	checkpoint_data.clear()
	player.global_position = PLAYER_START
	player.carrying_ari = false
	_close_all_overlays()
	_close_doll_menu()
	for node in interactables:
		node.visible = true
		if node.kind == &"doll":
			var doll_id: StringName = StringName(node.get_meta("doll_id"))
			var doll: DollData = dolls[doll_id] as DollData
			node.body_color = doll.color
			node.display_label = "Unknown" if doll.unnamed else doll.child_name
			node.interaction_text = "Listen"
			node.queue_redraw()
	_set_smoke_stage(0)
	_change_phase(Phase.SAFE_EXPLORE)
	_save_checkpoint()
	_update_ui()

func _refresh_world_state_from_progress() -> void:
	for id in ITEM_ORDER:
		var container_id := StringName(ITEM_LOCATION[id])
		if interactable_by_id.has(container_id):
			var item_node: AshInteractable = interactable_by_id[container_id] as AshInteractable
			item_node.visible = not inventory.has(id) and not _item_is_resolved(id)
	for doll_id in DOLL_ORDER:
		if interactable_by_id.has(doll_id):
			var doll_node: AshInteractable = interactable_by_id[doll_id] as AshInteractable
			var doll: DollData = dolls[doll_id] as DollData
			doll_node.visible = doll_id != &"anchor" or not anchor_carried
			if resolved_dolls.has(doll_id):
				doll_node.body_color = doll.color.lightened(0.25)
				doll_node.display_label = doll.child_name
				doll_node.interaction_text = "Remember"
			else:
				doll_node.body_color = doll.color
				doll_node.display_label = "Unknown" if doll.unnamed else doll.child_name
				doll_node.interaction_text = "Listen"
			doll_node.queue_redraw()

func _item_is_resolved(item_id: StringName) -> bool:
	for doll_id in resolved_dolls.keys():
		var doll: DollData = dolls[StringName(doll_id)] as DollData
		if doll.required_item_id == item_id:
			return true
	return false

func _show_hint() -> void:
	if not has_music_box_open:
		_show_subtitle("Hint: Open the music box near the low cabinet.")
		return
	for doll_id in DOLL_ORDER:
		if doll_id == &"anchor" or resolved_dolls.has(doll_id):
			continue
		var doll: DollData = dolls[doll_id] as DollData
		if int(wrong_attempts_by_doll.get(doll_id, 0)) >= 3:
			var item: ItemData = items[doll.required_item_id] as ItemData
			_show_subtitle("Journal hint: %s's place points toward %s." % [doll.child_name, item.display_name])
			return
	_show_subtitle("Hint: Six names are recorded, but seven dolls are present.")

func _show_inventory_details() -> void:
	if inventory.is_empty():
		_show_subtitle("Inventory is empty.")
		return
	var lines: Array[String] = []
	for id in inventory:
		var item: ItemData = items[id] as ItemData
		lines.append("%s: %s" % [item.display_name, item.description])
	_open_document("Evidence inventory", "\n\n".join(lines))

func _toggle_journal() -> void:
	journal_open = not journal_open
	journal_panel.visible = journal_open
	if journal_open:
		document_open = false
		document_panel.visible = false
		_close_doll_menu()
	_update_ui()

func _toggle_settings() -> void:
	if settings_open:
		_close_settings_overlay()
	else:
		_open_settings_overlay()

func _toggle_credits() -> void:
	if credits_open:
		_close_credits_overlay()
	else:
		_open_credits_overlay()

func _open_settings_overlay() -> void:
	_hide_parent_menu_for_overlay()
	settings_open = true
	credits_open = false
	settings_panel.visible = true
	if credits_panel != null:
		credits_panel.visible = false
	settings_panel.move_to_front()
	_update_settings_text()
	_close_doll_menu()

func _close_settings_overlay() -> void:
	settings_open = false
	if settings_panel != null:
		settings_panel.visible = false
	_restore_parent_menu_after_overlay()

func _open_credits_overlay() -> void:
	_hide_parent_menu_for_overlay()
	credits_open = true
	settings_open = false
	credits_panel.visible = true
	if settings_panel != null:
		settings_panel.visible = false
	credits_panel.move_to_front()
	_close_doll_menu()

func _close_credits_overlay() -> void:
	credits_open = false
	if credits_panel != null:
		credits_panel.visible = false
	_restore_parent_menu_after_overlay()

func _hide_parent_menu_for_overlay() -> void:
	if menu_hidden_by_overlay != "":
		return
	if main_menu_open and main_menu_panel != null and main_menu_panel.visible:
		menu_hidden_by_overlay = "main"
		main_menu_panel.visible = false
	elif pause_menu_open and pause_menu_panel != null and pause_menu_panel.visible:
		menu_hidden_by_overlay = "pause"
		pause_menu_panel.visible = false

func _restore_parent_menu_after_overlay() -> void:
	if menu_hidden_by_overlay == "main" and main_menu_panel != null and main_menu_open:
		main_menu_panel.visible = true
	elif menu_hidden_by_overlay == "pause" and pause_menu_panel != null and pause_menu_open:
		pause_menu_panel.visible = true
	menu_hidden_by_overlay = ""

func _handle_settings_input(event: InputEvent) -> void:
	if event.is_action_pressed("open_settings") or event.is_action_pressed("close_overlay"):
		_toggle_settings()
	elif event.is_action_pressed("toggle_numeric_timer"):
		show_numeric_timer = not show_numeric_timer
		_update_settings_text()
	elif event.is_action_pressed("toggle_reduced_flashing"):
		reduced_flashing = not reduced_flashing
		_update_effect_overlays()
		_update_settings_text()
	elif event.is_action_pressed("text_scale_up"):
		text_scale = minf(1.35, text_scale + 0.1)
		_refresh_text_scale()
	elif event.is_action_pressed("text_scale_down"):
		text_scale = maxf(0.85, text_scale - 0.1)
		_refresh_text_scale()

func _update_settings_text() -> void:
	settings_label.text = "Accessibility settings\n\nMode: %s\nStory: no timer failure. Standard: 300s and +20s per restored doll. Dread: 240s, heavier smoke, no time reward.\n\nN numerical timer: %s\nR reduced flashing/smoke pulse: %s\n+/- text scale: %.0f%%\n\nAll essential whispers are shown as subtitles.\n\nPress O or Backspace to close." % [
		TIMING_LABELS[timing_mode],
		"on" if show_numeric_timer else "off",
		"on" if reduced_flashing else "off",
		text_scale * 100.0
	]

func _cycle_inventory(direction: int) -> void:
	if inventory.is_empty():
		_show_subtitle("No evidence item selected.")
		return
	selected_index = posmod(selected_index + direction, inventory.size())
	var item: ItemData = items[inventory[selected_index]] as ItemData
	_show_subtitle("Selected %s." % item.display_name)

func _close_top_overlay() -> void:
	if document_open:
		document_open = false
		document_panel.visible = false
	elif journal_open:
		journal_open = false
		journal_panel.visible = false
	elif settings_open:
		settings_open = false
		settings_panel.visible = false
	elif credits_open:
		credits_open = false
		credits_panel.visible = false
	else:
		_close_doll_menu()
	_update_ui()

func _close_all_overlays() -> void:
	document_open = false
	journal_open = false
	settings_open = false
	credits_open = false
	menu_hidden_by_overlay = ""
	if document_panel != null:
		document_panel.visible = false
	if journal_panel != null:
		journal_panel.visible = false
	if settings_panel != null:
		settings_panel.visible = false
	if credits_panel != null:
		credits_panel.visible = false
	if failure_panel != null:
		failure_panel.visible = false
	_close_doll_menu()

func _close_doll_menu() -> void:
	active_doll = null
	if doll_menu_panel != null:
		doll_menu_panel.visible = false

func _toggle_hud() -> void:
	hud_expanded = not hud_expanded
	_apply_hud_visibility()

func _apply_hud_visibility() -> void:
	if top_hud_panel != null:
		top_hud_panel.visible = hud_expanded
	if bottom_hud_panel != null:
		bottom_hud_panel.visible = hud_expanded
	for control in top_hud_controls:
		if control != null:
			if control == timer_bar:
				control.visible = _timer_hud_visible()
			elif control == timer_label:
				control.visible = _timer_hud_visible() and show_numeric_timer
			else:
				control.visible = hud_expanded
	for control in bottom_hud_controls:
		if control != null:
			control.visible = control == prompt_label or control == subtitle_label or hud_expanded
	if hud_toggle_button != null:
		hud_toggle_button.text = "HUD-" if hud_expanded else "HUD+"

func _timer_hud_visible() -> bool:
	return hud_expanded and timing_mode != TimingMode.STORY and _phase_can_fail_from_timer()

func _update_ui() -> void:
	if objective_label == null:
		return
	objective_label.text = _objective_text()
	timing_label.text = "Mode: %s" % TIMING_LABELS[timing_mode]
	smoke_label.text = "Smoke: %d" % smoke_stage
	if current_interactable == null:
		prompt_label.text = ""
	elif anchor_carried and current_interactable.kind == &"pedestal":
		prompt_label.text = "[E] Place anchor"
	else:
		prompt_label.text = "[E] %s" % current_interactable.interaction_text
	timer_bar.max_value = timer_max
	timer_bar.value = time_remaining
	timer_bar.visible = _timer_hud_visible()
	timer_label.visible = _timer_hud_visible() and show_numeric_timer
	timer_label.text = "%03d" % int(ceil(time_remaining))
	_update_inventory_slots()
	_update_journal_text()
	_apply_hud_visibility()
	_sync_player_input_lock()

func _sync_player_input_lock() -> void:
	if player == null:
		return
	player.input_locked = _player_input_blocked()
	if player.input_locked:
		player.velocity = Vector2.ZERO

func _player_input_blocked() -> bool:
	return main_menu_open or pause_menu_open or paused or game_over or document_open or journal_open or settings_open or credits_open or active_doll != null or phase == Phase.FIRE_STARTING or phase == Phase.RELEASE_CUTSCENE

func _update_inventory_slots() -> void:
	for index in range(inventory_slots.size()):
		var slot: Label = inventory_slots[index]
		if index < inventory.size():
			var id: StringName = inventory[index]
			var item: ItemData = items[id] as ItemData
			var marker := ">" if index == selected_index else " "
			slot.text = "%s %s" % [marker, item.display_name]
			slot.add_theme_color_override("font_color", Color(1.0, 0.94, 0.72) if index == selected_index else Color(0.88, 0.88, 0.82))
		else:
			slot.text = "-"
			slot.add_theme_color_override("font_color", Color(0.45, 0.47, 0.50))

func _update_journal_text() -> void:
	var lines: Array[String] = []
	lines.append("Evidence journal")
	lines.append("Names on card: %s" % ", ".join(RECORDED_NAMES))
	lines.append("Silhouettes seen: 7" if has_music_box_open else "Silhouettes seen: unknown")
	lines.append("")
	lines.append("Resolved dolls: %d / 6" % resolved_dolls.size())
	for doll_id in DOLL_ORDER:
		var doll: DollData = dolls[doll_id] as DollData
		if doll.unnamed:
			lines.append("Unknown anchor: waiting" if phase < Phase.COMPLETE else "Unknown anchor: remembered at pedestal")
		elif resolved_dolls.has(doll_id):
			var item: ItemData = items[doll.required_item_id] as ItemData
			lines.append("%s - %s" % [doll.child_name, item.display_name])
		else:
			lines.append("Unknown named doll - silhouette")
	lines.append("")
	lines.append("Carried evidence: %d" % inventory.size())
	for item_id in inventory:
		var item_data: ItemData = items[item_id] as ItemData
		lines.append("- %s" % item_data.display_name)
	lines.append("")
	lines.append("Clues:")
	if discovered_clues.is_empty():
		lines.append("- None yet.")
	else:
		for clue_id in discovered_clues.keys():
			lines.append("- %s" % String(discovered_clues[clue_id]))
	journal_label.text = "\n".join(lines)

func _objective_text() -> String:
	match phase:
		Phase.SAFE_EXPLORE:
			return "Explore safely. Open the music box."
		Phase.FIRE_STARTING:
			return "The nursery is remembering."
		Phase.INVESTIGATION:
			return "Return evidence. Resolved %d / 6." % resolved_dolls.size()
		Phase.PEDESTAL_READY:
			return "Carry the one the record forgot."
		Phase.CARRYING_ANCHOR:
			return "Bring the unknown doll to the pedestal."
		Phase.RELEASE_CUTSCENE:
			return "The record changes."
		Phase.COMPLETE:
			return "The nursery remembers seven."
		Phase.FAILED:
			return "The room is full of smoke."
		_:
			return "Burning Nursery"

func _show_subtitle(text: String) -> void:
	if subtitle_label != null:
		subtitle_label.text = text

func _change_phase(next_phase: Phase) -> void:
	phase = next_phase
	_update_ui()

func _run_self_test() -> void:
	if not has_music_box_open:
		_open_music_box()
	for id in ITEM_ORDER:
		if not inventory.has(id) and not _item_is_resolved(id):
			inventory.append(id)
	for node in interactables:
		if node.kind == &"doll":
			var doll_id: StringName = StringName(node.get_meta("doll_id"))
			if doll_id != &"anchor" and not resolved_dolls.has(doll_id):
				var doll: DollData = dolls[doll_id] as DollData
				_resolve_doll(node, doll, doll.required_item_id)
	_change_phase(Phase.PEDESTAL_READY)
	timer_draining = false
	_show_subtitle("Self-test complete: six dolls resolved. Carry the unknown doll to the pedestal.")
	_update_ui()
