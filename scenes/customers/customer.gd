extends Node2D
## one customer at the bar: walks in, waits to be noticed, gives an order when
## clicked, loses patience, gets served (or gives up), reacts, pays, leaves.

signal clicked(customer)        # clicking customer
signal finished(customer)       # customer done; new can arrive (spot free)

enum State { WALKING_IN, WAITING, TALKING, ORDERED, LEAVING }

const TALK_TIME = 2.0            # talking anim
const TALK_FRAME_TIME = 0.25     # b/w frames of talking
const EXIT_X = -400.0            # how far out left
const BUBBLE_GAP = 20.0          # b/w head and bubble

@export var show_order_only_on_hover := false

var type: CustomerType
var order: Drink
var state = State.WALKING_IN
var hovered := false

@onready var sprite: Sprite2D = $Sprite2D
@onready var bubble: PanelContainer = $Bubble
@onready var bubble_label: Label = $Bubble/Label
@onready var click_area: Area2D = $ClickArea
@onready var click_shape: CollisionShape2D = $ClickArea/CollisionShape2D
@onready var patience_timer: Timer = $PatienceTimer
@onready var patience_bar: VBoxContainer = $PatienceBar


func setup(customer_type: CustomerType):
	type = customer_type


func _ready():
	sprite.texture = type.neutral_sprite
	sprite.scale = Vector2.ONE * type.sprite_scale
	var size = sprite.texture.get_size() * type.sprite_scale

	# click box for character
	var shape = RectangleShape2D.new()
	shape.size = size * 0.8
	click_shape.shape = shape
	click_area.input_event.connect(_on_click_area_input_event)
	click_area.mouse_entered.connect(func(): hovered = true; _update_bubble())
	click_area.mouse_exited.connect(func(): hovered = false; _update_bubble())

	# bubble
	bubble.position.y = -size.y / 2.0 - BUBBLE_GAP
	var style = StyleBoxFlat.new()
	style.bg_color = Color(1, 0.98, 0.92)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(8)
	bubble.add_theme_stylebox_override("panel", style)
	bubble_label.add_theme_color_override("font_color", Color(0.15, 0.1, 0.1))
	bubble.visible = false

	# patience
	patience_bar.position = Vector2(-size.x * 0.42, -60)
	for i in GameState.PATIENCE_INCREMENTS:
		var segment = ColorRect.new()
		segment.custom_minimum_size = Vector2(14, 20)
		patience_bar.add_child(segment)
	patience_bar.visible = false

	patience_timer.one_shot = true
	patience_timer.timeout.connect(_on_patience_ran_out)


func _process(_delta):
	if state == State.ORDERED:
		_update_patience_bar()


# arriving

# from off screen -> leftmost
func walk_in(start_global_position: Vector2):
	global_position = start_global_position
	var tween = create_tween()
	tween.tween_property(self, "position", Vector2.ZERO, position.length() / type.walk_speed)
	await tween.finished
	if state != State.WALKING_IN:
		return
	state = State.WAITING
	_set_bubble_text("...")


func _on_click_area_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(self)


# taking orders

# clicking waiting customer
func take_order():
	if state != State.WAITING:
		return
	state = State.TALKING
	bubble.visible = false

	var elapsed = 0.0
	var frame = 0
	while elapsed < TALK_TIME:
		if type.talk_frames.size() > 0:
			sprite.texture = type.talk_frames[frame % type.talk_frames.size()]
		frame += 1
		await get_tree().create_timer(TALK_FRAME_TIME).timeout
		elapsed += TALK_FRAME_TIME

	sprite.texture = type.neutral_sprite
	order = GameState.make_order()
	state = State.ORDERED
	_set_bubble_text(GameState.describe(order))
	patience_timer.start(type.patience)
	patience_bar.visible = true


func increments_left() -> int:
	var per_increment = type.patience / GameState.PATIENCE_INCREMENTS
	return int(ceil(patience_timer.time_left / per_increment))


func _update_patience_bar():
	var left = increments_left()
	var color = Color(0.3, 0.8, 0.3)          # green
	if left <= 2:
		color = Color(0.9, 0.25, 0.2)         # red
	elif left == 3:
		color = Color(0.95, 0.8, 0.2)         # yellow
	# draining from top down
	var segments = patience_bar.get_children()
	for i in segments.size():
		var lit = i >= segments.size() - left
		segments[i].color = color if lit else Color(0.15, 0.15, 0.15, 0.6)


# being served

func receive_drink(result: Dictionary):
	patience_timer.stop()
	var happy = result.mistakes <= 1
	sprite.texture = type.happy_sprite if happy else type.mad_sprite
	_show_floating_text("+$%.2f" % snapped(bar.multiplier * result.total, 0.01), Color(0.4, 1, 0.4) if happy else Color(1, 0.85, 0.3))
	leave()


func _on_patience_ran_out():
	sprite.texture = type.mad_sprite
	_show_floating_text("Left!", Color(1, 0.4, 0.4))
	leave()


func leave():
	if state == State.LEAVING:
		return
	state = State.LEAVING
	bubble.visible = false
	patience_bar.visible = false
	patience_timer.stop()

	await get_tree().create_timer(1.2).timeout # this gives it a moment to see reaction if theyre happy or sad
	var target = get_parent().to_local(Vector2(EXIT_X, global_position.y))
	var tween = create_tween()
	tween.tween_property(self, "position", target, position.distance_to(target) / type.walk_speed)
	await tween.finished

	if order:
		order.free()
	finished.emit(self)
	queue_free()


# bubble and effects

func _set_bubble_text(text: String):
	bubble_label.text = text
	_update_bubble()
	# keeping it centered
	await get_tree().process_frame
	bubble.size = Vector2.ZERO
	bubble.position.x = -bubble.size.x / 2.0
	bubble.position.y = -sprite.texture.get_size().y * type.sprite_scale / 2.0 - BUBBLE_GAP - bubble.size.y


func _update_bubble():
	match state:
		State.WAITING:
			bubble.visible = true
		State.ORDERED:
			bubble.visible = hovered or not show_order_only_on_hover
		_:
			bubble.visible = false


func _show_floating_text(text: String, color: Color):
	var label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	label.add_theme_font_size_override("font_size", 28)
	label.position = Vector2(-40, -sprite.texture.get_size().y * type.sprite_scale / 2.0)
	add_child(label)
	var tween = label.create_tween().set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 60, 1.2)
	tween.tween_property(label, "modulate:a", 0.0, 1.2).set_delay(0.6)
