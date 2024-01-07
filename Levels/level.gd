extends Object

class_name Level

var starting_gold: int
var tile_map: PackedScene
var rounds: Array[Round]

func _init(level_starting_gold: int, level_tile_map: PackedScene, level_rounds: Array[Round] = []):
	starting_gold = level_starting_gold
	tile_map = level_tile_map
	rounds = level_rounds
