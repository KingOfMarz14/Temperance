class_name CustomerType
extends Resource

@export var display_name: String = ""

@export var neutral_sprite: Texture2D
@export var happy_sprite: Texture2D
@export var mad_sprite: Texture2D

## swapped back and forth while they give their order
@export var talk_frames: Array[Texture2D] = []

## seconds they wait for their drink after ordering
## this is set high for testing; CHANGE SOON
@export var patience: float = 200.0

## walking speed in pixels per second
@export var walk_speed: float = 350.0

## sprite size on screen (the art is drawn very large)
@export var sprite_scale: float = 0.25
