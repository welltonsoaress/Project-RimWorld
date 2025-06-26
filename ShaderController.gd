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
		# CORREÇÃO: Aguarda mais tempo para garantir que o terreno esteja pronto
		await get_tree().create_timer(2.0).timeout
		update_texture()

func setup_shader():
	"""Configura o shader e material - VERSÃO CORRIGIDA"""
	centered = false
	z_index = -1  # CORREÇÃO: Garante que fica atrás
	
	# CORREÇÃO: Força escala 2.0 desde o início
	scale = Vector2(2.0, 2.0)
	position = Vector2(0, 0)
	
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
	
	# CORREÇÃO: Configura parâmetros do shader corretamente
	shader_material.set_shader_parameter("tileSizeInPixels", 32.0)
	shader_material.set_shader_parameter("textureAtlasTextureSizeInPixels", 128.0)
	shader_material.set_shader_parameter("textureAtlasTexturesWidth", 4.0)
	shader_material.set_shader_parameter("mapTilesCountX", 128.0)
	shader_material.set_shader_parameter("mapTilesCountY", 128.0)

func find_terrain_generator():
	"""Encontra o TerrainGenerator - VERSÃO MELHORADA"""
	# CORREÇÃO: Busca usando estrutura vista no debug
	var possible_paths = [
		"../Terrain/TerrainMap",
		"../../Terrain/TerrainMap",
		"/root/Main/Terrain/TerrainMap"
	]
	
	for path in possible_paths:
		var node = get_node_or_null(path)
		if node and node is TileMapLayer:
			terrain_generator = node
			print("✅ TerrainGenerator encontrado em: ", path)
			sync_with_terrain()
			return
	
	# Busca por grupo
	var terrain_nodes = get_tree().get_nodes_in_group("terrain")
	if terrain_nodes.size() > 0:
		terrain_generator = terrain_nodes[0]
		print("✅ TerrainGenerator encontrado via grupo: ", terrain_generator.get_path())
		sync_with_terrain()
		return
	
	print("❌ TerrainGenerator não encontrado!")

func sync_with_terrain():
	"""Sincroniza com o TerrainGenerator - VERSÃO CORRIGIDA"""
	if not terrain_generator:
		return
	
	var map_width = terrain_generator.get("map_width") if "map_width" in terrain_generator else 128
	var map_height = terrain_generator.get("map_height") if "map_height" in terrain_generator else 128
	
	# CORREÇÃO: Força escala 2.0 para corresponder ao TerrainMap
	scale = Vector2(2.0, 2.0)
	position = Vector2(0, 0)
	
	if shader_material:
		shader_material.set_shader_parameter("mapTilesCountX", float(map_width))
		shader_material.set_shader_parameter("mapTilesCountY", float(map_height))
	
	print("🎯 Shader sincronizado:")
	print("  - Dimensões: ", map_width, "x", map_height)
	print("  - Escala CORRIGIDA: ", scale)
	print("  - Posição: ", position)

