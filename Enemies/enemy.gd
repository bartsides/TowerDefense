extends CharacterBody2D

class_name Enemy

@export var SPEED = 20
@export var DISTANCE_MARGIN = 3
@export var END_DISTANCE_MARGIN = 16
@export var TOTAL_HEALTH = 10

var health: float = 10.0
var dead = false
var number: int
var half_cell_size
var map: TileMap
var td: TD
var path: PackedVector2Array
var health_bar: ProgressBar
var fire_damage: float = 0

func is_enemy(): pass

func _ready():
	show_fire(false)
	$CollisionShape2D/AnimatedSprite2D.play()
	td = get_node("/root/TD")
	map = td.map
	half_cell_size = td.cell_size / 2.0
	health = TOTAL_HEALTH
	health_bar = $HealthBar/ProgressBar
	health_bar.max_value = TOTAL_HEALTH
	health_bar.value = health
	$Timers/UpdateNavTimer.start()
	update_nav()

func _physics_process(delta):
	follow_path(delta)

func update_nav():
	$Timers/UpdateNavTimer.stop()
	if is_at_end():
		return
	var astar_grid = td.astar_grid as AStarGrid2D
	var nav_start = map.local_to_map(position)
	var nav_end = map.local_to_map(td.map.end_position)
	path = astar_grid.get_point_path(nav_start, nav_end)
	if len(path) > 1 and Vector2i(map.local_to_map(path[0])) == nav_start:
		# Move towards center of edge closest to next point
		var dir = path[0].direction_to(path[1])
		# Round to handle when both directions have a value not zero ie (0.707107, 0.707107)
		dir.x = roundf(dir.x)
		dir.y = roundf(dir.y)
		path[0] += dir * half_cell_size
	for i in range(0, len(path)):
		# Convert to global coords and move to center of cell
		path[i] = map.to_global(path[i]) + Vector2(half_cell_size, half_cell_size)
	$Timers/UpdateNavTimer.start()

func follow_path(delta):
	if len(path) <= 0:
		is_at_end()
		return
	var point = path[0]
	if position.distance_to(point) <= DISTANCE_MARGIN:
		path.remove_at(0)
		if path.size() <= 0:
			is_at_end()
			return
		point = path[0]
	$CollisionShape2D.look_at(point)
	var dir = position.direction_to(point)
	var vel = dir * SPEED * delta
	move_and_collide(vel)

func is_at_end() -> bool:
	if position.distance_to(td.map.end_position) <= END_DISTANCE_MARGIN:
		call_deferred('kill', true)
		return true
	return false

func kill(reached_end: bool = false):
	if dead: return
	dead = true
	td.enemy_killed(self, reached_end)

func take_damage(damage: Damage):
	health = clamp(health - damage.physical_damage, 0, TOTAL_HEALTH)
	if damage.fire_damage > 0 and damage.fire_tick > 0 and damage.fire_duration > 0:
		fire_damage = damage.fire_damage
		$Timers/FireTimer.wait_time = maxf($Timers/FireTimer.wait_time, damage.fire_duration)
		$Timers/FireTickTimer.wait_time = damage.fire_tick
		show_fire(true)
		$Timers/FireTimer.start()
		$Timers/FireTickTimer.start()
	check_health()

func take_fire_damage():
	health = clamp(health - fire_damage, 0, TOTAL_HEALTH)
	check_health()

func fire_complete():
	show_fire(false)
	$Timers/FireTickTimer.stop()

func show_fire(val: bool):
	for particle in $FireParticles.get_children():
		particle.emitting = val

func check_health():
	if health == 0:
		call_deferred('kill')
	else:
		update_health_bar()

func update_health_bar():
	health_bar.value = health
