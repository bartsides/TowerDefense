extends Control

var td : TD

func _ready():
	get_tree().get_root().connect("size_changed", resized)
	td = get_node("/root/TD")
	resized()
	update()

func update():
	$TopLeftPanel/CenterContainer/Label.text = "Enemies alive: %s" % td.enemies_alive
	$TopRightPanel/CenterContainer/Label.text = "Lives: %s" % td.lives

func resized():
	size = get_viewport_rect().size
	print('resize ', size)
