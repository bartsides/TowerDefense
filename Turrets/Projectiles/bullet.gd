extends RigidBody2D

@export var LIFESPAN = 1.0
@export var MAX_ENEMIES_HIT = 1
@export var IS_PROJECTILE = true

var damage = 1.0
var dying = false

# Called when the node enters the scene tree for the first time.
func _ready():
	$LifespanTimer.wait_time = LIFESPAN
	if $AnimatedSprite2D: $AnimatedSprite2D.play()

func fire():
	$LifespanTimer.start()

func die():
	dying = true
	$AnimatedSprite2D.play("death")
	linear_velocity = Vector2i.ZERO
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
