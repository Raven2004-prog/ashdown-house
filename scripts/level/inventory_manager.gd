class_name AshdownInventoryManager
extends Node

signal inventory_changed

var evidence: Dictionary = {}
var selected_evidence_id: StringName = &""

func collect_evidence(evidence_id: StringName, title: String, observation: String) -> bool:
	if evidence.has(evidence_id):
		return false
	evidence[evidence_id] = {
		"title": title,
		"observation": observation
	}
	if selected_evidence_id == &"":
		selected_evidence_id = evidence_id
	inventory_changed.emit()
	return true

func has_evidence(evidence_id: StringName) -> bool:
	return evidence.has(evidence_id)

func get_evidence_title(evidence_id: StringName) -> String:
	if not evidence.has(evidence_id):
		return String(evidence_id)
	return String(evidence[evidence_id].get("title", evidence_id))

func get_all_evidence() -> Dictionary:
	return evidence.duplicate(true)

func get_snapshot() -> Dictionary:
	return {
		"evidence": evidence.duplicate(true),
		"selected_evidence_id": selected_evidence_id
	}

func restore_snapshot(snapshot: Dictionary) -> void:
	evidence = snapshot.get("evidence", {}).duplicate(true)
	selected_evidence_id = StringName(snapshot.get("selected_evidence_id", &""))
	inventory_changed.emit()
