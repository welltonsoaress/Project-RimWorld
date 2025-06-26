@tool
class_name ResourceGenerator
extends TileMapLayer

# === CONFIGURAÇÕES ===
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

# === CONFIGURAÇÕES REALISTAS TIPO RIMWORLD ===
@export_group("Densidade de Recursos")
@export_range(0.0, 0.08) var stone_density: float = 0.03  # AUMENTADO
@export_range(0.0, 0.04) var metal_density: float = 0.015  # AUMENTADO
@export_range(1, 20) var resource_cluster_size: int = 8

@export_group("Distribuição por Bioma")
@export_range(0.0, 5.0) var mountain_bonus: float = 3.0
@export_range(0.0, 5.0) var hills_bonus: float = 2.0
@export_range(0.0, 1.0) var desert_penalty: float = 0.7

# === SISTEMA DE RECURSOS ===
var terrain_generator: TileMapLayer
var resource_configs = {
	"stone": {
		"atlas_coords": Vector2i(2, 0),
		"base_chance": 0.03,  # AUMENTADO
		"cluster_size": 8,
		"biome_modifiers": {
			"mountain": 4.0,
			"hills": 2.5,
			"desert": 0.8,
			"grassland": 1.0,
			"forest": 0.7,
			"ocean": 0.0,
			"beach": 0.4
		}
	},
	"metal": {
		"atlas_coords": Vector2i(3, 0),
		"base_chance": 0.015,  # AUMENTADO
		"cluster_size": 6,
		"biome_modifiers": {
			"mountain": 6.0,
			"hills": 3.0,
			"grassland": 0.5,
			"forest": 0.3,
			"ocean": 0.0,
			"beach": 0.0,
			"desert": 0.4
		}
	}
}

func _ready():
	print("🔧 ResourceGenerator iniciado")
	add_to_group("resources")
	
	setup_tileset()
	
	# CORREÇÃO: Força configurações visuais
	visible = true
	enabled = true
	z_index = 1
	scale = Vector2(1.0, 1.0)  # CORREÇÃO: Força escala 2.0
	position = Vector2(0, 0)
	
	print("✅ ResourceMap configurado: visible=", visible, " scale=", scale, " z_index=", z_index)
	
	if not Engine.is_editor_hint():
		await get_tree().process_frame
		await get_tree().create_timer(1.5).timeout  # CORREÇÃO: Aguarda mais tempo
		find_terrain_generator()
		generate()

func setup_tileset():
	"""Configura TileSet automaticamente"""
	if tile_set:
		return
	
	var new_tileset = TileSet.new()
	var atlas_source = TileSetAtlasSource.new()
	
	var texture_path = "res://TileSets/ResourcesTileSet.png"
	if not FileAccess.file_exists(texture_path):
		print("❌ Textura de recursos não encontrada")
		return
	
	atlas_source.texture = load(texture_path)
	atlas_source.texture_region_size = Vector2i(32, 32)
	
	# CORREÇÃO: Cria tiles para recursos com source 0
	atlas_source.create_tile(Vector2i(2, 0))  # Pedra
	atlas_source.create_tile(Vector2i(3, 0))  # Metal
	
	new_tileset.add_source(atlas_source, 0)
	tile_set = new_tileset
	
	print("✅ ResourceGenerator: TileSet configurado")

func find_terrain_generator():
	"""Encontra o TerrainGenerator na cena - VERSÃO MELHORADA"""
	print("🔍 Buscando TerrainGenerator...")
	
	# CORREÇÃO: Lista de caminhos baseada na estrutura vista no debug
	var possible_paths = [
		"../../Terrain/TerrainMap",  # Estrutura vista no debug
		"../Terrain/TerrainMap",
		"/root/Main/Terrain/TerrainMap",
		"../../../Terrain/TerrainMap"
	]
	
	# Testa caminhos diretos primeiro
	for path in possible_paths:
		var node = get_node_or_null(path)
		if node and node is TileMapLayer:
			terrain_generator = node
			print("✅ TerrainGenerator encontrado em: ", path)
			return
	
	# Busca por grupo
	var terrain_nodes = get_tree().get_nodes_in_group("terrain")
	if terrain_nodes.size() > 0:
		terrain_generator = terrain_nodes[0]
		print("✅ TerrainGenerator encontrado via grupo: ", terrain_generator.get_path())
		return
	
	# Busca recursiva como último recurso
	terrain_generator = find_terrain_recursive(get_tree().root)
	if terrain_generator:
		print("✅ TerrainGenerator encontrado via busca recursiva: ", terrain_generator.get_path())
	else:
		print("❌ ERRO: TerrainGenerator não encontrado!")

