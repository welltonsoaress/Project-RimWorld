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

@export_group("Debug")
@export var debug_object_placement: bool = false

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
		# CORREÇÃO: Aguarda muito mais tempo para garantir que recursos foram gerados primeiro
		await get_tree().create_timer(2.0).timeout
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
	
	# Busca TerrainGenerator
	var terrain_paths = [
		"../../Terrain/TerrainMap",
		"../Terrain/TerrainMap",
		"/root/Main/Terrain/TerrainMap"
	]
	
	for path in terrain_paths:
		var node = get_node_or_null(path)
		if node and node is TileMapLayer:
			terrain_generator = node
			print("✅ TerrainGenerator encontrado em: ", path)
			break
	
	if not terrain_generator:
		var terrain_nodes = get_tree().get_nodes_in_group("terrain")
		if terrain_nodes.size() > 0:
			terrain_generator = terrain_nodes[0]
			print("✅ TerrainGenerator encontrado via grupo: ", terrain_generator.get_path())
	
	# CORREÇÃO: Busca ResourceGenerator de forma mais robusta
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
		var resource_nodes = get_tree().get_nodes_in_group("resources")
		if resource_nodes.size() > 0:
			resource_generator = resource_nodes[0]
			print("✅ ResourceGenerator encontrado via grupo: ", resource_generator.get_path())
	
	# Verifica resultados
	if terrain_generator:
		print("✅ TerrainGenerator configurado para ObjectGenerator")
	else:
		print("❌ ERRO: TerrainGenerator não encontrado!")
	
	if resource_generator:
		print("✅ ResourceGenerator encontrado para ObjectGenerator")
	else:
		print("❌ AVISO: ResourceGenerator não encontrado - objetos podem aparecer sobre pedras!")

func generate():
	"""Gera objetos baseado no terreno e recursos - VERSÃO CORRIGIDA"""
	print("🌿 Gerando objetos (evitando pedras)...")
	clear()
	
	# CORREÇÃO: Re-busca geradores antes de gerar
	if not terrain_generator or not resource_generator:
		find_generators()
	
	if not terrain_generator:
		print("❌ TerrainGenerator não encontrado!")
		return
	
	# CORREÇÃO: Força visibilidade e posicionamento
	visible = true
	enabled = true
	z_index = 2
	scale = Vector2(2.0, 2.0)
	position = Vector2(0, 0)
	modulate = Color.WHITE
	
	var map_width = terrain_generator.get("map_width") if "map_width" in terrain_generator else 128
	var map_height = terrain_generator.get("map_height") if "map_height" in terrain_generator else 128
	var placed_objects = {}
	var object_stats = {}
	var blocked_by_resources = 0
	var blocked_by_water = 0
	
	print("📍 Gerando objetos em mapa ", map_width, "x", map_height)
	
	# Inicializa estatísticas
	for object_name in object_configs:
		object_stats[object_name] = 0
	
	# CORREÇÃO: Gera objetos por tipo, verificando recursos primeiro
	for object_name in object_configs:
		var config = object_configs[object_name]
		var base_chance = config["base_chance"]
		
		for x in range(map_width):
			for y in range(map_height):
				var pos = Vector2i(x, y)
				
				# Verifica se já tem objeto
				if str(pos) in placed_objects:
					continue
				
				# CORREÇÃO PRINCIPAL: Verifica se há pedra/recurso no local PRIMEIRO
				if resource_generator and resource_generator.get_cell_source_id(pos) != -1:
					blocked_by_resources += 1
					if debug_object_placement and blocked_by_resources <= 5:
						print("🚫 Objeto bloqueado por recurso em: ", pos)
					continue
				
				# CORREÇÃO: Verifica se é água (oceano)
				var biome = "grassland"  # Fallback
				if terrain_generator.has_method("get_biome_at_position"):
					biome = terrain_generator.get_biome_at_position(x, y)
				else:
					var terrain_tile = terrain_generator.get_cell_atlas_coords(pos)
					biome = get_biome_from_terrain_tile(terrain_tile)
				
				# CORREÇÃO: Bloqueia objetos em água
				if biome == "ocean":
					blocked_by_water += 1
					continue
				
				# Calcula chance modificada por bioma
				var biome_preference = config["biome_preferences"].get(biome, 0.0)
				var final_chance = base_chance * biome_preference
				
				# Testa geração
				if randf() < final_chance:
					if place_object_safe(pos, object_name, placed_objects):
						object_stats[object_name] += 1
	
	print("🚫 Objetos bloqueados - Recursos: ", blocked_by_resources, " Água: ", blocked_by_water)
	print_object_statistics(object_stats, map_width * map_height)
	print("✅ Objetos gerados evitando pedras!")

