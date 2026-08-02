class_name AshdownInteractionManager
extends Node

signal interaction_selected(target)

const DEFAULT_PROMPT := "WASD move | Mouse camera | Shift sprint | Ctrl crouch | J journal | E interact"

var player = null
var prompt_label: Label
var enabled := true

func setup(player_node, prompt: Label) -> void:
	player = player_node
	prompt_label = prompt
	if player != null:
		player.interaction_requested.connect(_on_interaction_requested)
		player.target_changed.connect(_on_target_changed)
	_update_prompt(null)

func set_interaction_enabled(value: bool) -> void:
	enabled = value
	if not enabled:
		clear_target()
	else:
		_update_prompt(player.get_current_target() if player != null and player.has_method("get_current_target") else null)

func clear_target() -> void:
	if player != null and player.has_method("clear_current_target"):
		player.clear_current_target()
	_update_prompt(null)

func _on_interaction_requested(target) -> void:
	if enabled and target != null and is_instance_valid(target) and target.visible:
		interaction_selected.emit(target)

func _on_target_changed(target) -> void:
	if not enabled:
		_update_prompt(null)
		return
	_update_prompt(target)

func _update_prompt(target) -> void:
	if prompt_label == null:
		return
	if target == null:
		prompt_label.text = DEFAULT_PROMPT
	else:
		prompt_label.text = "[E] %s: %s" % [target.prompt, target.display_name]
