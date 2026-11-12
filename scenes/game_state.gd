extends Node

# tweakable
const SPIRIT_PRICE = 0.75
const MIXIN_PRICE = 0.25
const GARNISH_PRICE = 0.15
const CORRECT_ITEM_TIP = 0.03      # per correct part of the order
const SPEED_TIP = 0.08             # per patience increment left
const PATIENCE_INCREMENTS = 5
const FIRST_DAY_CUSTOMERS = 5
const EXTRA_CUSTOMERS_PER_DAY = 1
const MAX_CUSTOMERS = 100
const UNOWNED_CHANCE_PER_DAY = 0.02   # doc: X = days * 2%
# quota = what you'd make serving every order right with about 3 bars left,
# times this. lower = easier, 1.0 = basically perfect
const QUOTA_FRACTION = 0.76
const QUOTA_SPEED = 3.0

# limits
const MAX_SPIRITS = 1
const MAX_MIXINS = 2
const MAX_GARNISHES = 2

# -every item in the game
const ALL_GLASSES = ["Rocks Glass", "Cocktail Glass", "Coupe Glass", "Liqueur Glass"]
const ALL_SPIRITS = ["Gin", "Whiskey", "Rum", "Brandy", "Moonshine", "Scotch"]
const ALL_MIXINS = ["Lemon Juice", "Honey", "Grenadine", "Maraschino Liquer",
	"Pineapple Juice", "Sweet Vermouth", "Triple Sec", "Chartreuse Green",
	"Cola", "Ginger Ale", "Seltzer", "Simple Syrup"]
const ALL_GARNISHES = ["Lemon Twist", "Orange Twist", "Cherries", "Mint",
	"Lemon Slice", "Orange Slice"]

# shop prices (placeholder, CHANGE SOON)
const SHOP_SPIRIT_PRICE = 2.00
const SHOP_MIXIN_PRICE = 1.00
const SHOP_GARNISH_PRICE = 0.75

# starter items
const STARTER_SPIRITS = ["Gin", "Whiskey", "Rum"]
const STARTER_MIXINS = ["Lemon Juice", "Honey", "Grenadine"]
const STARTER_GARNISHES = ["Cherries", "Lemon Twist", "Mint"]

var day := 1
var money := 0.0   # profit only (whats left after quotas)
var owned_spirits: Array = []
var owned_mixins: Array = []
var owned_garnishes: Array = []


func _ready():
	reset()


# starts new run
func reset():
	day = 1
	money = 0.0
	owned_spirits = STARTER_SPIRITS.duplicate()
	owned_mixins = STARTER_MIXINS.duplicate()
	owned_garnishes = STARTER_GARNISHES.duplicate()


# shop

# stuff you dont own yet, as [name, category, price]
func shop_items() -> Array:
	var items = []
	for s in ALL_SPIRITS:
		if not owned_spirits.has(s): items.append([s, "spirit", SHOP_SPIRIT_PRICE])
	for m in ALL_MIXINS:
		if not owned_mixins.has(m): items.append([m, "mixin", SHOP_MIXIN_PRICE])
	for g in ALL_GARNISHES:
		if not owned_garnishes.has(g): items.append([g, "garnish", SHOP_GARNISH_PRICE])
	return items


func buy(item: String, category: String, price: float) -> bool:
	if money < price:
		return false
	money = snapped(money - price, 0.01)
	match category:
		"spirit": owned_spirits.append(item)
		"mixin": owned_mixins.append(item)
		"garnish": owned_garnishes.append(item)
	return true


func customers_for_day() -> int:
	return min(FIRST_DAY_CUSTOMERS + EXTRA_CUSTOMERS_PER_DAY * (day - 1), MAX_CUSTOMERS)


# makes the whole day's orders up front so the quota fits them
func make_day_orders() -> Array:
	var orders = []
	for i in customers_for_day():
		orders.append(make_order())
	return orders


func quota_for(orders: Array) -> float:
	var total = 0.0
	for order in orders:
		total += best_value(order)
	return snapped(total * QUOTA_FRACTION, 0.01)


