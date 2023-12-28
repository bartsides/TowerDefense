extends Node2D

class_name TD

const REGION_SIZE = 1024
const PATH_WIDTH = .7
const SHOW_PATHS = false

var cell_size = 16
var path_color = Color.BLACK
var mouse_mode = MOUSE_MODE.WALL
var enemies_spawned = 0
var enemies_alive = 0
var lives = 20
var astar_grid = AStarGrid2D.new()
var map : TileMap

enum MOUSE_MODE { WALL, TURRET, CANNON, FLAME_THROWER }
enum TILEMAP_LAYERS { MAZE }
enum TILEMAP_SOURCES { FLOOR, WALL }

var turret_scene = preload("res://Turrets/turret.tscn")
var cannon_scene = preload("res://Turrets/cannon.tscn")
var flame_thrower_scene = preload("res://Turrets/flame_thrower.tscn")

var enemy_scene = preload("res://Enemies/enemy.tscn")
var fish_scene = preload("res://Enemies/fish.tscn")

var current_level : Level = null
var current_round : Round = null
var level_index = -1
var round_index = -1
var round_enemy_index = -1
var round_enemy : Enemy
var levels : Array[Level] = [ \
	Level.new([ \
		Round.new(1.4, [fish_scene, enemy_scene, fish_scene, enemy_scene]), \
		Round.new(1.3, [fish_scene, fish_scene, fish_scene, fish_scene]), \
		Round.new(1.2, [enemy_scene, enemy_scene, enemy_scene, enemy_scene]), \
		Round.new(1.1, [enemy_scene, fish_scene, enemy_scene, fish_scene]), \
	]), \
	Level.new([ \
		Round.new(2, [fish_scene, fish_scene, enemy_scene, enemy_scene]), \
		Round.new(2.1, [fish_scene, fish_scene, enemy_scene, enemy_scene]), \
		Round.new(2.2, [fish_scene, fish_scene, enemy_scene, enemy_scene]), \
		Round.new(2.3, [fish_scene, fish_scene, enemy_scene, enemy_scene]), \
	]), \
]

func _ready():
	map = $TileMap
	cell_size = map.tile_set.tile_size.x * map.transform.get_scale().x
	astar_grid.region = Rect2i(REGION_SIZE/-2.0, REGION_SIZE/-2.0, REGION_SIZE, REGION_SIZE)
	astar_grid.cell_size = Vector2(cell_size, cell_size)
	astar_grid.jumping_enabled = true
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar_grid.update()
	add_debug_turrets()
	next_level()

func add_debug_turrets():
	var prev_mouse_mode = mouse_mode
	mouse_mode = MOUSE_MODE.TURRET
	for coords in [Vector2(0, -1), Vector2(0, 3)]:
		handle_click(coords)
	mouse_mode = MOUSE_MODE.CANNON
	for coords in [Vector2(-2, 1)]:
		handle_click(coords)
	mouse_mode = MOUSE_MODE.FLAME_THROWER
	for coords in [Vector2(-3, -1)]:
		handle_click(coords)
	mouse_mode = prev_mouse_mode
	
func _process(_delta):
	if lives <= 0:
		game_over()

func next_level():
	stop_timers()
	level_index += 1
	round_index = -1
	if level_index >= len(levels):
		print('you have won the game')
		return
	current_level = levels[level_index]
	next_round()

func next_round():
	stop_timers()
	round_index += 1
	if round_index >= len(current_level.rounds):
		next_level()
		return
	print('Starting Level %s Round %s' % [level_index + 1, round_index + 1])
	current_round = current_level.rounds[round_index]
	round_enemy_index = -1
	$Timers/SpawnTimer.wait_time = current_round.spawn_time
	update_nav()
	add_enemy()
	start_timers()

func add_enemy():
	round_enemy_index += 1
	if round_enemy_index >= len(current_round.enemies):
		$Timers/SpawnTimer.stop()
		return
	
	var enemy = current_round.enemies[round_enemy_index].instantiate()
	enemy.position = $Start.position
	enemy.number = enemies_spawned
	$Enemies.add_child(enemy)
	
	enemies_alive += 1
	enemies_spawned += 1
	$UIControl.update()

