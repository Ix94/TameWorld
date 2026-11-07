extends Node
## Arena de prueba del combate 1 contra 1 (etapa 1 del plan).
## Construye todo por código: mundo 3D en baja resolución (look pixel art),
## cámara inclinada, criaturas, IA, captura e interfaz.

const PIXEL_SHRINK := 3
const ARENA_RADIUS := 11.0
const CAMERA_PITCH_DEG := 40.0
const CAMERA_DISTANCE := 30.0
const CAMERA_SIZE := 15.0
const HELP_TEXT := "WASD mover · Espacio esquivar · J golpe · K golpe fuerte · U / I habilidades · C capturar · Tab cambiar criatura · R nueva pelea"

var _viewport: SubViewport
var _world: Node3D
var _camera: Camera3D
var _camera_pos := Vector3.ZERO
var _player: Creature
var _enemy: Creature
var _player_ctrl: PlayerController
var _enemy_ai: AIController
var _capturing := false
var _fight_over := false
var _hud: Dictionary = {}
var _message_time := 0.0


func _ready() -> void:
	_build_viewport()
	_build_world()
	_build_hud()
	_start_fight()


func _process(delta: float) -> void:
	if not _capturing:
		if Input.is_action_just_pressed("restart"):
			_start_fight()
		elif Input.is_action_just_pressed("next_creature"):
			GameState.cycle_active()
			_start_fight()
		elif Input.is_action_just_pressed("capture"):
			_try_capture()
	_update_camera(delta)
	_update_hud(delta)


# --- Pelea -----------------------------------------------------------------

func _start_fight() -> void:
	for node in [_player, _enemy, _player_ctrl, _enemy_ai]:
		if is_instance_valid(node):
			node.queue_free()
	_fight_over = false
	_capturing = false

	_player = _spawn(GameState.active_creature(), 0, Vector3(0.0, 0.0, 4.0))
	_enemy = _spawn(GameState.random_wild(_player.data.species_name), 1, Vector3(0.0, 0.0, -4.0))
	_player.target = _enemy
	_enemy.target = _player
	_enemy.windup_scale = 1.6

	_player_ctrl = PlayerController.new()
	_player_ctrl.me = _player
	add_child(_player_ctrl)
	_enemy_ai = AIController.new()
	_enemy_ai.me = _enemy
	_enemy_ai.foe = _player
	add_child(_enemy_ai)

	_player.died.connect(_on_player_died)
	_enemy.died.connect(_on_enemy_died)
	_player.message.connect(_show_message)
	_enemy.message.connect(_show_message)
	_camera_pos = _camera_target()
	_show_message("¡Un %s salvaje apareció!" % _enemy.data.display_name())


func _spawn(data: CreatureData, team: int, at: Vector3) -> Creature:
	var creature := Creature.new()
	creature.setup(data, team)
	creature.arena_radius = ARENA_RADIUS
	_world.add_child(creature)
	creature.global_position = at
	creature.look_along(-at)
	return creature


func _on_player_died(_creature: Creature) -> void:
	_fight_over = true
	_show_message("Tu criatura se debilitó. R para reintentar.")


func _on_enemy_died(_creature: Creature) -> void:
	_fight_over = true
	GameState.capture_orbs += 1
	_show_message("¡Ganaste! +1 cristal de captura. R para otra criatura salvaje.")


