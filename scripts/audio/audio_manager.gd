extends Node

signal audio_settings_changed

const CONFIG_PATH := "user://audio.cfg"
const BUS_NAMES := [&"Master", &"Music", &"Ambience", &"SFX", &"UI", &"Voice"]
const SAMPLE_RATE := 22050

var bus_levels := {
	&"Master": 0.82,
	&"Music": 0.72,
	&"Ambience": 0.76,
	&"SFX": 0.86,
	&"UI": 0.78,
	&"Voice": 0.90,
}
var master_muted := false
var stream_cache: Dictionary = {}
var one_shot_index := 0
var last_room: StringName = &""

var ambience_player: AudioStreamPlayer
var fire_player: AudioStreamPlayer
var boiler_player: AudioStreamPlayer3D

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_buses()
	_load_settings()
	_apply_levels()
	_create_players()

func set_bus_level(bus_name: StringName, linear_value: float) -> void:
	if not bus_levels.has(bus_name):
		return
	bus_levels[bus_name] = clampf(linear_value, 0.0, 1.0)
	_apply_bus_level(bus_name)
	_save_settings()
	audio_settings_changed.emit()

func get_bus_level(bus_name: StringName) -> float:
	return float(bus_levels.get(bus_name, 1.0))

func set_master_muted(value: bool) -> void:
	master_muted = value
	var master_index := AudioServer.get_bus_index(&"Master")
	if master_index >= 0:
		AudioServer.set_bus_mute(master_index, value)
	_save_settings()
	audio_settings_changed.emit()

func play_ui_cue(cue: StringName = &"select") -> void:
	_play_2d(cue, &"UI", -8.0, 1.0)

func play_world_cue(cue: StringName, world_position: Vector3, gain_db := -4.0, bus_name: StringName = &"SFX") -> void:
	var player := AudioStreamPlayer3D.new()
	player.name = "WorldCue_%d" % one_shot_index
	one_shot_index += 1
	player.bus = bus_name
	player.stream = _stream(cue)
	player.position = world_position
	player.volume_db = gain_db
	player.max_distance = 15.0
	player.unit_size = 2.5
	player.finished.connect(player.queue_free)
	add_child(player)
	player.play()

func play_footstep(world_position: Vector3) -> void:
	var surface := _surface_for_position(world_position)
	var player := AudioStreamPlayer3D.new()
	player.name = "Footstep_%d" % one_shot_index
	one_shot_index += 1
	player.bus = &"SFX"
	player.stream = _stream(surface)
	player.position = world_position
	player.volume_db = -7.0
	player.pitch_scale = 0.93 + float(one_shot_index % 5) * 0.025
	player.max_distance = 9.0
	player.finished.connect(player.queue_free)
	add_child(player)
	player.play()

func update_house_state(player_position: Vector3, flags: Dictionary, pressure_fraction: float) -> void:
	if ambience_player == null:
		return
	var room := _room_for_position(player_position)
	if room != last_room:
		last_room = room
		ambience_player.pitch_scale = {
			&"library": 0.90,
			&"dormitory": 0.84,
			&"bathroom": 1.12,
			&"kitchen": 1.04,
			&"boiler": 0.72,
		}.get(room, 1.0)
	var fire_active := bool(flags.get("fire_started", false)) and not bool(flags.get("final_doll_placed", false))
	if fire_active and not fire_player.playing:
		fire_player.play()
	elif not fire_active and fire_player.playing:
		fire_player.stop()
	fire_player.volume_db = lerpf(-18.0, -6.0, clampf(pressure_fraction, 0.0, 1.0))
	var boiler_active := room == &"boiler" and not bool(flags.get("boiler_disabled", false))
	if boiler_active and not boiler_player.playing:
		boiler_player.position = Vector3(0, 1.1, -12.8)
		boiler_player.play()
	elif not boiler_active and boiler_player.playing:
		boiler_player.stop()
	ambience_player.volume_db = lerpf(-15.0, -9.0, clampf(pressure_fraction, 0.0, 1.0))

