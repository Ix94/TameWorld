class_name Creature
extends CharacterBody3D
## Criatura que pelea en tiempo real. No decide nada por sí sola:
## recibe órdenes de un PlayerController (jugador) o de un AIController (enemigo).

signal message(text: String)
signal died(creature: Creature)

enum State { FREE, WINDUP, ACTIVE, RECOVERY, DODGE, STUNNED, DEAD }

const GRAVITY := 25.0
const DODGE_SPEED := 13.0
const DODGE_TIME := 0.28
## Tiempo invulnerable al esquivar.
const IFRAME_TIME := 0.22
const DODGE_COST := 20.0
const ENERGY_REGEN := 20.0
const TURN_SPEED := 14.0
const DASH_SPEED := 17.0
## Distancia a la que la criatura se orienta sola hacia su rival al atacar.
const SOFT_LOCK_RANGE := 12.0

const LIGHT_ATTACK := {
	"kind": "melee", "windup": 0.12, "active": 0.1, "recovery": 0.2,
	"power": 0.6, "range": 1.6, "arc_deg": 110.0, "energy": 0.0, "lunge": 4.0,
}
const HEAVY_ATTACK := {
	"kind": "melee", "windup": 0.45, "active": 0.12, "recovery": 0.35,
	"power": 1.4, "range": 2.1, "arc_deg": 150.0, "energy": 12.0, "lunge": 6.0,
}

var data: CreatureData
var team := 0
var hp := 1.0
var energy := 0.0
var state: State = State.FREE
var state_time := 0.0
## Dirección deseada en el plano XZ (longitud 0 a 1).
var move_input := Vector3.ZERO
var facing := Vector3.FORWARD
## Dirección de apuntado con el mouse. Si es cero, la criatura apunta sola al rival.
var aim_direction := Vector3.ZERO
## Mayor que 1 = el ataque tarda más en salir (la IA lo usa para que se pueda esquivar).
var windup_scale := 1.0
var target: Creature
var arena_radius := 11.0

var _attack: Dictionary = {}
var _attack_element := 0
var _has_hit := false
var _stun_time := 0.0
var _iframes := 0.0
var _flash := 0.0
var _dodge_dir := Vector3.FORWARD
var _cooldowns: Dictionary = {}
var _material: StandardMaterial3D
var _visual: Node3D
var _telegraph: MeshInstance3D
var _telegraph_material: StandardMaterial3D


func setup(creature_data: CreatureData, creature_team: int) -> void:
	data = creature_data
	team = creature_team
	hp = data.max_hp
	energy = data.max_energy


func _ready() -> void:
	add_to_group("creatures")
	_build_body()
	look_along(facing)


# --- Consultas -------------------------------------------------------------

func is_dead() -> bool:
	return state == State.DEAD


func is_targetable() -> bool:
	return not is_dead() and visible and process_mode != Node.PROCESS_MODE_DISABLED


func is_stunned() -> bool:
	return state == State.STUNNED


func is_winding_up() -> bool:
	return state == State.WINDUP


func can_act() -> bool:
	return state == State.FREE


func hp_ratio() -> float:
	return hp / data.max_hp


func radius() -> float:
	return data.height_m * 0.35


func cooldown_left(index: int) -> float:
	if index < 0 or index >= data.ability_ids.size():
		return 0.0
	return float(_cooldowns.get(data.ability_ids[index], 0.0))


# --- Órdenes ---------------------------------------------------------------

func try_light() -> bool:
	return _start_attack(LIGHT_ATTACK, Elements.Type.NORMAL)


func try_heavy() -> bool:
	return _start_attack(HEAVY_ATTACK, Elements.Type.NORMAL)


func try_ability(index: int) -> bool:
	if index < 0 or index >= data.ability_ids.size():
		return false
	var id := data.ability_ids[index]
	if float(_cooldowns.get(id, 0.0)) > 0.0:
		return false
	var ability := AbilityLibrary.find(id)
	if ability.is_empty():
		return false
	if not _start_attack(AbilityLibrary.to_attack(ability), data.element):
		return false
	_cooldowns[id] = float(ability["cooldown"])
	return true


func try_dodge() -> bool:
	if state != State.FREE and state != State.RECOVERY:
		return false
	if energy < DODGE_COST:
		return false
	energy -= DODGE_COST
	var direction := Vector3(move_input.x, 0.0, move_input.z)
	if direction.length() < 0.1:
		direction = -facing
	_dodge_dir = direction.normalized()
	_iframes = IFRAME_TIME
	_enter(State.DODGE)
	return true


