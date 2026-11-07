class_name Blocks
extends RefCounted
## Tipos de bloque del mundo, como en Minecraft o Terraria.

enum Id { GRASS, DIRT, STONE, SAND, SNOW, LOG, LEAVES, ORE, WATER, PLANK, BRICK, CACTUS }

## Valor de una celda vacía (igual a GridMap.INVALID_CELL_ITEM).
const EMPTY := -1

const INFO := {
	Id.GRASS: {"name": "Pasto", "color": Color(0.38, 0.64, 0.3)},
	Id.DIRT: {"name": "Tierra", "color": Color(0.5, 0.35, 0.22)},
	Id.STONE: {"name": "Piedra", "color": Color(0.52, 0.52, 0.56)},
	Id.SAND: {"name": "Arena", "color": Color(0.87, 0.8, 0.55)},
	Id.SNOW: {"name": "Nieve", "color": Color(0.93, 0.95, 1.0)},
	Id.LOG: {"name": "Tronco", "color": Color(0.45, 0.3, 0.17)},
	Id.LEAVES: {"name": "Hojas", "color": Color(0.2, 0.47, 0.22)},
	Id.ORE: {"name": "Mineral de cristal", "color": Color(0.45, 0.8, 0.9)},
	Id.WATER: {"name": "Agua", "color": Color(0.25, 0.5, 0.9)},
	Id.PLANK: {"name": "Tablón", "color": Color(0.78, 0.6, 0.38)},
	Id.BRICK: {"name": "Bloque de piedra", "color": Color(0.62, 0.64, 0.7)},
	Id.CACTUS: {"name": "Cactus", "color": Color(0.3, 0.6, 0.3)},
}

## Materiales del inventario que se pueden colocar como bloque.
const PLACEABLE := {
	"madera": Id.PLANK,
	"piedra": Id.BRICK,
	"tierra": Id.DIRT,
	"arena": Id.SAND,
}
const MATERIAL_ORDER := ["madera", "piedra", "tierra", "arena"]


static func is_solid(id: int) -> bool:
	return id != EMPTY and id != Id.WATER


static func name_of(id: int) -> String:
	if not INFO.has(id):
		return "Vacío"
	return INFO[id]["name"]


static func color_of(id: int) -> Color:
	return INFO[id]["color"]
