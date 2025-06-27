@tool
class_name WorldPresetController
extends Control

# === REFERÊNCIAS DA UI ===
@onready var preset_dropdown: OptionButton = $MainPanel/ScrollContainer/VBoxContainer/PresetSection/PresetDropdown
@onready var size_dropdown: OptionButton = $MainPanel/ScrollContainer/VBoxContainer/BasicSettings/SizeContainer/SizeDropdown
@onready var terrain_dropdown: OptionButton = $MainPanel/ScrollContainer/VBoxContainer/BasicSettings/TerrainContainer/TerrainDropdown
@onready var seed_input: SpinBox = $MainPanel/ScrollContainer/VBoxContainer/BasicSettings/SeedContainer/SeedInput
@onready var random_seed_button: Button = $MainPanel/ScrollContainer/VBoxContainer/BasicSettings/SeedContainer/RandomSeedButton
@onready var generate_button: Button = $MainPanel/ScrollContainer/VBoxContainer/GenerationControls/GenerateButton
@onready var status_label: Label = $MainPanel/ScrollContainer/VBoxContainer/GenerationControls/StatusLabel
@onready var values_display: RichTextLabel = $MainPanel/ScrollContainer/VBoxContainer/ValuesSection/ValuesDisplay

# Botões de ação
@onready var regenerate_objects_btn: Button = $MainPanel/ScrollContainer/VBoxContainer/GenerationControls/ActionsContainer/RegenerateObjectsBtn
@onready var test_quality_btn: Button = $MainPanel/ScrollContainer/VBoxContainer/GenerationControls/ActionsContainer/TestQualityBtn
@onready var clear_all_btn: Button = $MainPanel/ScrollContainer/VBoxContainer/GenerationControls/ActionsContainer/ClearAllBtn

# Botões avançados
@onready var show_shader_btn: Button = $MainPanel/ScrollContainer/VBoxContainer/AdvancedSection/AdvancedContainer/ShowShaderBtn
@onready var show_tiles_btn: Button = $MainPanel/ScrollContainer/VBoxContainer/AdvancedSection/AdvancedContainer/ShowTilesBtn
@onready var debug_btn: Button = $MainPanel/ScrollContainer/VBoxContainer/AdvancedSection/AdvancedContainer/DebugBtn
@onready var export_btn: Button = $MainPanel/ScrollContainer/VBoxContainer/AdvancedSection/AdvancedContainer/ExportBtn

# === COMPONENTES DO SISTEMA ===
var world_manager: Node2D
var terrain_generator: TileMapLayer
var resource_generator: TileMapLayer
var object_generator: TileMapLayer
var shader_controller: Sprite2D

