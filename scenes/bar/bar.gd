class_name bar
extends Node2D


# size of one screen
const SCREEN_WIDTH = 1152

# look-down behavior
const COUNTER_Y_UP = 500.0
const COUNTER_Y_DOWN = 150.0
const LOOK_SHIFT = 235.0           # how far everything slides up when you look down
const CUSTOMER_SCALE_DOWN = 0.95   # tiny shrink so it feels like depth
const CUSTOMER_DIM_DOWN = 0.85     # customers go a bit out of focus, still visible
const BACKDROP_DIM_DOWN = 0.7
const CustomerScript = preload("res://scenes/customers/customer.gd")
var LOOK_TIME: float = 0.3
var MOVE_TIME: float = 0.25

var screen_index := 0     # 0 = The Library, 1 = The Toolkit
var looking_down := false
var current
var barmatdrink1
var barmatdrink2
var barmat: Array[Drink] = [barmatdrink1, barmatdrink2]
var purifydrink1
var purifydrink2
var purifydrink3
var purifier: Array[Drink] = [purifydrink1, purifydrink2, purifydrink3]
static var multiplier: float = 1.0
var waiting_p1 = false
var finished_p1 = false
var waiting_p2 = false
var finished_p2 = false
var waiting_p3 = false
var finished_p3 = false

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
	$ToolkitScreen/CounterLayer/Counter/consumables/consumables_list.hide()
	$LibraryScreen/CounterLayer/Counter/exit_menu.hide()
	$ToolkitScreen/CounterLayer/Counter/purifier1.hide()
	$ToolkitScreen/CounterLayer/Counter/purifier2.hide()
	$ToolkitScreen/CounterLayer/Counter/purifier3.hide()

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


# looking down = like tilting your head
# everything slides up, the counter comes up in front
# customers peek over the counter (heads and shoulders)
func _apply_look(animate: bool, duration: float = LOOK_TIME):
	var s = CUSTOMER_SCALE_DOWN if looking_down else 1.0
	var shift = Vector2(0, -LOOK_SHIFT) if looking_down else Vector2.ZERO
	var counter_y = COUNTER_Y_DOWN if looking_down else COUNTER_Y_UP
	var pivot = Vector2(screen_index * SCREEN_WIDTH + SCREEN_WIDTH / 2.0, 0)

	var tween: Tween = null
	if animate:
		tween = create_tween().set_parallel(true)  # everything at once

	for i in shrink_layers.size():
		var layer = shrink_layers[i]
		var parent_offset = (layer.get_parent() as Node2D).position
		var normal_global = parent_offset + base_positions[i]
		var new_position = pivot + (normal_global - pivot) * s - parent_offset + shift
		var dim = CUSTOMER_DIM_DOWN if looking_down else 1.0
		if layer == backdrop:
			dim = BACKDROP_DIM_DOWN if looking_down else 1.0
		var tint = Color(dim, dim, dim, 1)
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
	$LibraryScreen/CounterLayer/Counter/exit_menu.show()
	$"LibraryScreen/CounterLayer/Counter/mix-in_menu".hide()
	$LibraryScreen/CounterLayer/Counter/garnish_menu.hide()
	

func _on_mixin_menu_pressed() -> void:
	$"LibraryScreen/CounterLayer/Counter/mix-in_menu/mix-in_list".show()
	$LibraryScreen/CounterLayer/Counter/exit_menu.show()
	$LibraryScreen/CounterLayer/Counter/spirit_menu.hide()
	$LibraryScreen/CounterLayer/Counter/garnish_menu.hide()


func _on_garnish_menu_pressed() -> void:
	$LibraryScreen/CounterLayer/Counter/garnish_menu/garnish_list.show()
	$LibraryScreen/CounterLayer/Counter/exit_menu.show()
	$LibraryScreen/CounterLayer/Counter/spirit_menu.hide()
	$"LibraryScreen/CounterLayer/Counter/mix-in_menu".hide()

func _on_glasses_menu_pressed() -> void:
	$ToolkitScreen/CounterLayer/Counter/glasses_menu/glasses_list.show()

func _on_spirits_list_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	if no_glass():
		$LibraryScreen/CounterLayer/Counter/spirit_menu/spirits_list.hide()
		$"LibraryScreen/CounterLayer/Counter/mix-in_menu".show()
		$LibraryScreen/CounterLayer/Counter/garnish_menu.show()
		$LibraryScreen/CounterLayer/Counter/exit_menu.hide()
		return

	if (current._spirit[0] == null):
		current._spirit[0] = $LibraryScreen/CounterLayer/Counter/spirit_menu/spirits_list.get_item_text(index)
	elif (current._spirit[1] == null):
		current._spirit[1] = $LibraryScreen/CounterLayer/Counter/spirit_menu/spirits_list.get_item_text(index)
	
	$LibraryScreen/CounterLayer/Counter/spirit_menu/spirits_list.hide()
	$"LibraryScreen/CounterLayer/Counter/mix-in_menu".show()
	$LibraryScreen/CounterLayer/Counter/garnish_menu.show()
	$LibraryScreen/CounterLayer/Counter/exit_menu.hide()
	


