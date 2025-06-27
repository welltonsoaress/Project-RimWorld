@tool
class_name PresetManager
extends Control

# === REFERÊNCIAS DOS COMPONENTES ===
var world_manager: Node2D
var terrain_generator: TileMapLayer
var resource_generator: TileMapLayer
var object_generator: TileMapLayer

# === NODES DA UI ===
@onready var preset_dropdown: OptionButton
@onready var size_dropdown: OptionButton
@onready var terrain_type_dropdown: OptionButton
@onready var seed_input: SpinBox
@onready var random_seed_button: Button
@onready var generate_button: Button
@onready var status_label: Label
@onready var values_display: RichTextLabel

# === PREDEFINIÇÕES ===
var presets = {
	"balanced_empire": {
		"name": "🏰 Balanced Empire",
		"description": "Ideal para estratégia e citybuilding",
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
			"grass_density": 0.05,
			"tree_density": 0.025,
			"bush_density": 0.01
		}
	},
	"harsh_survival": {
		"name": "🗡️ Harsh Survival",
		"description": "Mundo desafiador com recursos escassos",
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
			"grass_density": 0.08,
			"tree_density": 0.05,
			"bush_density": 0.03
		}
	},
	"peaceful_explorer": {
		"name": "🌿 Peaceful Explorer",
		"description": "Mundo verde e abundante para exploração",
		"config": {
			"terrain_quality": 0.8,
			"resource_abundance": 0.7,
			"vegetation_density": 0.8,
			"resource_object_separation": 1,
			"object_spacing": 1,
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
			"grass_density": 0.1,
			"tree_density": 0.06,
			"bush_density": 0.04
		}
	},
	"strategic_warfare": {
		"name": "⚔️ Strategic Warfare",
		"description": "Grandes batalhas e posições estratégicas",
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
			"grass_density": 0.04,
			"tree_density": 0.02,
			"bush_density": 0.01
		}
	},
	"desert_wasteland": {
		"name": "🏜️ Desert Wasteland",
		"description": "Sobrevivência extrema em ambiente hostil",
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
			"grass_density": 0.02,
			"tree_density": 0.005,
			"bush_density": 0.01
		}
	},
	"paradise_island": {
		"name": "🏖️ Paradise Island",
		"description": "Ilha tropical densa e exuberante",
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
			"grass_density": 0.12,
			"tree_density": 0.08,
			"bush_density": 0.05
		}
	}
}

var map_sizes = {
	"small": {"name": "Pequeno (64x64)", "width": 64, "height": 64},
	"medium": {"name": "Médio (128x128)", "width": 128, "height": 128},
	"large": {"name": "Grande (256x256)", "width": 256, "height": 256}
}

var terrain_types = [
	"Auto", "Ilha", "Continente", "Arquipélago", "Península", "Desertão"
]

func _ready():
	create_ui()
	find_components()
	setup_connections()
	update_values_display()

func create_ui():
	"""Cria a interface visual completa"""
	# Container principal
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Painel principal
	var main_panel = Panel.new()
	main_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	main_panel.size = Vector2(400, 600)
	main_panel.position = Vector2(20, 20)
	add_child(main_panel)
	
	# Container de scroll
	var scroll = ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.add_theme_constant_override("margin_left", 10)
	scroll.add_theme_constant_override("margin_right", 10)
	scroll.add_theme_constant_override("margin_top", 10)
	scroll.add_theme_constant_override("margin_bottom", 10)
	main_panel.add_child(scroll)
	
	# Container vertical principal
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	scroll.add_child(vbox)
	
	# Título
	var title = Label.new()
	title.text = "🌍 Gerador de Mundos Procedurais"
	title.add_theme_font_size_override("font_size", 20)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	# Seção: Predefinições
	create_preset_section(vbox)
	
	# Separador
	vbox.add_child(HSeparator.new())
	
	# Seção: Configurações básicas
	create_basic_settings_section(vbox)
	
	# Separador
	vbox.add_child(HSeparator.new())
	
	# Seção: Controles de geração
	create_generation_controls(vbox)
	
	# Separador
	vbox.add_child(HSeparator.new())
	
	# Seção: Visualização de valores
	create_values_display_section(vbox)

