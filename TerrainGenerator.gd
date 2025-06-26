@tool
class_name TerrainGenerator
extends TileMapLayer

# === CONFIGURAÇÕES PRINCIPAIS ===
@export_group("Configuração do Mapa")
@export var map_width: int = 128
@export var map_height: int = 128
@export var terrain_seed: int = 0

@export_group("Tipo de Terreno")
@export_enum("Auto", "Ilha", "Continente", "Arquipélago", "Península", "Desertão")
var terrain_type: String = "Auto"

@export_group("Qualidade do Terreno")
@export_range(1, 8) var noise_octaves: int = 4
@export_range(0.001, 0.1) var noise_frequency: float = 0.03
@export_range(0.0, 2.0) var terrain_smoothness: float = 1.0

@export_group("Controles")
@export var generate_terrain: bool = false:
	set(value):
		if value:
			generate_terrain = false
			GenerateTerrain()

@export var clear_terrain: bool = false:
	set(value):
		if value:
			clear_terrain = false
			clear()

# === THRESHOLDS ORIGINAIS (COMO NO CÓDIGO FUNCIONAL) ===
@export var oceanThreshold := 0.25
@export var beachThreshold := 0.35
@export var desertThreshold := 0.45
@export var grassThreshold := 0.55
@export var darkGrassThreshold := 0.7
@export var mountainThreshold := 0.85

# === SISTEMA DE RUÍDO ===
var noise: FastNoiseLite = null
var isIsland: bool = false

func _ready():
	print("🌍 TerrainGenerator iniciado")
	
	# CORREÇÃO: Adiciona à grupo para facilitar busca
	add_to_group("terrain")
	
	setup_tileset()
	
	# CORREÇÃO: Força configurações visuais
	visible = true
	enabled = true
	z_index = 0
	scale = Vector2(2.0, 2.0)  # CORREÇÃO: Força escala 2.0
	position = Vector2(0, 0)
	
	print("✅ TerrainMap configurado: visible=", visible, " scale=", scale, " z_index=", z_index)
	
	if not Engine.is_editor_hint():
		await get_tree().process_frame
		GenerateTerrain()

func setup_tileset():
	"""Configura o TileSet automaticamente"""
	if tile_set:
		return
	
	var new_tileset = TileSet.new()
	var atlas_source = TileSetAtlasSource.new()
	
	# Carrega textura atlas
	var texture_path = "res://TileSets/textureAtlas.png"
	if not FileAccess.file_exists(texture_path):
		print("❌ textureAtlas.png não encontrado em res://TileSets/")
		return
	
	atlas_source.texture = load(texture_path)
	atlas_source.texture_region_size = Vector2i(32, 32)
	
	# Cria tiles para cada tipo de terreno
	var tile_coords = [
		Vector2i(0, 0),  # Grama
		Vector2i(1, 0),  # Floresta
		Vector2i(2, 0),  # Colinas
		Vector2i(3, 0),  # Montanhas
		Vector2i(0, 1),  # Água
		Vector2i(1, 1),  # Praia
		Vector2i(2, 1)   # Deserto
	]
	
	for coords in tile_coords:
		atlas_source.create_tile(coords)
	
	new_tileset.add_source(atlas_source, 0)
	tile_set = new_tileset
	
	print("✅ TileSet configurado automaticamente")

