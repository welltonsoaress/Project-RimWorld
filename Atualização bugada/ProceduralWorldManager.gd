@tool
class_name ProceduralWorldManager
extends Node

# === INTEGRAÇÃO COM O SISTEMA EXISTENTE ===
# Este script substitui ou complementa o main.gd atual

@export_group("Geração do Mundo")
@export var auto_generate_on_start: bool = true
@export var world_seed: int = 0
@export var world_width: int = 128
@export var world_height: int = 128

@export_group("Sistema Modular")
@export var use_advanced_generation: bool = true
@export var force_regenerate_all: bool = false:
	set(value):
		force_regenerate_all = false
		if value:
			force_full_regeneration()

@export_group("Configuração de Terreno")
@export_enum("Auto", "Ilha", "Continente", "Arquipélago", "Península", "Desertão")
var terrain_type: String = "Auto"

@export_group("Debug e Análise")
@export var show_generation_progress: bool = true
@export var generate_analysis_report: bool = false:
	set(value):
		generate_analysis_report = false
		if value:
			generate_world_analysis()

@export var save_debug_images: bool = false:
	set(value):
		save_debug_images = false
		if value:
			save_debug_previews()

# Sistema modular
var biome_manager: BiomeManager
var noise_generator: NoiseGenerator
var is_generating: bool = false

# Referências aos componentes
var terrain_map: TileMapLayer
var resource_map: TileMapLayer
var object_map: TileMapLayer
var shader_terrain: Sprite2D

func _ready():
	if not Engine.is_editor_hint() and auto_generate_on_start:
		print("🌍 ProceduralWorldManager iniciado")
		initialize_system()
		
		if not is_generating:
			await get_tree().process_frame
			generate_world()

func initialize_system():
	"""Inicializa todo o sistema modular"""
	print("🔧 Inicializando sistema procedural modular...")
	
	# Inicializa o BiomeManager
	biome_manager = BiomeManager.get_instance()
	
	# Configura gerador de ruído
	var seed_to_use = world_seed if world_seed != 0 else randi()
	noise_generator = NoiseGenerator.new(seed_to_use)
	
	# Encontra componentes na cena
	find_world_components()
	
	# Sincroniza configurações
	sync_component_settings()
	
	print("✅ Sistema procedural inicializado")

func find_world_components():
	"""Encontra todos os componentes do mundo na cena"""
	
	# Busca TerrainMap na estrutura WorldManager/Main/Terrain/TerrainMap
	terrain_map = find_component_by_path([
		"Main/Terrain/TerrainMap",
		"Terrain/TerrainMap",
		"TerrainMap"
	])
	if not terrain_map:
		terrain_map = find_component_by_script("Terrain_map")
	
	# Busca ResourceMap na estrutura WorldManager/Main/Resource/ResourceMap
	resource_map = find_component_by_path([
		"Main/Resource/ResourceMap",
		"Resource/ResourceMap", 
		"ResourceMap"
	])
	if not resource_map:
		resource_map = find_component_by_script("resource_map")
	
	# Busca ObjectMap na estrutura WorldManager/Main/Object/ObjectMap
	object_map = find_component_by_path([
		"Main/Object/ObjectMap",
		"Object/ObjectMap",
		"ObjectMap"
	])
	if not object_map:
		object_map = find_component_by_script("object_map")
	
	# Busca ShaderTerrain
	shader_terrain = find_component_by_path([
		"Main/ShaderTerrain",
		"ShaderTerrain"
	])
	
	print("📍 Componentes encontrados:")
	print("  - TerrainMap: ", "✅" if terrain_map else "❌")
	print("  - ResourceMap: ", "✅" if resource_map else "❌")
	print("  - ObjectMap: ", "✅" if object_map else "❌")
	print("  - ShaderTerrain: ", "✅" if shader_terrain else "❌")

func find_component_by_path(possible_paths: Array) -> Node:
	"""Busca um componente usando lista de caminhos possíveis"""
	for path in possible_paths:
		var node = get_node_or_null(path)
		if node:
			print("✅ Componente encontrado em: ", path)
			return node
	return null

func find_component_by_name(component_name: String) -> Node:
	"""Busca um componente por nome"""
	var possible_paths = [
		"Main/Terrain/" + component_name,
		"Main/Resource/" + component_name,
		"Main/Object/" + component_name,
		"Main/" + component_name,
		component_name
	]
	
	return find_component_by_path(possible_paths)

func find_component_by_script(script_name: String) -> Node:
	"""Busca um componente por script"""
	return find_by_script_recursive(self, script_name)

