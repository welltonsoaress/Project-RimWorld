@tool
extends TileMapLayer


func create_auto_tileset():
	"""Cria TileSet automaticamente para ObjectMap"""
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
				print("✅ Textura encontrada para ObjectMap: ", path)
				break
	
	if not texture:
		print("❌ Nenhuma textura encontrada para ObjectMap!")
		return
	
	# Cria fonte atlas
	var source = TileSetAtlasSource.new()
	source.texture = texture
	
	# Cria tile para vegetação (grama escura - posição 1,0)
	source.create_tile(Vector2i(1, 0))
	
	# Adiciona fonte ao TileSet
	var source_id = new_tileset.add_source(source)
	
	# Atribui TileSet
	tile_set = new_tileset
	print("✅ TileSet criado automaticamente para ObjectMap")

# === COMPATIBILIDADE COM SISTEMA ATUAL ===
@export var generateObjects: bool:
	set(value):
		generateObjects = false
		if is_inside_tree():
			generate()
		else:
			await ready
			generate()

@export var generationChance := 0.08

# === SISTEMA MODULAR ===
@export_group("Sistema Modular")
@export var use_biome_based_generation: bool = true
@export var respect_resource_placement: bool = true
@export var use_object_variety: bool = true
@export var apply_biome_density_modifiers: bool = true

@export_group("Configuração Avançada")
@export var forest_density_multiplier: float = 2.0
@export var desert_density_multiplier: float = 0.3
@export var mountain_tree_chance: float = 0.02

@export_group("Debug")
@export var show_generation_debug: bool = false
@export var analyze_object_distribution: bool = false:
	set(value):
		analyze_object_distribution = false
		if value:
			analyze_distribution()

# Sistema modular
var biome_manager: BiomeManager
var terrain_map: TileMapLayer
var resource_map: TileMapLayer

func _ready():
	apply_visual_scale_correction()
	initialize_modular_system()

func initialize_modular_system():
	"""Inicializa o sistema modular de objetos"""
	biome_manager = BiomeManager.get_instance()
	print("✅ ObjectMap: Sistema modular inicializado")

func generate():
	"""Função principal de geração - Sistema Modular"""
	print("🔁 Gerando OBJETOS - Sistema Modular Ativo!")
	clear()
	
	# Encontra dependências
	terrain_map = find_terrain_map()
	resource_map = find_resource_map()
	
	if not terrain_map:
		print("❌ TerrainMap não encontrado para geração de objetos!")
		return
	
	if use_biome_based_generation and biome_manager:
		generate_with_biome_system()
	else:
		generate_with_legacy_system()
	
	if show_generation_debug:
		print_generation_stats()

func generate_with_biome_system():
	"""Geração avançada baseada em biomas"""
	print("🚀 Usando sistema de geração de objetos baseado em biomas")
	
	var map_width = get_map_dimension("mapWidth", 128)
	var map_height = get_map_dimension("mapHeight", 128)
	var placed_objects = {}
	
	for x in range(map_width):
		for y in range(map_height):
			var pos = Vector2i(x, y)
			
			# Verifica se há recurso no local
			if respect_resource_placement and resource_map:
				var has_resource = resource_map.get_cell_source_id(pos) != -1
				if has_resource:
					continue
			
			# Determina o bioma atual
			var biome = get_biome_at_position(x, y)
			if biome.is_empty():
				continue
			
			var biome_name = get_biome_name_from_data(biome)
			var objects_config = biome_manager.get_objects_for_biome(biome_name)
			
			# Aplica modificadores de densidade por bioma
			var density_modifier = get_density_modifier_for_biome(biome_name)
			
			# Gera objetos baseado na configuração do bioma
			for object_name in objects_config:
				var object_config = objects_config[object_name]
				var base_chance = object_config.get("chance", 0.05)
				var final_chance = base_chance * density_modifier
				
				if randf() < final_chance:
					place_object(pos, object_name, object_config, placed_objects)

func place_object(pos: Vector2i, object_name: String, object_config: Dictionary, placed_objects: Dictionary):
	"""Coloca um objeto em uma posição"""
	if str(pos) in placed_objects:
		return
	
	if is_valid_position_for_object(pos, object_name):
		var atlas_coords = object_config.get("atlas_coords", [0, 0])
		var atlas_vector = Vector2i(atlas_coords[0], atlas_coords[1])
		
		set_cell(pos, 0, atlas_vector)
		placed_objects[str(pos)] = object_name
		
		if show_generation_debug and randf() < 0.01:  # Debug apenas para alguns objetos
			print("  🌿 ", object_name.capitalize(), " colocado em ", pos)

