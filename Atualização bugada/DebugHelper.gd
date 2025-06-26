# Adicione este script como DebugHelper.gd a um nó na cena

extends Node

@export var debug_tiles: bool = false:
	set(value):
		if value:
			debug_tiles = false
			debug_all_tiles()

@export var debug_position: Vector2i = Vector2i(64, 64)
@export var debug_specific_position: bool = false:
	set(value):
		if value:
			debug_specific_position = false
			debug_single_position()

func debug_all_tiles():
	"""Debug completo de todos os TileMapLayers"""
	print("\n🔍 === DEBUG COMPLETO DOS TILES ===")
	
	var terrain = get_node_or_null("../Terrain/TerrainMap")
	var resources = get_node_or_null("../Resource/ResourceMap")
	var objects = get_node_or_null("../Object/ObjectMap")
	var shader = get_node_or_null("../ShaderTerrain")
	
	# Debug TerrainMap
	if terrain:
		debug_tilemap_layer(terrain, "TERRAIN")
	else:
		print("❌ TerrainMap não encontrado")
	
	# Debug ResourceMap
	if resources:
		debug_tilemap_layer(resources, "RESOURCES")
	else:
		print("❌ ResourceMap não encontrado")
	
	# Debug ObjectMap
	if objects:
		debug_tilemap_layer(objects, "OBJECTS")
	else:
		print("❌ ObjectMap não encontrado")
	
	# Debug Shader
	if shader:
		print("\n🎨 SHADER DEBUG:")
		print("  - Visible: ", shader.visible)
		print("  - Scale: ", shader.scale)
		print("  - Position: ", shader.position)
		print("  - Z-Index: ", shader.z_index)
		print("  - Material: ", shader.material != null)
		if shader.material and shader.material is ShaderMaterial:
			var mat = shader.material as ShaderMaterial
			print("  - mapData: ", mat.get_shader_parameter("mapData") != null)
			print("  - textureAtlas: ", mat.get_shader_parameter("textureAtlas") != null)
	
	print("=== FIM DEBUG COMPLETO ===\n")

func debug_tilemap_layer(tilemap: TileMapLayer, name: String):
	"""Debug de um TileMapLayer específico"""
	print("\n📊 ", name, " DEBUG:")
	print("  - Visible: ", tilemap.visible)
	print("  - Enabled: ", tilemap.enabled)
	print("  - Scale: ", tilemap.scale)
	print("  - Position: ", tilemap.position)
	print("  - Z-Index: ", tilemap.z_index)
	print("  - TileSet: ", tilemap.tile_set != null)
	
	if tilemap.tile_set:
		var source_count = tilemap.tile_set.get_source_count()
		print("  - Sources: ", source_count)
		
		if source_count > 0:
			var source = tilemap.tile_set.get_source(0)
			if source is TileSetAtlasSource:
				var atlas = source as TileSetAtlasSource
				print("  - Texture: ", atlas.texture != null)
				print("  - Texture size: ", atlas.texture.get_size() if atlas.texture else "N/A")
				print("  - Tile size: ", atlas.texture_region_size)
	
	# Conta tiles não vazios
	var tile_count = 0
	var sample_positions = []
	
	for x in range(0, 128, 16):  # Amostragem
		for y in range(0, 128, 16):
			var pos = Vector2i(x, y)
			var source_id = tilemap.get_cell_source_id(pos)
			if source_id != -1:
				tile_count += 1
				if sample_positions.size() < 5:  # Primeiras 5 posições
					var atlas_coords = tilemap.get_cell_atlas_coords(pos)
					sample_positions.append({"pos": pos, "atlas": atlas_coords})
	
	print("  - Tiles encontrados (amostra): ", tile_count)
	print("  - Exemplos de tiles:")
	for sample in sample_positions:
		print("    ", sample["pos"], " -> ", sample["atlas"])

func debug_single_position():
	"""Debug de uma posição específica"""
	print("\n🎯 === DEBUG POSIÇÃO ", debug_position, " ===")
	
	var terrain = get_node_or_null("../Terrain/TerrainMap")
	var resources = get_node_or_null("../Resource/ResourceMap")
	var objects = get_node_or_null("../Object/ObjectMap")
	
	if terrain:
		var terrain_source = terrain.get_cell_source_id(debug_position)
		var terrain_atlas = terrain.get_cell_atlas_coords(debug_position)
		print("🌍 Terrain: source=", terrain_source, " atlas=", terrain_atlas)
		
		if terrain.has_method("get_biome_at_position"):
			var biome = terrain.get_biome_at_position(debug_position.x, debug_position.y)
			print("  - Bioma: ", biome)
	
	if resources:
		var res_source = resources.get_cell_source_id(debug_position)
		var res_atlas = resources.get_cell_atlas_coords(debug_position)
		print("🔧 Resources: source=", res_source, " atlas=", res_atlas)
	
	if objects:
		var obj_source = objects.get_cell_source_id(debug_position)
		var obj_atlas = objects.get_cell_atlas_coords(debug_position)
		print("🌿 Objects: source=", obj_source, " atlas=", obj_atlas)
	
	print("=== FIM DEBUG POSIÇÃO ===\n")

# Função para forçar visibilidade de todos os layers
@export var force_visibility: bool = false:
	set(value):
		if value:
			force_visibility = false
			force_all_visible()

func force_all_visible():
	"""Força todos os TileMapLayers a ficarem visíveis"""
	print("\n🔧 === FORÇANDO VISIBILIDADE ===")
	
	var terrain = get_node_or_null("../Terrain/TerrainMap")
	var resources = get_node_or_null("../Resource/ResourceMap")
	var objects = get_node_or_null("../Object/ObjectMap")
	var shader = get_node_or_null("../ShaderTerrain")
	
	if terrain:
		terrain.visible = true
		terrain.z_index = 0
		terrain.scale = Vector2(1, 1)
		print("✅ TerrainMap forçado a visible")
	
	if resources:
		resources.visible = true
		resources.z_index = 1
		resources.scale = Vector2(1, 1)
		print("✅ ResourceMap forçado a visible")
	
	if objects:
		objects.visible = true
		objects.z_index = 2
		objects.scale = Vector2(1, 1)
		print("✅ ObjectMap forçado a visible")
	
	# Desabilita shader para garantir que tiles apareçam
	if shader:
		shader.visible = false
		print("✅ Shader desabilitado")
	
	print("=== VISIBILIDADE FORÇADA ===\n")