func _try_capture() -> void:
	if _fight_over or not is_instance_valid(_enemy) or not is_instance_valid(_player) or _player.is_dead():
		return
	if GameState.capture_orbs <= 0:
		_show_message("No te quedan cristales de captura.")
		return
	GameState.capture_orbs -= 1
	_capturing = true
	var wild := _enemy
	var chance := CombatRules.capture_chance(wild.data.catch_rate, wild.hp_ratio(), wild.is_stunned())
	var success := randf() < chance

	var orb_mesh := SphereMesh.new()
	orb_mesh.radius = 0.25
	orb_mesh.height = 0.5
	orb_mesh.radial_segments = 6
	orb_mesh.rings = 3
	var orb := MeshInstance3D.new()
	orb.mesh = orb_mesh
	orb.material_override = PixelLook.unshaded(Color(0.4, 0.95, 1.0))
	_world.add_child(orb)
	orb.global_position = _player.global_position + Vector3.UP * (_player.data.height_m + 0.3)
	var hit_point := wild.global_position + Vector3.UP * wild.data.height_m * 0.5

	var tween := create_tween()
	tween.tween_property(orb, "global_position", hit_point, 0.4)
	await tween.finished
	if wild != _enemy or wild.is_dead():
		orb.queue_free()
		_capturing = false
		return

	# La criatura queda dentro del cristal mientras se decide la captura.
	wild.visible = false
	wild.process_mode = Node.PROCESS_MODE_DISABLED
	_enemy_ai.process_mode = Node.PROCESS_MODE_DISABLED
	tween = create_tween()
	tween.tween_property(orb, "global_position", Vector3(hit_point.x, 0.25, hit_point.z), 0.25)
	await tween.finished
	var shakes := 3 if success else randi_range(0, 2)
	for i in shakes:
		tween = create_tween()
		tween.tween_property(orb, "rotation:z", 0.5, 0.1)
		tween.tween_property(orb, "rotation:z", -0.5, 0.2)
		tween.tween_property(orb, "rotation:z", 0.0, 0.1)
		tween.tween_interval(0.35)
		await tween.finished
	orb.queue_free()
	_capturing = false

	if success:
		GameState.add_to_roster(wild.data)
		wild.queue_free()
		_enemy = null
		_fight_over = true
		_show_message("¡Capturaste a %s! Ya tienes %d criaturas. Tab para usarla, R para otra pelea." % [wild.data.display_name(), GameState.roster.size()])
	else:
		wild.visible = true
		wild.process_mode = Node.PROCESS_MODE_INHERIT
		_enemy_ai.process_mode = Node.PROCESS_MODE_INHERIT
		_enemy_ai.aggression = 1.3
		_show_message("¡%s se escapó! (probabilidad: %d%%)" % [wild.data.display_name(), roundi(chance * 100.0)])


# --- Mundo -----------------------------------------------------------------

## El mundo 3D se dibuja en un viewport 3 veces más pequeño que la ventana
## y se agranda sin suavizado: así se consigue el look pixel art.
func _build_viewport() -> void:
	var container := SubViewportContainer.new()
	container.stretch = true
	container.stretch_shrink = PIXEL_SHRINK
	container.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(container)
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_viewport = SubViewport.new()
	_viewport.msaa_3d = Viewport.MSAA_DISABLED
	_viewport.audio_listener_enable_3d = true
	container.add_child(_viewport)
	_world = Node3D.new()
	_world.name = "World"
	_viewport.add_child(_world)


func _build_world() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.45, 0.7, 0.95)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.75, 0.8, 0.9)
	environment.ambient_light_energy = 0.6
	var world_env := WorldEnvironment.new()
	world_env.environment = environment
	_world.add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55.0, 35.0, 0.0)
	sun.shadow_enabled = true
	sun.light_energy = 1.1
	_world.add_child(sun)

	var ground := StaticBody3D.new()
	_world.add_child(ground)
	var ground_shape := BoxShape3D.new()
	ground_shape.size = Vector3(80.0, 1.0, 80.0)
	var ground_collision := CollisionShape3D.new()
	ground_collision.shape = ground_shape
	ground_collision.position.y = -0.5
	ground.add_child(ground_collision)
	var plane := PlaneMesh.new()
	plane.size = Vector2(80.0, 80.0)
	var ground_material := PixelLook.toon(Color.WHITE)
	ground_material.albedo_texture = PixelLook.checker_texture(Color(0.36, 0.62, 0.3), Color(0.31, 0.55, 0.27))
	ground_material.uv1_scale = Vector3(20.0, 20.0, 1.0)
	var ground_mesh := MeshInstance3D.new()
	ground_mesh.mesh = plane
	ground_mesh.material_override = ground_material
	ground.add_child(ground_mesh)

	# Borde de la arena: un anillo de piedras.
	var stone_mesh := CylinderMesh.new()
	stone_mesh.top_radius = 0.35
	stone_mesh.bottom_radius = 0.5
	stone_mesh.height = 0.5
	stone_mesh.radial_segments = 5
	var stone_material := PixelLook.toon(Color(0.55, 0.55, 0.6))
	for i in 28:
		var angle := TAU * i / 28.0
		var stone := MeshInstance3D.new()
		stone.mesh = stone_mesh
		stone.material_override = stone_material
		stone.position = Vector3(cos(angle), 0.0, sin(angle)) * (ARENA_RADIUS + 0.6) + Vector3.UP * 0.25
		_world.add_child(stone)

	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 40:
		var angle := rng.randf() * TAU
		var distance := rng.randf_range(ARENA_RADIUS + 3.0, 30.0)
		_world.add_child(_make_tree(Vector3(cos(angle), 0.0, sin(angle)) * distance, rng.randf_range(0.8, 1.5)))

	_camera = Camera3D.new()
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.size = CAMERA_SIZE
	_camera.rotation_degrees = Vector3(-CAMERA_PITCH_DEG, 0.0, 0.0)
	_camera.far = 200.0
	_world.add_child(_camera)
	_camera.current = true