func find_terrain_recursive(node: Node) -> TileMapLayer:
	"""Busca recursiva pelo TerrainGenerator"""
	if node.name == "TerrainMap" and node is TileMapLayer:
		return node
	
	for child in node.get_children():
		var result = find_terrain_recursive(child)
		if result:
			return result
	
	return null

func generate():
	"""Gera recursos baseado no terreno - VERSÃO CORRIGIDA"""
	print("🔧 Gerando recursos...")
	clear()
	
	# CORREÇÃO: Sempre re-busca antes de gerar
	if not terrain_generator:
		find_terrain_generator()
	
	if not terrain_generator:
		print("❌ TerrainGenerator não encontrado! Tentando busca de emergência...")
		
		# Busca de emergência mais ampla
		var all_nodes = get_tree().get_nodes_in_group("terrain")
		if all_nodes.is_empty():
			# Busca por script específico
			terrain_generator = find_node_with_script("TerrainGenerator")
		else:
			terrain_generator = all_nodes[0]
		
		if not terrain_generator:
			print("❌ Impossível gerar recursos sem TerrainGenerator!")
			return
		else:
			print("✅ TerrainGenerator encontrado via busca de emergência")
	
	# CORREÇÃO: Força visibilidade
	
	var map_width = terrain_generator.get("map_width") if "map_width" in terrain_generator else 128
	var map_height = terrain_generator.get("map_height") if "map_height" in terrain_generator else 128
	var placed_resources = {}
	var resource_stats = {}
	
	print("📍 Gerando recursos em mapa ", map_width, "x", map_height)
	
	# Inicializa estatísticas
	for resource_name in resource_configs:
		resource_stats[resource_name] = 0
	
	# CORREÇÃO: Gera recursos por tipo com chances aumentadas
	for resource_name in resource_configs:
		var config = resource_configs[resource_name]
		var base_chance = config["base_chance"]
		var resource_cluster_size_config = config["cluster_size"]
		
		for x in range(map_width):
			for y in range(map_height):
				var pos = Vector2i(x, y)
				
				# Verifica se já tem recurso
				if str(pos) in placed_resources:
					continue
				
				# Obtém bioma com fallback robusto
				var biome = "grassland"  # Fallback
				if terrain_generator.has_method("get_biome_at_position"):
					biome = terrain_generator.get_biome_at_position(x, y)
				else:
					# Fallback baseado no tile
					var terrain_tile = terrain_generator.get_cell_atlas_coords(pos)
					biome = get_biome_from_terrain_tile(terrain_tile)
				
				# Calcula chance modificada por bioma
				var biome_modifier = config["biome_modifiers"].get(biome, 1.0)
				var final_chance = base_chance * biome_modifier
				
				# CORREÇÃO: Chance mínima para garantir recursos
				final_chance = max(final_chance, 0.001)
				
				# Testa geração
				if randf() < final_chance:
					var placed_count = generate_resource_cluster(pos, resource_name, resource_cluster_size_config, placed_resources)
					resource_stats[resource_name] += placed_count
	
	print_resource_statistics(resource_stats, map_width * map_height)
	
	# CORREÇÃO: Debug final e força refresh
	var total_resources = resource_stats.values().reduce(func(a, b): return a + b, 0)
	print("🔧 TOTAL de recursos colocados: ", total_resources)
	
	# Força atualização visual
	queue_redraw()
	
	print("✅ Recursos gerados com sucesso!")

func generate_resource_cluster(start_pos: Vector2i, resource_name: String, cluster_size_param: int, placed_resources: Dictionary) -> int:
	"""Gera um cluster de recursos"""
	var config = resource_configs[resource_name]
	var atlas_coords = config["atlas_coords"]
	var placed_count = 0
	
	var map_width = terrain_generator.get("map_width") if "map_width" in terrain_generator else 128
	var map_height = terrain_generator.get("map_height") if "map_height" in terrain_generator else 128
	
	for i in range(cluster_size_param):
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
			set_cell(pos, 0, atlas_coords)  # CORREÇÃO: Usa source 0
			placed_resources[str(pos)] = resource_name
			placed_count += 1
			
	
	return placed_count

