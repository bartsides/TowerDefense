extends AnimatedSprite2D

func _ready():
	connect("animation_looped", _animation_looped)

func _animation_looped():
	if animation == "attack":
		play("default")
