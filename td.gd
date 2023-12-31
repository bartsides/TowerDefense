extends Node2D

class_name TD

const REGION_SIZE = 1024
const PATH_WIDTH = .7
const SHOW_PATHS = false

enum MOUSE_MODE { WALL, TURRET, CANNON, FLAME_THROWER }
enum TILEMAP_LAYERS { MAZE }

var turret_scene = preload("res://Turrets/turret.tscn")
var cannon_scene = preload("res://Turrets/cannon.tscn")
var flame_thrower_scene = preload("res://Turrets/flame_thrower.tscn")
var enemy_scene = preload("res://Enemies/enemy.tscn")
var fish_scene = preload("res://Enemies/fish.tscn")
var jet_ski_scene = preload("res://Enemies/jet_ski.tscn")

var cell_size = 16
var path_color = Color.BLACK
var mouse_mode = MOUSE_MODE.WALL
var enemies_spawned = 0
var enemies_alive = 0
var lives = 20
var astar_grid = AStarGrid2D.new()
var map: TileMap
var current_level: Level = null
var current_round: Round = null
var level_index = -1
var round_index = -1
var round_enemy_index = -1
var round_enemy: Enemy
var tilemap_sources: Array[TileSetSource] = []
var levels: Array[Level] = [ \
	Level.new([ \
	Round.new(.1, [jet_ski_scene,jet_ski_scene,jet_ski_scene,jet_ski_scene,jet_ski_scene,jet_ski_scene,jet_ski_scene,jet_ski_scene,jet_ski_scene,jet_ski_scene,jet_ski_scene,jet_ski_scene,jet_ski_scene,jet_ski_scene,jet_ski_scene,jet_ski_scene,jet_ski_scene,jet_ski_scene,jet_ski_scene,jet_ski_scene,jet_ski_scene,jet_ski_scene,jet_ski_scene,jet_ski_scene,jet_ski_scene,jet_ski_scene,jet_ski_scene,jet_ski_scene,jet_ski_scene,jet_ski_scene,jet_ski_scene,jet_ski_scene,jet_ski_scene,jet_ski_scene,jet_ski_scene,jet_ski_scene,jet_ski_scene,jet_ski_scene,jet_ski_scene,jet_ski_scene,jet_ski_scene,jet_ski_scene,jet_ski_scene,jet_ski_scene,jet_ski_scene,jet_ski_scene,jet_ski_scene,jet_ski_scene,jet_ski_scene,jet_ski_scene,jet_ski_scene,jet_ski_scene,jet_ski_scene,jet_ski_scene,jet_ski_scene,jet_ski_scene,jet_ski_scene,jet_ski_scene,jet_ski_scene,]), \
		Round.new(.3, [enemy_scene, fish_scene, enemy_scene, fish_scene, jet_ski_scene, jet_ski_scene, jet_ski_scene]), \
		Round.new(.5, [jet_ski_scene, jet_ski_scene, jet_ski_scene, jet_ski_scene, jet_ski_scene, jet_ski_scene, jet_ski_scene]), \
		Round.new(1.4, [fish_scene, enemy_scene, fish_scene, enemy_scene, jet_ski_scene, jet_ski_scene, jet_ski_scene]), \
		Round.new(1.3, [fish_scene, fish_scene, fish_scene, fish_scene, jet_ski_scene, jet_ski_scene, jet_ski_scene]), \
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
	map = $GameLayer/TileMap
	cell_size = map.tile_set.tile_size.x * map.transform.get_scale().x
	setup_astar_grid()
	next_level()
	add_debug_turrets()

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
	update_tilemap_sources()
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
	$GameLayer/Timers/SpawnTimer.wait_time = current_round.spawn_time
	update_nav()
	add_enemy()
	start_timers()

func add_enemy():
	round_enemy_index += 1
	if round_enemy_index >= len(current_round.enemies):
		$GameLayer/Timers/SpawnTimer.stop()
		return
	
	var enemy = current_round.enemies[round_enemy_index].instantiate()
	enemy.position = $GameLayer/Start.position
	enemy.number = enemies_spawned
	$GameLayer/Enemies.add_child(enemy)
	
	enemies_alive += 1
	enemies_spawned += 1
	update_ui()

func enemy_killed(enemy: Enemy, reached_end: bool):
	$GameLayer/Enemies.remove_child(enemy)
	enemy.queue_free()
	enemies_alive -= 1
	if reached_end:
		lives -= 1
		if lives <= 0:
			game_over()
			return
	if enemies_alive <= 0 && round_enemy_index >= len(current_round.enemies):
		next_round()
	update_ui()

func update_tilemap_sources():
	tilemap_sources = []
	for i in range(0, map.tile_set.get_next_source_id()):
		var source: TileSetSource = map.tile_set.get_source(i)
		if source != null: 
			tilemap_sources.insert(i, source)

func is_tilemap_source_id_wall(source_id) -> bool: return is_tilemap_source_wall(tilemap_sources[source_id])
func is_tilemap_source_wall(source) -> bool: return source != null && source.resource_name.find("Wall") > -1

func get_wall_tilemap_source() -> int:
	for i in range(0, len(tilemap_sources)):
		var source = tilemap_sources[i]
		if source == null: continue
		if is_tilemap_source_wall(source):
			return i
	return -1

func get_walkable_tilemap_source() -> int:
	for i in range(0, len(tilemap_sources)):
		var source = tilemap_sources[i]
		if source == null: continue
		if !is_tilemap_source_wall(source):
			return i
	return -1

func update_nav():
	var cells = map.get_used_cells(TILEMAP_LAYERS.MAZE)
	for cell in cells:
		var cell_pos = Vector2i(cell.x, cell.y)
		var source_id = map.get_cell_source_id(TILEMAP_LAYERS.MAZE, cell_pos)
		astar_grid.set_point_solid(cell_pos, is_tilemap_source_id_wall(source_id))
	for enemy in $GameLayer/Enemies.get_children():
		enemy.update_nav()
	queue_redraw()

func _input(event):
	if event.is_action_pressed("mouse_click"):
		var coords = map.local_to_map(map.to_local(get_global_mouse_position()))
		handle_click(coords)
	elif event.is_action_pressed("1"):
		mouse_mode = MOUSE_MODE.WALL
	elif event.is_action_pressed("2"):
		mouse_mode = MOUSE_MODE.TURRET
	elif event.is_action_pressed("3"):
		mouse_mode = MOUSE_MODE.CANNON
	elif event.is_action_pressed("4"):
		mouse_mode = MOUSE_MODE.FLAME_THROWER

func handle_click(coords: Vector2):
	if mouse_mode == MOUSE_MODE.WALL:
		var is_wall = is_tilemap_source_id_wall(map.get_cell_source_id(TILEMAP_LAYERS.MAZE, coords))
		var new_source_id = get_walkable_tilemap_source() if is_wall else get_wall_tilemap_source()
		if !is_wall && !can_navigate_with_change(coords, true):
			return # Prevent player from blocking path
		map.set_cell(TILEMAP_LAYERS.MAZE, coords, new_source_id, Vector2i.ZERO)
		update_nav()
	
	if mouse_mode == MOUSE_MODE.TURRET \
	or mouse_mode == MOUSE_MODE.CANNON \
	or mouse_mode == MOUSE_MODE.FLAME_THROWER:
		if !can_navigate_with_change(coords, true):
			return
		
		# set base tilemap layer as a wall
		map.set_cell(TILEMAP_LAYERS.MAZE, coords, get_wall_tilemap_source(), Vector2i.ZERO)
		var t: Turret = get_selected_turret_scene()
		if t != null:
			t.coords = coords
			t.position = map.map_to_local(coords)
			$GameLayer/Turrets.add_child(t)
		update_nav()

func get_selected_turret_scene() -> Turret:
	var scene = null
	match mouse_mode:
		MOUSE_MODE.TURRET:
			scene = turret_scene
		MOUSE_MODE.CANNON:
			scene = cannon_scene
		MOUSE_MODE.FLAME_THROWER:
			scene =  flame_thrower_scene
	if scene != null:
		return scene.instantiate()
	push_error('Unable to determine selected turret scene from mouse mode $s.' % mouse_mode)
	return null

func can_navigate_with_change(coords: Vector2, is_wall: bool) -> bool:
	var cell_pos = Vector2i(int(coords.x), int(coords.y))
	astar_grid.set_point_solid(cell_pos, is_wall)
	
	var nav_start = map.local_to_map($GameLayer/Start.position)
	var nav_end = map.local_to_map($GameLayer/End.position)
	var path = astar_grid.get_point_path(nav_start, nav_end)
	if len(path) > 0 && Vector2i(path[0]) == nav_start:
		path.remove_at(0)
	var result = len(path) > 0
	
	astar_grid.set_point_solid(cell_pos, !is_wall)
	return result

func game_over():
	$GameLayer/Timers/SpawnTimer.stop()
	update_ui()
	print('game over')

func _draw():
	if !SHOW_PATHS: return
	for enemy in $GameLayer/Enemies.get_children():
		var prev = enemy.position
		for point in enemy.path:
			draw_circle(point, PATH_WIDTH * 3, path_color)
			draw_line(prev, point, path_color, PATH_WIDTH, true)
			prev = point

func force_draw(): queue_redraw()

func stop_timers():
	$GameLayer/Timers/SpawnTimer.stop()
	$GameLayer/Timers/DrawPathsTimer.stop()

func start_timers():
	$GameLayer/Timers/SpawnTimer.start()
	$GameLayer/Timers/DrawPathsTimer.start()

func setup_astar_grid():
	astar_grid.region = Rect2i(REGION_SIZE/-2.0, REGION_SIZE/-2.0, REGION_SIZE, REGION_SIZE)
	astar_grid.cell_size = Vector2(cell_size, cell_size)
	astar_grid.jumping_enabled = true
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar_grid.update()

func update_ui():
	$UILayer/UIControl.update()