func find_shader_terrain() -> Sprite2D:
	var possible_paths = [
		"Main/ShaderTerrain",
		"ShaderTerrain",
		"Main/Terrain/ShaderTerrain",
		"Terrain/ShaderTerrain"
	]
	
	for path in possible_paths:
		var node = get_node_or_null(path)
		if node and node is Sprite2D:
			print("✅ ShaderTerrain encontrado em: ", path)
			return node
	
	# Busca recursiva
	var shader_node = find_recursive(self, "ShaderTerrain")
	if shader_node and shader_node is Sprite2D:
		print("✅ ShaderTerrain encontrado via busca recursiva")
		return shader_node
	
	print("❌ ShaderTerrain não encontrado!")
	return null

func find_recursive(node: Node, target_name: String) -> Node:
	"""Busca recursiva por nome"""
	if node.name == target_name:
		return node
	
	for child in node.get_children():
		var result = find_recursive(child, target_name)
		if result:
			return result
	
	return null

func find_by_script_recursive(node: Node, script_name: String) -> Node:
	"""Busca recursiva por script"""
	if node.get_script() and node.get_script().resource_path.ends_with(script_name + ".gd"):
		return node
	
	for child in node.get_children():
		var result = find_by_script_recursive(child, script_name)
		if result:
			return result
	
	return null

func sync_component_settings():
	"""Sincroniza configurações entre componentes"""
	
	# Sincroniza dimensões do mundo
	if terrain_map and "mapWidth" in terrain_map:
		terrain_map.mapWidth = world_width
		terrain_map.mapHeight = world_height
	
	# Sincroniza tipo de terreno
	if terrain_map and "terrainType" in terrain_map:
		terrain_map.terrainType = terrain_type
	
	# Sincroniza semente
	if terrain_map and "terrainSeed" in terrain_map:
		terrain_map.terrainSeed = world_seed
	
	# Ativa sistema avançado nos componentes
	if use_advanced_generation:
		if terrain_map and "use_advanced_generation" in terrain_map:
			terrain_map.use_advanced_generation = true
		
		if resource_map and "use_biome_based_generation" in resource_map:
			resource_map.use_biome_based_generation = true
		
		if object_map and "use_biome_based_generation" in object_map:
			object_map.use_biome_based_generation = true

func generate_world():
	"""Gera o mundo completo usando o sistema modular"""
	if is_generating:
		print("⚠️ Geração já em progresso...")
		return
	
	is_generating = true
	print("\n🚀 === INICIANDO GERAÇÃO DO MUNDO PROCEDURAL ===")
	
	var start_time = Time.get_ticks_msec()
	
	# Etapa 1: Gera terreno
	if show_generation_progress:
		print("🌍 Etapa 1/4: Gerando terreno...")
	
	if terrain_map:
		# Força configurações antes da geração
		terrain_map.visible = true
		terrain_map.enabled = true
		terrain_map.scale = Vector2(2.0, 2.0)  # Escala correta
		
		# Verifica qual método de geração usar
		if terrain_map.has_method("GenerateTerrain"):
			print("🌍 Gerando terreno com GenerateTerrain()...")
			terrain_map.GenerateTerrain()
		elif terrain_map.has_method("generate_terrain"):
			print("🌍 Gerando terreno com generate_terrain()...")
			terrain_map.generate_terrain()
		elif terrain_map.has_method("generate"):
			print("🌍 Gerando terreno com generate()...")
			terrain_map.generate()
		else:
			print("❌ Nenhum método de geração encontrado no TerrainMap!")
		
		# Força refresh após geração
		await get_tree().create_timer(0.3).timeout
		terrain_map.queue_redraw()
		print("🎯 TerrainMap: Refresh forçado com escala (2.0, 2.0)")
		
		await get_tree().create_timer(0.2).timeout  # Aguarda processamento
	
	# Etapa 2: Configura shader
	if show_generation_progress:
		print("🎨 Etapa 2/4: Configurando shader...")
	
	if shader_terrain and shader_terrain.has_method("update_texture"):
		shader_terrain.update_texture()
		await get_tree().create_timer(0.3).timeout
	
	# Etapa 3: Gera recursos
	if show_generation_progress:
		print("🔧 Etapa 3/4: Gerando recursos...")
	
	if resource_map and resource_map.has_method("generate"):
		resource_map.generate()
		await get_tree().process_frame
	
	# Etapa 4: Gera objetos
	if show_generation_progress:
		print("🌿 Etapa 4/4: Gerando objetos...")
	
	if object_map and object_map.has_method("generate"):
		object_map.generate()
		await get_tree().process_frame
	
	# === FINALIZAÇÃO ===
	if show_generation_progress:
		print("✅ === GERAÇÃO COMPLETA ===")
		print("⏱️ Tempo total: ", Time.get_ticks_msec() - start_time, "ms")
		print("🌍 Mundo gerado com sucesso!")
	
	# Debug final dos componentes
	call_deferred("debug_final_state")
	
	_on_generation_finished()
	is_generating = false

