extends Node2D

class_name Turret

@export var AIM_STYLE = AIM_STYLES.FIRST
@export var ATTACK_RANGE = 120
@export var ATTACK_TIME = 1.0
@export var DAMAGE = 3.0
@export var BULLET_SPEED = 200.0
@export var SHOW_RANGE = false
@export var PROJECTILE_SCENE: PackedScene = preload("res://Turrets/Projectiles/bullet.tscn")
@export var ATTACK_SOUND: AudioStreamMP3 = null

var target_enemy: Enemy = null
var coords
var ready_to_fire = false
var range_thickness = .2
@onready var projectilesNode = get_node("/root/TD/GameLayer/Projectiles")

enum AIM_STYLES { \
	FIRST, LAST, \
	CLOSEST, FURTHEST, \
	STRONGEST, WEAKEST, \
	FOCUS_FIRST, FOCUS_LAST, \
}

func _ready():
	if ATTACK_SOUND != null:
		$AttackAudioPlayer2D.stream = ATTACK_SOUND
	$AttackTimer.wait_time = ATTACK_TIME

func _process(_delta):
	if ready_to_fire:
		_target_enemy()
		if target_enemy != null:
			$AttackTimer.stop()
			ready_to_fire = false
			look_at(target_enemy.position)
			_attack()
			$AttackTimer.start()
	elif target_enemy != null:
		look_at(target_enemy.position)

func _target_enemy():
	var enemies = get_node("/root/TD/GameLayer/Enemies").get_children()
	if len(enemies) < 1:
		return
	var enemy_dist = -1.0
	var selected_enemy: Enemy = null
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
				select_enemy = dist < enemy_dist
				if select_enemy:
					enemy_dist = dist
			AIM_STYLES.FURTHEST:
				select_enemy = dist > enemy_dist
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
	if target_enemy == null or PROJECTILE_SCENE == null:
		return
	var bullet = PROJECTILE_SCENE.instantiate()
	bullet.position = to_global($BulletMarker2D.position)
	bullet.damage = DAMAGE
	if bullet.has_method("apply_central_force"):
		bullet.apply_central_force(position.direction_to(target_enemy.position) * BULLET_SPEED)
	bullet.look_at(target_enemy.position)
	projectilesNode.add_child(bullet)
	bullet.fire()
	$AnimatedSprite2D.play("attack")
	$AttackAudioPlayer2D.play()

func _draw():
	if SHOW_RANGE:
		draw_arc(Vector2.ZERO, ATTACK_RANGE, 0, 360, 100, Color.AQUA, range_thickness, true)
