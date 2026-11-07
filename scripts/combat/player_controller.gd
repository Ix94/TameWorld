class_name PlayerController
extends Node
## Traduce los controles del jugador en órdenes para su criatura.
## La cámara no gira, así que "arriba" en el mando es -Z en el mundo.
## Con teclado y mouse, la criatura ataca hacia el cursor; con mando, apunta sola al rival.

var me: Creature
var camera: Camera3D
## Cuántas veces más pequeña es la imagen 3D que la ventana (look pixel art).
var pixel_shrink := 1


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(me) or me.is_dead():
		return
	var stick := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	me.move_input = Vector3(stick.x, 0.0, stick.y)
	me.aim_direction = _mouse_aim() if InputDevice.using_mouse() else Vector3.ZERO
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


## Punto del suelo bajo el cursor, como dirección desde la criatura.
func _mouse_aim() -> Vector3:
	if camera == null:
		return Vector3.ZERO
	var mouse := get_viewport().get_mouse_position() / float(pixel_shrink)
	var origin := camera.project_ray_origin(mouse)
	var direction := camera.project_ray_normal(mouse)
	if absf(direction.y) < 0.001:
		return Vector3.ZERO
	var ground := origin + direction * (-origin.y / direction.y)
	var aim := ground - me.global_position
	aim.y = 0.0
	return aim
