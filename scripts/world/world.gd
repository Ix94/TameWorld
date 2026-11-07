class_name WorldScene
extends Node
## Muestra del mundo abierto (vista previa de las etapas 2 a 5).
## El mundo está hecho de bloques que las criaturas cambian con sus habilidades de campo,
## como en Minecraft o Terraria. Los cambios se guardan en GameState y siguen ahí al volver.

const PIXEL_SHRINK := 3
const CAMERA_PITCH_DEG := 45.0
const CAMERA_DISTANCE := 30.0
const CAMERA_SIZE := 13.0
const WILD_COUNT := 8
const ENCOUNTER_DISTANCE := 0.9
const ENCOUNTER_GRACE := 2.0
const FIELD_XP := 3
## Hasta cuántos bloques por encima de los pies se puede alcanzar.
const REACH_UP := 2
const NO_CELL := Vector3i(-1, -1, -1)
## Distancia máxima (en bloques) a la que se puede elegir un bloque con el mouse.
const MOUSE_REACH := 3.5
## Cada cuántos segundos se guarda la partida sola.
const AUTOSAVE_SECONDS := 60.0

var _viewport: SubViewport
var _world3d: Node3D
var _grid: GridMap
var _gen: WorldGen
var _trainer: Trainer
var _follower: Node3D
var _follower_data: CreatureData
var _camera: Camera3D
var _camera_pos := Vector3.ZERO
var _highlight: MeshInstance3D
var _highlight_material: StandardMaterial3D
var _hud: Dictionary = {}
var _message_time := 0.0
var _encounter_grace := ENCOUNTER_GRACE
var _material_index := 0
var _autosave_timer := AUTOSAVE_SECONDS
var _pause_panel: PanelContainer
var _pause_label: Label
var _confirm_new_game := false


func _ready() -> void:
	# Esta escena sigue atendiendo el menú de pausa; el mundo 3D sí se detiene.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_viewport = PixelLook.make_pixel_viewport(self, PIXEL_SHRINK)
	_viewport.process_mode = Node.PROCESS_MODE_PAUSABLE
	_world3d = Node3D.new()
	_world3d.name = "World3D"
	_viewport.add_child(_world3d)
	PixelLook.add_daylight(_world3d, Color(0.5, 0.75, 0.95))
	_gen = WorldGen.new(GameState.world_seed)
	_build_grid()
	_spawn_trainer()
	_spawn_wild()
	_build_camera()
	_build_highlight()
	_build_hud()
	_refresh_follower()
	if GameState.loaded_from_save:
		_show_message("Partida cargada (%s jugados). %s para pausa y guardar." % [GameState.play_time_text(), InputDevice.prompt("pause")])
		GameState.loaded_from_save = false
	else:
		_show_message("Bienvenido a Tameworld. Tus criaturas pueden cambiar el mundo: prueba %s y %s." % [InputDevice.prompt("field_1"), InputDevice.prompt("field_2")])
	_save()


func _process(delta: float) -> void:
	if get_tree().paused:
		_handle_pause_menu()
		return
	if Input.is_action_just_pressed("pause"):
		_open_pause_menu()
		return
	GameState.world_player_pos = _trainer.global_position
	_autosave_timer -= delta
	if _autosave_timer <= 0.0:
		_save()
	_encounter_grace -= delta
	var active := GameState.active_creature()
	_trainer.can_swim = active.can_swim
	_trainer.in_water = _grid.get_cell_item(_cell_of(_trainer.global_position + Vector3.UP * 0.5)) == Blocks.Id.WATER
	if _trainer.global_position.y < -5.0:
		_trainer.global_position = _spawn_point()
	_handle_actions()
	_update_follower(delta)
	_update_highlight()
	_check_encounters()
	_camera_pos = _camera_pos.lerp(_camera_target(), clampf(6.0 * delta, 0.0, 1.0))
	PixelLook.snap_camera(_camera, _camera_pos, _viewport)
	_update_hud(delta)


