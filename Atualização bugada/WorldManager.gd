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
@export_range(0.0, 1.0) var resource_abundance: float = 0.4  # Reduzido
@export_range(0.0, 1.0) var vegetation_density: float = 0.5  # Reduzido

# === CONFIGURAÇÕES DE SEPARAÇÃO ===
@export_group("Separação e Espaçamento")
@export_range(1, 5) var resource_object_separation: int = 2  # Separação entre recursos e objetos
@export_range(1, 3) var object_spacing: int = 1  # Espaçamento entre objetos
@export_range(1, 8) var map_border_safety: int = 3  # Margem de segurança das bordas

# === REFERÊNCIAS DOS COMPONENTES ===
var terrain_generator: TileMapLayer
var resource_generator: TileMapLayer
var object_generator: TileMapLayer
var shader_controller: Sprite2D

# === SISTEMA DE COORDENAÇÃO MELHORADO ===
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
	"resources": 1.2,
	"objects": 0.8
}

# === ESTADO ===
var is_generating: bool = false

func _ready():
	print("🌍 WorldManager melhorado iniciado")
	if not find_all_components():
		print("❌ Erro: Nem todos os componentes foram encontrados.")
		return
	
	setup_world_parameters()
	
	if not Engine.is_editor_hint():
		await get_tree().process_frame
		generate_complete_world()
		create_preset_interface()

func create_preset_interface():
	var preset_controller = preload("res://WorldPresetController.gd").new()
	add_child(preset_controller)
	print("✅ Interface de presets criada!")
	
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
	"""Configura o gerador de recursos COM LIMITES RÍGIDOS"""
	if not resource_generator:
		return
	
	# Configurações de densidade reduzidas
	set_property_if_exists(resource_generator, "rock_formation_density", resource_abundance * 0.1)
	set_property_if_exists(resource_generator, "min_formation_size", 6)
	set_property_if_exists(resource_generator, "max_formation_size", 20)
	set_property_if_exists(resource_generator, "map_border_margin", map_border_safety)
	
	apply_correct_transform(resource_generator, 1)

func configure_object_generator():
	"""Configura o gerador de objetos COM ESPAÇAMENTO"""
	if not object_generator:
		return
	
	# Configurações de densidade reduzidas
	set_property_if_exists(object_generator, "grass_density", vegetation_density * 0.08)
	set_property_if_exists(object_generator, "tree_density", vegetation_density * 0.04)
	set_property_if_exists(object_generator, "bush_density", vegetation_density * 0.02)
	
	# Configurações de espaçamento
	set_property_if_exists(object_generator, "resource_avoidance_radius", resource_object_separation)
	set_property_if_exists(object_generator, "object_spacing", object_spacing)
	
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

# === GERAÇÃO COORDENADA MELHORADA ===
func generate_complete_world():
	"""Gera o mundo completo com coordenação melhorada"""
	if is_generating:
		print("⚠️ Geração já em progresso...")
		return
	
	is_generating = true
	print("\n🚀 === INICIANDO GERAÇÃO COORDENADA MELHORADA ===")
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
	
	# === SEQUÊNCIA COORDENADA MELHORADA ===
	await generate_terrain_coordinated()
	await configure_shader_coordinated()
	await generate_resources_coordinated_safe()
	await generate_objects_coordinated_safe()
	
	var total_time = Time.get_ticks_msec() - start_time
	print("✅ === MUNDO GERADO COM SUCESSO ===")
	print("⏱️ Tempo total: ", total_time, "ms")
	print("🎯 Seed usado: ", world_seed)
	
	call_deferred("force_final_transforms")
	verify_generation_quality()
	analyze_world_improved()
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

