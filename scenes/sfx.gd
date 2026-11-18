extends Node

# plays a click on every button + menu item in the game, no setup needed per button

const CLICK = preload("res://audio/sfx/click.wav")
var player: AudioStreamPlayer


func _ready():
	player = AudioStreamPlayer.new()
	player.stream = CLICK
	player.volume_db = -4
	player.max_polyphony = 4
	add_child(player)
	get_tree().node_added.connect(_on_node_added)


func _on_node_added(node):
	if node is BaseButton:
		node.pressed.connect(click)
	elif node is ItemList:
		node.item_clicked.connect(func(_i, _pos, _button): click())


func click():
	player.pitch_scale = randf_range(0.95, 1.05)   # so it doesnt sound robotic
	player.play()
