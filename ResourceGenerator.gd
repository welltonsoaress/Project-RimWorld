@tool
class_name ResourceGenerator
extends TileMapLayer

# === CONFIGURAÇÕES PRINCIPAIS ===
@export_group("Controles")
@export var generate_resources: bool = false:
	set(value):
		if value:
			generate_resources = false
			generate()

@export var clear_resources: bool = false:
	set(value):
		if value:
			clear_resources = false
			clear()

# === CONFIGURAÇÃO DE FORMAÇÕES ROCHOSAS ===
@export_group("Formações Rochosas")
@export_range(0.0, 0.3) var rock_formation_density: float = 0.08  # Reduzido para evitar saturação
@export_range(5, 50) var min_formation_size: int = 6  # Reduzido
@export_range(15, 100) var max_formation_size: int = 25  # Reduzido
@export_range(0.1, 1.0) var formation_compactness: float = 0.6
@export_range(0.0, 1.0) var edge_roughness: float = 0.4

# === MARGEM DE SEGURANÇA ===
@export_group("Limites do Mapa")
@export_range(1, 10) var map_border_margin: int = 3  # Margem de segurança das bordas

@export_group("Distribuição por Bioma")
@export_range(0.0, 8.0) var mountain_formation_multiplier: float = 4.0
@export_range(0.0, 4.0) var hills_formation_multiplier: float = 2.5
@export_range(0.0, 2.0) var desert_formation_multiplier: float = 1.2
@export_range(0.0, 2.0) var grassland_formation_multiplier: float = 0.8
@export_range(0.0, 2.0) var forest_formation_multiplier: float = 0.6

@export_group("Debug")
@export var debug_generation: bool = false

# === SISTEMA DE RECURSOS ===
var terrain_generator: TileMapLayer
var formation_noise: FastNoiseLite
var detail_noise: FastNoiseLite
var map_width: int = 128
var map_height: int = 128

# Mapa de posições ocupadas para evitar sobreposição
var occupied_positions: Dictionary = {}

# Configuração dos tipos de rochas
var rock_types = {
	"stone": {
		"atlas_coords": Vector2i(2, 0),
		"name": "Stone",
		"color": Color(0.6, 0.6, 0.6),
		"preferred_biomes": ["mountain", "hills", "desert", "grassland", "forest"],
		"formation_chance": 1.0,
		"min_cluster_size": 6,
		"max_cluster_size": 25
	}
}

func _ready():
	print("🏔️ ResourceGenerator iniciado")
	add_to_group("resources")
	
	setup_tileset()
	setup_noise_generators()
	force_correct_positioning()
	
	if not Engine.is_editor_hint():
		await get_tree().process_frame
		await get_tree().create_timer(1.5).timeout
		find_terrain_generator()
		generate()

func setup_noise_generators():
	"""Configura geradores de ruído para formações orgânicas"""
	formation_noise = FastNoiseLite.new()
	formation_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	formation_noise.frequency = 0.035  # Frequência menor para formações maiores
	formation_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	formation_noise.fractal_octaves = 3
	formation_noise.seed = randi()
	
	detail_noise = FastNoiseLite.new()
	detail_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	detail_noise.frequency = 0.15
	detail_noise.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	detail_noise.fractal_octaves = 2
	detail_noise.seed = randi() + 1000

func setup_tileset():
	"""Configura TileSet automaticamente"""
	if tile_set:
		return
	
	var new_tileset = TileSet.new()
	var atlas_source = TileSetAtlasSource.new()
	
	var texture_path = "res://TileSets/ResourcesTileSet.png"
	if not FileAccess.file_exists(texture_path):
		print("❌ Textura de recursos não encontrada:", texture_path)
		return
	
	atlas_source.texture = load(texture_path)
	atlas_source.texture_region_size = Vector2i(32, 32)
	atlas_source.create_tile(Vector2i(2, 0))
	
	new_tileset.add_source(atlas_source, 0)
	tile_set = new_tileset
	print("✅ ResourceGenerator: TileSet configurado")

