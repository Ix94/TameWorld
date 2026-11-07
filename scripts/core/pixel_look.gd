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
