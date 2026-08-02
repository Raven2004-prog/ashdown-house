class_name AshInteractable
extends Area2D

@export var interaction_id: StringName
@export var kind: StringName = &"clue"
@export var display_label := "Object"
@export var interaction_text := "Inspect"
@export var body_size := Vector2(32, 16)
@export var body_color := Color(0.45, 0.48, 0.52)
@export var visual_alpha := 1.0

var highlighted := false:
	set(value):
		highlighted = value
		queue_redraw()

func _ready() -> void:
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = body_size + Vector2(8, 8)
	shape.shape = rect
	add_child(shape)
	input_pickable = false

func _draw() -> void:
	var rect := Rect2(-body_size * 0.5, body_size)
	var drawn_color := Color(body_color.r, body_color.g, body_color.b, body_color.a * visual_alpha)
	draw_rect(rect.grow_side(SIDE_BOTTOM, 3).grow_side(SIDE_RIGHT, 2), Color(0.02, 0.018, 0.018, 0.34 * visual_alpha), true)
	draw_rect(rect, drawn_color, true)
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 1)), Color(body_color.lightened(0.22), visual_alpha), true)
	draw_rect(Rect2(rect.position + Vector2(0, rect.size.y - 2), Vector2(rect.size.x, 2)), Color(body_color.darkened(0.32), visual_alpha), true)
	draw_rect(rect, Color(0.09, 0.1, 0.12, visual_alpha), false, 1.0)
	if highlighted:
		draw_rect(rect.grow(3), Color(1.0, 0.9, 0.45), false, 2.0)
	var font := ThemeDB.fallback_font
	var label_pos := Vector2(-body_size.x * 0.5 + 2, -body_size.y * 0.5 - 3)
	draw_string(font, label_pos + Vector2(1, 1), display_label, HORIZONTAL_ALIGNMENT_LEFT, body_size.x + 46, 9, Color(0.01, 0.01, 0.012, 0.95))
	draw_string(font, label_pos, display_label, HORIZONTAL_ALIGNMENT_LEFT, body_size.x + 46, 9, Color(0.95, 0.95, 0.9))