func force_correct_positioning():
	"""Força posicionamento correto"""
	position = Vector2(0, 0)
	scale = Vector2(2.0, 2.0)
	visible = true
	enabled = true
	z_index = 1

func find_terrain_generator():
	"""Encontra o TerrainGenerator na cena"""
	var terrain_nodes = get_tree().get_nodes_in_group("terrain")
	if terrain_nodes.size() > 0:
		terrain_generator = terrain_nodes[0]
		if "map_width" in terrain_generator:
			map_width = terrain_generator.map_width
		if "map_height" in terrain_generator:
			map_height = terrain_generator.map_height
		print("✅ TerrainGenerator encontrado: ", terrain_generator.get_path())
		print("📏 Dimensões do mapa: ", map_width, "x", map_height)

func generate():
	"""Gera formações rochosas - VERSÃO CORRIGIDA COM LIMITES RÍGIDOS"""
	print("🏔️ Gerando formações rochosas com limites rígidos...")
	clear()
	occupied_positions.clear()
	
	if not terrain_generator:
		find_terrain_generator()
		if not terrain_generator:
			print("❌ Impossível gerar sem TerrainGenerator!")
			return
	
	force_correct_positioning()
	
	print("🗺️ Gerando formações em mapa ", map_width, "x", map_height)
	print("🛡️ Margem de segurança: ", map_border_margin, " tiles das bordas")
	
	# Gera formações de cada tipo de rocha
	for rock_type_name in rock_types:
		generate_rock_formations_safe(rock_type_name)
	
	print("✅ Formações rochosas geradas com segurança!")
	call_deferred("final_positioning_check")

func generate_rock_formations_safe(rock_type_name: String):
	"""Gera formações de um tipo específico de rocha COM LIMITES RÍGIDOS"""
	var rock_config = rock_types[rock_type_name]
	var placed_rocks = {}
	var formations_created = 0
	var attempts_made = 0
	var out_of_bounds_attempts = 0
	
	print("🪨 Gerando formações de ", rock_type_name, "...")
	
	# CORREÇÃO CRÍTICA: Calcula área válida considerando margem
	var valid_min_x = map_border_margin
	var valid_max_x = map_width - map_border_margin - 1
	var valid_min_y = map_border_margin
	var valid_max_y = map_height - map_border_margin - 1
	
	print("📐 Área válida: x[", valid_min_x, "-", valid_max_x, "] y[", valid_min_y, "-", valid_max_y, "]")
	
	# Reduz tentativas para evitar saturação
	var base_attempts = int((valid_max_x - valid_min_x) * (valid_max_y - valid_min_y) * rock_formation_density * 0.015)
	print("🎯 Tentativas de geração: ", base_attempts)
	
	# Busca pontos de ancoragem para formações DENTRO DOS LIMITES
	for attempt in range(base_attempts):
		attempts_made += 1
		
		# CORREÇÃO PRINCIPAL: Garante que anchor está SEMPRE dentro dos limites
		var anchor_x = randi_range(valid_min_x, valid_max_x)
		var anchor_y = randi_range(valid_min_y, valid_max_y)
		var anchor_pos = Vector2i(anchor_x, anchor_y)
		
		# Verificação dupla de segurança
		if not is_position_within_safe_bounds(anchor_pos):
			out_of_bounds_attempts += 1
			continue
		
		if not is_valid_formation_anchor_safe(anchor_pos, rock_type_name):
			continue
		
		var biome = get_biome_at_position(anchor_pos)
		var biome_multiplier = get_biome_multiplier(biome)
		
		if biome_multiplier < 0.1:
			biome_multiplier = 0.3
		
		var formation_size = calculate_formation_size(biome_multiplier, rock_config)
		
		# Gera a formação rochosa COM LIMITES
		var formation_rocks = generate_single_formation_safe(
			anchor_pos, 
			formation_size, 
			rock_config,
			placed_rocks
		)
		
		if formation_rocks.size() > 0:
			formations_created += 1
			
			# Adiciona posições ao mapa global de ocupação
			for rock_pos in formation_rocks:
				occupied_positions[str(rock_pos)] = true
	
	print("📊 ", rock_type_name, " - Tentativas:", attempts_made, " Formações:", formations_created)
	if out_of_bounds_attempts > 0:
		print("⚠️ Tentativas fora dos limites: ", out_of_bounds_attempts)