func _on_mixin_list_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	if no_glass():
		$"LibraryScreen/CounterLayer/Counter/mix-in_menu/mix-in_list".hide()
		$LibraryScreen/CounterLayer/Counter/spirit_menu.show()
		$LibraryScreen/CounterLayer/Counter/garnish_menu.show()
		$LibraryScreen/CounterLayer/Counter/exit_menu.hide()
		return

	var basic_quality = [0, 1, 2, 9, 10, 11, 12]
	var herbal_quality = [7, 8]
	var exotic_quality = [4, 6, 13]
	var unusual_quality = [14, 15, 16, 17]
	if (current._mix[0] == null):
		current._mix[0] = $"LibraryScreen/CounterLayer/Counter/mix-in_menu/mix-in_list".get_item_text(index)
	elif (current._mix[1] == null):
		current._mix[1] = $"LibraryScreen/CounterLayer/Counter/mix-in_menu/mix-in_list".get_item_text(index)
	elif (current._mix[2] == null):
		current._mix[2] = $"LibraryScreen/CounterLayer/Counter/mix-in_menu/mix-in_list".get_item_text(index)
	
	if (current._quality[0] == null):
		if (basic_quality.has(index)) :
			current._quality[0] = "basic"
	else :
		current._quality[1] = "basic"
		
	if (current._quality[0] == null):
		if (herbal_quality.has(index)) :
			current._quality[0] = "herbal"
	else :
		current._quality[1] = "herbal"
		
	if (current._quality[0] == null):
		if (exotic_quality.has(index)) :
			current._quality[0] = "exotic"
	else :
		current._quality[1] = "exotic"
	
	if (current._quality[0] == null):
		if (unusual_quality.has(index)) :
			current._quality[0] = "unusual"
	else :
		current._quality[1] = "unusual"
		
	$"LibraryScreen/CounterLayer/Counter/mix-in_menu/mix-in_list".hide()
	$LibraryScreen/CounterLayer/Counter/spirit_menu.show()
	$LibraryScreen/CounterLayer/Counter/garnish_menu.show()
	$LibraryScreen/CounterLayer/Counter/exit_menu.hide()


func _on_garnish_list_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	if no_glass():
		$LibraryScreen/CounterLayer/Counter/garnish_menu/garnish_list.hide()
		$LibraryScreen/CounterLayer/Counter/spirit_menu.show()
		$"LibraryScreen/CounterLayer/Counter/mix-in_menu".show()
		$LibraryScreen/CounterLayer/Counter/exit_menu.hide()
		return
	
	if (current._garnish[0] == null):
		current._garnish[0] = $LibraryScreen/CounterLayer/Counter/garnish_menu/garnish_list.get_item_text(index)
	elif (current._garnish[1] == null):
		current._garnish[1] = $LibraryScreen/CounterLayer/Counter/garnish_menu/garnish_list.get_item_text(index)
	
	$LibraryScreen/CounterLayer/Counter/garnish_menu/garnish_list.hide()
	$LibraryScreen/CounterLayer/Counter/spirit_menu.show()
	$"LibraryScreen/CounterLayer/Counter/mix-in_menu".show()
	$LibraryScreen/CounterLayer/Counter/exit_menu.hide()


func _on_glasses_list_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	current = Drink.new()
	current.glass = $ToolkitScreen/CounterLayer/Counter/glasses_menu/glasses_list.get_item_text(index)
	$ToolkitScreen/CounterLayer/Counter/glasses_menu/glasses_list.hide()


func _on_ice_pressed() -> void:
	if no_glass():
		return

	current.ice = true

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


func _on_consumables_list_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	if index == 0 :
		MOVE_TIME = 0
		LOOK_TIME = 0
		$ToolkitScreen/CounterLayer/Counter/consumables/consumables_list.hide()
		await get_tree().create_timer(10).timeout
		MOVE_TIME = 0.25
		LOOK_TIME = 0.3
	if index == 1 :
		multiplier = 2.0
		$ToolkitScreen/CounterLayer/Counter/consumables/consumables_list.hide()
	if index == 2 :
		multiplier = 1.1
		if current == null:
			current = Drink.new()
		current.item += "Talis. Of The Exotics"
		$ToolkitScreen/CounterLayer/Counter/consumables/consumables_list.hide()
		await get_tree().create_timer(15).timeout
		multiplier = 1
	if index == 3 :
		multiplier = 1.1
		if current == null:
			current = Drink.new()
		current.item += "Talis. Of The Unnatural"
		$ToolkitScreen/CounterLayer/Counter/consumables/consumables_list.hide()
		await get_tree().create_timer(15).timeout
		multiplier = 1
	if index == 4 :
		multiplier = 1.1
		if current == null:
			current = Drink.new()
		current.item += "Talis. of The Basic"
		$ToolkitScreen/CounterLayer/Counter/consumables/consumables_list.hide()
		await get_tree().create_timer(15).timeout
		multiplier = 1
	if index == 5 :
		multiplier = 1.1
		if current == null:
			current = Drink.new()
		current.item += "Talis. of Herbal"
		$ToolkitScreen/CounterLayer/Counter/consumables/consumables_list.hide()
		await get_tree().create_timer(15).timeout
		multiplier = 1
	#if index == 6 :
		#
		#$CustomerManager.spawn_delay_min = 999
		#$CustomerManager.spawn_delay_max = 1000
		#await get_tree().create_timer(10).timeout
		#$CustomerManager.spawn_delay_min = 25
		#$CustomerManager.spawn_delay_max = 40


