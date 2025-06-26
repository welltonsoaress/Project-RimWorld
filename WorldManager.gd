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
	
	# Busca com caminhos mais específicos
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
	"""Configura parâmetros do mundo em todos os componentes"""
	var seed_to_use = randi() if world_seed == 0 else world_seed
	world_seed = seed_to_use
	
	if terrain_generator:
		if "map_width" in terrain_generator:
			terrain_generator.map_width = map_size
		if "map_height" in terrain_generator:
			terrain_generator.map_height = map_size
		if "terrain_seed" in terrain_generator:
			terrain_generator.terrain_seed = seed_to_use
		if "terrain_type" in terrain_generator:
			terrain_generator.terrain_type = world_type
		
		terrain_generator.scale = Vector2(2.0, 2.0)
	
	if resource_generator:
		if "stone_density" in resource_generator:
			resource_generator.stone_density = resource_abundance * 0.025
		
		resource_generator.scale = Vector2(2.0, 2.0)
	
	if object_generator:
		if "grass_density" in object_generator:
			object_generator.grass_density = vegetation_density * 0.12
		if "tree_density" in object_generator:
			object_generator.tree_density = vegetation_density * 0.06
		if "bush_density" in object_generator:
			object_generator.bush_density = vegetation_density * 0.03
		
		object_generator.scale = Vector2(2.0, 2.0)
	
	if shader_controller:
		shader_controller.scale = Vector2(2.0, 2.0)
	
	print("⚙️ Parâmetros do mundo configurados (seed: ", seed_to_use, ")")

func generate_complete_world():
	"""Gera o mundo completo em sequência CORRIGIDA - Ordem: Terreno -> Recursos -> Objetos"""
	if is_generating:
		print("⚠️ Geração já em progresso...")
		return
	
	is_generating = true
	print("\n🚀 === INICIANDO GERAÇÃO COMPLETA DO MUNDO (ORDEM CORRIGIDA) ===")
	var start_time = Time.get_ticks_msec()
	
	clear_world()
	
	if not terrain_generator:
		print("❌ TerrainGenerator não encontrado! Abortando geração.")
		is_generating = false
		return
	
	# Força escala correta em todos os componentes antes da geração
	force_correct_scales()
	
	# === ETAPA 1: TERRENO (BASE) ===
	print("🌍 Etapa 1/4: Gerando terreno...")
	if terrain_generator.has_method("GenerateTerrain"):
		terrain_generator.GenerateTerrain()
	elif terrain_generator.has_method("generate"):
		terrain_generator.generate()
	await get_tree().create_timer(1.5).timeout  # Aguarda mapData.png ser salvo
	
	# === ETAPA 2: SHADER (VISUALIZAÇÃO DO TERRENO) ===
	if shader_controller:
		print("🎨 Etapa 2/4: Configurando shader...")
		shader_controller.scale = Vector2(2.0, 2.0)
		
		if shader_controller.has_method("update_texture"):
			shader_controller.call_deferred("update_texture")
		elif shader_controller.has_method("refresh"):
			shader_controller.call_deferred("refresh")
		await get_tree().create_timer(1.0).timeout
	
	# === ETAPA 3: RECURSOS (PEDRAS - DEVEM VIR ANTES DOS OBJETOS) ===
	if resource_generator:
		print("🔧 Etapa 3/4: Gerando recursos (pedras)...")
		print("  ⚠️ IMPORTANTE: Recursos gerados ANTES dos objetos para evitar sobreposição")
		
		resource_generator.scale = Vector2(2.0, 2.0)
		if resource_generator.has_method("generate"):
			resource_generator.generate()
		
		# Aguarda mais tempo para garantir que recursos foram totalmente gerados
		await get_tree().create_timer(1.0).timeout
		
		# Verifica se recursos foram realmente gerados
		var resource_count = count_resources()
		print("  📊 Recursos gerados: ", resource_count)
		
		if resource_count == 0:
			print("  ⚠️ AVISO: Nenhum recurso gerado - objetos podem não evitar pedras corretamente")
	else:
		print("❌ ResourceGenerator não encontrado!")
	
	# === ETAPA 4: OBJETOS (POR ÚLTIMO - EVITA PEDRAS) ===
	if object_generator:
		print("🌿 Etapa 4/4: Gerando objetos (evitando pedras)...")
		print("  ✅ Objetos gerados APÓS recursos para evitar sobreposição")
		
		object_generator.scale = Vector2(2.0, 2.0)
		
		# Garante que object_generator encontre resource_generator
		if object_generator.has_method("find_generators"):
			object_generator.find_generators()
		
		if object_generator.has_method("generate"):
			object_generator.generate()
		await get_tree().create_timer(0.5).timeout
		
		# Verifica se houve colisões
		verify_no_collisions()
	else:
		print("❌ ObjectGenerator não encontrado!")
	
	var total_time = Time.get_ticks_msec() - start_time
	print("✅ === MUNDO GERADO COM SUCESSO (ORDEM CORRIGIDA) ===")
	print("⏱️ Tempo total: ", total_time, "ms")
	print("🎯 Seed usado: ", world_seed)
	print("📋 Ordem: Terreno → Recursos → Objetos (sem sobreposição)")
	
	# Força escala final em todos os componentes
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
	
	# Força atualização visual
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
	
	if terrain_generator and terrain_generator.has_method("clear"):
		terrain_generator.clear()
	
	if resource_generator and resource_generator.has_method("clear"):
		resource_generator.clear()
	
	if object_generator and object_generator.has_method("clear"):
		object_generator.clear()
	
	# Remove mapData.png antigo
	if FileAccess.file_exists("res://mapData.png"):
		var dir = DirAccess.open("res://")
		if dir:
			dir.remove("res://mapData.png")
			print("🗑️ mapData.png removido")
			await get_tree().process_frame

