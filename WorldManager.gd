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

# === SISTEMA DE COORDENAÇÃO INTEGRADO ===
var occupied_positions: Dictionary = {}
var generation_state = {
	"terrain_ready": false,
	"resources_ready": false,
	"objects_ready": false
}

# === CONSTANTES ===
const CORRECT_SCALE = Vector2(2.0, 2.0)
const GENERATION_DELAYS = {
	"terrain": 1.5,
	"shader": 1.0,
	"resources": 1.0,
	"objects": 0.5
}

# === ESTADO ===
var is_generating: bool = false

func _ready():
	print("🌍 WorldManager iniciado (com coordenação integrada)")
	if not find_all_components():
		print("❌ Erro: Nem todos os componentes foram encontrados.")
		return
	
	setup_world_parameters()
	
	if not Engine.is_editor_hint():
		await get_tree().process_frame
		generate_complete_world()

# === BUSCA DE COMPONENTES ===
func find_all_components() -> bool:
	"""Encontra todos os componentes necessários"""
	print("🔍 Procurando componentes...")
	
	terrain_generator = find_component_by_group("terrain")
	resource_generator = find_component_by_group("resources")
	object_generator = find_component_by_group("objects")
	shader_controller = find_component_by_group("shader")
	
	print_component_status()
	return terrain_generator != null

func find_component_by_group(group_name: String) -> Node:
	"""Busca componente por grupo de forma unificada"""
	var nodes = get_tree().get_nodes_in_group(group_name)
	if nodes.size() > 0:
		print("✅ ", group_name.capitalize(), " encontrado: ", nodes[0].get_path())
		return nodes[0]
	
	print("❌ ", group_name.capitalize(), " não encontrado")
	return null

func print_component_status():
	"""Imprime status dos componentes"""
	print("📊 Status dos componentes:")
	print("  🌍 TerrainGenerator: ", "✅" if terrain_generator else "❌")
	print("  🔧 ResourceGenerator: ", "✅" if resource_generator else "❌")
	print("  🌿 ObjectGenerator: ", "✅" if object_generator else "❌")
	print("  🎨 ShaderController: ", "✅" if shader_controller else "❌")

# === CONFIGURAÇÃO ===
func setup_world_parameters():
	"""Configura parâmetros do mundo em todos os componentes"""
	var seed_to_use = randi() if world_seed == 0 else world_seed
	world_seed = seed_to_use
	
	configure_terrain_generator(seed_to_use)
	configure_resource_generator()
	configure_object_generator()
	configure_shader_controller()
	
	print("⚙️ Parâmetros do mundo configurados (seed: ", seed_to_use, ")")

func configure_terrain_generator(seed_value: int):
	"""Configura o gerador de terreno"""
	if not terrain_generator:
		return
	
	set_property_if_exists(terrain_generator, "map_width", map_size)
	set_property_if_exists(terrain_generator, "map_height", map_size)
	set_property_if_exists(terrain_generator, "terrain_seed", seed_value)
	set_property_if_exists(terrain_generator, "terrain_type", world_type)
	
	apply_correct_transform(terrain_generator, 0)

func configure_resource_generator():
	"""Configura o gerador de recursos"""
	if not resource_generator:
		return
	
	set_property_if_exists(resource_generator, "rock_formation_density", resource_abundance * 0.15)
	apply_correct_transform(resource_generator, 1)

func configure_object_generator():
	"""Configura o gerador de objetos"""
	if not object_generator:
		return
	
	set_property_if_exists(object_generator, "grass_density", vegetation_density * 0.12)
	set_property_if_exists(object_generator, "tree_density", vegetation_density * 0.06)
	set_property_if_exists(object_generator, "bush_density", vegetation_density * 0.03)
	
	apply_correct_transform(object_generator, 2)

func configure_shader_controller():
	"""Configura o controlador de shader"""
	if not shader_controller:
		return
	
	apply_correct_transform(shader_controller, -1)

