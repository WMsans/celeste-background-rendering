class_name FgLayer
extends Sprite2D

## Screen-filling layer that loops on both axes, ported from Celeste's Parallax
## styleground: texel = screen_px + floor(camera * scroll - drift).
## Celeste's summit fog is two of these with the same soft noise texture
## (one flipped, different scroll/speed) so the tiles never line up, plus an
## additive colour wash. Blend comes from the node's material, alpha from modulate.

@export var scroll_scale := Vector2(0.9, 0.9)
## Drift in art pixels per second.
@export var speed := Vector2(16.0, 8.0)

var _drift := Vector2.ZERO


func _ready() -> void:
	centered = false
	region_enabled = true
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED


func _process(delta: float) -> void:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return
	_drift += speed * delta
	var view := get_viewport_rect().size / camera.zoom
	var top_left := (camera.get_screen_center_position() - view * 0.5).floor()
	global_position = top_left
	# Whole art pixels only, like Celeste's Calc.Floor, so the fog never shimmers.
	region_rect = Rect2((top_left * scroll_scale - _drift).floor(), view.ceil() + Vector2.ONE)
