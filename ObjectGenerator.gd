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
@export_range(0.0, 0.3) var grass_density: float = 0.06  # Reduzido
@export_range(0.0, 0.15) var tree_density: float = 0.03  # Reduzido
@export_range(0.0, 0.1) var bush_density: float = 0.015  # Reduzido

# === CONFIGURAÇÕES DE ESPAÇAMENTO ===
@export_group("Espaçamento de Recursos")
@export_range(1, 5) var resource_avoidance_radius: int = 2  # Raio de evitação de recursos
@export_range(1, 3) var object_spacing: int = 1  # Espaçamento mínimo entre objetos

@export_group("Modificadores por Bioma")
@export_range(0.0, 5.0) var forest_vegetation_bonus: float = 2.5
@export_range(0.0, 2.0) var grassland_bonus: float = 1.2
@export_range(0.0, 1.0) var desert_penalty: float = 0.15

@export_group("Debug")
@export var debug_object_placement: bool = false

# === SISTEMA DE OBJETOS ===
var terrain_generator: TileMapLayer
var resource_generator: TileMapLayer
var map_width: int = 128
var map_height: int = 128
var occupied_positions: Dictionary = {}  # Posições ocupadas por recursos
var placed_objects: Dictionary = {}  # Posições ocupadas por objetos já colocados

var object_configs = {
	"grass": {
		"atlas_coords": Vector2i(0, 0),
		"base_chance": 0.06,
		"blocks_movement": false,
		"biome_preferences": {
			"grassland": 1.2,
			"forest": 1.8,
			"hills": 0.7,
			"beach": 0.2,
			"mountain": 0.1,
			"desert": 0.08,
			"ocean": 0.0
		}
	},
	"tree": {
		"atlas_coords": Vector2i(1, 0),
		"base_chance": 0.03,
		"blocks_movement": true,
		"biome_preferences": {
			"forest": 3.0,
			"grassland": 0.8,
			"hills": 0.5,
			"mountain": 0.2,
			"beach": 0.0,
			"desert": 0.03,
			"ocean": 0.0
		}
	},
	"bush": {
		"atlas_coords": Vector2i(2, 1),
		"base_chance": 0.015,
		"blocks_movement": false,
		"biome_preferences": {
			"forest": 1.5,
			"grassland": 1.0,
			"hills": 1.2,
			"desert": 0.2,
			"mountain": 0.3,
			"beach": 0.05,
			"ocean": 0.0
		}
	}
}

func _ready():
	print("🌿 ObjectGenerator iniciado")
	add_to_group("objects")
	
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
	"""Encontra outros geradores na cena"""
	print("🔍 ObjectGenerator buscando dependências...")
	
	# Busca TerrainGenerator
	var terrain_nodes = get_tree().get_nodes_in_group("terrain")
	if terrain_nodes.size() > 0:
		terrain_generator = terrain_nodes[0]
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
	"""Gera objetos evitando sobreposição com recursos - VERSÃO MELHORADA COM ESPAÇAMENTO"""
	print("🌿 Gerando objetos com espaçamento de recursos...")
	clear()
	placed_objects.clear()
	
	if not terrain_generator or not resource_generator:
		find_generators()
	
	if not terrain_generator:
		print("❌ TerrainGenerator não encontrado!")
		return
	
	force_correct_positioning()
	
	# MELHORIA: Mapeia posições ocupadas com área de influência
	map_resource_positions_with_buffer()
	
	var object_stats = {}
	var blocked_by_resources = 0
	var blocked_by_water = 0
	var blocked_by_spacing = 0
	
	print("📍 Gerando objetos em mapa ", map_width, "x", map_height)
	print("🚫 Área bloqueada por recursos (incluindo buffer): ", occupied_positions.size())
	print("🛡️ Raio de evitação de recursos: ", resource_avoidance_radius)
	print("📏 Espaçamento entre objetos: ", object_spacing)
	
	# Inicializa estatísticas
	for object_name in object_configs:
		object_stats[object_name] = 0
	
	# Gera objetos por tipo, verificando espaçamento
	for object_name in object_configs:
		var config = object_configs[object_name]
		var base_chance = config["base_chance"]
		
		for x in range(map_width):
			for y in range(map_height):
				var pos = Vector2i(x, y)
				
				# Verifica se já tem objeto nesta posição
				if str(pos) in placed_objects:
					continue
				
				# VERIFICAÇÃO PRINCIPAL: Área de influência de recursos
				if is_position_in_resource_influence_area(pos):
					blocked_by_resources += 1
					continue
				
				# Verifica se é água
				var biome = get_biome_at_position(pos)
				if biome == "ocean":
					blocked_by_water += 1
					continue
				
				# NOVA VERIFICAÇÃO: Espaçamento entre objetos
				if not has_adequate_object_spacing(pos):
					blocked_by_spacing += 1
					continue
				
				# Calcula chance modificada por bioma
				var biome_preference = config["biome_preferences"].get(biome, 0.0)
				var final_chance = base_chance * biome_preference
				
				# Testa geração
				if randf() < final_chance:
					if place_object_safe(pos, object_name):
						object_stats[object_name] += 1
						placed_objects[str(pos)] = object_name
	
	print("🚫 Objetos bloqueados - Recursos: ", blocked_by_resources, " Água: ", blocked_by_water, " Espaçamento: ", blocked_by_spacing)
	print_object_statistics(object_stats, map_width * map_height)
	print("✅ Objetos gerados com espaçamento adequado!")