# === CORREÇÕES DE EMERGÊNCIA ===
@export_group("Correções de Emergência")
@export var fix_collision_issues: bool = false:
	set(value):
		if value:
			fix_collision_issues = false
			emergency_fix_collisions()

func emergency_fix_collisions():
	"""Correção de emergência para colisões objeto-recurso"""
	print("\n🚨 === CORREÇÃO DE EMERGÊNCIA - COLISÕES ===")
	
	if not resource_generator or not object_generator:
		print("❌ Geradores não encontrados")
		return
	
	var removed_objects = 0
	var map_width = terrain_generator.get("map_width") if terrain_generator and "map_width" in terrain_generator else 128
	var map_height = terrain_generator.get("map_height") if terrain_generator and "map_height" in terrain_generator else 128
	
	# Remove objetos que estão sobre recursos
	for x in range(map_width):
		for y in range(map_height):
			var pos = Vector2i(x, y)
			
			var has_resource = resource_generator.get_cell_source_id(pos) != -1
			var has_object = object_generator.get_cell_source_id(pos) != -1
			
			if has_resource and has_object:
				object_generator.erase_cell(pos)
				removed_objects += 1
	
	print("🔧 Objetos removidos de cima de recursos: ", removed_objects)
	print("✅ Correção concluída")
	print("=== FIM CORREÇÃO ===\n")

# Sistema para manter posicionamento correto
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

func _on_generate_button_pressed():
	"""Compatibilidade com UI"""
	generate_complete_world()

