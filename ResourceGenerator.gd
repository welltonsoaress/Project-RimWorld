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
@export_range(0.0, 0.3) var rock_formation_density: float = 0.12  # AUMENTADO
@export_range(5, 50) var min_formation_size: int = 8
@export_range(15, 200) var max_formation_size: int = 45
@export_range(0.1, 1.0) var formation_compactness: float = 0.7
@export_range(0.0, 1.0) var edge_roughness: float = 0.3

@export_group("Distribuição por Bioma")
@export_range(0.0, 8.0) var mountain_formation_multiplier: float = 5.0
@export_range(0.0, 4.0) var hills_formation_multiplier: float = 3.0
@export_range(0.0, 2.0) var desert_formation_multiplier: float = 1.5
@export_range(0.0, 2.0) var grassland_formation_multiplier: float = 1.0  # AUMENTADO
@export_range(0.0, 2.0) var forest_formation_multiplier: float = 0.8

@export_group("Debug")
@export var debug_generation: bool = false
@export var force_generation_everywhere: bool = false  # Para debug

# === SISTEMA DE RECURSOS ===
var terrain_generator: TileMapLayer
var formation_noise: FastNoiseLite
var detail_noise: FastNoiseLite

# Configuração dos tipos de rochas
var rock_types = {
	"stone": {
		"atlas_coords": Vector2i(2, 0),
		"name": "Stone",
		"color": Color(0.6, 0.6, 0.6),
		"preferred_biomes": ["mountain", "hills", "desert", "grassland", "forest"],  # EXPANDIDO
		"formation_chance": 1.0,
		"min_cluster_size": 8,
		"max_cluster_size": 45
	}
}

func _ready():
	print("🏔️ EnhancedResourceGenerator iniciado")
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
	formation_noise.frequency = 0.045
	formation_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	formation_noise.fractal_octaves = 3
	formation_noise.seed = randi()
	
	detail_noise = FastNoiseLite.new()
	detail_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	detail_noise.frequency = 0.12
	detail_noise.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	detail_noise.fractal_octaves = 2
	detail_noise.seed = randi() + 1000
	
	print("🎲 Ruído configurado - Formation seed:", formation_noise.seed, "Detail seed:", detail_noise.seed)

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
	atlas_source.create_tile(Vector2i(2, 0))  # Pedra
	
	new_tileset.add_source(atlas_source, 0)
	tile_set = new_tileset
	print("✅ EnhancedResourceGenerator: TileSet configurado")

func force_correct_positioning():
	"""Força posicionamento correto igual ao TerrainMap"""
	position = Vector2(0, 0)
	scale = Vector2(2.0, 2.0)
	visible = true
	enabled = true
	z_index = 1
	print("✅ ResourceMap posicionado: scale=", scale, " z_index=", z_index)

func find_terrain_generator():
	"""Encontra o TerrainGenerator na cena"""
	var possible_paths = [
		"../../Terrain/TerrainMap",
		"../Terrain/TerrainMap",
		"/root/Main/Terrain/TerrainMap"
	]
	
	for path in possible_paths:
		var node = get_node_or_null(path)
		if node and node is TileMapLayer:
			terrain_generator = node
			print("✅ TerrainGenerator encontrado em: ", path)
			return
	
	var terrain_nodes = get_tree().get_nodes_in_group("terrain")
	if terrain_nodes.size() > 0:
		terrain_generator = terrain_nodes[0]
		print("✅ TerrainGenerator encontrado via grupo: ", terrain_generator.get_path())

func generate():
	"""Gera formações rochosas - VERSÃO CORRIGIDA"""
	print("🏔️ Gerando formações rochosas avançadas...")
	clear()
	
	if not terrain_generator:
		find_terrain_generator()
		if not terrain_generator:
			print("❌ Impossível gerar sem TerrainGenerator!")
			return
	
	force_correct_positioning()
	
	var map_width = terrain_generator.get("map_width") if "map_width" in terrain_generator else 128
	var map_height = terrain_generator.get("map_height") if "map_height" in terrain_generator else 128
	
	print("🗺️ Gerando formações em mapa ", map_width, "x", map_height)
	
	# DEBUG: Verifica se terrain tem dados
	debug_terrain_data(map_width, map_height)
	
	# Gera formações de cada tipo de rocha
	for rock_type_name in rock_types:
		generate_rock_formations(rock_type_name, map_width, map_height)
	
	print("✅ Formações rochosas geradas!")
	call_deferred("final_positioning_check")

