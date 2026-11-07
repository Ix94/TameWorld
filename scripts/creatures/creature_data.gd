class_name CreatureData
extends Resource
## Ficha de una especie de criatura. Cada especie es un archivo .tres en data/creatures/.

enum MountMode { GROUND, SWIM, FLY }

## La criatura debe medir al menos esto multiplicado por la altura del jinete.
const MOUNT_HEIGHT_RATIO := 1.3
## Fracción de su peso que puede cargar según cómo se desplaza (volar exige más fuerza).
const LOAD_FACTOR := {
	MountMode.GROUND: 0.5,
	MountMode.SWIM: 0.4,
	MountMode.FLY: 0.25,
}

@export var species_name := "Criatura"
@export var nickname := ""
@export var element: Elements.Type = Elements.Type.NORMAL
@export_group("Combate")
@export var max_hp := 100.0
@export var max_energy := 100.0
@export var attack := 20.0
@export var defense := 20.0
@export var move_speed := 6.0
@export var ability_ids: PackedStringArray = []
@export_group("Cuerpo")
@export var height_m := 1.0
@export var weight_kg := 50.0
@export var body_color := Color.WHITE
@export_group("Movilidad")
@export var can_swim := false
@export var can_dive := false
@export var can_fly := false
@export var can_dig := false
@export_group("Captura")
@export_range(0.0, 1.0) var catch_rate := 0.5


func display_name() -> String:
	return nickname if not nickname.is_empty() else species_name


func supports_mode(mode: MountMode) -> bool:
	match mode:
		MountMode.SWIM:
			return can_swim
		MountMode.FLY:
			return can_fly
		_:
			return true


func max_load_kg(mode: MountMode) -> float:
	return weight_kg * float(LOAD_FACTOR[mode])


func can_be_mounted(rider_height_m: float, rider_load_kg: float, mode := MountMode.GROUND) -> bool:
	if not supports_mode(mode):
		return false
	if height_m < rider_height_m * MOUNT_HEIGHT_RATIO:
		return false
	return max_load_kg(mode) >= rider_load_kg