## Altura del suelo (primer bloque sólido desde arriba) en una columna.
func ground_y(x: int, z: int) -> float:
	for y in range(WorldGen.MAX_HEIGHT + 6, -1, -1):
		if Blocks.is_solid(_grid.get_cell_item(Vector3i(x, y, z))):
			return y + 1.0
	return 0.0


# --- Construcción del mundo -------------------------------------------------

func _build_grid() -> void:
	_grid = GridMap.new()
	_grid.mesh_library = _make_library()
	_grid.cell_size = Vector3.ONE
	_world3d.add_child(_grid)
	var cells := _gen.generate()
	for cell: Vector3i in cells:
		_grid.set_cell_item(cell, cells[cell])
	for cell: Vector3i in GameState.world_edits:
		_grid.set_cell_item(cell, GameState.world_edits[cell])


func _make_library() -> MeshLibrary:
	var library := MeshLibrary.new()
	for id: int in Blocks.INFO:
		library.create_item(id)
		library.set_item_name(id, Blocks.name_of(id))
		var color := Blocks.color_of(id)
		var box := BoxMesh.new()
		if id == Blocks.Id.WATER:
			box.size = Vector3(1.0, 0.9, 1.0)
			box.material = PixelLook.unshaded(Color(color.r, color.g, color.b, 0.55))
			library.set_item_mesh_transform(id, Transform3D(Basis.IDENTITY, Vector3(0.0, -0.05, 0.0)))
		else:
			box.size = Vector3.ONE
			var material := PixelLook.toon(Color.WHITE)
			material.albedo_texture = PixelLook.checker_texture(color, color.darkened(0.08))
			box.material = material
			var shape := BoxShape3D.new()
			shape.size = Vector3.ONE
			library.set_item_shapes(id, [shape, Transform3D.IDENTITY])
		library.set_item_mesh(id, box)
	return library


func _spawn_point() -> Vector3:
	var center := int(WorldGen.SIZE / 2.0)
	return Vector3(center + 0.5, ground_y(center, center) + 0.2, center + 0.5)


func _spawn_trainer() -> void:
	_trainer = Trainer.new()
	_trainer.bounds = WorldGen.SIZE
	_world3d.add_child(_trainer)
	if GameState.world_player_pos is Vector3:
		_trainer.global_position = GameState.world_player_pos
	else:
		_trainer.global_position = _spawn_point()


## Coloca criaturas salvajes según su bioma; son de más nivel lejos del centro.
func _spawn_wild() -> void:
	var species := GameState.wild_species()
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var placed := 0
	var attempts := 0
	while placed < WILD_COUNT and attempts < 2000:
		attempts += 1
		var x := rng.randi_range(1, WorldGen.SIZE - 2)
		var z := rng.randi_range(1, WorldGen.SIZE - 2)
		var biome := _gen.biome_at(x, z)
		var candidates: Array[CreatureData] = []
		for candidate: CreatureData in species:
			if candidate.habitat_biomes.has(biome):
				candidates.append(candidate)
		if candidates.is_empty():
			continue
		var at := Vector3(x + 0.5, ground_y(x, z), z + 0.5)
		if at.distance_to(_trainer.global_position) < 6.0:
			continue
		var pick: CreatureData = candidates[rng.randi_range(0, candidates.size() - 1)]
		var data := pick.duplicate() as CreatureData
		data.set_level(_level_for(x, z))
		var wild := WildCreature.new()
		wild.data = data
		wild.world = self
		_world3d.add_child(wild)
		wild.global_position = at
		placed += 1


func _level_for(x: int, z: int) -> int:
	var half := WorldGen.SIZE / 2.0
	return 1 + int(Vector2(x - half, z - half).length() / 6.0)


func _build_camera() -> void:
	_camera = Camera3D.new()
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.size = CAMERA_SIZE
	_camera.rotation_degrees = Vector3(-CAMERA_PITCH_DEG, 0.0, 0.0)
	_camera.far = 200.0
	_world3d.add_child(_camera)
	_camera.current = true
	_camera_pos = _camera_target()


func _camera_target() -> Vector3:
	var pitch := deg_to_rad(CAMERA_PITCH_DEG)
	return _trainer.global_position + Vector3(0.0, sin(pitch), cos(pitch)) * CAMERA_DISTANCE


