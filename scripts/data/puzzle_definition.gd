class_name PuzzleDefinition
extends Resource

@export var puzzle_id: StringName
@export var prerequisite_flags: Array[StringName] = []
@export var completion_flags: Array[StringName] = []
@export var required_items: Array[StringName] = []
@export var persistent_after_checkpoint := true
