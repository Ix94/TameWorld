class_name CreatureData
extends Resource
## Ficha de una especie de criatura. Cada especie es un archivo .tres en data/creatures/.

enum MountMode { GROUND, SWIM, FLY }

## La criatura debe medir al menos esto multiplicado por la altura del jinete.
const MOUNT_HEIGHT_RATIO := 1.3
## Cada nivel multiplica vida, ataque y defensa por este valor.
const STAT_GROWTH := 1.06
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
@export_group("Progreso")
@export var level := 1
@export var xp := 0
@export_group("Mundo")
## Habilidades que cambian el mundo (ver FieldAbilities).
@export var field_ability_ids: PackedStringArray = []
## Biomas donde aparece en estado salvaje (ver WorldGen.Biome).
@export var habitat_biomes: PackedInt32Array = []


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


## Experiencia necesaria para pasar al siguiente nivel.
func xp_to_next() -> int:
	return 10 * level


## Suma experiencia y devuelve cuántos niveles subió.
func gain_xp(amount: int) -> int:
	xp += amount
	var gained := 0
	while xp >= xp_to_next():
		xp -= xp_to_next()
		level += 1
		_grow()
		gained += 1
	return gained


## Sube directamente hasta un nivel (para criaturas salvajes).
func set_level(target_level: int) -> void:
	while level < target_level:
		level += 1
		_grow()


func _grow() -> void:
	max_hp *= STAT_GROWTH
	attack *= STAT_GROWTH
	defense *= STAT_GROWTH
