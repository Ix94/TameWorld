class_name SaveGame
extends RefCounted
## Convierte la partida a JSON y de vuelta. JSON es texto simple: no ejecuta código
## al cargar y se puede abrir con cualquier editor si hace falta revisarlo.

const PATH := "user://partida.json"
const VERSION := 1
const CREATURES_DIR := "res://data/creatures/%s.tres"


## Ficha de una criatura del equipo: especie + lo que cambió al subir de nivel.
static func creature_to_dict(data: CreatureData) -> Dictionary:
	return {
		"species": data.species_name.to_lower(),
		"nickname": data.nickname,
		"level": data.level,
		"xp": data.xp,
		"max_hp": data.max_hp,
		"attack": data.attack,
		"defense": data.defense,
	}


## Devuelve null si la especie ya no existe en el juego.
static func creature_from_dict(entry: Dictionary) -> CreatureData:
	var path := CREATURES_DIR % String(entry.get("species", ""))
	if not ResourceLoader.exists(path):
		return null
	var data := (load(path) as CreatureData).duplicate() as CreatureData
	data.nickname = String(entry.get("nickname", ""))
	data.level = int(entry.get("level", 1))
	data.xp = int(entry.get("xp", 0))
	data.max_hp = float(entry.get("max_hp", data.max_hp))
	data.attack = float(entry.get("attack", data.attack))
	data.defense = float(entry.get("defense", data.defense))
	return data


## Los cambios al mundo se guardan como "x,y,z": bloque.
static func edits_to_dict(edits: Dictionary) -> Dictionary:
	var out := {}
	for cell: Vector3i in edits:
		out["%d,%d,%d" % [cell.x, cell.y, cell.z]] = edits[cell]
	return out


static func edits_from_dict(saved: Dictionary) -> Dictionary:
	var out := {}
	for key: String in saved:
		var parts := key.split(",")
		if parts.size() != 3:
			continue
		out[Vector3i(int(parts[0]), int(parts[1]), int(parts[2]))] = int(saved[key])
	return out


static func write(save: Dictionary) -> bool:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(save, "\t"))
	return true


## Devuelve un diccionario vacío si no hay partida o el archivo está dañado.
static func read() -> Dictionary:
	if not FileAccess.file_exists(PATH):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if parsed is Dictionary:
		return parsed
	return {}


static func delete() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
