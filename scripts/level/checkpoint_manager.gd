class_name AshdownCheckpointManager
extends Node

var latest_checkpoint: Dictionary = {}

func save_checkpoint(snapshot: Dictionary) -> void:
	latest_checkpoint = snapshot.duplicate(true)

func has_checkpoint() -> bool:
	return not latest_checkpoint.is_empty()

func get_checkpoint() -> Dictionary:
	return latest_checkpoint.duplicate(true)