func generate_resources_coordinated_safe() -> void:
	"""Gera recursos de forma coordenada COM LIMITES RÍGIDOS"""
	if not resource_generator:
		print("❌ ResourceGenerator não encontrado!")
		return
	
	print("🔧 Etapa 3/4: Gerando recursos com limites seguros...")
	apply_correct_transform(resource_generator, 1)
	
	# Garante que o resource generator tenha as configurações corretas
	configure_resource_generator()
	
	if resource_generator.has_method("generate"):
		resource_generator.generate()
	
	await get_tree().create_timer(GENERATION_DELAYS["resources"]).timeout
	
	# CRÍTICO: Mapeia posições ocupadas incluindo área de influência
	map_occupied_positions_with_influence()
	
	generation_state["resources_ready"] = true
	var resource_count = count_generated_items(resource_generator)
	print("✅ Recursos gerados: ", resource_count)

func map_occupied_positions_with_influence():
	"""Mapeia todas as posições ocupadas por recursos COM ÁREA DE INFLUÊNCIA"""
	print("📍 Mapeando posições ocupadas com área de influência...")
	
	occupied_positions.clear()
	
	if not resource_generator:
		return
	
	var resource_positions = []
	var direct_count = 0
	
	# Encontra todas as posições com recursos
	for x in range(map_size):
		for y in range(map_size):
			var pos = Vector2i(x, y)
			if resource_generator.get_cell_source_id(pos) != -1:
				resource_positions.append(pos)
				direct_count += 1
	
	print("🗺️ ", direct_count, " posições com recursos encontradas")
	
	# Marca área de influência ao redor de cada recurso
	var influence_count = 0
	
	for resource_pos in resource_positions:
		# Marca a posição do recurso
		occupied_positions[str(resource_pos)] = true
		
		# Marca área de influência ao redor
		for dx in range(-resource_object_separation, resource_object_separation + 1):
			for dy in range(-resource_object_separation, resource_object_separation + 1):
				var influence_pos = resource_pos + Vector2i(dx, dy)
				
				# Verifica se está dentro dos limites do mapa
				if (influence_pos.x >= 0 and influence_pos.x < map_size and 
					influence_pos.y >= 0 and influence_pos.y < map_size):
					
					var pos_key = str(influence_pos)
					if not pos_key in occupied_positions:
						occupied_positions[pos_key] = true
						influence_count += 1
	
	print("🛡️ ", influence_count, " posições adicionais bloqueadas por área de influência")
	print("📊 Total de posições bloqueadas: ", occupied_positions.size())

func generate_objects_coordinated_safe() -> void:
	"""Gera objetos evitando recursos COM ESPAÇAMENTO"""
	if not object_generator:
		print("❌ ObjectGenerator não encontrado!")
		return
	
	print("🌿 Etapa 4/4: Gerando objetos com espaçamento seguro...")
	apply_correct_transform(object_generator, 2)
	
	# Garante que o object generator tenha as configurações corretas
	configure_object_generator()
	
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

# === FUNÇÕES AUXILIARES MELHORADAS ===
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
	# Amostragem mais precisa
	for x in range(0, map_size, 2):
		for y in range(0, map_size, 2):
			if generator.get_cell_source_id(Vector2i(x, y)) != -1:
				count += 1
	
	return count * 4  # Multiplica pela amostragem

