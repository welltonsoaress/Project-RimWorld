extends Sprite2D

@export var tile_size := 32
@export var map_width := 128
@export var map_height := 128

@onready var shader_sprite := self
@onready var material_instance := material as ShaderMaterial if material and material is ShaderMaterial else ShaderMaterial.new()
var map_data_texture: ImageTexture = null  # Usa ImageTexture para geração dinâmica

func _ready():
	if not Engine.is_editor_hint():
		# Usa material existente ou cria novo, preserva configurações manuais
		if not material or not material is ShaderMaterial:
			material = ShaderMaterial.new()
			material.shader = load("res://main.gdshader")
			print("📢 Material inicializado e shader atribuído: ", material.shader.resource_path)
		else:
			print("📢 Usando material existente: ", material.resource_name)
		update_texture()

func update_texture():
	await get_tree().process_frame
	await get_tree().create_timer(0.5).timeout

	var map_data_image = Image.new()
	var err = map_data_image.load("res://mapData.png")
	if err != OK:
		print("⚠️ Falha ao carregar mapData.png: ", err)
		return

	if not map_data_texture:
		map_data_texture = ImageTexture.new()
	map_data_texture.set_image(map_data_image)
	print("📷 Textura gerada dinamicamente, tamanho: ", map_data_image.get_size(), " - Primeiros pixels: ", map_data_image.get_pixel(0, 0), map_data_image.get_pixel(1, 0))

	if material_instance:
		material_instance.set_shader_parameter("map_data", null)
		await get_tree().process_frame
		material_instance.set_shader_parameter("map_data", map_data_texture)
		print("📌 map_data atribuído: ", map_data_texture.get_size())
		material_instance.set_shader_parameter("mapTilesCountX", map_width)
		material_instance.set_shader_parameter("mapTilesCountY", map_height)
		material_instance.set_shader_parameter("tileSizeInPixels", tile_size)
		material_instance.set_shader_parameter("textureAtlasTextureSizeInPixels", 128.0)
		material_instance.set_shader_parameter("textureAtlasTexturesWidth", 4.0)
		material_instance.set_shader_parameter("blendTexture", preload("res://blendTexture.png"))
		material_instance.set_shader_parameter("blendTextureTiles", 4.0)
		print("🎨 ShaderMaterial atualizado com nova textura: ", map_data_texture.get_size())
		material = material_instance
		queue_redraw()  # Força a renderização
	else:
		print("⚠️ No shader material instance assigned to ShaderTerrain!")

	scale = Vector2(1.0, 1.0)
	print("Sprite scaled to: ", scale)

	position = Vector2.ZERO

func _on_material_changed():
	print("🔄 Material mudou, verificando parâmetros...")
	if material_instance:
		var map_data = material_instance.get_shader_parameter("map_data")
		print("🔍 map_data atual: ", map_data.get_size() if map_data else "Nenhum")
