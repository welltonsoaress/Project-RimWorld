@tool
class_name ObjectGenerator
extends TileMapLayer

# === CONFIGURAÇÕES ===
@export_group("Controles")
@export var generate_objects: bool = false:
	set(value):
		if value:
			generate_objects = false
			generate()

@export var clear_objects: bool = false:
	set(value):
		if value:
			clear_objects = false
			clear()

# === CONFIGURAÇÕES REALISTAS TIPO RIMWORLD ===
@export_group("Densidade de Vegetação")
@export_range(0.0, 0.3) var grass_density: float = 0.08
@export_range(0.0, 0.15) var tree_density: float = 0.04
@export_range(0.0, 0.1) var bush_density: float = 0.02

@export_group("Modificadores por Bioma")
@export_range(0.0, 5.0) var forest_vegetation_bonus: float = 3.0
@export_range(0.0, 2.0) var grassland_bonus: float = 1.5
@export_range(0.0, 1.0) var desert_penalty: float = 0.1

# === SISTEMA DE OBJETOS ===
var terrain_generator: TileMapLayer
var resource_generator: TileMapLayer
var object_configs = {
	"grass": {
		"atlas_coords": Vector2i(0, 0),
		"base_chance": 0.08,
		"blocks_movement": false,
		"biome_preferences": {
			"grassland": 1.5,
			"forest": 2.0,
			"hills": 0.8,
			"beach": 0.3,
			"mountain": 0.2,
			"desert": 0.1,
			"ocean": 0.0
		}
	},
	"tree": {
		"atlas_coords": Vector2i(1, 0),
		"base_chance": 0.04,
		"blocks_movement": true,
		"biome_preferences": {
			"forest": 4.0,
			"grassland": 1.0,
			"hills": 0.6,
			"mountain": 0.3,
			"beach": 0.0,
			"desert": 0.05,
			"ocean": 0.0
		}
	},
	"bush": {
		"atlas_coords": Vector2i(2, 1),
		"base_chance": 0.02,
		"blocks_movement": false,
		"biome_preferences": {
			"forest": 2.0,
			"grassland": 1.2,
			"hills": 1.5,
			"desert": 0.3,
			"mountain": 0.4,
			"beach": 0.1,
			"ocean": 0.0
		}
	}
}

func _ready():
	setup_tileset()
	find_generators()
	
	if not Engine.is_editor_hint():
		await get_tree().process_frame
		await get_tree().create_timer(1.0).timeout  # Aguarda terreno e recursos
		generate()

func setup_tileset():
	"""Configura TileSet automaticamente"""
	if tile_set:
		return
	
	var new_tileset = TileSet.new()
	var atlas_source = TileSetAtlasSource.new()
	
	var texture_path = "res://TileSets/textureAtlas.png"
	if not FileAccess.file_exists(texture_path):
		print("❌ Textura de objetos não encontrada")
		return
	
	atlas_source.texture = load(texture_path)
	atlas_source.texture_region_size = Vector2i(32, 32)
	
	# Cria tiles para objetos
	atlas_source.create_tile(Vector2i(0, 0))  # Grama
	atlas_source.create_tile(Vector2i(1, 0))  # Árvore
	atlas_source.create_tile(Vector2i(2, 1))  # Arbusto
	
	new_tileset.add_source(atlas_source, 0)
	tile_set = new_tileset
	
	print("✅ ObjectGenerator: TileSet configurado")

func find_generators():
	"""Encontra outros geradores na cena"""
	print("🔍 ObjectGenerator buscando dependências...")
	
	# Busca TerrainGenerator com caminhos mais específicos baseado na estrutura vista
	var terrain_paths = [
		"../../Terrain/TerrainMap",  # Estrutura vista no debug
		"../Terrain/TerrainMap",
		"/root/Main/Terrain/TerrainMap",
		"../../../Terrain/TerrainMap"
	]
	
	for path in terrain_paths:
		var node = get_node_or_null(path)
		if node and node is TileMapLayer:
			terrain_generator = node
			print("✅ TerrainGenerator encontrado em: ", path)
			break
	
	# Se não encontrou, busca por grupo
	if not terrain_generator:
		var terrain_nodes = get_tree().get_nodes_in_group("terrain")
		if terrain_nodes.size() > 0:
			terrain_generator = terrain_nodes[0]
			print("✅ TerrainGenerator encontrado via grupo: ", terrain_generator.get_path())
	
	# Busca recursiva como último recurso
	if not terrain_generator:
		terrain_generator = find_terrain_recursive(get_tree().root)
		if terrain_generator:
			print("✅ TerrainGenerator encontrado via busca recursiva: ", terrain_generator.get_path())
	
	# Busca ResourceGenerator
	var resource_paths = [
		"../../Resource/ResourceMap",
		"../Resource/ResourceMap",
		"/root/Main/Resource/ResourceMap"
	]
	
	for path in resource_paths:
		var node = get_node_or_null(path)
		if node and node is TileMapLayer:
			resource_generator = node
			print("✅ ResourceGenerator encontrado em: ", path)
			break
	
	if not resource_generator:
		resource_generator = find_resource_recursive(get_tree().root)
	
	# Verifica resultados
	if terrain_generator:
		print("✅ TerrainGenerator configurado para ObjectGenerator")
	else:
		print("❌ ERRO: TerrainGenerator não encontrado!")
		print("🔍 Estrutura atual vista:")
		debug_scene_structure()
	
	if resource_generator:
		print("✅ ResourceGenerator encontrado para ObjectGenerator")