func stop_all_for_test() -> void:
	for player in [ambience_player, fire_player, boiler_player]:
		if player != null:
			player.stop()
	for child in get_children():
		if child is AudioStreamPlayer or child is AudioStreamPlayer3D:
			(child as Node).queue_free()
	stream_cache.clear()

func _ensure_buses() -> void:
	for bus_name in BUS_NAMES:
		if AudioServer.get_bus_index(bus_name) >= 0:
			continue
		AudioServer.add_bus()
		var index := AudioServer.bus_count - 1
		AudioServer.set_bus_name(index, bus_name)
		if bus_name != &"Master":
			AudioServer.set_bus_send(index, &"Master")

func _create_players() -> void:
	ambience_player = AudioStreamPlayer.new()
	ambience_player.name = "HouseAmbience"
	ambience_player.bus = &"Ambience"
	ambience_player.stream = _stream(&"house_ambience")
	ambience_player.volume_db = -14.0
	add_child(ambience_player)
	ambience_player.play()
	fire_player = AudioStreamPlayer.new()
	fire_player.name = "FirePressure"
	fire_player.bus = &"Ambience"
	fire_player.stream = _stream(&"fire")
	fire_player.volume_db = -18.0
	add_child(fire_player)
	boiler_player = AudioStreamPlayer3D.new()
	boiler_player.name = "BoilerMachinery"
	boiler_player.bus = &"Ambience"
	boiler_player.stream = _stream(&"boiler")
	boiler_player.max_distance = 22.0
	boiler_player.volume_db = -9.0
	add_child(boiler_player)

func _play_2d(cue: StringName, bus_name: StringName, gain_db: float, pitch: float) -> void:
	var player := AudioStreamPlayer.new()
	player.name = "UICue_%d" % one_shot_index
	one_shot_index += 1
	player.bus = bus_name
	player.stream = _stream(cue)
	player.volume_db = gain_db
	player.pitch_scale = pitch
	player.finished.connect(player.queue_free)
	add_child(player)
	player.play()

