extends Node
## Registra los controles por código, así no dependen del editor.
## Teclado y mouse (control principal) y cualquier mando: Xbox, PlayStation, Nintendo
## o genérico. Godot usa la misma distribución física para todos los mandos.
## Para el coop en pantalla dividida (etapa 12): repetir con el prefijo "p2_"
## y filtrar por `device` en cada evento de mando.

const KEYS := {
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"move_up": [KEY_W, KEY_UP],
	"move_down": [KEY_S, KEY_DOWN],
	"dodge": [KEY_SPACE, KEY_SHIFT],
	"attack_light": [KEY_J],
	"attack_heavy": [KEY_K],
	"ability_1": [KEY_U, KEY_1],
	"ability_2": [KEY_I, KEY_2],
	"capture": [KEY_C],
	"next_creature": [KEY_TAB],
	"restart": [KEY_R],
	"flee": [KEY_ESCAPE],
	# Mundo
	"jump": [KEY_SPACE],
	"field_1": [KEY_E],
	"field_2": [KEY_Q],
	"place_block": [KEY_F],
	"next_material": [KEY_X],
	# Menú de pausa del mundo
	"pause": [KEY_ESCAPE],
	"save_game": [KEY_G],
	"new_game": [KEY_N],
	"quit_game": [KEY_Q],
}

const PAD_BUTTONS := {
	"dodge": JOY_BUTTON_B,
	"attack_light": JOY_BUTTON_X,
	"attack_heavy": JOY_BUTTON_Y,
	"ability_1": JOY_BUTTON_LEFT_SHOULDER,
	"ability_2": JOY_BUTTON_RIGHT_SHOULDER,
	"capture": JOY_BUTTON_A,
	"next_creature": JOY_BUTTON_BACK,
	"restart": JOY_BUTTON_START,
	"flee": JOY_BUTTON_BACK,
	"jump": JOY_BUTTON_A,
	"field_1": JOY_BUTTON_X,
	"field_2": JOY_BUTTON_Y,
	"place_block": JOY_BUTTON_RIGHT_SHOULDER,
	"next_material": JOY_BUTTON_LEFT_SHOULDER,
	"pause": JOY_BUTTON_START,
	"save_game": JOY_BUTTON_Y,
	"new_game": JOY_BUTTON_X,
	"quit_game": JOY_BUTTON_B,
}


## Botones del mouse. El mismo clic hace cosas distintas en el combate y en el mundo.
const MOUSE_BUTTONS := {
	"attack_light": [MOUSE_BUTTON_LEFT],
	"attack_heavy": [MOUSE_BUTTON_RIGHT],
	"field_1": [MOUSE_BUTTON_LEFT],
	"field_2": [MOUSE_BUTTON_MIDDLE],
	"place_block": [MOUSE_BUTTON_RIGHT],
	"next_material": [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN],
}

## La cruceta también mueve, para mandos sin stick o de estilo retro.
const DPAD := {
	"move_left": JOY_BUTTON_DPAD_LEFT,
	"move_right": JOY_BUTTON_DPAD_RIGHT,
	"move_up": JOY_BUTTON_DPAD_UP,
	"move_down": JOY_BUTTON_DPAD_DOWN,
}


func _ready() -> void:
	for action: String in KEYS:
		_ensure_action(action)
		for keycode: int in KEYS[action]:
			var event := InputEventKey.new()
			event.physical_keycode = keycode as Key
			InputMap.action_add_event(action, event)
	for action: String in PAD_BUTTONS:
		_ensure_action(action)
		var button := InputEventJoypadButton.new()
		var index: int = PAD_BUTTONS[action]
		button.button_index = index as JoyButton
		InputMap.action_add_event(action, button)
	for action: String in MOUSE_BUTTONS:
		_ensure_action(action)
		for button_index: int in MOUSE_BUTTONS[action]:
			var click := InputEventMouseButton.new()
			click.button_index = button_index as MouseButton
			InputMap.action_add_event(action, click)
	for action: String in DPAD:
		_ensure_action(action)
		var dpad := InputEventJoypadButton.new()
		var dpad_index: int = DPAD[action]
		dpad.button_index = dpad_index as JoyButton
		InputMap.action_add_event(action, dpad)
	_add_axis("move_left", JOY_AXIS_LEFT_X, -1.0)
	_add_axis("move_right", JOY_AXIS_LEFT_X, 1.0)
	_add_axis("move_up", JOY_AXIS_LEFT_Y, -1.0)
	_add_axis("move_down", JOY_AXIS_LEFT_Y, 1.0)


func _ensure_action(action: String) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.2)


func _add_axis(action: String, axis: JoyAxis, value: float) -> void:
	_ensure_action(action)
	var motion := InputEventJoypadMotion.new()
	motion.axis = axis
	motion.axis_value = value
	InputMap.action_add_event(action, motion)
