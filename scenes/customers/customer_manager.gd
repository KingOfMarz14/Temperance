extends Node
## runs a day at the bar: brings in customers, handles clicks on them,
## serves drinks, keeps the money HUD updated, and ends the day.
## lives as a child of the Bar scene and talks to it as little as possible:
## it only reads/clears the Bar's `current` drink and finds the spots.

const CUSTOMER_SCENE = preload("res://scenes/customers/customer.tscn")
const SCREEN_WIDTH = 1152
const NUM_SCREENS = 2

## characters that can show up (drag CustomerType files in here)
@export var customer_types: Array[CustomerType] = []
@export var first_customer_delay: float = 3
@export var spawn_delay_min: float = 25.0 ## SLOW RN, CHANGE SOON
@export var spawn_delay_max: float = 40.0 

var spots: Array[Marker2D] = []
var customers_spawned := 0
var customers_done := 0
var day_earnings := 0.0
var day_over := false

@onready var bar = get_parent()
@onready var hud_label: Label = $HUD/Info
@onready var message_label: Label = $HUD/Message
@onready var day_over_panel: Control = $HUD/DayOver
@onready var day_over_label: Label = $HUD/DayOver/Panel/VBox/Result
@onready var day_over_button: Button = $HUD/DayOver/Panel/VBox/Continue


func _ready():
	# find all customer spots
	for screen_name in ["LibraryScreen", "ToolkitScreen"]:
		for child in bar.get_node(screen_name + "/CustomerLayer").get_children():
			if child is Marker2D:
				spots.append(child)
	spots.sort_custom(func(a, b): return a.global_position.x < b.global_position.x)

	for screen_name in ["LibraryScreen", "ToolkitScreen"]:
		bar.get_node(screen_name + "/CounterLayer").z_index = 1

	day_over_panel.visible = false
	day_over_button.pressed.connect(_on_continue_pressed)
	message_label.text = ""
	_update_hud()
	_run_day()


# day

func _run_day():
	await get_tree().create_timer(first_customer_delay).timeout
	while customers_spawned < GameState.customers_for_day():
		var spot = _free_spot()
		if spot == null:
			await get_tree().create_timer(1.0).timeout   # bar is full so check agian soon
			continue
		_spawn_customer(spot)
		await get_tree().create_timer(randf_range(spawn_delay_min, spawn_delay_max)).timeout


func _free_spot() -> Marker2D:
	for spot in spots:
		if spot.get_child_count() == 0:
			return spot
	return null


func _spawn_customer(spot: Marker2D):
	if customer_types.is_empty():
		push_warning("No customer types set on the CustomerManager node!")
		return
	var customer = CUSTOMER_SCENE.instantiate()
	customer.setup(customer_types.pick_random())
	spot.add_child(customer)
	customer.clicked.connect(_on_customer_clicked)
	customer.finished.connect(_on_customer_finished)
	customers_spawned += 1
	_update_hud()
	
	customer.walk_in(Vector2(SCREEN_WIDTH * NUM_SCREENS + 250, spot.global_position.y))


func _on_customer_finished(_customer):
	customers_done += 1
	_update_hud()
	if customers_done >= GameState.customers_for_day():
		_end_day()


# customer clicking

func _on_customer_clicked(customer):
	if day_over:
		return
	match customer.state:
		customer.State.WAITING:
			customer.take_order()
		customer.State.ORDERED:
			if bar.current == null:
				_flash_message("Make a drink first! (Look down with S, start with a glass)")
			else:
				_serve(customer)


func _serve(customer):
	var drink: Drink = bar.current
	var result = GameState.score(customer.order, drink, customer.increments_left())
	bar.current = null       # the drink is handed over
	drink.free()
	GameState.money += result.total
	day_earnings += result.total
	customer.receive_drink(result)
	_update_hud()


# hud

func _update_hud():
	hud_label.text = "Day %d    Today: $%.2f / $%.2f    Customers: %d / %d    Total: $%.2f" % [
		GameState.day, day_earnings, GameState.quota_for_day(),
		customers_done, GameState.customers_for_day(), GameState.money]


func _flash_message(text: String):
	message_label.text = text
	message_label.modulate.a = 1.0
	var tween = message_label.create_tween()
	tween.tween_interval(1.5)
	tween.tween_property(message_label, "modulate:a", 0.0, 0.5)


func _end_day():
	day_over = true
	var quota = GameState.quota_for_day()
	if day_earnings >= quota:
		day_over_label.text = "Day %d complete!\nYou made $%.2f (quota $%.2f)" % [GameState.day, day_earnings, quota]
		day_over_button.text = "Next day"
	else:
		day_over_label.text = "Closed down...\nYou made $%.2f but needed $%.2f" % [day_earnings, quota]
		day_over_button.text = "Back to main menu"
	day_over_panel.visible = true


func _on_continue_pressed():
	if day_earnings >= GameState.quota_for_day():
		GameState.day += 1
		get_tree().reload_current_scene()
	else:
		GameState.reset()
		get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")


func _on_shop_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/shop/shop.tscn")
