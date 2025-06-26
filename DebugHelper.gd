# DebugHelper.gd - Versão corrigida e simplificada
extends Node

@export var debug_tiles: bool = false:
	set(value):
		if value:
			debug_tiles = false
			call_deferred("debug_all_tiles")

@export var debug_position: Vector2i = Vector2i(64, 64)
@export var debug_specific_position: bool = false:
	set(value):
		if value:
			debug_specific_position = false
			call_deferred("debug_single_position")

@export var force_visibility: bool = false:
	set(value):
		if value:
			force_visibility = false
			call_deferred("force_all_visible")

func _ready():
	await get_tree().process_frame

func debug_all_tiles():
	"""Debug completo usando apenas sistema de grupos"""
	print("\n🔍 === DEBUG COMPLETO DOS TILES ===")
	
	var terrain_nodes = get_tree().get_nodes_in_group("terrain")
	var resource_nodes = get_tree().get_nodes_in_group("resources")
	var object_nodes = get_tree().get_nodes_in_group("objects")
	var shader_nodes = get_tree().get_nodes_in_group("shader")
	
	var terrain = terrain_nodes[0] if terrain_nodes.size() > 0 else null
	var resources = resource_nodes[0] if resource_nodes.size() > 0 else null
	var objects = object_nodes[0] if object_nodes.size() > 0 else null
	var shader = shader_nodes[0] if shader_nodes.size() > 0 else null
	
	# Debug TerrainMap
	if terrain:
		debug_tilemap_layer(terrain, "TERRAIN")
		print("✅ TerrainMap encontrado: ", terrain.get_path())
	else:
		print("❌ TerrainMap não encontrado no grupo 'terrain'")
	
	# Debug ResourceMap
	if resources:
		debug_tilemap_layer(resources, "RESOURCES")
		print("✅ ResourceMap encontrado: ", resources.get_path())
	else:
		print("❌ ResourceMap não encontrado no grupo 'resources'")
	
	# Debug ObjectMap
	if objects:
		debug_tilemap_layer(objects, "OBJECTS")
		print("✅ ObjectMap encontrado: ", objects.get_path())
	else:
		print("❌ ObjectMap não encontrado no grupo 'objects'")
	
	# Debug Shader
	if shader:
		print("\n🎨 SHADER DEBUG:")
		print("  - Caminho: ", shader.get_path())
		print("  - Visible: ", shader.visible)
		print("  - Scale: ", shader.scale)
		print("  - Position: ", shader.position)
		print("  - Z-Index: ", shader.z_index if "z_index" in shader else "N/A")
		print("  - Material: ", shader.material != null)
		if shader.material and shader.material is ShaderMaterial:
			var mat = shader.material as ShaderMaterial
			print("  - mapData: ", mat.get_shader_parameter("mapData") != null)
			print("  - textureAtlas: ", mat.get_shader_parameter("textureAtlas") != null)
		print("✅ ShaderTerrain encontrado: ", shader.get_path())
	else:
		print("❌ ShaderTerrain não encontrado no grupo 'shader'")
	
	print("=== FIM DEBUG COMPLETO ===\n")

func debug_tilemap_layer(tilemap: TileMapLayer, name: String):
	"""Debug de um TileMapLayer específico"""
	if not tilemap:
		print("❌ ", name, " é null")
		return
		
	print("\n📊 ", name, " DEBUG:")
	print("  - Caminho: ", tilemap.get_path())
	print("  - Visible: ", tilemap.visible)
	print("  - Enabled: ", tilemap.enabled)
	print("  - Scale: ", tilemap.scale)
	print("  - Position: ", tilemap.position)
	print(" - Z-Index: ", str(tilemap.z_index) if tilemap else "N/A")
	print("  - TileSet: ", tilemap.tile_set != null)
	
	if tilemap.tile_set:
		var source_count = tilemap.tile_set.get_source_count()
		print("  - Sources: ", source_count)
		
		if source_count > 0:
			var source = tilemap.tile_set.get_source(0)
			if source is TileSetAtlasSource:
				var atlas = source as TileSetAtlasSource
				print("  - Texture: ", atlas.texture != null)
				if atlas.texture:
					print("  - Texture size: ", atlas.texture.get_size())
					print("  - Tile size: ", atlas.texture_region_size)
	
	# Conta tiles de forma segura
	var tile_count = 0
	var sample_positions = []
	
	# Amostragem limitada para evitar problemas
	var max_samples = 5
	var step = 32
	
	for x in range(0, min(128, step * 4), step):
		for y in range(0, min(128, step * 4), step):
			var pos = Vector2i(x, y)
			var source_id = tilemap.get_cell_source_id(pos)
			if source_id != -1:
				tile_count += 1
				if sample_positions.size() < max_samples:
					var atlas_coords = tilemap.get_cell_atlas_coords(pos)
					sample_positions.append({"pos": pos, "atlas": atlas_coords})
	
	print("  - Tiles encontrados (amostra): ", tile_count)
	print("  - Exemplos de tiles:")
	for sample in sample_positions:
		print("    ", sample["pos"], " -> ", sample["atlas"])