func take_hit(attack_stat: float, power: float, element: int, direction: Vector3) -> void:
	if not is_targetable():
		return
	if _iframes > 0.0:
		message.emit("¡%s esquivó el golpe!" % data.display_name())
		return
	var multiplier := Elements.multiplier(element, data.element)
	hp = maxf(0.0, hp - CombatRules.damage(power, attack_stat, data.defense, multiplier))
	_flash = 0.12
	if multiplier > 1.0:
		message.emit("¡Es muy eficaz!")
	elif multiplier < 1.0:
		message.emit("No es muy eficaz...")
	_show_telegraph(false)
	if hp <= 0.0:
		_die()
		return
	_stun_time = 0.12 + power * 0.18
	_enter(State.STUNNED)
	velocity.x = direction.x * 5.0 * power
	velocity.z = direction.z * 5.0 * power


func look_along(direction: Vector3) -> void:
	var flat := Vector3(direction.x, 0.0, direction.z)
	if flat.length() < 0.01:
		return
	facing = flat.normalized()
	rotation.y = atan2(-facing.x, -facing.z)


# --- Bucle -----------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if data == null:
		return
	state_time += delta
	_iframes = maxf(0.0, _iframes - delta)
	_flash = maxf(0.0, _flash - delta)
	for id: String in _cooldowns.keys():
		_cooldowns[id] = maxf(0.0, float(_cooldowns[id]) - delta)

	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	match state:
		State.FREE:
			energy = minf(data.max_energy, energy + ENERGY_REGEN * delta)
			horizontal = move_input.limit_length(1.0) * data.move_speed
			if move_input.length() > 0.1:
				_turn_towards(move_input, delta)
		State.WINDUP:
			horizontal = horizontal.move_toward(Vector3.ZERO, 40.0 * delta)
			if aim_direction.length() > 0.1:
				_turn_towards(aim_direction, delta)
			else:
				_face_target(delta)
			if state_time >= float(_attack["windup"]) * windup_scale:
				horizontal = _begin_active()
		State.ACTIVE:
			if _attack["kind"] == "dash":
				horizontal = facing * DASH_SPEED
			else:
				horizontal = horizontal.move_toward(Vector3.ZERO, 30.0 * delta)
			if _attack["kind"] != "projectile" and not _has_hit:
				_has_hit = _try_hit()
			if state_time >= float(_attack["active"]):
				_enter(State.RECOVERY)
		State.RECOVERY:
			horizontal = horizontal.move_toward(Vector3.ZERO, 40.0 * delta)
			if state_time >= float(_attack.get("recovery", 0.2)):
				_enter(State.FREE)
		State.DODGE:
			horizontal = _dodge_dir * DODGE_SPEED
			if state_time >= DODGE_TIME:
				_enter(State.FREE)
		State.STUNNED:
			horizontal = horizontal.move_toward(Vector3.ZERO, 20.0 * delta)
			if state_time >= _stun_time:
				_enter(State.FREE)
		State.DEAD:
			horizontal = horizontal.move_toward(Vector3.ZERO, 20.0 * delta)

	velocity.x = horizontal.x
	velocity.z = horizontal.z
	velocity.y = -0.5 if is_on_floor() else velocity.y - GRAVITY * delta
	move_and_slide()
	_keep_inside_arena()
	_update_visuals()


# --- Combate interno -------------------------------------------------------

func _start_attack(attack: Dictionary, element: int) -> bool:
	if state != State.FREE:
		return false
	var cost: float = attack.get("energy", 0.0)
	if energy < cost:
		return false
	energy -= cost
	_attack = attack
	_attack_element = element
	_has_hit = false
	if aim_direction.length() > 0.1:
		look_along(aim_direction)
	else:
		_face_target(-1.0)
	_enter(State.WINDUP)
	_show_telegraph(true)
	return true


## Pasa a la fase activa del ataque y devuelve la velocidad de embestida.
func _begin_active() -> Vector3:
	_show_telegraph(false)
	if _attack["kind"] == "projectile":
		_spawn_projectile()
	_enter(State.ACTIVE)
	var lunge: float = _attack.get("lunge", 0.0)
	return facing * lunge