func is_valid_position_for_object(pos: Vector2i, object_name: String) -> bool:
	"""Verifica se uma posição é válida para um objeto"""
	
	# Verifica recursos se necessário
	if respect_resource_placement and resource_map and resource_map.get_cell_source_id(pos) != -1:
		return false
	
	# Verifica compatibilidade com bioma
	var biome = get_biome_at_position(pos.x, pos.y)
	if biome.is_empty():
		return false
	
	var biome_name = get_biome_name_from_data(biome)
	var objects_config = biome_manager.get_objects_for_biome(biome_name)
	
	return object_name in objects_config

func get_density_modifier_for_biome(biome_name: String) -> float:
	"""Retorna modificador de densidade para um bioma"""
	if not apply_biome_density_modifiers:
		return 1.0
	
	match biome_name:
		"forest":
			return forest_density_multiplier
		"desert":
			return desert_density_multiplier
		"mountains":
			return 0.5  # Menos vegetação em montanhas
		"ocean", "beach":
			return 0.0  # Sem vegetação em água/praia
		"grassland":
			return 1.2  # Ligeiramente mais vegetação em campos
		"hills":
			return 0.8  # Menos vegetação em colinas
		_:
			return 1.0

func generate_with_legacy_system():
	"""Sistema de compatibilidade usando lógica original"""
	print("🔄 Usando sistema de compatibilidade para objetos")
	
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	var map_width = get_map_dimension("mapWidth", 128)
	var map_height = get_map_dimension("mapHeight", 128)
	
	for x in range(map_width):
		for y in range(map_height):
			var pos = Vector2i(x, y)
			var ground_tile = terrain_map.get_cell_atlas_coords(pos)
			
			# Verifica se há pedra neste tile
			var tile_atlas = Vector2i(0, 0)
			var source_id = -1
			if resource_map:
				tile_atlas = resource_map.get_cell_atlas_coords(pos)
				source_id = resource_map.get_cell_source_id(pos)
			var has_stone = (source_id != -1 and tile_atlas == Vector2i(2, 0))
			
			# Condição original: não coloca em não-grama ou onde há pedra
			if ground_tile != Vector2i(0, 0) or has_stone:
				continue
			
			var roll = rng.randf()
			if roll < generationChance:
				set_cell(pos, 0, Vector2i(0, 0))  # mato
			elif roll < generationChance + 0.03:
				set_cell(pos, 0, Vector2i(1, 0))  # árvore

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
	var object_count = 0
	var object_types = {}
	var map_width = get_map_dimension("mapWidth", 128)
	var map_height = get_map_dimension("mapHeight", 128)
	
	# Conta objetos e tipos
	for x in range(map_width):
		for y in range(map_height):
			var pos = Vector2i(x, y)
			if get_cell_source_id(pos) != -1:
				object_count += 1
				var atlas_coords = get_cell_atlas_coords(pos)
				var object_type = get_object_type_from_atlas(atlas_coords)
				
				if object_type in object_types:
					object_types[object_type] += 1
				else:
					object_types[object_type] = 1
	
	var total_tiles = map_width * map_height
	var object_density = float(object_count) / float(total_tiles) * 100.0
	
	print("📊 Estatísticas de Objetos:")
	print("  - Total de objetos: ", object_count)
	print("  - Densidade: ", "%.2f" % object_density, "%")
	
	for obj_type in object_types:
		print("  - ", obj_type.capitalize(), ": ", object_types[obj_type])

func get_object_type_from_atlas(atlas_coords: Vector2i) -> String:
	"""Converte coordenadas do atlas em tipo de objeto"""
	match atlas_coords:
		Vector2i(0, 0):
			return "grass"
		Vector2i(1, 0):
			return "tree"
		_:
			return "unknown"

