class_name AshdownHUD
extends Control

signal resume_requested

@onready var prompt_label: Label = %PromptLabel
@onready var subtitle_label: Label = %SubtitleLabel
@onready var reticle_label: Label = %ReticleLabel
@onready var journal_panel: Control = %JournalPanel
@onready var journal_label: Label = %JournalLabel
@onready var code_panel: Control = %CodePanel
@onready var code_label: Label = %CodeLabel
@onready var pause_layer: Control = %PauseLayer
@onready var quality_value: Label = %QualityValue
@onready var brightness_slider: HSlider = %BrightnessSlider
@onready var text_scale_slider: HSlider = %TextScaleSlider
@onready var master_volume_slider: HSlider = %MasterVolumeSlider
@onready var music_volume_slider: HSlider = %MusicVolumeSlider
@onready var ambience_volume_slider: HSlider = %AmbienceVolumeSlider
@onready var sfx_volume_slider: HSlider = %SFXVolumeSlider
@onready var ui_volume_slider: HSlider = %UIVolumeSlider
@onready var voice_volume_slider: HSlider = %VoiceVolumeSlider
@onready var mute_toggle: CheckButton = %MuteToggle
@onready var fullscreen_toggle: CheckButton = %FullscreenToggle
@onready var fog_toggle: CheckButton = %FogToggle
@onready var shadows_toggle: CheckButton = %ShadowsToggle
@onready var flashing_toggle: CheckButton = %FlashingToggle

var base_font_sizes: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_cache_font_sizes(self)
	%PerformanceButton.pressed.connect(func(): GraphicsSettings.set_world_quality(GraphicsSettings.WorldQuality.PERFORMANCE))
	%BalancedButton.pressed.connect(func(): GraphicsSettings.set_world_quality(GraphicsSettings.WorldQuality.BALANCED))
	%NativeButton.pressed.connect(func(): GraphicsSettings.set_world_quality(GraphicsSettings.WorldQuality.NATIVE))
	brightness_slider.value_changed.connect(GraphicsSettings.set_brightness)
	text_scale_slider.value_changed.connect(GraphicsSettings.set_text_scale)
	master_volume_slider.value_changed.connect(func(value: float): AudioManager.set_bus_level(&"Master", value))
	music_volume_slider.value_changed.connect(func(value: float): AudioManager.set_bus_level(&"Music", value))
	ambience_volume_slider.value_changed.connect(func(value: float): AudioManager.set_bus_level(&"Ambience", value))
	sfx_volume_slider.value_changed.connect(func(value: float): AudioManager.set_bus_level(&"SFX", value))
	ui_volume_slider.value_changed.connect(func(value: float): AudioManager.set_bus_level(&"UI", value))
	voice_volume_slider.value_changed.connect(func(value: float): AudioManager.set_bus_level(&"Voice", value))
	mute_toggle.toggled.connect(AudioManager.set_master_muted)
	fullscreen_toggle.toggled.connect(GraphicsSettings.set_fullscreen)
	fog_toggle.toggled.connect(GraphicsSettings.set_fog_enabled)
	shadows_toggle.toggled.connect(GraphicsSettings.set_shadows_enabled)
	flashing_toggle.toggled.connect(GraphicsSettings.set_reduced_flashing)
	%ResumeButton.pressed.connect(func(): resume_requested.emit())
	GraphicsSettings.settings_changed.connect(sync_settings)
	AudioManager.audio_settings_changed.connect(sync_audio_settings)
	sync_settings()
	sync_audio_settings()

func set_pause_visible(value: bool) -> void:
	pause_layer.visible = value

func is_pause_visible() -> bool:
	return pause_layer.visible

func sync_settings() -> void:
	quality_value.text = "%s world (%d%%)" % [GraphicsSettings.get_quality_name(), roundi(GraphicsSettings.get_world_scale() * 100.0)]
	brightness_slider.set_value_no_signal(GraphicsSettings.brightness)
	text_scale_slider.set_value_no_signal(GraphicsSettings.text_scale)
	fullscreen_toggle.set_pressed_no_signal(GraphicsSettings.fullscreen)
	fog_toggle.set_pressed_no_signal(GraphicsSettings.fog_enabled)
	shadows_toggle.set_pressed_no_signal(GraphicsSettings.shadows_enabled)
	flashing_toggle.set_pressed_no_signal(GraphicsSettings.reduced_flashing)
	_apply_text_scale(GraphicsSettings.text_scale)

func sync_audio_settings() -> void:
	master_volume_slider.set_value_no_signal(AudioManager.get_bus_level(&"Master"))
	music_volume_slider.set_value_no_signal(AudioManager.get_bus_level(&"Music"))
	ambience_volume_slider.set_value_no_signal(AudioManager.get_bus_level(&"Ambience"))
	sfx_volume_slider.set_value_no_signal(AudioManager.get_bus_level(&"SFX"))
	ui_volume_slider.set_value_no_signal(AudioManager.get_bus_level(&"UI"))
	voice_volume_slider.set_value_no_signal(AudioManager.get_bus_level(&"Voice"))
	mute_toggle.set_pressed_no_signal(AudioManager.master_muted)

func _cache_font_sizes(node: Node) -> void:
	if node is Control:
		var control := node as Control
		var size := control.get_theme_font_size("font_size")
		if size > 0:
			base_font_sizes[control.get_path()] = size
	for child in node.get_children():
		_cache_font_sizes(child)

func _apply_text_scale(value: float) -> void:
	for path in base_font_sizes:
		var control := get_node_or_null(path) as Control
		if control != null:
			control.add_theme_font_size_override("font_size", roundi(float(base_font_sizes[path]) * value))