func update_texture():
	"""CORREÇÃO CRÍTICA: Atualiza mapData com sistema robusto"""
	print("🎨 Atualizando mapData no shader...")
	
	# Verifica se o TerrainGenerator está disponível
	if not terrain_generator:
		print("🔍 Buscando TerrainGenerator...")
		find_terrain_generator()
		
		if not terrain_generator:
			print("❌ Não é possível atualizar mapData sem TerrainGenerator")
			return
	
	# CORREÇÃO CRÍTICA: Sistema robusto para carregar mapData.png
	var max_attempts = 30  # MUITO AUMENTADO
	var attempt = 1
	var map_texture: ImageTexture
	
	while attempt <= max_attempts:
		# CORREÇÃO: Verifica se arquivo existe E tem tamanho válido
		var file = FileAccess.open("res://mapData.png", FileAccess.READ)
		if file:
			var file_size = file.get_length()
			file.close()
			
			if file_size > 100:  # Arquivo tem conteúdo mínimo
				# CORREÇÃO: Aguarda um pouco para garantir que escrita terminou
				await get_tree().create_timer(0.1).timeout
				
				# CORREÇÃO: Tenta carregar de múltiplas formas
				var success = false
				
				# Método 1: Carrega diretamente
				var image = Image.new()
				var error = image.load("res://mapData.png")
				if error == OK and image.get_size() == Vector2i(128, 128):
					map_texture = ImageTexture.create_from_image(image)
					if map_texture:
						success = true
				
				# Método 2: Se falhou, força reload do ResourceLoader
				if not success:
					print("🔄 Tentativa ", attempt, ": Forçando reload...")
					
					# Clear cache se possível
					if ResourceLoader.has_cached("res://mapData.png"):
						print("🧹 Limpando cache...")
					
					# Tenta carregar novamente
					await get_tree().create_timer(0.2).timeout
					image = Image.new()
					error = image.load("res://mapData.png")
					if error == OK:
						map_texture = ImageTexture.create_from_image(image)
						if map_texture:
							success = true
				
				# Se conseguiu carregar, aplica ao shader
				if success and map_texture:
					if shader_material:
						shader_material.set_shader_parameter("mapData", map_texture)
						print("✅ mapData atualizado no shader (tentativa ", attempt, ")")
						print("  - Tamanho da imagem: ", map_texture.get_size())
						print("  - Primeiro pixel: ", image.get_pixel(0, 0))
						
						# CORREÇÃO: Força escala 2.0 após atualização
						scale = Vector2(2.0, 2.0)
						
						queue_redraw()
						if debug_mode:
							debug_shader_parameters()
						return
					else:
						print("❌ ShaderMaterial não disponível")
						return
				else:
					print("⚠️ Tentativa ", attempt, ": Falha ao criar ImageTexture")
			else:
				print("⚠️ Tentativa ", attempt, ": Arquivo muito pequeno (", file_size, " bytes)")
		else:
			print("⚠️ Tentativa ", attempt, ": mapData.png não encontrado")
		
		attempt += 1
		await get_tree().create_timer(0.3).timeout  # AUMENTADO
	
	print("❌ mapData.png não foi carregado após ", max_attempts, " tentativas")
	
	# CORREÇÃO: Debug final do sistema de arquivos
	debug_filesystem_state()

func debug_filesystem_state():
	"""Debug do estado do sistema de arquivos"""
	print("🔍 === DEBUG SISTEMA DE ARQUIVOS ===")
	
	var dir = DirAccess.open("res://")
	if dir:
		var files = dir.get_files()
		print("📁 Arquivos em res://:")
		for file in files:
			if file.ends_with(".png"):
				var file_access = FileAccess.open("res://" + file, FileAccess.READ)
				if file_access:
					var size = file_access.get_length()
					file_access.close()
					print("  🖼️ ", file, " (", size, " bytes)")
				else:
					print("  ❌ ", file, " (não acessível)")
	
	# Verifica ResourceLoader
	print("📦 ResourceLoader cache:")
	if ResourceLoader.has_cached("res://mapData.png"):
		print("  ✅ mapData.png está em cache")
	else:
		print("  ❌ mapData.png NÃO está em cache")
	
	print("=== FIM DEBUG ===")

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
	# CORREÇÃO: Força escala 2.0 durante refresh
	scale = Vector2(2.0, 2.0)
	
	if terrain_generator:
		sync_with_terrain()
	update_texture()

# CORREÇÃO: Função para forçar escala correta
func force_correct_scale():
	"""Força escala correta do shader"""
	scale = Vector2(2.0, 2.0)
	position = Vector2(0, 0)
	z_index = -1
	print("🔧 Shader: Escala forçada para (2.0, 2.0)")

# CORREÇÃO: Função chamada automaticamente para manter escala
func _process(_delta):
	if not Engine.is_editor_hint():
		# Garante que a escala permaneça 2.0
		if scale != Vector2(2.0, 2.0):
			scale = Vector2(2.0, 2.0)
			if debug_mode:
				print("🔧 Shader: Escala corrigida automaticamente para (2.0, 2.0)")
