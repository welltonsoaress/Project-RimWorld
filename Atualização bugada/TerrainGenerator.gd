@tool
class_name TerrainGenerator
extends TileMapLayer

# === CONFIGURAÇÕES PRINCIPAIS ===
@export_group("Configuração do Mapa")
@export var map_width: int = 128
@export var map_height: int = 128
@export var terrain_seed: int = 0

@export_group("Tipo de Terreno")
@export_enum("Continente", "Ilha", "Arquipélago", "Península") 
var terrain_type: String = "Continente"

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

# === CONFIGURAÇÕES PROFISSIONAIS TIPO RIMWORLD ===
@export_group("Parâmetros Realistas")
@export_range(0.0, 1.0) var ocean_coverage: float = 0.15
@export_range(0.0, 1.0) var mountain_coverage: float = 0.12
@export_range(0.0, 1.0) var forest_density: float = 0.25
@export_range(0.0, 1.0) var desert_chance: float = 0.08

@export_group("Qualidade do Terreno")
@export_range(1, 8) var noise_octaves: int = 4
@export_range(0.001, 0.1) var noise_frequency: float = 0.02
@export_range(0.0, 2.0) var terrain_smoothness: float = 1.0

# === THRESHOLDS CALCULADOS DINAMICAMENTE ===
var ocean_threshold: float
var beach_threshold: float
var grassland_threshold: float
var forest_threshold: float
var hills_threshold: float
var mountain_threshold: float

# === SISTEMA DE RUÍDO ===
var height_noise: FastNoiseLite
var temperature_noise: FastNoiseLite
var humidity_noise: FastNoiseLite

func _ready():
	print("🌍 TerrainGenerator iniciado")
	
	# CORREÇÃO: Adiciona à grupo para facilitar busca
	add_to_group("terrain")
	
	setup_tileset()
	calculate_dynamic_thresholds()
	
	# CORREÇÃO: Força configurações visuais
	visible = true
	enabled = true
	z_index = 0
	scale = Vector2(1.0, 1.0)
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

func calculate_dynamic_thresholds():
	"""Calcula thresholds dinâmicos baseados nos parâmetros"""
	ocean_threshold = ocean_coverage
	beach_threshold = ocean_threshold + 0.05
	
	# CORREÇÃO: Garante que todos os thresholds estejam entre 0-1
	var remaining_land = 1.0 - beach_threshold
	
	# Distribui o terreno restante proporcionalmente
	grassland_threshold = beach_threshold + (remaining_land * 0.35)
	forest_threshold = grassland_threshold + (remaining_land * forest_density * 0.6)
	hills_threshold = forest_threshold + (remaining_land * 0.15)
	mountain_threshold = min(0.95, hills_threshold + (remaining_land * mountain_coverage * 0.5))
	
	print("🎯 Thresholds calculados:")
	print("  Ocean: ", "%.3f" % ocean_threshold)
	print("  Beach: ", "%.3f" % beach_threshold)
	print("  Grass: ", "%.3f" % grassland_threshold)
	print("  Forest: ", "%.3f" % forest_threshold)
	print("  Hills: ", "%.3f" % hills_threshold)
	print("  Mountain: ", "%.3f" % mountain_threshold)

func setup_noise():
	"""Configura geradores de ruído profissionais"""
	var seed_value = terrain_seed if terrain_seed != 0 else randi()
	
	# Ruído de altura principal
	height_noise = FastNoiseLite.new()
	height_noise.seed = seed_value
	height_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	height_noise.frequency = noise_frequency
	height_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	height_noise.fractal_octaves = noise_octaves
	height_noise.fractal_lacunarity = 2.0
	height_noise.fractal_gain = 0.5
	
	# Ruído de temperatura (varia com latitude)
	temperature_noise = FastNoiseLite.new()
	temperature_noise.seed = seed_value + 1000
	temperature_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	temperature_noise.frequency = noise_frequency * 0.7
	temperature_noise.fractal_octaves = 3
	
	# Ruído de umidade
	humidity_noise = FastNoiseLite.new()
	humidity_noise.seed = seed_value + 2000
	humidity_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	humidity_noise.frequency = noise_frequency * 0.8
	humidity_noise.fractal_octaves = 3
	
	print("🌀 Geradores de ruído configurados com seed: ", seed_value)

func GenerateTerrain():
	"""Função principal de geração - CORRIGIDA E PROFISSIONAL"""
	print("🚀 Gerando terreno profissional tipo RimWorld...")
	
	clear()
	setup_noise()
	calculate_dynamic_thresholds()
	
	var terrain_data = generate_height_map()
	apply_terrain_type_modifications(terrain_data)
	place_terrain_tiles(terrain_data)
	save_map_data(terrain_data)
	
	print("✅ Terreno gerado com sucesso!")

