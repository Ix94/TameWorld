class_name CreatureLook
extends RefCounted
## Construye el cuerpo low-poly de una criatura a partir de su ficha.
## Lo usan el combate (Creature) y el mundo (acompañante y criaturas salvajes).
## El material del cuerpo queda en el meta "body_material" del nodo devuelto.


static func build(data: CreatureData) -> Node3D:
	var root := Node3D.new()
	var r := data.height_m * 0.35
	var height := maxf(data.height_m, r * 2.0)
	var body_material := PixelLook.toon(data.body_color)
	root.set_meta("body_material", body_material)

	var capsule := CapsuleMesh.new()
	capsule.radius = r
	capsule.height = height
	capsule.radial_segments = 8
	capsule.rings = 2
	_add_part(root, capsule, body_material, Vector3(0.0, height * 0.5, 0.0))

	var white := PixelLook.toon(Color.WHITE)
	var black := PixelLook.unshaded(Color.BLACK)
	for side: float in [-1.0, 1.0]:
		var eye_pos := Vector3(side * r * 0.45, height * 0.72, -r * 0.8)
		_add_part(root, _sphere(r * 0.22), white, eye_pos)
		_add_part(root, _sphere(r * 0.11), black, eye_pos + Vector3(0.0, 0.0, -r * 0.18))

	var crest := PrismMesh.new()
	crest.size = Vector3(r * 0.8, r * 0.7, r * 0.5)
	_add_part(root, crest, PixelLook.toon(data.body_color.darkened(0.3)), Vector3(0.0, height + r * 0.3, 0.0))
	return root


static func _add_part(root: Node3D, mesh: Mesh, material: Material, offset: Vector3) -> void:
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.material_override = material
	part.position = offset
	root.add_child(part)


static func _sphere(r: float) -> SphereMesh:
	var sphere := SphereMesh.new()
	sphere.radius = r
	sphere.height = r * 2.0
	sphere.radial_segments = 6
	sphere.rings = 3
	return sphere
