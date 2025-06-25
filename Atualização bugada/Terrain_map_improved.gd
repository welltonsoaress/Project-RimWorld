@tool
extends TileMapLayer

# === COMPATIBILIDADE COM SISTEMA ATUAL ===
# Mantém todas as propriedades e métodos existentes

@export var generateTerrain: bool = false:
	set(value):
		generateTerrain = false
		if value:
			GenerateTerrain()

@export var clearTerrain: bool = false:
	set(value):
		clearTerrain = false
		if value:
			clear()
			print("🧹 Terreno limpo!")

# Tamanho do mapa (mantido para compatibilidade)
@export var mapWidth: int = 128
@export var mapHeight: int = 128

# Semente para ruído
@export var terrainSeed: int = 0

# Tipo de terreno expandido
@export_enum("Auto", "Ilha", "Continente", "Arquipélago", "Península", "Desertão")
var terrainType: String = "Auto"

# === NOVAS FUNCIONALIDADES ===

# Sistema modular de biomas
@export_group("Sistema Modular")
@export var use_advanced_generation: bool = true
@export var use_temperature: bool = true
@export var use_humidity: bool = true

# Debug e preview
@export_group("Debug")
@export var show_debug_info: bool = false
@export var generate_preview_maps: bool = false:
	set(value):
		generate_preview_maps = false
		if value:
			generate_debug_previews()

# Thresholds originais (mantidos para compatibilidade)
@export_group("Compatibilidade")
@export var oceanThreshold := 0.25
@export var beachThreshold := 0.35
@export var desertThreshold := 0.45
@export var grassThreshold := 0.55
@export var darkGrassThreshold := 0.7
@export var mountainThreshold := 0.85

# === SISTEMA MODULAR ===
var biome_manager: BiomeManager
var noise_generator: NoiseGenerator
var isIsland: bool = false

func _ready():
	print("🌍 TerrainMap _ready() chamado - Sistema Modular")
	
	# Inicializa o sistema modular
	initialize_modular_system()
	
	if not tile_set:
		print("⚠️ TileSet não atribuído, criando automaticamente...")
		create_automatic_tileset()
	
	position = Vector2(0, 0)
	print("✅ TileMapLayer pronto: ", name, " | Posição inicial: ", position)
	
	if not Engine.is_editor_hint():
		await get_tree().process_frame
		GenerateTerrain()

func initialize_modular_system():
	"""Inicializa o sistema modular de biomas"""
	biome_manager = BiomeManager.get_instance()
	
	if biome_manager.validate_config():
		print("✅ Sistema modular de biomas inicializado")
		if show_debug_info:
			biome_manager.print_biome_info()
	else:
		print("⚠️ Usando configuração de fallback")

func GenerateTerrain():
	"""Função principal de geração - mantém compatibilidade total"""
	print("🌍 Gerando terreno procedural - Sistema Modular Ativo!")
	
	# Configuração de semente (sistema original mantido)
	var rng = RandomNumberGenerator.new()
	if terrainSeed == 0:
		rng.randomize()
		terrainSeed = rng.randi()
		print("🌱 Nova semente gerada: ", terrainSeed)
	else:
		rng.set_seed(terrainSeed)
		print("🌱 Usando semente fixa: ", terrainSeed)
	
	# Determina tipo de terreno (sistema original expandido)
	var terrain_type_config = determine_terrain_type(rng)
	
	# Inicializa gerador de ruído
	noise_generator = NoiseGenerator.new(terrainSeed)
	
	# Verifica se deve usar geração avançada ou compatibilidade
	if use_advanced_generation and biome_manager:
		generate_with_advanced_system(terrain_type_config)
	else:
		generate_with_legacy_system(terrain_type_config)
	
	# Finalização (mantém sistema original)
	finalize_generation()

func determine_terrain_type(rng: RandomNumberGenerator) -> Dictionary:
	"""Determina o tipo de terreno baseado na configuração"""
	var terrain_type_lower = terrainType.to_lower()
	
	# Usa configuração do BiomeManager se disponível
	if biome_manager:
		var config = biome_manager.get_terrain_type_config(terrain_type_lower)
		if not config.is_empty():
			return config
	
	# Sistema original como fallback
	match terrainType:
		"Ilha":
			isIsland = true
			return {"name": "Island", "falloff_strength": 1.0}
		"Continente":
			isIsland = false
			return {"name": "Continent", "falloff_strength": 0.3}
		"Arquipélago":
			isIsland = true
			return {"name": "Archipelago", "falloff_strength": 0.8, "island_count": 5}
		"Auto":
			isIsland = rng.randf() < 0.5
			if isIsland:
				return {"name": "Island", "falloff_strength": 1.0}
			else:
				return {"name": "Continent", "falloff_strength": 0.3}
		_:
			isIsland = false
			return {"name": "Continent", "falloff_strength": 0.3}

