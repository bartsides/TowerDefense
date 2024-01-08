extends AnimatedSprite2D

func _ready():
	play("default")
	connect("animation_looped", _animation_looped)

func _animation_looped():
	if animation == "attack":
		play("default")