func create_preset_section(parent: VBoxContainer):
	"""Cria a seção de predefinições"""
	var preset_label = Label.new()
	preset_label.text = "🎯 Estilo de Jogo"
	preset_label.add_theme_font_size_override("font_size", 16)
	parent.add_child(preset_label)
	
	preset_dropdown = OptionButton.new()
	preset_dropdown.add_item("Selecione um estilo...")
	
	for preset_key in presets:
		var preset = presets[preset_key]
		preset_dropdown.add_item(preset["name"])
	
	parent.add_child(preset_dropdown)
	
	# Descrição do preset
	var description_label = Label.new()
	description_label.text = "Escolha um estilo para configurar automaticamente o mundo"
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.add_theme_color_override("font_color", Color.GRAY)
	parent.add_child(description_label)

func create_basic_settings_section(parent: VBoxContainer):
	"""Cria a seção de configurações básicas"""
	var settings_label = Label.new()
	settings_label.text = "⚙️ Configurações Básicas"
	settings_label.add_theme_font_size_override("font_size", 16)
	parent.add_child(settings_label)
	
	# Tamanho do mapa
	var size_label = Label.new()
	size_label.text = "Tamanho do Mapa:"
	parent.add_child(size_label)
	
	size_dropdown = OptionButton.new()
	for size_key in map_sizes:
		var size_info = map_sizes[size_key]
		size_dropdown.add_item(size_info["name"])
	size_dropdown.selected = 1  # Médio por padrão
	parent.add_child(size_dropdown)
	
	# Tipo de terreno
	var terrain_label = Label.new()
	terrain_label.text = "Tipo de Terreno:"
	parent.add_child(terrain_label)
	
	terrain_type_dropdown = OptionButton.new()
	for terrain_type in terrain_types:
		terrain_type_dropdown.add_item(terrain_type)
	parent.add_child(terrain_type_dropdown)
	
	# Seed
	var seed_container = HBoxContainer.new()
	parent.add_child(seed_container)
	
	var seed_label = Label.new()
	seed_label.text = "Seed:"
	seed_label.custom_minimum_size.x = 80
	seed_container.add_child(seed_label)
	
	seed_input = SpinBox.new()
	seed_input.min_value = 0
	seed_input.max_value = 999999999
	seed_input.step = 1
	seed_input.value = 0
	seed_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	seed_container.add_child(seed_input)
	
	random_seed_button = Button.new()
	random_seed_button.text = "🎲"
	random_seed_button.tooltip_text = "Gerar seed aleatório"
	random_seed_button.custom_minimum_size.x = 40
	seed_container.add_child(random_seed_button)

func create_generation_controls(parent: VBoxContainer):
	"""Cria os controles de geração"""
	var controls_label = Label.new()
	controls_label.text = "🚀 Controles de Geração"
	controls_label.add_theme_font_size_override("font_size", 16)
	parent.add_child(controls_label)
	
	# Botão principal de geração
	generate_button = Button.new()
	generate_button.text = "🌍 Gerar Mundo Completo"
	generate_button.add_theme_font_size_override("font_size", 16)
	generate_button.custom_minimum_size.y = 50
	parent.add_child(generate_button)
	
	# Botões de ações específicas
	var actions_container = HBoxContainer.new()
	actions_container.add_theme_constant_override("separation", 10)
	parent.add_child(actions_container)
	
	var regenerate_objects_btn = Button.new()
	regenerate_objects_btn.text = "🌿 Só Objetos"
	regenerate_objects_btn.tooltip_text = "Regenera apenas vegetação"
	regenerate_objects_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions_container.add_child(regenerate_objects_btn)
	
	var test_quality_btn = Button.new()
	test_quality_btn.text = "🔍 Testar Qualidade"
	test_quality_btn.tooltip_text = "Verifica conflitos e qualidade"
	test_quality_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions_container.add_child(test_quality_btn)
	
	var clear_all_btn = Button.new()
	clear_all_btn.text = "🧹 Limpar Tudo"
	clear_all_btn.tooltip_text = "Remove todos os elementos"
	clear_all_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions_container.add_child(clear_all_btn)
	
	# Status
	status_label = Label.new()
	status_label.text = "✅ Pronto para gerar"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_color_override("font_color", Color.GREEN)
	parent.add_child(status_label)
	
	# Conecta botões
	regenerate_objects_btn.pressed.connect(_on_regenerate_objects_pressed)
	test_quality_btn.pressed.connect(_on_test_quality_pressed)
	clear_all_btn.pressed.connect(_on_clear_all_pressed)

