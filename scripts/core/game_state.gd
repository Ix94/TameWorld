extends Node
## Estado global de la partida: equipo de criaturas y cristales de captura.

signal roster_changed

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


func _ready() -> void:
	roster.append(load(STARTER_PATH).duplicate() as CreatureData)


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