func generate_height_map() -> Array:
	"""Gera mapa de altura base"""
	var terrain_data = []
	
	for x in range(map_width):
		terrain_data.append([])
		for y in range(map_height):
			# Altura base do ruído
			var height = height_noise.get_noise_2d(x, y)
			height = (height + 1.0) / 2.0  # Normaliza 0-1
			
			# Temperatura baseada na latitude
			var latitude_factor = abs(float(y) / float(map_height) - 0.5) * 2.0
			var temp_noise = temperature_noise.get_noise_2d(x, y)
			var temperature = ((temp_noise + 1.0) / 2.0) * (1.0 - latitude_factor * 0.6)
			
			# Umidade
			var humidity = (humidity_noise.get_noise_2d(x, y) + 1.0) / 2.0
			
			# Aplica suavização se configurada
			if terrain_smoothness > 0:
				height = apply_smoothing(height, x, y)
			
			terrain_data[x].append({
				"height": height,
				"temperature": temperature,
				"humidity": humidity,
				"biome": ""
			})
	
	return terrain_data

func apply_smoothing(height: float, x: int, y: int) -> float:
	"""Aplica suavização ao terreno"""
	var smooth_factor = terrain_smoothness * 0.1
	var neighbors = 0
	var total_height = height
	
	# Verifica vizinhos para suavização
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			var nx = x + dx
			var ny = y + dy
			if nx >= 0 and nx < map_width and ny >= 0 and ny < map_height and (dx != 0 or dy != 0):
				var neighbor_height = height_noise.get_noise_2d(nx, ny)
				neighbor_height = (neighbor_height + 1.0) / 2.0
				total_height += neighbor_height * smooth_factor
				neighbors += 1
	
	return total_height / (1.0 + neighbors * smooth_factor)

func apply_terrain_type_modifications(terrain_data: Array):
	"""Aplica modificações baseadas no tipo de terreno"""
	match terrain_type:
		"Ilha":
			apply_island_falloff(terrain_data)
		"Arquipélago":
			apply_archipelago_pattern(terrain_data)
		"Península":
			apply_peninsula_pattern(terrain_data)
		"Continente":
			apply_continental_pattern(terrain_data)

func apply_island_falloff(terrain_data: Array):
	"""Aplica falloff circular para criar ilha"""
	var center_x = map_width / 2.0
	var center_y = map_height / 2.0
	var max_distance = min(center_x, center_y) * 0.8
	
	for x in range(map_width):
		for y in range(map_height):
			var dx = x - center_x
			var dy = y - center_y
			var distance = sqrt(dx * dx + dy * dy)
			
			var falloff = 1.0 - clamp(distance / max_distance, 0.0, 1.0)
			falloff = pow(falloff, 1.5)  # Curva mais suave
			
			terrain_data[x][y]["height"] *= falloff

func apply_archipelago_pattern(terrain_data: Array):
	"""Cria padrão de arquipélago com múltiplas ilhas"""
	var island_centers = [
		Vector2(map_width * 0.3, map_height * 0.3),
		Vector2(map_width * 0.7, map_height * 0.3),
		Vector2(map_width * 0.5, map_height * 0.7),
		Vector2(map_width * 0.2, map_height * 0.8),
		Vector2(map_width * 0.8, map_height * 0.8)
	]
	
	for x in range(map_width):
		for y in range(map_height):
			var max_influence = 0.0
			
			for center in island_centers:
				var dx = x - center.x
				var dy = y - center.y
				var distance = sqrt(dx * dx + dy * dy)
				var influence = 1.0 - clamp(distance / (min(map_width, map_height) * 0.2), 0.0, 1.0)
				max_influence = max(max_influence, influence)
			
			terrain_data[x][y]["height"] *= max_influence

func apply_peninsula_pattern(terrain_data: Array):
	"""Cria padrão de península"""
	for x in range(map_width):
		for y in range(map_height):
			var edge_distance = min(x, map_width - x, y, map_height - y)
			var falloff = clamp(float(edge_distance) / (min(map_width, map_height) * 0.15), 0.0, 1.0)
			
			# Conecta uma das bordas (simula conexão com continente)
			if y > map_height * 0.8:
				falloff = 1.0
			
			terrain_data[x][y]["height"] *= falloff

func apply_continental_pattern(terrain_data: Array):
	"""Aplica padrão continental com bordas oceânicas"""
	for x in range(map_width):
		for y in range(map_height):
			var edge_distance = min(x, map_width - x, y, map_height - y)
			var falloff = clamp(float(edge_distance) / (min(map_width, map_height) * 0.1), 0.0, 1.0)
			falloff = pow(falloff, 0.5)  # Falloff suave
			
			terrain_data[x][y]["height"] = terrain_data[x][y]["height"] * 0.7 + falloff * 0.3

