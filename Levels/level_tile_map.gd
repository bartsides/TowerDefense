extends TileMap

class_name LevelTileMap

@onready var td: TD = get_node("/root/TD")

var start_position: Vector2 = Vector2.INF
var start_map_position: Vector2 = Vector2.INF
var end_position: Vector2 = Vector2.INF
var end_map_position: Vector2 = Vector2.INF
var tilemap_sources: Array[TileSetSource] = []
var walkable_source: int
var wall_source: int
var border_source: int
var start_end_source: int
var show_paths = true
var path_width = .7
var path_color = Color.RED

func _ready():
	update_tilemap_sources()
	_set_start_and_end()

func _set_start_and_end():
	for coords in get_used_cells_by_id(TdEnums.TILEMAP_LAYERS.MAZE, start_end_source):
		var atlas_coords = get_cell_atlas_coords(TdEnums.TILEMAP_LAYERS.MAZE, coords)
		if atlas_coords == Vector2i.ZERO:
			start_map_position = coords
		else:
			end_map_position = coords
	
	if [start_map_position, end_map_position].has(Vector2.INF):
		push_error("Unable to find start and or end position in level: ", self)
	start_position = map_to_local(start_map_position)
	end_position = map_to_local(end_map_position)

func update_tilemap_sources():
	tilemap_sources = []
	for i in range(0, tile_set.get_next_source_id()):
		var source: TileSetSource = tile_set.get_source(i)
		if source != null: 
			tilemap_sources.insert(i, source)
			if source.resource_name.find("Wall") > -1:
				wall_source = i
			elif source.resource_name.find("Border") > -1:
				border_source = i
			elif source.resource_name.find("Start and End") > -1:
				start_end_source = i
			else:
				walkable_source = i

func _draw():
	if !show_paths: return
	_draw_path(td.astar_grid.get_point_path(start_map_position, end_map_position))
	for enemy in td.get_node("GameLayer/Enemies").get_children():
		_draw_path(enemy.path)

func _draw_path(path):
	# TODO: Fix path drawing layer
	if len(path) < 2: return
	var prev = path[0]
	for i in range(1, len(path)):
		var point = path[i]
		draw_circle(point, path_width * 3, path_color)
		draw_line(prev, point, path_color, path_width, true)
		prev = point
