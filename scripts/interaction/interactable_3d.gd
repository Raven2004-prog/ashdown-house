class_name Interactable3D
extends Area3D

@export var interaction_id: StringName
@export var kind: StringName = &"clue"
@export var display_name := "Object"
@export var prompt := "Inspect"
@export_multiline var observation := ""
@export var interaction_radius := 0.7

var highlighted := false
var authored_visual: Node3D
var hide_visual_on_collect := false
var hide_visual_when_unavailable := false
var highlight_material: StandardMaterial3D

func _ready() -> void:
	collision_layer = 1
	collision_mask = 1
	monitoring = true
	input_ray_pickable = true
	if get_node_or_null("CollisionShape3D") == null:
		var shape := CollisionShape3D.new()
		var sphere := SphereShape3D.new()
		sphere.radius = interaction_radius
		shape.shape = sphere
		add_child(shape)
	add_to_group("ashdown_interactable")

func set_highlighted(value: bool) -> void:
	if highlighted == value:
		return
	highlighted = value
	var root: Node = authored_visual if authored_visual != null and is_instance_valid(authored_visual) else self
	_apply_highlight_overlay(root, _get_highlight_material() if highlighted else null)

func bind_authored_visual(visual: Node3D, hide_on_collect: bool, hide_when_unavailable: bool) -> void:
	authored_visual = visual
	hide_visual_on_collect = hide_on_collect
	hide_visual_when_unavailable = hide_when_unavailable

func set_visual_available(value: bool) -> void:
	if authored_visual != null and is_instance_valid(authored_visual) and hide_visual_when_unavailable:
		authored_visual.visible = value

func collect_visual() -> void:
	if authored_visual != null and is_instance_valid(authored_visual) and hide_visual_on_collect:
		authored_visual.visible = false

func _get_highlight_material() -> StandardMaterial3D:
	if highlight_material != null:
		return highlight_material
	highlight_material = StandardMaterial3D.new()
	highlight_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	highlight_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	highlight_material.albedo_color = Color(1.0, 0.72, 0.20, 0.16)
	highlight_material.emission_enabled = true
	highlight_material.emission = Color(1.0, 0.62, 0.16)
	highlight_material.emission_energy_multiplier = 0.65
	return highlight_material

func _apply_highlight_overlay(node: Node, overlay: Material) -> void:
	if node is MeshInstance3D:
		(node as MeshInstance3D).material_overlay = overlay
	for child in node.get_children():
		_apply_highlight_overlay(child, overlay)
