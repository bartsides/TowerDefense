extends Control

var td : TD

# Called when the node enters the scene tree for the first time.
func _ready():
	td = get_node("/root/TD")
	update()

func update():
	$TopLeftInfo/Label.text = "Enemies alive: %s" % td.enemies_alive
	#$Panel.position = get_screen_transform() * get_global_transform_with_canvas() * Vector2(0, 0)
