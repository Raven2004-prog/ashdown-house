class_name DollDefinition
extends Resource

@export var doll_id: StringName
@export var display_name: String
@export var age: int
@export_multiline var initial_line: String
@export_multiline var first_clue_line: String
@export_multiline var completed_line: String
@export var required_clue_ids: Array[StringName] = []
@export var doll_scene: PackedScene
@export var portrait: Texture2D

