@tool
extends Node2D

# === REFERÊNCIAS ===
var world_manager: Node2D
var preset_controller: Control
var camera: Camera2D

# === CONFIGURAÇÕES ===
@export_group("Interface")
@export var show_preset_ui: bool = true:
	set(value):
		show_preset_ui = value
		if preset_controller:
			preset_controller.visible = value

@export var ui_position: Vector2 = Vector2(20, 20):
	set(value):
		ui_position = value
		if preset_controller:
			preset_controller.position = value

@export_group("Atalhos de Teclado")
@export var toggle_ui_key: Key = KEY_TAB
@export var quick_generate_key: Key = KEY_G
@export var random_preset_key: Key = KEY_R

# === ESTADO ===
var is_setup_complete: bool = false
var preset_names: Array = []

func _ready():
	print("🚀 Iniciando sistema completo com predefinições...")
	
	# Adiciona ao grupo para facilitar busca
	add_to_group("main")
	add_to_group("world_manager")
	
	setup_system()
	
	if not Engine.is_editor_hint():
		await get_tree().process_frame
		create_preset_ui()
		setup_camera_controls()
		show_welcome_message()

func setup_system():
	"""Configuração inicial do sistema"""
	print("⚙️ Configurando sistema base...")
	
	# Busca o WorldManager existente ou usa este nó como WorldManager
	world_manager = self
	
	# Garante que componentes tenham grupos corretos
	ensure_component_groups()
	
	# Configura preset names para acesso rápido
	preset_names = [
		"🏰 Balanced Empire",
		"🗡️ Harsh Survival", 
		"🌿 Peaceful Explorer",
		"⚔️ Strategic Warfare",
		"🏜️ Desert Wasteland",
		"🏖️ Paradise Island"
	]
	
	is_setup_complete = true

func ensure_component_groups():
	"""Garante que componentes estejam nos grupos corretos"""
	# Busca componentes existentes e adiciona aos grupos
	var terrain = find_node_recursive(self, "TerrainMap")
	if terrain:
		terrain.add_to_group("terrain")
		print("✅ TerrainMap adicionado ao grupo 'terrain'")
	
	var resources = find_node_recursive(self, "ResourceMap")
	if resources:
		resources.add_to_group("resources")
		print("✅ ResourceMap adicionado ao grupo 'resources'")
	
	var objects = find_node_recursive(self, "ObjectMap")
	if objects:
		objects.add_to_group("objects")
		print("✅ ObjectMap adicionado ao grupo 'objects'")
	
	var shader = find_node_recursive(self, "ShaderTerrain")
	if shader:
		shader.add_to_group("shader")
		print("✅ ShaderController adicionado ao grupo 'shader'")

func find_node_recursive(node: Node, target_name: String) -> Node:
	"""Busca recursiva por nome"""
	if node.name == target_name:
		return node
	
	for child in node.get_children():
		var result = find_node_recursive(child, target_name)
		if result:
			return result
	
	return null

func create_preset_ui():
	"""Cria a interface de predefinições"""
	print("🎨 Criando interface de predefinições...")
	
	# Carrega a cena da UI ou cria programaticamente
	var preset_scene = preload("res://PresetUI.tscn") if ResourceLoader.exists("res://PresetUI.tscn") else null
	
	if preset_scene:
		preset_controller = preset_scene.instantiate()
		add_child(preset_controller)
		print("✅ Interface carregada da cena PresetUI.tscn")
	else:
		# Cria interface programaticamente se cena não existir
		preset_controller = preload("res://WorldPresetController.gd").new()
		add_child(preset_controller)
		print("✅ Interface criada programaticamente")
	
	# Configura posição e visibilidade
	preset_controller.position = ui_position
	preset_controller.visible = show_preset_ui
	
	# Conecta sinais customizados se necessário
	setup_preset_callbacks()

func setup_preset_callbacks():
	"""Configura callbacks customizados para a interface"""
	if not preset_controller:
		return
	
	# Exemplo de callback customizado quando preset é aplicado
	if preset_controller.has_signal("preset_applied"):
		preset_controller.preset_applied.connect(_on_preset_applied)

func setup_camera_controls():
	"""Configura controles de câmera"""
	camera = get_node_or_null("Camera2D")
	if not camera:
		# Cria câmera se não existir
		camera = Camera2D.new()
		camera.name = "Camera2D"
		add_child(camera)
		
		# Configura script de controle de câmera
		var camera_script = preload("res://camera_2d.gd") if ResourceLoader.exists("res://camera_2d.gd") else null
		if camera_script:
			camera.set_script(camera_script)
	
	print("✅ Controles de câmera configurados")