func place_object_safe(pos: Vector2i, object_name: String, placed_objects: Dictionary) -> bool:
	"""Coloca um objeto em uma posição COM VERIFICAÇÃO DE RECURSOS"""
	if str(pos) in placed_objects:
		return false
	
	# CORREÇÃO: Verificação dupla de recursos
	if resource_generator and resource_generator.get_cell_source_id(pos) != -1:
		if debug_object_placement:
			print("🚫 Tentativa de colocar objeto sobre recurso em: ", pos)
		return false
	
	if is_valid_position_for_object_safe(pos, object_name):
		var config = object_configs[object_name]
		var atlas_coords = config["atlas_coords"]
		
		set_cell(pos, 0, atlas_coords)
		placed_objects[str(pos)] = object_name
		
		if debug_object_placement and placed_objects.size() <= 10:
			print("🌿 Objeto '", object_name, "' colocado em: ", pos)
		
		return true
	
	return false

func is_valid_position_for_object_safe(pos: Vector2i, object_name: String) -> bool:
	"""Verifica se uma posição é válida para um objeto - VERSÃO SEGURA"""
	if not terrain_generator:
		return false
	
	# CORREÇÃO: Verificação tripla de recursos (para garantir)
	if resource_generator and resource_generator.get_cell_source_id(pos) != -1:
		return false
	
	# Verifica bioma
	var biome = "grassland"
	if terrain_generator.has_method("get_biome_at_position"):
		biome = terrain_generator.get_biome_at_position(pos.x, pos.y)
	else:
		var terrain_tile = terrain_generator.get_cell_atlas_coords(pos)
		biome = get_biome_from_terrain_tile(terrain_tile)
	
	# CORREÇÃO: Não permite objetos em água
	if biome == "ocean":
		return false
	
	var config = object_configs[object_name]
	var biome_preference = config["biome_preferences"].get(biome, 0.0)
	
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
				coverage[biome] = {"total": 0, "objects": 0, "blocked_by_resources": 0}
			
			coverage[biome]["total"] += 1
			
			# Verifica se tem objeto
			if get_cell_source_id(Vector2i(x, y)) != -1:
				coverage[biome]["objects"] += 1
			
			# Verifica se foi bloqueado por recurso
			if resource_generator and resource_generator.get_cell_source_id(Vector2i(x, y)) != -1:
				coverage[biome]["blocked_by_resources"] += 1
	
	# Calcula percentuais
	for biome in coverage:
		var data = coverage[biome]
		if data["total"] > 0:
			data["coverage_percent"] = float(data["objects"]) / float(data["total"]) * 100.0
			data["blocked_percent"] = float(data["blocked_by_resources"]) / float(data["total"]) * 100.0
		else:
			data["coverage_percent"] = 0.0
			data["blocked_percent"] = 0.0
	
	return coverage

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

# === FUNÇÕES DE DEBUG ===
@export_group("Debug e Análise")
@export var analyze_object_coverage: bool = false:
	set(value):
		if value:
			analyze_object_coverage = false
			analyze_coverage_vs_resources()

@export var test_resource_collision: bool = false:
	set(value):
		if value:
			test_resource_collision = false
			test_collision_detection()

func analyze_coverage_vs_resources():
	"""Analisa cobertura de objetos vs recursos por bioma"""
	print("\n📊 === ANÁLISE OBJETOS VS RECURSOS ===")
	
	var coverage = get_coverage_by_biome()
	
	for biome in coverage:
		var data = coverage[biome]
		print("🌍 ", biome.capitalize(), ":")
		print("  - Total tiles: ", data["total"])
		print("  - Objetos: ", data["objects"], " (", "%.1f" % data["coverage_percent"], "%)")
		print("  - Bloqueados por recursos: ", data["blocked_by_resources"], " (", "%.1f" % data["blocked_percent"], "%)")
		
		var available_for_objects = data["total"] - data["blocked_by_resources"]
		if available_for_objects > 0:
			var effective_coverage = float(data["objects"]) / float(available_for_objects) * 100.0
			print("  - Cobertura efetiva: ", "%.1f" % effective_coverage, "% (excluindo recursos)")
	
	print("=== FIM ANÁLISE ===\n")

func test_collision_detection():
	"""Testa detecção de colisão com recursos"""
	print("\n🧪 === TESTE DETECÇÃO DE COLISÃO ===")
	
	if not resource_generator:
		print("❌ ResourceGenerator não encontrado para teste")
		return
	
	var collision_count = 0
	var sample_size = 100
	
	for i in range(sample_size):
		var x = randi_range(10, 118)
		var y = randi_range(10, 118)
		var pos = Vector2i(x, y)
		
		var has_resource = resource_generator.get_cell_source_id(pos) != -1
		var has_object = get_cell_source_id(pos) != -1
		
		if has_resource and has_object:
			collision_count += 1
			print("❌ COLISÃO DETECTADA em: ", pos)
	
	print("🎯 Resultado do teste:")
	print("  - Amostras testadas: ", sample_size)
	print("  - Colisões encontradas: ", collision_count)
	
	if collision_count == 0:
		print("✅ Nenhuma colisão detectada - sistema funcionando!")
	else:
		print("⚠️ Colisões encontradas - verificar lógica de geração")
	
	print("=== FIM TESTE ===\n")

# Sistema para manter posicionamento correto
func _process(_delta):
	if not Engine.is_editor_hint():
		if position != Vector2(0, 0) or scale != Vector2(2.0, 2.0):
			position = Vector2(0, 0)
			scale = Vector2(2.0, 2.0)