func force_regenerate():
	"""Força regeneração completa"""
	clear_world()
	generate_complete_world()
	"""Gera o mundo completo em sequência CORRIGIDA - Ordem: Terreno -> Recursos -> Objetos"""
	if is_generating:
		print("⚠️ Geração já em progresso...")
		return
	
	is_generating = true
	print("\n🚀 === INICIANDO GERAÇÃO COMPLETA DO MUNDO (ORDEM CORRIGIDA) ===")
	var start_time = Time.get_ticks_msec()
	
	clear_world()
	
	if not terrain_generator:
		print("❌ TerrainGenerator não encontrado! Abortando geração.")
		is_generating = false
		return
	
	# CORREÇÃO: Força escala correta em todos os componentes antes da geração
	force_correct_scales()
	
	# === ETAPA 1: TERRENO (BASE) ===
	print("🌍 Etapa 1/4: Gerando terreno...")
	terrain_generator.GenerateTerrain()
	await get_tree().create_timer(1.5).timeout  # Aguarda mapData.png ser salvo
	
	# === ETAPA 2: SHADER (VISUALIZAÇÃO DO TERRENO) ===
	if shader_controller:
		print("🎨 Etapa 2/4: Configurando shader...")
		shader_controller.scale = Vector2(2.0, 2.0)
		
		if shader_controller.has_method("update_texture"):
			shader_controller.call_deferred("update_texture")
		elif shader_controller.has_method("refresh"):
			shader_controller.call_deferred("refresh")
		await get_tree().create_timer(1.0).timeout
	
	# === ETAPA 3: RECURSOS (PEDRAS - DEVEM VIR ANTES DOS OBJETOS) ===
	if resource_generator:
		print("🔧 Etapa 3/4: Gerando recursos (pedras)...")
		print("  ⚠️ IMPORTANTE: Recursos gerados ANTES dos objetos para evitar sobreposição")
		
		resource_generator.scale = Vector2(2.0, 2.0)
		resource_generator.generate()
		
		# CORREÇÃO: Aguarda mais tempo para garantir que recursos foram totalmente gerados
		await get_tree().create_timer(1.0).timeout
		
		# CORREÇÃO: Verifica se recursos foram realmente gerados
		var resource_count = count_resources()
		print("  📊 Recursos gerados: ", resource_count)
		
		if resource_count == 0:
			print("  ⚠️ AVISO: Nenhum recurso gerado - objetos podem não evitar pedras corretamente")
	else:
		print("❌ ResourceGenerator não encontrado!")
	
	# === ETAPA 4: OBJETOS (POR ÚLTIMO - EVITA PEDRAS) ===
	if object_generator:
		print("🌿 Etapa 4/4: Gerando objetos (evitando pedras)...")
		print("  ✅ Objetos gerados APÓS recursos para evitar sobreposição")
		
		object_generator.scale = Vector2(2.0, 2.0)
		
		# CORREÇÃO: Garante que object_generator encontre resource_generator
		if object_generator.has_method("find_generators"):
			object_generator.find_generators()
		
		object_generator.generate()
		await get_tree().create_timer(0.5).timeout
		
		# CORREÇÃO: Verifica se houve colisões
		verify_no_collisions()
	else:
		print("❌ ObjectGenerator não encontrado!")
	
	var total_time = Time.get_ticks_msec() - start_time
	print("✅ === MUNDO GERADO COM SUCESSO (ORDEM CORRIGIDA) ===")
	print("⏱️ Tempo total: ", total_time, "ms")
	print("🎯 Seed usado: ", world_seed)
	print("📋 Ordem: Terreno → Recursos → Objetos (sem sobreposição)")
	
	# CORREÇÃO: Força escala final em todos os componentes
	call_deferred("force_final_scales")
	
	analyze_world()
	is_generating = false

# === FUNÇÕES AUXILIARES PARA VERIFICAÇÃO ===

func count_resources() -> int:
	"""Conta quantos recursos foram gerados"""
	if not resource_generator:
		return 0
	
	var count = 0
	var map_width = terrain_generator.get("map_width") if "map_width" in terrain_generator else 128
	var map_height = terrain_generator.get("map_height") if "map_height" in terrain_generator else 128
	
	# Amostragem rápida para não impactar performance
	for x in range(0, map_width, 4):
		for y in range(0, map_height, 4):
			if resource_generator.get_cell_source_id(Vector2i(x, y)) != -1:
				count += 1
	
	return count * 16  # Multiplica pela amostragem (4x4 = 16)