func _on_consumables_pressed() -> void:
	$ToolkitScreen/CounterLayer/Counter/consumables/consumables_list.show()


#func _on_purifier_1_pressed() -> void:
	#if waiting_p1:
		#$CustomerManager._flash_message("Purifier currently being used")
		#return
	#if finished_p1:
		#if current == null:
			#current = purifier[0]
			#purifier[0] = null
			#finished_p1 = false
			#$CustomerManager._flash_message("Purified drink has been picked up")
			#return
		#else:
			#$CustomerManager._flash_message("Hands full, put drink down first")
			#return
		#
	#if current == null or current.mix[0] == null or current.spirit[0] == null:
		#$CustomerManager._flash_message("Nothing to purify")
		#return
	#
	#var temp = current
	#purifier[0] = temp
	#current = null
	#waiting_p1 = true
	#$CustomerManager._flash_message("Current drink being purified, please wait")
	#await get_tree().create_timer(15).timeout
	#
	#temp.purify = true
	#waiting_p1 = false
	#finished_p1 = true
	#$CustomerManager._flash_message("Drink has been purified")
#
#
#func _on_purifier_2_pressed() -> void:
	#if waiting_p2:
		#$CustomerManager._flash_message("Purifier currently being used")
		#return
	#if finished_p2:
		#if current == null:
			#current = purifier[0]
			#purifier[0] = null
			#finished_p2 = false
			#$CustomerManager._flash_message("Purified drink has been picked up")
			#return
		#else:
			#$CustomerManager._flash_message("Hands full, put drink down first")
			#return
		#
	#if current == null or current.mix[0] == null or current.spirit[0] == null:
		#$CustomerManager._flash_message("Nothing to purify")
		#return
	#
	#var temp = current
	#purifier[0] = temp
	#current = null
	#waiting_p2 = true
	#$CustomerManager._flash_message("Current drink being purified, please wait")
	#await get_tree().create_timer(15).timeout
	#
	#temp.purify = true
	#waiting_p2 = false
	#finished_p2 = true
	#$CustomerManager._flash_message("Drink has been purified")
#
#
#func _on_purifier_3_pressed() -> void:
	#if waiting_p3:
		#$CustomerManager._flash_message("Purifier currently being used")
		#return
	#if finished_p3:
		#if current == null:
			#current = purifier[0]
			#purifier[0] = null
			#finished_p3 = false
			#$CustomerManager._flash_message("Purified drink has been picked up")
			#return
		#else:
			#$CustomerManager._flash_message("Hands full, put drink down first")
			#return
		#
	#if current == null or current.mix[0] == null or current.spirit[0] == null:
		#$CustomerManager._flash_message("Nothing to purify")
		#return
	#
	#var temp = current
	#purifier[0] = temp
	#current = null
	#waiting_p3 = true
	#$CustomerManager._flash_message("Current drink being purified, please wait")
	#await get_tree().create_timer(15).timeout
	#
	#temp.purify = true
	#waiting_p3 = false
	#finished_p3 = true
	#$CustomerManager._flash_message("Drink has been purified")


func _on_shaker_pressed() -> void:
	if no_glass():
		return
	if current.mix[0] != null && current.spirit[0] != null:
		current._shaken = true
	else:
		$CustomerManager._flash_message("Nothing to shake right now")


func _on_exit_menu_pressed() -> void:
	$LibraryScreen/CounterLayer/Counter/spirit_menu/spirits_list.hide()
	$"LibraryScreen/CounterLayer/Counter/mix-in_menu/mix-in_list".hide()
	$LibraryScreen/CounterLayer/Counter/garnish_menu/garnish_list.hide()
	$LibraryScreen/CounterLayer/Counter/exit_menu.hide()
	$LibraryScreen/CounterLayer/Counter/spirit_menu.show()
	$"LibraryScreen/CounterLayer/Counter/mix-in_menu".show()
	$LibraryScreen/CounterLayer/Counter/garnish_menu.show()
