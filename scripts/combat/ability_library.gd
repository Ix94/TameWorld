class_name AbilityLibrary
extends RefCounted
## Habilidades disponibles. Cada criatura las referencia por id.
## El elemento del golpe es el de la criatura que la usa.

enum Kind { DASH_STRIKE, PROJECTILE, AREA }

const ABILITIES := {
	"embestida": {"name": "Embestida", "kind": Kind.DASH_STRIKE, "power": 1.5, "energy": 25.0, "cooldown": 3.5, "range": 5.0},
	"llamarada": {"name": "Llamarada", "kind": Kind.PROJECTILE, "power": 1.2, "energy": 20.0, "cooldown": 2.0, "range": 11.0},
	"chorro": {"name": "Chorro", "kind": Kind.PROJECTILE, "power": 1.2, "energy": 20.0, "cooldown": 2.0, "range": 11.0},
	"rafaga": {"name": "Ráfaga", "kind": Kind.PROJECTILE, "power": 1.0, "energy": 15.0, "cooldown": 1.5, "range": 9.0},
	"temblor": {"name": "Temblor", "kind": Kind.AREA, "power": 1.3, "energy": 30.0, "cooldown": 5.0, "range": 2.8},
}


static func find(id: String) -> Dictionary:
	return ABILITIES.get(id, {})


## Convierte una habilidad en la definición de ataque que usa Creature.
static func to_attack(ability: Dictionary) -> Dictionary:
	var kind: int = ability["kind"]
	var power: float = ability["power"]
	var reach: float = ability["range"]
	var energy: float = ability["energy"]
	match kind:
		Kind.DASH_STRIKE:
			return {"kind": "dash", "windup": 0.25, "active": 0.3, "recovery": 0.3,
				"power": power, "range": 0.6, "arc_deg": 180.0, "energy": energy, "lunge": 0.0}
		Kind.PROJECTILE:
			return {"kind": "projectile", "windup": 0.28, "active": 0.05, "recovery": 0.25,
				"power": power, "range": reach, "arc_deg": 0.0, "energy": energy, "lunge": 0.0}
		_:
			return {"kind": "melee", "windup": 0.4, "active": 0.1, "recovery": 0.4,
				"power": power, "range": reach, "arc_deg": 360.0, "energy": energy, "lunge": 0.0}