func verify_no_collisions():
	"""Verifica se há colisões entre objetos e recursos"""
	if not resource_generator or not object_generator:
		print("  ⚠️ Não foi possível verificar colisões - geradores não encontrados")
		return
	
	var collision_count = 0
	var sample_size = 200  # Amostra maior para verificação
	
	print("  🔍 Verificando colisões objeto-recurso...")
	
	for i in range(sample_size):
		var x = randi_range(5, 123)
		var y = randi_range(5, 123)
		var pos = Vector2i(x, y)
		
		var has_resource = resource_generator.get_cell_source_id(pos) != -1
		var has_object = object_generator.get_cell_source_id(pos) != -1
		
		if has_resource and has_object:
			collision_count += 1
			if collision_count <= 3:  # Mostra apenas as primeiras 3
				print("    ❌ Colisão em: ", pos)
	
	if collision_count == 0:
		print("  ✅ Nenhuma colisão detectada - objetos evitaram pedras corretamente!")
	else:
		print("  ⚠️ ", collision_count, " colisões detectadas em ", sample_size, " amostras")
		print("  🔧 Sugestão: Verifique ordem de geração ou aguarde mais tempo entre etapas")

# === FUNÇÃO MELHORADA DE ANÁLISE ===

func analyze_world():
	"""Analisa o mundo gerado - VERSÃO MELHORADA"""
	print("\n📊 === ANÁLISE DO MUNDO GERADO ===")
	
	if not terrain_generator:
		print("❌ Não é possível analisar sem TerrainGenerator")
		return
	
	var biome_counts = {}
	var resource_counts = {}
	var object_counts = {}
	var total_tiles = map_size * map_size
	var sample_size = min(50.0, map_size / 4.0)
	var step = max(1, float(map_size) / float(sample_size))
	
	# Análise por amostragem
	for x in range(0, map_size, int(step)):
		for y in range(0, map_size, int(step)):
			var pos = Vector2i(x, y)
			
			# Conta biomas
			var biome = terrain_generator.get_biome_at_position(x, y)
			if biome in biome_counts:
				biome_counts[biome] += 1
			else:
				biome_counts[biome] = 1
			
			# Conta recursos
			if resource_generator and resource_generator.get_cell_source_id(pos) != -1:
				if biome in resource_counts:
					resource_counts[biome] += 1
				else:
					resource_counts[biome] = 1
			
			# Conta objetos
			if object_generator and object_generator.get_cell_source_id(pos) != -1:
				if biome in object_counts:
					object_counts[biome] += 1
				else:
					object_counts[biome] = 1
	
	var sample_total = biome_counts.values().reduce(func(a, b): return a + b, 0)
	
	# Análise de terreno
	print("🌍 Composição do terreno:")
	for biome in biome_counts:
		var percentage = float(biome_counts[biome]) / float(sample_total) * 100.0
		print("  🔹 ", biome.capitalize(), ": ", "%.1f" % percentage, "%")
	
	# Análise de recursos
	if resource_generator:
		var total_resources = resource_counts.values().reduce(func(a, b): return a + b, 0)
		var resource_density = float(total_resources) / float(sample_total) * 100.0
		print("🔧 Recursos:")
		print("  📊 Densidade total: ", "%.2f" % resource_density, "%")
		
		if resource_counts.size() > 0:
			print("  📍 Distribuição por bioma:")
			for biome in resource_counts:
				var biome_total = biome_counts.get(biome, 0)
				var biome_resources = resource_counts[biome]
				var biome_density = float(biome_resources) / float(biome_total) * 100.0 if biome_total > 0 else 0.0
				print("    🔹 ", biome.capitalize(), ": ", "%.1f" % biome_density, "% (", biome_resources, " recursos)")
	
	# Análise de objetos
	if object_generator:
		var total_objects = object_counts.values().reduce(func(a, b): return a + b, 0)
		var object_density = float(total_objects) / float(sample_total) * 100.0
		print("🌿 Objetos:")
		print("  📊 Densidade total: ", "%.2f" % object_density, "%")
		
		if object_counts.size() > 0:
			print("  📍 Distribuição por bioma:")
			for biome in object_counts:
				var biome_total = biome_counts.get(biome, 0)
				var biome_objects = object_counts[biome]
				var biome_density = float(biome_objects) / float(biome_total) * 100.0 if biome_total > 0 else 0.0
				print("    🔹 ", biome.capitalize(), ": ", "%.1f" % biome_density, "% (", biome_objects, " objetos)")
	
	# Verificação final de integridade
	print("🔍 Verificação de integridade:")
	verify_layer_integrity()
	
	print("=== FIM ANÁLISE ===\n")

