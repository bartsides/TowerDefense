extends Control

var td : TD
var selected = false

func _ready():
	td = get_node("/root/TD")
	connect_buttons()
	update()

func connect_buttons():
	for turret_button in $RightSidebar/MarginContainer/TurretButtons.get_children():
		if turret_button is TurretButton:
			turret_button.connect("click", button_clicked)

func button_clicked(mode: TdEnums.MOUSE_MODE):
	td.change_mouse_mode(mode)

func set_wall_texture(texture: Texture2D):
	var button = $RightSidebar/MarginContainer/TurretButtons/WallButton as TurretButton
	button.set_texture(texture)

func update():
	$TopLeftPanel/CenterContainer/VBoxContainer/LivesLabel.text = "Lives: %s" % td.lives
	$TopLeftPanel/CenterContainer/VBoxContainer/EnemiesLabel.text = "Enemies: %s/%s" % [td.enemies_alive, td.total_enemies]
	$TopLeftPanel/CenterContainer/VBoxContainer/GoldLabel.text = "Gold: %s" % td.gold
	for turret_button in $RightSidebar/MarginContainer/TurretButtons.get_children():
		if turret_button is TurretButton:
			turret_button.set_disabled(td.gold < turret_button.PRICE)

func update_mouse_mode(mode: TdEnums.MOUSE_MODE):
	for turret_button in $RightSidebar/MarginContainer/TurretButtons.get_children():
		if turret_button is TurretButton:
			turret_button.focused = turret_button.MOUSE_MODE == mode
			turret_button.update_bg()

func _start_level():
	td.start_level()

func show_start_level(show_start: bool):
	$StartButton.visible = show_start
