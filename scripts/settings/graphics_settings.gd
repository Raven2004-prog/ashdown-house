extends Node

signal settings_changed

enum WorldQuality {
	PERFORMANCE,
	BALANCED,
	NATIVE,
}

const CONFIG_PATH := "user://graphics.cfg"
const WORLD_SCALES := {
	WorldQuality.PERFORMANCE: 0.33333334,
	WorldQuality.BALANCED: 0.5,
	WorldQuality.NATIVE: 1.0,
}

var world_quality: WorldQuality = WorldQuality.BALANCED
var brightness := 1.0
var text_scale := 1.0
var fog_enabled := true
var shadows_enabled := true
var reduced_flashing := false
var reduced_camera_motion := false
var fullscreen := true

func _ready() -> void:
	_load_settings()
	call_deferred("apply")

func set_world_quality(value: int) -> void:
	world_quality = clampi(value, WorldQuality.PERFORMANCE, WorldQuality.NATIVE) as WorldQuality
	_apply_viewport()
	_save_and_emit()

func set_brightness(value: float) -> void:
	brightness = clampf(value, 0.75, 1.3)
	_save_and_emit()

func set_text_scale(value: float) -> void:
	text_scale = clampf(value, 0.85, 1.35)
	_save_and_emit()

func set_fog_enabled(value: bool) -> void:
	fog_enabled = value
	_save_and_emit()

func set_shadows_enabled(value: bool) -> void:
	shadows_enabled = value
	_save_and_emit()

func set_reduced_flashing(value: bool) -> void:
	reduced_flashing = value
	_save_and_emit()

func set_reduced_camera_motion(value: bool) -> void:
	reduced_camera_motion = value
	_save_and_emit()

func set_fullscreen(value: bool) -> void:
	fullscreen = value
	_apply_window()
	_save_and_emit()

func apply() -> void:
	_apply_viewport()
	_apply_window()
	settings_changed.emit()

func get_world_scale() -> float:
	return float(WORLD_SCALES.get(world_quality, 0.5))

func get_quality_name() -> String:
	match world_quality:
		WorldQuality.PERFORMANCE:
			return "Performance"
		WorldQuality.NATIVE:
			return "Native"
		_:
			return "Balanced"

func _apply_viewport() -> void:
	var viewport := get_tree().root
	viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_NEAREST
	viewport.scaling_3d_scale = get_world_scale()
	viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	viewport.use_taa = false

func _apply_window() -> void:
	var window := get_tree().root
	window.mode = Window.MODE_EXCLUSIVE_FULLSCREEN if fullscreen else Window.MODE_WINDOWED
	if not fullscreen:
		window.size = Vector2i(1280, 720)

func _save_and_emit() -> void:
	_save_settings()
	settings_changed.emit()

func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("graphics", "world_quality", int(world_quality))
	config.set_value("graphics", "brightness", brightness)
	config.set_value("graphics", "text_scale", text_scale)
	config.set_value("graphics", "fog_enabled", fog_enabled)
	config.set_value("graphics", "shadows_enabled", shadows_enabled)
	config.set_value("graphics", "reduced_flashing", reduced_flashing)
	config.set_value("graphics", "reduced_camera_motion", reduced_camera_motion)
	config.set_value("graphics", "fullscreen", fullscreen)
	config.save(CONFIG_PATH)

func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) != OK:
		return
	world_quality = clampi(int(config.get_value("graphics", "world_quality", int(WorldQuality.BALANCED))), WorldQuality.PERFORMANCE, WorldQuality.NATIVE) as WorldQuality
	brightness = clampf(float(config.get_value("graphics", "brightness", 1.0)), 0.75, 1.3)
	text_scale = clampf(float(config.get_value("graphics", "text_scale", 1.0)), 0.85, 1.35)
	fog_enabled = bool(config.get_value("graphics", "fog_enabled", true))
	shadows_enabled = bool(config.get_value("graphics", "shadows_enabled", true))
	reduced_flashing = bool(config.get_value("graphics", "reduced_flashing", false))
	reduced_camera_motion = bool(config.get_value("graphics", "reduced_camera_motion", false))
	fullscreen = bool(config.get_value("graphics", "fullscreen", true))