func verify_generation_quality():
	"""Verifica qualidade da geração"""
	print("\n🔍 === VERIFICAÇÃO DE QUALIDADE DA GERAÇÃO ===")
	
	if not resource_generator or not object_generator:
		print("❌ Não é possível verificar - geradores não encontrados")
		return
	
	var conflicts = 0
	var near_conflicts = 0
	var sample_positions = []
	
	# Verifica conflitos diretos e proximidade
	for x in range(0, map_size, 3):  # Amostragem
		for y in range(0, map_size, 3):
			var pos = Vector2i(x, y)
			
			var has_resource = resource_generator.get_cell_source_id(pos) != -1
			var has_object = object_generator.get_cell_source_id(pos) != -1
			
			# Conflito direto
			if has_resource and has_object:
				conflicts += 1
				if sample_positions.size() < 3:
					sample_positions.append({"type": "conflict", "pos": pos})
			
			# Verifica proximidade se há objeto
			elif has_object and not has_resource:
				var has_nearby_resource = false
				for dx in range(-resource_object_separation, resource_object_separation + 1):
					for dy in range(-resource_object_separation, resource_object_separation + 1):
						var check_pos = pos + Vector2i(dx, dy)
						if (check_pos.x >= 0 and check_pos.x < map_size and 
							check_pos.y >= 0 and check_pos.y < map_size):
							if resource_generator.get_cell_source_id(check_pos) != -1:
								has_nearby_resource = true
								break
					if has_nearby_resource:
						break
				
				if has_nearby_resource:
					near_conflicts += 1
					if sample_positions.size() < 5:
						sample_positions.append({"type": "near", "pos": pos})
	
	print("🎯 Resultado da verificação de qualidade:")
	print("  - Conflitos diretos: ", conflicts)
	print("  - Objetos próximos a recursos: ", near_conflicts)
	
	if conflicts == 0:
		print("✅ Nenhum conflito direto detectado!")
		if near_conflicts > 0:
			print("⚠️ ", near_conflicts, " objetos estão próximos a recursos (pode precisar aumentar separação)")
	else:
		print("❌ Conflitos encontrados:")
		for sample in sample_positions:
			if sample["type"] == "conflict":
				print("    ❌ Conflito direto em: ", sample["pos"])
	
	# Verifica se recursos estão dentro dos limites
	verify_resource_bounds()
	
	print("=== FIM VERIFICAÇÃO DE QUALIDADE ===\n")

func verify_resource_bounds():
	"""Verifica se todos os recursos estão dentro dos limites seguros"""
	print("🛡️ Verificando limites dos recursos...")
	
	if not resource_generator:
		return
	
	var out_of_bounds_count = 0
	var border_violations = []
	
	for x in range(map_size):
		for y in range(map_size):
			var pos = Vector2i(x, y)
			if resource_generator.get_cell_source_id(pos) != -1:
				# Verifica se está muito próximo das bordas
				if (x < map_border_safety or x >= map_size - map_border_safety or
					y < map_border_safety or y >= map_size - map_border_safety):
					out_of_bounds_count += 1
					if border_violations.size() < 5:
						border_violations.append(pos)
	
	if out_of_bounds_count == 0:
		print("✅ Todos os recursos respeitam a margem de segurança de ", map_border_safety, " tiles")
	else:
		print("⚠️ ", out_of_bounds_count, " recursos muito próximos das bordas:")
		for pos in border_violations:
			print("    ⚠️ Recurso próximo à borda: ", pos)

func analyze_world_improved():
	"""Análise melhorada do mundo gerado"""
	print("\n📊 === ANÁLISE AVANÇADA DO MUNDO ===")
	
	if not terrain_generator:
		print("❌ Não é possível analisar sem TerrainGenerator")
		return
	
	var biome_counts = {}
	var resource_count = count_generated_items(resource_generator) if resource_generator else 0
	var object_count = count_generated_items(object_generator) if object_generator else 0
	var total_tiles = map_size * map_size
	
	# Análise detalhada por biomas
	var sample_size = 64
	var step = max(1, map_size / sample_size)
	
	for x in range(0, map_size, step):
		for y in range(0, map_size, step):
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
	
	# Relatório de recursos e objetos com densidade
	var resource_density = float(resource_count) / float(total_tiles) * 100.0
	var object_density = float(object_count) / float(total_tiles) * 100.0
	
	print("🔧 Recursos: ", resource_count, " (", "%.3f" % resource_density, "% densidade)")
	print("🌿 Objetos: ", object_count, " (", "%.3f" % object_density, "% densidade)")
	
	# Análise de eficiência de espaço
	var blocked_tiles = occupied_positions.size()
	var blocked_percentage = float(blocked_tiles) / float(total_tiles) * 100.0
	print("🚫 Área bloqueada para objetos: ", blocked_tiles, " tiles (", "%.2f" % blocked_percentage, "%)")
	
	# Relatório de configurações usadas
	print("\n⚙️ Configurações aplicadas:")
	print("  - Separação recurso-objeto: ", resource_object_separation, " tiles")
	print("  - Espaçamento entre objetos: ", object_spacing, " tiles")
	print("  - Margem de segurança: ", map_border_safety, " tiles")
	print("  - Abundância de recursos: ", "%.1f" % (resource_abundance * 100), "%")
	print("  - Densidade de vegetação: ", "%.1f" % (vegetation_density * 100), "%")
	
	verify_layer_integrity_improved()
	print("=== FIM ANÁLISE AVANÇADA ===\n")