func show_welcome_message():
	"""Mostra mensagem de boas-vindas"""
	print("\n🌍 === SISTEMA DE GERAÇÃO PROCEDURAL ===")
	print("📋 Controles disponíveis:")
	print("  🎯 TAB - Toggle da interface de predefinições")
	print("  🚀 G - Geração rápida com preset aleatório")
	print("  🎲 R - Preset aleatório")
	print("  📊 F1 - Debug completo")
	print("  🔧 F2 - Toggle shader/tiles")
	print("=========================================\n")

# === INPUT HANDLING ===

func _input(event: InputEvent):
	if not Engine.is_editor_hint() and is_setup_complete:
		handle_keyboard_shortcuts(event)

func handle_keyboard_shortcuts(event: InputEvent):
	"""Gerencia atalhos de teclado"""
	if event is InputEventKey and event.pressed:
		match event.keycode:
			toggle_ui_key:  # TAB
				toggle_preset_ui()
			
			quick_generate_key:  # G
				quick_generate_random()
			
			random_preset_key:  # R
				apply_random_preset()
			
			KEY_F1:  # Debug
				debug_system()
			
			KEY_F2:  # Toggle visualização
				toggle_visualization_mode()
			
			KEY_F3:  # Exportar screenshot
				export_screenshot()

func toggle_preset_ui():
	"""Toggle da interface de predefinições"""
	if preset_controller:
		preset_controller.visible = !preset_controller.visible
		print("🎨 Interface de predefinições: ", "Visível" if preset_controller.visible else "Oculta")

func quick_generate_random():
	"""Geração rápida com preset aleatório"""
	if not preset_controller:
		print("❌ Interface de predefinições não encontrada")
		return
	
	print("🚀 Geração rápida com preset aleatório...")
	
	# Seleciona preset aleatório
	var random_preset = preset_names[randi() % preset_names.size()]
	
	# Seleciona tamanho aleatório
	var sizes = ["small", "medium", "large"]
	var random_size = sizes[randi() % sizes.size()]
	
	# Gera seed aleatório
	var random_seed = randi() % 999999999
	
	print("  🎯 Preset: ", random_preset)
	print("  📏 Tamanho: ", random_size)
	print("  🌱 Seed: ", random_seed)
	
	# Aplica via interface
	if preset_controller.has_method("quick_generate"):
		preset_controller.quick_generate(random_preset, random_size)

func apply_random_preset():
	"""Aplica preset aleatório sem gerar"""
	if not preset_controller:
		return
	
	var random_preset = preset_names[randi() % preset_names.size()]
	print("🎲 Aplicando preset aleatório: ", random_preset)
	
	if preset_controller.has_method("load_preset_by_name"):
		preset_controller.load_preset_by_name(random_preset)

func debug_system():
	"""Debug completo do sistema"""
	print("\n🐛 === DEBUG COMPLETO DO SISTEMA ===")
	
	# Debug da interface
	if preset_controller and preset_controller.has_method("_on_debug_pressed"):
		preset_controller._on_debug_pressed()
	
	# Debug do sistema base
	debug_base_system()
	
	# Debug dos componentes
	debug_components()
	
	print("=== FIM DEBUG COMPLETO ===\n")

func debug_base_system():
	"""Debug do sistema base"""
	print("🌍 Sistema Base:")
	print("  - WorldManager: ", world_manager != null)
	print("  - PresetController: ", preset_controller != null)
	print("  - Camera: ", camera != null)
	print("  - Setup Complete: ", is_setup_complete)

func debug_components():
	"""Debug dos componentes do sistema"""
	print("🔧 Componentes:")
	
	var terrain = get_tree().get_nodes_in_group("terrain")
	var resources = get_tree().get_nodes_in_group("resources")
	var objects = get_tree().get_nodes_in_group("objects")
	var shader = get_tree().get_nodes_in_group("shader")
	
	print("  - Terrain: ", terrain.size(), " nós")
	print("  - Resources: ", resources.size(), " nós")
	print("  - Objects: ", objects.size(), " nós")
	print("  - Shader: ", shader.size(), " nós")
	
	# Chama debug específico se DebugHelper existir
	var debug_helper = find_node_recursive(self, "DebugHelper")
	if debug_helper and debug_helper.has_method("debug_all_tiles"):
		debug_helper.debug_all_tiles()

func toggle_visualization_mode():
	"""Alterna entre modos de visualização"""
	if not preset_controller:
		return
	
	# Toggle shader
	if preset_controller.has_method("_on_show_shader_pressed"):
		preset_controller._on_show_shader_pressed()
	
	print("🔧 Modo de visualização alternado")

func export_screenshot():
	"""Exporta screenshot do mundo atual"""
	print("📷 Exportando screenshot...")
	
	# Captura screenshot
	var image = get_viewport().get_texture().get_image()
	var timestamp = Time.get_datetime_string_from_system().replace(":", "-")
	var filename = "res://world_screenshot_" + timestamp + ".png"
	
	var error = image.save_png(filename)
	if error == OK:
		print("✅ Screenshot salvo: ", filename)
	else:
		print("❌ Erro ao salvar screenshot: ", error)

