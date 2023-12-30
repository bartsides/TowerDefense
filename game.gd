extends Panel

func _ready():
	get_tree().get_root().connect("size_changed", _on_resized)
	_on_resized()

func _set_button_widths(buttons: Array[Button]):
	# why tho
	for button in buttons:
		button.rect_size = Vector2(500, button.size.y)
		print(button.size)

func _start():
	get_tree().change_scene_to_file("res://td.tscn")

func _exit():
	get_tree().quit()

func _on_resized():
	size = get_viewport_rect().size
