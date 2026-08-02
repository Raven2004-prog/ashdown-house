class_name AshdownLibraryBenchmark
extends Node3D

const SHELF_OPEN_OFFSET := Vector3(1.65, 0, 0)

@onready var sliding_shelf: Node3D = $Furniture/L05_SlidingShelf

var sliding_shelf_closed_position := Vector3.ZERO
var shelf_open := false

func _ready() -> void:
	sliding_shelf_closed_position = sliding_shelf.position

func apply_gameplay_state(flags: Dictionary) -> void:
	var should_open := bool(flags.get("library_bookcase_open", false)) or bool(flags.get("library_shelf_open", false))
	if should_open == shelf_open:
		return
	shelf_open = should_open
	var destination := sliding_shelf_closed_position + (SHELF_OPEN_OFFSET if shelf_open else Vector3.ZERO)
	if is_inside_tree():
		var tween := create_tween()
		tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(sliding_shelf, "position", destination, 0.8)
	else:
		sliding_shelf.position = destination
