class_name FieldAbilities
extends RefCounted
## Habilidades de campo: cómo cada criatura cambia el mundo.
## Cada objetivo indica [resultado, nivel mínimo]. El resultado es el recurso que se
## obtiene ("break"), el bloque en que se convierte ("transform") o nada ("plant").

const ABILITIES := {
	"quemar": {"name": "Quemar", "kind": "break", "targets": {
		Blocks.Id.LOG: ["carbón", 1], Blocks.Id.CACTUS: ["carbón", 1], Blocks.Id.LEAVES: ["", 1]}},
	"cortar": {"name": "Cortar", "kind": "break", "targets": {
		Blocks.Id.LOG: ["madera", 1], Blocks.Id.CACTUS: ["madera", 1], Blocks.Id.LEAVES: ["", 1]}},
	"romper": {"name": "Romper", "kind": "break", "targets": {
		Blocks.Id.STONE: ["piedra", 1], Blocks.Id.BRICK: ["piedra", 1], Blocks.Id.PLANK: ["madera", 1],
		Blocks.Id.ORE: ["cristal", 3]}},
	"excavar": {"name": "Excavar", "kind": "break", "targets": {
		Blocks.Id.GRASS: ["tierra", 1], Blocks.Id.DIRT: ["tierra", 1], Blocks.Id.SAND: ["arena", 1],
		Blocks.Id.SNOW: ["nieve", 1]}},
	"despejar": {"name": "Despejar", "kind": "break", "targets": {
		Blocks.Id.SNOW: ["nieve", 1], Blocks.Id.LEAVES: ["", 1]}},
	"regar": {"name": "Regar", "kind": "transform", "targets": {
		Blocks.Id.SAND: [Blocks.Id.GRASS, 1], Blocks.Id.DIRT: [Blocks.Id.GRASS, 1]}},
	"plantar": {"name": "Plantar árbol", "kind": "plant", "targets": {
		Blocks.Id.GRASS: [-1, 2]}},
}


## Qué pasa si la habilidad `id`, a nivel `level`, se usa sobre `block`.
## Devuelve {"action": "break"|"transform"|"plant"|"locked"|"none", ...}.
static func resolve(id: String, block: int, level: int) -> Dictionary:
	var ability: Dictionary = ABILITIES.get(id, {})
	if ability.is_empty():
		return {"action": "none"}
	var targets: Dictionary = ability["targets"]
	if not targets.has(block):
		return {"action": "none"}
	var entry: Array = targets[block]
	var needed: int = entry[1]
	if level < needed:
		return {"action": "locked", "needs_level": needed}
	match String(ability["kind"]):
		"break":
			return {"action": "break", "resource": entry[0]}
		"transform":
			return {"action": "transform", "to": entry[0]}
		_:
			return {"action": "plant"}


static func name_of(id: String) -> String:
	var ability: Dictionary = ABILITIES.get(id, {})
	return ability.get("name", id)


## Texto corto con los bloques sobre los que funciona, para la interfaz.
static func targets_text(id: String) -> String:
	var ability: Dictionary = ABILITIES.get(id, {})
	if ability.is_empty():
		return ""
	var parts: PackedStringArray = []
	var targets: Dictionary = ability["targets"]
	for block: int in targets:
		var entry: Array = targets[block]
		var needed: int = entry[1]
		var label := Blocks.name_of(block)
		if needed > 1:
			label += " (nv. %d)" % needed
		parts.append(label)
	return ", ".join(parts)
