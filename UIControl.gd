extends Control

var td : TD
var selected = false

func _ready():
	get_tree().get_root().connect("size_changed", resized)
	td = get_node("/root/TD")
	connect_buttons()
	resized()
	update()

func connect_buttons():
	for turret_button in $Panel/MarginContainer/VBoxContainer.get_children():
		if turret_button is TurretButton:
			turret_button.connect("click", button_clicked)

func button_clicked(mode: TdEnums.MOUSE_MODE):
	td.change_mouse_mode(mode)

func set_wall_texture(texture: Texture2D):
	var button = $Panel/MarginContainer/VBoxContainer/WallButton as TurretButton
	button.set_texture(texture)
	button.size = Vector2(32, 32)
	button.position = Vector2(19, 19)

func update():
	$TopLeftPanel/CenterContainer/VBoxContainer/LivesLabel.text = "Lives: %s" % td.lives
	$TopLeftPanel/CenterContainer/VBoxContainer/EnemiesLabel.text = "Enemies: %s/%s" % [td.enemies_alive, td.total_enemies]

func resized():
	size = get_viewport_rect().size

func _unhandled_input(event):
	print('eating ', event)

