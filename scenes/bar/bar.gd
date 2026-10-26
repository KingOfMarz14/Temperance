extends Node2D

# size of one screen
const SCREEN_WIDTH = 1152

# look-down behavior
const COUNTER_Y_UP = 500.0
const COUNTER_Y_DOWN = 150.0
const CUSTOMER_SCALE_DOWN = 0.85
const CUSTOMER_ALPHA_DOWN = 0.4
const BACKDROP_DIM_DOWN = 0.7
const LOOK_TIME = 0.3
const MOVE_TIME = 0.25

var screen_index := 0     # 0 = The Library, 1 = The Toolkit
var looking_down := false
var current 
var barmatdrink1
var barmatdrink2
var barmat: Array[Drink] = [barmatdrink1, barmatdrink2]

@onready var camera: Camera2D = $Camera2D
@onready var screens = [$LibraryScreen, $ToolkitScreen]
@onready var backdrop: Node2D = $Backdrop


var shrink_layers: Array[Node2D] = []
var base_positions: Array[Vector2] = []


func _ready():
	camera.anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
	camera.position = Vector2.ZERO
	shrink_layers = [backdrop, $LibraryScreen/CustomerLayer, $ToolkitScreen/CustomerLayer]
	for layer in shrink_layers:
		base_positions.append(layer.position)
	_apply_look(false)
	$LibraryScreen/CounterLayer/Counter/spirit_menu/spirits_list.hide()
	$"LibraryScreen/CounterLayer/Counter/mix-in_menu/mix-in_list".hide()
	$LibraryScreen/CounterLayer/Counter/garnish_menu/garnish_list.hide()
	$ToolkitScreen/CounterLayer/Counter/glasses_menu/glasses_list.hide()
	$LibraryScreen/CounterLayer/Counter/bar_mat/bar_mat_drink1.hide()
	$LibraryScreen/CounterLayer/Counter/bar_mat/bar_mat_drink2.hide()

func _unhandled_input(event):
	if event.is_action_pressed("move_left") and screen_index > 0:
		screen_index -= 1
		_move_camera()
	elif event.is_action_pressed("move_right") and screen_index < screens.size() - 1:
		screen_index += 1
		_move_camera()
	elif event.is_action_pressed("look_down") and not looking_down:
		looking_down = true
		_apply_look(true)
	elif event.is_action_pressed("look_up") and looking_down:
		looking_down = false
		_apply_look(true)


# sideways movement
func _move_camera():
	var tween = create_tween()
	tween.tween_property(camera, "position:x", screen_index * SCREEN_WIDTH, MOVE_TIME)
	# recenter shrink when looking down
	if looking_down:
		_apply_look(true, MOVE_TIME)


# background and characters shrink toward top center
func _apply_look(animate: bool, duration: float = LOOK_TIME):
	var s = CUSTOMER_SCALE_DOWN if looking_down else 1.0
	var alpha = CUSTOMER_ALPHA_DOWN if looking_down else 1.0
	var counter_y = COUNTER_Y_DOWN if looking_down else COUNTER_Y_UP
	var pivot = Vector2(screen_index * SCREEN_WIDTH + SCREEN_WIDTH / 2.0, 0)

	var tween: Tween = null
	if animate:
		tween = create_tween().set_parallel(true)  # everything at once

	for i in shrink_layers.size():
		var layer = shrink_layers[i]
		var parent_offset = (layer.get_parent() as Node2D).position
		var normal_global = parent_offset + base_positions[i]
		var new_position = pivot + (normal_global - pivot) * s - parent_offset
		var tint = Color(1, 1, 1, alpha)
		if layer == backdrop:
			var dim = BACKDROP_DIM_DOWN if looking_down else 1.0
			tint = Color(dim, dim, dim, 1)
		if animate:
			tween.tween_property(layer, "scale", Vector2.ONE * s, duration)
			tween.tween_property(layer, "position", new_position, duration)
			tween.tween_property(layer, "modulate", tint, duration)
		else:
			layer.scale = Vector2.ONE * s
			layer.position = new_position
			layer.modulate = tint

	for screen in screens:
		var counter = screen.get_node("CounterLayer")
		if animate:
			tween.tween_property(counter, "position:y", counter_y, duration)
		else:
			counter.position.y = counter_y

func _on_spirit_menu_pressed() -> void:
	$LibraryScreen/CounterLayer/Counter/spirit_menu/spirits_list.show()
	

func _on_mixin_menu_pressed() -> void:
	$"LibraryScreen/CounterLayer/Counter/mix-in_menu/mix-in_list".show()


func _on_garnish_menu_pressed() -> void:
	$LibraryScreen/CounterLayer/Counter/garnish_menu/garnish_list.show()

func _on_glasses_menu_pressed() -> void:
	$ToolkitScreen/CounterLayer/Counter/glasses_menu/glasses_list.show()

