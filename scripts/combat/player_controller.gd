class_name PlayerController
extends Node
## Traduce los controles del jugador en órdenes para su criatura.
## La cámara no gira, así que "arriba" en el mando es -Z en el mundo.

var me: Creature


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(me) or me.is_dead():
		return
	var stick := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	me.move_input = Vector3(stick.x, 0.0, stick.y)
	if Input.is_action_just_pressed("dodge"):
		me.try_dodge()
	elif Input.is_action_just_pressed("attack_light"):
		me.try_light()
	elif Input.is_action_just_pressed("attack_heavy"):
		me.try_heavy()
	elif Input.is_action_just_pressed("ability_1"):
		me.try_ability(0)
	elif Input.is_action_just_pressed("ability_2"):
		me.try_ability(1)