func _make_tree(at: Vector3, tree_scale: float) -> Node3D:
	var tree := Node3D.new()
	tree.position = at
	tree.scale = Vector3.ONE * tree_scale
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.15
	trunk_mesh.bottom_radius = 0.2
	trunk_mesh.height = 1.0
	trunk_mesh.radial_segments = 5
	var trunk := MeshInstance3D.new()
	trunk.mesh = trunk_mesh
	trunk.material_override = PixelLook.toon(Color(0.45, 0.3, 0.18))
	trunk.position.y = 0.5
	tree.add_child(trunk)
	var leaves_mesh := CylinderMesh.new()
	leaves_mesh.top_radius = 0.0
	leaves_mesh.bottom_radius = 0.9
	leaves_mesh.height = 1.8
	leaves_mesh.radial_segments = 6
	var leaves := MeshInstance3D.new()
	leaves.mesh = leaves_mesh
	leaves.material_override = PixelLook.toon(Color(0.2, 0.45, 0.22))
	leaves.position.y = 1.7
	tree.add_child(leaves)
	return tree


func _camera_target() -> Vector3:
	var focus := Vector3.ZERO
	if is_instance_valid(_player):
		focus = _player.global_position
	if is_instance_valid(_enemy) and _enemy.visible:
		focus = focus.lerp(_enemy.global_position, 0.35)
	var pitch := deg_to_rad(CAMERA_PITCH_DEG)
	return focus + Vector3(0.0, sin(pitch), cos(pitch)) * CAMERA_DISTANCE


func _update_camera(delta: float) -> void:
	_camera_pos = _camera_pos.lerp(_camera_target(), clampf(6.0 * delta, 0.0, 1.0))
	# Ajusta la cámara a la rejilla de píxeles para que la imagen no "tiemble".
	var texel := CAMERA_SIZE / maxf(1.0, float(_viewport.size.y))
	var cam_basis := _camera.global_transform.basis
	var local := (cam_basis.inverse() * _camera_pos).snapped(Vector3(texel, texel, texel))
	_camera.global_position = cam_basis * local


# --- Interfaz --------------------------------------------------------------

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_hud["player"] = _make_panel(root, Control.PRESET_TOP_LEFT)
	_hud["enemy"] = _make_panel(root, Control.PRESET_TOP_RIGHT)

	var status := _make_label(18)
	root.add_child(status)
	status.size = Vector2(500.0, 30.0)
	status.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_KEEP_SIZE, 16)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hud["status"] = status

	var help := _make_label(14)
	help.text = HELP_TEXT
	root.add_child(help)
	help.size = Vector2(1000.0, 24.0)
	help.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_KEEP_SIZE, 16)
	_hud["help"] = help

	var msg := _make_label(22)
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(msg)
	msg.size = Vector2(900.0, 40.0)
	msg.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_KEEP_SIZE, 70)
	_hud["message"] = msg


