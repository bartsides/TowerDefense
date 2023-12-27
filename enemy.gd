extends CharacterBody2D

class_name Enemy

@export var SPEED = 20
@export var DISTANCE_MARGIN = 2
@export var TOTAL_HEALTH = 10

var health_bar_thickness = 0.25
var health_bar_width = 8
var health_bar_y = -5

var health = 10.0
var dead = false
var number : int
var half_cell_size
var map : TileMap
var td : TD
var path : PackedVector2Array

func is_enemy(): pass

func _ready():
	$AnimatedSprite2D.play()
	$UpdateNavTimer.start()
	td = get_node("/root/TD")
	map = td.get_node("TileMap")
	half_cell_size = td.cell_size / 2.0
	update_nav()

func _physics_process(delta):
	follow_path(delta)

func _draw():
	if health == 0: return
	# draw health bar
	var health_percentage = health / TOTAL_HEALTH
	var start = Vector2(-health_bar_width / 2.0, health_bar_y)
	var end = Vector2(health_bar_width * health_percentage - (health_bar_width / 2.0), health_bar_y)
	draw_line(start, end, Color.RED, health_bar_thickness, true)

func update_nav():
	$UpdateNavTimer.stop()
	var end = td.get_node("End") as Marker2D
	var astar_grid = td.astar_grid as AStarGrid2D
	
	var nav_start = map.local_to_map(position)
	var nav_end = map.local_to_map(end.position)
	path = astar_grid.get_point_path(nav_start, nav_end)
	if len(path) > 0 && Vector2i(map.local_to_map(path[0])) == nav_start:
		path.remove_at(0)
	for i in range(0, len(path)):
		path[i] = map.to_global(path[i]) + Vector2(half_cell_size, half_cell_size)
	$UpdateNavTimer.start()

func follow_path(delta):
	if path.size() <= 0:
		call_deferred('kill') # TODO: Handle enemy reaching end better
		return
	var point = path[0]
	if position.distance_to(point) <= DISTANCE_MARGIN:
		path.remove_at(0)
		if path.size() <= 0:
			return
		point = path[0]
	look_at(point)
	var dir = position.direction_to(point)
	var vel = dir * SPEED * delta
	move_and_collide(vel)

func kill():
	if dead: return
	dead = true
	td.enemy_killed(self)
	# TODO: Consider emit_signal instead of getting TD node

func take_damage(damage):
	health = clamp(health - damage, 0, TOTAL_HEALTH)
	if health == 0:
		call_deferred('kill')
	else:
		queue_redraw()
