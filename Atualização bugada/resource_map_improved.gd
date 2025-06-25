@tool
extends TileMapLayer

# === COMPATIBILIDADE COM SISTEMA ATUAL ===
@export var generateResources: bool:
	set(value):
		generateResources = false
		if is_inside_tree():
			generate()
		else:
			await ready
			generate()

@export var generationChance := 0.03
@export var clusterSize := 10

# === SISTEMA MODULAR ===
@export_group("Sistema Modular")
@export var use_biome_based_generation: bool = true
@export var respect_terrain_rules: bool = true
@export var use_resource_clusters: bool = true

@export_group("Debug")
@export var show_generation_debug: bool = false
@export var analyze_resource_distribution: bool = false:
	set(value):
		analyze_resource_distribution = false
		if value:
			analyze_distribution()

# Sistema modular
var biome_manager: BiomeManager
var terrain_map: TileMapLayer
var object_map: TileMapLayer

func _ready():
	apply_visual_scale_correction()
	initialize_modular_system()
	create_auto_tileset()

func create_auto_tileset():
	"""Cria TileSet automaticamente para ResourceMap"""
	var new_tileset = TileSet.new()
	new_tileset.tile_size = Vector2i(32, 32)
	
	# Procura textureAtlas em vários locais
	var texture_paths = [
		"res://textureAtlas.png",
		"res://TileSets/textureAtlas.png",
		"res://assets/textureAtlas.png",
		"res://textures/textureAtlas.png"
	]
	
	var texture = null
	for path in texture_paths:
		if FileAccess.file_exists(path):
			texture = load(path)
			if texture:
				print("✅ Textura encontrada para ResourceMap: ", path)
				break
	
	if not texture:
		print("❌ Nenhuma textura encontrada para ResourceMap!")
		return
	
	# Cria fonte atlas
	var source = TileSetAtlasSource.new()
	source.texture = texture
	
	# Cria tile para recursos (pedra - posição 2,0)
	source.create_tile(Vector2i(2, 0))
	
	# Adiciona fonte ao TileSet
#	var source_id = new_tileset.add_source(source)
	
	# Atribui TileSet
	tile_set = new_tileset
	print("✅ TileSet criado automaticamente para ResourceMap")

func initialize_modular_system():
	"""Inicializa o sistema modular de recursos"""
	biome_manager = BiomeManager.get_instance()
	print("✅ ResourceMap: Sistema modular inicializado")

func generate():
	"""Função principal de geração - Sistema Modular"""
	print("🔁 Gerando RECURSOS - Sistema Modular Ativo!")
	clear()
	
	# Encontra dependências
	terrain_map = find_terrain_map()
	object_map = find_object_map()
	
	if not terrain_map:
		print("❌ TerrainMap não encontrado para geração de recursos!")
		return
	
	if use_biome_based_generation and biome_manager:
		generate_with_biome_system()
	else:
		generate_with_legacy_system()
	
	if show_generation_debug:
		print_generation_stats()