func GenerateTerrain():
	"""CORREÇÃO CRÍTICA: Baseado no código funcional original"""
	print("🌍 Gerando terreno procedural...")
	
	# Verifica se tile_set existe
	if not tile_set:
		print("⚠️ TileSet não configurado, criando...")
		setup_tileset()
		if not tile_set:
			print("❌ Falha ao criar TileSet!")
			return
	
	var rng = RandomNumberGenerator.new()
	
	# CORREÇÃO CRÍTICA: Reset da seed igual ao código funcional
	terrain_seed = 0  # FORÇA RESET para aleatoriedade a cada geração
	
	if terrain_seed == 0:
		rng.randomize()
		terrain_seed = rng.randi()
		print("🌱 Nova semente gerada: ", terrain_seed)
	else:
		rng.set_seed(terrain_seed)
		print("🌱 Usando semente fixa: ", terrain_seed)
	
	# CORREÇÃO: Determina tipo de terreno igual ao original
	match terrain_type:
		"Ilha":
			isIsland = true
		"Continente":
			isIsland = false
		"Auto":
			isIsland = rng.randf() < 0.5
		"Arquipélago":
			isIsland = true
		"Península":
			isIsland = false
		"Desertão":
			isIsland = false
	print("🔀 Terreno: " + ("Ilha" if isIsland else "Continente"))
	
	# CORREÇÃO: Configuração de ruído com parâmetros exportados
	noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = noise_frequency  # Usa propriedade exportada
	noise.seed = terrain_seed
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = noise_octaves  # Usa propriedade exportada
	print("📊 Ruído configurado com semente: ", noise.seed)
	
	clear()
	
	# CORREÇÃO CRÍTICA: Remove mapData.png antigo ANTES de gerar
	force_remove_old_mapdata()
	await get_tree().process_frame
	
	var image = Image.create(map_width, map_height, true, Image.FORMAT_RGB8)
	
	for x in range(map_width):
		for y in range(map_height):
			var height = noise.get_noise_2d(x, y)
			height = (height + 1.0) / 2.0
			
			# CORREÇÃO: Aplicação de falloff de ilha igual ao original
			if isIsland:
				var dx = float(x - map_width / 2.0) / (map_width / 2.0)
				var dy = float(y - map_height / 2.0) / (map_height / 2.0)
				var dist = sqrt(dx * dx + dy * dy)
				height *= clamp(1.0 - dist, 0.0, 1.0)
			
			# CORREÇÃO: Mapeamento direto igual ao código original
			var atlas_coord = Vector2i(0, 1)  # Água por padrão
			var tile_id = 4  # Água (índice 4 no atlas)
			
			if height < oceanThreshold:
				atlas_coord = Vector2i(0, 1)  # Água
				tile_id = 4
			elif height < beachThreshold:
				atlas_coord = Vector2i(1, 1)  # Areia de praia
				tile_id = 5
			elif height < desertThreshold:
				atlas_coord = Vector2i(2, 1)  # Areia do deserto
				tile_id = 6
			elif height < grassThreshold:
				atlas_coord = Vector2i(0, 0)  # Grama
				tile_id = 0
			elif height < darkGrassThreshold:
				atlas_coord = Vector2i(1, 0)  # Grama escura
				tile_id = 1
			elif height < mountainThreshold:
				atlas_coord = Vector2i(2, 0)  # Terra
				tile_id = 2
			else:
				atlas_coord = Vector2i(3, 0)  # Pedra
				tile_id = 3
			
			set_cell(Vector2i(x, y), 0, atlas_coord)
			image.set_pixel(x, y, Color(float(tile_id) / 7.0, 0, 0))
	
	# CORREÇÃO: Garante posição igual ao original
	position = Vector2(0, 0)
	print("🔄 TerrainMap posicionado em: ", position)
	
	visible = true  # Garante que o TileMapLayer seja visível
	
	# CORREÇÃO CRÍTICA: Salva mapData.png igual ao original
	save_map_data_original_method(image)
	
	# CORREÇÃO: Força escala 2.0 após geração
	scale = Vector2(2.0, 2.0)
	
	print("✅ Terreno gerado com sucesso!")

func force_remove_old_mapdata():
	"""Remove mapData.png antigo para forçar atualização"""
	var dir = DirAccess.open("res://")
	if dir and dir.file_exists("mapData.png"):
		var success = dir.remove("mapData.png")
		if success == OK:
			print("🗑️ mapData.png antigo removido")
		else:
			print("⚠️ Falha ao remover mapData.png antigo")