func find_terrain_recursive(node: Node) -> TileMapLayer:
	"""Busca recursiva pelo TerrainGenerator"""
	if node.name == "TerrainMap" and node is TileMapLayer:
		return node
	
	for child in node.get_children():
		var result = find_terrain_recursive(child)
		if result:
			return result
	
	return null

func find_resource_recursive(node: Node) -> TileMapLayer:
	"""Busca recursiva pelo ResourceGenerator"""
	if node.name == "ResourceMap" and node is TileMapLayer:
		return node
	
	for child in node.get_children():
		var result = find_resource_recursive(child)
		if result:
			return result
	
	return null

func generate():
	"""Gera objetos baseado no terreno e recursos"""
	print("🌿 Gerando objetos...")
	clear()
	
	# CORREÇÃO: Sempre re-busca antes de gerar
	if not terrain_generator:
		find_generators()
	
	if not terrain_generator:
		print("❌ TerrainGenerator não encontrado!")
		print("🔧 Tentando busca de emergência...")
		
		# Busca de emergência mais ampla
		var all_nodes = get_tree().get_nodes_in_group("terrain")
		if all_nodes.is_empty():
			# Busca por script específico
			terrain_generator = find_node_with_script("TerrainGenerator")
		else:
			terrain_generator = all_nodes[0]
		
		if not terrain_generator:
			print("❌ Impossível gerar objetos sem TerrainGenerator!")
			return
		else:
			print("✅ TerrainGenerator encontrado via busca de emergência")
	
	# CORREÇÃO: Força visibilidade
	visible = true
	enabled = true
	z_index = 2
	modulate = Color.WHITE
	
	var map_width = terrain_generator.get("map_width") if "map_width" in terrain_generator else 128
	var map_height = terrain_generator.get("map_height") if "map_height" in terrain_generator else 128
	var placed_objects = {}
	var object_stats = {}
	
	print("📍 Gerando objetos em mapa ", map_width, "x", map_height)
	
	# Inicializa estatísticas
	for object_name in object_configs:
		object_stats[object_name] = 0
	
	# Gera objetos por tipo
	for object_name in object_configs:
		var config = object_configs[object_name]
		var base_chance = config["base_chance"]
		
		for x in range(map_width):
			for y in range(map_height):
				var pos = Vector2i(x, y)
				
				# Verifica se já tem objeto
				if str(pos) in placed_objects:
					continue
				
				# Verifica se há recurso no local
				if resource_generator and resource_generator.get_cell_source_id(pos) != -1:
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
				var biome_preference = config["biome_preferences"].get(biome, 0.0)
				var final_chance = base_chance * biome_preference
				
				# Testa geração
				if randf() < final_chance:
					if place_object(pos, object_name, placed_objects):
						object_stats[object_name] += 1
	
	print_object_statistics(object_stats, map_width * map_height)
	print("✅ Objetos gerados com sucesso!")

func place_object(pos: Vector2i, object_name: String, placed_objects: Dictionary) -> bool:
	"""Coloca um objeto em uma posição"""
	if str(pos) in placed_objects:
		return false
	
	if is_valid_position_for_object(pos, object_name):
		var config = object_configs[object_name]
		var atlas_coords = config["atlas_coords"]
		
		set_cell(pos, 0, atlas_coords)
		placed_objects[str(pos)] = object_name
		return true
	
	return false

func is_valid_position_for_object(pos: Vector2i, object_name: String) -> bool:
	"""Verifica se uma posição é válida para um objeto"""
	if not terrain_generator:
		return false
	
	# Verifica se há recurso no local
	if resource_generator and resource_generator.get_cell_source_id(pos) != -1:
		return false
	
	# Verifica bioma
	var biome = terrain_generator.get_biome_at_position(pos.x, pos.y)
	var config = object_configs[object_name]
	var biome_preference = config["biome_preferences"].get(biome, 0.0)
	
	# Se preferência é 0, não pode colocar
	return biome_preference > 0.0

