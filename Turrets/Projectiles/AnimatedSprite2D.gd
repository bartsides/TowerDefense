extends AnimatedSprite2D

func _ready():
	play("default")
	connect("animation_looped", _animation_looped)

func _animation_looped():
	match animation:
		"intro":
			play("default")
		"death":
			get_parent().death_anim_complete()
