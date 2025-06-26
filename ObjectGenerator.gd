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

# === CONFIGURAÇÕES DE DENSIDADE ===
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
var map_width: int = 128
var map_height: int = 128
var occupied_positions: Dictionary = {}  # Posições ocupadas por recursos

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
	print("🌿 ObjectGenerator iniciado")
	add_to_group("objects")  # CORREÇÃO CRÍTICA: Adiciona ao grupo
	
	setup_tileset()
	find_generators()
	
	if not Engine.is_editor_hint():
		await get_tree().process_frame
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
	
	atlas_source.create_tile(Vector2i(0, 0))  # Grama
	atlas_source.create_tile(Vector2i(1, 0))  # Árvore
	atlas_source.create_tile(Vector2i(2, 1))  # Arbusto
	
	new_tileset.add_source(atlas_source, 0)
	tile_set = new_tileset
	
	print("✅ ObjectGenerator: TileSet configurado")

func find_generators():
	"""Encontra outros geradores na cena - VERSÃO MELHORADA"""
	print("🔍 ObjectGenerator buscando dependências...")
	
	# Busca TerrainGenerator
	var terrain_nodes = get_tree().get_nodes_in_group("terrain")
	if terrain_nodes.size() > 0:
		terrain_generator = terrain_nodes[0]
		# Obtém dimensões do mapa
		if "map_width" in terrain_generator:
			map_width = terrain_generator.map_width
		if "map_height" in terrain_generator:
			map_height = terrain_generator.map_height
		print("✅ TerrainGenerator encontrado: ", terrain_generator.get_path())
		print("📏 Dimensões do mapa: ", map_width, "x", map_height)
	else:
		print("❌ ERRO: TerrainGenerator não encontrado!")
	
	# Busca ResourceGenerator
	var resource_nodes = get_tree().get_nodes_in_group("resources")
	if resource_nodes.size() > 0:
		resource_generator = resource_nodes[0]
		print("✅ ResourceGenerator encontrado: ", resource_generator.get_path())
	else:
		print("❌ AVISO: ResourceGenerator não encontrado!")

func generate():
	"""Gera objetos evitando sobreposição com recursos - VERSÃO MELHORADA"""
	print("🌿 Gerando objetos evitando recursos...")
	clear()
	
	if not terrain_generator or not resource_generator:
		find_generators()
	
	if not terrain_generator:
		print("❌ TerrainGenerator não encontrado!")
		return
	
	force_correct_positioning()
	
	# MELHORIA: Se não temos posições ocupadas mapeadas, mapeia agora
	if occupied_positions.is_empty():
		map_resource_positions()
	
	var placed_objects = {}
	var object_stats = {}
	var blocked_by_resources = 0
	var blocked_by_water = 0
	
	print("📍 Gerando objetos em mapa ", map_width, "x", map_height)
	print("🚫 Posições bloqueadas por recursos: ", occupied_positions.size())
	
	# Inicializa estatísticas
	for object_name in object_configs:
		object_stats[object_name] = 0
	
	# Gera objetos por tipo, verificando recursos primeiro
	for object_name in object_configs:
		var config = object_configs[object_name]
		var base_chance = config["base_chance"]
		
		for x in range(map_width):
			for y in range(map_height):
				var pos = Vector2i(x, y)
				
				# Verifica se já tem objeto
				if str(pos) in placed_objects:
					continue
				
				# CORREÇÃO PRINCIPAL: Verifica posições ocupadas PRIMEIRO
				if is_position_blocked(pos):
					blocked_by_resources += 1
					continue
				
				# Verifica se é água
				var biome = get_biome_at_position(pos)
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
	print("✅ Objetos gerados evitando recursos!")

func map_resource_positions():
	"""Mapeia posições ocupadas por recursos"""
	print("📍 Mapeando posições de recursos...")
	
	occupied_positions.clear()
	
	if not resource_generator:
		return
	
	var count = 0
	for x in range(map_width):
		for y in range(map_height):
			var pos = Vector2i(x, y)
			if resource_generator.get_cell_source_id(pos) != -1:
				occupied_positions[str(pos)] = true
				count += 1
	
	print("🗺️ ", count, " posições de recursos mapeadas")

