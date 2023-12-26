extends RigidBody2D

@export var LIFESPAN = 1.0

var damage = 1.0

# Called when the node enters the scene tree for the first time.
func _ready():
	$LifespanTimer.wait_time = LIFESPAN
	
func fire():
	$LifespanTimer.start()

func _kill():
	get_parent().remove_child(self)
	queue_free()

func _hit(body):
	if body.has_method("is_enemy"):
		body.take_damage(damage)
		call_deferred('_kill')
