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
@onready var regenerate_objects_btn: Button = $MainPanel/ScrollContainer/VBoxContainer/GenerationControls/ActionsContainer/RegenerateObjectsBtn
@onready var test_quality_btn: Button = $MainPanel/ScrollContainer/VBoxContainer/GenerationControls/ActionsContainer/TestQualityBtn
@onready var clear_all_btn: Button = $MainPanel/ScrollContainer/VBoxContainer/GenerationControls/ActionsContainer/ClearAllBtn
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
	# Verifica se todos os nós da UI foram encontrados
	if not verify_ui_nodes():
		update_status("❌ Erro: Alguns nós da UI não foram encontrados", Color.RED)
		return
	
	await get_tree().process_frame
	setup_ui()
	find_components()
	connect_signals()
	populate_dropdowns()
	update_values_display()
	update_status("✅ Interface carregada - Pronto para gerar", Color.GREEN)

func verify_ui_nodes() -> bool:
	"""Verifica se todos os nós da UI foram encontrados"""
	var all_nodes_found = true
	var nodes_to_check = [
		{"node": preset_dropdown, "name": "PresetDropdown"},
		{"node": size_dropdown, "name": "SizeDropdown"},
		{"node": terrain_dropdown, "name": "TerrainDropdown"},
		{"node": seed_input, "name": "SeedInput"},
		{"node": random_seed_button, "name": "RandomSeedButton"},
		{"node": generate_button, "name": "GenerateButton"},
		{"node": status_label, "name": "StatusLabel"},
		{"node": values_display, "name": "ValuesDisplay"},
		{"node": regenerate_objects_btn, "name": "RegenerateObjectsBtn"},
		{"node": test_quality_btn, "name": "TestQualityBtn"},
		{"node": clear_all_btn, "name": "ClearAllBtn"},
		{"node": show_shader_btn, "name": "ShowShaderBtn"},
		{"node": show_tiles_btn, "name": "ShowTilesBtn"},
		{"node": debug_btn, "name": "DebugBtn"},
		{"node": export_btn, "name": "ExportBtn"}
	]
	
	for node_info in nodes_to_check:
		if not node_info["node"]:
			print("❌ Nó não encontrado: ", node_info["name"])
			all_nodes_found = false
	
	return all_nodes_found

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
	if nodes.size() > 0:
		print("✅ ", group_name.capitalize(), " encontrado: ", nodes[0].get_path())
		return nodes[0]
	print("❌ ", group_name.capitalize(), " não encontrado")
	return null

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
	if not preset_dropdown or not size_dropdown or not terrain_dropdown or not random_seed_button or not seed_input or not generate_button or not regenerate_objects_btn or not test_quality_btn or not clear_all_btn or not show_shader_btn or not show_tiles_btn or not debug_btn or not export_btn:
		update_status("❌ Erro: Alguns nós da UI não estão disponíveis para conectar sinais", Color.RED)
		return
	
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
	if not preset_dropdown or not size_dropdown or not terrain_dropdown:
		update_status("❌ Erro: Dropdowns não encontrados", Color.RED)
		return
	
	print("📋 Populando dropdowns...")
	
	# Preset dropdown
	preset_dropdown.clear()
	preset_dropdown.add_item("Selecione um estilo...", 0)
	var preset_index = 1
	for preset_key in world_presets:
		var preset = world_presets[preset_key]
		preset_dropdown.add_item(preset["name"], preset_index)
		preset_index += 1
	
	# Size dropdown
	size_dropdown.clear()
	size_dropdown.add_item("Selecione um tamanho...", 0)
	var size_index = 1
	for size_key in map_sizes:
		@warning_ignore("shadowed_variable_base_class")
		var size = map_sizes[size_key]
		size_dropdown.add_item(size["name"], size_index)
		size_index += 1
	
	# Terrain dropdown
	terrain_dropdown.clear()
	terrain_dropdown.add_item("Selecione um tipo de terreno...", 0)
	for i in range(terrain_types.size()):
		terrain_dropdown.add_item(terrain_types[i], i + 1)
	
	update_values_display()
	update_status("✅ Dropdowns populados", Color.GREEN)

