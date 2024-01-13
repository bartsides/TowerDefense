extends Control

var td : TD
var selected = false
var turret_button_scene = preload("res://UI/turret_button.tscn")

func _ready():
	td = get_node("/root/TD")
	connect_buttons()
	update()

func connect_buttons():
	for turret_button in $RightSidebar/MarginContainer/TurretButtons.get_children():
		if turret_button is TurretButton:
			connect_button(turret_button)

func connect_button(turret_button: TurretButton):
	turret_button.connect("click", button_clicked)

func button_clicked(mode: TdEnums.MOUSE_MODE):
	print('button clicked ', mode)
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

func add_turret(scene_path: String):
	var turret = load(scene_path).instantiate()
	var turret_button = turret_button_scene.instantiate() as TurretButton
	turret_button.MOUSE_MODE = turret.MOUSE_MODE
	turret_button.PRICE = turret.PRICE
	turret_button.TEXTURE = turret.BUTTON_THUMBNAIL
	connect_button(turret_button)
	$RightSidebar/MarginContainer/TurretButtons.add_child(turret_button)

func get_loot():
	td.get_loot()

func _unhandled_input(event):
	if event is InputEventKey:
		for number in [1,2,3,4,5,6,7,8,9,0]:
			if event.is_action_pressed(str(number)):
				var mouse_mode = get_mouse_mode_pressed(number)
				if mouse_mode != -1:
					td.change_mouse_mode(mouse_mode)
					break
	
	if event.is_action_pressed("mouse_click"):
		td.handle_click()
	
	if event is InputEventMouseMotion:
		if event.button_mask == MOUSE_BUTTON_MASK_MIDDLE:
			td.camera.position -= event.relative * td.camera.zoom

func get_mouse_mode_pressed(number: int):
	var i = 1
	for button in $RightSidebar/MarginContainer/TurretButtons.get_children():
		if not button is TurretButton:
			continue
		if i == number:
			return button.MOUSE_MODE
		i += 1
	return -1
