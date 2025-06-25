# Adicione este script a um novo nó na cena principal
# Este script permite testar diferentes escalas em tempo real

@tool
extends Node

@export_group("Teste de Escala")
@export var resource_scale_multiplier: float = 1.0:
	set(value):
		resource_scale_multiplier = value
		apply_resource_scale()

@export var object_scale_multiplier: float = 1.0:
	set(value):
		object_scale_multiplier = value
		apply_object_scale()

@export var terrain_scale_multiplier: float = 1.0:
	set(value):
		terrain_scale_multiplier = value
		apply_terrain_scale()

@export var reset_all_scales: bool = false:
	set(value):
		if value:
			resource_scale_multiplier = 1.0
			object_scale_multiplier = 1.0
			terrain_scale_multiplier = 1.0
			apply_all_scales()

func apply_resource_scale():
	var resource_map = get_node_or_null("/root/Main/Resource/ResourceMap")
	if resource_map:
		resource_map.scale = Vector2(resource_scale_multiplier, resource_scale_multiplier)
		print("🔧 ResourceMap escala alterada para: ", resource_map.scale)

func apply_object_scale():
	var object_map = get_node_or_null("/root/Main/Object/ObjectMap")
	if object_map:
		object_map.scale = Vector2(object_scale_multiplier, object_scale_multiplier)
		print("📦 ObjectMap escala alterada para: ", object_map.scale)

func apply_terrain_scale():
	var terrain_map = get_node_or_null("/root/Main/Terrain/TerrainMap")
	if terrain_map:
		terrain_map.scale = Vector2(terrain_scale_multiplier, terrain_scale_multiplier)
		print("🌍 TerrainMap escala alterada para: ", terrain_map.scale)

func apply_all_scales():
	apply_resource_scale()
	apply_object_scale()
	apply_terrain_scale()

# Testes pré-definidos
@export_group("Testes Rápidos")
@export var test_double_resources: bool = false:
	set(value):
		if value:
			resource_scale_multiplier = 2.0

@export var test_half_resources: bool = false:
	set(value):
		if value:
			resource_scale_multiplier = 0.5

@export var test_match_visual_size: bool = false:
	set(value):
		if value:
			# Baseado no debug, se effective scale é 0.25 para todos,
			# mas visualmente parecem diferentes, pode ser que resources 
			# precisem ser 4x maiores para compensar conteúdo menor
			resource_scale_multiplier = 4.0
			object_scale_multiplier = 4.0

@export var test_find_correct_scale: bool = false:
	set(value):
		if value:
			# Testa diferentes escalas automaticamente
			find_correct_scale()

func find_correct_scale():
	print("\n🔍 === TESTE AUTOMÁTICO DE ESCALA ===")
	
	# Testa escalas de 0.5 até 4.0
	var test_scales = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 2.5, 3.0, 4.0]
	
	for i in range(test_scales.size()):
		var scale_val = test_scales[i]
		
		print("\n📊 Testando escala ", scale_val, ":")
		resource_scale_multiplier = scale_val
		object_scale_multiplier = scale_val
		
		# Espera um frame para aplicar
		await get_tree().process_frame
		
		# Analisa se algum tile tem resource nesta escala
		var resource_map = get_node_or_null("/root/Main/Resource/ResourceMap")
		if resource_map:
			var has_visible_resource = false
			for x in range(20, 60):
				for y in range(20, 60):
					var source_id = resource_map.get_cell_source_id(Vector2i(x, y))
					if source_id != -1:
						has_visible_resource = true
						break
				if has_visible_resource:
					break
			
			print("  - Resources visíveis: ", has_visible_resource)
			print("  - Escala aplicada: ", resource_map.scale)
		
		# Pausa para observação visual (só funciona se estiver rodando)
		if not Engine.is_editor_hint():
			await get_tree().create_timer(1.0).timeout
	
	print("=== FIM TESTE AUTOMÁTICO ===\n")

# Debug adicional
@export_group("Debug Avançado")
@export var analyze_texture_content: bool = false:
	set(value):
		if value:
			analyze_textures()

func analyze_textures():
	print("\n🔍 === ANÁLISE DE CONTEÚDO DAS TEXTURAS ===")
	
	var terrain_map = get_node_or_null("/root/Main/Terrain/TerrainMap")
	var resource_map = get_node_or_null("/root/Main/Resource/ResourceMap")
	var object_map = get_node_or_null("/root/Main/Object/ObjectMap")
	
	# Analisa TerrainMap
	analyze_single_layer(terrain_map, "TerrainMap")
	# Analisa ResourceMap  
	analyze_single_layer(resource_map, "ResourceMap")
	# Analisa ObjectMap
	analyze_single_layer(object_map, "ObjectMap")
	
	print("=== FIM ANÁLISE DE TEXTURAS ===\n")

func analyze_single_layer(layer: TileMapLayer, name: String):
	if not layer or not layer.tile_set:
		print("❌ ", name, " não encontrado")
		return
	
	var source = layer.tile_set.get_source(0) as TileSetAtlasSource
	if not source:
		print("❌ ", name, " sem TileSetAtlasSource")
		return
	
	print("📊 ", name, ":")
	print("  - Texture path: ", source.texture.resource_path if source.texture else "N/A")
	print("  - Texture size: ", source.texture.get_size() if source.texture else "N/A")
	print("  - Tile region size: ", source.texture_region_size)
	print("  - Atlas columns: ", source.get_atlas_grid_size().x)
	print("  - Atlas rows: ", source.get_atlas_grid_size().y)
	
	# Verifica quantos tiles diferentes existem
	var tile_count = 0
	var atlas_size = source.get_atlas_grid_size()
	for x in range(atlas_size.x):
		for y in range(atlas_size.y):
			if source.has_tile(Vector2i(x, y)):
				tile_count += 1
	
	print("  - Tiles configurados: ", tile_count, "/", atlas_size.x * atlas_size.y)
