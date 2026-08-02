class_name AshdownJournalManager
extends Node

signal journal_changed

var doll_roster: Array = []
var known_profiles: Dictionary = {}
var heard_whispers: Dictionary = {}
var discovered_clues: Dictionary = {}
var ambient_observations: Dictionary = {}

func configure_dolls(dolls: Array) -> void:
	doll_roster = dolls.duplicate(true)
	journal_changed.emit()

func record_profile(doll_id: StringName, display_name: String) -> void:
	known_profiles[doll_id] = display_name
	journal_changed.emit()

func record_whisper(doll_id: StringName, display_name: String) -> void:
	heard_whispers[doll_id] = display_name
	journal_changed.emit()

func record_all_profiles(dolls: Array) -> void:
	for doll in dolls:
		var doll_data: Dictionary = doll
		known_profiles[StringName(doll_data["id"])] = String(doll_data["name"])
	journal_changed.emit()

func record_clue(clue_id: StringName, title: String, observation: String) -> void:
	discovered_clues[clue_id] = {
		"title": title,
		"observation": observation
	}
	journal_changed.emit()

func record_observation(observation_id: StringName, title: String) -> void:
	ambient_observations[observation_id] = title
	journal_changed.emit()

func build_text(inventory, flags: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append("Ashdown journal")
	lines.append("Dolls heard: %d / 7" % heard_whispers.size())
	lines.append("Identities proven: %d / 7" % known_profiles.size())
	for doll in doll_roster:
		var doll_data: Dictionary = doll
		var id := StringName(doll_data["id"])
		var status := "identified" if known_profiles.has(id) else ("heard" if heard_whispers.has(id) else "unknown")
		lines.append("- %s: %s" % [String(doll_data["name"]), status])
	lines.append("")
	lines.append("Clues found: %d" % discovered_clues.size())
	for clue_id in discovered_clues.keys():
		var entry: Dictionary = discovered_clues[clue_id]
		lines.append("- %s: %s" % [String(entry.get("title", clue_id)), String(entry.get("observation", ""))])
	lines.append("")
	lines.append("Evidence inventory: %d" % inventory.evidence.size())
	for item_id in inventory.evidence.keys():
		lines.append("- %s" % inventory.get_evidence_title(item_id))
	lines.append("Optional details noticed: %d" % ambient_observations.size())
	lines.append("")
	var flag_names: Array[String] = []
	for flag in flags.keys():
		flag_names.append(String(flag))
	lines.append("Flags: %s" % ", ".join(flag_names))
	lines.append("")
	lines.append("Press J or Esc to close.")
	return "\n".join(lines)

func get_snapshot() -> Dictionary:
	return {
		"known_profiles": known_profiles.duplicate(true),
		"heard_whispers": heard_whispers.duplicate(true),
		"discovered_clues": discovered_clues.duplicate(true),
		"ambient_observations": ambient_observations.duplicate(true)
	}

func restore_snapshot(snapshot: Dictionary) -> void:
	known_profiles = snapshot.get("known_profiles", {}).duplicate(true)
	heard_whispers = snapshot.get("heard_whispers", {}).duplicate(true)
	discovered_clues = snapshot.get("discovered_clues", {}).duplicate(true)
	ambient_observations = snapshot.get("ambient_observations", {}).duplicate(true)
	journal_changed.emit()