func update_values_display():
	"""Atualiza o display com os valores atuais do preset"""
	if not values_display:
		update_status("❌ Erro: ValuesDisplay não encontrado", Color.RED)
		return
	
	var text = "[b]Configurações Atuais:[/b]\n"
	if current_preset != "" and world_presets.has(current_preset):
		var preset = world_presets[current_preset]
		text += "[b]Preset:[/b] %s\n" % preset["name"]
		text += "[b]Descrição:[/b] %s\n" % preset["description"]
		text += "[b]Tipo de Terreno:[/b] %s\n" % preset["terrain_type"]
		for key in preset["config"]:
			text += "%s: %s\n" % [key.capitalize(), str(preset["config"][key])]
	else:
		text += "Nenhum preset selecionado\n"
	
	if world_manager:
		text += "\n[b]WorldManager:[/b]\n"
		text += "Map Size: %s\n" % world_manager.map_size
		text += "World Seed: %s\n" % world_manager.world_seed
	
	values_display.text = text

func update_status(message: String, color: Color = Color.WHITE):
	"""Atualiza a mensagem de status"""
	if status_label:
		status_label.text = message
		status_label.modulate = color
	print("📢 ", message)

func _on_preset_selected(index: int):
	"""Quando um preset é selecionado"""
	if index == 0:
		update_status("⚠️ Selecione um preset válido", Color.YELLOW)
		return
	
	var preset_keys = world_presets.keys()
	var selected_key = preset_keys[index - 1]
	current_preset = selected_key
	var preset = world_presets[selected_key]
	
	print("🎯 Preset selecionado: ", preset["name"])
	apply_preset(preset)
	update_values_display()
	update_status("✅ Preset aplicado: " + preset["name"], Color.GREEN)

func apply_preset(preset: Dictionary):
	"""Aplica as configurações do preset ao WorldManager"""
	if not world_manager:
		update_status("❌ WorldManager não encontrado", Color.RED)
		return
	
	var config = preset["config"]
	for key in config:
		set_property_safe(world_manager, key, config[key])
	
	# Aplica tipo de terreno
	set_property_safe(world_manager, "world_type", preset["terrain_type"])
	
	# Aplica configurações dinamicamente
	if world_manager.has_method("apply_dynamic_settings"):
		world_manager.apply_dynamic_settings()
	else:
		update_status("⚠️ Método apply_dynamic_settings não encontrado", Color.YELLOW)

func _on_size_selected(index: int):
	"""Quando um tamanho de mapa é selecionado"""
	if index == 0:
		update_status("⚠️ Selecione um tamanho válido", Color.YELLOW)
		return
	
	var size_keys = map_sizes.keys()
	var selected_size = map_sizes[size_keys[index - 1]]
	
	if world_manager:
		set_property_safe(world_manager, "map_size", selected_size["width"])
		update_values_display()
		update_status("✅ Tamanho do mapa selecionado: " + selected_size["name"], Color.GREEN)

func _on_terrain_type_selected(index: int):
	"""Quando um tipo de terreno é selecionado"""
	if index == 0:
		update_status("⚠️ Selecione um tipo de terreno válido", Color.YELLOW)
		return
	
	var selected_terrain = terrain_types[index - 1]
	if world_manager:
		set_property_safe(world_manager, "world_type", selected_terrain)
		update_values_display()
		update_status("✅ Tipo de terreno selecionado: " + selected_terrain, Color.GREEN)

func _on_random_seed_pressed():
	"""Define uma seed aleatória"""
	if seed_input:
		seed_input.value = randi()
		update_status("✅ Seed aleatória gerada", Color.GREEN)

func _on_seed_changed(value: float):
	"""Quando a seed é alterada"""
	if world_manager:
		set_property_safe(world_manager, "world_seed", int(value))
		update_values_display()
		update_status("✅ Seed atualizada: " + str(int(value)), Color.GREEN)