func _build_highlight() -> void:
	var box := BoxMesh.new()
	box.size = Vector3.ONE * 1.06
	_highlight_material = PixelLook.unshaded(Color(1.0, 1.0, 1.0, 0.25))
	_highlight = MeshInstance3D.new()
	_highlight.mesh = box
	_highlight.material_override = _highlight_material
	_highlight.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_world3d.add_child(_highlight)


# --- Acompañante ------------------------------------------------------------

func _refresh_follower() -> void:
	var active := GameState.active_creature()
	if active == _follower_data and is_instance_valid(_follower):
		return
	if is_instance_valid(_follower):
		_follower.queue_free()
	_follower_data = active
	_follower = CreatureLook.build(active)
	_world3d.add_child(_follower)
	_follower.global_position = _trainer.global_position - _trainer.facing * 1.5


func _update_follower(delta: float) -> void:
	var behind := _trainer.global_position - _trainer.facing * 1.5
	var target := Vector3(behind.x, ground_y(floori(behind.x), floori(behind.z)), behind.z)
	var to := target - _follower.global_position
	_follower.global_position = _follower.global_position.lerp(target, clampf(4.0 * delta, 0.0, 1.0))
	if Vector2(to.x, to.z).length() > 0.1:
		_follower.rotation.y = atan2(-to.x, -to.z)


# --- Acciones del jugador ---------------------------------------------------

func _handle_actions() -> void:
	if Input.is_action_just_pressed("next_creature"):
		GameState.cycle_active()
		_refresh_follower()
		_show_message("Ahora te acompaña %s." % GameState.active_creature().display_name())
	if Input.is_action_just_pressed("field_1"):
		_use_field_ability(0)
	elif Input.is_action_just_pressed("field_2"):
		_use_field_ability(1)
	if Input.is_action_just_pressed("next_material"):
		_material_index = (_material_index + 1) % Blocks.MATERIAL_ORDER.size()
	if Input.is_action_just_pressed("place_block"):
		_place_block()


func _cell_of(point: Vector3) -> Vector3i:
	return Vector3i(floori(point.x), floori(point.y), floori(point.z))


func _front_column() -> Vector2i:
	var point := _trainer.global_position + _trainer.facing * 1.1
	return Vector2i(floori(point.x), floori(point.z))


func _in_bounds(column: Vector2i) -> bool:
	return column.x >= 0 and column.y >= 0 and column.x < WorldGen.SIZE and column.y < WorldGen.SIZE


## Con mouse: el bloque bajo el cursor si está al alcance. Devuelve {} si no hay.
## "cell" es el bloque apuntado y "place" la celda vacía junto a la cara apuntada.
func _mouse_hit() -> Dictionary:
	if not InputDevice.using_mouse():
		return {}
	var mouse := get_viewport().get_mouse_position() / float(PIXEL_SHRINK)
	var origin := _camera.project_ray_origin(mouse)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + _camera.project_ray_normal(mouse) * 300.0)
	query.exclude = [_trainer.get_rid()]
	var hit := _world3d.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return {}
	var point: Vector3 = hit["position"]
	var normal: Vector3 = hit["normal"]
	var cell := _cell_of(point - normal * 0.5)
	if not _within_reach(cell):
		return {}
	return {"cell": cell, "place": _cell_of(point + normal * 0.5)}


func _within_reach(cell: Vector3i) -> bool:
	var feet := floori(_trainer.global_position.y + 0.05)
	var flat := Vector2(cell.x + 0.5 - _trainer.global_position.x, cell.z + 0.5 - _trainer.global_position.z)
	return flat.length() <= MOUSE_REACH and cell.y <= feet + REACH_UP and cell.y >= feet - 3


## El bloque elegido: el del cursor (mouse) o el más alto delante del jugador (mando).
func _target_cell() -> Vector3i:
	var hit := _mouse_hit()
	if not hit.is_empty():
		return hit["cell"]
	var column := _front_column()
	if not _in_bounds(column):
		return NO_CELL
	var feet := floori(_trainer.global_position.y + 0.05)
	for y in range(feet + REACH_UP, -1, -1):
		var item := _grid.get_cell_item(Vector3i(column.x, y, column.y))
		if item != GridMap.INVALID_CELL_ITEM and item != Blocks.Id.WATER:
			return Vector3i(column.x, y, column.y)
	return NO_CELL


