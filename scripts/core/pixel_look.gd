class_name PixelLook
extends RefCounted
## Materiales y texturas para el estilo pixel art 3D.


static func toon(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	material.specular_mode = BaseMaterial3D.SPECULAR_TOON
	material.roughness = 1.0
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	return material


static func unshaded(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	if color.a < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


## Textura de cuadros de 4x4 píxeles con un poco de variación, para el suelo.
static func checker_texture(a: Color, b: Color) -> ImageTexture:
	var image := Image.create_empty(4, 4, false, Image.FORMAT_RGBA8)
	for y in 4:
		for x in 4:
			var base := a if (x + y) % 2 == 0 else b
			var shade := 0.04 if (x * 3 + y * 5) % 7 == 0 else 0.0
			image.set_pixel(x, y, base.lightened(shade))
	return ImageTexture.create_from_image(image)


## Crea un viewport de baja resolución que se agranda sin suavizado (look pixel art).
## Todo lo 3D debe ir dentro del viewport devuelto.
static func make_pixel_viewport(parent: Node, shrink: int) -> SubViewport:
	var container := SubViewportContainer.new()
	container.stretch = true
	container.stretch_shrink = shrink
	container.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	parent.add_child(container)
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var viewport := SubViewport.new()
	viewport.msaa_3d = Viewport.MSAA_DISABLED
	viewport.audio_listener_enable_3d = true
	container.add_child(viewport)
	return viewport


## Cielo, luz ambiental y sol.
static func add_daylight(world: Node3D, sky_color: Color) -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = sky_color
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.75, 0.8, 0.9)
	environment.ambient_light_energy = 0.6
	var world_env := WorldEnvironment.new()
	world_env.environment = environment
	world.add_child(world_env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55.0, 35.0, 0.0)
	sun.shadow_enabled = true
	sun.light_energy = 1.1
	world.add_child(sun)


## Mueve la cámara a `target` ajustada a la rejilla de píxeles, para que la imagen no "tiemble".
static func snap_camera(camera: Camera3D, target: Vector3, viewport: SubViewport) -> void:
	var texel := camera.size / maxf(1.0, float(viewport.size.y))
	var cam_basis := camera.global_transform.basis
	var local := (cam_basis.inverse() * target).snapped(Vector3(texel, texel, texel))
	camera.global_position = cam_basis * local