func _on_generate_pressed():
	"""Gera o mundo"""
	if not world_manager:
		update_status("❌ WorldManager não encontrado", Color.RED)
		return
	
	if current_preset == "":
		update_status("⚠️ Selecione um preset antes de gerar", Color.YELLOW)
		return
	
	if is_generating:
		update_status("⚠️ Geração em progresso, aguarde...", Color.YELLOW)
		return
	
	is_generating = true
	update_status("🚀 Gerando mundo...", Color.YELLOW)
	
	if world_manager.has_method("generate_complete_world"):
		world_manager.call_deferred("generate_complete_world")
	else:
		update_status("❌ Método generate_complete_world não encontrado", Color.RED)
	
	# Aguarda a geração (ajuste o tempo conforme necessário)
	await get_tree().create_timer(3.0).timeout
	is_generating = false
	update_status("✅ Mundo gerado!", Color.GREEN)

func _on_regenerate_objects_pressed():
	"""Regenera apenas os objetos"""
	if not world_manager:
		update_status("❌ WorldManager não encontrado", Color.RED)
		return
	
	if world_manager.has_method("regenerate_objects_only"):
		world_manager.call_deferred("regenerate_objects_only")
		update_status("✅ Objetos regenerados", Color.GREEN)
	else:
		update_status("⚠️ Método regenerate_objects_only não encontrado", Color.YELLOW)

func _on_test_quality_pressed():
	"""Testa a qualidade da geração"""
	if not world_manager:
		update_status("❌ WorldManager não encontrado", Color.RED)
		return
	
	if world_manager.has_method("verify_generation_quality"):
		world_manager.call_deferred("verify_generation_quality")
		update_status("✅ Verificação de qualidade concluída", Color.GREEN)
	else:
		update_status("⚠️ Método verify_generation_quality não encontrado", Color.YELLOW)

func _on_clear_all_pressed():
	"""Limpa o mundo"""
	if not world_manager:
		update_status("❌ WorldManager não encontrado", Color.RED)
		return
	
	if world_manager.has_method("clear_world"):
		world_manager.call_deferred("clear_world")
		update_status("✅ Mundo limpo", Color.GREEN)
	else:
		update_status("⚠️ Método clear_world não encontrado", Color.YELLOW)

func _on_show_shader_pressed():
	"""Alterna visibilidade do shader"""
	if shader_controller:
		shader_visible = not shader_visible
		shader_controller.visible = shader_visible
		update_status("✅ Shader " + ("visível" if shader_visible else "oculto"), Color.GREEN)
	else:
		update_status("❌ ShaderController não encontrado", Color.RED)

func _on_show_tiles_pressed():
	"""Alterna visibilidade dos tiles"""
	if terrain_generator and resource_generator and object_generator:
		tiles_visible = not tiles_visible
		terrain_generator.visible = tiles_visible
		resource_generator.visible = tiles_visible
		object_generator.visible = tiles_visible
		update_status("✅ Tiles " + ("visíveis" if tiles_visible else "ocultos"), Color.GREEN)
	else:
		update_status("❌ Geradores de tiles não encontrados", Color.RED)

func _on_debug_pressed():
	"""Ativa debug"""
	if world_manager and world_manager.has_method("analyze_world_improved"):
		world_manager.call_deferred("analyze_world_improved")
		update_status("✅ Análise de debug concluída", Color.GREEN)
	else:
		update_status("❌ Método analyze_world_improved ou WorldManager não encontrado", Color.RED)

func _on_export_pressed():
	"""Exporta o mapa (implementação pendente)"""
	update_status("⚠️ Exportação não implementada", Color.YELLOW)
	# Adicione aqui a lógica para exportar o mapa, se necessário

func set_property_safe(node: Node, property: String, value):
	"""Define propriedade de forma segura"""
	if node and property in node:
		node.set(property, value)
		print("✅ ", property, " = ", value)
	else:
		@warning_ignore("incompatible_ternary")
		print("❌ Propriedade ", property, " não encontrada no node ", node.get_path() if node else "null")
