# Adicione este script como um novo nó na cena (ex: VisualDebugger)
# Este script vai criar uma grade visual para mostrar exatamente onde cada elemento está renderizando

@tool
extends Node2D

@export var show_debug_grid: bool = false:
	set(value):
		show_debug_grid = value
		queue_redraw()

@export var grid_color := Color.RED
@export var tile_size := 32
@export var grid_thickness := 2.0

func _ready():
	z_index = 1000  # Fica por cima de tudo
	
func _draw():
	if not show_debug_grid:
		return
		
	# Desenha grade sobre toda a tela para mostrar onde cada tile deveria estar
	var viewport_size = get_viewport_rect().size
	var camera = get_viewport().get_camera_2d()
	
	var start_pos = Vector2.ZERO
	var end_pos = Vector2(4096, 4096)  # Tamanho total do mapa
	
	if camera:
		# Ajusta para a posição da câmera
		start_pos -= camera.global_position
		end_pos -= camera.global_position
	
	# Linhas verticais
	var x = start_pos.x
	while x <= end_pos.x:
		if x >= -viewport_size.x and x <= viewport_size.x * 2:
			draw_line(
				Vector2(x, start_pos.y - viewport_size.y),
				Vector2(x, end_pos.y + viewport_size.y),
				grid_color,
				grid_thickness
			)
		x += tile_size
	
	# Linhas horizontais  
	var y = start_pos.y
	while y <= end_pos.y:
		if y >= -viewport_size.y and y <= viewport_size.y * 2:
			draw_line(
				Vector2(start_pos.x - viewport_size.x, y),
				Vector2(end_pos.x + viewport_size.x, y),
				grid_color,
				grid_thickness
			)
		y += tile_size

@export var show_tile_info: bool = false:
	set(value):
		show_tile_info = value
		if value:
			print_tile_analysis()

func print_tile_analysis():
	print("\n🔍 === ANÁLISE VISUAL DOS TILES ===")
	
	# Analisa alguns tiles específicos para ver o que está sendo renderizado
	var terrain = get_node_or_null("/root/Main/Terrain/TerrainMap")
	var resources = get_node_or_null("/root/Main/Resource/ResourceMap") 
	var objects = get_node_or_null("/root/Main/Object/ObjectMap")
	
	var test_positions = [
		Vector2i(10, 10),
		Vector2i(20, 20), 
		Vector2i(30, 30),
		Vector2i(50, 50)
	]
	
	for pos in test_positions:
		print("\n📍 Posição ", pos, ":")
		
		if terrain:
			var terrain_cell = terrain.get_cell_atlas_coords(pos)
			var terrain_source = terrain.get_cell_source_id(pos)
			print("  🌍 Terrain: source=", terrain_source, " atlas=", terrain_cell)
		
		if resources:
			var resource_cell = resources.get_cell_atlas_coords(pos)  
			var resource_source = resources.get_cell_source_id(pos)
			print("  🔧 Resource: source=", resource_source, " atlas=", resource_cell)
			
		if objects:
			var object_cell = objects.get_cell_atlas_coords(pos)
			var object_source = objects.get_cell_source_id(pos)
			print("  📦 Object: source=", object_source, " atlas=", object_cell)
	
	print("=== FIM ANÁLISE ===\n")

# Função para mostrar informações específicas sobre scale visual
@export var compare_visual_scales: bool = false:
	set(value):
		compare_visual_scales = value
		if value:
			compare_scales()

func compare_scales():
	print("\n🔍 === COMPARAÇÃO VISUAL DE ESCALAS ===")
	
	var terrain = get_node_or_null("/root/Main/Terrain/TerrainMap")
	var resources = get_node_or_null("/root/Main/Resource/ResourceMap") 
	var objects = get_node_or_null("/root/Main/Object/ObjectMap")
	var shader = get_node_or_null("/root/Main/ShaderTerrain")
	
	if terrain and terrain.tile_set:
		var ts = terrain.tile_set.get_source(0) as TileSetAtlasSource
		print("🌍 TerrainMap:")
		print("  - Global position: ", terrain.global_position)
		print("  - Global scale: ", terrain.global_scale) 
		print("  - Tile region size: ", ts.texture_region_size if ts else "N/A")
		if ts and ts.texture:
			print("  - Atlas texture size: ", ts.texture.get_size())
			print("  - Effective tile scale: ", Vector2(ts.texture_region_size) / ts.texture.get_size())
	
	if resources and resources.tile_set:
		var ts = resources.tile_set.get_source(0) as TileSetAtlasSource
		print("🔧 ResourceMap:")
		print("  - Global position: ", resources.global_position)
		print("  - Global scale: ", resources.global_scale)
		print("  - Tile region size: ", ts.texture_region_size if ts else "N/A")
		if ts and ts.texture:
			print("  - Atlas texture size: ", ts.texture.get_size())
			print("  - Effective tile scale: ", Vector2(ts.texture_region_size) / ts.texture.get_size())
	
	if objects and objects.tile_set:
		var ts = objects.tile_set.get_source(0) as TileSetAtlasSource
		print("📦 ObjectMap:")
		print("  - Global position: ", objects.global_position)
		print("  - Global scale: ", objects.global_scale)
		print("  - Tile region size: ", ts.texture_region_size if ts else "N/A")
		if ts and ts.texture:
			print("  - Atlas texture size: ", ts.texture.get_size()) 
			print("  - Effective tile scale: ", Vector2(ts.texture_region_size) / ts.texture.get_size())
	
	if shader:
		print("🎨 ShaderTerrain:")
		print("  - Global position: ", shader.global_position)
		print("  - Global scale: ", shader.global_scale)
		print("  - Local scale: ", shader.scale)
	
	print("=== FIM COMPARAÇÃO ===\n")