func debug_single_position():
	"""Debug de uma posição específica usando grupos"""
	print("\n🎯 === DEBUG POSIÇÃO ", debug_position, " ===")
	
	var terrain_nodes = get_tree().get_nodes_in_group("terrain")
	var resource_nodes = get_tree().get_nodes_in_group("resources")
	var object_nodes = get_tree().get_nodes_in_group("objects")
	
	var terrain = terrain_nodes[0] if terrain_nodes.size() > 0 else null
	var resources = resource_nodes[0] if resource_nodes.size() > 0 else null
	var objects = object_nodes[0] if object_nodes.size() > 0 else null
	
	if terrain:
		var terrain_source = terrain.get_cell_source_id(debug_position)
		var terrain_atlas = terrain.get_cell_atlas_coords(debug_position)
		print("🌍 Terrain: source=", terrain_source, " atlas=", terrain_atlas)
		
		if terrain.has_method("get_biome_at_position"):
			var biome = terrain.get_biome_at_position(debug_position.x, debug_position.y)
			print("  - Bioma: ", biome)
	else:
		print("❌ TerrainMap não encontrado")
	
	if resources:
		var res_source = resources.get_cell_source_id(debug_position)
		var res_atlas = resources.get_cell_atlas_coords(debug_position)
		print("🔧 Resources: source=", res_source, " atlas=", res_atlas)
	else:
		print("❌ ResourceMap não encontrado")
	
	if objects:
		var obj_source = objects.get_cell_source_id(debug_position)
		var obj_atlas = objects.get_cell_atlas_coords(debug_position)
		print("🌿 Objects: source=", obj_source, " atlas=", obj_atlas)
	else:
		print("❌ ObjectMap não encontrado")
	
	print("=== FIM DEBUG POSIÇÃO ===\n")

func force_all_visible():
	"""Força todos os TileMapLayers a ficarem visíveis usando grupos"""
	print("\n🔧 === FORÇANDO VISIBILIDADE ===")
	
	var terrain_nodes = get_tree().get_nodes_in_group("terrain")
	var resource_nodes = get_tree().get_nodes_in_group("resources")
	var object_nodes = get_tree().get_nodes_in_group("objects")
	var shader_nodes = get_tree().get_nodes_in_group("shader")
	
	var terrain = terrain_nodes[0] if terrain_nodes.size() > 0 else null
	var resources = resource_nodes[0] if resource_nodes.size() > 0 else null
	var objects = object_nodes[0] if object_nodes.size() > 0 else null
	var shader = shader_nodes[0] if shader_nodes.size() > 0 else null
	
	if terrain:
		terrain.visible = true
		if "z_index" in terrain:
			terrain.z_index = 0
		terrain.scale = Vector2(2, 2)
		print("✅ TerrainMap forçado a visible com escala (2,2)")
	else:
		print("❌ TerrainMap não encontrado")
	
	if resources:
		resources.visible = true
		if "z_index" in resources:
			resources.z_index = 1
		resources.scale = Vector2(2, 2)
		print("✅ ResourceMap forçado a visible com escala (2,2)")
	else:
		print("❌ ResourceMap não encontrado")
	
	if objects:
		objects.visible = true
		if "z_index" in objects:
			objects.z_index = 2
		objects.scale = Vector2(2, 2)
		print("✅ ObjectMap forçado a visible com escala (2,2)")
	else:
		print("❌ ObjectMap não encontrado")
	
	if shader:
		shader.visible = false
		print("✅ Shader desabilitado")
	else:
		print("❌ Shader não encontrado")
	
	print("=== VISIBILIDADE FORÇADA ===\n")

# Função para debug da estrutura de grupos
@export var debug_groups: bool = false:
	set(value):
		if value:
			debug_groups = false
			call_deferred("debug_scene_groups")

func debug_scene_groups():
	"""Debug dos grupos da cena"""
	print("\n🔍 === DEBUG GRUPOS DA CENA ===")
	
	var all_nodes = get_tree().get_nodes_in_group("terrain")
	print("🌍 Grupo 'terrain': ", all_nodes.size(), " nós")
	for node in all_nodes:
		print("  - ", node.get_path(), " (", node.get_class(), ")")
	
	all_nodes = get_tree().get_nodes_in_group("resources")
	print("🔧 Grupo 'resources': ", all_nodes.size(), " nós")
	for node in all_nodes:
		print("  - ", node.get_path(), " (", node.get_class(), ")")
	
	all_nodes = get_tree().get_nodes_in_group("objects")
	print("🌿 Grupo 'objects': ", all_nodes.size(), " nós")
	for node in all_nodes:
		print("  - ", node.get_path(), " (", node.get_class(), ")")
	
	all_nodes = get_tree().get_nodes_in_group("shader")
	print("🎨 Grupo 'shader': ", all_nodes.size(), " nós")
	for node in all_nodes:
		print("  - ", node.get_path(), " (", node.get_class(), ")")
	
	print("=== FIM DEBUG GRUPOS ===\n")