func map_resource_positions_with_buffer():
	"""Mapeia posições ocupadas por recursos INCLUINDO ÁREA DE INFLUÊNCIA"""
	print("📍 Mapeando posições de recursos com buffer de ", resource_avoidance_radius, " tiles...")
	
	occupied_positions.clear()
	
	if not resource_generator:
		return
	
	var resource_positions = []
	var direct_count = 0
	
	# Primeiro, encontra todas as posições com recursos
	for x in range(map_width):
		for y in range(map_height):
			var pos = Vector2i(x, y)
			if resource_generator.get_cell_source_id(pos) != -1:
				resource_positions.append(pos)
				direct_count += 1
	
	print("🗺️ ", direct_count, " posições com recursos encontradas")
	
	# Agora, marca área de influência ao redor de cada recurso
	var influence_count = 0
	
	for resource_pos in resource_positions:
		# Marca a posição do recurso
		occupied_positions[str(resource_pos)] = true
		
		# Marca área de influência ao redor
		for dx in range(-resource_avoidance_radius, resource_avoidance_radius + 1):
			for dy in range(-resource_avoidance_radius, resource_avoidance_radius + 1):
				var influence_pos = resource_pos + Vector2i(dx, dy)
				
				# Verifica se está dentro dos limites do mapa
				if (influence_pos.x >= 0 and influence_pos.x < map_width and 
					influence_pos.y >= 0 and influence_pos.y < map_height):
					
					var pos_key = str(influence_pos)
					if not pos_key in occupied_positions:
						occupied_positions[pos_key] = true
						influence_count += 1
	
	print("🛡️ ", influence_count, " posições adicionais bloqueadas por área de influência")
	print("📊 Total de posições bloqueadas: ", occupied_positions.size())

func is_position_in_resource_influence_area(pos: Vector2i) -> bool:
	"""Verifica se uma posição está na área de influência de recursos"""
	return str(pos) in occupied_positions

func has_adequate_object_spacing(pos: Vector2i) -> bool:
	"""Verifica se há espaçamento adequado entre objetos"""
	if object_spacing <= 0:
		return true
	
	# Verifica se há outros objetos no raio de espaçamento
	for dx in range(-object_spacing, object_spacing + 1):
		for dy in range(-object_spacing, object_spacing + 1):
			if dx == 0 and dy == 0:
				continue  # Pula a posição central
			
			var check_pos = pos + Vector2i(dx, dy)
			
			# Verifica se está dentro dos limites
			if (check_pos.x >= 0 and check_pos.x < map_width and 
				check_pos.y >= 0 and check_pos.y < map_height):
				
				# Verifica se já tem objeto nesta posição
				if str(check_pos) in placed_objects:
					return false
				
				# Verifica também se já tem objeto colocado no TileMapLayer
				if get_cell_source_id(check_pos) != -1:
					return false
	
	return true

func set_occupied_positions(positions: Dictionary):
	"""Define posições ocupadas externamente (usado pelo coordenador)"""
	occupied_positions = positions
	print("📍 Recebidas ", positions.size(), " posições ocupadas")
	
	# MELHORIA: Expande as posições recebidas com buffer
	if resource_avoidance_radius > 0:
		var expanded_positions = {}
		
		# Copia as posições originais
		for pos_str in positions:
			expanded_positions[pos_str] = true
		
		# Expande cada posição com o raio de evitação
		for pos_str in positions:
			# Parse da string da posição
			var pos_clean = pos_str.replace("(", "").replace(")", "")
			var parts = pos_clean.split(", ")
			if parts.size() >= 2:
				var base_pos = Vector2i(int(parts[0]), int(parts[1]))
				
				# Adiciona área de influência
				for dx in range(-resource_avoidance_radius, resource_avoidance_radius + 1):
					for dy in range(-resource_avoidance_radius, resource_avoidance_radius + 1):
						var influence_pos = base_pos + Vector2i(dx, dy)
						
						if (influence_pos.x >= 0 and influence_pos.x < map_width and 
							influence_pos.y >= 0 and influence_pos.y < map_height):
							expanded_positions[str(influence_pos)] = true
		
		occupied_positions = expanded_positions
		print("🛡️ Posições expandidas com buffer: ", occupied_positions.size())

