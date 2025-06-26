extends Node2D

# === CONFIGURAÇÕES ===
@export_group("Controles Principais")
@export var generate_world: bool = false:
	set(value):
		if value:
			generate_world = false
			generate_complete_world()

@export var clear_all: bool = false:
	set(value):
		if value:
			clear_all = false
			clear_world()

# === CONFIGURAÇÕES DO MUNDO ===
@export_group("Configuração do Mundo")
@export var world_seed: int = 0
@export var map_size: int = 128
@export_enum("Continente", "Ilha", "Arquipélago", "Península") 
var world_type: String = "Continente"

@export_group("Qualidade da Geração")
@export_range(0.0, 1.0) var terrain_quality: float = 0.8
@export_range(0.0, 1.0) var resource_abundance: float = 0.5
@export_range(0.0, 1.0) var vegetation_density: float = 0.6

# === REFERÊNCIAS DOS COMPONENTES ===
var terrain_generator: TileMapLayer
var resource_generator: TileMapLayer
var object_generator: TileMapLayer
var shader_controller: Sprite2D

# === ESTADO ===
var is_generating: bool = false

func _ready():
	print("🌍 WorldManager iniciado")
	if not find_components():
		print("❌ Erro: Nem todos os componentes foram encontrados. Verifique a estrutura da cena.")
		return
	
	setup_world_parameters()
	
	if not Engine.is_editor_hint():
		await get_tree().process_frame
		generate_complete_world()