func set_property_if_exists(node: Node, property: String, value):
	"""Define propriedade se ela existir no nó"""
	if property in node:
		node.set(property, value)

func apply_correct_transform(node: Node, z_index_value: int):
	"""Aplica transformação correta a um nó"""
	if not node:
		return
	
	node.position = Vector2(0, 0)
	node.scale = CORRECT_SCALE
	node.visible = true
	
	if "z_index" in node:
		node.z_index = z_index_value

# === GERAÇÃO COORDENADA INTEGRADA ===
func generate_complete_world():
	"""Gera o mundo completo com coordenação integrada"""
	if is_generating:
		print("⚠️ Geração já em progresso...")
		return
	
	is_generating = true
	print("\n🚀 === INICIANDO GERAÇÃO COORDENADA ===")
	var start_time = Time.get_ticks_msec()
	
	# Reset do estado
	reset_generation_state()
	clear_world()
	
	if not terrain_generator:
		print("❌ TerrainGenerator não encontrado! Abortando geração.")
		is_generating = false
		return
	
	# Força configurações corretas
	force_all_correct_transforms()
	
	# === SEQUÊNCIA COORDENADA ===
	await generate_terrain_coordinated()
	await configure_shader_coordinated()
	await generate_resources_coordinated()
	await generate_objects_coordinated()
	
	var total_time = Time.get_ticks_msec() - start_time
	print("✅ === MUNDO GERADO COM SUCESSO ===")
	print("⏱️ Tempo total: ", total_time, "ms")
	print("🎯 Seed usado: ", world_seed)
	
	call_deferred("force_final_transforms")
	verify_no_conflicts()
	analyze_world()
	is_generating = false

func reset_generation_state():
	"""Reset do estado de geração"""
	generation_state = {
		"terrain_ready": false,
		"resources_ready": false,
		"objects_ready": false
	}
	occupied_positions.clear()

func generate_terrain_coordinated() -> void:
	"""Gera terreno de forma coordenada"""
	print("🌍 Etapa 1/4: Gerando terreno...")
	
	if terrain_generator.has_method("GenerateTerrain"):
		terrain_generator.GenerateTerrain()
	elif terrain_generator.has_method("generate"):
		terrain_generator.generate()
	
	await get_tree().create_timer(GENERATION_DELAYS["terrain"]).timeout
	generation_state["terrain_ready"] = true
	print("✅ Terreno gerado")

func configure_shader_coordinated() -> void:
	"""Configura shader de forma coordenada"""
	if not shader_controller:
		return
	
	print("🎨 Etapa 2/4: Configurando shader...")
	apply_correct_transform(shader_controller, -1)
	
	if shader_controller.has_method("update_texture"):
		shader_controller.call_deferred("update_texture")
	elif shader_controller.has_method("refresh"):
		shader_controller.call_deferred("refresh")
	
	await get_tree().create_timer(GENERATION_DELAYS["shader"]).timeout
	print("✅ Shader configurado")

func generate_resources_coordinated() -> void:
	"""Gera recursos de forma coordenada"""
	if not resource_generator:
		print("❌ ResourceGenerator não encontrado!")
		return
	
	print("🔧 Etapa 3/4: Gerando recursos...")
	apply_correct_transform(resource_generator, 1)
	
	if resource_generator.has_method("generate"):
		resource_generator.generate()
	
	await get_tree().create_timer(GENERATION_DELAYS["resources"]).timeout
	
	# CRÍTICO: Mapeia posições ocupadas
	map_occupied_positions()
	
	generation_state["resources_ready"] = true
	var resource_count = count_generated_items(resource_generator)
	print("✅ Recursos gerados: ", resource_count)

func map_occupied_positions():
	"""Mapeia todas as posições ocupadas por recursos"""
	print("📍 Mapeando posições ocupadas...")
	
	occupied_positions.clear()
	
	if not resource_generator:
		return
	
	var occupied_count = 0
	
	for x in range(map_size):
		for y in range(map_size):
			var pos = Vector2i(x, y)
			if resource_generator.get_cell_source_id(pos) != -1:
				occupied_positions[str(pos)] = true
				occupied_count += 1
	
	print("🚫 ", occupied_count, " posições ocupadas por recursos")