func analyze_distribution():
	"""Analisa a distribuição de objetos por bioma"""
	if not biome_manager:
		print("❌ Sistema modular não disponível para análise")
		return
	
	print("\n🔍 === ANÁLISE DE DISTRIBUIÇÃO DE OBJETOS ===")
	
	var biome_objects = {}
	var map_width = get_map_dimension("mapWidth", 128)
	var map_height = get_map_dimension("mapHeight", 128)
	
	# Amostragem para performance
	for x in range(0, map_width, 4):
		for y in range(0, map_height, 4):
			var pos = Vector2i(x, y)
			if get_cell_source_id(pos) != -1:
				var biome = get_biome_at_position(x, y)
				var biome_name = get_biome_name_from_data(biome)
				var atlas_coords = get_cell_atlas_coords(pos)
				var object_type = get_object_type_from_atlas(atlas_coords)
				
				var key = biome_name + "_" + object_type
				if key in biome_objects:
					biome_objects[key] += 1
				else:
					biome_objects[key] = 1
	
	# Organiza por bioma
	var biomes = {}
	for key in biome_objects:
		var parts = key.split("_")
		var biome_name = parts[0]
		var object_type = parts[1]
		
		if not biome_name in biomes:
			biomes[biome_name] = {}
		
		biomes[biome_name][object_type] = biome_objects[key]
	
	for biome_name in biomes:
		print("🔹 ", biome_name.capitalize(), ":")
		for object_type in biomes[biome_name]:
			print("    ", object_type.capitalize(), ": ", biomes[biome_name][object_type])
	
	print("=== FIM ANÁLISE ===\n")

# === FUNCIONALIDADES AVANÇADAS ===

func get_object_coverage_by_biome() -> Dictionary:
	"""Retorna cobertura de objetos por bioma"""
	var coverage = {}
	var map_width = get_map_dimension("mapWidth", 128)
	var map_height = get_map_dimension("mapHeight", 128)
	
	for x in range(0, map_width, 2):  # Amostragem
		for y in range(0, map_height, 2):
			var biome = get_biome_at_position(x, y)
			var biome_name = get_biome_name_from_data(biome)
			
			if not biome_name in coverage:
				coverage[biome_name] = {"total": 0, "objects": 0}
			
			coverage[biome_name]["total"] += 1
			
			if get_cell_source_id(Vector2i(x, y)) != -1:
				coverage[biome_name]["objects"] += 1
	
	# Calcula percentuais
	for biome_name in coverage:
		var data = coverage[biome_name]
		if data["total"] > 0:
			data["coverage_percent"] = float(data["objects"]) / float(data["total"]) * 100.0
		else:
			data["coverage_percent"] = 0.0
	
	return coverage

@export var show_coverage_analysis: bool = false:
	set(value):
		show_coverage_analysis = false
		if value:
			var coverage = get_object_coverage_by_biome()
			print("\n🌿 === COBERTURA DE OBJETOS POR BIOMA ===")
			for biome_name in coverage:
				var data = coverage[biome_name]
				print("🔹 ", biome_name.capitalize(), ": ", "%.1f" % data["coverage_percent"], "% (", data["objects"], "/", data["total"], ")")
			print("=== FIM COBERTURA ===\n")

func apply_visual_scale_correction():
	"""Mantém correção visual original"""
	scale = Vector2(2.0, 2.0)
	print("✅ ObjectMap: Escala corrigida para (2.0, 2.0)")

# === FUNÇÕES DE COMPATIBILIDADE (MANTIDAS) ===

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
	
	return null

func find_resource_map() -> TileMapLayer:
	var possible_paths = [
		"Main/Resource/ResourceMap",
		"/root/Main/Resource/ResourceMap",
		"../Resource/ResourceMap",
		"../../Resource/ResourceMap",
		"/root/Main/ResourceMap",
		"../ResourceMap",
		"../../ResourceMap"
	]
	
	for path in possible_paths:
		var node = get_node_or_null(path)
		if node and node is TileMapLayer:
			print("✅ ResourceMap encontrado em: ", path)
			return node
	
	var main_node = get_tree().get_first_node_in_group("main")
	if not main_node:
		main_node = get_tree().root.get_node_or_null("Main")
	
	if main_node:
		var result = find_tilemap_recursive(main_node, "ResourceMap")
		if result:
			print("✅ ResourceMap encontrado via busca recursiva")
			return result
	
	return find_node_with_script("resource_map.gd")

func find_tilemap_recursive(node: Node, target_name: String) -> TileMapLayer:
	if node is TileMapLayer and node.name == target_name:
		return node
	
	for child in node.get_children():
		var result = find_tilemap_recursive(child, target_name)
		if result:
			return result
	
	return null

func find_node_with_script(script_name: String) -> Node:
	return find_script_recursive(get_tree().root, script_name)

func find_script_recursive(node: Node, script_name: String) -> Node:
	if node.get_script() and node.get_script().resource_path.ends_with(script_name + ".gd"):
		return node
	
	for child in node.get_children():
		var result = find_script_recursive(child, script_name)
		if result:
			return result
	
	return null
