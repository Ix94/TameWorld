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


func _ready() -> void:
	roster.append(load(STARTER_PATH).duplicate() as CreatureData)
	world_seed = randi_range(1, 99999)


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