func debug_terrain_data(map_width: int, map_height: int):
	"""Debug dos dados do terreno"""
	if not debug_generation:
		return
		
	print("🔍 === DEBUG TERRAIN DATA ===")
	var biome_count = {}
	var sample_positions = []
	
	# Amostra alguns pontos
	for i in range(10):
		var x = randi_range(10, map_width - 10)
		var y = randi_range(10, map_height - 10)
		var pos = Vector2i(x, y)
		var biome = get_biome_at_position(pos)
		
		sample_positions.append({"pos": pos, "biome": biome})
		
		if not biome in biome_count:
			biome_count[biome] = 0
		biome_count[biome] += 1
	
	print("📊 Biomas encontrados:", biome_count)
	print("📍 Amostras:")
	for sample in sample_positions:
		print("  ", sample["pos"], " = ", sample["biome"])
	print("=== FIM DEBUG ===")

func generate_rock_formations(rock_type_name: String, map_width: int, map_height: int):
	"""Gera formações de um tipo específico de rocha - VERSÃO CORRIGIDA"""
	var rock_config = rock_types[rock_type_name]
	var placed_rocks = {}
	var formations_created = 0
	var attempts_made = 0
	var valid_anchors_found = 0
	
	print("🪨 Gerando formações de ", rock_type_name, "...")
	
	# CORREÇÃO: Muito mais tentativas e densidade aumentada
	var base_attempts = int(map_width * map_height * rock_formation_density * 0.01)  # AUMENTADO
	if debug_generation:
		print("🎯 Tentativas planejadas: ", base_attempts)
	
	# Busca pontos de ancoragem para formações
	for attempt in range(base_attempts):
		attempts_made += 1
		
		var anchor_x = randi_range(5, map_width - 5)  # Margens menores
		var anchor_y = randi_range(5, map_height - 5)
		var anchor_pos = Vector2i(anchor_x, anchor_y)
		
		# CORREÇÃO: Validação mais permissiva
		if not is_valid_formation_anchor_corrected(anchor_pos, rock_type_name):
			continue
		
		valid_anchors_found += 1
		
		# Calcula tamanho da formação baseado no bioma
		var biome = get_biome_at_position(anchor_pos)
		var biome_multiplier = get_biome_multiplier(biome)
		
		if debug_generation and formations_created < 5:
			print("🎯 Âncora válida em ", anchor_pos, " bioma=", biome, " mult=", biome_multiplier)
		
		# CORREÇÃO: Sempre gera algo, mesmo em biomas "inadequados"
		if biome_multiplier < 0.1:
			biome_multiplier = 0.3  # Mínimo garantido
		
		var formation_size = calculate_formation_size(biome_multiplier, rock_config)
		
		# Gera a formação rochosa
		var formation_rocks = generate_single_formation(
			anchor_pos, 
			formation_size, 
			rock_config,
			placed_rocks
		)
		
		if formation_rocks.size() > 0:
			formations_created += 1
			if debug_generation:
				print("  🏔️ Formação ", formations_created, " criada com ", formation_rocks.size(), " rochas em ", anchor_pos)
	
	print("📊 ", rock_type_name, " - Tentativas:", attempts_made, " Âncoras válidas:", valid_anchors_found, " Formações:", formations_created)

func is_valid_formation_anchor_corrected(pos: Vector2i, rock_type_name: String) -> bool:
	"""Verificação CORRIGIDA - NÃO gera em água"""
	if not terrain_generator:
		return false
	
	# CORREÇÃO: Verifica se já tem recurso (deve estar vazio)
	if get_cell_source_id(pos) != -1:
		return false
	
	# CORREÇÃO: Verifica bioma - NUNCA gera em água
	var biome = get_biome_at_position(pos)
	
	# CORREÇÃO PRINCIPAL: Bloqueia água sempre, mesmo com force_generation_everywhere
	if biome == "ocean":
		return false
	
	# CORREÇÃO: Se force_generation_everywhere está ativo, permite outros biomas
	if force_generation_everywhere:
		return true
	
	# CORREÇÃO: Aceita todos os biomas terrestres (exceto água)
	var terrestrial_biomes = ["mountain", "hills", "desert", "grassland", "forest", "beach"]
	return biome in terrestrial_biomes

