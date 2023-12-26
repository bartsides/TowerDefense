extends CharacterBody2D

class_name Enemy

@export var SPEED = 20
@export var DISTANCE_MARGIN = 3
@export var TOTAL_HEALTH = 10

var health = 10.0
var dead = false
var number : int
var half_cell_size
var map
var td
var path : PackedVector2Array

func is_enemy(): pass

func _ready():
	td = get_node("/root/TD")
	map = td.get_node("TileMap") as TileMap
	half_cell_size = td.cell_size / 2
	update_nav()

func _physics_process(delta):
	follow_path(delta)

func _draw():
	if health == 0: return
	# draw health bar
	var health_percentage = health / TOTAL_HEALTH
	draw_line(Vector2(-4, -5), Vector2(8 * health_percentage - 4, -5), Color.RED, .25, true)

func update_nav():
	var end = td.get_node("End") as Marker2D
	var astar_grid = td.astar_grid as AStarGrid2D
	
	var nav_start = map.local_to_map(position)
	var nav_end = map.local_to_map(end.position)
	path = astar_grid.get_point_path(nav_start, nav_end)
	if len(path) > 0 && Vector2i(path[0]) == nav_start:
		path.remove_at(0)
	for i in range(0, len(path)):
		path[i] = map.to_global(path[i]) + Vector2(half_cell_size, half_cell_size)

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
	position = position.move_toward(point, SPEED * delta)
	move_and_slide()

func kill():
	if dead:
		return
	dead = true
	get_node("/root/TD").enemy_killed(self)
	# TODO: Consider emit_signal instead of getting TD node

func take_damage(damage):
	health = clamp(health - damage, 0, TOTAL_HEALTH)
	if health == 0:
		call_deferred('kill')
	else:
		queue_redraw()
