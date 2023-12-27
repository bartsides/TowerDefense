extends Node2D

class_name TD

const REGION_SIZE = 1024
const PATH_WIDTH = .7
const SHOW_PATHS = true

var cell_size = 16
var path_color = Color.BLACK
var mouse_mode = MOUSE_MODE.WALL
var enemies_count = 200
var enemies_spawned = 0
var enemies_alive = 0
var lives = 20
var astar_grid = AStarGrid2D.new()
var map : TileMap

enum MOUSE_MODE { WALL, TURRET }
enum TILEMAP_LAYERS { MAZE }
enum TILEMAP_SOURCES { FLOOR, WALL }

var enemyScene = preload("res://enemy.tscn")
var turretScene = preload("res://turret.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	map = $TileMap
	cell_size = map.tile_set.tile_size.x * map.transform.get_scale().x
	
	astar_grid.region = Rect2i(REGION_SIZE/-2.0, REGION_SIZE/-2.0, REGION_SIZE, REGION_SIZE)
	astar_grid.cell_size = Vector2(cell_size, cell_size)
	astar_grid.jumping_enabled = true
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar_grid.update()
	
	start_round()
	
func _process(_delta):
	if lives <= 0:
		game_over()

func start_round():
	update_nav()
	$Timers/SpawnTimer.start()
	$Timers/DrawPathsTimer.start()
	add_enemy()

func add_enemy():
	enemies_count -= 1
	if enemies_count < 0:
		$Timers/SpawnTimer.stop()
		return
	
	enemies_alive += 1
	var e = enemyScene.instantiate()
	e.position = $Start.position
	e.number = enemies_spawned
	enemies_spawned += 1
	$Enemies.add_child(e)
	$UIControl.update()
	
func enemy_killed(enemy : Enemy):
	$Enemies.remove_child(enemy)
	enemy.queue_free()
	enemies_alive -= 1
	$UIControl.update()

func update_nav():
	var cells = map.get_used_cells(TILEMAP_LAYERS.MAZE)
	for cell in cells:
		var cell_pos = Vector2i(cell.x, cell.y)
		var source = map.get_cell_source_id(TILEMAP_LAYERS.MAZE, cell_pos)
		astar_grid.set_point_solid(cell_pos, source == 1)
		
	for enemy in $Enemies.get_children():
		enemy.update_nav()
	
	queue_redraw()

func _input(event):
	if event.is_action_pressed("mouse_click"):
		var coords = map.local_to_map(map.to_local(get_global_mouse_position()))
		
		if mouse_mode == MOUSE_MODE.WALL:
			var tile_source = map.get_cell_source_id(TILEMAP_LAYERS.MAZE, coords)
			var new_val = 1
			if tile_source == 1:
				new_val = 0
			map.set_cell(TILEMAP_LAYERS.MAZE, coords, new_val, Vector2i(0,0))
			update_nav()
		
		if mouse_mode == MOUSE_MODE.TURRET:
			# set base tilemap layer as a wall
			map.set_cell(TILEMAP_LAYERS.MAZE, coords, TILEMAP_SOURCES.WALL, Vector2i.ZERO)
			var t = turretScene.instantiate()
			t.coords = coords
			t.position = map.map_to_local(coords)
			$Turrets.add_child(t)
			update_nav()
			# TODO: ensure turret doesn't already exist
	
	if event.is_action_pressed("1"):
		mouse_mode = MOUSE_MODE.WALL
	
	if event.is_action_pressed("2"):
		mouse_mode = MOUSE_MODE.TURRET

func game_over():
	$Timers/SpawnTimer.stop()
	print('game over')

func _draw():
	if !SHOW_PATHS:
		return
	for enemy in $Enemies.get_children():
		var prev = enemy.position
		for point in enemy.path:
			draw_circle(point, PATH_WIDTH * 3, path_color)
			draw_line(prev, point, path_color, PATH_WIDTH, true)
			prev = point

func force_draw():
	queue_redraw()