func save_map_data_original_method(image: Image):
	"""CORREÇÃO CRÍTICA: Salva mapData.png usando método original"""
	# Remove arquivo antigo primeiro (igual ao código original)
	var dir = DirAccess.open("res://")
	if dir and dir.file_exists("res://mapData.png"):
		dir.remove("res://mapData.png")
		print("🗑️ mapData.png removido antes de salvar novo")
	
	# Salva nova imagem
	var error = image.save_png("res://mapData.png")
	if error == OK:
		print("🗺️ mapData.png salvo com sucesso! - Primeiros pixels: ", image.get_pixel(0, 0), ", ", image.get_pixel(1, 0))
		
		# CORREÇÃO CRÍTICA: Força reload da imagem importada
		force_reimport_mapdata()
		
		# CORREÇÃO: Notifica outros sistemas
		call_deferred("notify_terrain_updated")
	else:
		print("❌ Falha ao salvar mapData.png, erro: ", error)

func force_reimport_mapdata():
	"""CORREÇÃO: Força reimportação do mapData.png no sistema de assets"""
	# No Godot 4, força refresh do filesystem
	if Engine.is_editor_hint():
		# Se estiver no editor, força refresh
		var filesystem = EditorInterface.get_resource_filesystem()
		if filesystem:
			filesystem.scan()
			filesystem.reimport_files(["res://mapData.png"])
	else:
		# Em runtime, força clear do cache
		ResourceLoader.set_abort_on_missing_resources(false)
		if ResourceLoader.has_cached("res://mapData.png"):
			print("🔄 Limpando cache do mapData.png")

func notify_terrain_updated():
	"""Notifica outros sistemas que o terreno foi atualizado"""
	# Aguarda um pouco mais para garantir que o arquivo foi escrito
	await get_tree().create_timer(0.8).timeout  # AUMENTADO
	
	# Notifica shader para recarregar
	var shader_controller = get_node_or_null("../../ShaderTerrain")
	if not shader_controller:
		shader_controller = get_tree().get_first_node_in_group("shader")
	
	if shader_controller and shader_controller.has_method("update_texture"):
		print("🎯 Notificando shader para atualizar...")
		shader_controller.call_deferred("update_texture")
	
	# Atualiza label se existir (igual ao original)
	var label = get_tree().root.get_node_or_null("Node2D/CanvasLayer/MapTypeLabel")
	if not label:
		label = get_tree().root.get_node_or_null("Main/UI/MapTypeLabel")
	if label:
		label.text = "Tipo: " + terrain_type + " → " + ("Ilha" if isIsland else "Continente")

# === FUNÇÃO PARA OBTER BIOMA EM POSIÇÃO ESPECÍFICA ===
func get_biome_at_position(x: int, y: int) -> String:
	"""Retorna o bioma em uma posição específica"""
	if x < 0 or x >= map_width or y < 0 or y >= map_height:
		return "ocean"
	
	var tile_coords = get_cell_atlas_coords(Vector2i(x, y))
	return get_biome_for_tile_coords(tile_coords)

func get_biome_for_tile_coords(coords: Vector2i) -> String:
	"""Converte coordenadas do tile em nome do bioma"""
	if coords == Vector2i(0, 1): return "ocean"
	if coords == Vector2i(1, 1): return "beach"
	if coords == Vector2i(2, 1): return "desert"
	if coords == Vector2i(0, 0): return "grassland"
	if coords == Vector2i(1, 0): return "forest"
	if coords == Vector2i(2, 0): return "hills"
	if coords == Vector2i(3, 0): return "mountain"
	return "grassland"

# === MÉTODOS DE COMPATIBILIDADE ===
func force_generate_terrain():
	GenerateTerrain()

func generate():
	GenerateTerrain()

func regenerate():
	GenerateTerrain()