func create_values_display_section(parent: VBoxContainer):
	"""Cria a seção de visualização de valores"""
	var values_label = Label.new()
	values_label.text = "📊 Valores Atuais"
	values_label.add_theme_font_size_override("font_size", 16)
	parent.add_child(values_label)
	
	values_display = RichTextLabel.new()
	values_display.custom_minimum_size.y = 200
	values_display.bbcode_enabled = true
	values_display.fit_content = true
	parent.add_child(values_display)

func setup_connections():
	"""Configura as conexões de sinais"""
	preset_dropdown.item_selected.connect(_on_preset_selected)
	size_dropdown.item_selected.connect(_on_size_selected)
	terrain_type_dropdown.item_selected.connect(_on_terrain_type_selected)
	random_seed_button.pressed.connect(_on_random_seed_pressed)
	generate_button.pressed.connect(_on_generate_pressed)
	seed_input.value_changed.connect(_on_seed_changed)

func find_components():
	"""Encontra os componentes necessários"""
	print("🔍 PresetManager buscando componentes...")
	
	# Busca WorldManager
	var world_nodes = get_tree().get_nodes_in_group("world_manager")
	if world_nodes.size() == 0:
		world_manager = get_node_or_null("/root/Main")
		if not world_manager:
			world_manager = find_node_recursive(get_tree().root, "WorldManager")
		if not world_manager:
			world_manager = find_script_node("WorldManager.gd")
	else:
		world_manager = world_nodes[0]
	
	# Busca outros componentes
	terrain_generator = find_component_by_group("terrain")
	resource_generator = find_component_by_group("resources")
	object_generator = find_component_by_group("objects")
	
	print_component_status()

func find_component_by_group(group_name: String) -> Node:
	"""Busca componente por grupo"""
	var nodes = get_tree().get_nodes_in_group(group_name)
	if nodes.size() > 0:
		return nodes[0]
	return null

func find_node_recursive(node: Node, target_name: String) -> Node:
	"""Busca recursiva por nome"""
	if node.name == target_name:
		return node
	
	for child in node.get_children():
		var result = find_node_recursive(child, target_name)
		if result:
			return result
	
	return null

func find_script_node(script_name: String) -> Node:
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
	"""Mostra status dos componentes"""
	print("📊 Status dos componentes:")
	print("  🌍 WorldManager: ", "✅" if world_manager else "❌")
	print("  🗻 TerrainGenerator: ", "✅" if terrain_generator else "❌")
	print("  🔧 ResourceGenerator: ", "✅" if resource_generator else "❌")
	print("  🌿 ObjectGenerator: ", "✅" if object_generator else "❌")

# === CALLBACKS DA UI ===

func _on_preset_selected(index: int):
	"""Callback quando preset é selecionado"""
	if index == 0:  # "Selecione um estilo..."
		return
	
	var preset_keys = presets.keys()
	var selected_key = preset_keys[index - 1]
	var preset = presets[selected_key]
	
	print("🎯 Preset selecionado: ", preset["name"])
	apply_preset(preset)
	update_values_display()
	update_status("Preset '" + preset["name"] + "' aplicado", Color.BLUE)

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
	update_status("Seed aleatório gerado: " + str(new_seed), Color.GREEN)

func _on_seed_changed(value: float):
	"""Callback quando seed muda"""
	apply_seed(int(value))

func _on_generate_pressed():
	"""Callback do botão principal de geração"""
	generate_complete_world()