func verify_layer_integrity_improved():
	"""Verifica integridade das camadas com mais detalhes"""
	var issues = []
	var warnings = []
	
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
			warnings.append(name + " z-index inesperado: " + str(node.z_index) + " (esperado: " + str(expected_z) + ")")
		
		if not node.visible:
			warnings.append(name + " não está visível")
	
	if issues.size() == 0 and warnings.size() == 0:
		print("  ✅ Todas as camadas estão perfeitas")
	else:
		if issues.size() > 0:
			print("  ❌ Problemas críticos:")
			for issue in issues:
				print("    - ", issue)
		
		if warnings.size() > 0:
			print("  ⚠️ Avisos:")
			for warning in warnings:
				print("    - ", warning)

# === SISTEMA DE CORREÇÃO AUTOMÁTICA MELHORADO ===
func _process(_delta):
	if not Engine.is_editor_hint() and not is_generating:
		# Corrige automaticamente transformações incorretas
		var needs_correction = false
		
		for component in [terrain_generator, resource_generator, object_generator, shader_controller]:
			if component and (component.position != Vector2(0, 0) or component.scale != CORRECT_SCALE):
				component.position = Vector2(0, 0)
				component.scale = CORRECT_SCALE
				needs_correction = true
		
		# Log apenas quando houver correção (evita spam)
		if needs_correction:
			print("🔧 Transformações corrigidas automaticamente")

# === FUNÇÕES DE CONVENIÊNCIA E DEBUG ===
@export_group("Debug e Testes")
@export var test_resource_bounds: bool = false:
	set(value):
		if value:
			test_resource_bounds = false
			verify_resource_bounds()

@export var test_generation_quality: bool = false:
	set(value):
		if value:
			test_generation_quality = false
			verify_generation_quality()

@export var regenerate_only_objects: bool = false:
	set(value):
		if value:
			regenerate_only_objects = false
			regenerate_objects_only()

func regenerate_objects_only():
	"""Regenera apenas objetos (útil para testes)"""
	if object_generator and object_generator.has_method("clear"):
		print("🌿 Regenerando apenas objetos...")
		object_generator.clear()
		
		# Reconfigura
		configure_object_generator()
		
		# Passa posições ocupadas atualizadas
		if object_generator.has_method("set_occupied_positions"):
			map_occupied_positions_with_influence()
			object_generator.set_occupied_positions(occupied_positions)
		
		if object_generator.has_method("generate"):
			object_generator.generate()
		
		print("✅ Objetos regenerados")

func _on_generate_button_pressed():
	"""Compatibilidade com UI"""
	generate_complete_world()

func force_regenerate():
	"""Força regeneração completa"""
	clear_world()
	generate_complete_world()

# === SISTEMA DE CONFIGURAÇÃO DINÂMICA ===
@export_group("Configuração Dinâmica")
@export var apply_new_settings: bool = false:
	set(value):
		if value:
			apply_new_settings = false
			apply_dynamic_settings()

func apply_dynamic_settings():
	"""Aplica novas configurações sem regenerar terreno"""
	print("⚙️ Aplicando novas configurações...")
	
	# Reconfigura componentes
	configure_resource_generator()
	configure_object_generator()
	
	# Regenera apenas recursos e objetos
	if not is_generating:
		is_generating = true
		
		# Limpa apenas recursos e objetos
		if resource_generator and resource_generator.has_method("clear"):
			resource_generator.clear()
		if object_generator and object_generator.has_method("clear"):
			object_generator.clear()
		
		# Regenera
		await generate_resources_coordinated_safe()
		await generate_objects_coordinated_safe()
		
		is_generating = false
		print("✅ Novas configurações aplicadas")
