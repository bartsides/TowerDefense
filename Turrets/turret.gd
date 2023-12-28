extends Node2D

class_name Turret

@export var AIM_STYLE = AIM_STYLES.FIRST
@export var ATTACK_RANGE = 120
@export var ATTACK_TIME = 1.0
@export var DAMAGE = 3.0
@export var BULLET_SPEED = 200.0
@export var SHOW_RANGE = true

var bullet_scene = preload("res://Turrets/Projectiles/bullet.tscn")
var target_enemy : Enemy = null
var coords
var sprite : AnimatedSprite2D
var ready_to_fire = false
var range_thickness = .2

enum AIM_STYLES { FIRST, LAST, CLOSEST, FURTHEST, STRONGEST, WEAKEST, FOCUS_FIRST, FOCUS_LAST }

func _ready():
	sprite = $AnimatedSprite2D

func _process(_delta):
	if ready_to_fire:
		_target_enemy()
		if target_enemy != null:
			ready_to_fire = false
			$AttackTimer.stop()
			_attack()
			$AttackTimer.start()
	if target_enemy != null:
		look_at(target_enemy.position)

func _target_enemy():
	var enemies = get_node("/root/TD/Enemies").get_children()
	if len(enemies) < 1:
		return
	var enemy_dist = -1.0
	var selected_enemy : Enemy = null
	for enemy in enemies:
		var dist = enemy.position.distance_to(position)
		if dist == null || dist > ATTACK_RANGE:
			continue
		
		if selected_enemy == null:
			selected_enemy = enemy
			enemy_dist = dist
			continue
		
		var select_enemy = false
		
		match AIM_STYLE:
			AIM_STYLES.FIRST:
				select_enemy = enemy.number < selected_enemy.number
			AIM_STYLES.FOCUS_FIRST:
				select_enemy = enemy.number < selected_enemy.number
			AIM_STYLES.LAST:
				select_enemy = enemy.number > selected_enemy.number
			AIM_STYLES.FOCUS_LAST:
				select_enemy = enemy.number > selected_enemy.number
			AIM_STYLES.CLOSEST:
				select_enemy = enemy_dist < dist
				if select_enemy:
					enemy_dist = dist
			AIM_STYLES.FURTHEST:
				select_enemy = enemy_dist < dist
				if select_enemy:
					enemy_dist = dist
			AIM_STYLES.STRONGEST:
				select_enemy = enemy.health > selected_enemy.HEALTH
			AIM_STYLES.WEAKEST:
				select_enemy = enemy.health < selected_enemy.HEALTH
		
		if select_enemy:
			selected_enemy = enemy
	
	if selected_enemy == null && target_enemy == null:
		ready_to_fire = true
	elif AIM_STYLE == AIM_STYLES.FOCUS_FIRST || AIM_STYLE == AIM_STYLES.FOCUS_LAST:
		if target_enemy == null:
			target_enemy = selected_enemy
	else:
		target_enemy = selected_enemy

func _attack():
	if target_enemy == null:
		return
	var direction = position.direction_to(target_enemy.position)
	var bullet = bullet_scene.instantiate()
	bullet.damage = DAMAGE
	bullet.visible = true
	bullet.look_at(target_enemy.position)
	bullet.apply_central_force(direction * BULLET_SPEED)
	$Bullets.add_child(bullet)
	bullet.fire()
	$AnimatedSprite2D.play("attack")

func _draw():
	if SHOW_RANGE:
		draw_arc(Vector2.ZERO, ATTACK_RANGE, 0, 360, 100, Color.AQUA, range_thickness, true)





