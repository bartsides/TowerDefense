extends Panel

class_name TurretButton

signal click(mouse_mode: TdEnums.MOUSE_MODE)

@export var MOUSE_MODE: TdEnums.MOUSE_MODE
@export var TEXTURE: Texture = null

var mouse_within = false
var rect: NinePatchRect
var button: TextureButton

func _ready():
	rect = $NinePatchRect
	button = rect.get_node("Button") as TextureButton
	if TEXTURE != null:
		set_texture(TEXTURE)
	button.connect("mouse_entered", mouse_entered)
	button.connect("mouse_exited", mouse_exited)
	button.connect("pressed", mouse_pressed)
	update()

func mouse_entered():
	mouse_within = true
	update()

func mouse_exited():
	mouse_within = false
	update()

func mouse_pressed():
	click.emit(MOUSE_MODE)

func update():
	if mouse_within or button.button_pressed:
		rect.texture.region.position.x = 0
	else:
		rect.texture.region.position.x = 32

func set_texture(texture):
	button.texture_normal = texture
	button.texture_pressed = texture
	button.texture_hover = texture
	button.texture_disabled = texture
	button.texture_focused = texture