func _stream(cue: StringName) -> AudioStreamWAV:
	if stream_cache.has(cue):
		return stream_cache[cue]
	var settings := _cue_settings(cue)
	var duration := float(settings.duration)
	var frame_count := maxi(1, int(SAMPLE_RATE * duration))
	var bytes := PackedByteArray()
	bytes.resize(frame_count * 2)
	for frame in range(frame_count):
		var time := float(frame) / SAMPLE_RATE
		var envelope := _envelope(time, duration, bool(settings.loop))
		var sample := _sample_cue(cue, time, frame) * envelope
		bytes.encode_s16(frame * 2, int(clampf(sample, -1.0, 1.0) * 32760.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = bytes
	if bool(settings.loop):
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = frame_count
	stream_cache[cue] = stream
	return stream

func _cue_settings(cue: StringName) -> Dictionary:
	if cue in [&"house_ambience", &"fire", &"boiler"]:
		return {"duration": 6.0, "loop": true}
	if cue in [&"whisper", &"release"]:
		return {"duration": 1.6, "loop": false}
	return {"duration": 0.34, "loop": false}

func _sample_cue(cue: StringName, time: float, frame: int) -> float:
	var noise := _noise(frame)
	match cue:
		&"house_ambience":
			return sin(TAU * 37.0 * time) * 0.08 + sin(TAU * 61.0 * time) * 0.035
		&"fire":
			return noise * (0.10 + 0.08 * sin(TAU * 1.5 * time)) + sin(TAU * 83.0 * time) * 0.025
		&"boiler":
			return sin(TAU * 31.0 * time) * 0.18 + sin(TAU * 62.0 * time) * 0.07
		&"footstep_wood":
			return noise * exp(-time * 18.0) * 0.55 + sin(TAU * 95.0 * time) * exp(-time * 22.0) * 0.20
		&"footstep_tile":
			return noise * exp(-time * 28.0) * 0.32 + sin(TAU * 420.0 * time) * exp(-time * 24.0) * 0.22
		&"footstep_metal":
			return sin(TAU * 560.0 * time) * exp(-time * 18.0) * 0.34 + noise * exp(-time * 24.0) * 0.16
		&"door":
			return sin(TAU * (74.0 - time * 30.0) * time) * exp(-time * 7.0) * 0.48 + noise * 0.08
		&"paper":
			return noise * sin(minf(PI, time * 11.0)) * 0.20
		&"puzzle":
			return (sin(TAU * 310.0 * time) + sin(TAU * 465.0 * time) * 0.5) * exp(-time * 5.0) * 0.22
		&"alarm":
			return sin(TAU * 880.0 * time) * exp(-time * 2.4) * 0.32
		&"whisper":
			return noise * sin(PI * time / 1.6) * (0.16 + 0.08 * sin(TAU * 5.0 * time))
		&"smoke_surge":
			return noise * exp(-time * 2.5) * 0.42
		&"release":
			return (sin(TAU * 220.0 * time) + sin(TAU * 330.0 * time) + sin(TAU * 440.0 * time)) * sin(PI * time / 1.6) * 0.10
		_:
			return sin(TAU * 520.0 * time) * exp(-time * 14.0) * 0.28

func _noise(frame: int) -> float:
	var value := int((frame * 1103515245 + 12345) & 0x7fffffff)
	return float(value % 65536) / 32768.0 - 1.0

func _envelope(time: float, duration: float, looping: bool) -> float:
	if looping:
		var edge := minf(time, duration - time)
		return clampf(edge / 0.08, 0.0, 1.0)
	var attack := clampf(time / 0.012, 0.0, 1.0)
	var release := clampf((duration - time) / minf(0.12, duration * 0.35), 0.0, 1.0)
	return attack * release

func _surface_for_position(position: Vector3) -> StringName:
	if position.x >= 9.0 and position.z <= -6.0:
		return &"footstep_tile"
	if position.x >= -8.0 and position.x <= 8.0 and position.z <= -7.0:
		return &"footstep_metal"
	return &"footstep_wood"

func _room_for_position(position: Vector3) -> StringName:
	if position.x <= -9.0 and position.z >= -5.0:
		return &"library"
	if position.x <= -9.0 and position.z <= -6.0:
		return &"dormitory"
	if position.x >= 9.0 and position.x <= 17.0 and position.z <= -6.0:
		return &"bathroom"
	if position.x >= 18.0 and position.z <= -6.0:
		return &"kitchen"
	if position.x >= -8.0 and position.x <= 8.0 and position.z <= -7.0:
		return &"boiler"
	return &"hall"

func _apply_levels() -> void:
	for bus_name in bus_levels:
		_apply_bus_level(bus_name)
	var master_index := AudioServer.get_bus_index(&"Master")
	if master_index >= 0:
		AudioServer.set_bus_mute(master_index, master_muted)

func _apply_bus_level(bus_name: StringName) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		return
	var value := maxf(0.0001, float(bus_levels.get(bus_name, 1.0)))
	AudioServer.set_bus_volume_db(index, linear_to_db(value))

func _save_settings() -> void:
	var config := ConfigFile.new()
	for bus_name in bus_levels:
		config.set_value("audio", String(bus_name).to_lower(), bus_levels[bus_name])
	config.set_value("audio", "muted", master_muted)
	config.save(CONFIG_PATH)

func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) != OK:
		return
	for bus_name in bus_levels:
		bus_levels[bus_name] = clampf(float(config.get_value("audio", String(bus_name).to_lower(), bus_levels[bus_name])), 0.0, 1.0)
	master_muted = bool(config.get_value("audio", "muted", false))