# === CONFIGURAÇÕES DE PREDEFINIÇÕES ===
var world_presets = {
	"balanced_empire": {
		"name": "🏰 Balanced Empire",
		"description": "Equilibrado para estratégia e construção de cidades",
		"terrain_type": "Continente",
		"config": {
			"terrain_quality": 0.7,
			"resource_abundance": 0.6,
			"vegetation_density": 0.4,
			"resource_object_separation": 2,
			"object_spacing": 1,
			"map_border_safety": 4,
			"noise_octaves": 4,
			"noise_frequency": 0.025,
			"oceanThreshold": 0.2,
			"beachThreshold": 0.25,
			"desertThreshold": 0.4,
			"grassThreshold": 0.6,
			"darkGrassThreshold": 0.75,
			"mountainThreshold": 0.85,
			"rock_formation_density": 0.12,
			"min_formation_size": 8,
			"max_formation_size": 30,
			"mountain_formation_multiplier": 5.0,
			"hills_formation_multiplier": 3.0,
			"grass_density": 0.05,
			"tree_density": 0.025,
			"bush_density": 0.01,
			"resource_avoidance_radius": 2
		}
	},
	"harsh_survival": {
		"name": "🗡️ Harsh Survival",
		"description": "Mundo desafiador com recursos escassos",
		"terrain_type": "Ilha",
		"config": {
			"terrain_quality": 0.9,
			"resource_abundance": 0.25,
			"vegetation_density": 0.7,
			"resource_object_separation": 3,
			"object_spacing": 1,
			"map_border_safety": 2,
			"noise_octaves": 6,
			"noise_frequency": 0.035,
			"oceanThreshold": 0.3,
			"beachThreshold": 0.35,
			"desertThreshold": 0.5,
			"grassThreshold": 0.6,
			"darkGrassThreshold": 0.75,
			"mountainThreshold": 0.8,
			"rock_formation_density": 0.06,
			"min_formation_size": 4,
			"max_formation_size": 15,
			"formation_compactness": 0.4,
			"mountain_formation_multiplier": 6.0,
			"grass_density": 0.08,
			"tree_density": 0.05,
			"bush_density": 0.03,
			"forest_vegetation_bonus": 4.0,
			"resource_avoidance_radius": 3
		}
	},
	"peaceful_explorer": {
		"name": "🌿 Peaceful Explorer",
		"description": "Mundo verde e abundante para exploração relaxante",
		"terrain_type": "Auto",
		"config": {
			"terrain_quality": 0.8,
			"resource_abundance": 0.7,
			"vegetation_density": 0.8,
			"resource_object_separation": 1,
			"object_spacing": 2,
			"map_border_safety": 3,
			"noise_octaves": 5,
			"noise_frequency": 0.03,
			"oceanThreshold": 0.28,
			"beachThreshold": 0.36,
			"desertThreshold": 0.4,
			"grassThreshold": 0.5,
			"darkGrassThreshold": 0.8,
			"mountainThreshold": 0.88,
			"rock_formation_density": 0.1,
			"min_formation_size": 6,
			"max_formation_size": 20,
			"formation_compactness": 0.6,
			"edge_roughness": 0.3,
			"grassland_formation_multiplier": 1.2,
			"forest_formation_multiplier": 1.0,
			"grass_density": 0.1,
			"tree_density": 0.06,
			"bush_density": 0.04,
			"forest_vegetation_bonus": 3.0,
			"grassland_bonus": 1.5,
			"resource_avoidance_radius": 1
		}
	},
	"strategic_warfare": {
		"name": "⚔️ Strategic Warfare",
		"description": "Terreno otimizado para combate tático e estratégico",
		"terrain_type": "Continente",
		"config": {
			"terrain_quality": 0.6,
			"resource_abundance": 0.5,
			"vegetation_density": 0.3,
			"resource_object_separation": 2,
			"object_spacing": 2,
			"map_border_safety": 3,
			"noise_octaves": 4,
			"noise_frequency": 0.02,
			"oceanThreshold": 0.25,
			"beachThreshold": 0.3,
			"desertThreshold": 0.45,
			"grassThreshold": 0.65,
			"darkGrassThreshold": 0.75,
			"mountainThreshold": 0.75,
			"rock_formation_density": 0.08,
			"min_formation_size": 10,
			"max_formation_size": 35,
			"formation_compactness": 0.7,
			"mountain_formation_multiplier": 4.0,
			"hills_formation_multiplier": 2.0,
			"grass_density": 0.04,
			"tree_density": 0.02,
			"bush_density": 0.01,
			"resource_avoidance_radius": 2
		}
	},
	"desert_wasteland": {
		"name": "🏜️ Desert Wasteland",
		"description": "Sobrevivência extrema em ambiente árido e hostil",
		"terrain_type": "Desertão",
		"config": {
			"terrain_quality": 0.6,
			"resource_abundance": 0.15,
			"vegetation_density": 0.1,
			"resource_object_separation": 4,
			"object_spacing": 1,
			"map_border_safety": 5,
			"noise_octaves": 4,
			"noise_frequency": 0.04,
			"oceanThreshold": 0.15,
			"beachThreshold": 0.2,
			"desertThreshold": 0.7,
			"grassThreshold": 0.8,
			"darkGrassThreshold": 0.9,
			"mountainThreshold": 0.8,
			"rock_formation_density": 0.04,
			"min_formation_size": 3,
			"max_formation_size": 8,
			"mountain_formation_multiplier": 8.0,
			"desert_formation_multiplier": 0.5,
			"grassland_formation_multiplier": 0.3,
			"grass_density": 0.02,
			"tree_density": 0.005,
			"bush_density": 0.01,
			"desert_penalty": 0.05,
			"resource_avoidance_radius": 4
		}
	},
	"paradise_island": {
		"name": "🏖️ Paradise Island",
		"description": "Ilha tropical exuberante e paradisíaca",
		"terrain_type": "Ilha",
		"config": {
			"terrain_quality": 0.8,
			"resource_abundance": 0.4,
			"vegetation_density": 0.9,
			"resource_object_separation": 2,
			"object_spacing": 1,
			"map_border_safety": 2,
			"noise_octaves": 5,
			"noise_frequency": 0.04,
			"oceanThreshold": 0.35,
			"beachThreshold": 0.45,
			"desertThreshold": 0.5,
			"grassThreshold": 0.6,
			"darkGrassThreshold": 0.8,
			"mountainThreshold": 0.9,
			"rock_formation_density": 0.06,
			"min_formation_size": 4,
			"max_formation_size": 15,
			"formation_compactness": 0.5,
			"grass_density": 0.12,
			"tree_density": 0.08,
			"bush_density": 0.05,
			"forest_vegetation_bonus": 4.0,
			"grassland_bonus": 2.0,
			"resource_avoidance_radius": 2
		}
	}
}

