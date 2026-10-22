class_name PixelCamera
extends Camera2D

## Pixel-perfect camera: zooms by a whole number so the 320x180 art fills the
## window, and snaps to whole art pixels so texels never shimmer.
## Arrow keys / left-drag pan freely; set `target` to follow a node instead.

@export var art_size := Vector2i(320, 180)
@export var target: Node2D
@export var follow_speed := 8.0
## Pan speed in art pixels per second.
@export var pan_speed := 150.0
@export var pan_acceleration := 900.0
## Clamp for the camera centre in world units; a zero-size rect means unbounded.
@export var bounds := Rect2()

## Unsnapped centre; `position` is this rounded to the art grid.
var exact := Vector2.ZERO

var _velocity := Vector2.ZERO
var _dragging := false


func _ready() -> void:
	process_priority = -10
	exact = position
	get_viewport().size_changed.connect(_fit_zoom)
	_fit_zoom()
	_apply()


func _process(delta: float) -> void:
	if target:
		exact = exact.lerp(target.global_position, 1.0 - exp(-follow_speed * delta))
	else:
		var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		_velocity = _velocity.move_toward(dir * pan_speed, pan_acceleration * delta)
		exact += _velocity * delta
	_apply()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed
	elif event is InputEventMouseMotion and _dragging and not target:
		exact -= event.relative / zoom
		_velocity = Vector2.ZERO


## Jumps straight to `pos` with no easing.
func teleport(pos: Vector2) -> void:
	exact = pos
	_velocity = Vector2.ZERO
	_apply()


func _apply() -> void:
	if bounds.has_area():
		exact = exact.clamp(bounds.position, bounds.end)
	position = exact.round()
	RenderingServer.global_shader_parameter_set("camera_pan", position)


func _fit_zoom() -> void:
	var view := get_viewport_rect().size
	var factor := floorf(minf(view.x / art_size.x, view.y / art_size.y))
	zoom = Vector2.ONE * maxf(factor, 1.0)