func generate_with_advanced_system(terrain_config: Dictionary):
	"""Geração avançada usando sistema modular"""
	print("🚀 Usando sistema avançado de geração")
	
	clear()
	var image = Image.create(mapWidth, mapHeight, true, Image.FORMAT_RGB8)
	var biome_map = {}  # Para debug
	
	for x in range(mapWidth):
		for y in range(mapHeight):
			# Gera todos os parâmetros ambientais
			var height = noise_generator.get_height_at(x, y, terrain_config.get("name", "auto").to_lower(), mapWidth, mapHeight)
			var temperature = noise_generator.get_temperature_at(x, y, mapHeight) if use_temperature else 0.5
			var humidity = noise_generator.get_humidity_at(x, y, height) if use_humidity else 0.5
			
			# Determina bioma baseado em todos os parâmetros
			var biome = biome_manager.get_biome_for_point(height, temperature, humidity)
			var terrain_tile = biome_manager.get_terrain_tile_for_biome(biome)
			
			# Aplica o tile
			var atlas_coords = Vector2i(terrain_tile.get("atlas_coords", [0, 0])[0], terrain_tile.get("atlas_coords", [0, 0])[1])
			var tile_id = terrain_tile.get("tile_id", 0)
			
			set_cell(Vector2i(x, y), 0, atlas_coords)
			image.set_pixel(x, y, Color(float(tile_id) / 7.0, 0, 0))
			
			# Armazena para debug
			if show_debug_info and x % 32 == 0 and y % 32 == 0:
				biome_map[Vector2i(x, y)] = {
					"biome": biome.get("name", "Unknown"),
					"height": height,
					"temperature": temperature,
					"humidity": humidity
				}
	
	# Debug info
	if show_debug_info:
		print_generation_debug(biome_map)
	
	save_map_data(image)

func generate_with_legacy_system(_terrain_config: Dictionary):
	"""Geração usando sistema original para compatibilidade"""
	print("🔄 Usando sistema de compatibilidade")
	
	# Configura ruído original
	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.03
	noise.seed = terrainSeed
	
	clear()
	var image = Image.create(mapWidth, mapHeight, true, Image.FORMAT_RGB8)
	
	for x in range(mapWidth):
		for y in range(mapHeight):
			# Sistema original de altura
			var height = noise.get_noise_2d(x, y)
			height = (height + 1.0) / 2.0
			
			# Aplicação de island falloff original
			if isIsland:
				var dx = float(x - mapWidth / 2.0) / (mapWidth / 2.0)
				var dy = float(y - mapHeight / 2.0) / (mapHeight / 2.0)
				var dist = sqrt(dx * dx + dy * dy)
				height *= clamp(1.0 - dist, 0.0, 1.0)
			
			# Sistema original de determinação de biomas por altura
			var atlas_coord = Vector2i(0, 1)
			var tile_id = 4
			
			if height < oceanThreshold:
				atlas_coord = Vector2i(0, 1)
				tile_id = 4
			elif height < beachThreshold:
				atlas_coord = Vector2i(1, 1)
				tile_id = 5
			elif height < desertThreshold:
				atlas_coord = Vector2i(2, 1)
				tile_id = 6
			elif height < grassThreshold:
				atlas_coord = Vector2i(0, 0)
				tile_id = 0
			elif height < darkGrassThreshold:
				atlas_coord = Vector2i(1, 0)
				tile_id = 1
			elif height < mountainThreshold:
				atlas_coord = Vector2i(2, 0)
				tile_id = 2
			else:
				atlas_coord = Vector2i(3, 0)
				tile_id = 3
			
			set_cell(Vector2i(x, y), 0, atlas_coord)
			image.set_pixel(x, y, Color(float(tile_id) / 7.0, 0, 0))
	
	save_map_data(image)

func save_map_data(image: Image):
	"""Salva mapData.png (sistema original mantido)"""
	position = Vector2(0, 0)
	visible = true
	
	var dir = DirAccess.open("res://")
	if dir and dir.file_exists("res://mapData.png"):
		dir.remove("res://mapData.png")
	
	var error = image.save_png("res://mapData.png")
	if error == OK:
		print("🗺️ mapData.png salvo com sucesso!")
	else:
		print("❌ Falha ao salvar mapData.png, erro: ", error)

func finalize_generation():
	"""Finaliza a geração (sistema original mantido)"""
	# Atualiza label se existir
	var label = get_tree().root.get_node_or_null("Node2D/CanvasLayer/MapTypeLabel")
	if not label:
		label = get_tree().root.get_node_or_null("Main/UI/MapTypeLabel")
	if label:
		label.text = "Tipo: " + terrainType + " → " + ("Ilha" if isIsland else "Continente")
	
	# Notifica o shader
	var shader_terrain = get_tree().root.get_node_or_null("Main/ShaderTerrain")
	if shader_terrain and shader_terrain.has_method("update_texture"):
		print("🎨 Notificando ShaderTerrain para atualizar...")
		await get_tree().create_timer(0.5).timeout
		shader_terrain.update_texture()

