extends Node2D

class_name TD

const REGION_SIZE = 1024

var turret_scene = preload("res://Turrets/turret.tscn")
var cannon_scene = preload("res://Turrets/cannon.tscn")
var flame_thrower_scene = preload("res://Turrets/flame_thrower.tscn")
var ballista_scene = preload("res://Turrets/ballista.tscn")
var blob_launcher_scene = preload("res://Turrets/blob_launcher.tscn")

var enemy_scene = preload("res://Enemies/enemy.tscn")
var alligator_scene = preload("res://Enemies/alligator.tscn")
var fish_scene = preload("res://Enemies/fish.tscn")
var jet_ski_scene = preload("res://Enemies/jet_ski.tscn")

var cell_size = 32
var placement_preview_alpha = 0.4196
var mouse_mode = TdEnums.MOUSE_MODE.WALL
var hover_position: Vector2i = Vector2i.MAX
var turret_preview_sprite: AnimatedSprite2D = null
var enemies_spawned = 0
var enemies_alive = 0
var total_enemies = 0
var game_active = true
var lives = 20
var gold = 0
var astar_grid = AStarGrid2D.new()
var map: LevelTileMap = null
var current_level: Level = null
var current_round: Round = null
var level_index = -1
var round_index = -1
var round_enemy_index = -1
var round_enemy: Enemy

var levels: Array[Level] = [
	Level.new(200,
		load("res://Levels/level1.tscn"),
		[
			Round.new(2, .1, [alligator_scene, alligator_scene, jet_ski_scene,jet_ski_scene,jet_ski_scene,jet_ski_scene,jet_ski_scene,jet_ski_scene,jet_ski_scene,]),
			#Round.new(2, .3, [enemy_scene, fish_scene, enemy_scene, fish_scene, jet_ski_scene, jet_ski_scene, jet_ski_scene]),
			#Round.new(2, .5, [jet_ski_scene, jet_ski_scene, jet_ski_scene, jet_ski_scene, jet_ski_scene, jet_ski_scene, jet_ski_scene]),
			#Round.new(2, 1.4, [fish_scene, enemy_scene, fish_scene, enemy_scene, jet_ski_scene, jet_ski_scene, jet_ski_scene]),
			#Round.new(2, 1.3, [fish_scene, fish_scene, fish_scene, fish_scene, jet_ski_scene, jet_ski_scene, jet_ski_scene]),
			#Round.new(2, 1.2, [enemy_scene, enemy_scene, enemy_scene, enemy_scene]),
			Round.new(2, 1.1, [enemy_scene, fish_scene, enemy_scene, fish_scene]),
		]
	),
	Level.new(400, 
		load("res://Levels/level2.tscn"),
		[
			Round.new(2, 2, [fish_scene, fish_scene, enemy_scene, enemy_scene]),
			Round.new(2, 2.1, [fish_scene, fish_scene, enemy_scene, enemy_scene]),
			Round.new(2, 2.2, [fish_scene, fish_scene, enemy_scene, enemy_scene]),
			Round.new(2, 2.3, [fish_scene, fish_scene, enemy_scene, enemy_scene]),
		]
	),
]

@onready var preview_map: TileMap = $GameLayer/PreviewTileMap
@onready var turret_map: TileMap = $GameLayer/TurretTileMap

func _ready():
	change_mouse_mode(TdEnums.MOUSE_MODE.WALL)
	start_game()

func start_game():
	setup_astar_grid(astar_grid)
	next_level()

func next_level():
	stop_timers()
	level_index += 1
	round_index = -1
	if level_index >= len(levels):
		print('you have won the game')
		return
	current_level = levels[level_index]
	gold = current_level.starting_gold
	turret_map.clear_layer(0)
	remove_children($GameLayer/Turrets)
	remove_children($GameLayer/Projectiles)
	if map != null:
		$GameLayer.remove_child(map)
		map.queue_free()
	map = current_level.tile_map.instantiate()
	preview_map.clear()
	preview_map.tile_set = map.tile_set.duplicate(true)
	preview_map.tile_set.set_physics_layer_collision_layer(0, 0)
	preview_map.tile_set.set_physics_layer_collision_mask(0, 0)
	$GameLayer.add_child(map)
	update_nav()
	update_wall_texture_in_ui()
	$UILayer/UIControl.show_start_level(true)
	update_ui()

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
	if enemies_alive <= 0 and round_enemy_index >= total_enemies - 1:
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
	if turret_map.get_cell_source_id(0, coords) == 0:
		# Turret at clicked location
		return
	var source_id = map.get_cell_source_id(TdEnums.TILEMAP_LAYERS.MAZE, coords)
	if [-1, map.border_source, map.start_end_source].has(source_id):
		return
	
	if mouse_mode == TdEnums.MOUSE_MODE.WALL:
		var is_wall = map.wall_source == source_id
		if !is_wall and !can_navigate_with_change(coords):
			# Prevent player from blocking path
			return
		var new_source_id = map.walkable_source if is_wall else map.wall_source
		map.set_cell(TdEnums.TILEMAP_LAYERS.MAZE, coords, new_source_id, Vector2i.ZERO)
		update_nav()
	else:
		if !can_navigate_with_change(coords):
			# Prevent player from blocking path
			return
		map.set_cell(TdEnums.TILEMAP_LAYERS.MAZE, coords, map.wall_source, Vector2i.ZERO)
		var t: Turret = get_selected_turret_scene()
		t.coords = coords
		t.position = map.map_to_local(coords)
		$GameLayer/Turrets.add_child(t)
		turret_map.set_cell(0, coords, 0, Vector2i.ZERO)
		update_nav()

