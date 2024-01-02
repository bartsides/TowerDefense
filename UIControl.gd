extends Control

var td : TD
var mouse_mode: TdEnums.MOUSE_MODE = TdEnums.MOUSE_MODE.CANNON

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
	print('button clicked ', mode)
	mouse_mode = mode
	# TODO: Update button pressed values

func set_wall_texture(texture: Texture2D):
	$Panel/MarginContainer/VBoxContainer/WallButton.set_texture(texture)

func update():
	$TopLeftPanel/CenterContainer/VBoxContainer/LivesLabel.text = "Lives: %s" % td.lives
	$TopLeftPanel/CenterContainer/VBoxContainer/EnemiesLabel.text = "Enemies: %s/%s" % [td.enemies_alive, td.total_enemies]

func resized():
	size = get_viewport_rect().size

func set_turret(val):
	mouse_mode = val
	td.mouse_mode = mouse_mode

func _unhandled_input(event):
	print('eating ', event)

