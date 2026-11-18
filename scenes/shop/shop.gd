extends Control

@onready var wallet_label: Label = $Panel/VBox/Top/Wallet
@onready var item_list: VBoxContainer = $Panel/VBox/Scroll/Items
@onready var message_label: Label = $Panel/VBox/Message
@onready var next_day_button: Button = $Panel/VBox/NextDay
@onready var bigfoot: TextureRect = $Bigfoot

const BIGFOOT_NEUTRAL = preload("res://sprites/Character_Sprites/bigfootNeutral0.png")
const BIGFOOT_HAPPY = preload("res://sprites/Character_Sprites/bigfootHappy0.png")
const BIGFOOT_MAD = preload("res://sprites/Character_Sprites/bigfootMad0.png")
var mood_count := 0


func _ready() -> void:
	# shop music
	var music = AudioStreamPlayer.new()
	var song = load("res://audio/music/sphinx_w_strings.mp3")
	song.loop = true
	music.stream = song
	add_child(music)
	music.play()

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
		if GameState.money < price:
			button.modulate = Color(1, 1, 1, 0.5)   # cant afford, still clickable so bigfoot can get mad
		button.pressed.connect(_on_buy_pressed.bind(item_name, category, price))
		row.add_child(button)
		item_list.add_child(row)


func _on_buy_pressed(item_name: String, category: String, price: float):
	if GameState.buy(item_name, category, price):
		message_label.text = "bought " + item_name
		_bigfoot_mood(BIGFOOT_HAPPY)
	else:
		message_label.text = "not enough money"
		_bigfoot_mood(BIGFOOT_MAD)
	_refresh()


# show a face for a sec then go back to normal
func _bigfoot_mood(face: Texture2D):
	mood_count += 1
	var mine = mood_count
	bigfoot.texture = face
	await get_tree().create_timer(1.5).timeout
	if mine == mood_count:   # only reset if nothing else happened since
		bigfoot.texture = BIGFOOT_NEUTRAL


func _on_next_day_pressed():
	GameState.day += 1
	get_tree().change_scene_to_file("res://scenes/bar/bar.tscn")
