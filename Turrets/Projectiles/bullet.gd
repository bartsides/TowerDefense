extends RigidBody2D

class_name Bullet

var damage: Damage = Damage.new(1)
var max_enemies_hit = 1
var dying = false

func fire():
	if $AnimatedSprite2D: $AnimatedSprite2D.play()
	$LifespanTimer.wait_time = damage.projectile_lifespan
	$LifespanTimer.start()

func die():
	dying = true
	$AnimatedSprite2D.play("death")
	linear_velocity = Vector2i.ZERO
	collision_layer = 0

func death_anim_complete():
	kill()

func kill():
	var parent = get_parent()
	if parent != null: parent.remove_child(self)
	queue_free()

func _hit(body):
	if dying: return
	if body.has_method("is_enemy"):
		body.take_damage(damage)
		max_enemies_hit -= 1
		if max_enemies_hit <= 0:
			die()
