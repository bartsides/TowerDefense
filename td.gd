extends Node2D

class_name TD

const CELL_SIZE = 16
const REGION_SIZE = 64
const PATH_WIDTH = .7
const SHOW_PATHS = true

var path_color = Color.BLACK

var enemyScene = preload("res://enemy.tscn")
var enemies_count = 20
var enemies_alive = 0
var lives = 20

var spawn_timer = Timer.new()
var astar_grid = AStarGrid2D.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	astar_grid.region = Rect2i(REGION_SIZE/-2.0, REGION_SIZE/-2.0, REGION_SIZE, REGION_SIZE)
	astar_grid.cell_size = Vector2(CELL_SIZE, CELL_SIZE)
	astar_grid.jumping_enabled = true
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.update()
	
	spawn_timer.wait_time = 1.0
	spawn_timer.connect("timeout", add_enemy)
	add_child(spawn_timer)
	
	start_round()
	
func _process(_delta):
	if lives <= 0:
		game_over()

func start_round():
	update_nav()
	spawn_timer.start()
	add_enemy()

func add_enemy():
	enemies_count -= 1
	if enemies_count < 0:
		spawn_timer.stop()
		return
	
	enemies_alive += 1
	var e = enemyScene.instantiate()
	e.position = $Start.position
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
	print('nav updated')

func game_over():
	print('game over')

func _draw():
	if !SHOW_PATHS:
		return
	for enemy in $Enemies.get_children():
		var prev = Vector2.INF
		for point in enemy.path:
			draw_circle(point, PATH_WIDTH * 3, path_color)
			if prev != Vector2.INF:
				draw_line(prev, point, path_color, PATH_WIDTH, true)
			prev = point
