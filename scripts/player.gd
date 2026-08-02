extends CharacterBody2D

@export var speed := 72.0
@export var acceleration := 700.0
@export var deceleration := 900.0

var facing := Vector2.DOWN
var carrying_ari := false
var input_locked := false

func _ready() -> void:
	var sprite := Sprite2D.new()
	sprite.name = "Body"
	sprite.texture = load("res://art/approved/nursery_2_5d/player.png") as Texture2D
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = Vector2(0, -10)
	add_child(sprite)

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(10, 8)
	shape.shape = rect
	shape.position = Vector2(0, -4)
	add_child(shape)

func _physics_process(delta: float) -> void:
	if input_locked:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input.length() > 0.0:
		facing = input.normalized()
		var target_speed := speed * (0.82 if carrying_ari else 1.0)
		velocity = velocity.move_toward(input.normalized() * target_speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, deceleration * delta)
	move_and_slide()