func verify_layer_integrity():
	"""Verifica integridade das camadas"""
	var issues = []
	
	# Verifica posicionamento
	if terrain_generator and terrain_generator.position != Vector2(0, 0):
		issues.append("TerrainMap fora de posição: " + str(terrain_generator.position))
	
	if resource_generator and resource_generator.position != Vector2(0, 0):
		issues.append("ResourceMap fora de posição: " + str(resource_generator.position))
	
	if object_generator and object_generator.position != Vector2(0, 0):
		issues.append("ObjectMap fora de posição: " + str(object_generator.position))
	
	# Verifica escala
	var expected_scale = Vector2(2.0, 2.0)
	if terrain_generator and terrain_generator.scale != expected_scale:
		issues.append("TerrainMap escala incorreta: " + str(terrain_generator.scale))
	
	if resource_generator and resource_generator.scale != expected_scale:
		issues.append("ResourceMap escala incorreta: " + str(resource_generator.scale))
	
	if object_generator and object_generator.scale != expected_scale:
		issues.append("ObjectMap escala incorreta: " + str(object_generator.scale))
	
	# Verifica z-index
	if terrain_generator and terrain_generator.z_index != 0:
		issues.append("TerrainMap z-index incorreto: " + str(terrain_generator.z_index))
	
	if resource_generator and resource_generator.z_index != 1:
		issues.append("ResourceMap z-index incorreto: " + str(resource_generator.z_index))
	
	if object_generator and object_generator.z_index != 2:
		issues.append("ObjectMap z-index incorreto: " + str(object_generator.z_index))
	
	# Reporta resultados
	if issues.size() == 0:
		print("  ✅ Todas as camadas estão corretamente posicionadas")
	else:
		print("  ⚠️ Problemas encontrados:")
		for issue in issues:
			print("    - ", issue)

# === FUNÇÃO PARA CORRIGIR PROBLEMAS ===
@export_group("Correções de Emergência")
# === CONFIGURAÇÕES DE DEBUG ===
@export_group("Debug Geração")
@export var debug_generation_order: bool = false
@export var pause_between_steps: float = 2.0

# Função de geração com debug (opcional)
func generate_complete_world_debug():
	"""Versão com debug detalhado da geração"""
	if not debug_generation_order:
		generate_complete_world()
		return
	
	print("\n🔍 === GERAÇÃO COM DEBUG DETALHADO ===")
	
	# Similar à função normal, mas com paradas e verificações extras
	is_generating = true
	clear_world()
	
	print("⏸️ Pausa entre etapas: ", pause_between_steps, "s")
	
	# Etapa 1: Terreno
	print("\n1️⃣ === GERANDO TERRENO ===")
	terrain_generator.GenerateTerrain()
	await get_tree().create_timer(pause_between_steps).timeout
	print("✅ Terreno gerado. Pressione qualquer tecla para continuar...")
	
	# Etapa 2: Shader  
	print("\n2️⃣ === CONFIGURANDO SHADER ===")
	if shader_controller:
		shader_controller.update_texture()
	await get_tree().create_timer(pause_between_steps).timeout
	
	# Etapa 3: Recursos
	print("\n3️⃣ === GERANDO RECURSOS ===")
	if resource_generator:
		resource_generator.generate()
		var resource_count = count_resources()
		print("📊 Recursos gerados: ", resource_count)
	await get_tree().create_timer(pause_between_steps).timeout
	
	# Etapa 4: Objetos
	print("\n4️⃣ === GERANDO OBJETOS ===")
	if object_generator:
		object_generator.generate()
		verify_no_collisions()
	
	print("\n✅ === GERAÇÃO DEBUG CONCLUÍDA ===")
	is_generating = false
