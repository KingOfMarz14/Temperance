extends Node2D
var drink = Drink.new();

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_spirit_1_pressed() -> void:
	drink.spirit = "placeholder"


func _on_garnish_1_pressed() -> void:
	drink.garnish = "placeholder"


func _on_mixin_1_pressed() -> void:
	drink.mix = "placeholder"


#
