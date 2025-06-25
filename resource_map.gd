@tool
extends TileMapLayer

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

func _ready():
	apply_visual_scale_correction()

func generate():
	print("🔁 Gerando RESOURCES...")
	clear()
	
	# Busca o terrain_map de forma mais robusta
	var terrain_map = find_terrain_map()
	var object_map = find_object_map()
	
	if not terrain_map:
		print("❌ 'TerrainMap' não encontrado.")
		return

	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var placed = {}

	# Pega dimensões do mapa do terrain_map
	var map_width = 128
	var map_height = 128
	
	if terrain_map.has_method("get") and terrain_map.get("mapWidth"):
		map_width = terrain_map.get("mapWidth")
		map_height = terrain_map.get("mapHeight")

	for _i in range(map_width * map_height * generationChance):
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

# Função para encontrar o TerrainMap
func find_terrain_map() -> TileMapLayer:
	# Tenta primeiro os caminhos mais comuns
	var possible_paths = [
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
	
	# Busca recursiva
	var main_node = get_tree().get_first_node_in_group("main")
	if not main_node:
		main_node = get_tree().root.get_node_or_null("Main")
	
	if main_node:
		var terrain_recursive = find_tilemap_recursive(main_node, "TerrainMap")
		if terrain_recursive:
			print("✅ TerrainMap encontrado via busca recursiva")
			return terrain_recursive
	
	# Busca por script
	var terrain_by_script = find_node_with_script("layer1.gd")
	if terrain_by_script and terrain_by_script is TileMapLayer:
		print("✅ TerrainMap encontrado via script")
		return terrain_by_script
	
	return null

func apply_visual_scale_correction():
	# CORREÇÃO DEFINITIVA: ResourcesTileSet.png tem sprites menores que textureAtlas.png
	# Os sprites em ResourcesTileSet.png aparentam ocupar ~50% do tile (16x16 em tiles 32x32)
	# Aplicamos escala 2.0 para compensar e igualar visualmente ao terrain
	scale = Vector2(2.0, 2.0)
	print("✅ ResourceMap: Escala corrigida para (2.0, 2.0) - sprites pequenos compensados")
# Função para encontrar o ObjectMap
func find_object_map() -> TileMapLayer:
	var possible_paths = [
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
			return node
	
	# Busca recursiva
	var main_node = get_tree().get_first_node_in_group("main")
	if not main_node:
		main_node = get_tree().root.get_node_or_null("Main")
	
	if main_node:
		return find_tilemap_recursive(main_node, "ObjectMap")
	
	return find_node_with_script("object_map.gd")

# Busca recursiva por nome
func find_tilemap_recursive(node: Node, target_name: String) -> TileMapLayer:
	if node is TileMapLayer and node.name == target_name:
		return node
	
	for child in node.get_children():
		var child_result = find_tilemap_recursive(child, target_name)
		if child_result:
			return child_result
	
	return null

# Busca por script específico
func find_node_with_script(script_name: String) -> Node:
	return find_script_recursive(get_tree().root, script_name)

func find_script_recursive(node: Node, script_name: String) -> Node:
	if node.get_script() and node.get_script().resource_path.ends_with(script_name):
		return node
	
	for child in node.get_children():
		var script_result = find_script_recursive(child, script_name)
		if script_result:
			return script_result
	
	return null