# most you could make on this order with what you own rn
func best_value(order: Drink) -> float:
	var best = Drink.new()
	best.glass = order.glass
	best.ice = order.ice
	best.shaken = order.shaken
	best.stirred = order.stirred
	best.set_spirit(_if_owned(order.spirit[0], owned_spirits), _if_owned(order.spirit[1], owned_spirits))
	best.set_mix(_if_owned(order.mix[0], owned_mixins), _if_owned(order.mix[1], owned_mixins),
		_if_owned(order.mix[2], owned_mixins))
	best.set_garnish(_if_owned(order.garnish[0], owned_garnishes), _if_owned(order.garnish[1], owned_garnishes))
	var value = score(order, best, QUOTA_SPEED).total
	best.free()
	return value


func _if_owned(item, owned: Array):
	return item if owned.has(item) else null


# ORDERING

# makes a random order
func make_order() -> Drink:
	var order = Drink.new()
	order.glass = ALL_GLASSES.pick_random()
	order.ice = randf() < 0.5
	match randi() % 3:
		0: order.shaken = true
		1: order.stirred = true
		# 2: straight-up (neither)

	var spirits = _pick_some(owned_spirits, ALL_SPIRITS, 1, MAX_SPIRITS)
	# shaken always needs a spirit and a mix-in
	var min_mixins = 1 if order.shaken else 0
	var mixins = _pick_some(owned_mixins, ALL_MIXINS, min_mixins, MAX_MIXINS)
	var garnishes = _pick_some(owned_garnishes, ALL_GARNISHES, 0, MAX_GARNISHES)
	order.set_spirit(_slot(spirits, 0), _slot(spirits, 1))
	order.set_mix(_slot(mixins, 0), _slot(mixins, 1), _slot(mixins, 2))
	order.set_garnish(_slot(garnishes, 0), _slot(garnishes, 1))
	return order


# each pick has a diff chance by-day
func _pick_some(owned: Array, everything: Array, min_count: int, max_count: int) -> Array:
	var picked = []
	var count = randi_range(min_count, max_count)
	var unowned = everything.filter(func(item): return not owned.has(item))
	var chance = (day - 1) * UNOWNED_CHANCE_PER_DAY
	for i in count:
		var pool = owned
		if not unowned.is_empty() and randf() < chance:
			pool = unowned
		pool = pool.filter(func(item): return not picked.has(item))
		if pool.is_empty():
			break
		picked.append(pool.pick_random())
	return picked


func _slot(items: Array, index: int):
	return items[index] if index < items.size() else null


# order is lines of text for now
func describe(order: Drink) -> String:
	var lines = [order.glass]
	var ice_line = "On the rocks" if order.ice else "No ice"
	# nothing listed = not shaken or stirred
	if order.shaken:
		ice_line += ", shaken"
	elif order.stirred:
		ice_line += ", stirred"
	lines.append(ice_line)
	for list in [order.spirit, order.mix, order.garnish]:
		var names = list.filter(func(x): return x != null)
		if not names.is_empty():
			lines.append(", ".join(names))
	return "\n".join(lines)


# SCORING

# compares what player chooses, notes what it means (score, money, etc)
func score(order: Drink, made: Drink, increments_left: float) -> Dictionary:
	var correct = 0
	var mistakes = 0

	for same in [order.glass == made.glass, order.ice == made.ice,
			order.shaken == made.shaken and order.stirred == made.stirred]:
		if same: correct += 1
		else: mistakes += 1

	var pay = 0.0
	var lists = [[order.spirit, made.spirit, SPIRIT_PRICE],
		[order.mix, made.mix, MIXIN_PRICE],
		[order.garnish, made.garnish, GARNISH_PRICE]]
	for entry in lists:
		var wanted = entry[0].filter(func(x): return x != null)
		var given = entry[1].filter(func(x): return x != null)
		
		pay += min(wanted.size(), given.size()) * entry[2]
		var remaining = wanted.duplicate()
		for item in given:
			if remaining.has(item):
				remaining.erase(item)
				correct += 1
			else:
				mistakes += 1     # something they didn't ask for
		mistakes += remaining.size()  # something they asked for but didn't get

	var tip = correct * CORRECT_ITEM_TIP + increments_left * SPEED_TIP
	# how happy they are (0 to 1): accuracy matters most, speed adds on top
	# a wrong drink fast is still bad, a right drink slow is just ok
	var accuracy = float(correct) / max(correct + mistakes, 1)
	var speed = float(increments_left) / PATIENCE_INCREMENTS
	var satisfaction = accuracy * (0.5 + 0.5 * speed)
	return {"pay": pay, "tip": tip, "total": pay + tip,
		"correct": correct, "mistakes": mistakes, "satisfaction": satisfaction}
