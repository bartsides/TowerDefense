extends TileMap

class_name LevelTileMap

@export var START: Vector2
@export var END: Vector2

var start_position: Vector2
var end_position: Vector2

var tilemap_sources: Array[TileSetSource] = []
var walkable_source: int
var wall_source: int
var border_source: int
var start_end_source: int

func _ready():
	update_tilemap_sources()
	set_cell(TdEnums.TILEMAP_LAYERS.MAZE, START, start_end_source, Vector2i.ZERO)
	set_cell(TdEnums.TILEMAP_LAYERS.MAZE, END, start_end_source, Vector2i.ZERO)
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
