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

# === CONFIGURAÇÕES REALISTAS ===
@export_group("Densidade de Recursos")
@export_range(0.0, 0.08) var stone_density: float = 0.03
# REMOVIDO: metal_density (apenas pedra como solicitado)

@export_range(1, 20) var resource_cluster_size: int = 8

@export_group("Distribuição por Bioma")
@export_range(0.0, 5.0) var mountain_bonus: float = 3.0
@export_range(0.0, 5.0) var hills_bonus: float = 2.0
@export_range(0.0, 1.0) var desert_penalty: float = 0.7

# === SISTEMA DE RECURSOS ===
var terrain_generator: TileMapLayer
var resource_configs = {
	"stone": {
		"atlas_coords": Vector2i(2, 0),  # APENAS PEDRA
		"base_chance": 0.03,
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
	}
	# REMOVIDO: metal e outros recursos
}

func _ready():
	print("🔧 ResourceGenerator iniciado")
	add_to_group("resources")
	
	setup_tileset()
	
	# CORREÇÃO CRÍTICA: Força posicionamento e escala EXATOS
	force_correct_positioning()
	
	if not Engine.is_editor_hint():
		await get_tree().process_frame
		await get_tree().create_timer(1.5).timeout
		find_terrain_generator()
		generate()

func force_correct_positioning():
	"""CORREÇÃO CRÍTICA: Força posicionamento exato igual ao TerrainMap"""
	# Força configurações visuais EXATAS
	position = Vector2(0, 0)  # POSIÇÃO ZERO ABSOLUTA
	scale = Vector2(1.0, 1.0)  # ESCALA IGUAL AO TERRAIN
	visible = true
	enabled = true
	z_index = 1  # ACIMA DO TERRAIN (z_index = 0)
	
	print("✅ ResourceMap CORRIGIDO:")
	print("  - Position: ", position)
	print("  - Scale: ", scale)
	print("  - Z-index: ", z_index)
	print("  - Visible: ", visible)

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
	
	# CORREÇÃO: Cria APENAS tile de pedra
	atlas_source.create_tile(Vector2i(2, 0))  # Pedra
	
	new_tileset.add_source(atlas_source, 0)
	tile_set = new_tileset
	
	print("✅ ResourceGenerator: TileSet configurado (APENAS PEDRA)")

func find_terrain_generator():
	"""Encontra o TerrainGenerator na cena"""
	print("🔍 Buscando TerrainGenerator...")
	
	var possible_paths = [
		"../../Terrain/TerrainMap",
		"../Terrain/TerrainMap",
		"/root/Main/Terrain/TerrainMap",
		"../../../Terrain/TerrainMap"
	]
	
	for path in possible_paths:
		var node = get_node_or_null(path)
		if node and node is TileMapLayer:
			terrain_generator = node
			print("✅ TerrainGenerator encontrado em: ", path)
			
			# CORREÇÃO CRÍTICA: Sincroniza posicionamento com o TerrainMap
			sync_positioning_with_terrain()
			return
	
	# Busca por grupo
	var terrain_nodes = get_tree().get_nodes_in_group("terrain")
	if terrain_nodes.size() > 0:
		terrain_generator = terrain_nodes[0]
		print("✅ TerrainGenerator encontrado via grupo: ", terrain_generator.get_path())
		sync_positioning_with_terrain()
		return
	
	print("❌ ERRO: TerrainGenerator não encontrado!")

func sync_positioning_with_terrain():
	"""CORREÇÃO CRÍTICA: Sincroniza posicionamento EXATO com o TerrainMap"""
	if not terrain_generator:
		return
	
	# Força o TerrainMap a ter posicionamento correto também
	terrain_generator.position = Vector2(0, 0)
	terrain_generator.scale = Vector2(2.0, 2.0)
	
	# Força este ResourceMap a ter EXATAMENTE a mesma configuração
	position = Vector2(0, 0)
	scale = Vector2(1.0, 1.0)
	
	print("🔄 SINCRONIZAÇÃO FORÇADA:")
	print("  - TerrainMap: pos=", terrain_generator.position, " scale=", terrain_generator.scale)
	print("  - ResourceMap: pos=", position, " scale=", scale)

