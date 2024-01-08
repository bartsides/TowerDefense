extends Bullet

const SPEED = 80.0
const NUDGE = 360.0

var direction: Vector2 = Vector2.INF
var rng = RandomNumberGenerator.new()

func _ready():
	rng.seed = hash("Godot")

func _integrate_forces(state: PhysicsDirectBodyState2D):
	if direction == Vector2.INF:
		direction = state.linear_velocity.normalized()
	var neg = -1 if rng.randi_range(0, 1) == 1 else 1
	#print(neg)
	direction = direction.rotated(deg_to_rad(neg * NUDGE * state.step))
	linear_velocity = state.linear_velocity + direction * SPEED * state.step
