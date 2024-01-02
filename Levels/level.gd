extends Object

class_name Level

var tile_map: PackedScene
var rounds: Array[Round]

func _init(level_tile_map: PackedScene, level_rounds: Array[Round] = []):
	tile_map = level_tile_map
	rounds = level_rounds