func generate_single_formation(anchor_pos: Vector2i, target_size: int, rock_config: Dictionary, placed_rocks: Dictionary) -> Array:
	"""Gera uma única formação rochosa orgânica - VERSÃO CORRIGIDA"""
	var formation_rocks = []
	var pending_positions = [anchor_pos]
	var formation_id = str(anchor_pos.x) + "_" + str(anchor_pos.y)
	var iterations = 0
	var max_iterations = target_size * 3  # Previne loops infinitos
	
	while pending_positions.size() > 0 and formation_rocks.size() < target_size and iterations < max_iterations:
		iterations += 1
		var current_pos = pending_positions.pop_front()
		
		# Verifica se já foi processada
		if str(current_pos) in placed_rocks:
			continue
		
		# CORREÇÃO: Validação mais simples
		if not is_valid_rock_position_corrected(current_pos):
			continue
		
		# CORREÇÃO: Lógica de probabilidade mais generosa
		var noise_value = formation_noise.get_noise_2d(current_pos.x, current_pos.y)
		var detail_value = detail_noise.get_noise_2d(current_pos.x, current_pos.y)
		
		# Calcula probabilidade baseada na distância do anchor
		var distance_from_anchor = anchor_pos.distance_to(Vector2(current_pos.x, current_pos.y))
		var size_factor = 1.0 - (distance_from_anchor / (target_size * 0.8))  # Mais generoso
		size_factor = clamp(size_factor, 0.0, 1.0)
		
		# CORREÇÃO: Probabilidade mais alta
		var placement_chance = size_factor * formation_compactness
		placement_chance += (noise_value + 1.0) * 0.4  # Mais influência do ruído
		placement_chance += (detail_value + 1.0) * 0.2
		placement_chance = clamp(placement_chance, 0.0, 1.2)  # Permite > 1.0
		
		if randf() < placement_chance:
			# Coloca a rocha
			set_cell(current_pos, 0, rock_config["atlas_coords"])
			placed_rocks[str(current_pos)] = formation_id
			formation_rocks.append(current_pos)
			
			# Adiciona posições vizinhas para expansão
			add_expansion_candidates_corrected(current_pos, pending_positions, placed_rocks, formation_rocks.size(), target_size)
	
	if debug_generation and formation_rocks.size() > 0:
		print("    ⛰️ Formação finalizada: ", formation_rocks.size(), " rochas (alvo: ", target_size, ")")
	
	return formation_rocks

func is_valid_rock_position_corrected(pos: Vector2i) -> bool:
	"""Verificação CORRIGIDA - NÃO permite água"""
	if not terrain_generator:
		return false
	
	# Verifica limites do mapa
	var map_width = terrain_generator.get("map_width") if "map_width" in terrain_generator else 128
	var map_height = terrain_generator.get("map_height") if "map_height" in terrain_generator else 128
	
	if pos.x < 0 or pos.y < 0 or pos.x >= map_width or pos.y >= map_height:
		return false
	
	# CORREÇÃO: Verifica se já há recurso (não deve sobrescrever)
	if get_cell_source_id(pos) != -1:
		return false
	
	# CORREÇÃO: Verifica bioma - NUNCA permite água
	var biome = get_biome_at_position(pos)
	if biome == "ocean":
		return false  # Bloqueia água sempre
	
	# CORREÇÃO: Se force_generation_everywhere, permite outros biomas terrestres
	if force_generation_everywhere:
		return true
	
	# CORREÇÃO: Validação normal para biomas terrestres
	return biome in ["mountain", "hills", "desert", "grassland", "forest", "beach"]

func add_expansion_candidates_corrected(center_pos: Vector2i, pending_positions: Array, placed_rocks: Dictionary, current_size: int, target_size: int):
	"""Adiciona candidatos para expansão - VERSÃO CORRIGIDA"""
	# CORREÇÃO: Padrões de expansão mais agressivos
	var expansion_patterns = [
		# Adjacentes diretos (sempre)
		[Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)],
		# Diagonais
		[Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1)],
		# Expansão mais distante
		[Vector2i(2, 0), Vector2i(-2, 0), Vector2i(0, 2), Vector2i(0, -2)]
	]
	
	# CORREÇÃO: Usa todos os padrões, não apenas um
	var patterns_to_use = []
	if current_size < target_size * 0.3:
		patterns_to_use = [0]  # Só adjacentes
	elif current_size < target_size * 0.7:
		patterns_to_use = [0, 1]  # Adjacentes + diagonais
	else:
		patterns_to_use = [0, 1, 2]  # Todos
	
	for pattern_index in patterns_to_use:
		var chosen_pattern = expansion_patterns[pattern_index]
		
		for offset in chosen_pattern:
			var new_pos = center_pos + offset
			
			if str(new_pos) in placed_rocks or new_pos in pending_positions:
				continue
			
			# CORREÇÃO: Probabilidade mais alta de adicionar
			var add_chance = 1.0 - (edge_roughness * 0.5)  # Menos rugosidade
			if randf() < add_chance:
				pending_positions.append(new_pos)

