class_name ControlPrompts
extends RefCounted
## Nombres de teclas y botones según el control que se use.
## Godot reconoce cientos de mandos (Xbox, PlayStation, Nintendo, genéricos) con la
## base de datos de SDL y les da la misma distribución física: el botón de abajo es
## siempre JOY_BUTTON_A. Aquí solo cambia el NOMBRE que se muestra en pantalla.

enum Family { KEYBOARD_MOUSE, XBOX, PLAYSTATION, NINTENDO, GENERIC }

const FAMILY_NAMES := ["Teclado y mouse", "Mando de Xbox", "Mando de PlayStation", "Mando de Nintendo", "Mando genérico"]

const PLAYSTATION_WORDS := ["playstation", "dualsense", "dualshock", "ps3", "ps4", "ps5", "sony"]
const NINTENDO_WORDS := ["nintendo", "switch", "pro controller", "joy-con", "joycon"]
const XBOX_WORDS := ["xbox", "xinput", "microsoft"]

const BUTTONS := {
	Family.XBOX: {
		JOY_BUTTON_A: "A", JOY_BUTTON_B: "B", JOY_BUTTON_X: "X", JOY_BUTTON_Y: "Y",
		JOY_BUTTON_LEFT_SHOULDER: "LB", JOY_BUTTON_RIGHT_SHOULDER: "RB",
		JOY_BUTTON_BACK: "View", JOY_BUTTON_START: "Menu",
	},
	Family.PLAYSTATION: {
		JOY_BUTTON_A: "Cruz", JOY_BUTTON_B: "Círculo", JOY_BUTTON_X: "Cuadrado", JOY_BUTTON_Y: "Triángulo",
		JOY_BUTTON_LEFT_SHOULDER: "L1", JOY_BUTTON_RIGHT_SHOULDER: "R1",
		JOY_BUTTON_BACK: "Create", JOY_BUTTON_START: "Options",
	},
	# En Nintendo la A está a la derecha y la B abajo.
	Family.NINTENDO: {
		JOY_BUTTON_A: "B", JOY_BUTTON_B: "A", JOY_BUTTON_X: "Y", JOY_BUTTON_Y: "X",
		JOY_BUTTON_LEFT_SHOULDER: "L", JOY_BUTTON_RIGHT_SHOULDER: "R",
		JOY_BUTTON_BACK: "-", JOY_BUTTON_START: "+",
	},
	Family.GENERIC: {
		JOY_BUTTON_A: "Botón abajo", JOY_BUTTON_B: "Botón derecho", JOY_BUTTON_X: "Botón izquierdo",
		JOY_BUTTON_Y: "Botón arriba", JOY_BUTTON_LEFT_SHOULDER: "L1", JOY_BUTTON_RIGHT_SHOULDER: "R1",
		JOY_BUTTON_BACK: "Select", JOY_BUTTON_START: "Start",
	},
}


## Familia del mando a partir del nombre que informa el sistema.
static func family_for(joy_name: String) -> Family:
	var lower := joy_name.to_lower()
	if _contains_any(lower, PLAYSTATION_WORDS):
		return Family.PLAYSTATION
	if _contains_any(lower, NINTENDO_WORDS):
		return Family.NINTENDO
	if _contains_any(lower, XBOX_WORDS):
		return Family.XBOX
	return Family.GENERIC


static func button_label(family: int, button: int) -> String:
	var table: Dictionary = BUTTONS.get(family, BUTTONS[Family.GENERIC])
	return table.get(button, "Botón %d" % button)


static func key_label(keycode: Key) -> String:
	match keycode:
		KEY_SPACE:
			return "Espacio"
		KEY_ESCAPE:
			return "Esc"
		KEY_SHIFT:
			return "Shift"
		_:
			return OS.get_keycode_string(keycode)


static func mouse_label(button: MouseButton) -> String:
	match button:
		MOUSE_BUTTON_LEFT:
			return "Clic izq."
		MOUSE_BUTTON_RIGHT:
			return "Clic der."
		MOUSE_BUTTON_MIDDLE:
			return "Clic central"
		MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN:
			return "Rueda"
		_:
			return "Botón del mouse %d" % button


## Texto corto con las teclas o botones de una acción, por ejemplo "E / Clic izq.".
static func for_action(action: String, family: int) -> String:
	var labels: PackedStringArray = []
	if InputMap.has_action(action):
		for event in InputMap.action_get_events(action):
			var label := ""
			if family == Family.KEYBOARD_MOUSE:
				if event is InputEventKey:
					label = key_label((event as InputEventKey).physical_keycode)
				elif event is InputEventMouseButton:
					label = mouse_label((event as InputEventMouseButton).button_index)
			elif event is InputEventJoypadButton:
				label = button_label(family, (event as InputEventJoypadButton).button_index)
			if not label.is_empty() and not labels.has(label):
				labels.append(label)
	if labels.is_empty():
		return "?"
	return " / ".join(labels.slice(0, 2))


static func move_label(family: int) -> String:
	return "WASD" if family == Family.KEYBOARD_MOUSE else "Stick izq."


static func _contains_any(text: String, words: Array) -> bool:
	for word: String in words:
		if text.contains(word):
			return true
	return false