func generate_with_biome_system():
	"""Geração avançada baseada em biomas"""
	print("🚀 Usando sistema de geração baseado em biomas")
	
	# Verifica se BiomeManager existe
	if not biome_manager:
		print("❌ BiomeManager não encontrado para geração de recursos!")
		return
	
	# Verifica se tem configuração de recursos
	var resource_types = biome_manager.get_available_resource_types()
	print("🔧 Tipos de recursos disponíveis: ", resource_types)
	
	if resource_types.is_empty():
		print("❌ Nenhum tipo de recurso configurado no BiomeManager!")
		return
	
	var map_width = get_map_dimension("mapWidth", 128)
	var map_height = get_map_dimension("mapHeight", 128)
	var placed_resources = {}
	var total_attempts = 0
	var successful_placements = 0
	
	print("📍 Iniciando geração em mapa ", map_width, "x", map_height)
	
	for x in range(map_width):
		for y in range(map_height):
			var pos = Vector2i(x, y)
			total_attempts += 1
			
			# Verifica se já há objeto no local
			if respect_terrain_rules and object_map and object_map.get_cell_source_id(pos) != -1:
				continue
			
			# Determina o bioma atual
			var biome = get_biome_at_position(x, y)
			if biome.is_empty():
				continue
			
			var biome_name = get_biome_name_from_data(biome)
			var resources_config = biome_manager.get_resources_for_biome(biome_name)
			
			# Debug primeira vez que encontra um bioma
			if total_attempts == 1 or (total_attempts % 5000 == 0):
				print("  🔍 Bioma em (", x, ",", y, "): ", biome_name, " | Recursos: ", resources_config.keys())
			
			# Gera recursos baseado na configuração do bioma
			for resource_name in resources_config:
				var resource_config = resources_config[resource_name]
				var chance = resource_config.get("chance", 0.01)
				var cluster_size = resource_config.get("cluster_size", 5)
				
				# Aumenta chance base para garantir geração
				chance = max(chance, 0.05)  # Mínimo 5% de chance
				
				if randf() < chance:
					if use_resource_clusters:
						var placed = generate_resource_cluster(pos, resource_name, cluster_size, placed_resources)
						if placed > 0:
							successful_placements += placed
							if successful_placements <= 10:  # Log primeiros 10
								print("    ✅ Cluster de ", resource_name, " em ", pos, " (", placed, " tiles)")
					else:
						if place_single_resource(pos, resource_name, placed_resources):
							successful_placements += 1
							if successful_placements <= 10:  # Log primeiros 10
								print("    ✅ Recurso ", resource_name, " em ", pos)
	
	print("📊 Recursos - Tentativas: ", total_attempts, " | Colocados: ", successful_placements)
	
	# Força visibilidade e atualização
	visible = true
	enabled = true
	z_index = 1  # Acima do terreno
	queue_redraw()
	print("🔧 ResourceMap: Forçada visibilidade (z_index: 1)")

func generate_resource_cluster(start_pos: Vector2i, resource_name: String, cluster_size: int, placed_resources: Dictionary) -> int:
	"""Gera um cluster de recursos"""
	var resource_config = biome_manager.get_resource_config(resource_name)
	var atlas_coords = resource_config.get("atlas_coords", [2, 0])
	var atlas_vector = Vector2i(atlas_coords[0], atlas_coords[1])
	
	var map_width = get_map_dimension("mapWidth", 128)
	var map_height = get_map_dimension("mapHeight", 128)
	var placed_count = 0
	
	for i in range(cluster_size):
		var offset = Vector2i(randi_range(-2, 2), randi_range(-2, 2))
		var pos = start_pos + offset
		
		# Verifica limites
		if pos.x < 0 or pos.y < 0 or pos.x >= map_width or pos.y >= map_height:
			continue
		
		# Verifica se já foi colocado
		if str(pos) in placed_resources:
			continue
		
		# Verifica se é válido para o bioma
		if is_valid_position_for_resource(pos, resource_name):
			set_cell(pos, 0, atlas_vector)
			placed_resources[str(pos)] = resource_name
			placed_count += 1
			
			if show_generation_debug and i == 0:
				print("  🔧 Cluster de ", resource_name, " em ", pos)
	
	return placed_count

func place_single_resource(pos: Vector2i, resource_name: String, placed_resources: Dictionary) -> bool:
	"""Coloca um recurso individual"""
	if str(pos) in placed_resources:
		return false
	
	if is_valid_position_for_resource(pos, resource_name):
		var resource_config = biome_manager.get_resource_config(resource_name)
		var atlas_coords = resource_config.get("atlas_coords", [2, 0])
		var atlas_vector = Vector2i(atlas_coords[0], atlas_coords[1])
		
		set_cell(pos, 0, atlas_vector)
		placed_resources[str(pos)] = resource_name
		return true
	
	return false

func is_valid_position_for_resource(pos: Vector2i, resource_name: String) -> bool:
	"""Verifica se uma posição é válida para um recurso"""
	
	# Verifica objetos se necessário
	if respect_terrain_rules and object_map and object_map.get_cell_source_id(pos) != -1:
		return false
	
	# Verifica compatibilidade com bioma
	var biome = get_biome_at_position(pos.x, pos.y)
	if biome.is_empty():
		return false
	
	var biome_name = get_biome_name_from_data(biome)
	var resources_config = biome_manager.get_resources_for_biome(biome_name)
	
	return resource_name in resources_config