func is_position_within_safe_bounds(pos: Vector2i) -> bool:
	"""Verifica se a posição está dentro dos limites seguros do mapa"""
	return (pos.x >= map_border_margin and 
			pos.x < map_width - map_border_margin and 
			pos.y >= map_border_margin and 
			pos.y < map_height - map_border_margin)

func is_valid_formation_anchor_safe(pos: Vector2i, rock_type_name: String) -> bool:
	"""Verificação de âncora válida COM VERIFICAÇÃO RIGOROSA DE LIMITES"""
	if not terrain_generator:
		return false
	
	# VERIFICAÇÃO PRINCIPAL: Limites rígidos do mapa
	if not is_position_within_safe_bounds(pos):
		return false
	
	# Verifica se já tem recurso
	if get_cell_source_id(pos) != -1:
		return false
	
	# Verifica bioma - nunca gera em água
	var biome = get_biome_at_position(pos)
	if biome == "ocean":
		return false
	
	# Aceita todos os biomas terrestres
	var terrestrial_biomes = ["mountain", "hills", "desert", "grassland", "forest", "beach"]
	return biome in terrestrial_biomes

func generate_single_formation_safe(anchor_pos: Vector2i, target_size: int, rock_config: Dictionary, placed_rocks: Dictionary) -> Array:
	"""Gera uma única formação rochosa COM VERIFICAÇÃO DE LIMITES"""
	var formation_rocks = []
	var pending_positions = [anchor_pos]
	var formation_id = str(anchor_pos.x) + "_" + str(anchor_pos.y)
	var iterations = 0
	var max_iterations = target_size * 2  # Reduzido para evitar travamento
	var rejected_out_of_bounds = 0
	
	while pending_positions.size() > 0 and formation_rocks.size() < target_size and iterations < max_iterations:
		iterations += 1
		var current_pos = pending_positions.pop_front()
		
		if str(current_pos) in placed_rocks:
			continue
		
		# VERIFICAÇÃO CRÍTICA: Sempre verifica limites
		if not is_position_within_safe_bounds(current_pos):
			rejected_out_of_bounds += 1
			continue
		
		if not is_valid_rock_position_safe(current_pos):
			continue
		
		var noise_value = formation_noise.get_noise_2d(current_pos.x, current_pos.y)
		var detail_value = detail_noise.get_noise_2d(current_pos.x, current_pos.y)
		
		var distance_from_anchor = anchor_pos.distance_to(Vector2(current_pos.x, current_pos.y))
		var size_factor = 1.0 - (distance_from_anchor / (target_size * 0.8))
		size_factor = clamp(size_factor, 0.0, 1.0)
		
		var placement_chance = size_factor * formation_compactness
		placement_chance += (noise_value + 1.0) * 0.3
		placement_chance += (detail_value + 1.0) * 0.15
		placement_chance = clamp(placement_chance, 0.0, 1.0)
		
		if randf() < placement_chance:
			set_cell(current_pos, 0, rock_config["atlas_coords"])
			placed_rocks[str(current_pos)] = formation_id
			formation_rocks.append(current_pos)
			
			add_expansion_candidates_safe(current_pos, pending_positions, placed_rocks, formation_rocks.size(), target_size)
	
	if rejected_out_of_bounds > 0 and debug_generation:
		print("⚠️ Formação em ", anchor_pos, ": ", rejected_out_of_bounds, " posições rejeitadas por estar fora dos limites")
	
	return formation_rocks

func is_valid_rock_position_safe(pos: Vector2i) -> bool:
	"""Verificação de posição válida para rocha COM LIMITES RÍGIDOS"""
	if not terrain_generator:
		return false
	
	# VERIFICAÇÃO PRINCIPAL: Limites rígidos do mapa
	if not is_position_within_safe_bounds(pos):
		return false
	
	# Verifica se já há recurso
	if get_cell_source_id(pos) != -1:
		return false
	
	# Verifica bioma - nunca permite água
	var biome = get_biome_at_position(pos)
	if biome == "ocean":
		return false
	
	return biome in ["mountain", "hills", "desert", "grassland", "forest", "beach"]

