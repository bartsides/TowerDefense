extends Object

class_name Damage

var physical_damage: float = 0
var fire_damage: float = 0
var fire_duration: float = 0
var fire_tick: float = 0

func _init(p_physical_damage: float, p_fire_damage: float, p_fire_duration: float, p_fire_tick: float):
	physical_damage = p_physical_damage
	fire_damage = p_fire_damage
	fire_duration = p_fire_duration
	fire_tick = p_fire_tick