func set_occupied_positions(positions: Dictionary):
	"""Define posições ocupadas externamente (usado pelo coordenador)"""
	occupied_positions = positions
	print("📍 Recebidas ", positions.size(), " posições ocupadas")

func is_position_blocked(pos: Vector2i) -> bool:
	"""Verifica se uma posição está bloqueada por recursos"""
	# Método 1: Verifica no mapa de posições ocupadas (mais rápido)
	if str(pos) in occupied_positions:
		return true
	
	# Método 2: Verifica diretamente no ResourceGenerator (redundância)
	if resource_generator and resource_generator.get_cell_source_id(pos) != -1:
		return true
	
	return false 
	
	print("✅ Objetos gerados evitando recursos!")

func place_object_safe(pos: Vector2i, object_name: String, placed_objects: Dictionary) -> bool:
	"""Coloca um objeto COM VERIFICAÇÃO MÚLTIPLA DE RECURSOS"""
	if str(pos) in placed_objects:
		return false
	
	# CORREÇÃO: Verificação múltipla para total segurança
	if is_position_blocked(pos):
		if debug_object_placement:
			print("🚫 Tentativa de colocar objeto sobre recurso em: ", pos)
		return false
	
	if is_valid_position_for_object(pos, object_name):
		var config = object_configs[object_name]
		var atlas_coords = config["atlas_coords"]
		
		set_cell(pos, 0, atlas_coords)
		placed_objects[str(pos)] = object_name
		
		if debug_object_placement and placed_objects.size() <= 10:
			print("🌿 Objeto '", object_name, "' colocado em: ", pos)
		
		return true
	
	return false

func is_valid_position_for_object(pos: Vector2i, object_name: String) -> bool:
	"""Verifica se uma posição é válida para um objeto"""
	if not terrain_generator:
		return false
	
	# CORREÇÃO: Verificação de recursos usando método melhorado
	if is_position_blocked(pos):
		return false
	
	# Verifica bioma
	var biome = get_biome_at_position(pos)
	if biome == "ocean":
		return false
	
	var config = object_configs[object_name]
	var biome_preference = config["biome_preferences"].get(biome, 0.0)
	
	return biome_preference > 0.0

func get_biome_at_position(pos: Vector2i) -> String:
	"""Obtém bioma em uma posição"""
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

func force_correct_positioning():
	"""Força posicionamento correto"""
	visible = true
	enabled = true
	z_index = 2
	scale = Vector2(2.0, 2.0)
	position = Vector2(0, 0)
	modulate = Color.WHITE

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

# === VERIFICAÇÃO DE COLISÕES ===
@export_group("Debug e Verificação")
@export var verify_no_collisions: bool = false:
	set(value):
		if value:
			verify_no_collisions = false
			check_collisions_with_resources()

func check_collisions_with_resources():
	"""Verifica se há colisões entre objetos e recursos"""
	print("\n🔍 === VERIFICAÇÃO DE COLISÕES ===")
	
	if not resource_generator:
		print("❌ ResourceGenerator não encontrado")
		return
	
	var collision_count = 0
	var sample_positions = []
	
	for x in range(0, map_width, 4):  # Amostragem
		for y in range(0, map_height, 4):
			var pos = Vector2i(x, y)
			
			var has_resource = resource_generator.get_cell_source_id(pos) != -1
			var has_object = get_cell_source_id(pos) != -1
			
			if has_resource and has_object:
				collision_count += 1
				if sample_positions.size() < 5:
					sample_positions.append(pos)
	
	print("🎯 Resultado da verificação:")
	print("  - Colisões encontradas: ", collision_count)
	
	if collision_count == 0:
		print("✅ Nenhuma colisão detectada - sistema funcionando!")
	else:
		print("⚠️ Colisões encontradas:")
		for pos in sample_positions:
			print("    ❌ Colisão em: ", pos)
	
	print("=== FIM VERIFICAÇÃO ===\n")

func _process(_delta):
	if not Engine.is_editor_hint():
		if position != Vector2(0, 0) or scale != Vector2(2.0, 2.0):
			position = Vector2(0, 0)
			scale = Vector2(2.0, 2.0)
