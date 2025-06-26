@tool
extends Sprite2D

# === CONFIGURAÇÕES ===
@export var auto_update: bool = true
@export var debug_mode: bool = false

# === REFERÊNCIAS ===
var terrain_generator: TileMapLayer
var shader_material: ShaderMaterial

func _ready():
	print("🎨 ShaderController iniciado")
	
	add_to_group("shader")
	
	setup_shader()
	find_terrain_generator()
	
	if not Engine.is_editor_hint() and auto_update:
		await get_tree().process_frame
		# Aguarda um tempo maior para garantir que o terreno esteja pronto
		await get_tree().create_timer(2.0).timeout
		update_texture()

func setup_shader():
	"""Configura o shader e material"""
	centered = false
	z_index = -1
	
	if not material or not material is ShaderMaterial:
		material = ShaderMaterial.new()
	
	shader_material = material as ShaderMaterial
	
	var shader = load("res://Main.gdshader")
	if shader:
		shader_material.shader = shader
		print("✅ Shader carregado com sucesso")
	else:
		print("❌ Erro ao carregar shader Main.gdshader")
		return
	
	var texture_path = "res://TileSets/textureAtlas.png"
	if FileAccess.file_exists(texture_path):
		var texture_atlas = load(texture_path)
		shader_material.set_shader_parameter("textureAtlas", texture_atlas)
		print("✅ textureAtlas configurado no shader")
	else:
		print("❌ textureAtlas.png não encontrado")
	
	shader_material.set_shader_parameter("tileSizeInPixels", 32.0)
	shader_material.set_shader_parameter("textureAtlasTextureSizeInPixels", 128.0)
	shader_material.set_shader_parameter("textureAtlasTexturesWidth", 4.0)
	shader_material.set_shader_parameter("mapTilesCountX", 128.0)
	shader_material.set_shader_parameter("mapTilesCountY", 128.0)

func find_terrain_generator():
	"""Encontra o TerrainGenerator"""
	terrain_generator = get_node_or_null("../Terrain/TerrainMap")
	
	if not terrain_generator:
		var terrain_nodes = get_tree().get_nodes_in_group("terrain")
		if terrain_nodes.size() > 0:
			terrain_generator = terrain_nodes[0]
			print("✅ TerrainGenerator encontrado via grupo: ", terrain_generator.get_path())
	
	if terrain_generator:
		print("✅ TerrainGenerator encontrado para ShaderController")
		sync_with_terrain()
	else:
		print("❌ TerrainGenerator não encontrado!")

func sync_with_terrain():
	"""Sincroniza com o TerrainGenerator"""
	if not terrain_generator:
		return
	
	var map_width = terrain_generator.get("map_width") if terrain_generator.get("map_width") != null else 128
	var map_height = terrain_generator.get("map_height") if terrain_generator.get("map_height") != null else 128
	var tile_size = 32
	
	var total_width = map_width * tile_size
	var total_height = map_height * tile_size
	
	scale = Vector2(total_width / 32.0, total_height / 32.0)
	position = Vector2(0, 0)
	
	if shader_material:
		shader_material.set_shader_parameter("mapTilesCountX", float(map_width))
		shader_material.set_shader_parameter("mapTilesCountY", float(map_height))
	
		print("🎯 Shader sincronizado:")
		print("  - Dimensões: ", map_width, "x", map_height)
		print("  - Escala: ", scale)
		print("  - Posição: ", position)

func update_texture():
	"""Atualiza a textura mapData do shader"""
	print("🎨 Atualizando mapData no shader...")
	
	# Verifica se o TerrainGenerator está disponível
	if not terrain_generator:
		print("❌ Não é possível atualizar mapData sem TerrainGenerator")
		return
	
	# Aguarda até que o mapData.png esteja disponível
	var max_attempts = 10
	var attempt = 1
	var map_texture: ImageTexture
	
	while attempt <= max_attempts:
		if FileAccess.file_exists("res://mapData.png"):
			# Aguarda um pequeno tempo para garantir que o arquivo esteja completamente escrito
			await get_tree().create_timer(0.1).timeout
			
			var image = Image.new()
			var error = image.load("res://mapData.png")
			if error == OK:
				map_texture = ImageTexture.create_from_image(image)
				if map_texture:
					if shader_material:
						shader_material.set_shader_parameter("mapData", map_texture)
						print("✅ mapData atualizado no shader (tentativa ", attempt, ")")
						queue_redraw()
						if debug_mode:
							debug_shader_parameters()
						return
					else:
						print("❌ ShaderMaterial não disponível")
						return
				else:
					print("❌ Falha ao criar ImageTexture")
			else:
				print("❌ Erro ao carregar mapData.png: ", error)
			
			attempt += 1
			await get_tree().create_timer(0.1).timeout
		else:
			print("⏳ Aguardando mapData.png... (", attempt, "/", max_attempts, ")")
			attempt += 1
			await get_tree().create_timer(0.1).timeout
	
	print("❌ mapData.png não encontrado após ", max_attempts, " tentativas")
	if debug_mode:
		print("🔍 Verificando sistema de arquivos:")
		var dir = DirAccess.open("res://")
		if dir:
			var files = dir.get_files()
			print("📁 Arquivos em res://: ", files)

func debug_shader_parameters():
	"""Debug dos parâmetros do shader"""
	print("\n🔍 === DEBUG SHADER ===")
	print("  - Shader: ", shader_material.shader != null)
	print("  - textureAtlas: ", shader_material.get_shader_parameter("textureAtlas") != null)
	print("  - mapData: ", shader_material.get_shader_parameter("mapData") != null)
	print("  - tileSizeInPixels: ", shader_material.get_shader_parameter("tileSizeInPixels"))
	print("  - mapTilesCountX: ", shader_material.get_shader_parameter("mapTilesCountX"))
	print("  - mapTilesCountY: ", shader_material.get_shader_parameter("mapTilesCountY"))
	print("  - Sprite scale: ", scale)
	print("  - Sprite position: ", position)
	print("=== FIM DEBUG ===\n")

func refresh():
	"""Força atualização completa"""
	if terrain_generator:
		sync_with_terrain()
	update_texture()