func debug_final_state():
	"""Debug do estado final após geração"""
	print("\n🔍 === DEBUG ESTADO FINAL ===")
	
	# Debug básico
	if terrain_map:
		print("🗺️ TerrainMap - Scale: ", terrain_map.scale, " | Visible: ", terrain_map.visible)
	
	if resource_map:
		var resource_count = count_tiles_in_map(resource_map)
		print("📦 ResourceMap - Scale: ", resource_map.scale, " | Tiles: ", resource_count, " | Visible: ", resource_map.visible)
	
	if object_map:
		var object_count = count_tiles_in_map(object_map)
		print("🌿 ObjectMap - Scale: ", object_map.scale, " | Tiles: ", object_count, " | Visible: ", object_map.visible)
	
	if shader_terrain:
		print("🎨 ShaderTerrain - Scale: ", shader_terrain.scale, " | Z-Index: ", shader_terrain.z_index)
	
	print("=== FIM DEBUG FINAL ===\n")

func count_tiles_in_map(map: TileMapLayer) -> int:
	"""Conta o número de tiles não vazios em um TileMapLayer"""
	if not map:
		return 0
	
	var tile_count = 0
	for x in range(world_width):
		for y in range(world_height):
			if map.get_cell_source_id(Vector2i(x, y)) != -1:
				tile_count += 1
	return tile_count

func force_full_regeneration():
	"""Força regeneração completa ignorando cache"""
	print("🔄 Forçando regeneração completa...")
	
	# Limpa todos os mapas
	if terrain_map and terrain_map.has_method("clear"):
		terrain_map.clear()
	
	if resource_map and resource_map.has_method("clear"):
		resource_map.clear()
	
	if object_map and object_map.has_method("clear"):
		object_map.clear()
	
	# Remove arquivos de cache
	var dir = DirAccess.open("res://")
	if dir:
		for file in ["mapData.png", "debug_height_preview.png", "debug_temperature_preview.png", "debug_humidity_preview.png"]:
			if dir.file_exists(file):
				dir.remove(file)
	
	# Regenera tudo
	generate_world()

func generate_world_analysis():
	"""Gera relatório completo de análise do mundo"""
	print("\n📊 === RELATÓRIO DE ANÁLISE DO MUNDO ===")
	
	# Análise de terreno
	if terrain_map and terrain_map.has_method("analyze_terrain_composition"):
		print("\n🌍 COMPOSIÇÃO DO TERRENO:")
		var terrain_composition = terrain_map.analyze_terrain_composition()
		for biome_name in terrain_composition:
			var count = terrain_composition[biome_name]
			var total = terrain_composition.values().reduce(func(a, b): return a + b)
			var percentage = float(count) / float(total) * 100.0
			print("  🔹 ", biome_name.capitalize(), ": ", "%.1f" % percentage, "% (", count, " tiles)")
	
	# Análise de recursos
	if resource_map and resource_map.has_method("analyze_distribution"):
		print("\n🔧 DISTRIBUIÇÃO DE RECURSOS:")
		resource_map.analyze_distribution()
	
	# Análise de objetos
	if object_map and object_map.has_method("get_object_coverage_by_biome"):
		print("\n🌿 COBERTURA DE OBJETOS POR BIOMA:")
		var coverage = object_map.get_object_coverage_by_biome()
		for biome_name in coverage:
			var data = coverage[biome_name]
			print("  🔹 ", biome_name.capitalize(), ": ", "%.1f" % data["coverage_percent"], "% cobertura")
	
	# Estatísticas gerais
	print("\n📈 ESTATÍSTICAS GERAIS:")
	print("  - Dimensões do mundo: ", world_width, "x", world_height, " (", world_width * world_height, " tiles)")
	print("  - Semente utilizada: ", world_seed)
	print("  - Tipo de terreno: ", terrain_type)
	print("  - Sistema avançado: ", "Ativo" if use_advanced_generation else "Desativado")
	
	print("=== FIM RELATÓRIO ===\n")

