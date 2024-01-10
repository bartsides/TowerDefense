extends Object

class_name Loot

var weight: float
var scene_path: String

func _init(p_weight: float, p_scene_path: String):
	weight = p_weight
	scene_path = "res://Turrets/%s.tscn" % p_scene_path
