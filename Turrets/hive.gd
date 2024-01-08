extends Turret

const bees: int = 8

func attack():
	if target_enemy == null:
		return
	var dir = Vector2.UP
	var angle: float = TdUtils.get_equal_angle(bees)
	for i in range(0, bees):
		var bee = PROJECTILE_SCENE.instantiate()
		bee.position = global_position + (dir*2)
		bee.damage = damage
		if bee.has_method("apply_central_force"):
			bee.apply_central_force(dir * BULLET_SPEED)
		bee.look_at(dir)
		projectilesNode.add_child(bee)
		bee.fire()
		dir = dir.rotated(angle)
	$AnimatedSprite2D.play("attack")
	$AttackAudioPlayer2D.play()
