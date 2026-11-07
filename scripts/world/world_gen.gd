class_name WorldGen
extends RefCounted
## Genera el mundo a partir de una semilla: la misma semilla da siempre el mismo mundo.
## Devuelve un diccionario celda (Vector3i) -> bloque, sin depender de ninguna escena.

enum Biome { PRADERA, BOSQUE, DESIERTO, NIEVE, MONTANA, COSTA }

const BIOME_NAMES := ["Pradera", "Bosque", "Desierto", "Nieve", "Montaña", "Costa"]
const SIZE := 48
const SEA_LEVEL := 3
const MAX_HEIGHT := 10
const MOUNTAIN_HEIGHT := 8
const ORE_CHANCE := 0.06

var world_seed: int
var _height_noise := FastNoiseLite.new()
var _temperature_noise := FastNoiseLite.new()
var _moisture_noise := FastNoiseLite.new()


func _init(seed_value: int) -> void:
	world_seed = seed_value
	_height_noise.seed = seed_value
	_height_noise.frequency = 0.045
	_temperature_noise.seed = seed_value + 1
	_temperature_noise.frequency = 0.03
	_moisture_noise.seed = seed_value + 2
	_moisture_noise.frequency = 0.035


## Número de bloques sólidos de la columna (la superficie está en y = altura - 1).
func height_at(x: int, z: int) -> int:
	var noise := _height_noise.get_noise_2d(x, z)
	return clampi(roundi(4.0 + noise * 7.0), 1, MAX_HEIGHT)


func biome_at(x: int, z: int) -> Biome:
	var height := height_at(x, z)
	if height <= SEA_LEVEL:
		return Biome.COSTA
	if height >= MOUNTAIN_HEIGHT:
		return Biome.MONTANA
	var temperature := _temperature_noise.get_noise_2d(x, z)
	var moisture := _moisture_noise.get_noise_2d(x, z)
	if temperature < -0.2:
		return Biome.NIEVE
	if temperature > 0.2 and moisture < 0.05:
		return Biome.DESIERTO
	if moisture > 0.1:
		return Biome.BOSQUE
	return Biome.PRADERA


func generate() -> Dictionary:
	var cells := {}
	var rng := RandomNumberGenerator.new()
	rng.seed = world_seed
	for x in SIZE:
		for z in SIZE:
			var height := height_at(x, z)
			var biome := biome_at(x, z)
			var surface := _surface_block(biome)
			var sandy := biome == Biome.DESIERTO or biome == Biome.COSTA
			var subsoil := Blocks.Id.SAND if sandy else Blocks.Id.DIRT
			for y in height:
				var block: int = Blocks.Id.STONE
				if y == height - 1:
					block = surface
				elif y >= height - 3:
					block = subsoil
				elif rng.randf() < ORE_CHANCE:
					block = Blocks.Id.ORE
				cells[Vector3i(x, y, z)] = block
			for y in range(height, SEA_LEVEL):
				cells[Vector3i(x, y, z)] = Blocks.Id.WATER
			var roll := rng.randf()
			var inside := x > 1 and z > 1 and x < SIZE - 2 and z < SIZE - 2
			if not inside:
				continue
			if (biome == Biome.BOSQUE and roll < 0.08) or (biome == Biome.PRADERA and roll < 0.015):
				cells.merge(tree_cells(x, height, z), true)
			elif biome == Biome.DESIERTO and roll < 0.03:
				cells[Vector3i(x, height, z)] = Blocks.Id.CACTUS
				cells[Vector3i(x, height + 1, z)] = Blocks.Id.CACTUS
	return cells


## Árbol con su base en la celda (x, y, z).
static func tree_cells(x: int, y: int, z: int) -> Dictionary:
	var cells := {}
	for dy in 3:
		cells[Vector3i(x, y + dy, z)] = Blocks.Id.LOG
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			if dx != 0 or dz != 0:
				cells[Vector3i(x + dx, y + 2, z + dz)] = Blocks.Id.LEAVES
	for offset: Vector3i in [Vector3i(0, 3, 0), Vector3i(1, 3, 0), Vector3i(-1, 3, 0), Vector3i(0, 3, 1), Vector3i(0, 3, -1)]:
		cells[Vector3i(x, y, z) + offset] = Blocks.Id.LEAVES
	return cells


static func biome_name(biome: int) -> String:
	return BIOME_NAMES[biome]


func _surface_block(biome: Biome) -> int:
	match biome:
		Biome.DESIERTO, Biome.COSTA:
			return Blocks.Id.SAND
		Biome.NIEVE:
			return Blocks.Id.SNOW
		Biome.MONTANA:
			return Blocks.Id.STONE
		_:
			return Blocks.Id.GRASS
