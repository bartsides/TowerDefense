extends Node2D

class_name Turret

@export var AIM_STYLE = AIM_STYLES.FIRST
@export var ATTACK_RANGE = 60
@export var ATTACK_TIME = 1.0
@export var DAMAGE = 1.0
@export var BULLET_SPEED = 100.0

var bullet_scene = preload("res://bullet.tscn")
var target_enemy : Enemy = null
var coords

enum AIM_STYLES { FIRST, LAST, CLOSEST, FURTHEST, STRONGEST, WEAKEST, FOCUS_FIRST, FOCUS_LAST }

func _process(_delta):
	if target_enemy != null:
		$Sprite2D.look_at(target_enemy.position)

func _target_enemy():
	# TODO: Handle attack range
	var enemies = get_node("/root/TD/Enemies").get_children()
	if len(enemies) < 1:
		return
	var enemy_dist = -1.0
	var selected_enemy : Enemy = null
	for enemy in enemies:
		if selected_enemy == null:
			selected_enemy = enemy
			enemy_dist = enemy.position.distance_to(position)
			continue
			
		var select = false
		
		match AIM_STYLE:
			AIM_STYLES.FIRST:
				select = enemy.number < selected_enemy.number
			AIM_STYLES.FOCUS_FIRST:
				select = enemy.number < selected_enemy.number
			AIM_STYLES.LAST:
				select = enemy.number > selected_enemy.number
			AIM_STYLES.FOCUS_LAST:
				select = enemy.number > selected_enemy.number
			AIM_STYLES.CLOSEST:
				var dist = enemy.position.distance_to(position)
				select = enemy_dist < dist
				if select:
					enemy_dist = dist
			AIM_STYLES.FURTHEST:
				var dist = enemy.position.distance_to(position)
				select = enemy_dist < dist
				if select:
					enemy_dist = dist
			AIM_STYLES.STRONGEST:
				select = enemy.health > selected_enemy.HEALTH
			AIM_STYLES.WEAKEST:
				select = enemy.health < selected_enemy.HEALTH
		
		if select:
			selected_enemy = enemy
	
	if AIM_STYLE == AIM_STYLES.FOCUS_FIRST || AIM_STYLE == AIM_STYLES.FOCUS_LAST:
		if target_enemy == null:
			target_enemy = selected_enemy
	else:
		target_enemy = selected_enemy

func _attack():
	if target_enemy == null:
		return
	var direction = position.direction_to(target_enemy.position)
	var bullet = bullet_scene.instantiate()	
	bullet.visible = true
	bullet.look_at(target_enemy.position)
	bullet.apply_central_force(direction * BULLET_SPEED)
	$Bullets.add_child(bullet)
	bullet.fire()