func _set_block(cell: Vector3i, block: int) -> void:
	_grid.set_cell_item(cell, block)
	GameState.world_edits[cell] = block


func _use_field_ability(slot: int) -> void:
	var data := GameState.active_creature()
	if slot >= data.field_ability_ids.size():
		_show_message("%s no tiene habilidad de campo en %s." % [data.display_name(), InputDevice.prompt("field_2" if slot == 1 else "field_1")])
		return
	var ability_id := data.field_ability_ids[slot]
	var ability_name := FieldAbilities.name_of(ability_id)
	var cell := _target_cell()
	if cell == NO_CELL:
		_show_message("No hay nada delante.")
		return
	var block := _grid.get_cell_item(cell)
	var result := FieldAbilities.resolve(ability_id, block, data.level)
	match String(result["action"]):
		"break":
			if cell.y == 0:
				_show_message("La roca del fondo del mundo no se puede romper.")
				return
			_set_block(cell, Blocks.EMPTY)
			var resource: String = result["resource"]
			if resource.is_empty():
				_show_message("%s: %s eliminado." % [ability_name, Blocks.name_of(block)])
			else:
				GameState.add_item(resource)
				_show_message("%s: +1 %s" % [ability_name, resource])
		"transform":
			var new_block: int = result["to"]
			_set_block(cell, new_block)
			_show_message("%s: %s se convirtió en %s." % [ability_name, Blocks.name_of(block), Blocks.name_of(new_block)])
		"plant":
			var tree := WorldGen.tree_cells(cell.x, cell.y + 1, cell.z)
			for tree_cell: Vector3i in tree:
				if _grid.get_cell_item(tree_cell) == GridMap.INVALID_CELL_ITEM:
					_set_block(tree_cell, tree[tree_cell])
			_show_message("¡%s plantó un árbol!" % data.display_name())
		"locked":
			_show_message("%s necesita nivel %d para usar %s sobre %s." % [data.display_name(), int(result["needs_level"]), ability_name, Blocks.name_of(block)])
			return
		_:
			_show_message("%s no sirve sobre %s." % [ability_name, Blocks.name_of(block)])
			return
	if data.gain_xp(FIELD_XP) > 0:
		_show_message("¡%s subió a nivel %d trabajando!" % [data.display_name(), data.level])


func _place_block() -> void:
	var material: String = Blocks.MATERIAL_ORDER[_material_index]
	if GameState.item_count(material) <= 0:
		_show_message("No tienes %s. Consíguela con las habilidades de tus criaturas." % material)
		return
	var own := _cell_of(_trainer.global_position)
	var cell := _place_cell(own)
	if cell == NO_CELL or cell == own or cell == own + Vector3i.UP:
		return
	if cell.y > own.y + REACH_UP:
		_show_message("Demasiado alto.")
		return
	var existing := _grid.get_cell_item(cell)
	if existing != GridMap.INVALID_CELL_ITEM and existing != Blocks.Id.WATER:
		return
	GameState.take_item(material)
	_set_block(cell, Blocks.PLACEABLE[material])


## Celda donde se colocaría un bloque: junto a la cara apuntada con el mouse,
## o encima del bloque más alto delante del jugador.
func _place_cell(own: Vector3i) -> Vector3i:
	var hit := _mouse_hit()
	if not hit.is_empty():
		var place: Vector3i = hit["place"]
		var inside := place.x >= 0 and place.z >= 0 and place.x < WorldGen.SIZE and place.z < WorldGen.SIZE and place.y >= 0
		return place if inside else NO_CELL
	var column := _front_column()
	if not _in_bounds(column) or column == Vector2i(own.x, own.z):
		return NO_CELL
	var top := _target_cell()
	return Vector3i(column.x, 0 if top == NO_CELL else top.y + 1, column.y)


