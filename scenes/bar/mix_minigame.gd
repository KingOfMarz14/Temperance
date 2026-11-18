extends CanvasLayer

# hold click and shake (up/down) or stir (left/right) until the bar fills

signal done

const SHAKER_ICON = "res://sprites/Menu_Icon_Sprites/REUPLOADED_SHAKER_OPEN.png"
const MIXER_ICON = "res://sprites/Menu_Icon_Sprites/REUPLOADED_MIXER.png"
const NEEDED = 3000.0      # how much mouse movement it takes
const SWING = 120.0        # how far the tool moves from the middle

var stirring := false      # false = shaker, true = mixer
var progress := 0.0
var swing_pos := 0.0
var tool: TextureRect
var bar: ProgressBar


func _init(is_mixer: bool):
	stirring = is_mixer


func _ready():
	layer = 10

	# dark bg also blocks clicks on the bar behind it
	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var label = Label.new()
	label.text = "Hold click and stir side to side!" if stirring else "Hold click and shake up and down!"
	label.add_theme_font_size_override("font_size", 26)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.anchor_right = 1.0
	label.offset_top = 40
	label.offset_bottom = 80
	add_child(label)

	tool = TextureRect.new()
	tool.texture = load(MIXER_ICON if stirring else SHAKER_ICON)
	tool.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tool.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tool.size = Vector2(200, 200)
	tool.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tool)

	# progress bar on the right
	bar = ProgressBar.new()
	bar.fill_mode = ProgressBar.FILL_BOTTOM_TO_TOP
	bar.show_percentage = false
	bar.max_value = NEEDED
	bar.anchor_left = 1.0
	bar.anchor_right = 1.0
	bar.anchor_top = 0.5
	bar.anchor_bottom = 0.5
	bar.offset_left = -90
	bar.offset_right = -50
	bar.offset_top = -180
	bar.offset_bottom = 180
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bar)

	var x = Button.new()
	x.text = "X"
	x.anchor_left = 1.0
	x.anchor_right = 1.0
	x.offset_left = -50
	x.offset_right = -10
	x.offset_top = 10
	x.offset_bottom = 50
	x.pressed.connect(queue_free)   # cancel, drink stays the same
	add_child(x)

	_place_tool()


func _input(event):
	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		var move = event.relative.x if stirring else event.relative.y
		progress += abs(move)
		swing_pos = clamp(swing_pos + move, -SWING, SWING)
		bar.value = progress
		_place_tool()
		if progress >= NEEDED:
			done.emit()
			queue_free()


func _place_tool():
	var center = get_viewport().get_visible_rect().size / 2.0 - tool.size / 2.0
	if stirring:
		tool.position = center + Vector2(swing_pos, 0)
	else:
		tool.position = center + Vector2(0, swing_pos)
