class_name Trainer
extends CharacterBody3D
## El jugador en el mundo abierto: camina, salta y nada.
## En el agua va lento, salvo que su criatura activa sepa nadar.

const SPEED := 5.0
const WATER_SPEED_FACTOR := 0.45
const JUMP_VELOCITY := 7.5
const SWIM_UP_SPEED := 3.0
const GRAVITY := 25.0

var facing := Vector3.FORWARD
var in_water := false
var can_swim := false
## Tamaño del mundo, para no salirse por los bordes.
var bounds := 48.0


func _ready() -> void:
	var shape := CapsuleShape3D.new()
	shape.radius = 0.3
	shape.height = 1.6
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position.y = 0.8
	add_child(collision)
	_add_part(_capsule(0.28, 1.0), PixelLook.toon(Color(0.25, 0.4, 0.8)), Vector3(0.0, 0.55, 0.0))
	_add_part(_box(Vector3(0.4, 0.4, 0.4)), PixelLook.toon(Color(0.95, 0.78, 0.62)), Vector3(0.0, 1.3, 0.0))
	_add_part(_box(Vector3(0.48, 0.14, 0.52)), PixelLook.toon(Color(0.85, 0.2, 0.2)), Vector3(0.0, 1.55, -0.04))


func _physics_process(delta: float) -> void:
	var stick := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction := Vector3(stick.x, 0.0, stick.y)
	var speed := SPEED
	if in_water and not can_swim:
		speed *= WATER_SPEED_FACTOR
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	if direction.length() > 0.1:
		facing = direction.normalized()
		rotation.y = atan2(-facing.x, -facing.z)

	if in_water:
		velocity.y -= GRAVITY * 0.3 * delta
		if Input.is_action_pressed("jump"):
			velocity.y = SWIM_UP_SPEED
	elif is_on_floor():
		if Input.is_action_just_pressed("jump"):
			velocity.y = JUMP_VELOCITY
	else:
		velocity.y -= GRAVITY * delta
	move_and_slide()
	global_position.x = clampf(global_position.x, 0.4, bounds - 0.4)
	global_position.z = clampf(global_position.z, 0.4, bounds - 0.4)


func _add_part(mesh: Mesh, material: Material, offset: Vector3) -> void:
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.material_override = material
	part.position = offset
	add_child(part)


func _capsule(r: float, height: float) -> CapsuleMesh:
	var capsule := CapsuleMesh.new()
	capsule.radius = r
	capsule.height = height
	capsule.radial_segments = 8
	capsule.rings = 2
	return capsule


func _box(size: Vector3) -> BoxMesh:
	var box := BoxMesh.new()
	box.size = size
	return box