func enemy_killed(enemy : Enemy):
	$Enemies.remove_child(enemy)
	enemy.queue_free()
	enemies_alive -= 1
	if enemies_alive <= 0 && round_enemy_index >= len(current_round.enemies):
		next_round()
	
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
		handle_click(coords)
	
	if event.is_action_pressed("1"):
		mouse_mode = MOUSE_MODE.WALL
	elif event.is_action_pressed("2"):
		mouse_mode = MOUSE_MODE.TURRET
	elif event.is_action_pressed("3"):
		mouse_mode = MOUSE_MODE.CANNON
	elif event.is_action_pressed("4"):
		mouse_mode = MOUSE_MODE.FLAME_THROWER

func handle_click(coords : Vector2):
	print('click ', coords)
	if mouse_mode == MOUSE_MODE.WALL:
		var tile_source = map.get_cell_source_id(TILEMAP_LAYERS.MAZE, coords)
		var new_val = 1
		if tile_source == 1:
			new_val = 0
		if new_val == TILEMAP_SOURCES.WALL && !can_navigate_with_change(coords, TILEMAP_LAYERS.MAZE, TILEMAP_SOURCES.WALL):
			return
		map.set_cell(TILEMAP_LAYERS.MAZE, coords, new_val, Vector2i(0,0))
		update_nav()
	
	if mouse_mode == MOUSE_MODE.TURRET or mouse_mode == MOUSE_MODE.CANNON \
	or mouse_mode == MOUSE_MODE.FLAME_THROWER:
		if !can_navigate_with_change(coords, TILEMAP_LAYERS.MAZE, TILEMAP_SOURCES.WALL):
			return
		
		# set base tilemap layer as a wall
		map.set_cell(TILEMAP_LAYERS.MAZE, coords, TILEMAP_SOURCES.WALL, Vector2i.ZERO)
		var t : Turret = get_selected_turret_scene()
		if t != null:
			t.coords = coords
			t.position = map.map_to_local(coords)
			$Turrets.add_child(t)
		update_nav()

func get_selected_turret_scene() -> Turret:
	match mouse_mode:
		MOUSE_MODE.TURRET:
			return turret_scene.instantiate()
		MOUSE_MODE.CANNON:
			return cannon_scene.instantiate()
		MOUSE_MODE.FLAME_THROWER:
			return flame_thrower_scene.instantiate()
	push_error('Unable to determine selected turret scene from mouse mode $s.' % mouse_mode)
	return null

func can_navigate_with_change(coords : Vector2, layer, source) -> bool:
	var orig_source = map.get_cell_source_id(layer, coords)
	var cell_pos = Vector2i(int(coords.x), int(coords.y))
	astar_grid.set_point_solid(cell_pos, source == TILEMAP_SOURCES.WALL)
	
	var nav_start = map.local_to_map($Start.position)
	var nav_end = map.local_to_map($End.position)
	var path = astar_grid.get_point_path(nav_start, nav_end)
	if len(path) > 0 && Vector2i(path[0]) == nav_start:
		path.remove_at(0)
	var result = len(path) > 0
	
	astar_grid.set_point_solid(cell_pos, orig_source == TILEMAP_SOURCES.WALL)
	
	return result

func game_over():
	$Timers/SpawnTimer.stop()
	print('game over')

func _draw():
	if !SHOW_PATHS: return
	for enemy in $Enemies.get_children():
		var prev = enemy.position
		for point in enemy.path:
			draw_circle(point, PATH_WIDTH * 3, path_color)
			draw_line(prev, point, path_color, PATH_WIDTH, true)
			prev = point

func force_draw(): queue_redraw()

func stop_timers():
	$Timers/SpawnTimer.stop()
	$Timers/DrawPathsTimer.stop()

func start_timers():
	$Timers/SpawnTimer.start()
	$Timers/DrawPathsTimer.start()
