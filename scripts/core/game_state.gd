extends Node
## Estado global de la partida: equipo, inventario y cambios hechos al mundo.

signal roster_changed

const WORLD_SCENE := "res://scenes/world.tscn"
const COMBAT_SCENE := "res://scenes/combat_arena.tscn"
const STARTER_PATH := "res://data/creatures/brasalce.tres"
const WILD_PATHS := [
	"res://data/creatures/musgorro.tres",
	"res://data/creatures/pedrusco.tres",
	"res://data/creatures/burbujo.tres",
	"res://data/creatures/ventisco.tres",
]

## Medidas del jugador para las reglas de montura.
const RIDER_HEIGHT_M := 1.7
const RIDER_LOAD_KG := 80.0

var roster: Array[CreatureData] = []
var active_index := 0
var capture_orbs := 5
## Recurso -> cantidad (madera, piedra, tierra, arena, cristal, carbón, nieve).
var inventory: Dictionary = {}

## El mundo se regenera desde la semilla y luego se aplican los cambios del jugador.
var world_seed := 0
var world_edits: Dictionary = {}
var world_player_pos: Variant = null

## Pelea iniciada desde el mundo: criatura salvaje elegida y si hay que volver al mapa.
var pending_wild: CreatureData = null
var from_world := false

## Segundos jugados en total (útil para medir los playtests).
var play_seconds := 0.0
## true si al abrir el juego se cargó una partida guardada.
var loaded_from_save := false


func _ready() -> void:
	loaded_from_save = apply_save(SaveGame.read())
	if not loaded_from_save:
		reset()


func _process(delta: float) -> void:
	play_seconds += delta


## Al cerrar la ventana se guarda solo.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()


# --- Guardado ----------------------------------------------------------------

## Deja todo como en una partida nueva (no borra el archivo guardado).
func reset() -> void:
	roster.clear()
	roster.append(load(STARTER_PATH).duplicate() as CreatureData)
	active_index = 0
	capture_orbs = 5
	inventory = {}
	world_seed = randi_range(1, 99999)
	world_edits = {}
	world_player_pos = null
	pending_wild = null
	from_world = false
	play_seconds = 0.0


## Borra la partida guardada y empieza de cero con un mundo nuevo.
func new_game() -> void:
	SaveGame.delete()
	reset()
	loaded_from_save = false


func save_game() -> bool:
	return SaveGame.write(to_save_dict())


func to_save_dict() -> Dictionary:
	var creatures: Array = []
	for creature in roster:
		creatures.append(SaveGame.creature_to_dict(creature))
	var position: Variant = null
	if world_player_pos is Vector3:
		var pos: Vector3 = world_player_pos
		position = [pos.x, pos.y, pos.z]
	return {
		"version": SaveGame.VERSION,
		"roster": creatures,
		"active_index": active_index,
		"capture_orbs": capture_orbs,
		"inventory": inventory,
		"world_seed": world_seed,
		"world_edits": SaveGame.edits_to_dict(world_edits),
		"player_pos": position,
		"play_seconds": play_seconds,
	}


## Carga una partida desde un diccionario. Devuelve false si no es válida.
func apply_save(save: Dictionary) -> bool:
	if int(save.get("version", 0)) != SaveGame.VERSION:
		return false
	var loaded: Array[CreatureData] = []
	for entry: Variant in save.get("roster", []):
		if entry is Dictionary:
			var creature := SaveGame.creature_from_dict(entry)
			if creature != null:
				loaded.append(creature)
	if loaded.is_empty():
		return false
	roster = loaded
	active_index = clampi(int(save.get("active_index", 0)), 0, roster.size() - 1)
	capture_orbs = int(save.get("capture_orbs", 5))
	inventory = {}
	var saved_inventory: Variant = save.get("inventory", {})
	if saved_inventory is Dictionary:
		for item: String in saved_inventory:
			inventory[item] = int(saved_inventory[item])
	world_seed = int(save.get("world_seed", 1))
	var saved_edits: Variant = save.get("world_edits", {})
	world_edits = {}
	if saved_edits is Dictionary:
		world_edits = SaveGame.edits_from_dict(saved_edits)
	var pos: Variant = save.get("player_pos")
	world_player_pos = null
	if pos is Array and (pos as Array).size() == 3:
		world_player_pos = Vector3(float(pos[0]), float(pos[1]), float(pos[2]))
	play_seconds = float(save.get("play_seconds", 0.0))
	pending_wild = null
	from_world = false
	return true


## "1 h 05 min" o "12 min".
func play_time_text() -> String:
	var minutes := int(play_seconds / 60.0)
	if minutes < 60:
		return "%d min" % minutes
	return "%d h %02d min" % [floori(minutes / 60.0), minutes % 60]


func add_item(item: String, amount := 1) -> void:
	inventory[item] = item_count(item) + amount


func take_item(item: String) -> bool:
	if item_count(item) <= 0:
		return false
	inventory[item] = item_count(item) - 1
	return true


func item_count(item: String) -> int:
	return int(inventory.get(item, 0))


func take_pending_wild() -> CreatureData:
	var wild := pending_wild
	pending_wild = null
	return wild


func wild_species() -> Array[CreatureData]:
	var species: Array[CreatureData] = []
	for path: String in WILD_PATHS + [STARTER_PATH]:
		species.append(load(path) as CreatureData)
	return species


func active_creature() -> CreatureData:
	return roster[active_index]


func cycle_active() -> void:
	active_index = (active_index + 1) % roster.size()


func add_to_roster(creature: CreatureData) -> void:
	roster.append(creature)
	roster_changed.emit()


func random_wild(exclude_species: String) -> CreatureData:
	var options: Array[CreatureData] = []
	for path: String in WILD_PATHS:
		var candidate := load(path) as CreatureData
		if candidate.species_name != exclude_species:
			options.append(candidate)
	var pick: CreatureData = options.pick_random()
	return pick.duplicate() as CreatureData
