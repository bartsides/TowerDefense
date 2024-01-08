extends TileMap

class_name LevelTileMap

@export var START: Vector2
@export var END: Vector2

@onready var td: TD = get_node("/root/TD")

var start_position: Vector2
var end_position: Vector2
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
	set_cell(TdEnums.TILEMAP_LAYERS.MAZE, START, start_end_source, Vector2i.ZERO)
	set_cell(TdEnums.TILEMAP_LAYERS.MAZE, END, start_end_source, Vector2i(9, 0))
	start_position = map_to_local(START)
	end_position = map_to_local(END)

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

func _unhandled_input(event):
	if   event.is_action_pressed("1"):
		td.change_mouse_mode(TdEnums.MOUSE_MODE.WALL)
	elif event.is_action_pressed("2"):
		td.change_mouse_mode(TdEnums.MOUSE_MODE.TURRET)
	elif event.is_action_pressed("3"):
		td.change_mouse_mode(TdEnums.MOUSE_MODE.CANNON)
	elif event.is_action_pressed("4"):
		td.change_mouse_mode(TdEnums.MOUSE_MODE.FLAME_THROWER)
	elif event.is_action_pressed("5"):
		td.change_mouse_mode(TdEnums.MOUSE_MODE.BALLISTA)
	elif event.is_action_pressed("6"):
		td.change_mouse_mode(TdEnums.MOUSE_MODE.BLOB_LAUNCHER)
	
	if event.is_action_pressed("mouse_click"):
		td.handle_click()

func _draw():
	if !show_paths: return
	_draw_path(td.astar_grid.get_point_path(START, END))
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
