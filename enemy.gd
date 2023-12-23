extends CharacterBody2D

class_name Enemy

const SPEED = 1
const UPDATE_NAV_TIME = 10

var half_cell_size
var map
var td
var path : PackedVector2Array
var update_nav_timer = Timer.new()

func _ready():
	td = get_node("/root/TD")
	map = td.get_node("TileMap") as TileMap
	half_cell_size = td.CELL_SIZE / 2
	update_nav_timer.wait_time = UPDATE_NAV_TIME
	update_nav_timer.connect("timeout", update_nav)
	add_child(update_nav_timer)
	#update_nav_timer.start()
	update_nav()

func _physics_process(_delta):
	follow_path()

func update_nav():
	var end = td.get_node("End") as Marker2D
	var astar_grid = td.astar_grid as AStarGrid2D
	
	var navStart = map.local_to_map(position)
	var navEnd = map.local_to_map(end.position)
	path = astar_grid.get_point_path(navStart, navEnd)
	for i in range(0, len(path)):
		#path[i] = path[i] + Vector2(half_cell_size, half_cell_size)
		path[i] = map.to_global(path[i]) + Vector2(half_cell_size, half_cell_size)

func follow_path():
	if path.size() <= 0:
		kill()
		return
	var point = path[0]
	if position.distance_to(point) <= .5:
		path.remove_at(0)
		if path.size() <= 0:
			return
		point = path[0]
	position = position.move_toward(point, SPEED)
	move_and_slide()

func kill():
	get_node("/root/TD").enemy_killed(self)
