class_name Drink
extends Node

var _glass = null
var _spirit = [null, null]
var _mix = [null, null, null]
var _garnish = [null, null]
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

func set_spirit(x, y):
	_spirit[0] = x;
	_spirit[1] = y

var mix:
	get:
		return _mix;
	
func set_mix(x, y, z):
	_mix[0] = x;
	_mix[1] = y;
	_mix[2] = z;

var garnish:
	get:
		return _garnish;

func set_garnish(x, y):
	_garnish[0] = x;
	_garnish[1] = y;
	

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