func _on_regenerate_objects_pressed():
	"""Regenera apenas objetos"""
	if world_manager and world_manager.has_method("regenerate_only_objects"):
		update_status("🌿 Regenerando objetos...", Color.YELLOW)
		world_manager.regenerate_only_objects()
		await get_tree().create_timer(2.0).timeout
		update_status("✅ Objetos regenerados", Color.GREEN)

func _on_test_quality_pressed():
	"""Testa qualidade da geração"""
	if world_manager and world_manager.has_method("verify_generation_quality"):
		update_status("🔍 Testando qualidade...", Color.YELLOW)
		world_manager.verify_generation_quality()
		update_status("✅ Teste de qualidade concluído", Color.GREEN)

func _on_clear_all_pressed():
	"""Limpa tudo"""
	if world_manager and world_manager.has_method("clear_world"):
		update_status("🧹 Limpando mundo...", Color.YELLOW)
		world_manager.clear_world()
		await get_tree().create_timer(1.0).timeout
		update_status("✅ Mundo limpo", Color.GREEN)

# === APLICAÇÃO DE CONFIGURAÇÕES ===

func apply_preset(preset: Dictionary):
	"""Aplica uma predefinição completa"""
	var config = preset["config"]
	
	# Aplica no WorldManager
	if world_manager:
		set_property_if_exists(world_manager, "terrain_quality", config.get("terrain_quality", 0.8))
		set_property_if_exists(world_manager, "resource_abundance", config.get("resource_abundance", 0.4))
		set_property_if_exists(world_manager, "vegetation_density", config.get("vegetation_density", 0.5))
		set_property_if_exists(world_manager, "resource_object_separation", config.get("resource_object_separation", 2))
		set_property_if_exists(world_manager, "object_spacing", config.get("object_spacing", 1))
		set_property_if_exists(world_manager, "map_border_safety", config.get("map_border_safety", 3))
	
	# Aplica no TerrainGenerator
	if terrain_generator:
		set_property_if_exists(terrain_generator, "noise_octaves", config.get("noise_octaves", 4))
		set_property_if_exists(terrain_generator, "noise_frequency", config.get("noise_frequency", 0.03))
		set_property_if_exists(terrain_generator, "oceanThreshold", config.get("oceanThreshold", 0.25))
		set_property_if_exists(terrain_generator, "beachThreshold", config.get("beachThreshold", 0.35))
		set_property_if_exists(terrain_generator, "desertThreshold", config.get("desertThreshold", 0.45))
		set_property_if_exists(terrain_generator, "grassThreshold", config.get("grassThreshold", 0.55))
		set_property_if_exists(terrain_generator, "darkGrassThreshold", config.get("darkGrassThreshold", 0.7))
		set_property_if_exists(terrain_generator, "mountainThreshold", config.get("mountainThreshold", 0.85))
	
	# Aplica no ResourceGenerator
	if resource_generator:
		set_property_if_exists(resource_generator, "rock_formation_density", config.get("rock_formation_density", 0.08))
		set_property_if_exists(resource_generator, "min_formation_size", config.get("min_formation_size", 6))
		set_property_if_exists(resource_generator, "max_formation_size", config.get("max_formation_size", 25))
	
	# Aplica no ObjectGenerator
	if object_generator:
		set_property_if_exists(object_generator, "grass_density", config.get("grass_density", 0.06))
		set_property_if_exists(object_generator, "tree_density", config.get("tree_density", 0.03))
		set_property_if_exists(object_generator, "bush_density", config.get("bush_density", 0.015))

func apply_map_size(width: int, height: int):
	"""Aplica tamanho do mapa"""
	if world_manager:
		set_property_if_exists(world_manager, "map_size", width)
	
	if terrain_generator:
		set_property_if_exists(terrain_generator, "map_width", width)
		set_property_if_exists(terrain_generator, "map_height", height)

func apply_terrain_type(terrain_type: String):
	"""Aplica tipo de terreno"""
	if world_manager:
		set_property_if_exists(world_manager, "world_type", terrain_type)
	
	if terrain_generator:
		set_property_if_exists(terrain_generator, "terrain_type", terrain_type)

