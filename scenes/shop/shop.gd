extends Control

@onready var wallet_label: Label = $Panel/VBox/Top/Wallet
@onready var item_list: VBoxContainer = $Panel/VBox/Scroll/Items
@onready var message_label: Label = $Panel/VBox/Message
@onready var next_day_button: Button = $Panel/VBox/NextDay


func _ready() -> void:
	next_day_button.pressed.connect(_on_next_day_pressed)
	message_label.text = ""
	_refresh()


# rebuild the list every time something gets bought
func _refresh():
	wallet_label.text = "Wallet: $%.2f" % GameState.money
	for child in item_list.get_children():
		child.queue_free()

	var items = GameState.shop_items()
	if items.is_empty():
		var label = Label.new()
		label.text = "you own everything!"
		item_list.add_child(label)
		return

	var last_category = ""
	for item in items:
		var item_name = item[0]
		var category = item[1]
		var price = item[2]

		# header for each type
		if category != last_category:
			var header = Label.new()
			header.text = {"spirit": "Spirits", "mixin": "Mix-ins", "garnish": "Garnishes"}[category]
			header.add_theme_font_size_override("font_size", 22)
			item_list.add_child(header)
			last_category = category

		var row = HBoxContainer.new()
		var label = Label.new()
		label.text = item_name
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)

		var button = Button.new()
		button.text = "Buy  $%.2f" % price
		button.custom_minimum_size = Vector2(130, 0)
		button.disabled = GameState.money < price   # cant afford
		button.pressed.connect(_on_buy_pressed.bind(item_name, category, price))
		row.add_child(button)
		item_list.add_child(row)


func _on_buy_pressed(item_name: String, category: String, price: float):
	if GameState.buy(item_name, category, price):
		message_label.text = "bought " + item_name
	else:
		message_label.text = "not enough money"
	_refresh()


func _on_next_day_pressed():
	GameState.day += 1
	get_tree().change_scene_to_file("res://scenes/bar/bar.tscn")
