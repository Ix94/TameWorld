extends SceneTree
## Pruebas de reglas del juego. Ejecutar con:
##   godot --headless --path . --script res://tests/run_tests.gd
## (la primera vez, antes: godot --headless --path . --import)

const RIDER_HEIGHT := 1.7
const RIDER_LOAD := 80.0
const CREATURE_PATHS := [
	"res://data/creatures/brasalce.tres",
	"res://data/creatures/musgorro.tres",
	"res://data/creatures/pedrusco.tres",
	"res://data/creatures/burbujo.tres",
	"res://data/creatures/ventisco.tres",
]

var _failures := 0
var _checks := 0


func _initialize() -> void:
	_test_mount_rules()
	_test_capture_chance()
	_test_damage_and_elements()
	_test_creature_files()
	_test_leveling()
	_test_field_abilities()
	_test_world_gen()
	if _failures == 0:
		print("OK: %d comprobaciones pasaron." % _checks)
		quit(0)
	else:
		printerr("FALLARON %d de %d comprobaciones." % [_failures, _checks])
		quit(1)


func _check(condition: bool, label: String) -> void:
	_checks += 1
	if condition:
		print("  ok  ", label)
	else:
		_failures += 1
		printerr("  FALLO  ", label)


func _creature(species: String) -> CreatureData:
	return load("res://data/creatures/%s.tres" % species) as CreatureData


func _test_mount_rules() -> void:
	var G := CreatureData.MountMode.GROUND
	var S := CreatureData.MountMode.SWIM
	var F := CreatureData.MountMode.FLY
	_check(_creature("musgorro").can_be_mounted(RIDER_HEIGHT, RIDER_LOAD, G), "Musgorro (2,4 m, 320 kg) se monta por tierra")
	_check(not _creature("pedrusco").can_be_mounted(RIDER_HEIGHT, RIDER_LOAD, G), "Pedrusco (1 m) es demasiado bajo para montar")
	_check(not _creature("brasalce").can_be_mounted(RIDER_HEIGHT, RIDER_LOAD, G), "Brasalce (1,4 m) es demasiado bajo para montar")
	_check(_creature("burbujo").can_be_mounted(RIDER_HEIGHT, RIDER_LOAD, S), "Burbujo carga al jinete nadando (104 kg >= 80 kg)")
	_check(not _creature("burbujo").can_be_mounted(RIDER_HEIGHT, RIDER_LOAD, F), "Burbujo no vuela")
	_check(_creature("ventisco").can_be_mounted(RIDER_HEIGHT, RIDER_LOAD, G), "Ventisco se monta por tierra")
	_check(not _creature("ventisco").can_be_mounted(RIDER_HEIGHT, RIDER_LOAD, F), "Ventisco vuela, pero no con 80 kg (carga 70 kg)")
	_check(_creature("ventisco").can_be_mounted(RIDER_HEIGHT, 60.0, F), "Ventisco sí vuela con un jinete de 60 kg")


func _test_capture_chance() -> void:
	_check(is_zero_approx(CombatRules.capture_chance(0.5, 1.0, false)), "Con vida llena no se puede capturar")
	var half := CombatRules.capture_chance(0.5, 0.5, false)
	var low := CombatRules.capture_chance(0.5, 0.1, false)
	_check(low > half, "Menos vida = más probabilidad")
	_check(CombatRules.capture_chance(0.5, 0.5, true) > half, "Aturdida = más probabilidad")
	_check(CombatRules.capture_chance(1.0, 0.0, true, 3.0) <= CombatRules.MAX_CAPTURE_CHANCE, "La probabilidad nunca supera el máximo")


func _test_damage_and_elements() -> void:
	var fire := Elements.Type.FUEGO
	var water := Elements.Type.AGUA
	var plant := Elements.Type.PLANTA
	_check(Elements.multiplier(water, fire) > 1.0, "Agua es eficaz contra Fuego")
	_check(Elements.multiplier(fire, water) < 1.0, "Fuego no es eficaz contra Agua")
	_check(Elements.multiplier(fire, plant) > 1.0, "Fuego es eficaz contra Planta")
	_check(is_equal_approx(Elements.multiplier(Elements.Type.NORMAL, fire), 1.0), "Normal es neutral")
	var neutral := CombatRules.damage(1.0, 20.0, 20.0, 1.0)
	_check(CombatRules.damage(1.0, 20.0, 20.0, 1.5) > neutral, "El daño sube con ventaja de elemento")
	_check(CombatRules.damage(1.0, 30.0, 20.0, 1.0) > neutral, "Más ataque = más daño")
	_check(CombatRules.damage(0.01, 1.0, 999.0, 0.5) >= 1.0, "El daño mínimo es 1")


