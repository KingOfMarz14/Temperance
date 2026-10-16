extends Node2D

# Size of one screen. Match this to Project Settings > Display > Window.
const SCREEN_WIDTH = 1152

# How the "look down" effect behaves. Tweak these to taste.
const COUNTER_Y_UP = 500.0          # Looking up: only the counter's top edge peeks in
const COUNTER_Y_DOWN = 150.0        # Looking down: counter rises to fill the screen
const CUSTOMER_SCALE_DOWN = 0.85    # Customers shrink to 85% size
const CUSTOMER_ALPHA_DOWN = 0.4     # Customers fade to 40% visible
const LOOK_TIME = 0.3               # Seconds the effect takes

var screen_index := 0       # 0 = The Library, 1 = The Toolkit
var looking_down := false
var current 

@onready var camera: Camera2D = $Camera2D
@onready var screens = [$LibraryScreen, $ToolkitScreen]


func _ready():
	# Make the camera's position mark the top-left corner of what you see.
	camera.anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
	camera.position = Vector2.ZERO
	_apply_look(false)  # Set the starting look instantly, no animation
	$LibraryScreen/CounterLayer/Counter/spirit_menu/spirits_list.hide()
	$"LibraryScreen/CounterLayer/Counter/mix-in_menu/mix-in_list".hide()
	$LibraryScreen/CounterLayer/Counter/garnish_menu/garnish_list.hide()
	$ToolkitScreen/CounterLayer/Counter/glasses_menu/glasses_list.hide()


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


# Slide the camera sideways to the current screen.
func _move_camera():
	var tween = create_tween()
	tween.tween_property(camera, "position:x", screen_index * SCREEN_WIDTH, 0.25)


# Shrink/fade the customers and raise/lower the counter on BOTH screens,
# so the other screen already matches if the player presses A or D.
func _apply_look(animate: bool):
	var customer_scale = Vector2.ONE * (CUSTOMER_SCALE_DOWN if looking_down else 1.0)
	var customer_alpha = CUSTOMER_ALPHA_DOWN if looking_down else 1.0
	var counter_y = COUNTER_Y_DOWN if looking_down else COUNTER_Y_UP

	for screen in screens:
		var customers = screen.get_node("CustomerLayer")
		var counter = screen.get_node("CounterLayer")

		if animate:
			var tween = create_tween().set_parallel(true)  # all three at once
			tween.tween_property(customers, "scale", customer_scale, LOOK_TIME)
			tween.tween_property(customers, "modulate:a", customer_alpha, LOOK_TIME)
			tween.tween_property(counter, "position:y", counter_y, LOOK_TIME)
		else:
			customers.scale = customer_scale
			customers.modulate.a = customer_alpha
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
	current.spirit = $LibraryScreen/CounterLayer/Counter/spirit_menu/spirits_list.get_item_text(index)
	print(current.spirit)
	$LibraryScreen/CounterLayer/Counter/spirit_menu/spirits_list.hide()


func _on_mixin_list_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	current.mix = $"LibraryScreen/CounterLayer/Counter/mix-in_menu/mix-in_list".get_item_text(index)
	print(current.mix)
	$"LibraryScreen/CounterLayer/Counter/mix-in_menu/mix-in_list".hide()


func _on_garnish_list_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	current.garnish = $LibraryScreen/CounterLayer/Counter/garnish_menu/garnish_list.get_item_text(index)
	print(current.garnish)
	$LibraryScreen/CounterLayer/Counter/garnish_menu/garnish_list.hide()


func _on_glasses_list_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	current = Drink.new()
	current.glass = $ToolkitScreen/CounterLayer/Counter/glasses_menu/glasses_list.get_item_text(index)
	print(current.glass)
	$ToolkitScreen/CounterLayer/Counter/glasses_menu/glasses_list.hide()


func _on_ice_pressed() -> void:
	current.ice = true
	print(current.ice)