func is_valid_position_for_resource(pos: Vector2i, resource_name: String) -> bool:
	"""Verifica se uma posição é válida para um recurso"""
	if not terrain_generator:
		return false
	
	# Obtém bioma
	var biome = "grassland"
	if terrain_generator.has_method("get_biome_at_position"):
		biome = terrain_generator.get_biome_at_position(pos.x, pos.y)
	else:
		var terrain_tile = terrain_generator.get_cell_atlas_coords(pos)
		biome = get_biome_from_terrain_tile(terrain_tile)
	
	var config = resource_configs[resource_name]
	var biome_modifier = config["biome_modifiers"].get(biome, 1.0)
	
	# Se modifier é 0, não pode colocar
	return biome_modifier > 0.0

func get_biome_from_terrain_tile(terrain_tile: Vector2i) -> String:
	"""Converte tile de terreno em nome de bioma"""
	match terrain_tile:
		Vector2i(0, 1):  # Água
			return "ocean"
		Vector2i(1, 1):  # Areia praia
			return "beach"
		Vector2i(2, 1):  # Areia deserto
			return "desert"
		Vector2i(0, 0):  # Grama clara
			return "grassland"
		Vector2i(1, 0):  # Grama escura/floresta
			return "forest"
		Vector2i(2, 0):  # Terra/colinas
			return "hills"
		Vector2i(3, 0):  # Pedra/montanhas
			return "mountain"
		_:
			return "grassland"

func print_resource_statistics(stats: Dictionary, total_tiles: int):
	"""Imprime estatísticas dos recursos"""
	print("\n📊 === ESTATÍSTICAS DE RECURSOS ===")
	var total_resources = 0
	
	for resource_name in stats:
		var count = stats[resource_name]
		total_resources += count
		var density = float(count) / float(total_tiles) * 100.0
		print("🔧 ", resource_name.capitalize(), ": ", count, " (", "%.3f" % density, "%)")
	
	var total_density = float(total_resources) / float(total_tiles) * 100.0
	print("📦 Total de recursos: ", total_resources, " (", "%.3f" % total_density, "%)")
	print("=== FIM ESTATÍSTICAS ===\n")

# === FUNÇÕES DE ANÁLISE ===
func get_resources_near_position(center_pos: Vector2i, radius: int = 5) -> Array:
	"""Retorna recursos próximos a uma posição"""
	var nearby_resources = []
	
	for x in range(center_pos.x - radius, center_pos.x + radius + 1):
		for y in range(center_pos.y - radius, center_pos.y + radius + 1):
			var pos = Vector2i(x, y)
			if get_cell_source_id(pos) != -1:
				var distance = center_pos.distance_to(Vector2(x, y))
				var atlas_coords = get_cell_atlas_coords(pos)
				var resource_type = get_resource_type_from_coords(atlas_coords)
				
				nearby_resources.append({
					"position": pos,
					"type": resource_type,
					"distance": distance
				})
	
	# Ordena por distância
	nearby_resources.sort_custom(func(a, b): return a["distance"] < b["distance"])
	return nearby_resources

func get_resource_type_from_coords(coords: Vector2i) -> String:
	"""Converte coordenadas do atlas em tipo de recurso"""
	if coords == Vector2i(2, 0):
		return "stone"
	elif coords == Vector2i(3, 0):
		return "metal"
	return "unknown"

func find_node_with_script(script_name: String) -> TileMapLayer:
	"""Busca nó por nome de script"""
	return find_script_recursive(get_tree().root, script_name)

func find_script_recursive(node: Node, script_name: String) -> TileMapLayer:
	"""Busca recursiva por script"""
	if node is TileMapLayer and node.get_script() and node.get_script().resource_path.get_file().begins_with(script_name):
		return node
	
	for child in node.get_children():
		var result = find_script_recursive(child, script_name)
		if result:
			return result
	
	return null