func _make_panel(parent: Control, preset: Control.LayoutPreset) -> Dictionary:
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(320.0, 0.0)
	box.size = Vector2(320.0, 120.0)
	parent.add_child(box)
	box.set_anchors_and_offsets_preset(preset, Control.PRESET_MODE_KEEP_SIZE, 16)
	var title := _make_label(20)
	var hp_bar := _make_bar(Color(0.35, 0.85, 0.4))
	var energy_bar := _make_bar(Color(0.95, 0.8, 0.25))
	var info := _make_label(14)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for node: Control in [title, hp_bar, energy_bar, info]:
		box.add_child(node)
	return {"box": box, "title": title, "hp": hp_bar, "energy": energy_bar, "info": info}


func _make_label(font_size: int) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_constant_override("outline_size", 6)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	return label


func _make_bar(color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(320.0, 12.0)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.0, 0.0, 0.0, 0.6)
	bar.add_theme_stylebox_override("fill", fill)
	bar.add_theme_stylebox_override("background", background)
	return bar


func _update_hud(delta: float) -> void:
	_fill_panel(_hud["player"], _player, true)
	_fill_panel(_hud["enemy"], _enemy, false)
	(_hud["status"] as Label).text = "Cristales: %d · Equipo: %d criaturas" % [GameState.capture_orbs, GameState.roster.size()]
	_message_time = maxf(0.0, _message_time - delta)
	(_hud["message"] as Label).modulate.a = clampf(_message_time, 0.0, 1.0)


func _fill_panel(panel: Dictionary, creature: Creature, is_player: bool) -> void:
	var box := panel["box"] as Control
	box.visible = is_instance_valid(creature)
	if not box.visible:
		return
	var data := creature.data
	(panel["title"] as Label).text = "%s%s  [%s]" % ["" if is_player else "Salvaje: ", data.display_name(), Elements.name_of(data.element)]
	var hp_bar := panel["hp"] as ProgressBar
	hp_bar.max_value = data.max_hp
	hp_bar.value = creature.hp
	var energy_bar := panel["energy"] as ProgressBar
	energy_bar.max_value = data.max_energy
	energy_bar.value = creature.energy
	var info := panel["info"] as Label
	if is_player:
		info.text = "%s\n%s" % [_abilities_text(creature), _mount_text(data)]
	elif creature.is_dead():
		info.text = "Debilitada: ya no se puede capturar."
	else:
		var chance := CombatRules.capture_chance(data.catch_rate, creature.hp_ratio(), creature.is_stunned())
		info.text = "Captura (C): %d%%" % roundi(chance * 100.0)


func _abilities_text(creature: Creature) -> String:
	var keys := ["U", "I"]
	var parts: PackedStringArray = []
	for i in mini(keys.size(), creature.data.ability_ids.size()):
		var ability := AbilityLibrary.find(creature.data.ability_ids[i])
		var left := creature.cooldown_left(i)
		var ready_text := "listo" if left <= 0.0 else "%.1f s" % left
		parts.append("%s: %s (%s)" % [keys[i], ability.get("name", "?"), ready_text])
	return " · ".join(parts)


## Muestra las reglas de montura en acción para la criatura activa.
func _mount_text(data: CreatureData) -> String:
	var modes := {
		"tierra": CreatureData.MountMode.GROUND,
		"nado": CreatureData.MountMode.SWIM,
		"vuelo": CreatureData.MountMode.FLY,
	}
	var parts: PackedStringArray = []
	for label: String in modes:
		var mode: CreatureData.MountMode = modes[label]
		var ok := data.can_be_mounted(GameState.RIDER_HEIGHT_M, GameState.RIDER_LOAD_KG, mode)
		parts.append("%s %s" % [label, "sí" if ok else "no"])
	return "Montura (%.1f m, %d kg): %s" % [data.height_m, roundi(data.weight_kg), ", ".join(parts)]


func _show_message(text: String) -> void:
	(_hud["message"] as Label).text = text
	_message_time = 3.0