func generate_objects_coordinated() -> void:
	"""Gera objetos evitando recursos"""
	if not object_generator:
		print("❌ ObjectGenerator não encontrado!")
		return
	
	print("🌿 Etapa 4/4: Gerando objetos (evitando recursos)...")
	apply_correct_transform(object_generator, 2)
	
	# CRÍTICO: Passa posições ocupadas para o ObjectGenerator
	if object_generator.has_method("set_occupied_positions"):
		object_generator.set_occupied_positions(occupied_positions)
	
	# Garante que encontre os geradores
	if object_generator.has_method("find_generators"):
		object_generator.find_generators()
	
	if object_generator.has_method("generate"):
		object_generator.generate()
	
	await get_tree().create_timer(GENERATION_DELAYS["objects"]).timeout
	
	generation_state["objects_ready"] = true
	var object_count = count_generated_items(object_generator)
	print("✅ Objetos gerados: ", object_count)

# === FUNÇÕES AUXILIARES ===
func force_all_correct_transforms():
	"""Força transformações corretas em todos os componentes"""
	print("🔧 Forçando transformações corretas...")
	
	apply_correct_transform(terrain_generator, 0)
	apply_correct_transform(resource_generator, 1)
	apply_correct_transform(object_generator, 2)
	apply_correct_transform(shader_controller, -1)

func force_final_transforms():
	"""Força transformações finais após toda a geração"""
	print("🔧 === APLICANDO TRANSFORMAÇÕES FINAIS ===")
	force_all_correct_transforms()
	
	# Força atualização visual
	for component in [terrain_generator, resource_generator, object_generator, shader_controller]:
		if component and component.has_method("queue_redraw"):
			component.queue_redraw()
	
	print("✅ Transformações finais aplicadas")

func clear_world():
	"""Limpa todos os componentes"""
	print("🧹 Limpando mundo...")
	
	for component in [terrain_generator, resource_generator, object_generator]:
		if component and component.has_method("clear"):
			component.clear()
	
	# Remove mapData.png antigo
	if FileAccess.file_exists("res://mapData.png"):
		var dir = DirAccess.open("res://")
		if dir:
			dir.remove("res://mapData.png")
			print("🗑️ mapData.png removido")
			await get_tree().process_frame

func count_generated_items(generator: TileMapLayer) -> int:
	"""Conta quantos itens foram gerados"""
	if not generator:
		return 0
	
	var count = 0
	# Amostragem rápida para não impactar performance
	for x in range(0, map_size, 4):
		for y in range(0, map_size, 4):
			if generator.get_cell_source_id(Vector2i(x, y)) != -1:
				count += 1
	
	return count * 16  # Multiplica pela amostragem

func verify_no_conflicts():
	"""Verifica se há conflitos entre objetos e recursos"""
	print("\n🔍 === VERIFICAÇÃO FINAL DE CONFLITOS ===")
	
	if not resource_generator or not object_generator:
		print("❌ Não é possível verificar - geradores não encontrados")
		return
	
	var conflicts = 0
	var sample_positions = []
	
	# Verifica uma amostra das posições ocupadas
	var check_count = 0
	for pos_str in occupied_positions:
		if check_count >= 100:  # Limita verificação
			break
		
		# Parse da string da posição
		var pos_clean = pos_str.replace("(", "").replace(")", "")
		var parts = pos_clean.split(", ")
		if parts.size() >= 2:
			var pos = Vector2i(int(parts[0]), int(parts[1]))
			
			var has_resource = resource_generator.get_cell_source_id(pos) != -1
			var has_object = object_generator.get_cell_source_id(pos) != -1
			
			if has_resource and has_object:
				conflicts += 1
				if sample_positions.size() < 5:
					sample_positions.append(pos)
		
		check_count += 1
	
	if conflicts == 0:
		print("✅ Nenhum conflito detectado!")
	else:
		print("⚠️ ", conflicts, " conflitos detectados:")
		for pos in sample_positions:
			print("  ❌ Conflito em: ", pos)
	
	print("=== FIM VERIFICAÇÃO ===\n")