func find_components() -> bool:
	"""Encontra todos os componentes - VERSÃO CORRIGIDA"""
	print("🔍 Procurando componentes...")
	
	# CORREÇÃO: Busca com caminhos mais específicos
	var terrain_paths = [
		"Terrain/TerrainMap",
		"Main/Terrain/TerrainMap", 
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
	
	# Busca ResourceGenerator
	var resource_paths = [
		"Resource/ResourceMap",
		"Main/Resource/ResourceMap",
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
	
	# Busca ObjectGenerator
	var object_paths = [
		"Object/ObjectMap",
		"Main/Object/ObjectMap",
		"/root/Main/Object/ObjectMap"
	]
	
	for path in object_paths:
		var node = get_node_or_null(path)
		if node and node is TileMapLayer:
			object_generator = node
			print("✅ ObjectGenerator encontrado em: ", path)
			break
	
	if not object_generator:
		var object_nodes = get_tree().get_nodes_in_group("objects")
		if object_nodes.size() > 0:
			object_generator = object_nodes[0]
			print("✅ ObjectGenerator encontrado via grupo: ", object_generator.get_path())
	
	# Busca ShaderController
	var shader_paths = [
		"ShaderTerrain",
		"Main/ShaderTerrain",
		"/root/Main/ShaderTerrain"
	]
	
	for path in shader_paths:
		var node = get_node_or_null(path)
		if node and node is Sprite2D:
			shader_controller = node
			print("✅ ShaderController encontrado em: ", path)
			break
	
	if not shader_controller:
		var shader_nodes = get_tree().get_nodes_in_group("shader")
		if shader_nodes.size() > 0:
			shader_controller = shader_nodes[0]
			print("✅ ShaderController encontrado via grupo: ", shader_controller.get_path())
	
	print_component_status()
	return terrain_generator != null

func print_component_status():
	"""Imprime status dos componentes"""
	print("📊 Status dos componentes:")
	print("  🌍 TerrainGenerator: ", "✅" if terrain_generator else "❌")
	print("  🔧 ResourceGenerator: ", "✅" if resource_generator else "❌")
	print("  🌿 ObjectGenerator: ", "✅" if object_generator else "❌")
	print("  🎨 ShaderController: ", "✅" if shader_controller else "❌")

func setup_world_parameters():
	"""Configura parâmetros do mundo em todos os componentes - CORRIGIDO"""
	# CORREÇÃO: Gera nova seed sempre ou usa a especificada
	var seed_to_use = randi() if world_seed == 0 else world_seed
	world_seed = seed_to_use  # Atualiza para debug
	
	if terrain_generator:
		# CORREÇÃO: Usa apenas propriedades que existem no TerrainGenerator
		if "map_width" in terrain_generator:
			terrain_generator.map_width = map_size
		if "map_height" in terrain_generator:
			terrain_generator.map_height = map_size
		if "terrain_seed" in terrain_generator:
			terrain_generator.terrain_seed = seed_to_use
		if "terrain_type" in terrain_generator:
			terrain_generator.terrain_type = world_type
		
		# CORREÇÃO: Verifica se propriedades existem antes de definir
		if "terrain_smoothness" in terrain_generator:
			terrain_generator.terrain_smoothness = terrain_quality
		if "noise_frequency" in terrain_generator:
			terrain_generator.noise_frequency = lerp(0.01, 0.03, terrain_quality)
		if "noise_octaves" in terrain_generator:
			terrain_generator.noise_octaves = int(lerp(2.0, 6.0, terrain_quality))
		
		# CORREÇÃO: Força escala 2.0 no terrain
		terrain_generator.scale = Vector2(2.0, 2.0)
	
	if resource_generator:
		# CORREÇÃO: Verifica se propriedades existem
		if "stone_density" in resource_generator:
			resource_generator.stone_density = resource_abundance * 0.025  # AUMENTADO
		if "metal_density" in resource_generator:
			resource_generator.metal_density = resource_abundance * 0.012  # AUMENTADO
		
		# CORREÇÃO: Força escala 2.0 no resource
		resource_generator.scale = Vector2(2.0, 2.0)
	
	if object_generator:
		# CORREÇÃO: Verifica se propriedades existem
		if "grass_density" in object_generator:
			object_generator.grass_density = vegetation_density * 0.12
		if "tree_density" in object_generator:
			object_generator.tree_density = vegetation_density * 0.06
		if "bush_density" in object_generator:
			object_generator.bush_density = vegetation_density * 0.03
		
		# CORREÇÃO: Força escala 2.0 no object
		object_generator.scale = Vector2(2.0, 2.0)
	
	if shader_controller:
		# CORREÇÃO: Força escala 2.0 no shader
		shader_controller.scale = Vector2(2.0, 2.0)
	
	print("⚙️ Parâmetros do mundo configurados (seed: ", seed_to_use, ")")

func generate_complete_world():
	"""Gera o mundo completo em sequência - VERSÃO CORRIGIDA"""
	if is_generating:
		print("⚠️ Geração já em progresso...")
		return
	
	is_generating = true
	print("\n🚀 === INICIANDO GERAÇÃO COMPLETA DO MUNDO ===")
	var start_time = Time.get_ticks_msec()
	
	clear_world()
	
	if not terrain_generator:
		print("❌ TerrainGenerator não encontrado! Abortando geração.")
		is_generating = false
		return
	
	# CORREÇÃO: Força escala 2.0 em todos os componentes antes da geração
	force_correct_scales()
	
	# Etapa 1: Terreno
	print("🌍 Etapa 1/4: Gerando terreno...")
	terrain_generator.GenerateTerrain()
	# CORREÇÃO: Aguarda mais tempo para garantir que mapData.png seja salvo
	await get_tree().create_timer(1.5).timeout
	
	# Etapa 2: Shader
	if shader_controller:
		print("🎨 Etapa 2/4: Configurando shader...")
		
		# CORREÇÃO: Força escala 2.0 no shader
		shader_controller.scale = Vector2(2.0, 2.0)
		
		if shader_controller.has_method("update_texture"):
			shader_controller.call_deferred("update_texture")
		elif shader_controller.has_method("refresh"):
			shader_controller.call_deferred("refresh")
		await get_tree().create_timer(1.0).timeout  # AUMENTADO
	
	# Etapa 3: Recursos
	if resource_generator:
		print("🔧 Etapa 3/4: Gerando recursos...")
		
		# CORREÇÃO: Força escala 2.0 no resource
		resource_generator.scale = Vector2(2.0, 2.0)
		
		resource_generator.generate()
		await get_tree().create_timer(0.5).timeout
	
	# Etapa 4: Objetos
	if object_generator:
		print("🌿 Etapa 4/4: Gerando objetos...")
		
		# CORREÇÃO: Força escala 2.0 no object
		object_generator.scale = Vector2(2.0, 2.0)
		
		object_generator.generate()
		await get_tree().create_timer(0.3).timeout
	
	var total_time = Time.get_ticks_msec() - start_time
	print("✅ === MUNDO GERADO COM SUCESSO ===")
	print("⏱️ Tempo total: ", total_time, "ms")
	print("🎯 Seed usado: ", world_seed)
	
	# CORREÇÃO: Força escala final em todos os componentes
	call_deferred("force_final_scales")
	
	analyze_world()
	is_generating = false

func force_correct_scales():
	"""Força escala correta em todos os componentes"""
	print("🔧 Forçando escalas corretas...")
	
	if terrain_generator:
		terrain_generator.scale = Vector2(2.0, 2.0)
		terrain_generator.visible = true
		terrain_generator.z_index = 0
		print("  🌍 TerrainMap: escala (2.0, 2.0)")
	
	if resource_generator:
		resource_generator.scale = Vector2(2.0, 2.0)
		resource_generator.visible = true
		resource_generator.z_index = 1
		print("  🔧 ResourceMap: escala (2.0, 2.0)")
	
	if object_generator:
		object_generator.scale = Vector2(2.0, 2.0)
		object_generator.visible = true
		object_generator.z_index = 2
		print("  🌿 ObjectMap: escala (2.0, 2.0)")
	
	if shader_controller:
		shader_controller.scale = Vector2(2.0, 2.0)
		shader_controller.visible = true
		shader_controller.z_index = -1
		print("  🎨 ShaderTerrain: escala (2.0, 2.0)")

func force_final_scales():
	"""Força escala final após toda a geração"""
	print("🔧 === APLICANDO ESCALAS FINAIS ===")
	force_correct_scales()
	
	# CORREÇÃO: Força atualização visual
	if terrain_generator:
		terrain_generator.queue_redraw()
	if resource_generator:
		resource_generator.queue_redraw()
	if object_generator:
		object_generator.queue_redraw()
	if shader_controller:
		shader_controller.queue_redraw()
	
	print("✅ Escalas finais aplicadas")

func clear_world():
	"""Limpa todos os componentes"""
	print("🧹 Limpando mundo...")
	
	if terrain_generator:
		terrain_generator.clear()
	
	if resource_generator:
		resource_generator.clear()
	
	if object_generator:
		object_generator.clear()
	
	# CORREÇÃO: Remove mapData.png antigo
	if FileAccess.file_exists("res://mapData.png"):
		var dir = DirAccess.open("res://")
		if dir:
			dir.remove("res://mapData.png")
			print("🗑️ mapData.png removido")
			await get_tree().process_frame  # Aguarda sistema de arquivos

func analyze_world():
	"""Analisa o mundo gerado"""
	print("\n📊 === ANÁLISE DO MUNDO GERADO ===")
	
	if not terrain_generator:
		print("❌ Não é possível analisar sem TerrainGenerator")
		return
	
	var biome_counts = {}
	var total_tiles = map_size * map_size
	var sample_size = min(50.0, map_size / 4.0)
	var step = max(1, float(map_size) / float(sample_size))
	
	for x in range(0, map_size, int(step)):
		for y in range(0, map_size, int(step)):
			var biome = terrain_generator.get_biome_at_position(x, y)
			if biome in biome_counts:
				biome_counts[biome] += 1
			else:
				biome_counts[biome] = 1
	
	var sample_total = biome_counts.values().reduce(func(a, b): return a + b, 0)
	print("🌍 Composição do terreno:")
	for biome in biome_counts:
		var percentage = float(biome_counts[biome]) / float(sample_total) * 100.0
		print("  🔹 ", biome.capitalize(), ": ", "%.1f" % percentage, "%")
	
	if resource_generator:
		var resource_count = 0
		for x in range(0, map_size, int(step)):
			for y in range(0, map_size, int(step)):
				if resource_generator.get_cell_source_id(Vector2i(x, y)) != -1:
					resource_count += 1
		var resource_density = float(resource_count) / float(sample_total) * 100.0
		print("🔧 Densidade de recursos: ", "%.2f" % resource_density, "%")
	
	if object_generator:
		var object_count = 0
		for x in range(0, map_size, int(step)):
			for y in range(0, map_size, int(step)):
				if object_generator.get_cell_source_id(Vector2i(x, y)) != -1:
					object_count += 1
		var object_density = float(object_count) / float(sample_total) * 100.0
		print("🌿 Densidade de objetos: ", "%.2f" % object_density, "%")
	
	print("=== FIM ANÁLISE ===\n")

# === FUNÇÕES DE DEBUG ===
@export_group("Debug")
@export var debug_world_analysis: bool = false:
	set(value):
		if value:
			debug_world_analysis = false
			detailed_world_analysis()

@export var debug_component_paths: bool = false:
	set(value):
		if value:
			debug_component_paths = false
			debug_scene_structure()

func detailed_world_analysis():
	"""Análise detalhada do mundo"""
	print("\n🔍 === ANÁLISE DETALHADA DO MUNDO ===")
	
	if not terrain_generator:
		print("❌ TerrainGenerator não disponível")
		return
	
	var detailed_analysis = {}
	
	for x in range(0, map_size, 4):
		for y in range(0, map_size, 4):
			var biome = terrain_generator.get_biome_at_position(x, y)
			
			if not biome in detailed_analysis:
				detailed_analysis[biome] = {
					"positions": [],
					"resources": 0,
					"objects": 0
				}
			
			detailed_analysis[biome]["positions"].append(Vector2i(x, y))
			
			if resource_generator and resource_generator.get_cell_source_id(Vector2i(x, y)) != -1:
				detailed_analysis[biome]["resources"] += 1
			
			if object_generator and object_generator.get_cell_source_id(Vector2i(x, y)) != -1:
				detailed_analysis[biome]["objects"] += 1
	
	for biome in detailed_analysis:
		var data = detailed_analysis[biome]
		var tile_count = data["positions"].size()
		var resource_density = float(data["resources"]) / float(tile_count) * 100.0 if tile_count > 0 else 0.0
		var object_density = float(data["objects"]) / float(tile_count) * 100.0 if tile_count > 0 else 0.0
		
		print("🔹 ", biome.capitalize(), ":")
		print("    Tiles: ", tile_count)
		print("    Recursos: ", data["resources"], " (", "%.1f" % resource_density, "%)")
		print("    Objetos: ", data["objects"], " (", "%.1f" % object_density, "%)")
	
	print("=== FIM ANÁLISE DETALHADA ===\n")

func debug_scene_structure():
	"""Debug da estrutura da cena"""
	print("\n🔍 === ESTRUTURA DA CENA ===")
	print_node_tree(self, 0)
	print("=== FIM ESTRUTURA ===\n")

func print_node_tree(node: Node, depth: int):
	"""Imprime árvore de nós"""
	var indent = ""
	for i in range(depth):
		indent += "  "
	
	var node_info = indent + "📁 " + node.name + " (" + node.get_class() + ")"
	if node.get_script():
		node_info += " [Script: " + node.get_script().resource_path.get_file() + "]"
	
	print(node_info)
	
	for child in node.get_children():
		print_node_tree(child, depth + 1)

func _on_generate_button_pressed():
	"""Compatibilidade com UI"""
	generate_complete_world()

func force_regenerate():
	"""Força regeneração completa"""
	clear_world()
	generate_complete_world()

# CORREÇÃO: Sistema para manter escalas corretas
func _process(_delta):
	if not Engine.is_editor_hint() and not is_generating:
		# Verifica e corrige escalas automaticamente
		var needs_correction = false
		
		if terrain_generator and terrain_generator.scale != Vector2(2.0, 2.0):
			terrain_generator.scale = Vector2(2.0, 2.0)
			needs_correction = true
		
		if resource_generator and resource_generator.scale != Vector2(2.0, 2.0):
			resource_generator.scale = Vector2(2.0, 2.0)
			needs_correction = true
		
		if object_generator and object_generator.scale != Vector2(2.0, 2.0):
			object_generator.scale = Vector2(2.0, 2.0)
			needs_correction = true
		
		if shader_controller and shader_controller.scale != Vector2(2.0, 2.0):
			shader_controller.scale = Vector2(2.0, 2.0)
			needs_correction = true
		
		if needs_correction:
			print("🔧 Escalas corrigidas automaticamente")

func _input(event):
	if Engine.is_editor_hint():
		return
	
	if event.is_action_pressed("ui_cancel"):  # ESC
		detailed_world_analysis()
	elif event.is_action_pressed("ui_accept"):  # Enter
		force_regenerate()
	elif event.is_action_pressed("ui_select"):  # Space
		debug_scene_structure()
	elif event.is_action_pressed("ui_focus_next"):  # Tab
		force_correct_scales()
