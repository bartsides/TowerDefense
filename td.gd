extends Node2D

class_name TD

const REGION_SIZE = 1024
const PATH_WIDTH = .7
const SHOW_PATHS = false

var turret_scene = preload("res://Turrets/turret.tscn")
var cannon_scene = preload("res://Turrets/cannon.tscn")
var flame_thrower_scene = preload("res://Turrets/flame_thrower.tscn")
var ballista_scene = preload("res://Turrets/ballista.tscn")

var enemy_scene = preload("res://Enemies/enemy.tscn")
var alligator_scene = preload("res://Enemies/alligator.tscn")
var fish_scene = preload("res://Enemies/fish.tscn")
var jet_ski_scene = preload("res://Enemies/jet_ski.tscn")

@onready var turret_tile_map: TileMap = $GameLayer/TurretTileMap

var cell_size = 32
var path_color = Color.BLACK
var mouse_mode = TdEnums.MOUSE_MODE.WALL
var enemies_spawned = 0
var enemies_alive = 0
var total_enemies = 0
var game_active = true
var lives = 20
var astar_grid = AStarGrid2D.new()
var map: LevelTileMap = null
var current_level: Level = null
var current_round: Round = null
var level_index = -1
var round_index = -1
var round_enemy_index = -1
var round_enemy: Enemy

var levels: Array[Level] = [ \
	Level.new(load("res://Levels/level1.tscn"), \
		[ \
			Round.new(2, .1, [alligator_scene, alligator_scene, jet_ski_scene,jet_ski_scene,jet_ski_scene,jet_ski_scene,jet_ski_scene,jet_ski_scene,jet_ski_scene,]), \
			#Round.new(2, .3, [enemy_scene, fish_scene, enemy_scene, fish_scene, jet_ski_scene, jet_ski_scene, jet_ski_scene]), \
			#Round.new(2, .5, [jet_ski_scene, jet_ski_scene, jet_ski_scene, jet_ski_scene, jet_ski_scene, jet_ski_scene, jet_ski_scene]), \
			#Round.new(2, 1.4, [fish_scene, enemy_scene, fish_scene, enemy_scene, jet_ski_scene, jet_ski_scene, jet_ski_scene]), \
			#Round.new(2, 1.3, [fish_scene, fish_scene, fish_scene, fish_scene, jet_ski_scene, jet_ski_scene, jet_ski_scene]), \
			#Round.new(2, 1.2, [enemy_scene, enemy_scene, enemy_scene, enemy_scene]), \
			Round.new(2, 1.1, [enemy_scene, fish_scene, enemy_scene, fish_scene]), \
		] \
	), \
	Level.new(load("res://Levels/level2.tscn"), \
		[ \
			Round.new(2, 2, [fish_scene, fish_scene, enemy_scene, enemy_scene]), \
			Round.new(2, 2.1, [fish_scene, fish_scene, enemy_scene, enemy_scene]), \
			Round.new(2, 2.2, [fish_scene, fish_scene, enemy_scene, enemy_scene]), \
			Round.new(2, 2.3, [fish_scene, fish_scene, enemy_scene, enemy_scene]), \
		] \
	), \
]


func _ready():
	start_game()

func start_game():
	setup_astar_grid()
	next_level()
	#add_debug_turrets()

func add_debug_turrets():
	var prev_mouse_mode = mouse_mode
	mouse_mode = TdEnums.MOUSE_MODE.TURRET
	for coords in [Vector2(0, -1), Vector2(0, 3)]:
		handle_click(coords)
	mouse_mode = TdEnums.MOUSE_MODE.CANNON
	for coords in [Vector2(-2, 1)]:
		handle_click(coords)
	mouse_mode = TdEnums.MOUSE_MODE.FLAME_THROWER
	for coords in [Vector2(-3, -1)]:
		handle_click(coords)
	mouse_mode = prev_mouse_mode

func _process(_delta):
	if !game_active: return
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
	turret_tile_map.clear_layer(0)
	for t in $GameLayer/Turrets.get_children():
		$GameLayer/Turrets.remove_child(t)
		t.queue_free()
	if map != null:
		$GameLayer.remove_child(map)
		map.queue_free()
	map = current_level.tile_map.instantiate()
	$GameLayer.add_child(map)
	update_nav()
	update_wall_texture_in_ui()
	next_round()

func update_wall_texture_in_ui():
	var atlas_texture = AtlasTexture.new()
	atlas_texture.atlas = map.tile_set.get_source(map.wall_source).texture
	atlas_texture.region = Rect2(0, 0, 32, 32)
	$UILayer/UIControl.set_wall_texture(atlas_texture)

func next_round():
	stop_timers()
	round_index += 1
	if round_index >= len(current_level.rounds):
		next_level()
		return
	round_enemy_index = -1
	current_round = current_level.rounds[round_index]
	total_enemies = len(current_round.enemies)
	$GameLayer/Timers/StartRoundTimer.wait_time = current_round.wait_time
	$GameLayer/Timers/StartRoundTimer.start()
	print('waiting ', current_round.wait_time, 's')
	$GameLayer/Timers/SpawnTimer.wait_time = current_round.spawn_time
	update_nav()
	update_ui()

