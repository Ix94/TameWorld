class_name WildCreature
extends Node3D
## Criatura salvaje que deambula por el mundo. Si el jugador la toca, empieza una pelea.

const WALK_SPEED := 1.5

var data: CreatureData
var world: WorldScene

var _target := Vector3.ZERO
var _timer := 0.0


func _ready() -> void:
	add_to_group("wild")
	add_child(CreatureLook.build(data))
	var label := Label3D.new()
	label.text = "Nv. %d" % data.level
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.font_size = 40
	label.pixel_size = 0.012
	label.outline_size = 8
	label.position.y = data.height_m + 0.6
	add_child(label)
	_target = global_position


func radius() -> float:
	return data.height_m * 0.35


func _process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		var wander := Vector3(randf_range(-3.0, 3.0), 0.0, randf_range(-3.0, 3.0))
		_target = (global_position + wander).clamp(Vector3(1, -10, 1), Vector3(WorldGen.SIZE - 1, 100, WorldGen.SIZE - 1))
		_timer = randf_range(2.0, 5.0)
	var to := _target - global_position
	to.y = 0.0
	if to.length() > 0.2:
		global_position += to.normalized() * WALK_SPEED * delta
		rotation.y = atan2(-to.x, -to.z)
	var ground := world.ground_y(floori(global_position.x), floori(global_position.z))
	global_position.y = lerpf(global_position.y, ground, clampf(10.0 * delta, 0.0, 1.0))
