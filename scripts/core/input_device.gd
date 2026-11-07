extends Node
## Detecta qué control usó el jugador por última vez (teclado y mouse o un mando)
## para mostrar en pantalla los nombres de botones correctos.

signal changed(family: int)

const STICK_DEADZONE := 0.4
## Movimiento mínimo del mouse (en píxeles) para considerar que se está usando.
const MOUSE_MOTION_MIN := 3.0

var family: int = ControlPrompts.Family.KEYBOARD_MOUSE


func _input(event: InputEvent) -> void:
	var detected := family
	if event is InputEventKey or event is InputEventMouseButton:
		detected = ControlPrompts.Family.KEYBOARD_MOUSE
	elif event is InputEventMouseMotion:
		if (event as InputEventMouseMotion).relative.length() < MOUSE_MOTION_MIN:
			return
		detected = ControlPrompts.Family.KEYBOARD_MOUSE
	elif event is InputEventJoypadButton:
		detected = ControlPrompts.family_for(Input.get_joy_name(event.device))
	elif event is InputEventJoypadMotion:
		if absf((event as InputEventJoypadMotion).axis_value) < STICK_DEADZONE:
			return
		detected = ControlPrompts.family_for(Input.get_joy_name(event.device))
	else:
		return
	if detected != family:
		family = detected
		changed.emit(family)


func using_mouse() -> bool:
	return family == ControlPrompts.Family.KEYBOARD_MOUSE


func prompt(action: String) -> String:
	return ControlPrompts.for_action(action, family)


func move_prompt() -> String:
	return ControlPrompts.move_label(family)


func family_name() -> String:
	return ControlPrompts.FAMILY_NAMES[family]