func get_selected_turret_scene(mode: TdEnums.MOUSE_MODE = mouse_mode) -> Turret:
	var scene = null
	match mode:
		TdEnums.MOUSE_MODE.TURRET:
			scene = turret_scene
		TdEnums.MOUSE_MODE.CANNON:
			scene = cannon_scene
		TdEnums.MOUSE_MODE.FLAME_THROWER:
			scene = flame_thrower_scene
		TdEnums.MOUSE_MODE.BALLISTA:
			scene = ballista_scene
		TdEnums.MOUSE_MODE.BLOB_LAUNCHER:
			scene = blob_launcher_scene
	if scene != null:
		return scene.instantiate()
	push_error('Unable to determine selected turret scene from mouse mode $s.' % mouse_mode)
	return null

func can_navigate_with_change(coords: Vector2) -> bool:
	var astar = AStarGrid2D.new()
	setup_astar_grid(astar)
	var used_cells = []
	for blockable_source in [map.wall_source, map.border_source]:
		used_cells.append_array(map.get_used_cells_by_id(TdEnums.TILEMAP_LAYERS.MAZE, blockable_source))
	for cell in used_cells:
		astar.set_point_solid(Vector2i(cell))
	astar.set_point_solid(Vector2i(coords))
	
	# Get cell coordinates for starting position and all enemies
	var cells: Array[Vector2i] = [map.START]
	for enemy in $GameLayer/Enemies.get_children():
		var cell = map.local_to_map(enemy.position)
		if !cells.has(cell):
			cells.append(cell)
	
	var result = true
	for cell in cells:
		var path = astar.get_point_path(cell, map.END)
		if len(path) > 0 and Vector2i(path[0]) == cell:
			path.remove_at(0)
		if len(path) < 1:
			result = false
	return result

func change_mouse_mode(mode: TdEnums.MOUSE_MODE):
	mouse_mode = mode
	$UILayer/UIControl.update_mouse_mode(mode)
	if map != null:
		handle_mouse_hover()

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		handle_mouse_hover()

func handle_mouse_hover():
	var old_hover_position = hover_position
	var new_hover_position = get_mouse_map_cell_pos()
	var hover_position_changed = old_hover_position != new_hover_position
	hover_position = new_hover_position
	
	if turret_preview_sprite != null:
		map.remove_child(turret_preview_sprite)
		turret_preview_sprite.queue_free()
	
	var turret_at_pos = false
	for turret: Turret in $GameLayer/Turrets.get_children():
		# Show turret range if hovering over a turret
		turret.SHOW_RANGE = turret.coords == hover_position
		if turret.SHOW_RANGE:
			turret_at_pos = true
		turret.queue_redraw()
	
	var cell_source = map.get_cell_source_id(TdEnums.TILEMAP_LAYERS.MAZE, hover_position)
	var place_turret = \
			not turret_at_pos \
			and mouse_mode != TdEnums.MOUSE_MODE.WALL \
			and not [-1, map.border_source, map.start_end_source].has(cell_source)
	
	if not hover_position_changed and not place_turret:
		# Avoid checking if can navigate with change if not needed
		return
	
	var valid_placement = can_navigate_with_change(hover_position)
	var blue_green_mod = 1 if valid_placement else 0
	var mod_color = Color(1, blue_green_mod, blue_green_mod, placement_preview_alpha)
	
	if hover_position_changed:
		# Handle wall placement preview
		if hover_position != Vector2i.MAX:
			preview_map.erase_cell(0, old_hover_position)
		if cell_source == map.walkable_source:
			preview_map.set_cell(0, hover_position, map.wall_source, Vector2i.ZERO)
			preview_map.set_layer_modulate(0, mod_color)
	
	if place_turret:
		var turret = get_selected_turret_scene() as Turret
		turret_preview_sprite = turret.get_node("AnimatedSprite2D").duplicate() as AnimatedSprite2D
		turret_preview_sprite.modulate = mod_color
		turret_preview_sprite.position = map.map_to_local(hover_position)
		turret_preview_sprite.z_as_relative = false
		turret_preview_sprite.z_index = 5
		map.add_child(turret_preview_sprite)

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

func setup_astar_grid(grid: AStarGrid2D):
	grid.region = Rect2i(REGION_SIZE/-2.0, REGION_SIZE/-2.0, REGION_SIZE, REGION_SIZE)
	grid.cell_size = Vector2(cell_size, cell_size)
	grid.jumping_enabled = true
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()

func force_draw(): 
	queue_redraw()
	if map != null:
		map.queue_redraw()

func update_ui(): $UILayer/UIControl.update()

func remove_children(node: Node):
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()
