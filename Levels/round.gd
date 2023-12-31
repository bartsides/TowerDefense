class_name Round

var wait_time: float
var spawn_time: float
var enemies: Array

func _init(round_wait_time, round_spawn_time, round_enemies):
	wait_time = round_wait_time
	spawn_time = round_spawn_time
	enemies = round_enemies
