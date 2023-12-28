extends AnimatedSprite2D

func _ready():
	connect("animation_looped", _animation_looped)

func _animation_looped():
	match animation:
		"intro":
			play("default")
		"death":
			get_parent().kill()
