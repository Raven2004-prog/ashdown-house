class_name ClueDefinition
extends Resource

@export var clue_id: StringName
@export var title: String
@export_multiline var observation: String
@export var related_doll_ids: Array[StringName] = []
@export var clue_type: StringName
@export var journal_icon: Texture2D
@export var world_object_scene: PackedScene

