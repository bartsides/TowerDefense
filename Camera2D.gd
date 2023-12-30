extends Camera2D

const MAX_ZOOM = 10
const MIN_ZOOM = .02
const ZOOM_INCR = .2
const MOVE_SPEED = 2

func _process(_delta):
	if Input.is_action_pressed("move_down"):
		position += Vector2(0, MOVE_SPEED)

	if Input.is_action_pressed("move_up"):
		position -= Vector2(0, MOVE_SPEED)

	if Input.is_action_pressed("move_left"):
		position -= Vector2(MOVE_SPEED, 0)

	if Input.is_action_pressed("move_right"):
		position += Vector2(MOVE_SPEED, 0)

func _input(event):
	if event.is_action_pressed("mouse_scroll_down"):
		zoom = Vector2(max(zoom.x - ZOOM_INCR, MIN_ZOOM), max(zoom.y - ZOOM_INCR, MIN_ZOOM))

	if event.is_action_pressed("mouse_scroll_up"):
		zoom = Vector2(min(zoom.x + ZOOM_INCR, MAX_ZOOM), min(zoom.y + ZOOM_INCR, MAX_ZOOM))
