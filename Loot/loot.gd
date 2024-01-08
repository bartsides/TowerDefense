extends Node

class_name Loot

var tiers: Array[Tier] = [
	Tier.new(1, 10),
	Tier.new(2, 7),
	Tier.new(3, 5),
	Tier.new(4, 3),
	Tier.new(5, 2),
	Tier.new(6, 1),
	Tier.new(7, .5),
]

func get_tier() -> Tier:
	var totalWeight = 0
	for tier in tiers:
		totalWeight += tier.weight
	
	var p = Rng.rng.randf_range(0, totalWeight)
	var total = 0.0
	for tier in tiers:
		total += tier.weight
		if p < total:
			return tier
	# Should never reach this
	print("Couldn't determine loot tier")
	return null