func save_debug_previews():
	"""Salva imagens de debug para análise visual"""
	print("🎨 Salvando previews de debug...")
	
	if noise_generator:
		# Gera previews dos mapas de ruído
		var preview_size = Vector2i(128, 128)
		
		var height_image = noise_generator.generate_preview_image(preview_size.x, preview_size.y, "height")
		height_image.save_png("res://debug_height_full.png")
		
		var temp_image = noise_generator.generate_preview_image(preview_size.x, preview_size.y, "temperature")
		temp_image.save_png("res://debug_temperature_full.png")
		
		var humidity_image = noise_generator.generate_preview_image(preview_size.x, preview_size.y, "humidity")
		humidity_image.save_png("res://debug_humidity_full.png")
		
		print("✅ Previews salvos: debug_*_full.png")
	
	# Gera preview combinado dos biomas
	generate_biome_preview()

func generate_biome_preview():
	"""Gera uma imagem preview dos biomas"""
	if not biome_manager or not noise_generator:
		return
	
	var preview_image = Image.create(world_width, world_height, false, Image.FORMAT_RGB8)
	
	for x in range(world_width):
		for y in range(world_height):
			var height = noise_generator.get_height_at(x, y, terrain_type.to_lower(), world_width, world_height)
			var temperature = noise_generator.get_temperature_at(x, y, world_height)
			var humidity = noise_generator.get_humidity_at(x, y, height)
			
			var biome = biome_manager.get_biome_for_point(height, temperature, humidity)
			var biome_color = biome.get("color", [0.5, 0.5, 0.5])
			
			var color = Color(biome_color[0], biome_color[1], biome_color[2])
			preview_image.set_pixel(x, y, color)
	
	preview_image.save_png("res://debug_biomes_preview.png")
	print("✅ Preview de biomas salvo: debug_biomes_preview.png")

# === FUNCIONALIDADES AVANÇADAS ===

func get_world_statistics() -> Dictionary:
	"""Retorna estatísticas completas do mundo"""
	var stats = {
		"world_info": {
			"width": world_width,
			"height": world_height,
			"total_tiles": world_width * world_height,
			"seed": world_seed,
			"terrain_type": terrain_type,
			"advanced_generation": use_advanced_generation
		},
		"terrain_composition": {},
		"resource_stats": {},
		"object_stats": {}
	}
	
	# Coleta estatísticas de terreno
	if terrain_map and terrain_map.has_method("analyze_terrain_composition"):
		stats["terrain_composition"] = terrain_map.analyze_terrain_composition()
	
	# Coleta estatísticas de recursos
	if resource_map:
		var resource_count = 0
		for x in range(world_width):
			for y in range(world_height):
				if resource_map.get_cell_source_id(Vector2i(x, y)) != -1:
					resource_count += 1
		
		stats["resource_stats"] = {
			"total_resources": resource_count,
			"density_percent": float(resource_count) / float(world_width * world_height) * 100.0
		}
	
	# Coleta estatísticas de objetos
	if object_map:
		var object_count = 0
		for x in range(world_width):
			for y in range(world_height):
				if object_map.get_cell_source_id(Vector2i(x, y)) != -1:
					object_count += 1
		
		stats["object_stats"] = {
			"total_objects": object_count,
			"coverage_percent": float(object_count) / float(world_width * world_height) * 100.0
		}
	
	return stats

func export_world_config() -> Dictionary:
	"""Exporta configuração atual do mundo para reutilização"""
	return {
		"world_config": {
			"seed": world_seed,
			"width": world_width,
			"height": world_height,
			"terrain_type": terrain_type,
			"advanced_generation": use_advanced_generation
		},
		"biome_config": biome_manager.biomes if biome_manager else {},
		"generation_timestamp": Time.get_unix_time_from_system()
	}

func import_world_config(config: Dictionary) -> bool:
	"""Importa configuração de mundo"""
	if not "world_config" in config:
		print("❌ Configuração inválida")
		return false
	
	var world_config = config["world_config"]
	
	world_seed = world_config.get("seed", 0)
	world_width = world_config.get("width", 128)
	world_height = world_config.get("height", 128)
	terrain_type = world_config.get("terrain_type", "Auto")
	use_advanced_generation = world_config.get("advanced_generation", true)
	
	print("✅ Configuração importada com sucesso")
	return true

# === UTILITÁRIOS PARA INTEGRAÇÃO ===

func get_biome_at_world_position(world_pos: Vector2i) -> Dictionary:
	"""Retorna bioma em uma posição do mundo"""
	if not noise_generator or not biome_manager:
		return {}
	
	var height = noise_generator.get_height_at(world_pos.x, world_pos.y, terrain_type.to_lower(), world_width, world_height)
	var temperature = noise_generator.get_temperature_at(world_pos.x, world_pos.y, world_height)
	var humidity = noise_generator.get_humidity_at(world_pos.x, world_pos.y, height)
	
	return biome_manager.get_biome_for_point(height, temperature, humidity)