func generate_with_legacy_system():
	"""Sistema de compatibilidade usando lógica original"""
	print("🔄 Usando sistema de compatibilidade para recursos")
	
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var placed = {}
	
	var map_width = get_map_dimension("mapWidth", 128)
	var map_height = get_map_dimension("mapHeight", 128)
	
	for _i in range(int(map_width * map_height * generationChance)):
		var start = Vector2i(rng.randi_range(0, map_width - 1), rng.randi_range(0, map_height - 1))
		var ground_tile = terrain_map.get_cell_atlas_coords(start)
		
		var has_object = false
		if object_map:
			has_object = object_map.get_cell_source_id(start) != -1
		
		var valid_terrains = [
			Vector2i(0, 0),  # grama clara
			Vector2i(1, 0),  # grama escura
			Vector2i(2, 0),  # terra
			Vector2i(1, 1),  # areia praia
			Vector2i(2, 1)   # areia deserto
		]
		
		if ground_tile not in valid_terrains or has_object:
			continue
		
		for _j in range(clusterSize):
			var offset = Vector2i(rng.randi_range(-2, 2), rng.randi_range(-2, 2))
			var pos = start + offset
			if pos.x < 0 or pos.y < 0 or pos.x >= map_width or pos.y >= map_height:
				continue
			if str(pos) in placed:
				continue
			
			var g = terrain_map.get_cell_atlas_coords(pos)
			var o = object_map and object_map.get_cell_source_id(pos) != -1
			
			if g not in valid_terrains or o:
				continue
			
			set_cell(pos, 0, Vector2i(2, 0))  # pedra
			placed[str(pos)] = true

func get_biome_at_position(x: int, y: int) -> Dictionary:
	"""Obtém o bioma em uma posição específica"""
	if not terrain_map or not terrain_map.has_method("get_biome_at_position"):
		# Fallback: determina bioma baseado no tile de terreno
		var terrain_tile = terrain_map.get_cell_atlas_coords(Vector2i(x, y))
		return get_biome_from_terrain_tile(terrain_tile)
	
	return terrain_map.get_biome_at_position(x, y)

func get_biome_from_terrain_tile(terrain_tile: Vector2i) -> Dictionary:
	"""Converte tile de terreno em dados de bioma (fallback)"""
	match terrain_tile:
		Vector2i(0, 1):  # Água
			return {"name": "ocean", "id": 0}
		Vector2i(1, 1):  # Areia praia
			return {"name": "beach", "id": 1}
		Vector2i(2, 1):  # Areia deserto
			return {"name": "desert", "id": 2}
		Vector2i(0, 0):  # Grama
			return {"name": "grassland", "id": 3}
		Vector2i(1, 0):  # Grama escura
			return {"name": "forest", "id": 4}
		Vector2i(2, 0):  # Terra
			return {"name": "hills", "id": 5}
		Vector2i(3, 0):  # Pedra
			return {"name": "mountains", "id": 6}
		_:
			return {"name": "grassland", "id": 3}

func get_biome_name_from_data(biome_data: Dictionary) -> String:
	"""Extrai nome do bioma dos dados"""
	return biome_data.get("name", "grassland")

func get_map_dimension(property_name: String, default_value: int) -> int:
	"""Obtém dimensões do mapa do TerrainMap"""
	if terrain_map and property_name in terrain_map:
		return terrain_map.get(property_name)
	return default_value

func print_generation_stats():
	"""Imprime estatísticas da geração"""
	var resource_count = 0
	var map_width = get_map_dimension("mapWidth", 128)
	var map_height = get_map_dimension("mapHeight", 128)
	
	for x in range(map_width):
		for y in range(map_height):
			if get_cell_source_id(Vector2i(x, y)) != -1:
				resource_count += 1
	
	var total_tiles = map_width * map_height
	var resource_density = float(resource_count) / float(total_tiles) * 100.0
	
	print("📊 Estatísticas de Recursos:")
	print("  - Total de recursos: ", resource_count)
	print("  - Densidade: ", "%.2f" % resource_density, "%")