var map_sizes = {
	"small": {"name": "Pequeno (64x64)", "width": 64, "height": 64},
	"medium": {"name": "Médio (128x128)", "width": 128, "height": 128},
	"large": {"name": "Grande (256x256)", "width": 256, "height": 256}
}

var terrain_types = ["Auto", "Ilha", "Continente", "Arquipélago", "Península", "Desertão"]

# === ESTADO ===
var current_preset: String = ""
var shader_visible: bool = true
var tiles_visible: bool = true
var is_generating: bool = false

func _ready():
	await get_tree().process_frame
	setup_ui()
	find_components()
	connect_signals()
	populate_dropdowns()
	update_values_display()
	update_status("✅ Interface carregada - Pronto para gerar", Color.GREEN)

func setup_ui():
	"""Configuração inicial da UI"""
	print("🎨 Configurando interface de predefinições...")
	
	# Garante que a UI seja visível
	visible = true
	
	# Posiciona o painel no lado direito
	if has_node("MainPanel"):
		var main_panel = get_node("MainPanel")
		main_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		main_panel.position.x -= 420
		main_panel.size = Vector2(400, 660)

func find_components():
	"""Encontra todos os componentes do sistema"""
	print("🔍 Buscando componentes do sistema...")
	
	# Busca WorldManager
	world_manager = find_component_by_group("world_manager")
	if not world_manager:
		world_manager = get_node_or_null("/root/Main")
		if not world_manager:
			world_manager = find_node_by_script("WorldManager.gd")
	
	# Busca geradores
	terrain_generator = find_component_by_group("terrain")
	resource_generator = find_component_by_group("resources")
	object_generator = find_component_by_group("objects")
	shader_controller = find_component_by_group("shader")
	
	print_component_status()

func find_component_by_group(group_name: String) -> Node:
	"""Busca componente por grupo"""
	var nodes = get_tree().get_nodes_in_group(group_name)
	return nodes[0] if nodes.size() > 0 else null

func find_node_by_script(script_name: String) -> Node:
	"""Busca nó por script"""
	return find_script_recursive(get_tree().root, script_name)