func is_position_valid_for_building(world_pos: Vector2i) -> bool:
	"""Verifica se uma posição é válida para construção"""
	# Verifica limites
	if world_pos.x < 0 or world_pos.y < 0 or world_pos.x >= world_width or world_pos.y >= world_height:
		return false
	
	# Verifica se não é água
	var biome = get_biome_at_world_position(world_pos)
	var biome_name = biome.get("name", "")
	
	if biome_name == "ocean":
		return false
	
	# Verifica se não há recursos ou objetos
	var has_resource = resource_map and resource_map.get_cell_source_id(world_pos) != -1
	var has_object = object_map and object_map.get_cell_source_id(world_pos) != -1
	
	return not has_resource and not has_object

func get_nearby_resources(world_pos: Vector2i, radius: int = 5) -> Array:
	"""Retorna recursos próximos a uma posição"""
	var nearby_resources = []
	
	if not resource_map:
		return nearby_resources
	
	for x in range(world_pos.x - radius, world_pos.x + radius + 1):
		for y in range(world_pos.y - radius, world_pos.y + radius + 1):
			if x >= 0 and y >= 0 and x < world_width and y < world_height:
				var pos = Vector2i(x, y)
				if resource_map.get_cell_source_id(pos) != -1:
					var distance = world_pos.distance_to(Vector2(x, y))
					nearby_resources.append({
						"position": pos,
						"distance": distance,
						"type": "stone"  # Por enquanto apenas pedra
					})
	
	# Ordena por distância
	nearby_resources.sort_custom(func(a, b): return a["distance"] < b["distance"])
	
	return nearby_resources

# === EVENTOS E CALLBACKS ===

signal world_generation_started()
signal world_generation_finished()

func _on_generation_started():
	world_generation_started.emit()

func _on_generation_finished():
	world_generation_finished.emit()

# === COMPATIBILIDADE COM SISTEMA ANTERIOR ===

func _on_generate_button_pressed():
	"""Compatibilidade com botão de geração do sistema anterior"""
	if not is_generating:
		print("🔁 Regenerando mundo via botão...")
		generate_world()
	else:
		print("⚠️ Geração em progresso, aguarde...")

# Métodos para compatibilidade com main.gd anterior
func force_regenerate():
	force_full_regeneration()

func force_realign():
	print("🔄 Forçando realinhamento de componentes...")
	sync_component_settings()
	
	if shader_terrain and shader_terrain.has_method("setup_sprite_transform"):
		shader_terrain.setup_sprite_transform()

# === DEBUG E TESTES ===

func _input(event):
	if not Engine.is_editor_hint():
		if event.is_action_pressed("ui_cancel"): # ESC
			generate_world_analysis()
		elif event.is_action_pressed("ui_focus_next"): # Tab
			force_realign()
		elif event.is_action_pressed("ui_select"): # Space
			save_debug_previews()

@export var test_specific_position: Vector2i = Vector2i(64, 64)
@export var test_position_analysis: bool = false:
	set(value):
		test_position_analysis = false
		if value:
			test_position_data()

func test_position_data():
	"""Testa dados em uma posição específica"""
	var pos = test_specific_position
	print("\n🔍 === TESTE DE POSIÇÃO (", pos, ") ===")
	
	if noise_generator:
		var height = noise_generator.get_height_at(pos.x, pos.y, terrain_type.to_lower(), world_width, world_height)
		var temp = noise_generator.get_temperature_at(pos.x, pos.y, world_height)
		var humidity = noise_generator.get_humidity_at(pos.x, pos.y, height)
		
		print("🌀 Ruído:")
		print("  - Altura: ", "%.3f" % height)
		print("  - Temperatura: ", "%.3f" % temp)
		print("  - Umidade: ", "%.3f" % humidity)
	
	var biome = get_biome_at_world_position(pos)
	print("🌍 Bioma: ", biome.get("name", "Desconhecido"))
	
	if terrain_map:
		var terrain_tile = terrain_map.get_cell_atlas_coords(pos)
		print("🗺️ Tile de terreno: ", terrain_tile)
	
	if resource_map:
		var has_resource = resource_map.get_cell_source_id(pos) != -1
		print("🔧 Tem recurso: ", has_resource)
	
	if object_map:
		var has_object = object_map.get_cell_source_id(pos) != -1
		print("🌿 Tem objeto: ", has_object)
	
	print("🏗️ Válido para construção: ", is_position_valid_for_building(pos))
	
	print("=== FIM TESTE ===\n")
