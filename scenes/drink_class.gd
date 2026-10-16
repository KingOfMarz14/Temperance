class_name Drink
extends Node

var _glass
var _spirit
var _mix
var _garnish
var _ice = false
var _shaken = false
var _stirred = false

func _init() -> void:
	self.glass = null;
	self.spirit = null;
	self.mix = null;
	self.garnish = null;
	self.ice = false;
	self.shaken = false;
	self.stirred = false;

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
		

var ice:
	get:
		return _ice;
	set(x):
		_ice = x;

var shaken:
	get:
		return _shaken;
	set(value):
		_shaken = value;
		
var stirred:
	get:
		return _stirred;
	set(value):
		_stirred = value;