func _on_spirits_list_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	if no_glass():
		$LibraryScreen/CounterLayer/Counter/spirit_menu/spirits_list.hide()
		return
	
	if (current._spirit[0] == null):
		current._spirit[0] = $LibraryScreen/CounterLayer/Counter/spirit_menu/spirits_list.get_item_text(index)
	elif (current._spirit[1] == null):
		current._spirit[1] = $LibraryScreen/CounterLayer/Counter/spirit_menu/spirits_list.get_item_text(index)
	
	$LibraryScreen/CounterLayer/Counter/spirit_menu/spirits_list.hide()
	print(current.spirit[0])
	print(current.spirit[1])
	


func _on_mixin_list_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	if no_glass():
		$"LibraryScreen/CounterLayer/Counter/mix-in_menu/mix-in_list".hide()
		return

	if (current._mix[0] == null):
		current._mix[0] = $"LibraryScreen/CounterLayer/Counter/mix-in_menu/mix-in_list".get_item_text(index)
	elif (current._mix[1] == null):
		current._mix[1] = $"LibraryScreen/CounterLayer/Counter/mix-in_menu/mix-in_list".get_item_text(index)
	elif (current._mix[2] == null):
		current._mix[2] = $"LibraryScreen/CounterLayer/Counter/mix-in_menu/mix-in_list".get_item_text(index)
	
	$"LibraryScreen/CounterLayer/Counter/mix-in_menu/mix-in_list".hide()
	print(current.mix[0])
	print(current.mix[1])
	print(current.mix[2])



func _on_garnish_list_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	if no_glass():
		$LibraryScreen/CounterLayer/Counter/garnish_menu/garnish_list.hide()
		return
	
	if (current._garnish[0] == null):
		current._garnish[0] = $LibraryScreen/CounterLayer/Counter/garnish_menu/garnish_list.get_item_text(index)
	elif (current._garnish[1] == null):
		current._garnish[1] = $LibraryScreen/CounterLayer/Counter/garnish_menu/garnish_list.get_item_text(index)
	
	$LibraryScreen/CounterLayer/Counter/garnish_menu/garnish_list.hide()
	print(current.garnish[0])
	print(current.garnish[1])


func _on_glasses_list_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	current = Drink.new()
	current.glass = $ToolkitScreen/CounterLayer/Counter/glasses_menu/glasses_list.get_item_text(index)
	print(current.glass)
	$ToolkitScreen/CounterLayer/Counter/glasses_menu/glasses_list.hide()


func _on_ice_pressed() -> void:
	if no_glass():
		return

	current.ice = true
	print(current.ice)

func no_glass() -> bool:
	if (current == null):
		$CustomerManager._flash_message("Select a glass first!")
		return true
	return false


func _on_trash_pressed() -> void:
	if (current != null):
		current = null
		$CustomerManager._flash_message("Drink has been thrown away")
	elif (no_glass()):
		$CustomerManager._flash_message("Nothing to throw away")


func _on_bar_mat_pressed() -> void:
	if (current != null):
		if (barmat[0] == null):
			barmat[0] = current
			$CustomerManager._flash_message("Current drink set on bar mat")
			current = null
		elif (barmat[1] == null):
			barmat[1] = current
			current = null
			$CustomerManager._flash_message("Current drink set on bar mat")
		else:
			$CustomerManager._flash_message("Click on a drink to swap it with what's currently in your hand")
			$LibraryScreen/CounterLayer/Counter/bar_mat/bar_mat_drink1.show()
			$LibraryScreen/CounterLayer/Counter/bar_mat/bar_mat_drink2.show()
			
			
	elif (barmat[0] != null):
		$CustomerManager._flash_message("Select a drink from the bar mat")
		$LibraryScreen/CounterLayer/Counter/bar_mat/bar_mat_drink1.show()
	elif (barmat[1] != null):
		$CustomerManager._flash_message("Select a drink from the bar mat")
		$LibraryScreen/CounterLayer/Counter/bar_mat/bar_mat_drink2.show()
	else:
		$CustomerManager._flash_message("Nothing to set down")


func _on_bar_mat_drink_1_pressed() -> void:
	var temp = barmat[0]
	barmat[0] = current
	current = temp
	$LibraryScreen/CounterLayer/Counter/bar_mat/bar_mat_drink1.hide()
	$LibraryScreen/CounterLayer/Counter/bar_mat/bar_mat_drink2.hide()


func _on_bar_mat_drink_2_pressed() -> void:
	var temp = barmat[1]
	barmat[1] = current
	current = temp
	$LibraryScreen/CounterLayer/Counter/bar_mat/bar_mat_drink1.hide()
	$LibraryScreen/CounterLayer/Counter/bar_mat/bar_mat_drink2.hide()
