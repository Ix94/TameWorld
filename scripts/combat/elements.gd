class_name Elements
extends RefCounted
## Elementos y tabla de ventajas.

enum Type { NORMAL, FUEGO, AGUA, PLANTA, ROCA }

const NAMES := ["Normal", "Fuego", "Agua", "Planta", "Roca"]

## Cada elemento es fuerte contra los de su lista.
const STRONG_AGAINST := {
	Type.FUEGO: [Type.PLANTA],
	Type.AGUA: [Type.FUEGO, Type.ROCA],
	Type.PLANTA: [Type.AGUA, Type.ROCA],
	Type.ROCA: [Type.FUEGO],
}

const SUPER_EFFECTIVE := 1.5
const NOT_EFFECTIVE := 0.67


static func multiplier(attacker: int, defender: int) -> float:
	var strong: Array = STRONG_AGAINST.get(attacker, [])
	if strong.has(defender):
		return SUPER_EFFECTIVE
	var resisted: Array = STRONG_AGAINST.get(defender, [])
	if resisted.has(attacker):
		return NOT_EFFECTIVE
	return 1.0


static func name_of(element: int) -> String:
	return NAMES[element]
