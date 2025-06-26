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
@export_range(0.0, 0.05) var stone_density: float = 0.01  # REDUZIDO de 0.03
@export_range(0.0, 0.025) var metal_density: float = 0.005  # REDUZIDO de 0.015
@export_range(1, 20) var resource_cluster_size: int = 6  # REDUZIDO de 8

@export_group("Distribuição por Bioma")
@export_range(0.0, 5.0) var mountain_bonus: float = 3.0
@export_range(0.0, 5.0) var hills_bonus: float = 2.0
@export_range(0.0, 1.0) var desert_penalty: float = 0.7

# === SISTEMA DE RECURSOS ===
var terrain_generator: TileMapLayer
var resource_configs = {
	"stone": {
		"atlas_coords": Vector2i(2, 0),
		"base_chance": 0.01,  # REDUZIDO
		"cluster_size": 6,    # REDUZIDO
		"biome_modifiers": {
			"mountain": 4.0,   # AUMENTADO
			"hills": 2.5,      # AUMENTADO
			"desert": 0.8,
			"grassland": 0.5,  # REDUZIDO
			"forest": 0.3,     # REDUZIDO
			"ocean": 0.0,
			"beach": 0.2       # REDUZIDO
		}
	},
	"metal": {
		"atlas_coords": Vector2i(3, 0),
		"base_chance": 0.005,  # REDUZIDO
		"cluster_size": 4,     # REDUZIDO
		"biome_modifiers": {
			"mountain": 6.0,   # AUMENTADO
			"hills": 3.0,      # AUMENTADO
			"grassland": 0.3,  # REDUZIDO
			"forest": 0.2,     # REDUZIDO
			"ocean": 0.0,
			"beach": 0.0,
			"desert": 0.4
		}
	}
}

func _ready():
	setup_tileset()
	find_terrain_generator()
	
	if not Engine.is_editor_hint():
		await get_tree().process_frame
		await get_tree().create_timer(0.5).timeout  # Aguarda terreno ser gerado
		generate()

func setup_tileset():
	"""Configura TileSet automaticamente"""
	if tile_set:
		return
	
	var new_tileset = TileSet.new()
	var atlas_source = TileSetAtlasSource.new()
	
	var texture_path = "res://TileSets/ResourcesTileSet.png"
	if not FileAccess.file_exists(texture_path):
		texture_path = "res://TileSets/textureAtlas.png"
	
	if not FileAccess.file_exists(texture_path):
		print("❌ Textura de recursos não encontrada")
		return
	
	atlas_source.texture = load(texture_path)
	atlas_source.texture_region_size = Vector2i(32, 32)
	
	# Cria tiles para recursos
	atlas_source.create_tile(Vector2i(2, 0))  # Pedra
	atlas_source.create_tile(Vector2i(3, 0))  # Metal
	
	new_tileset.add_source(atlas_source, 0)
	tile_set = new_tileset
	
	print("✅ ResourceGenerator: TileSet configurado")

func find_terrain_generator():
	"""Encontra o TerrainGenerator na cena"""
	print("🔍 Buscando TerrainGenerator...")
	
	# Lista completa de caminhos possíveis
	var possible_paths = [
		"../Terrain/TerrainMap",
		"../../Terrain/TerrainMap", 
		"/root/Main/Terrain/TerrainMap",
		"/root/WorldManager/Terrain/TerrainMap",
		"../TerrainMap",
		"../../TerrainMap"
	]
	
	# Testa caminhos diretos primeiro
	for path in possible_paths:
		var node = get_node_or_null(path)
		if node and node is TileMapLayer:
			terrain_generator = node
			print("✅ TerrainGenerator encontrado em: ", path)
			return
	
	# Busca recursiva na árvore principal
	var main_node = get_tree().root.get_node_or_null("Main")
	if not main_node:
		main_node = get_tree().root.get_node_or_null("WorldManager")
	
	if main_node:
		terrain_generator = find_terrain_recursive(main_node)
		if terrain_generator:
			print("✅ TerrainGenerator encontrado via busca recursiva em: ", terrain_generator.get_path())
			return
	
	# Busca global como último recurso
	terrain_generator = find_terrain_recursive(get_tree().root)
	if terrain_generator:
		print("✅ TerrainGenerator encontrado via busca global em: ", terrain_generator.get_path())
	else:
		print("❌ ERRO: TerrainGenerator não encontrado em lugar nenhum!")
		print("🔍 Estrutura atual da cena:")
		debug_scene_tree(get_tree().root, 0)

func find_terrain_recursive(node: Node) -> TileMapLayer:
	"""Busca recursiva pelo TerrainGenerator"""
	if node.name == "TerrainMap" and node is TileMapLayer and node.has_method("get_biome_at_position"):
		return node
	
	for child in node.get_children():
		var result = find_terrain_recursive(child)
		if result:
			return result
	
	return null

func debug_scene_tree(node: Node, depth: int):
	"""Debug da estrutura da cena"""
	if depth > 3:  # Limita profundidade
		return
		
	var indent = ""
	for i in range(depth):
		indent += "  "
	
	var info = indent + "📁 " + node.name + " (" + node.get_class() + ")"
	if node is TileMapLayer:
		info += " [TileMapLayer]"
	if node.get_script():
		info += " [Script]"
		
	print(info)
	
	for child in node.get_children():
		debug_scene_tree(child, depth + 1)

func generate():
	"""Gera recursos baseado no terreno"""
	print("🔧 Gerando recursos...")
	clear()
	
	if not terrain_generator:
		print("❌ TerrainGenerator não encontrado!")
		return
	
	var map_width = terrain_generator.map_width
	var map_height = terrain_generator.map_height
	var placed_resources = {}
	var resource_stats = {}
	
	# Inicializa estatísticas
	for resource_name in resource_configs:
		resource_stats[resource_name] = 0
	
	# Gera recursos por tipo
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
				
				# Obtém bioma
				var biome = terrain_generator.get_biome_at_position(x, y)
				
				# Calcula chance modificada por bioma
				var biome_modifier = config["biome_modifiers"].get(biome, 1.0)
				var final_chance = base_chance * biome_modifier
				
				# Testa geração
				if randf() < final_chance:
					var placed_count = generate_resource_cluster(pos, resource_name, resource_cluster_size_config, placed_resources)
					resource_stats[resource_name] += placed_count
	
	print_resource_statistics(resource_stats, map_width * map_height)
	print("✅ Recursos gerados com sucesso!")

func generate_resource_cluster(start_pos: Vector2i, resource_name: String, cluster_size_param: int, placed_resources: Dictionary) -> int:
	"""Gera um cluster de recursos"""
	var config = resource_configs[resource_name]
	var atlas_coords = config["atlas_coords"]
	var placed_count = 0
	
	var map_width = terrain_generator.map_width
	var map_height = terrain_generator.map_height
	
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
			set_cell(pos, 0, atlas_coords)
			placed_resources[str(pos)] = resource_name
			placed_count += 1
	
	return placed_count

func is_valid_position_for_resource(pos: Vector2i, resource_name: String) -> bool:
	"""Verifica se uma posição é válida para um recurso"""
	if not terrain_generator:
		return false
	
	var biome = terrain_generator.get_biome_at_position(pos.x, pos.y)
	var config = resource_configs[resource_name]
	var biome_modifier = config["biome_modifiers"].get(biome, 1.0)
	
	# Se modifier é 0, não pode colocar
	return biome_modifier > 0.0

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
