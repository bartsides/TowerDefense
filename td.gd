extends Node2D

class_name TD

const CELL_SIZE = 16
const REGION_SIZE = 1024
const PATH_WIDTH = .7
const SHOW_PATHS = true

var path_color = Color.BLACK
var enemyScene = preload("res://enemy.tscn")
var enemies_count = 200
var enemies_spawned = 0
var enemies_alive = 0
var lives = 20

var astar_grid = AStarGrid2D.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	astar_grid.region = Rect2i(REGION_SIZE/-2.0, REGION_SIZE/-2.0, REGION_SIZE, REGION_SIZE)
	astar_grid.cell_size = Vector2(CELL_SIZE, CELL_SIZE)
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
	
func enemy_killed(enemy : Enemy):
	$Enemies.remove_child(enemy)
	enemy.queue_free()
	enemies_alive -= 1

func update_nav():
	var map = $TileMap as TileMap
	#astar_grid.clear() TODO: Figure out how to clear without breaking
	
	var cells = map.get_used_cells(0)
	for cell in cells:
		var cell_pos = Vector2i(cell.x, cell.y)
		var source = map.get_cell_source_id(0, cell_pos)
		astar_grid.set_point_solid(cell_pos, source == 1)
		
	for enemy in $Enemies.get_children():
		enemy.update_nav()
	queue_redraw()

func _input(event):
	if event.is_action_pressed("mouse_click"):
		var map = $TileMap as TileMap
		var coords = map.local_to_map(map.to_local(get_global_mouse_position()))
		var tile_source = map.get_cell_source_id(0, coords)
		var new_val = 1
		if tile_source == 1:
			new_val = 0
		map.set_cell(0, coords, new_val, Vector2i(0,0))
		update_nav()

func game_over():
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