func print_generation_debug(biome_map: Dictionary):
	"""Imprime informações de debug da geração"""
	print("\n🔍 === DEBUG GERAÇÃO AVANÇADA ===")
	print("📊 Amostras de biomas:")
	
	for pos in biome_map:
		var data = biome_map[pos]
		print("  ", pos, ": ", data["biome"], " (H:", "%.2f" % data["height"], " T:", "%.2f" % data["temperature"], " U:", "%.2f" % data["humidity"], ")")
	
	print("=== FIM DEBUG ===\n")

func generate_debug_previews():
	"""Gera mapas de preview para debug"""
	if not noise_generator:
		noise_generator = NoiseGenerator.new(terrainSeed if terrainSeed != 0 else 12345)
	
	print("🎨 Gerando previews de debug...")
	
	var preview_size = Vector2i(64, 64)
	
	# Preview de altura
	var height_image = noise_generator.generate_preview_image(preview_size.x, preview_size.y, "height")
	height_image.save_png("res://debug_height_preview.png")
	
	# Preview de temperatura
	if use_temperature:
		var temp_image = noise_generator.generate_preview_image(preview_size.x, preview_size.y, "temperature")
		temp_image.save_png("res://debug_temperature_preview.png")
	
	# Preview de umidade
	if use_humidity:
		var humidity_image = noise_generator.generate_preview_image(preview_size.x, preview_size.y, "humidity")
		humidity_image.save_png("res://debug_humidity_preview.png")
	
	print("✅ Previews salvos em debug_*_preview.png")

# === SISTEMA ORIGINAL MANTIDO ===
func create_automatic_tileset():
	"""Mantém função original de criação de tileset"""
	print("🔧 Criando TileSet com textureAtlas.png...")
	
	var new_tileset = TileSet.new()
	var atlas_source = TileSetAtlasSource.new()
	
	var texture_atlas = load("res://TileSets/textureAtlas.png")
	if not texture_atlas:
		print("❌ ERRO: textureAtlas.png não encontrado em res://TileSets/")
		return
	
	atlas_source.texture = texture_atlas
	atlas_source.texture_region_size = Vector2i(32, 32)
	
	print("✅ textureAtlas.png carregado: ", texture_atlas.get_size())
	
	var tiles_to_create = [
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0),
		Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1)
	]
	
	for atlas_coords in tiles_to_create:
		var tile_pixel_x = atlas_coords.x * 32
		var tile_pixel_y = atlas_coords.y * 32
		
		if tile_pixel_x + 32 <= texture_atlas.get_width() and tile_pixel_y + 32 <= texture_atlas.get_height():
			atlas_source.create_tile(atlas_coords)
			print("✅ Tile criado: ", atlas_coords)
	
	new_tileset.add_source(atlas_source, 0)
	tile_set = new_tileset
	print("✅ TileSet criado automaticamente")

# === MÉTODOS DE COMPATIBILIDADE ===
func generate_terrain():
	GenerateTerrain()

func generate():
	GenerateTerrain()

func regenerate():
	GenerateTerrain()

# === FUNCIONALIDADES AVANÇADAS ===

func get_biome_at_position(x: int, y: int) -> Dictionary:
	"""Retorna o bioma em uma posição específica"""
	if not noise_generator or not biome_manager:
		return {}
	
	var height = noise_generator.get_height_at(x, y, terrainType.to_lower(), mapWidth, mapHeight)
	var temperature = noise_generator.get_temperature_at(x, y, mapHeight) if use_temperature else 0.5
	var humidity = noise_generator.get_humidity_at(x, y, height) if use_humidity else 0.5
	
	return biome_manager.get_biome_for_point(height, temperature, humidity)

func analyze_terrain_composition() -> Dictionary:
	"""Analisa a composição dos biomas no mapa atual"""
	if not biome_manager:
		return {}
	
	var composition = {}
	var sample_size = 50  # Amostragem para performance
	
	@warning_ignore("integer_division")
	for x in range(0.0, mapWidth, mapWidth / sample_size):
		@warning_ignore("integer_division")
		for y in range(0.0, mapHeight, mapHeight / sample_size):
			var biome = get_biome_at_position(x, y)
			var biome_name = biome.get("name", "Unknown")
			
			if biome_name in composition:
				composition[biome_name] += 1
			else:
				composition[biome_name] = 1
	
	return composition

@export var analyze_composition: bool = false:
	set(value):
		analyze_composition = false
		if value:
			var composition = analyze_terrain_composition()
			print("\n🌍 === COMPOSIÇÃO DO TERRENO ===")
			for biome_name in composition:
				var percentage = float(composition[biome_name]) / float(composition.values().reduce(func(a, b): return a + b)) * 100.0
				print("🔹 ", biome_name, ": ", "%.1f" % percentage, "%")
			print("=== FIM COMPOSIÇÃO ===\n")