func print_object_statistics(stats: Dictionary, total_tiles: int):
	"""Imprime estatísticas dos objetos"""
	print("\n📊 === ESTATÍSTICAS DE OBJETOS ===")
	var total_objects = 0
	
	for object_name in stats:
		var count = stats[object_name]
		total_objects += count
		var density = float(count) / float(total_tiles) * 100.0
		print("🌿 ", object_name.capitalize(), ": ", count, " (", "%.3f" % density, "%)")
	
	var total_density = float(total_objects) / float(total_tiles) * 100.0
	print("📦 Total de objetos: ", total_objects, " (", "%.3f" % total_density, "%)")
	print("=== FIM ESTATÍSTICAS ===\n")

# === FUNÇÕES DE ANÁLISE ===
func get_objects_near_position(center_pos: Vector2i, radius: int = 5) -> Array:
	"""Retorna objetos próximos a uma posição"""
	var nearby_objects = []
	
	for x in range(center_pos.x - radius, center_pos.x + radius + 1):
		for y in range(center_pos.y - radius, center_pos.y + radius + 1):
			var pos = Vector2i(x, y)
			if get_cell_source_id(pos) != -1:
				var distance = center_pos.distance_to(Vector2(x, y))
				var atlas_coords = get_cell_atlas_coords(pos)
				var object_type = get_object_type_from_coords(atlas_coords)
				
				nearby_objects.append({
					"position": pos,
					"type": object_type,
					"distance": distance,
					"blocks_movement": object_configs.get(object_type, {}).get("blocks_movement", false)
				})
	
	# Ordena por distância
	nearby_objects.sort_custom(func(a, b): return a["distance"] < b["distance"])
	return nearby_objects

func get_object_type_from_coords(coords: Vector2i) -> String:
	"""Converte coordenadas do atlas em tipo de objeto"""
	if coords == Vector2i(0, 0):
		return "grass"
	elif coords == Vector2i(1, 0):
		return "tree"
	elif coords == Vector2i(2, 1):
		return "bush"
	return "unknown"

func get_coverage_by_biome() -> Dictionary:
	"""Retorna cobertura de objetos por bioma"""
	if not terrain_generator:
		return {}
	
	var coverage = {}
	var map_width = terrain_generator.get("map_width") if "map_width" in terrain_generator else 128
	var map_height = terrain_generator.get("map_height") if "map_height" in terrain_generator else 128
	
	# Amostragem para performance
	for x in range(0, map_width, 2):
		for y in range(0, map_height, 2):
			var biome = "grassland"
			if terrain_generator.has_method("get_biome_at_position"):
				biome = terrain_generator.get_biome_at_position(x, y)
			else:
				var terrain_tile = terrain_generator.get_cell_atlas_coords(Vector2i(x, y))
				biome = get_biome_from_terrain_tile(terrain_tile)
			
			if not biome in coverage:
				coverage[biome] = {"total": 0, "objects": 0}
			
			coverage[biome]["total"] += 1
			
			if get_cell_source_id(Vector2i(x, y)) != -1:
				coverage[biome]["objects"] += 1
	
	# Calcula percentuais
	for biome in coverage:
		var data = coverage[biome]
		if data["total"] > 0:
			data["coverage_percent"] = float(data["objects"]) / float(data["total"]) * 100.0
		else:
			data["coverage_percent"] = 0.0
	
	return coverage

# === FUNÇÕES QUE ESTAVAM FALTANDO ===

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

func debug_scene_structure():
	"""Debug da estrutura da cena"""
	print("🔍 Estrutura vista do ObjectGenerator:")
	print("  - Nó atual: ", get_path())
	@warning_ignore("incompatible_ternary")
	print("  - Pai: ", get_parent().get_path() if get_parent() else "N/A")
	@warning_ignore("incompatible_ternary")
	print("  - Avô: ", get_parent().get_parent().get_path() if get_parent() and get_parent().get_parent() else "N/A")
	
	var main_node = get_tree().root.get_node_or_null("Main")
	if main_node:
		print("  - Main encontrado: ", main_node.get_path())
		var terrain_node = main_node.get_node_or_null("Terrain/TerrainMap")
		if terrain_node:
			print("  - TerrainMap em Main: ", terrain_node.get_path())
		else:
			print("  - TerrainMap NÃO encontrado em Main/Terrain/TerrainMap")