func analyze_world():
	"""Analisa o mundo gerado"""
	print("\n📊 === ANÁLISE DO MUNDO GERADO ===")
	
	if not terrain_generator:
		print("❌ Não é possível analisar sem TerrainGenerator")
		return
	
	var biome_counts = {}
	var resource_count = count_generated_items(resource_generator) if resource_generator else 0
	var object_count = count_generated_items(object_generator) if object_generator else 0
	var total_tiles = map_size * map_size
	
	# Análise por amostragem de biomas
	var sample_size = 50
	var step = map_size / sample_size
	
	for x in range(0, map_size, int(step)):
		for y in range(0, map_size, int(step)):
			var biome = "grassland"
			if terrain_generator.has_method("get_biome_at_position"):
				biome = terrain_generator.get_biome_at_position(x, y)
			
			if biome in biome_counts:
				biome_counts[biome] += 1
			else:
				biome_counts[biome] = 1
	
	var sample_total = biome_counts.values().reduce(func(a, b): return a + b, 0)
	
	# Relatório de composição
	print("🌍 Composição do terreno:")
	for biome in biome_counts:
		var percentage = float(biome_counts[biome]) / float(sample_total) * 100.0
		print("  🔹 ", biome.capitalize(), ": ", "%.1f" % percentage, "%")
	
	# Relatório de recursos e objetos
	var resource_density = float(resource_count) / float(total_tiles) * 100.0
	var object_density = float(object_count) / float(total_tiles) * 100.0
	
	print("🔧 Recursos: ", resource_count, " (", "%.2f" % resource_density, "%)")
	print("🌿 Objetos: ", object_count, " (", "%.2f" % object_density, "%)")
	
	verify_layer_integrity()
	print("=== FIM ANÁLISE ===\n")

func verify_layer_integrity():
	"""Verifica integridade das camadas"""
	var issues = []
	
	for component_info in [
		{"node": terrain_generator, "name": "TerrainMap", "z_index": 0},
		{"node": resource_generator, "name": "ResourceMap", "z_index": 1},
		{"node": object_generator, "name": "ObjectMap", "z_index": 2}
	]:
		var node = component_info["node"]
		var name = component_info["name"]
		var expected_z = component_info["z_index"]
		
		if not node:
			continue
		
		if node.position != Vector2(0, 0):
			issues.append(name + " fora de posição: " + str(node.position))
		
		if node.scale != CORRECT_SCALE:
			issues.append(name + " escala incorreta: " + str(node.scale))
		
		if "z_index" in node and node.z_index != expected_z:
			issues.append(name + " z-index incorreto: " + str(node.z_index))
	
	if issues.size() == 0:
		print("  ✅ Todas as camadas estão corretas")
	else:
		print("  ⚠️ Problemas encontrados:")
		for issue in issues:
			print("    - ", issue)

# === SISTEMA DE CORREÇÃO AUTOMÁTICA ===
func _process(_delta):
	if not Engine.is_editor_hint() and not is_generating:
		# Corrige automaticamente transformações incorretas
		var needs_correction = false
		
		for component in [terrain_generator, resource_generator, object_generator, shader_controller]:
			if component and (component.position != Vector2(0, 0) or component.scale != CORRECT_SCALE):
				component.position = Vector2(0, 0)
				component.scale = CORRECT_SCALE
				needs_correction = true

# === FUNÇÕES DE CONVENIÊNCIA ===
func _on_generate_button_pressed():
	"""Compatibilidade com UI"""
	generate_complete_world()

func force_regenerate():
	"""Força regeneração completa"""
	clear_world()
	generate_complete_world()
