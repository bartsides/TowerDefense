extends Control

var td : TD
var selected = false

func _ready():
	td = get_node("/root/TD")
	connect_buttons()
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

func update():
	$TopLeftPanel/CenterContainer/VBoxContainer/LivesLabel.text = "Lives: %s" % td.lives
	$TopLeftPanel/CenterContainer/VBoxContainer/EnemiesLabel.text = "Enemies: %s/%s" % [td.enemies_alive, td.total_enemies]
