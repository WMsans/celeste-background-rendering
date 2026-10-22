extends SceneTree

## Renders scenes/main.tscn at requested camera pans and saves viewport PNGs.
## godot --path . -s tests/capture.gd -- --out-dir DIR --pan X,Y [--pan X,Y ...]

const SETTLE_FRAMES := 4

var _shots: Array[Dictionary] = []
var _viewport: SubViewport
var _scene: Node
var _frame := 0
var _index := -1


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir := "/tmp"
	var pans: Array[Vector2] = []
	var i := 0
	while i < args.size():
		match args[i]:
			"--out-dir":
				out_dir = args[i + 1]
				i += 2
			"--pan":
				var parts := args[i + 1].split(",")
				pans.append(Vector2(float(parts[0]), float(parts[1])))
				i += 2
			_:
				i += 1
	if pans.is_empty():
		pans.append(Vector2.ZERO)
	for pan in pans:
		var name := "pan_%d_%d.png" % [int(pan.x), int(pan.y)]
		_shots.append({"pan": pan, "path": out_dir.path_join(name)})
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(1920, 1080)
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	# A fresh SubViewport filters linearly; match the project's nearest default.
	_viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	root.add_child(_viewport)
	_scene = load("res://scenes/main.tscn").instantiate()
	_viewport.add_child(_scene)


func _process(_delta: float) -> bool:
	if _index < 0:
		_index = 0
		_apply()
		return false
	_frame += 1
	if _frame < SETTLE_FRAMES:
		return false
	var img := _viewport.get_texture().get_image()
	print("capture ", img.get_size(), " pan=", _shots[_index].pan)
	img.save_png(_shots[_index].path)
	_index += 1
	if _index >= _shots.size():
		return true
	_frame = 0
	_apply()
	return false


func _apply() -> void:
	var pan: Vector2 = _shots[_index].pan
	(_scene.get_node("Camera2D") as PixelCamera).teleport(pan)
