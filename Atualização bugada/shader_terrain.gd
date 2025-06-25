@tool
extends Sprite2D

# === REFERÊNCIAS ===
var terrainMap: TileMapLayer
var shaderMaterial: ShaderMaterial

# === CONFIGURAÇÕES ===
@export var auto_update_shader: bool = true
@export var debug_shader_info: bool = false

# === TEXTURAS ===
var textureAtlas: CompressedTexture2D
var mapData: ImageTexture

func _ready():
	print("🎨 ShaderTerrain _ready() chamado")
	configure_shader_properties()
	loadTextures()
	
	# Conecta com TerrainMap se possível
	call_deferred("connect_terrain_signals")
	call_deferred("findTerrainMap")

func configure_shader_properties():
	"""Configura propriedades básicas do Sprite2D"""
	# Configurações do sprite para o shader
	centered = false
	
	# Cria ou obtém o ShaderMaterial
	if not material or not material is ShaderMaterial:
		material = ShaderMaterial.new()
	
	shaderMaterial = material as ShaderMaterial
	
	# Carrega o shader se não estiver carregado
	if not shaderMaterial.shader:
		var shader = load("res://terrain_shader.gdshader")
		if shader:
			shaderMaterial.shader = shader
			print("✅ Shader carregado")
		else:
			print("❌ Falha ao carregar terrain_shader.gdshader")

func loadTextures():
	"""Carrega texturas necessárias para o shader"""
	print("🎨 Carregando texturas...")
	
	# Carrega textureAtlas - tenta múltiplos caminhos
	var texture_paths = [
		"res://TileSets/textureAtlas.png",
		"res://textureAtlas.png",
		"res://assets/textureAtlas.png",
		"res://textures/textureAtlas.png",
		"res://Images/textureAtlas.png"
	]
	
	for path in texture_paths:
		if FileAccess.file_exists(path):
			textureAtlas = load(path)
			if textureAtlas:
				print("✅ textureAtlas.png carregado de: ", path)
				break
		else:
			print("⚠️ Tentando: ", path, " - não encontrado")
	
	if not textureAtlas:
		print("❌ textureAtlas.png não encontrado em nenhum caminho!")
		print("📁 Verifique se o arquivo existe na pasta res://")
		return
	
	# Carrega ou cria mapData
	loadMapData()
	
	# Configura texturas no shader
	if shaderMaterial:
		shaderMaterial.set_shader_parameter("textureAtlas", textureAtlas)
		if mapData:
			shaderMaterial.set_shader_parameter("mapData", mapData)
		
		print("✅ Texturas configuradas no shader")

func loadMapData():
	"""Carrega ou aguarda o mapData.png"""
	var max_attempts = 10
	var attempt = 1
	
	while attempt <= max_attempts:
		if FileAccess.file_exists("res://mapData.png"):
			var image = Image.new()
			var error = image.load("res://mapData.png")
			
			if error == OK:
				mapData = ImageTexture.new()
				mapData.set_image(image)
				print("✅ mapData.png carregado na tentativa ", attempt)
				return
			else:
				print("❌ Erro ao carregar mapData.png: ", error)
		
		print("⏳ Tentativa ", attempt, "/", max_attempts, " - mapData.png não encontrado")
		await get_tree().create_timer(0.5).timeout
		attempt += 1
	
	print("❌ mapData.png não encontrado após ", max_attempts, " tentativas")

func findTerrainMap():
	"""Busca o TerrainMap na hierarquia"""
	print("🔍 Procurando TerrainMap...")
	
	# Lista de caminhos possíveis para o TerrainMap
	var possible_paths = [
		
		"../Terrain/TerrainMap",           # Caminho relativo do Main
		"../../Main/Terrain/TerrainMap",   # Do WorldManager para Main
		"/root/WorldManager/Main/Terrain/TerrainMap",  # Caminho absoluto
		"Terrain/TerrainMap",              # Direto
		"../TerrainMap",                   # Backup
		"../../TerrainMap",                # Backup 2
		"/root/Main/Terrain/TerrainMap"    # Se Main for raiz
	]
	
	for path in possible_paths:
		var terrain = get_node_or_null(path)
		if terrain and terrain is TileMapLayer:
			print("✅ TerrainMap encontrado em: ", path)
			terrainMap = terrain
			
			# Força sincronização
			sync_with_terrain()
			return terrain
	
	# Busca recursiva a partir do WorldManager
	var world_manager = get_tree().root.get_node_or_null("WorldManager")
	if world_manager:
		var result = find_terrain_recursive(world_manager)
		if result:
			print("✅ TerrainMap encontrado via busca recursiva")
			terrainMap = result
			sync_with_terrain()
			return result
	
	# Busca recursiva a partir da raiz
	var result = find_terrain_recursive(get_tree().root)
	if result:
		print("✅ TerrainMap encontrado na busca global")
		terrainMap = result
		sync_with_terrain()
		return result
	
	print("❌ TerrainMap não encontrado para sincronização!")
	return null

