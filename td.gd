extends Node2D

class_name TD

const REGION_SIZE = 1024

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
var placement_preview_alpha = 0.4196
var mouse_mode = TdEnums.MOUSE_MODE.WALL
var hover_location: Vector2i = Vector2i.MAX
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
	change_mouse_mode(TdEnums.MOUSE_MODE.WALL)
	start_game()

func start_game():
	setup_astar_grid()
	next_level()

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
	$UILayer/UIControl.show_start_level(true)

func start_level():
	$UILayer/UIControl.show_start_level(false)
	next_round()

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
		$Sounds/EnemyReachEnd.play()
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
		astar_grid.set_point_solid(cell_pos, [map.wall_source, map.border_source].has(source_id))
	for enemy in $GameLayer/Enemies.get_children():
		enemy.update_nav()
	force_draw()

func update_wall_texture_in_ui():
	var atlas_texture = AtlasTexture.new()
	atlas_texture.atlas = map.tile_set.get_source(map.wall_source).texture
	atlas_texture.region = Rect2(0, 0, 32, 32)
	$UILayer/UIControl.set_wall_texture(atlas_texture)

func get_mouse_map_cell_pos() -> Vector2i:
	if map == null: return Vector2i.ZERO
	return Vector2i(map.local_to_map(map.to_local(get_global_mouse_position())))

func handle_click():
	var coords = get_mouse_map_cell_pos()
	if turret_tile_map.get_cell_source_id(0, coords) == 0:
		# Turret at clicked location
		return
	var source_id = map.get_cell_source_id(TdEnums.TILEMAP_LAYERS.MAZE, coords)
	if [-1, map.border_source, map.start_end_source].has(source_id):
		return
	
	if mouse_mode == TdEnums.MOUSE_MODE.WALL:
		var is_wall = map.wall_source == source_id
		if !is_wall && !can_navigate_with_change(coords):
			# Prevent player from blocking path
			return
		var new_source_id = map.walkable_source if is_wall else map.wall_source
		map.set_cell(TdEnums.TILEMAP_LAYERS.MAZE, coords, new_source_id, Vector2i.ZERO)
		update_nav()
	if mouse_mode == TdEnums.MOUSE_MODE.TURRET \
	or mouse_mode == TdEnums.MOUSE_MODE.CANNON \
	or mouse_mode == TdEnums.MOUSE_MODE.FLAME_THROWER \
	or mouse_mode == TdEnums.MOUSE_MODE.BALLISTA:
		if !can_navigate_with_change(coords):
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

func can_navigate_with_change(coords: Vector2) -> bool:
	var cell_to_change = Vector2i(int(coords.x), int(coords.y))
	astar_grid.set_point_solid(cell_to_change, true)
	
	# Get cell coordinates for starting position and all enemies
	var cells: Array[Vector2i] = [map.START]
	for enemy in $GameLayer/Enemies.get_children():
		var cell = map.local_to_map(enemy.position)
		if !cells.has(cell):
			cells.append(cell)
	
	var result = true
	var nav_end = map.END
	for cell in cells:
		var path = astar_grid.get_point_path(cell, nav_end)
		if len(path) > 0 && Vector2i(path[0]) == cell:
			path.remove_at(0)
		if len(path) <= 0:
			result = false
	
	astar_grid.set_point_solid(cell_to_change, false)
	return result

func change_mouse_mode(mode: TdEnums.MOUSE_MODE):
	mouse_mode = mode
	$UILayer/UIControl.update_mouse_mode(mode)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		var preview_layer = TdEnums.TILEMAP_LAYERS.PLACEMENT_PREVIEW
		if hover_location != Vector2i.MAX:
			# Remove previous placement preview
			map.erase_cell(preview_layer, hover_location)
			pass
		hover_location = get_mouse_map_cell_pos()
		for turret: Turret in $GameLayer/Turrets.get_children():
			turret.SHOW_RANGE = turret.coords == hover_location
			turret.queue_redraw()
		if turret_tile_map.get_cell_source_id(0, hover_location) < 0:
			if map.get_cell_source_id(TdEnums.TILEMAP_LAYERS.MAZE, hover_location) == map.walkable_source:
				# Add placement preview
				map.set_cell(preview_layer, hover_location, map.wall_source, Vector2i.ZERO)
				var valid_placement = can_navigate_with_change(hover_location)
				var mod_color = Color(1, 1 if valid_placement else 0, 1 if valid_placement else 0, placement_preview_alpha)
				map.set_layer_modulate(preview_layer, mod_color)
			# TODO: Add turret preview

func game_over():
	$GameLayer/Timers/SpawnTimer.stop()
	game_active = false
	$Sounds/GameOver.play()
	update_ui()
	print('game over')

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

func force_draw(): 
	queue_redraw()
	if map != null:
		map.queue_redraw()

func update_ui(): $UILayer/UIControl.update()
