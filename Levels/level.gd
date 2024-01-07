extends Object

class_name Level

var starting_gold: int
var tile_map: PackedScene
var rounds: Array[Round]

func _init(p_starting_gold: int, p_tile_map: PackedScene, p_rounds: Array[Round] = []):
	starting_gold = p_starting_gold
	tile_map = p_tile_map
	rounds = p_rounds