func place_terrain_tiles(terrain_data: Array):
	"""Coloca tiles de terreno baseado nos dados gerados"""
	var biome_counts = {}
	
	for x in range(map_width):
		for y in range(map_height):
			var data = terrain_data[x][y]
			var height = data["height"]
			var temperature = data["temperature"]
			var humidity = data["humidity"]
			
			var biome = determine_biome(height, temperature, humidity)
			var tile_coords = get_tile_coords_for_biome(biome)
			
			set_cell(Vector2i(x, y), 0, tile_coords)
			terrain_data[x][y]["biome"] = biome
			
			# Conta biomas para estatísticas
			if biome in biome_counts:
				biome_counts[biome] += 1
			else:
				biome_counts[biome] = 1
	
	print_biome_statistics(biome_counts)

func determine_biome(height: float, temperature: float, humidity: float) -> String:
	"""Determina bioma baseado em altura, temperatura e umidade - SISTEMA REALISTA"""
	
	# Primeiro, verifica água
	if height < ocean_threshold:
		return "ocean"
	
	# Praia próxima à água
	if height < beach_threshold:
		return "beach"
	
	# CORREÇÃO: Para terreno alto, sempre considera montanhas primeiro
	if height > mountain_threshold:
		return "mountain"
	
	if height > hills_threshold:
		# Deserto em colinas quentes e secas
		if temperature > 0.7 and humidity < 0.3:
			return "desert"
		return "hills"
	
	# CORREÇÃO: Terreno médio - usa temperatura e umidade
	if height > forest_threshold:
		# Florestas em áreas úmidas
		if humidity > 0.5 and temperature > 0.2 and temperature < 0.8:
			return "forest"
		# Deserto em áreas secas e quentes
		elif temperature > 0.8 and humidity < 0.2:
			return "desert"
		return "grassland"
	
	# Terreno baixo
	if temperature > 0.8 and humidity < 0.2:
		return "desert"
	
	if humidity > 0.6 and temperature > 0.3 and temperature < 0.8:
		return "forest"
	
	return "grassland"

func get_tile_coords_for_biome(biome: String) -> Vector2i:
	"""Retorna coordenadas do tile para cada bioma"""
	match biome:
		"ocean": return Vector2i(0, 1)
		"beach": return Vector2i(1, 1)
		"desert": return Vector2i(2, 1)
		"grassland": return Vector2i(0, 0)
		"forest": return Vector2i(1, 0)
		"hills": return Vector2i(2, 0)
		"mountain": return Vector2i(3, 0)
		_: return Vector2i(0, 0)

func save_map_data(terrain_data: Array):
	"""Salva dados do mapa para o shader"""
	var image = Image.create(map_width, map_height, false, Image.FORMAT_RGB8)
	
	for x in range(map_width):
		for y in range(map_height):
			var biome = terrain_data[x][y]["biome"]
			var tile_id = get_tile_id_for_biome(biome)
			var color = Color(float(tile_id) / 7.0, 0, 0)
			image.set_pixel(x, y, color)
	
	var error = image.save_png("res://mapData.png")
	if error == OK:
		print("✅ mapData.png salvo com sucesso")
		
		# CORREÇÃO: Notifica outros sistemas que o terreno foi atualizado
		notify_terrain_updated()
	else:
		print("❌ Erro ao salvar mapData.png: ", error)

func notify_terrain_updated():
	"""Notifica outros sistemas que o terreno foi atualizado"""
	# Notifica shader para recarregar
	var shader_controller = get_node_or_null("../../ShaderTerrain")
	if not shader_controller:
		shader_controller = get_tree().get_first_node_in_group("shader")
	
	if shader_controller and shader_controller.has_method("update_texture"):
		print("🎯 Notificando shader para atualizar...")
		shader_controller.call_deferred("update_texture")
	
	# Notifica outros geradores que o terreno mudou
	var resource_generator = get_node_or_null("../../Resource/ResourceMap")
	if resource_generator and resource_generator.has_method("find_terrain_generator"):
		resource_generator.terrain_generator = null  # Força re-busca
		resource_generator.call_deferred("find_terrain_generator")

func get_tile_id_for_biome(biome: String) -> int:
	"""Retorna ID numérico do tile para cada bioma"""
	match biome:
		"grassland": return 0
		"forest": return 1
		"hills": return 2
		"mountain": return 3
		"ocean": return 4
		"beach": return 5
		"desert": return 6
		_: return 0

func print_biome_statistics(biome_counts: Dictionary):
	"""Imprime estatísticas dos biomas gerados"""
	var total_tiles = map_width * map_height
	
	print("\n📊 === ESTATÍSTICAS DO TERRENO ===")
	for biome in biome_counts:
		var count = biome_counts[biome]
		var percentage = float(count) / float(total_tiles) * 100.0
		print("🔹 ", biome.capitalize(), ": ", "%.1f" % percentage, "% (", count, " tiles)")
	print("=== TOTAL: ", total_tiles, " tiles ===\n")

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
