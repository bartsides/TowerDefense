extends Object

class_name Damage

var physical_damage: float
var projectile_lifespan: float
var fire_damage: float
var fire_duration: float
var fire_tick: float
var secondary_projectile_count: int
var secondary_projectile_damage: float
var secondary_projectile_speed: float
var secondary_projectile_lifespan: float

func _init(p_physical_damage: float, p_projectile_lifespan: float = 1,
		p_fire_damage: float = 0, p_fire_duration: float = 0, p_fire_tick: float = 0, 
		p_secondary_projectile_count: int = 0,
		p_secondary_projectile_damage: float = 0,
		p_secondary_projectile_speed: float = 0,
		p_secondary_projectile_lifespan: float = 1):
	physical_damage = p_physical_damage
	projectile_lifespan = p_projectile_lifespan
	fire_damage = p_fire_damage
	fire_duration = p_fire_duration
	fire_tick = p_fire_tick
	secondary_projectile_count = p_secondary_projectile_count
	secondary_projectile_damage = p_secondary_projectile_damage
	secondary_projectile_speed = p_secondary_projectile_speed
	secondary_projectile_lifespan = p_secondary_projectile_lifespan

func get_secondary_projectile_damage() -> Damage:
	return Damage.new(secondary_projectile_damage, secondary_projectile_lifespan)