func generate():
	"""Gera recursos baseado no terreno - VERSÃO CORRIGIDA"""
	print("🔧 Gerando recursos...")
	clear()
	
	if not terrain_generator:
		find_terrain_generator()
	
	if not terrain_generator:
		print("❌ Impossível gerar recursos sem TerrainGenerator!")
		return
	
	# CORREÇÃO CRÍTICA: Re-força posicionamento antes da geração
	force_correct_positioning()
	sync_positioning_with_terrain()
	
	var map_width = terrain_generator.get("map_width") if "map_width" in terrain_generator else 128
	var map_height = terrain_generator.get("map_height") if "map_height" in terrain_generator else 128
	var placed_resources = {}
	var stone_count = 0
	
	print("📍 Gerando recursos em mapa ", map_width, "x", map_height)
	
	# CORREÇÃO: Gera APENAS pedra
	var config = resource_configs["stone"]
	var base_chance = config["base_chance"]
	var resource_cluster_size_config = config["cluster_size"]
	
	for x in range(map_width):
		for y in range(map_height):
			var pos = Vector2i(x, y)
			
			# Verifica se já tem recurso
			if str(pos) in placed_resources:
				continue
			
			# Obtém bioma
			var biome = "grassland"  # Fallback
			if terrain_generator.has_method("get_biome_at_position"):
				biome = terrain_generator.get_biome_at_position(x, y)
			else:
				var terrain_tile = terrain_generator.get_cell_atlas_coords(pos)
				biome = get_biome_from_terrain_tile(terrain_tile)
			
			# Calcula chance modificada por bioma
			var biome_modifier = config["biome_modifiers"].get(biome, 1.0)
			var final_chance = base_chance * biome_modifier
			
			# Chance mínima para garantir recursos
			final_chance = max(final_chance, 0.001)
			
			# Testa geração
			if randf() < final_chance:
				var placed_count = generate_stone_cluster(pos, resource_cluster_size_config, placed_resources)
				stone_count += placed_count
	
	print("🔧 TOTAL de pedras colocadas: ", stone_count)
	
	# CORREÇÃO FINAL: Força posicionamento após geração
	call_deferred("final_positioning_check")
	
	print("✅ Recursos gerados com sucesso!")

func generate_stone_cluster(start_pos: Vector2i, cluster_size_param: int, placed_resources: Dictionary) -> int:
	"""Gera um cluster de pedras"""
	var atlas_coords = Vector2i(2, 0)  # APENAS PEDRA
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
		if is_valid_position_for_resource(pos):
			set_cell(pos, 0, atlas_coords)  # Usa source 0
			placed_resources[str(pos)] = "stone"
			placed_count += 1
	
	return placed_count

func is_valid_position_for_resource(pos: Vector2i) -> bool:
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
	
	var config = resource_configs["stone"]
	var biome_modifier = config["biome_modifiers"].get(biome, 1.0)
	
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

func final_positioning_check():
	"""Verificação final de posicionamento"""
	print("🔍 === VERIFICAÇÃO FINAL DE POSICIONAMENTO ===")
	
	if position != Vector2(0, 0):
		position = Vector2(0, 0)
		print("🔧 Position corrigida para (0, 0)")
	
	if scale != Vector2(1.0, 1.0):
		scale = Vector2(1.0, 1.0)
		print("🔧 Scale corrigida para (2.0, 2.0)")
	
	if z_index != 1:
		z_index = 1
		print("🔧 Z-index corrigido para 1")
	
	# Força atualização visual
	queue_redraw()
	
	print("✅ ResourceMap FINALIZADO:")
	print("  - Position: ", position)
	print("  - Scale: ", scale)
	print("  - Z-index: ", z_index)
	print("=== FIM VERIFICAÇÃO ===")

# Sistema para manter posicionamento correto
func _process(_delta):
	if not Engine.is_editor_hint():
		# Verifica se posicionamento foi alterado
		if position != Vector2(0, 0) or scale != Vector2(1.0, 1.0):
			position = Vector2(0, 0)
			scale = Vector2(1.0, 1.0)
			# Não faz print para evitar spam, mas mantém correção ativa
