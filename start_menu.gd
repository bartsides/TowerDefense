extends PanelContainer

func _ready():
	get_tree().get_root().connect("size_changed", _on_resized)
	_on_resized()

func _start():
	get_tree().change_scene_to_file("res://td.tscn")

func _exit():
	get_tree().quit()

func _on_resized():
	size = get_viewport_rect().size
