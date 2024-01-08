extends Bullet

@onready var blib_scene = preload("res://Turrets/Projectiles/blib.tscn")

func death_anim_complete():
	var dir = Vector2.UP
	var angle: float = TdUtils.get_equal_angle(damage.secondary_projectile_count)
	for i in range(0, damage.secondary_projectile_count):
		var blib = blib_scene.instantiate()
		blib.position = global_position + (dir*2)
		blib.damage = damage.get_secondary_projectile_damage()
		if blib.has_method("apply_central_force"):
			blib.apply_central_force(dir * damage.secondary_projectile_speed)
		blib.look_at(dir)
		get_parent().add_child(blib)
		blib.fire()
		dir = dir.rotated(angle)
	super()