func find_terrain_recursive(node: Node) -> TileMapLayer:
	"""Busca recursiva pelo TerrainMap"""
	if node is TileMapLayer and node.name == "TerrainMap":
		return node
	
	for child in node.get_children():
		var result = find_terrain_recursive(child)
		if result:
			return result
	
	return null

func sync_with_terrain():
	"""Sincroniza configurações com o TerrainMap"""
	if not terrainMap:
		return
	
	# Aguarda o TerrainMap ter escala correta
	await get_tree().create_timer(0.1).timeout
	
	# Força escala correta no TerrainMap se necessário
	if terrainMap.scale != Vector2(2.0, 2.0):
		terrainMap.scale = Vector2(2.0, 2.0)
		print("🔧 Shader forçou escala (2.0, 2.0) no TerrainMap")
	
	# Obtém informações do TerrainMap
	var terrain_scale = terrainMap.scale
	var terrain_position = terrainMap.position
	
	# Calcula dimensões baseado na escala do TerrainMap
	var base_size = 128 * 32  # mapSize * tileSize
	var final_size = base_size * terrain_scale.x
	
	# Configura o sprite para cobrir exatamente o terreno
	scale = Vector2(final_size / 32.0, final_size / 32.0)  # 32 é o tamanho base do sprite
	position = terrain_position
	
	# Garante que está atrás do terreno
	z_index = -1
	
	print("🔄 Sincronizado com TerrainMap:")
	print("  - TerrainMap scale: ", terrain_scale)
	print("  - TerrainMap position: ", terrain_position)
	print("  - Shader scale: ", scale)
	print("  - Shader z_index: ", z_index)
	print("  - Tamanho final: ", final_size, "x", final_size)

func connect_terrain_signals():
	"""Conecta sinais do TerrainMap"""
	if not terrainMap:
		terrainMap = findTerrainMap()
	
	if terrainMap and terrainMap.has_signal("terrain_generated"):
		if not terrainMap.is_connected("terrain_generated", _on_terrain_generated):
			terrainMap.connect("terrain_generated", _on_terrain_generated)
			print("✅ Sinal terrain_generated conectado")

func _on_terrain_generated():
	"""Callback quando terreno é gerado"""
	print("🎯 Shader: Terreno gerado, atualizando...")
	call_deferred("updateShader")

func updateShader():
	"""Atualiza o shader com dados atuais"""
	print("🎨 Atualizando shader...")
	
	# Recarrega mapData se necessário
	if not mapData:
		await loadMapData()
	
	# Encontra TerrainMap se necessário
	if not terrainMap:
		terrainMap = findTerrainMap()
	
	if not terrainMap:
		print("❌ Não foi possível encontrar TerrainMap para atualizar shader")
		return
	
	# Sincroniza com TerrainMap
	sync_with_terrain()
	
	# Configura parâmetros do shader
	if shaderMaterial and mapData:
		# Parâmetros básicos
		shaderMaterial.set_shader_parameter("mapData", mapData)
		shaderMaterial.set_shader_parameter("tileSizeInPixels", 32.0)
		shaderMaterial.set_shader_parameter("mapTilesCountX", 128.0)
		shaderMaterial.set_shader_parameter("mapTilesCountY", 128.0)
		
		print("🎨 mapData atualizado no shader")
		
		if debug_shader_info:
			debug_shader_status()
	else:
		print("❌ ShaderMaterial ou mapData não disponível")

func debug_shader_status():
	"""Debug das configurações do shader"""
	print("🔍 DEBUG - Status do Shader:")
	print("  - ShaderMaterial: ", shaderMaterial != null)
	print("  - Shader carregado: ", shaderMaterial.shader != null if shaderMaterial else false)
	print("  - textureAtlas: ", textureAtlas != null)
	print("  - mapData: ", mapData != null)
	print("  - TerrainMap: ", terrainMap != null)
	
	if terrainMap:
		print("  - TerrainMap scale: ", terrainMap.scale)
		print("  - TerrainMap position: ", terrainMap.position)
	
	print("  - Sprite scale: ", scale)
	print("  - Sprite position: ", position)
	print("  - Sprite centered: ", centered)
	
	if shaderMaterial:
		print("🔍 DEBUG - Parâmetros do Shader:")
		print("  - textureAtlas: ", shaderMaterial.get_shader_parameter("textureAtlas"))
		print("  - mapData: ", shaderMaterial.get_shader_parameter("mapData"))
		print("  - tileSizeInPixels: ", shaderMaterial.get_shader_parameter("tileSizeInPixels"))
		print("  - mapTilesCountX: ", shaderMaterial.get_shader_parameter("mapTilesCountX"))
		print("  - mapTilesCountY: ", shaderMaterial.get_shader_parameter("mapTilesCountY"))

# === FUNÇÕES PÚBLICAS PARA COMPATIBILIDADE ===

func configure():
	"""Configuração inicial (compatibilidade)"""
	updateShader()

func setup():
	"""Setup inicial (compatibilidade)"""
	updateShader()