func _update_highlight() -> void:
	var cell := _target_cell()
	_highlight.visible = cell != NO_CELL
	if not _highlight.visible:
		return
	_highlight.global_position = Vector3(cell) + Vector3(0.5, 0.5, 0.5)
	var block := _grid.get_cell_item(cell)
	var data := GameState.active_creature()
	var color := Color(1.0, 1.0, 1.0, 0.2)
	for ability_id in data.field_ability_ids:
		var action := String(FieldAbilities.resolve(ability_id, block, data.level)["action"])
		if action == "locked":
			color = Color(1.0, 0.6, 0.2, 0.35)
		elif action != "none":
			color = Color(0.4, 1.0, 0.4, 0.35)
			break
	_highlight_material.albedo_color = color


## Tocar una criatura salvaje inicia la pelea en la arena; al terminar se vuelve aquí.
func _check_encounters() -> void:
	if _encounter_grace > 0.0:
		return
	for node in get_tree().get_nodes_in_group("wild"):
		var wild := node as WildCreature
		var to := wild.global_position - _trainer.global_position
		if Vector2(to.x, to.z).length() < ENCOUNTER_DISTANCE + wild.radius() and absf(to.y) < 1.5:
			GameState.pending_wild = wild.data
			GameState.from_world = true
			GameState.world_player_pos = _trainer.global_position - _trainer.facing * 1.5
			set_process(false)
			get_tree().change_scene_to_file.call_deferred(GameState.COMBAT_SCENE)
			return


# --- Guardado y pausa --------------------------------------------------------

func _save() -> void:
	_autosave_timer = AUTOSAVE_SECONDS
	GameState.world_player_pos = _trainer.global_position
	if not GameState.save_game():
		_show_message("No se pudo guardar la partida.")


func _open_pause_menu() -> void:
	get_tree().paused = true
	_confirm_new_game = false
	_pause_panel.visible = true
	_refresh_pause_text()


func _close_pause_menu() -> void:
	get_tree().paused = false
	_pause_panel.visible = false


func _handle_pause_menu() -> void:
	_refresh_pause_text()
	if Input.is_action_just_pressed("pause"):
		_close_pause_menu()
	elif Input.is_action_just_pressed("save_game"):
		_save()
		_close_pause_menu()
		_show_message("Partida guardada.")
	elif Input.is_action_just_pressed("new_game"):
		if not _confirm_new_game:
			_confirm_new_game = true
			_refresh_pause_text()
			return
		GameState.new_game()
		get_tree().paused = false
		get_tree().reload_current_scene()
	elif Input.is_action_just_pressed("quit_game"):
		_save()
		get_tree().quit()


func _refresh_pause_text() -> void:
	var lines: PackedStringArray = [
		"PAUSA",
		"",
		"Tiempo jugado: %s" % GameState.play_time_text(),
		"Equipo: %d criaturas · Semilla del mundo: %d" % [GameState.roster.size(), GameState.world_seed],
		"",
		"Control: %s" % InputDevice.family_name(),
		"",
		"%s: seguir jugando" % InputDevice.prompt("pause"),
		"%s: guardar ahora" % InputDevice.prompt("save_game"),
		"%s: guardar y salir del juego" % InputDevice.prompt("quit_game"),
	]
	if _confirm_new_game:
		lines.append("%s otra vez: CONFIRMAR partida nueva (se borra la actual)" % InputDevice.prompt("new_game"))
	else:
		lines.append("%s: partida nueva" % InputDevice.prompt("new_game"))
	lines.append("")
	lines.append("También se guarda sola cada minuto, al volver de una pelea y al cerrar la ventana.")
	_pause_label.text = "\n".join(lines)