func _test_creature_files() -> void:
	for path: String in CREATURE_PATHS:
		var data := load(path) as CreatureData
		_check(data != null, "Carga %s" % path)
		if data == null:
			continue
		_check(data.max_hp > 0.0 and data.height_m > 0.0 and data.weight_kg > 0.0, "%s tiene stats válidos" % data.species_name)
		for id in data.ability_ids:
			_check(not AbilityLibrary.find(id).is_empty(), "%s: la habilidad '%s' existe" % [data.species_name, id])
		_check(not data.field_ability_ids.is_empty(), "%s tiene habilidad de campo" % data.species_name)
		for id in data.field_ability_ids:
			_check(FieldAbilities.ABILITIES.has(id), "%s: la habilidad de campo '%s' existe" % [data.species_name, id])
		_check(not data.habitat_biomes.is_empty(), "%s tiene al menos un bioma" % data.species_name)


func _test_leveling() -> void:
	var data := _creature("brasalce").duplicate() as CreatureData
	var attack_before := data.attack
	_check(data.level == 1 and data.xp_to_next() == 10, "Empieza en nivel 1 y necesita 10 XP")
	_check(data.gain_xp(10) == 1 and data.level == 2, "10 XP suben a nivel 2")
	_check(data.attack > attack_before, "Al subir de nivel mejora el ataque")
	data.set_level(5)
	_check(data.level == 5, "Una criatura salvaje puede empezar en nivel 5")
	_check(_creature("brasalce").level == 1, "Subir de nivel una copia no cambia la ficha original")


func _test_field_abilities() -> void:
	_check(FieldAbilities.resolve("cortar", Blocks.Id.LOG, 1) == {"action": "break", "resource": "madera"}, "Cortar un tronco da madera")
	_check(FieldAbilities.resolve("cortar", Blocks.Id.STONE, 1)["action"] == "none", "Cortar no sirve sobre piedra")
	_check(FieldAbilities.resolve("romper", Blocks.Id.ORE, 1) == {"action": "locked", "needs_level": 3}, "Romper mineral pide nivel 3")
	_check(FieldAbilities.resolve("romper", Blocks.Id.ORE, 3)["resource"] == "cristal", "A nivel 3, romper mineral da cristal")
	_check(FieldAbilities.resolve("regar", Blocks.Id.SAND, 1) == {"action": "transform", "to": Blocks.Id.GRASS}, "Regar convierte arena en pasto")
	_check(FieldAbilities.resolve("plantar", Blocks.Id.GRASS, 1)["action"] == "locked", "Plantar pide nivel 2")
	_check(FieldAbilities.resolve("plantar", Blocks.Id.GRASS, 2)["action"] == "plant", "A nivel 2 se pueden plantar árboles")
	_check(FieldAbilities.resolve("inventada", Blocks.Id.GRASS, 9)["action"] == "none", "Una habilidad desconocida no hace nada")


func _test_world_gen() -> void:
	var first := WorldGen.new(42).generate()
	var second := WorldGen.new(42).generate()
	_check(first.size() == second.size() and first == second, "La misma semilla genera el mismo mundo")
	_check(first != WorldGen.new(43).generate(), "Otra semilla genera otro mundo")
	var floor_ok := true
	var water_ok := true
	for x in WorldGen.SIZE:
		for z in WorldGen.SIZE:
			if not Blocks.is_solid(int(first.get(Vector3i(x, 0, z), Blocks.EMPTY))):
				floor_ok = false
	for cell: Vector3i in first:
		if first[cell] == Blocks.Id.WATER and cell.y >= WorldGen.SEA_LEVEL:
			water_ok = false
	_check(floor_ok, "Todas las columnas tienen suelo en y = 0")
	_check(water_ok, "El agua solo está bajo el nivel del mar")
	var biomes := {}
	for world_seed in [1, 2, 3, 4, 5]:
		var gen := WorldGen.new(world_seed)
		for x in range(0, WorldGen.SIZE, 2):
			for z in range(0, WorldGen.SIZE, 2):
				biomes[gen.biome_at(x, z)] = true
	_check(biomes.size() >= 4, "Aparecen al menos 4 biomas distintos (%d)" % biomes.size())
	var trees := 0
	for cell: Vector3i in first:
		if first[cell] == Blocks.Id.LOG:
			trees += 1
	_check(trees > 0, "El mundo tiene árboles (%d troncos)" % trees)
	_check(WorldGen.tree_cells(5, 3, 5).values().count(Blocks.Id.LOG) == 3, "Un árbol tiene 3 troncos")