func analyze_distribution():
	"""Analisa a distribuição de recursos por bioma"""
	if not biome_manager:
		print("❌ Sistema modular não disponível para análise")
		return
	
	print("\n🔍 === ANÁLISE DE DISTRIBUIÇÃO DE RECURSOS ===")
	
	var biome_resources = {}
	var map_width = get_map_dimension("mapWidth", 128)
	var map_height = get_map_dimension("mapHeight", 128)
	
	# Amostragem para performance
	for x in range(0, map_width, 4):
		for y in range(0, map_height, 4):
			var pos = Vector2i(x, y)
			if get_cell_source_id(pos) != -1:
				var biome = get_biome_at_position(x, y)
				var biome_name = get_biome_name_from_data(biome)
				
				if biome_name in biome_resources:
					biome_resources[biome_name] += 1
				else:
					biome_resources[biome_name] = 1
	
	for biome_name in biome_resources:
		print("🔹 ", biome_name.capitalize(), ": ", biome_resources[biome_name], " recursos")
	
	print("=== FIM ANÁLISE ===\n")

func apply_visual_scale_correction():
	"""Mantém correção visual original"""
	scale = Vector2(2.0, 2.0)
	print("✅ ResourceMap: Escala corrigida para (2.0, 2.0)")

# === FUNÇÕES DE COMPATIBILIDADE ===
func find_terrain_map() -> TileMapLayer:
	var possible_paths = [
		"Main/Terrain/TerrainMap",
		"/root/Main/Terrain/TerrainMap",
		"../Terrain/TerrainMap",
		"../../Terrain/TerrainMap",
		"/root/Main/TerrainMap",
		"../TerrainMap",
		"../../TerrainMap"
	]
	
	for path in possible_paths:
		var node = get_node_or_null(path)
		if node and node is TileMapLayer:
			print("✅ TerrainMap encontrado em: ", path)
			return node
	
	var main_node = get_tree().get_first_node_in_group("main")
	if not main_node:
		main_node = get_tree().root.get_node_or_null("Main")
	
	if main_node:
		var terrain_recursive = find_tilemap_recursive(main_node, "TerrainMap")
		if terrain_recursive:
			print("✅ TerrainMap encontrado via busca recursiva")
			return terrain_recursive
	
	var terrain_by_script = find_node_with_script("res://Terrain_map_improved.gd")
	if terrain_by_script and terrain_by_script is TileMapLayer:
		print("✅ TerrainMap encontrado via script")
		return terrain_by_script
	
	print("❌ Nenhum TerrainMap encontrado")
	return null

func find_tilemap_recursive(node: Node, target_name: String) -> TileMapLayer:
	if node is TileMapLayer and node.name == target_name:
		return node
	
	for child in node.get_children():
		var child_result = find_tilemap_recursive(child, target_name)
		if child_result:
			return child_result
	
	return null

func find_node_with_script(script_name: String) -> Node:
	return find_script_recursive(get_tree().root, script_name)

func find_script_recursive(node: Node, script_name: String) -> Node:
	if node.get_script() and node.get_script().resource_path.ends_with(script_name + ".gd"):
		return node
	
	for child in node.get_children():
		var script_result = find_script_recursive(child, script_name)
		if script_result:
			return script_result
	
	return null

func find_object_map() -> TileMapLayer:
	var possible_paths = [
		
		"Main/Object",
		"/root/Main/Object/ObjectMap",
		"../Object/ObjectMap",
		"../../Object/ObjectMap",
		"/root/Main/ObjectMap",
		"../ObjectMap",
		"../../ObjectMap"
	]
	
	for path in possible_paths:
		var node = get_node_or_null(path)
		if node and node is TileMapLayer:
			print("✅ ObjectMap encontrado em: ", path)
			return node
	
	var main_node = get_tree().get_first_node_in_group("main")
	if not main_node:
		main_node = get_tree().root.get_node_or_null("Main")
	
	if main_node:
		var object_recursive = find_tilemap_recursive(main_node, "ObjectMap")
		if object_recursive:
			print("✅ ObjectMap encontrado via busca recursiva")
			return object_recursive
	
	var object_by_script = find_node_with_script("res://object_map_improved.gd")
	if object_by_script and object_by_script is TileMapLayer:
		print("✅ ObjectMap encontrado via script")
		return object_by_script
	
	print("❌ Nenhum ObjectMap encontrado")
	return null
