@tool
extends Panel

class_name TurretButton

signal click(mouse_mode: TdEnums.MOUSE_MODE)

@export var MOUSE_MODE: TdEnums.MOUSE_MODE
@export var PRICE: int = 100
@export var TEXTURE: Texture = null

var mouse_within = false
var focused = false
var button: TextureButton
var selected_bg: AtlasTexture
var unselected_bg: AtlasTexture
var disabled_val = .4
var disabled_alpha = .6
var disabled_mod = Color(disabled_val, disabled_val, disabled_val, disabled_alpha)

func _ready():
	$PriceLabel.text = str(PRICE)
	$NinePatchRect.texture = $NinePatchRect.texture.duplicate(true)
	unselected_bg = $NinePatchRect.texture
	unselected_bg.region.position.x = 0
	selected_bg = unselected_bg.duplicate(true)
	selected_bg.region.position.x = 32
	button = $NinePatchRect.get_node("Button") as TextureButton
	if TEXTURE != null:
		set_texture(TEXTURE)
	button.connect("mouse_entered", mouse_entered)
	button.connect("mouse_exited", mouse_exited)
	button.connect("pressed", mouse_pressed)
	update_bg()

func mouse_entered():
	mouse_within = true
	update_bg()

func mouse_exited():
	mouse_within = false
	update_bg()

func mouse_pressed():
	click.emit(MOUSE_MODE)

func update_bg():
	$NinePatchRect.texture = selected_bg if mouse_within or focused else unselected_bg

func set_texture(texture: Texture):
	button.texture_normal = texture
	button.texture_pressed = texture
	button.texture_hover = texture
	button.texture_disabled = texture
	button.texture_focused = texture

func set_disabled(disabled: bool):
	button.disabled = disabled
	button.modulate = disabled_mod if disabled else Color(1, 1, 1)
	# TODO: Fix clicking a disabled button causes button texture to no longer modulate
