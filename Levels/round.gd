class_name Round

var wait_time: float
var spawn_time: float
var enemies: Array

func _init(p_wait_time, p_spawn_time, p_enemies):
	wait_time = p_wait_time
	spawn_time = p_spawn_time
	enemies = p_enemies
