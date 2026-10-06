class_name Drink
extends Node

var _glass
var _spirit
var _mix
var _garnish

func _init() -> void:
	self.glass = null;
	self.spirit = null;
	self.mix = null;
	self.garnish = null;

var glass:
	get:
		return _glass;
	set(x):
		_glass = x;

var spirit:
	get:
		return _spirit;
	set(x):
		_spirit = x;

var mix:
	get:
		return _mix;
	set(x):
		_mix = x;

var garnish:
	get:
		return _garnish;
	set(x):
		_garnish = x;
