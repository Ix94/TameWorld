class_name Projectile
extends Node3D
## Proyectil de una habilidad a distancia.

const HIT_RADIUS := 0.3

var shooter_team := 0
var attack_stat := 10.0
var power := 1.0
var element := 0
var direction := Vector3.FORWARD
var speed := 15.0
var max_distance := 10.0
var color := Color.ORANGE

var _traveled := 0.0


func _ready() -> void:
	var sphere := SphereMesh.new()
	sphere.radius = HIT_RADIUS
	sphere.height = HIT_RADIUS * 2.0
	sphere.radial_segments = 6
	sphere.rings = 3
	var mesh := MeshInstance3D.new()
	mesh.mesh = sphere
	mesh.material_override = PixelLook.unshaded(color)
	add_child(mesh)


func _physics_process(delta: float) -> void:
	var step := direction * speed * delta
	global_position += step
	_traveled += step.length()
	for node in get_tree().get_nodes_in_group("creatures"):
		var creature := node as Creature
		if creature == null or creature.team == shooter_team or not creature.is_targetable():
			continue
		var to := creature.global_position - global_position
		to.y = 0.0
		if to.length() <= creature.radius() + HIT_RADIUS:
			creature.take_hit(attack_stat, power, element, direction)
			queue_free()
			return
	if _traveled >= max_distance:
		queue_free()