func find_script_recursive(node: Node, script_name: String) -> Node:
	"""Busca recursiva por script"""
	if node.get_script() and node.get_script().resource_path.ends_with(script_name):
		return node
	
	for child in node.get_children():
		var result = find_script_recursive(child, script_name)
		if result:
			return result
	
	return null

func print_component_status():
	"""Mostra status dos componentes encontrados"""
	print("📊 Status dos componentes:")
	print("  🌍 WorldManager: ", "✅" if world_manager else "❌")
	print("  🗻 TerrainGenerator: ", "✅" if terrain_generator else "❌")
	print("  🔧 ResourceGenerator: ", "✅" if resource_generator else "❌")
	print("  🌿 ObjectGenerator: ", "✅" if object_generator else "❌")
	print("  🎨 ShaderController: ", "✅" if shader_controller else "❌")

func connect_signals():
	"""Conecta todos os sinais da UI"""
	print("🔗 Conectando sinais da interface...")
	
	# Dropdowns
	preset_dropdown.item_selected.connect(_on_preset_selected)
	size_dropdown.item_selected.connect(_on_size_selected)
	terrain_dropdown.item_selected.connect(_on_terrain_type_selected)
	
	# Controles de seed
	random_seed_button.pressed.connect(_on_random_seed_pressed)
	seed_input.value_changed.connect(_on_seed_changed)
	
	# Botão principal
	generate_button.pressed.connect(_on_generate_pressed)
	
	# Botões de ação
	regenerate_objects_btn.pressed.connect(_on_regenerate_objects_pressed)
	test_quality_btn.pressed.connect(_on_test_quality_pressed)
	clear_all_btn.pressed.connect(_on_clear_all_pressed)
	
	# Botões avançados
	show_shader_btn.pressed.connect(_on_show_shader_pressed)
	show_tiles_btn.pressed.connect(_on_show_tiles_pressed)
	debug_btn.pressed.connect(_on_debug_pressed)
	export_btn.pressed.connect(_on_export_pressed)

func populate_dropdowns():
	"""Popula todos os dropdowns com dados"""
	print("📋 Populando dropdowns...")
	
	# Preset dropdown
	preset_dropdown.clear()
	preset_dropdown.add_item("Selecione um estilo...")
	for preset_key in world_presets:
		var preset = world_presets[preset_key]
		preset_dropdown.add_item(preset["name"])
	
	# Size dropdown
	size_dropdown.clear()
	for size_key in map_sizes:
		var size_info = map_sizes[size_key]
		size_dropdown.add_item(size_info["name"])
	size_dropdown.selected = 1  # Médio por padrão
	
	# Terrain type dropdown
	terrain_dropdown.clear()
	for terrain_type in terrain_types:
		terrain_dropdown.add_item(terrain_type)

# === CALLBACKS DA UI ===

func _on_preset_selected(index: int):
	"""Callback quando preset é selecionado"""
	if index == 0:  # "Selecione um estilo..."
		return
	
	var preset_keys = world_presets.keys()
	var selected_key = preset_keys[index - 1]
	var preset = world_presets[selected_key]
	
	current_preset = selected_key
	print("🎯 Preset selecionado: ", preset["name"])
	
	# Atualiza descrição
	if has_node("MainPanel/ScrollContainer/VBoxContainer/PresetSection/PresetDescription"):
		var desc_label = get_node("MainPanel/ScrollContainer/VBoxContainer/PresetSection/PresetDescription")
		desc_label.text = preset["description"]
	
	# Aplica o preset
	apply_preset(preset)
	
	# Atualiza tipo de terreno no dropdown
	var terrain_type = preset.get("terrain_type", "Auto")
	var terrain_index = terrain_types.find(terrain_type)
	if terrain_index >= 0:
		terrain_dropdown.selected = terrain_index
	
	update_values_display()
	update_status("Preset '" + preset["name"] + "' aplicado", Color.CYAN)

