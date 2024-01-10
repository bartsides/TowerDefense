extends Object

class_name Tier

var number: int
var weight: float
var loots: Array[Loot]

func _init(p_number: int, p_weight: float):
	number = p_number
	weight = p_weight
	_setup()

func get_loot() -> Loot:
	var totalWeight = 0
	for loot in loots:
		totalWeight += loot.weight
	
	var p = Rng.rng.randf_range(0, totalWeight)
	var total = 0.0
	for i in range(0, len(loots)):
		var loot = loots[i]
		total += loot.weight
		if p < total:
			loots.remove_at(i)
			return loot
	# Should never reach this
	print("Couldn't determine loot")
	return null

func _setup():
	match number:
		1:
			loots = [
				Loot.new(10, "cannon"),
				Loot.new(8, "flame_thrower"),
			]
		2:
			loots = [
				Loot.new(10, "ballista"),
				Loot.new(8, "blob_launcher"),
			]
		3:
			loots = [
				Loot.new(10, "hive"),
			]
