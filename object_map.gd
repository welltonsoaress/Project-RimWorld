@tool
extends TileMapLayer

@export var generateObjects: bool:
	set(value):
		generateObjects = false
		if is_inside_tree():
			generate()
		else:
			await ready
			generate()

@export var generationChance := 0.08

func _ready():
	apply_visual_scale_correction()

func generate():
	print("🔁 Gerando OBJECTS...")
	clear()
	
	# Busca de forma mais robusta
	var terrain_map = find_terrain_map()
	var resource_map = find_resource_map()
	
	if not terrain_map:
		print("❌ 'TerrainMap' não encontrado.")
		return
	
	if not resource_map:
		print("❌ 'ResourceMap' não encontrado.")
		return

	var rng = RandomNumberGenerator.new()
	rng.randomize()

	# Pega dimensões do mapa do terrain_map
	var map_width = 128
	var map_height = 128
	
	if terrain_map.has_method("get") and terrain_map.get("mapWidth"):
		map_width = terrain_map.get("mapWidth")
		map_height = terrain_map.get("mapHeight")

	for x in range(map_width):
		for y in range(map_height):
			var pos = Vector2i(x, y)
			var ground_tile = terrain_map.get_cell_atlas_coords(pos)

			# 🧱 Verifica se há PEDRA neste tile (2,0)
			var tile_atlas = resource_map.get_cell_atlas_coords(pos)
			var source_id = resource_map.get_cell_source_id(pos)
			var has_stone = (source_id != -1 and tile_atlas == Vector2i(2, 0))

			# 🧾 Condição para NÃO colocar mato/árvore:
			# - Não é grama
			# - OU há pedra
			if ground_tile != Vector2i(0, 0) or has_stone:
				continue

			var roll = rng.randf()
			if roll < generationChance:
				set_cell(pos, 0, Vector2i(0, 0))  # mato
			elif roll < generationChance + 0.03:
				set_cell(pos, 0, Vector2i(1, 0))  # árvore

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
	# CORREÇÃO DEFINITIVA: ObjectMap usa o mesmo ResourcesTileSet.png 
	# que tem sprites menores que o terrain
	# Aplicamos escala 2.0 para manter consistência visual
	scale = Vector2(2.0, 2.0)
	print("✅ ObjectMap: Escala corrigida para (2.0, 2.0) - sprites pequenos compensados")
# Função para encontrar o ResourceMap
func find_resource_map() -> TileMapLayer:
	var possible_paths = [
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
	
	# Busca recursiva
	var main_node = get_tree().get_first_node_in_group("main")
	if not main_node:
		main_node = get_tree().root.get_node_or_null("Main")
	
	if main_node:
		var result = find_tilemap_recursive(main_node, "ResourceMap")
		if result:
			print("✅ ResourceMap encontrado via busca recursiva")
			return result
	
	return find_node_with_script("resource_map.gd")

# Busca recursiva por nome
func find_tilemap_recursive(node: Node, target_name: String) -> TileMapLayer:
	if node is TileMapLayer and node.name == target_name:
		return node
	
	for child in node.get_children():
		var result = find_tilemap_recursive(child, target_name)
		if result:
			return result
	
	return null

# Busca por script específico
func find_node_with_script(script_name: String) -> Node:
	return find_script_recursive(get_tree().root, script_name)

func find_script_recursive(node: Node, script_name: String) -> Node:
	if node.get_script() and node.get_script().resource_path.ends_with(script_name):
		return node
	
	for child in node.get_children():
		var result = find_script_recursive(child, script_name)
		if result:
			return result
	
	return null