func place_object_safe(pos: Vector2i, object_name: String) -> bool:
	"""Coloca um objeto COM VERIFICAÇÃO MÚLTIPLA"""
	# Verificação de área de influência de recursos
	if is_position_in_resource_influence_area(pos):
		if debug_object_placement:
			print("🚫 Tentativa de colocar objeto em área de influência de recurso: ", pos)
		return false
	
	# Verificação de espaçamento entre objetos
	if not has_adequate_object_spacing(pos):
		if debug_object_placement:
			print("🚫 Tentativa de colocar objeto muito próximo de outro: ", pos)
		return false
	
	if is_valid_position_for_object(pos, object_name):
		var config = object_configs[object_name]
		var atlas_coords = config["atlas_coords"]
		
		set_cell(pos, 0, atlas_coords)
		
		if debug_object_placement and placed_objects.size() <= 10:
			print("🌿 Objeto '", object_name, "' colocado em: ", pos)
		
		return true
	
	return false

func is_valid_position_for_object(pos: Vector2i, object_name: String) -> bool:
	"""Verifica se uma posição é válida para um objeto"""
	if not terrain_generator:
		return false
	
	# VERIFICAÇÃO: Área de influência de recursos
	if is_position_in_resource_influence_area(pos):
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
	var near_miss_count = 0  # Objetos próximos mas não sobrepostos
	
	for x in range(0, map_width, 2):  # Amostragem mais densa
		for y in range(0, map_height, 2):
			var pos = Vector2i(x, y)
			
			var has_resource = resource_generator.get_cell_source_id(pos) != -1
			var has_object = get_cell_source_id(pos) != -1
			
			if has_resource and has_object:
				collision_count += 1
				if sample_positions.size() < 5:
					sample_positions.append(pos)
			elif has_object and not has_resource:
				# Verifica se há recursos próximos
				var has_nearby_resource = false
				for dx in range(-resource_avoidance_radius, resource_avoidance_radius + 1):
					for dy in range(-resource_avoidance_radius, resource_avoidance_radius + 1):
						var check_pos = pos + Vector2i(dx, dy)
						if (check_pos.x >= 0 and check_pos.x < map_width and 
							check_pos.y >= 0 and check_pos.y < map_height):
							if resource_generator.get_cell_source_id(check_pos) != -1:
								has_nearby_resource = true
								break
					if has_nearby_resource:
						break
				
				if has_nearby_resource:
					near_miss_count += 1
	
	print("🎯 Resultado da verificação:")
	print("  - Colisões diretas encontradas: ", collision_count)
	print("  - Objetos próximos a recursos (dentro do raio): ", near_miss_count)
	
	if collision_count == 0:
		print("✅ Nenhuma colisão direta detectada!")
		if near_miss_count > 0:
			print("ℹ️ ", near_miss_count, " objetos estão próximos a recursos (comportamento esperado)")
	else:
		print("⚠️ Colisões diretas encontradas:")
		for pos in sample_positions:
			print("    ❌ Colisão direta em: ", pos)
	
	print("=== FIM VERIFICAÇÃO ===\n")

# === FUNÇÕES DE DEBUG APRIMORADAS ===
@export_group("Debug Avançado")
@export var analyze_spacing: bool = false:
	set(value):
		if value:
			analyze_spacing = false
			analyze_object_spacing()

func analyze_object_spacing():
	"""Analisa o espaçamento real entre objetos"""
	print("\n🔍 === ANÁLISE DE ESPAÇAMENTO ===")
	
	var object_positions = []
	var spacing_violations = 0
	
	# Coleta todas as posições com objetos
	for x in range(map_width):
		for y in range(map_height):
			var pos = Vector2i(x, y)
			if get_cell_source_id(pos) != -1:
				object_positions.append(pos)
	
	print("📊 Total de objetos encontrados: ", object_positions.size())
	
	# Verifica espaçamento entre todos os pares
	for i in range(object_positions.size()):
		for j in range(i + 1, object_positions.size()):
			var pos1 = object_positions[i]
			var pos2 = object_positions[j]
			var distance = pos1.distance_to(pos2)
			
			if distance <= object_spacing and distance > 0:
				spacing_violations += 1
				if spacing_violations <= 5:  # Mostra apenas os primeiros 5
					print("⚠️ Violação de espaçamento: ", pos1, " <-> ", pos2, " (distância: ", "%.1f" % distance, ")")
	
	if spacing_violations == 0:
		print("✅ Todos os objetos respeitam o espaçamento mínimo de ", object_spacing)
	else:
		print("⚠️ ", spacing_violations, " violações de espaçamento encontradas")
	
	print("=== FIM ANÁLISE DE ESPAÇAMENTO ===\n")

func _process(_delta):
	if not Engine.is_editor_hint():
		if position != Vector2(0, 0) or scale != Vector2(2.0, 2.0):
			position = Vector2(0, 0)
			scale = Vector2(2.0, 2.0)
