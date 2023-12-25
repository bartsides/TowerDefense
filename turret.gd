extends Node2D

@export var AIM_STYLE = AIM_STYLES.FIRST
@export var ATTACK_RANGE = 60
@export var ATTACK_TIME = 1.0
@export var DAMAGE = 1.0
@export var BULLET_SPEED = 1.0

var target_enemy : Enemy = null
var coords

enum AIM_STYLES { FIRST, LAST, CLOSEST, FURTHEST, STRONGEST, WEAKEST }

func _process(_delta):
	if target_enemy != null:
		$Sprite2D.look_at(target_enemy.position)

func _target_enemy():
	var enemies = get_node("/root/TD/Enemies").get_children()
	if len(enemies) < 1:
		return
	var target_enemy_dist = -1.0
	for enemy in enemies:
		if target_enemy == null:
			target_enemy = enemy
			target_enemy_dist = enemy.position.distance_to(position)
			continue
		
		match AIM_STYLE:
			AIM_STYLES.FIRST:
				if enemy.number < target_enemy.number:
					target_enemy = enemy
			AIM_STYLES.LAST:
				if enemy.number > target_enemy.number:
					target_enemy = enemy
			AIM_STYLES.CLOSEST:
				var dist = enemy.position.distance_to(position)
				if target_enemy_dist < dist:
					target_enemy = enemy
			AIM_STYLES.FURTHEST:
				var dist = enemy.position.distance_to(position)
				if target_enemy_dist > dist:
					target_enemy = enemy
			AIM_STYLES.STRONGEST:
				if enemy.health > target_enemy.HEALTH:
					target_enemy = enemy
			AIM_STYLES.WEAKEST:
				if enemy.health < target_enemy.HEALTH:
					target_enemy = enemy

func _attack():
	if target_enemy == null:
		return
	var direction = position.direction_to(target_enemy.position)
	var bullet = $Bullet.duplicate() as RigidBody2D
	bullet.visible = true
	bullet.look_at(target_enemy.position)
	bullet.add_constant_force(direction * BULLET_SPEED)
	$Bullets.add_child(bullet)
	print('attack ', bullet.linear_velocity)