# === CALLBACKS CUSTOMIZADOS ===

func _on_preset_applied(preset_name: String):
	"""Callback quando preset é aplicado"""
	print("🎯 Preset aplicado via callback: ", preset_name)
	
	# Aqui você pode adicionar lógica customizada
	# como atualizar UI externa, salvar preferências, etc.

# === INTEGRAÇÃO COM WORLDMANAGER ===

# Implementa os métodos necessários que o PresetController espera
func generate_complete_world():
	"""Método de geração compatível com WorldManager original"""
	print("🌍 Gerando mundo via integração...")
	
	# Chama os métodos dos componentes em sequência
	var terrain = get_tree().get_first_node_in_group("terrain")
	var resources = get_tree().get_first_node_in_group("resources")
	var objects = get_tree().get_first_node_in_group("objects")
	var shader = get_tree().get_first_node_in_group("shader")
	
	if terrain:
		# Gera terreno
		if terrain.has_method("GenerateTerrain"):
			terrain.GenerateTerrain()
		elif terrain.has_method("generate"):
			terrain.generate()
		
		await get_tree().create_timer(2.0).timeout
	
	if shader:
		# Atualiza shader
		if shader.has_method("update_texture"):
			shader.update_texture()
		
		await get_tree().create_timer(1.0).timeout
	
	if resources:
		# Gera recursos
		if resources.has_method("generate"):
			resources.generate()
		
		await get_tree().create_timer(1.5).timeout
	
	if objects:
		# Gera objetos
		if objects.has_method("generate"):
			objects.generate()
		
		await get_tree().create_timer(1.0).timeout
	
	print("✅ Geração completa finalizada!")

func clear_world():
	"""Limpa todos os componentes"""
	print("🧹 Limpando mundo...")
	
	var components = []
	components.append_array(get_tree().get_nodes_in_group("terrain"))
	components.append_array(get_tree().get_nodes_in_group("resources"))
	components.append_array(get_tree().get_nodes_in_group("objects"))
	
	for component in components:
		if component and component.has_method("clear"):
			component.clear()
	
	print("✅ Mundo limpo")

func regenerate_only_objects():
	"""Regenera apenas objetos"""
	print("🌿 Regenerando apenas objetos...")
	
	var objects = get_tree().get_first_node_in_group("objects")
	if objects:
		if objects.has_method("clear"):
			objects.clear()
		
		await get_tree().create_timer(0.5).timeout
		
		if objects.has_method("generate"):
			objects.generate()
	
	print("✅ Objetos regenerados")

func verify_generation_quality():
	"""Verifica qualidade da geração"""
	print("🔍 Verificando qualidade da geração...")
	
	var terrain = get_tree().get_first_node_in_group("terrain")
	var resources = get_tree().get_first_node_in_group("resources")
	var objects = get_tree().get_first_node_in_group("objects")
	
	if not terrain or not resources or not objects:
		print("❌ Nem todos os componentes estão disponíveis")
		return
	
	# Verifica colisões entre recursos e objetos
	var conflicts = 0
	var sample_size = 50
	
	for i in range(sample_size):
		var x = randi() % 128
		var y = randi() % 128
		var pos = Vector2i(x, y)
		
		var has_resource = resources.get_cell_source_id(pos) != -1
		var has_object = objects.get_cell_source_id(pos) != -1
		
		if has_resource and has_object:
			conflicts += 1
	
	var conflict_percentage = float(conflicts) / float(sample_size) * 100.0
	
	print("📊 Resultado da verificação:")
	print("  - Amostras testadas: ", sample_size)
	print("  - Conflitos encontrados: ", conflicts)
	print("  - Porcentagem de conflitos: ", "%.2f" % conflict_percentage, "%")
	
	if conflict_percentage < 5.0:
		print("✅ Qualidade boa - Poucos conflitos")
	elif conflict_percentage < 15.0:
		print("⚠️ Qualidade média - Alguns conflitos")
	else:
		print("❌ Qualidade ruim - Muitos conflitos")

# === UTILITÁRIOS PARA DESENVOLVEDORES ===