func start_round():
	print('Starting Level %s Round %s' % [level_index + 1, round_index + 1])
	add_enemy()
	start_timers()

func add_enemy():
	if !game_active: return
	round_enemy_index += 1
	if round_enemy_index >= total_enemies:
		$GameLayer/Timers/SpawnTimer.stop()
		return
	
	var enemy = current_round.enemies[round_enemy_index].instantiate()
	enemy.position = map.start_position
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
	if enemies_alive <= 0 && round_enemy_index >= total_enemies - 1:
		next_round()
	update_ui()

func update_nav():
	var cells = map.get_used_cells(TdEnums.TILEMAP_LAYERS.MAZE)
	for cell in cells:
		var cell_pos = Vector2i(cell.x, cell.y)
		var source_id = map.get_cell_source_id(TdEnums.TILEMAP_LAYERS.MAZE, cell_pos)
		astar_grid.set_point_solid(cell_pos, map.wall_source == source_id || map.border_source == source_id)
	for enemy in $GameLayer/Enemies.get_children():
		enemy.update_nav()
	queue_redraw()

func _input(event):
	if event.is_action_pressed("mouse_click"):
		var coords = map.local_to_map(map.to_local(get_global_mouse_position()))
		handle_click(coords)
	elif event.is_action_pressed("1"):
		mouse_mode = TdEnums.MOUSE_MODE.WALL
	elif event.is_action_pressed("2"):
		mouse_mode = TdEnums.MOUSE_MODE.TURRET
	elif event.is_action_pressed("3"):
		mouse_mode = TdEnums.MOUSE_MODE.CANNON
	elif event.is_action_pressed("4"):
		mouse_mode = TdEnums.MOUSE_MODE.FLAME_THROWER
	elif event.is_action_pressed("5"):
		mouse_mode = TdEnums.MOUSE_MODE.BALLISTA

func handle_click(coords: Vector2):
	if turret_tile_map.get_cell_source_id(0, coords) == 0:
		# Turret at clicked location
		return
	var source_id = map.get_cell_source_id(TdEnums.TILEMAP_LAYERS.MAZE, coords)
	if [-1, map.border_source, map.start_end_source].has(source_id):
		return
	
	if mouse_mode == TdEnums.MOUSE_MODE.WALL:
		var is_wall = map.wall_source == source_id
		if !is_wall && !can_navigate_with_change(coords, true):
			# Prevent player from blocking path
			return
		var new_source_id = map.walkable_source if is_wall else map.wall_source
		map.set_cell(TdEnums.TILEMAP_LAYERS.MAZE, coords, new_source_id, Vector2i.ZERO)
		update_nav()
	if mouse_mode == TdEnums.MOUSE_MODE.TURRET \
	or mouse_mode == TdEnums.MOUSE_MODE.CANNON \
	or mouse_mode == TdEnums.MOUSE_MODE.FLAME_THROWER \
	or mouse_mode == TdEnums.MOUSE_MODE.BALLISTA:
		if !can_navigate_with_change(coords, true):
			# Prevent player from blocking path
			return
		map.set_cell(TdEnums.TILEMAP_LAYERS.MAZE, coords, map.wall_source, Vector2i.ZERO)
		var t: Turret = get_selected_turret_scene()
		t.coords = coords
		t.position = map.map_to_local(coords)
		$GameLayer/Turrets.add_child(t)
		turret_tile_map.set_cell(0, coords, 0, Vector2i.ZERO)
		update_nav()

func get_selected_turret_scene() -> Turret:
	var scene = null
	match mouse_mode:
		TdEnums.MOUSE_MODE.TURRET:
			scene = turret_scene
		TdEnums.MOUSE_MODE.CANNON:
			scene = cannon_scene
		TdEnums.MOUSE_MODE.FLAME_THROWER:
			scene = flame_thrower_scene
		TdEnums.MOUSE_MODE.BALLISTA:
			scene = ballista_scene
	if scene != null:
		return scene.instantiate()
	push_error('Unable to determine selected turret scene from mouse mode $s.' % mouse_mode)
	return null

func can_navigate_with_change(coords: Vector2, is_wall: bool) -> bool:
	var cell_pos = Vector2i(int(coords.x), int(coords.y))
	astar_grid.set_point_solid(cell_pos, is_wall)
	
	var nav_start = map.local_to_map(map.start_position)
	var nav_end = map.local_to_map(map.end_position)
	var path = astar_grid.get_point_path(nav_start, nav_end)
	if len(path) > 0 && Vector2i(path[0]) == nav_start:
		path.remove_at(0)
	
	astar_grid.set_point_solid(cell_pos, !is_wall)
	return len(path) > 0

func change_mouse_mode(mode: TdEnums.MOUSE_MODE):
	mouse_mode = mode
	for turret_button  in $UILayer/UIControl/Panel/MarginContainer/VBoxContainer.get_children():
		if turret_button is TurretButton:
			turret_button.focused = turret_button.MOUSE_MODE == mode
			turret_button.update()

func game_over():
	$GameLayer/Timers/SpawnTimer.stop()
	game_active = false
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

func force_draw(): queue_redraw()
func update_ui(): $UILayer/UIControl.update()
