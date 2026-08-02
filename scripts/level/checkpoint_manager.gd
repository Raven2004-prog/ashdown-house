class_name AshdownCheckpointManager
extends Node

const CONFIG_PATH := "user://ashdown_checkpoint.cfg"

var latest_checkpoint: Dictionary = {}

func save_checkpoint(snapshot: Dictionary, persist := true) -> void:
	latest_checkpoint = snapshot.duplicate(true)
	if persist:
		var config := ConfigFile.new()
		config.set_value("checkpoint", "snapshot", latest_checkpoint)
		config.save(CONFIG_PATH)

func has_checkpoint() -> bool:
	return not latest_checkpoint.is_empty()

func get_checkpoint() -> Dictionary:
	return latest_checkpoint.duplicate(true)

func load_persistent_checkpoint() -> bool:
	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) != OK:
		return false
	var stored = config.get_value("checkpoint", "snapshot", {})
	if not stored is Dictionary or stored.is_empty():
		return false
	latest_checkpoint = (stored as Dictionary).duplicate(true)
	return true

func clear_checkpoint() -> void:
	latest_checkpoint.clear()
	if FileAccess.file_exists(CONFIG_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(CONFIG_PATH))