func _on_size_selected(index: int):
	"""Callback quando tamanho é selecionado"""
	var size_keys = map_sizes.keys()
	var selected_key = size_keys[index]
	var size_info = map_sizes[selected_key]
	
	apply_map_size(size_info["width"], size_info["height"])
	update_values_display()
	update_status("Tamanho alterado para " + size_info["name"], Color.BLUE)

func _on_terrain_type_selected(index: int):
	"""Callback quando tipo de terreno é selecionado"""
	var selected_type = terrain_types[index]
	apply_terrain_type(selected_type)
	update_status("Tipo de terreno: " + selected_type, Color.BLUE)

func _on_random_seed_pressed():
	"""Gera seed aleatório"""
	var new_seed = randi() % 999999999
	seed_input.value = new_seed
	apply_seed(new_seed)
	update_status("Seed aleatório: " + str(new_seed), Color.GREEN)

func _on_seed_changed(value: float):
	"""Callback quando seed muda"""
	apply_seed(int(value))

func _on_generate_pressed():
	"""Callback do botão principal de geração"""
	if is_generating:
		update_status("⚠️ Geração já em progresso...", Color.YELLOW)
		return
	
	generate_complete_world()

func _on_regenerate_objects_pressed():
	"""Regenera apenas objetos"""
	if is_generating:
		return
	
	if world_manager and world_manager.has_method("regenerate_only_objects"):
		update_status("🌿 Regenerando objetos...", Color.YELLOW)
		world_manager.regenerate_only_objects()
		await get_tree().create_timer(2.0).timeout
		update_status("✅ Objetos regenerados", Color.GREEN)
	else:
		update_status("❌ Método não encontrado", Color.RED)

func _on_test_quality_pressed():
	"""Testa qualidade da geração"""
	if world_manager and world_manager.has_method("verify_generation_quality"):
		update_status("🔍 Testando qualidade...", Color.YELLOW)
		world_manager.verify_generation_quality()
		update_status("✅ Teste concluído - Veja console", Color.GREEN)
	else:
		update_status("❌ Método de teste não encontrado", Color.RED)

func _on_clear_all_pressed():
	"""Limpa tudo"""
	if world_manager and world_manager.has_method("clear_world"):
		update_status("🧹 Limpando mundo...", Color.YELLOW)
		world_manager.clear_world()
		await get_tree().create_timer(1.0).timeout
		update_status("✅ Mundo limpo", Color.GREEN)
	else:
		# Fallback - limpa individualmente
		clear_all_components()

func _on_show_shader_pressed():
	"""Toggle do shader"""
	shader_visible = !shader_visible
	
	if shader_controller:
		shader_controller.visible = shader_visible
		show_shader_btn.text = "🎨 " + ("Ocultar" if shader_visible else "Mostrar") + " Shader"
		update_status("Shader " + ("ativado" if shader_visible else "desativado"), Color.BLUE)

func _on_show_tiles_pressed():
	"""Toggle dos tiles"""
	tiles_visible = !tiles_visible
	
	# Alterna visibilidade dos TileMapLayers
	for component in [terrain_generator, resource_generator, object_generator]:
		if component:
			component.visible = tiles_visible
	
	show_tiles_btn.text = "🗂️ " + ("Ocultar" if tiles_visible else "Mostrar") + " Tiles"
	update_status("Tiles " + ("ativados" if tiles_visible else "desativados"), Color.BLUE)

func _on_debug_pressed():
	"""Ativa debug"""
	print("\n🐛 === DEBUG DA INTERFACE ===")
	print_component_status()
	
	# Debug dos valores atuais
	if world_manager:
		print("🌍 WorldManager valores:")
		print("  - terrain_quality: ", get_property_safe(world_manager, "terrain_quality"))
		print("  - resource_abundance: ", get_property_safe(world_manager, "resource_abundance"))
		print("  - vegetation_density: ", get_property_safe(world_manager, "vegetation_density"))
	
	# Chama debug no DebugHelper se existir
	var debug_helper = find_component_by_group("debug")
	if debug_helper and debug_helper.has_method("debug_all_tiles"):
		debug_helper.debug_all_tiles()
	
	update_status("🐛 Debug executado - Veja console", Color.MAGENTA)

