extends Area2D

@export var LIFESPAN = 1.0
@export var MAX_ENEMIES_HIT = 100

var damage: Damage = Damage.new(1)
var dying = false

func fire():
	if $AnimatedSprite2D: $AnimatedSprite2D.play()
	$LifespanTimer.wait_time = LIFESPAN
	$LifespanTimer.start()

func die():
	dying = true
	$AnimatedSprite2D.play("death")
	collision_layer = 0

func kill():
	var parent = get_parent()
	if parent != null: parent.remove_child(self)
	queue_free()

func _hit(body):
	if dying: return
	if body.has_method("is_enemy"):
		body.take_damage(damage)
		MAX_ENEMIES_HIT -= 1
		if MAX_ENEMIES_HIT <= 0:
			die()
