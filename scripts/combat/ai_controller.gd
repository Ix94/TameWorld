class_name AIController
extends Node
## IA simple para criaturas salvajes: se acerca, rodea al rival,
## ataca con pausas y a veces esquiva los golpes fuertes.

var me: Creature
var foe: Creature
## Más alto = ataca más seguido.
var aggression := 1.0

var _attack_timer := 1.2
var _strafe_timer := 0.0
var _strafe_sign := 1.0


func _physics_process(delta: float) -> void:
	if not is_instance_valid(me) or me.is_dead():
		return
	if not is_instance_valid(foe) or not foe.is_targetable():
		me.move_input = Vector3.ZERO
		return
	_attack_timer -= delta * aggression
	_strafe_timer -= delta
	if _strafe_timer <= 0.0:
		_strafe_sign = -_strafe_sign if randf() < 0.5 else _strafe_sign
		_strafe_timer = randf_range(1.0, 2.5)

	var to := foe.global_position - me.global_position
	to.y = 0.0
	var distance := to.length()
	var toward := to / distance if distance > 0.01 else Vector3.FORWARD
	var side := Vector3(-toward.z, 0.0, toward.x) * _strafe_sign

	if foe.is_winding_up() and distance < 4.0 and randf() < 2.0 * delta:
		me.move_input = side
		if me.try_dodge():
			return
	if not me.can_act():
		return

	var engage := 1.3 + me.radius() + foe.radius()
	if distance > engage:
		me.move_input = (toward + side * 0.3).normalized()
		if distance > 5.0 and _attack_timer <= 0.0 and _try_ranged():
			_attack_timer = randf_range(1.5, 2.5)
	else:
		me.move_input = (side * 0.6 + toward * clampf(distance - engage * 0.8, -1.0, 1.0)).normalized() * 0.5
		if _attack_timer <= 0.0:
			_choose_close_attack()
			_attack_timer = randf_range(0.9, 1.8)


func _try_ranged() -> bool:
	for i in me.data.ability_ids.size():
		var ability := AbilityLibrary.find(me.data.ability_ids[i])
		if int(ability.get("kind", -1)) != AbilityLibrary.Kind.AREA and me.try_ability(i):
			return true
	return false


func _choose_close_attack() -> void:
	var roll := randf()
	if roll < 0.5:
		me.try_light()
	elif roll < 0.75:
		me.try_heavy()
	elif me.data.ability_ids.size() > 0:
		if not me.try_ability(randi() % me.data.ability_ids.size()):
			me.try_light()