func apply_seed(seed_value: int):
	"""Aplica seed"""
	if world_manager:
		set_property_if_exists(world_manager, "world_seed", seed_value)
	
	if terrain_generator:
		set_property_if_exists(terrain_generator, "terrain_seed", seed_value)

func set_property_if_exists(node: Node, property: String, value):
	"""Define propriedade se ela existir"""
	if property in node:
		node.set(property, value)
		print("✅ ", node.name, ".", property, " = ", value)
	else:
		print("⚠️ Propriedade não encontrada: ", node.name, ".", property)

func generate_complete_world():
	"""Gera mundo completo"""
	if not world_manager:
		update_status("❌ WorldManager não encontrado!", Color.RED)
		return
	
	update_status("🚀 Gerando mundo...", Color.YELLOW)
	
	if world_manager.has_method("generate_complete_world"):
		world_manager.generate_complete_world()
		await get_tree().create_timer(5.0).timeout
		update_status("✅ Mundo gerado com sucesso!", Color.GREEN)
	elif world_manager.has_method("generate_world"):
		# Fallback para método alternativo
		world_manager.generate_world = true
		await get_tree().create_timer(5.0).timeout
		update_status("✅ Mundo gerado (método alternativo)!", Color.GREEN)
	else:
		update_status("❌ Método de geração não encontrado!", Color.RED)

func update_status(message: String, color: Color = Color.WHITE):
	"""Atualiza status"""
	if status_label:
		status_label.text = message
		status_label.add_theme_color_override("font_color", color)
	print("📢 Status: ", message)

func update_values_display():
	"""Atualiza visualização de valores"""
	if not values_display:
		return
	
	var text = "[color=yellow]🌍 Configurações Atuais[/color]\n\n"
	
	# Valores do WorldManager
	if world_manager:
		text += "[color=cyan]WorldManager:[/color]\n"
		text += "• Qualidade: " + str(get_property_safe(world_manager, "terrain_quality", 0.8)) + "\n"
		text += "• Recursos: " + str(get_property_safe(world_manager, "resource_abundance", 0.4)) + "\n"
		text += "• Vegetação: " + str(get_property_safe(world_manager, "vegetation_density", 0.5)) + "\n"
		text += "• Separação: " + str(get_property_safe(world_manager, "resource_object_separation", 2)) + "\n"
		text += "• Tamanho: " + str(get_property_safe(world_manager, "map_size", 128)) + "\n\n"
	
	# Valores do TerrainGenerator
	if terrain_generator:
		text += "[color=green]TerrainGenerator:[/color]\n"
		text += "• Octaves: " + str(get_property_safe(terrain_generator, "noise_octaves", 4)) + "\n"
		text += "• Frequência: " + str(get_property_safe(terrain_generator, "noise_frequency", 0.03)) + "\n"
		text += "• Tipo: " + str(get_property_safe(terrain_generator, "terrain_type", "Auto")) + "\n"
		text += "• Seed: " + str(get_property_safe(terrain_generator, "terrain_seed", 0)) + "\n\n"
	
	# Valores do ResourceGenerator
	if resource_generator:
		text += "[color=orange]ResourceGenerator:[/color]\n"
		text += "• Densidade: " + str(get_property_safe(resource_generator, "rock_formation_density", 0.08)) + "\n"
		text += "• Min Size: " + str(get_property_safe(resource_generator, "min_formation_size", 6)) + "\n"
		text += "• Max Size: " + str(get_property_safe(resource_generator, "max_formation_size", 25)) + "\n\n"
	
	# Valores do ObjectGenerator
	if object_generator:
		text += "[color=lime]ObjectGenerator:[/color]\n"
		text += "• Grama: " + str(get_property_safe(object_generator, "grass_density", 0.06)) + "\n"
		text += "• Árvores: " + str(get_property_safe(object_generator, "tree_density", 0.03)) + "\n"
		text += "• Arbustos: " + str(get_property_safe(object_generator, "bush_density", 0.015)) + "\n"
	
	values_display.text = text

func get_property_safe(node: Node, property: String, default_value):
	"""Obtém propriedade de forma segura"""
	if node and property in node:
		return node.get(property)
	return default_value