# --- Interfaz ---------------------------------------------------------------

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var panel := VBoxContainer.new()
	panel.size = Vector2(560.0, 140.0)
	root.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT, Control.PRESET_MODE_KEEP_SIZE, 16)
	for key: String in ["creature", "abilities", "inventory"]:
		var label := _make_label(20 if key == "creature" else 15)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size = Vector2(560.0, 0.0)
		panel.add_child(label)
		_hud[key] = label

	var place := _make_label(18)
	place.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(place)
	place.size = Vector2(420.0, 60.0)
	place.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_KEEP_SIZE, 16)
	_hud["place"] = place

	var help := _make_label(14)
	root.add_child(help)
	_hud["help"] = help
	help.size = Vector2(1240.0, 24.0)
	help.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_KEEP_SIZE, 16)

	var message := _make_label(22)
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(message)
	message.size = Vector2(1000.0, 40.0)
	message.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_KEEP_SIZE, 70)
	_hud["message"] = message

	_pause_panel = PanelContainer.new()
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.05, 0.07, 0.1, 0.88)
	background.set_content_margin_all(28.0)
	background.set_corner_radius_all(6)
	_pause_panel.add_theme_stylebox_override("panel", background)
	_pause_label = _make_label(20)
	_pause_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pause_panel.add_child(_pause_label)
	root.add_child(_pause_panel)
	_pause_panel.size = Vector2(760.0, 420.0)
	_pause_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_KEEP_SIZE)
	_pause_panel.visible = false


func _make_label(font_size: int) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_constant_override("outline_size", 6)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	return label


## Ayuda con los nombres de teclas o botones del control que se está usando.
func _help_text() -> String:
	var parts: PackedStringArray = [
		"%s mover" % InputDevice.move_prompt(),
		"%s saltar o nadar" % InputDevice.prompt("jump"),
		"%s / %s habilidad de campo" % [InputDevice.prompt("field_1"), InputDevice.prompt("field_2")],
		"%s colocar bloque" % InputDevice.prompt("place_block"),
		"%s cambiar material" % InputDevice.prompt("next_material"),
		"%s cambiar criatura" % InputDevice.prompt("next_creature"),
		"%s pausa" % InputDevice.prompt("pause"),
	]
	if InputDevice.using_mouse():
		parts.append("el mouse elige el bloque")
	parts.append("toca una criatura salvaje para pelear")
	return " · ".join(parts)


func _update_hud(delta: float) -> void:
	(_hud["help"] as Label).text = _help_text()
	var data := GameState.active_creature()
	(_hud["creature"] as Label).text = "%s  Nv. %d  (XP %d/%d)  ·  Equipo: %d" % [data.display_name(), data.level, data.xp, data.xp_to_next(), GameState.roster.size()]
	var lines: PackedStringArray = []
	var keys := [InputDevice.prompt("field_1"), InputDevice.prompt("field_2")]
	for i in mini(keys.size(), data.field_ability_ids.size()):
		var id := data.field_ability_ids[i]
		lines.append("%s: %s → %s" % [keys[i], FieldAbilities.name_of(id), FieldAbilities.targets_text(id)])
	if lines.is_empty():
		lines.append("Sin habilidades de campo")
	(_hud["abilities"] as Label).text = "\n".join(lines)

	var items: PackedStringArray = []
	for item: String in ["madera", "piedra", "tierra", "arena", "cristal", "carbón", "nieve"]:
		var text := "%s %d" % [item.capitalize(), GameState.item_count(item)]
		if item == Blocks.MATERIAL_ORDER[_material_index]:
			text = "[%s]" % text
		items.append(text)
	(_hud["inventory"] as Label).text = "Inventario (%s coloca lo marcado): %s" % [InputDevice.prompt("place_block"), " · ".join(items)]

	var column := _cell_of(_trainer.global_position)
	var biome := _gen.biome_at(clampi(column.x, 0, WorldGen.SIZE - 1), clampi(column.z, 0, WorldGen.SIZE - 1))
	var water_text := ""
	if _trainer.in_water:
		water_text = "\nNadando" if _trainer.can_swim else "\nEn el agua: lento (tu criatura no nada)"
	(_hud["place"] as Label).text = "%s · semilla %d%s\n%s" % [WorldGen.biome_name(biome), GameState.world_seed, water_text, InputDevice.family_name()]

	_message_time = maxf(0.0, _message_time - delta)
	(_hud["message"] as Label).modulate.a = clampf(_message_time, 0.0, 1.0)


func _show_message(text: String) -> void:
	(_hud["message"] as Label).text = text
	_message_time = 3.5
