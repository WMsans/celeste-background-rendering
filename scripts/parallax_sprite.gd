class_name ParallaxSprite
extends Sprite2D

## Parallax backdrop layer that tiles horizontally and stays on the art grid.
## scroll_scale 0 pins the layer to the screen; 1 moves it with the world.

@export var scroll_scale := Vector2(0.25, 0.1)
## Copies drawn on each side; 2 covers views up to 5 texture widths.
@export var repeat_times := 2

var _origin := Vector2.ZERO


func _ready() -> void:
	_origin = position
	var width := _width()
	for i in range(-repeat_times, repeat_times + 1):
		if i == 0:
			continue
		var copy := Sprite2D.new()
		copy.texture = texture
		copy.centered = centered
		copy.use_parent_material = true
		copy.position = Vector2(i * width, 0.0)
		add_child(copy)


func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return
	var cam := camera.global_position
	var pos := _origin + cam * (Vector2.ONE - scroll_scale)
	var width := _width()
	pos.x += width * roundf((cam.x - pos.x) / width)
	position = pos.round()


func _width() -> float:
	return texture.get_width() * scale.x
