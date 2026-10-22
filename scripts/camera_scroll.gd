extends Node2D

## Feeds the active camera's pan to the backdrop shaders.
## Arrow keys / left-drag move the camera; both are demo scaffolding.

@export var pan_speed := 900.0

@onready var camera: Camera2D = $Camera2D

var _dragging := false


func _ready() -> void:
	_push_pan()


func _process(delta: float) -> void:
	var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if dir != Vector2.ZERO:
		camera.position += dir * pan_speed * delta
	_push_pan()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed
	elif event is InputEventMouseMotion and _dragging:
		camera.position -= event.relative


func _push_pan() -> void:
	RenderingServer.global_shader_parameter_set("camera_pan", camera.global_position)