func _on_export_pressed():
	"""Exporta configuração atual"""
	var config = export_current_config()
	
	# Salva em arquivo JSON
	var file = FileAccess.open("res://exported_config.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(config, "\t"))
		file.close()
		update_status("💾 Configuração exportada", Color.GREEN)
	else:
		update_status("❌ Erro ao exportar", Color.RED)

# === APLICAÇÃO DE CONFIGURAÇÕES ===

func apply_preset(preset: Dictionary):
	"""Aplica uma predefinição completa"""
	var config = preset["config"]
	
	print("⚙️ Aplicando preset: ", preset["name"])
	
	# Aplica no WorldManager
	if world_manager:
		apply_config_to_node(world_manager, config, [
			"terrain_quality", "resource_abundance", "vegetation_density",
			"resource_object_separation", "object_spacing", "map_border_safety"
		])
	
	# Aplica no TerrainGenerator
	if terrain_generator:
		apply_config_to_node(terrain_generator, config, [
			"noise_octaves", "noise_frequency", "oceanThreshold", "beachThreshold",
			"desertThreshold", "grassThreshold", "darkGrassThreshold", "mountainThreshold"
		])
	
	# Aplica no ResourceGenerator
	if resource_generator:
		apply_config_to_node(resource_generator, config, [
			"rock_formation_density", "min_formation_size", "max_formation_size",
			"formation_compactness", "edge_roughness", "mountain_formation_multiplier",
			"hills_formation_multiplier", "desert_formation_multiplier",
			"grassland_formation_multiplier", "forest_formation_multiplier"
		])
	
	# Aplica no ObjectGenerator
	if object_generator:
		apply_config_to_node(object_generator, config, [
			"grass_density", "tree_density", "bush_density", "resource_avoidance_radius",
			"forest_vegetation_bonus", "grassland_bonus", "desert_penalty"
		])

func apply_config_to_node(node: Node, config: Dictionary, properties: Array):
	"""Aplica configuração específica a um nó"""
	for property in properties:
		if property in config:
			set_property_safe(node, property, config[property])

func apply_map_size(width: int, height: int):
	"""Aplica tamanho do mapa"""
	if world_manager:
		set_property_safe(world_manager, "map_size", width)
	
	if terrain_generator:
		set_property_safe(terrain_generator, "map_width", width)
		set_property_safe(terrain_generator, "map_height", height)

func apply_terrain_type(terrain_type: String):
	"""Aplica tipo de terreno"""
	if world_manager:
		set_property_safe(world_manager, "world_type", terrain_type)
	
	if terrain_generator:
		set_property_safe(terrain_generator, "terrain_type", terrain_type)

func apply_seed(seed_value: int):
	"""Aplica seed"""
	if world_manager:
		set_property_safe(world_manager, "world_seed", seed_value)
	
	if terrain_generator:
		set_property_safe(terrain_generator, "terrain_seed", seed_value)

func set_property_safe(node: Node, property: String, value):
	"""Define propriedade de forma segura"""
	if node and property in node:
		node.set(property, value)
		print("✅ ", node.name, ".", property, " = ", value)
	else:
		print("⚠️ Propriedade não encontrada: ", node.name if node else "null", ".", property)

func get_property_safe(node: Node, property: String, default_value = "N/A"):
	"""Obtém propriedade de forma segura"""
	if node and property in node:
		return node.get(property)
	return default_value

# === GERAÇÃO DE MUNDO ===

func generate_complete_world():
	"""Gera mundo completo"""
	if not world_manager:
		update_status("❌ WorldManager não encontrado!", Color.RED)
		return
	
	is_generating = true
	generate_button.text = "⏳ Gerando..."
	generate_button.disabled = true
	
	update_status("🚀 Iniciando geração do mundo...", Color.YELLOW)
	
	# Tenta diferentes métodos de geração
	var generation_started = false
	
	if world_manager.has_method("generate_complete_world"):
		world_manager.generate_complete_world()
		generation_started = true
	elif world_manager.has_method("generate_world"):
		set_property_safe(world_manager, "generate_world", true)
		generation_started = true
	elif world_manager.has_method("_on_generate_button_pressed"):
		world_manager._on_generate_button_pressed()
		generation_started = true
	
	if generation_started:
		# Aguarda geração completar
		await get_tree().create_timer(6.0).timeout
		update_status("✅ Mundo gerado com sucesso!", Color.GREEN)
		
		# Atualiza visualização
		update_values_display()
		
		# Aplica configurações de visibilidade
		apply_visibility_settings()
	else:
		update_status("❌ Método de geração não encontrado!", Color.RED)
	
	is_generating = false
	generate_button.text = "🌍 Gerar Mundo Completo"
	generate_button.disabled = false

func apply_visibility_settings():
	"""Aplica configurações de visibilidade"""
	if shader_controller:
		shader_controller.visible = shader_visible
	
	for component in [terrain_generator, resource_generator, object_generator]:
		if component:
			component.visible = tiles_visible

func clear_all_components():
	"""Limpa todos os componentes individualmente"""
	update_status("🧹 Limpando componentes...", Color.YELLOW)
	
	for component in [terrain_generator, resource_generator, object_generator]:
		if component and component.has_method("clear"):
			component.clear()
	
	update_status("✅ Componentes limpos", Color.GREEN)

# === VISUALIZAÇÃO DE VALORES ===

func update_values_display():
	"""Atualiza display de valores"""
	if not values_display:
		return
	
	var text = "[color=yellow]🌍 Configurações Atuais[/color]\n\n"
	
	# Preset atual
	if current_preset != "":
		var preset = world_presets.get(current_preset, {})
		text += "[color=gold]🎯 Preset: " + preset.get("name", "Desconhecido") + "[/color]\n\n"
	
	# WorldManager
	if world_manager:
		text += "[color=cyan]WorldManager:[/color]\n"
		text += "• Qualidade: " + str(get_property_safe(world_manager, "terrain_quality", 0.8)) + "\n"
		text += "• Recursos: " + str(get_property_safe(world_manager, "resource_abundance", 0.4)) + "\n"
		text += "• Vegetação: " + str(get_property_safe(world_manager, "vegetation_density", 0.5)) + "\n"
		text += "• Separação: " + str(get_property_safe(world_manager, "resource_object_separation", 2)) + "\n"
		text += "• Tamanho: " + str(get_property_safe(world_manager, "map_size", 128)) + "\n\n"
	
	# TerrainGenerator
	if terrain_generator:
		text += "[color=green]TerrainGenerator:[/color]\n"
		text += "• Octaves: " + str(get_property_safe(terrain_generator, "noise_octaves", 4)) + "\n"
		text += "• Frequência: " + str(get_property_safe(terrain_generator, "noise_frequency", 0.03)) + "\n"
		text += "• Tipo: " + str(get_property_safe(terrain_generator, "terrain_type", "Auto")) + "\n"
		text += "• Seed: " + str(get_property_safe(terrain_generator, "terrain_seed", 0)) + "\n\n"
	
	# ResourceGenerator
	if resource_generator:
		text += "[color=orange]ResourceGenerator:[/color]\n"
		text += "• Densidade: " + str(get_property_safe(resource_generator, "rock_formation_density", 0.08)) + "\n"
		text += "• Min Size: " + str(get_property_safe(resource_generator, "min_formation_size", 6)) + "\n"
		text += "• Max Size: " + str(get_property_safe(resource_generator, "max_formation_size", 25)) + "\n\n"
	
	# ObjectGenerator
	if object_generator:
		text += "[color=lime]ObjectGenerator:[/color]\n"
		text += "• Grama: " + str(get_property_safe(object_generator, "grass_density", 0.06)) + "\n"
		text += "• Árvores: " + str(get_property_safe(object_generator, "tree_density", 0.03)) + "\n"
		text += "• Arbustos: " + str(get_property_safe(object_generator, "bush_density", 0.015)) + "\n"
	
	# Status dos componentes
	text += "\n[color=gray]Status dos Componentes:[/color]\n"
	text += "• WorldManager: " + ("✅" if world_manager else "❌") + "\n"
	text += "• TerrainGenerator: " + ("✅" if terrain_generator else "❌") + "\n"
	text += "• ResourceGenerator: " + ("✅" if resource_generator else "❌") + "\n"
	text += "• ObjectGenerator: " + ("✅" if object_generator else "❌") + "\n"
	text += "• ShaderController: " + ("✅" if shader_controller else "❌") + "\n"
	
	values_display.text = text

func update_status(message: String, color: Color = Color.WHITE):
	"""Atualiza mensagem de status"""
	if status_label:
		status_label.text = message
		status_label.add_theme_color_override("font_color", color)
	
	print("📢 Status: ", message)

# === EXPORTAÇÃO/IMPORTAÇÃO ===

func export_current_config() -> Dictionary:
	"""Exporta configuração atual"""
	var config = {
		"preset": current_preset,
		"map_size": {
			"width": get_property_safe(terrain_generator, "map_width", 128),
			"height": get_property_safe(terrain_generator, "map_height", 128)
		},
		"terrain_type": get_property_safe(terrain_generator, "terrain_type", "Auto"),
		"seed": get_property_safe(terrain_generator, "terrain_seed", 0),
		"world_manager": extract_node_config(world_manager, [
			"terrain_quality", "resource_abundance", "vegetation_density",
			"resource_object_separation", "object_spacing", "map_border_safety"
		]),
		"terrain_generator": extract_node_config(terrain_generator, [
			"noise_octaves", "noise_frequency", "oceanThreshold", "beachThreshold",
			"desertThreshold", "grassThreshold", "darkGrassThreshold", "mountainThreshold"
		]),
		"resource_generator": extract_node_config(resource_generator, [
			"rock_formation_density", "min_formation_size", "max_formation_size",
			"formation_compactness", "edge_roughness"
		]),
		"object_generator": extract_node_config(object_generator, [
			"grass_density", "tree_density", "bush_density", "resource_avoidance_radius"
		])
	}
	
	return config

func extract_node_config(node: Node, properties: Array) -> Dictionary:
	"""Extrai configuração de um nó"""
	var config = {}
	if node:
		for property in properties:
			config[property] = get_property_safe(node, property)
	return config

# === FUNÇÕES DE CONVENIÊNCIA ===

func load_preset_by_name(preset_name: String):
	"""Carrega preset por nome (útil para scripts externos)"""
	for i in range(preset_dropdown.get_item_count()):
		if preset_dropdown.get_item_text(i) == preset_name:
			preset_dropdown.selected = i
			_on_preset_selected(i)
			return true
	return false

func quick_generate(preset_name: String, map_size_name: String = "medium"):
	"""Geração rápida com preset e tamanho específicos"""
	# Carrega preset
	load_preset_by_name(preset_name)
	
	# Define tamanho
	var size_keys = map_sizes.keys()
	var size_index = size_keys.find(map_size_name)
	if size_index >= 0:
		size_dropdown.selected = size_index
		_on_size_selected(size_index)
	
	# Gera
	generate_complete_world()

func toggle_interface():
	"""Toggle da visibilidade da interface"""
	visible = !visible