func get_current_world_stats() -> Dictionary:
	"""Retorna estatísticas do mundo atual"""
	var stats = {
		"terrain_tiles": 0,
		"resource_tiles": 0,
		"object_tiles": 0,
		"biome_distribution": {},
		"map_size": Vector2i(128, 128)
	}
	
	var terrain = get_tree().get_first_node_in_group("terrain")
	var resources = get_tree().get_first_node_in_group("resources")
	var objects = get_tree().get_first_node_in_group("objects")
	
	# Conta tiles (amostragem)
	var sample_step = 4
	for x in range(0, 128, sample_step):
		for y in range(0, 128, sample_step):
			var pos = Vector2i(x, y)
			
			if terrain and terrain.get_cell_source_id(pos) != -1:
				stats["terrain_tiles"] += 1
			
			if resources and resources.get_cell_source_id(pos) != -1:
				stats["resource_tiles"] += 1
			
			if objects and objects.get_cell_source_id(pos) != -1:
				stats["object_tiles"] += 1
	
	# Multiplica pela amostragem
	var multiplier = sample_step * sample_step
	stats["terrain_tiles"] *= multiplier
	stats["resource_tiles"] *= multiplier
	stats["object_tiles"] *= multiplier
	
	return stats

func save_world_preset(preset_name: String, description: String = ""):
	"""Salva configuração atual como novo preset"""
	if not preset_controller:
		print("❌ PresetController não encontrado")
		return
	
	var config = {}
	if preset_controller.has_method("export_current_config"):
		config = preset_controller.export_current_config()
	
	# Salva em arquivo separado
	var custom_presets_file = "res://custom_presets.json"
	var custom_presets = {}
	
	# Carrega presets existentes
	if FileAccess.file_exists(custom_presets_file):
		var file = FileAccess.open(custom_presets_file, FileAccess.READ)
		if file:
			var json_text = file.get_as_text()
			file.close()
			var json = JSON.new()
			var parse_result = json.parse(json_text)
			if parse_result == OK:
				custom_presets = json.data
	
	# Adiciona novo preset
	custom_presets[preset_name] = {
		"name": preset_name,
		"description": description,
		"created_at": Time.get_datetime_string_from_system(),
		"config": config
	}
	
	# Salva arquivo atualizado
	var file = FileAccess.open(custom_presets_file, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(custom_presets, "\t"))
		file.close()
		print("✅ Preset customizado salvo: ", preset_name)
	else:
		print("❌ Erro ao salvar preset customizado")

func load_custom_preset(preset_name: String) -> bool:
	"""Carrega preset customizado"""
	var custom_presets_file = "res://custom_presets.json"
	
	if not FileAccess.file_exists(custom_presets_file):
		print("❌ Arquivo de presets customizados não encontrado")
		return false
	
	var file = FileAccess.open(custom_presets_file, FileAccess.READ)
	if not file:
		print("❌ Erro ao abrir arquivo de presets")
		return false
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	if parse_result != OK:
		print("❌ Erro ao fazer parse do JSON")
		return false
	
	var custom_presets = json.data
	if not preset_name in custom_presets:
		print("❌ Preset não encontrado: ", preset_name)
		return false
	
	var preset_data = custom_presets[preset_name]
	print("✅ Carregando preset customizado: ", preset_name)
	
	# Aplica configuração via PresetController
	if preset_controller and preset_controller.has_method("apply_preset"):
		preset_controller.apply_preset(preset_data)
		return true
	
	return false

# === EXEMPLO DE AUTOMAÇÃO ===

func generate_world_series(count: int = 5):
	"""Gera uma série de mundos para comparação"""
	print("🔄 Gerando série de ", count, " mundos...")
	
	for i in range(count):
		print("🌍 Gerando mundo ", i + 1, "/", count)
		
		# Aplica preset aleatório
		apply_random_preset()
		await get_tree().create_timer(1.0).timeout
		
		# Gera mundo
		generate_complete_world()
		await get_tree().create_timer(8.0).timeout  # Aguarda geração completa
		
		# Exporta screenshot
		export_screenshot()
		await get_tree().create_timer(1.0).timeout
		
		# Salva estatísticas
		var stats = get_current_world_stats()
		print("  📊 Stats: ", stats)
	
	print("✅ Série de mundos completa!")

# === EXEMPLO DE USO PROGRAMÁTICO ===

func example_programmatic_usage():
	"""Exemplo de como usar o sistema programaticamente"""
	print("📋 Exemplo de uso programático:")
	
	# 1. Aplicar preset específico
	if preset_controller.has_method("load_preset_by_name"):
		preset_controller.load_preset_by_name("🏰 Balanced Empire")
	
	await get_tree().create_timer(1.0).timeout
	
	# 2. Customizar configurações específicas
	var terrain = get_tree().get_first_node_in_group("terrain")
	if terrain:
		terrain.set("map_width", 256)
		terrain.set("map_height", 256)
	
	# 3. Gerar mundo
	generate_complete_world()
	
	await get_tree().create_timer(5.0).timeout
	
	# 4. Verificar qualidade
	verify_generation_quality()
	
	# 5. Salvar como preset customizado
	save_world_preset("Meu Preset Customizado", "Gerado programaticamente")
	
	print("✅ Exemplo programático completo!")