func calculate_formation_size(biome_multiplier: float, rock_config: Dictionary) -> int:
	"""Calcula tamanho da formação baseado no bioma e configuração"""
	var base_size = lerp(float(min_formation_size), float(max_formation_size), randf())
	var adjusted_size = base_size * biome_multiplier
	
	# CORREÇÃO: Garante tamanho mínimo
	adjusted_size = max(adjusted_size, float(min_formation_size))
	
	# Variação extra
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
	"""Retorna multiplicador de formação para um bioma - CORRIGIDO"""
	match biome:
		"mountain": return mountain_formation_multiplier
		"hills": return hills_formation_multiplier
		"desert": return desert_formation_multiplier
		"grassland": return grassland_formation_multiplier
		"forest": return forest_formation_multiplier
		"beach": return desert_formation_multiplier * 0.7
		"ocean": return 0.0
		_: return grassland_formation_multiplier

func final_positioning_check():
	"""Verificação final de posicionamento"""
	if position != Vector2(0, 0):
		position = Vector2(0, 0)
	if scale != Vector2(2.0, 2.0):
		scale = Vector2(2.0, 2.0)
	if z_index != 1:
		z_index = 1
	
	queue_redraw()
	print("✅ ResourceMap: Posicionamento final verificado")

# === FUNÇÕES DE DEBUG E ANÁLISE ===
@export_group("Debug Avançado")
@export var analyze_formations: bool = false:
	set(value):
		if value:
			analyze_formations = false
			analyze_generated_formations()

@export var test_single_formation: bool = false:
	set(value):
		if value:
			test_single_formation = false
			test_formation_at_center()

func analyze_generated_formations():
	"""Analisa as formações geradas"""
	print("\n📊 === ANÁLISE DAS FORMAÇÕES ROCHOSAS ===")
	
	var total_rocks = 0
	var formations = {}
	
	var map_width = terrain_generator.get("map_width") if terrain_generator and "map_width" in terrain_generator else 128
	var map_height = terrain_generator.get("map_height") if terrain_generator and "map_height" in terrain_generator else 128
	
	# Conta todas as rochas
	for x in range(map_width):
		for y in range(map_height):
			var pos = Vector2i(x, y)
			if get_cell_source_id(pos) != -1:
				total_rocks += 1
	
	print("🪨 Total de rochas encontradas: ", total_rocks)
	
	if total_rocks == 0:
		print("❌ NENHUMA ROCHA GERADA!")
		print("🔍 Sugestões:")
		print("  1. Ative 'debug_generation' para mais detalhes")
		print("  2. Ative 'force_generation_everywhere' para teste")
		print("  3. Aumente 'rock_formation_density'")
	
	print("=== FIM ANÁLISE ===\n")

func test_formation_at_center():
	"""Testa geração de uma formação no centro do mapa"""
	print("\n🧪 === TESTE FORMAÇÃO NO CENTRO ===")
	
	var map_width = terrain_generator.get("map_width") if terrain_generator and "map_width" in terrain_generator else 128
	var map_height = terrain_generator.get("map_height") if terrain_generator and "map_height" in terrain_generator else 128
	
	var center_pos = Vector2i(map_width / 2, map_height / 2)
	var rock_config = rock_types["stone"]
	var placed_rocks = {}
	
	print("🎯 Testando formação em: ", center_pos)
	
	var formation_rocks = generate_single_formation(center_pos, 20, rock_config, placed_rocks)
	
	print("✅ Formação teste criada com ", formation_rocks.size(), " rochas")
	print("=== FIM TESTE ===\n")

# Sistema para manter posicionamento correto
func _process(_delta):
	if not Engine.is_editor_hint():
		if position != Vector2(0, 0) or scale != Vector2(2.0, 2.0):
			position = Vector2(0, 0)
			scale = Vector2(2.0, 2.0)
