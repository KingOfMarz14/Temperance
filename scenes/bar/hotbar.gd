extends CanvasLayer

const GLASS_ICONS = {
	"Rocks Glass": "res://sprites/Glass_Sprites/REUPLOADED_ROCKSGLASS_Wrk.png",
	"Cocktail Glass": "res://sprites/Glass_Sprites/REUPLOADED_COCKTAIL_Wrk.png",
	"Coupe Glass": "res://sprites/Glass_Sprites/REUPLOADED_COUPE_Wrk.png",
	"Liqueur Glass": "res://sprites/Glass_Sprites/REUPLOADED_LIQUERGLASS_Wrk.png",
	"Zombie Glass": "res://sprites/Glass_Sprites/REUPLOADED_ZOMBIEGLASS_Wrk.png",
}
const SHAKEN_ICON = "res://sprites/Menu_Icon_Sprites/REUPLOADED_SHAKER_OPEN.png"
const STIRRED_ICON = "res://sprites/Menu_Icon_Sprites/REUPLOADED_MIXER.png"
const GLASS_SIZE = 90.0
const ITEM_SIZE = 64.0
const LIBRARY = "LibraryScreen/CounterLayer/Counter/"

@onready var bar = get_parent()
var row: HBoxContainer
var last_look := ""
var purify_start = [0, 0, 0]
var purifier_art = []   # the purifier pics/text so they come back when empty


func _ready():
	var holder = Control.new()
	holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(holder)

	# squares along the very bottom
	row = HBoxContainer.new()
	row.anchor_left = 0.0
	row.anchor_right = 1.0
	row.anchor_top = 1.0
	row.anchor_bottom = 1.0
	row.offset_top = -GLASS_SIZE - 10
	row.offset_bottom = -10
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(row)
	row.hide()

	for i in 3:
		var button: Button = bar.get_node("ToolkitScreen/CounterLayer/Counter/purifier%d" % (i + 1))
		purifier_art.append([button.icon, button.text])


func _process(_delta):
	# only rebuild when the drink in hand changes
	var look = _look(bar.current)
	if look != last_look:
		last_look = look
		_rebuild(bar.current)
	_update_purifiers()


func _look(d) -> String:
	if d == null:
		return ""
	return str([d.get_instance_id(), d.glass, d.ice, d.spirit, d.mix, d.shaken, d.stirred, d.purify, d.garnish, d.item])


# hotbar

func _rebuild(d):
	for child in row.get_children():
		child.queue_free()
	if d == null:
		row.hide()   # trash / handed over / set down
		return
	row.show()

	# same order customers ask in: glass, rocks, spirit, mix-in, shaken/stirred, purify, garnish
	_add_square(_glass_icon(d.glass), d.glass if d.glass else "no glass", GLASS_SIZE)
	if d.ice:
		_add_square(null, "Ice", ITEM_SIZE)
	for s in d.spirit:
		if s != null:
			_add_square(_menu_icon("spirit_menu/spirits_list", GameState.ALL_SPIRITS, s), s, ITEM_SIZE)
	for m in d.mix:
		if m != null:
			_add_square(_menu_icon("mix-in_menu/mix-in_list", GameState.ALL_MIXINS, m), m, ITEM_SIZE)
	if d.shaken:
		_add_square(load(SHAKEN_ICON), "Shaken", ITEM_SIZE)
	elif d.stirred:
		_add_square(load(STIRRED_ICON), "Stirred", ITEM_SIZE)
	if d.purify:
		_add_square(null, "Purified", ITEM_SIZE)
	for g in d.garnish:
		if g != null:
			_add_square(_menu_icon("garnish_menu/garnish_list", GameState.ALL_GARNISHES, g), g, ITEM_SIZE)
	if d.item != "":
		_add_square(null, d.item, ITEM_SIZE)


func _add_square(tex, text: String, size: float):
	var square = PanelContainer.new()
	square.custom_minimum_size = Vector2(size, size)
	square.size_flags_vertical = Control.SIZE_SHRINK_END   # small ones line up at the bottom
	square.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.09, 0.08, 0.85)
	style.border_color = Color(0.85, 0.7, 0.45)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(4)
	square.add_theme_stylebox_override("panel", style)

	# picture if there is one, otherwise the word
	if tex:
		var pic = TextureRect.new()
		pic.texture = tex
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		square.add_child(pic)
	else:
		var label = Label.new()
		label.text = text
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 12)
		square.add_child(label)
	row.add_child(square)


func _glass_icon(glass):
	if glass and GLASS_ICONS.has(glass):
		return load(GLASS_ICONS[glass])
	return null


# grabs the icon straight from the menu so new art shows up automatically
func _menu_icon(list_path: String, all_names: Array, item_name: String):
	var list: ItemList = bar.get_node(LIBRARY + list_path)
	var full_index = all_names.find(item_name)
	for i in list.item_count:
		if list.get_item_metadata(i) == full_index:
			return list.get_item_icon(i)
	return null


# purifiers

func _update_purifiers():
	for i in 3:
		var button: Button = bar.get_node("ToolkitScreen/CounterLayer/Counter/purifier%d" % (i + 1))
		var d = bar.purifier[i]
		var waiting = bar.get("waiting_p%d" % (i + 1))
		var finished = bar.get("finished_p%d" % (i + 1))

		if d == null:
			button.icon = purifier_art[i][0]
			button.text = purifier_art[i][1]
			purify_start[i] = 0
			continue

		button.icon = _glass_icon(d.glass)
		button.expand_icon = true
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		if waiting:
			if purify_start[i] == 0:
				purify_start[i] = Time.get_ticks_msec()
			var left = bar.PURIFY_TIME - (Time.get_ticks_msec() - purify_start[i]) / 1000.0
			button.text = str(max(ceili(left), 1))
		elif finished:
			button.text = "READY"
