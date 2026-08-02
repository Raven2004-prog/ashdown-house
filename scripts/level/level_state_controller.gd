class_name AshdownLevelStateController
extends Node

signal state_changed(state)
signal flags_changed

const ARRIVAL := &"ARRIVAL"
const FIRE_STARTED := &"FIRE_STARTED"
const EAST_WING_OPEN := &"EAST_WING_OPEN"
const SOUTH_WING_OPEN := &"SOUTH_WING_OPEN"
const BOILER_DISABLED := &"BOILER_DISABLED"
const FINAL_DEDUCTION := &"FINAL_DEDUCTION"
const COMPLETE := &"COMPLETE"
const FAILED := &"FAILED"
const REQUIRED_SAVE_FLAGS: Array[StringName] = [
	&"register_taken",
	&"fire_started",
	&"library_catalog_solved",
	&"library_bookcase_open",
	&"classroom_unlocked",
	&"classroom_fuses_solved",
	&"projector_revealed",
	&"classroom_seating_solved",
	&"librarian_desk_opened",
	&"dormitory_unlocked",
	&"bathroom_unlocked",
	&"kitchen_fire_extinguished",
	&"kitchen_weight_solved",
	&"pantry_opened",
	&"towel_cabinet_opened",
	&"drain_closed",
	&"drain_accessed",
	&"wringer_crank_collected",
	&"wringer_operated",
	&"dormitory_music_solved",
	&"boiler_wheel_installed",
	&"boiler_disabled",
	&"mirror_message_revealed",
	&"drain_shoe_retrieved"
]

var state: StringName = ARRIVAL
var flags: Dictionary = {}

func set_state(next_state: StringName) -> void:
	if state == next_state:
		return
	state = next_state
	state_changed.emit(state)

func set_flag(flag: StringName, value := true) -> void:
	flags[flag] = value
	flags_changed.emit()

func has_flag(flag: StringName) -> bool:
	return bool(flags.get(flag, false))

func start_fire() -> void:
	set_flag(&"register_taken", true)
	set_flag(&"fire_started", true)
	set_state(FIRE_STARTED)

func complete_library_catalog() -> void:
	set_flag(&"library_catalog_solved", true)

func complete_library_code() -> void:
	set_flag(&"library_shelf_open", true)
	set_flag(&"library_bookcase_open", true)

func complete_classroom_fuses() -> void:
	set_flag(&"classroom_fuses_solved", true)

func complete_classroom_seating() -> void:
	set_flag(&"classroom_seating_solved", true)

func complete_bathroom_cabinet() -> void:
	set_flag(&"towel_cabinet_opened", true)

func complete_kitchen_scale() -> void:
	set_flag(&"kitchen_weight_solved", true)
	set_flag(&"pantry_opened", true)

func complete_dormitory_music() -> void:
	set_flag(&"dormitory_music_solved", true)

func complete_boiler_pressure() -> void:
	set_flag(&"boiler_pressure_solved", true)
	set_flag(&"steam_routed_to_bathroom", true)
	set_flag(&"boiler_disabled", true)
	set_state(BOILER_DISABLED)

func describe_door(display_name: String, state_text: String) -> String:
	if state_text.begins_with("open") or state_text.begins_with("available"):
		return "%s is open for this blockout route." % display_name
	if state_text == "locks_after_trigger":
		return "%s still opens, but it feels ready to slam shut." % display_name if not has_flag(&"fire_started") else "%s is chained shut. The fire phase has begun." % display_name
	if state_text == "requires_brass_key":
		return "%s unlocks with the brass key." % display_name if has_flag(&"classroom_unlocked") else "%s needs the classroom brass key." % display_name
	if state_text == "four_symbol_lock":
		return "%s opens with the dormitory symbols." % display_name if has_flag(&"dormitory_unlocked") else "%s has a four-symbol lock. Find the classroom seating evidence." % display_name
	if state_text == "requires_valve_wheel":
		return "%s opens with the valve wheel." % display_name if has_flag(&"boiler_wheel_installed") else "%s needs a valve wheel before the boiler route opens." % display_name
	if state_text == "requires_bathroom_key":
		return "%s unlocks with the bathroom key." % display_name if has_flag(&"bathroom_unlocked") else "%s needs the bathroom key." % display_name
	if state_text == "fire_blocked":
		return "%s is passable after the extinguisher clears the doorway." % display_name if has_flag(&"kitchen_fire_extinguished") else "%s is blocked by doorway fire." % display_name
	if state_text == "opens_from_boiler_side":
		return "%s has loosened enough for this blockout route." % display_name if has_flag(&"dormitory_unlocked") else "%s opens from the boiler side." % display_name
	if state_text == "opens_after_shutdown":
		return "%s opens after the boiler shutdown sequence." % display_name if has_flag(&"boiler_disabled") else "%s opens after the boiler shutdown sequence." % display_name
	if state_text == "jammed_until_pushed":
		return "%s has been pushed loose from the bathroom side." % display_name if has_flag(&"bathroom_unlocked") else "%s is jammed until it is pushed from the bathroom side." % display_name
	return "Blocked: %s." % state_text.replace("_", " ")

func get_snapshot() -> Dictionary:
	return {
		"state": state,
		"flags": flags.duplicate(true)
	}

func restore_snapshot(snapshot: Dictionary) -> void:
	state = StringName(snapshot.get("state", ARRIVAL))
	flags = snapshot.get("flags", {}).duplicate(true)
	state_changed.emit(state)
	flags_changed.emit()