func _try_hit() -> bool:
	var reach: float = _attack["range"]
	var arc: float = _attack["arc_deg"]
	var power: float = _attack["power"]
	var hit_any := false
	for node in get_tree().get_nodes_in_group("creatures"):
		var other := node as Creature
		if other == null or other == self or other.team == team or not other.is_targetable():
			continue
		var to := other.global_position - global_position
		to.y = 0.0
		var distance := to.length()
		if distance - other.radius() - radius() > reach:
			continue
		if distance > 0.01 and arc < 360.0 and rad_to_deg(facing.angle_to(to / distance)) > arc * 0.5:
			continue
		other.take_hit(data.attack, power, _attack_element, to.normalized())
		hit_any = true
	return hit_any


func _spawn_projectile() -> void:
	var projectile := Projectile.new()
	projectile.shooter_team = team
	projectile.attack_stat = data.attack
	projectile.power = float(_attack["power"])
	projectile.element = _attack_element
	projectile.direction = facing
	projectile.max_distance = float(_attack["range"])
	projectile.color = data.body_color.lightened(0.35)
	get_parent().add_child(projectile)
	projectile.global_position = global_position + facing * (radius() + 0.4) + Vector3.UP * data.height_m * 0.5


func _die() -> void:
	_enter(State.DEAD)
	_material.albedo_color = data.body_color.darkened(0.6)
	_visual.scale = Vector3(1.2, 0.4, 1.2)
	message.emit("%s se debilitó." % data.display_name())
	died.emit(self)


func _enter(new_state: State) -> void:
	state = new_state
	state_time = 0.0


func _face_target(delta: float) -> void:
	if not is_instance_valid(target) or not target.is_targetable():
		return
	var to := target.global_position - global_position
	to.y = 0.0
	if to.length() < 0.01 or to.length() > SOFT_LOCK_RANGE:
		return
	if delta < 0.0:
		look_along(to)
	else:
		_turn_towards(to, delta)


func _turn_towards(direction: Vector3, delta: float) -> void:
	if Vector2(direction.x, direction.z).length() < 0.01:
		return
	var angle := lerp_angle(atan2(facing.x, facing.z), atan2(direction.x, direction.z), clampf(TURN_SPEED * delta, 0.0, 1.0))
	look_along(Vector3(sin(angle), 0.0, cos(angle)))


func _keep_inside_arena() -> void:
	var flat := Vector2(global_position.x, global_position.z)
	var limit := arena_radius - radius()
	if flat.length() > limit:
		flat = flat.normalized() * limit
		global_position.x = flat.x
		global_position.z = flat.y


# --- Aspecto ---------------------------------------------------------------

func _build_body() -> void:
	var r := radius()
	var shape := CapsuleShape3D.new()
	shape.radius = r
	shape.height = maxf(data.height_m, r * 2.0)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position.y = shape.height * 0.5
	add_child(collision)

	_visual = CreatureLook.build(data)
	add_child(_visual)
	_material = _visual.get_meta("body_material") as StandardMaterial3D

	_telegraph_material = PixelLook.unshaded(Color(1.0, 0.15, 0.1, 0.35))
	_telegraph = MeshInstance3D.new()
	_telegraph.visible = false
	_telegraph.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_telegraph)


## Muestra en el suelo la zona que va a golpear el ataque, para poder esquivarlo.
func _show_telegraph(on: bool) -> void:
	if _telegraph == null:
		return
	if not on:
		_telegraph.visible = false
		return
	var kind: String = _attack["kind"]
	var reach: float = _attack["range"]
	if kind == "melee":
		var disc := CylinderMesh.new()
		disc.top_radius = reach + radius()
		disc.bottom_radius = disc.top_radius
		disc.height = 0.02
		disc.radial_segments = 16
		_telegraph.mesh = disc
		_telegraph.position = Vector3(0.0, 0.03, 0.0)
	else:
		var length := reach if kind == "projectile" else DASH_SPEED * float(_attack["active"])
		var strip := BoxMesh.new()
		strip.size = Vector3(radius() * 1.6, 0.02, length)
		_telegraph.mesh = strip
		_telegraph.position = Vector3(0.0, 0.03, -length * 0.5)
	_telegraph.material_override = _telegraph_material
	_telegraph.visible = true


func _update_visuals() -> void:
	if _flash > 0.0:
		_material.emission_enabled = true
		_material.emission = Color.WHITE
		_material.emission_energy_multiplier = 1.5
	elif state == State.WINDUP:
		_material.emission_enabled = true
		_material.emission = Color(1.0, 0.1, 0.05)
		_material.emission_energy_multiplier = 0.4 + 0.4 * sin(state_time * 30.0)
	else:
		_material.emission_enabled = false
	if state == State.DODGE:
		_visual.scale = Vector3(0.85, 0.85, 1.2)
	elif state != State.DEAD:
		_visual.scale = Vector3.ONE