func add_expansion_candidates_safe(center_pos: Vector2i, pending_positions: Array, placed_rocks: Dictionary, current_size: int, target_size: int):
	"""Adiciona candidatos para expansão COM VERIFICAÇÃO DE LIMITES"""
	var expansion_patterns = [
		[Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)],
		[Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1)],
		[Vector2i(2, 0), Vector2i(-2, 0), Vector2i(0, 2), Vector2i(0, -2)]
	]
	
	var patterns_to_use = []
	if current_size < target_size * 0.3:
		patterns_to_use = [0]
	elif current_size < target_size * 0.7:
		patterns_to_use = [0, 1]
	else:
		patterns_to_use = [0, 1, 2]
	
	for pattern_index in patterns_to_use:
		var chosen_pattern = expansion_patterns[pattern_index]
		
		for offset in chosen_pattern:
			var new_pos = center_pos + offset
			
			# VERIFICAÇÃO CRÍTICA: Sempre verifica limites antes de adicionar
			if not is_position_within_safe_bounds(new_pos):
				continue
			
			if str(new_pos) in placed_rocks or new_pos in pending_positions:
				continue
			
			var add_chance = 1.0 - (edge_roughness * 0.5)
			if randf() < add_chance:
				pending_positions.append(new_pos)

func calculate_formation_size(biome_multiplier: float, rock_config: Dictionary) -> int:
	"""Calcula tamanho da formação"""
	var base_size = lerp(float(min_formation_size), float(max_formation_size), randf())
	var adjusted_size = base_size * biome_multiplier
	adjusted_size = max(adjusted_size, float(min_formation_size))
	
	var size_variation = randf_range(0.8, 1.2)
	adjusted_size *= size_variation
	
	return int(clamp(adjusted_size, rock_config["min_cluster_size"], rock_config["max_cluster_size"]))

func get_biome_at_position(pos: Vector2i) -> String:
	"""Obtém bioma em uma posição específica"""
	if not terrain_generator:
		return "grassland"
	
	if terrain_generator.has_method("get_biome_at_position"):
		return terrain_generator.get_biome_at_position(pos.x, pos.y)
	else:
		var terrain_tile = terrain_generator.get_cell_atlas_coords(pos)
		return get_biome_from_terrain_tile(terrain_tile)

func get_biome_from_terrain_tile(terrain_tile: Vector2i) -> String:
	"""Converte tile de terreno em nome de bioma"""
	match terrain_tile:
		Vector2i(0, 1): return "ocean"
		Vector2i(1, 1): return "beach"
		Vector2i(2, 1): return "desert"
		Vector2i(0, 0): return "grassland"
		Vector2i(1, 0): return "forest"
		Vector2i(2, 0): return "hills"
		Vector2i(3, 0): return "mountain"
		_: return "grassland"

func get_biome_multiplier(biome: String) -> float:
	"""Retorna multiplicador de formação para um bioma"""
	match biome:
		"mountain": return mountain_formation_multiplier
		"hills": return hills_formation_multiplier
		"desert": return desert_formation_multiplier
		"grassland": return grassland_formation_multiplier
		"forest": return forest_formation_multiplier
		"beach": return desert_formation_multiplier * 0.7
		"ocean": return 0.0
		_: return grassland_formation_multiplier

func get_occupied_positions() -> Dictionary:
	"""Retorna mapa de posições ocupadas por recursos"""
	return occupied_positions

func final_positioning_check():
	"""Verificação final de posicionamento"""
	if position != Vector2(0, 0):
		position = Vector2(0, 0)
	if scale != Vector2(2.0, 2.0):
		scale = Vector2(2.0, 2.0)
	if z_index != 1:
		z_index = 1
	
	queue_redraw()

func _process(_delta):
	if not Engine.is_editor_hint():
		if position != Vector2(0, 0) or scale != Vector2(2.0, 2.0):
			position = Vector2(0, 0)
			scale = Vector2(2.0, 2.0)
