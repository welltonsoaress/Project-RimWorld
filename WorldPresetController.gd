@tool
class_name WorldPresetController
extends Control

# === VARIÁVEIS DE UI (sem @onready) ===
var preset_dropdown: OptionButton
var size_dropdown: OptionButton
var terrain_dropdown: OptionButton
var seed_input: SpinBox
var random_seed_button: Button
var generate_button: Button
var status_label: Label
var values_display: RichTextLabel
var regenerate_objects_btn: Button
var test_quality_btn: Button
var clear_all_btn: Button
var show_shader_btn: Button
var show_tiles_btn: Button
var debug_btn: Button
var export_btn: Button

# === COMPONENTES DO SISTEMA ===
var world_manager: Node2D
var terrain_generator: TileMapLayer
var resource_generator: TileMapLayer
var object_generator: TileMapLayer
var shader_controller: Sprite2D

# === ESTADO ===
var current_preset: String = ""
var shader_visible: bool = true
var tiles_visible: bool = true

# === CONFIGURAÇÕES SIMPLIFICADAS ===
var world_presets = {
	"balanced": {
		"name": "🏰 Balanced Empire",
		"config": {"terrain_quality": 0.7, "resource_abundance": 0.6}
	},
	"harsh": {
		"name": "🗡️ Harsh Survival", 
		"config": {"terrain_quality": 0.9, "resource_abundance": 0.25}
	},
	"peaceful": {
		"name": "🌿 Peaceful Explorer",
		"config": {"terrain_quality": 0.8, "resource_abundance": 0.7}
	}
}

func _ready():
	print("🚀 Iniciando WorldPresetController...")
	
	# Se não temos estrutura de UI, cria uma básica
	if get_child_count() == 0:
		print("⚠️ Sem estrutura de UI - criando interface básica...")
		create_basic_ui()
	else:
		print("✅ Estrutura de UI detectada - buscando nós...")
		find_ui_nodes()
	
	# Busca componentes do mundo
	find_world_components()
	
	# Conecta sinais
	connect_available_signals()
	
	print("✅ WorldPresetController pronto!")

func create_basic_ui():
	"""Cria uma UI mínima funcional"""
	var panel = Panel.new()
	panel.name = "SimplePanel"
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	panel.size = Vector2(300, 400)
	add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("margin_left", 10)
	vbox.add_theme_constant_override("margin_right", 10)
	vbox.add_theme_constant_override("margin_top", 10)
	vbox.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(vbox)
	
	# Título
	var title = Label.new()
	title.text = "🌍 Gerador de Mundos"
	title.add_theme_font_size_override("font_size", 18)
	vbox.add_child(title)
	
	# Preset dropdown
	preset_dropdown = OptionButton.new()
	preset_dropdown.add_item("Selecione um preset...")
	for key in world_presets:
		preset_dropdown.add_item(world_presets[key]["name"])
	vbox.add_child(preset_dropdown)
	
	# Botão gerar
	generate_button = Button.new()
	generate_button.text = "🚀 Gerar Mundo"
	generate_button.custom_minimum_size.y = 40
	vbox.add_child(generate_button)
	
	# Status
	status_label = Label.new()
	status_label.text = "✅ Pronto"
	status_label.modulate = Color.GREEN
	vbox.add_child(status_label)
	
	# Botões debug
	var hbox = HBoxContainer.new()
	vbox.add_child(hbox)
	
	show_shader_btn = Button.new()
	show_shader_btn.text = "🎨 Shader"
	hbox.add_child(show_shader_btn)
	
	show_tiles_btn = Button.new()
	show_tiles_btn.text = "🗂️ Tiles"
	hbox.add_child(show_tiles_btn)
	
	debug_btn = Button.new()
	debug_btn.text = "🐛 Debug"
	hbox.add_child(debug_btn)

func find_ui_nodes():
	"""Busca nós da UI de forma segura e flexível"""
	# Tenta diferentes caminhos possíveis
	var possible_paths = [
		"MainPanel/ScrollContainer/VBoxContainer/PresetSection/PresetDropdown",
		"SimplePanel/VBoxContainer/OptionButton",
		"VBoxContainer/PresetDropdown",
		"PresetDropdown"
	]
	
	# Busca preset dropdown
	for path in possible_paths:
		preset_dropdown = get_node_or_null(path)
		if preset_dropdown:
			print("✅ PresetDropdown encontrado em: ", path)
			break
	
	# Busca outros componentes essenciais
	generate_button = find_node_by_type("GenerateButton", Button)
	status_label = find_node_by_type("StatusLabel", Label)
	
	# Busca componentes opcionais
	show_shader_btn = find_node_by_type("ShowShaderBtn", Button)
	show_tiles_btn = find_node_by_type("ShowTilesBtn", Button)
	debug_btn = find_node_by_type("DebugBtn", Button)

func find_node_by_type(node_name: String, type):
	"""Busca nó por nome e tipo em toda a árvore"""
	return find_node_recursive(self, node_name, type)

func find_node_recursive(node: Node, target_name: String, target_type) -> Node:
	if node.name == target_name and is_instance_of(node, target_type):
		return node
	
	for child in node.get_children():
		var result = find_node_recursive(child, target_name, target_type)
		if result != null:
			return result
	
	return null
	
func find_world_components():
	"""Busca componentes do mundo"""
	world_manager = get_tree().get_first_node_in_group("world_manager")
	if not world_manager:
		world_manager = get_node_or_null("/root/Main")
	
	terrain_generator = get_tree().get_first_node_in_group("terrain")
	resource_generator = get_tree().get_first_node_in_group("resources")
	object_generator = get_tree().get_first_node_in_group("objects")
	shader_controller = get_tree().get_first_node_in_group("shader")
	
	print("🌍 Componentes encontrados:")
	print("  - WorldManager: ", world_manager != null)
	print("  - Terrain: ", terrain_generator != null)
	print("  - Resources: ", resource_generator != null)
	print("  - Objects: ", object_generator != null)
	print("  - Shader: ", shader_controller != null)

func connect_available_signals():
	"""Conecta apenas sinais de nós que existem"""
	if preset_dropdown:
		preset_dropdown.item_selected.connect(_on_preset_selected)
	
	if generate_button:
		generate_button.pressed.connect(_on_generate_pressed)
	
	if show_shader_btn:
		show_shader_btn.pressed.connect(_on_show_shader_pressed)
	
	if show_tiles_btn:
		show_tiles_btn.pressed.connect(_on_show_tiles_pressed)
	
	if debug_btn:
		debug_btn.pressed.connect(_on_debug_pressed)

# === CALLBACKS SIMPLIFICADOS ===

func _on_preset_selected(index: int):
	if index > 0:
		var keys = world_presets.keys()
		current_preset = keys[index - 1]
		update_status("Preset: " + world_presets[current_preset]["name"], Color.GREEN)
		
		# Aplica configurações
		if world_manager:
			var config = world_presets[current_preset]["config"]
			for key in config:
				if key in world_manager:
					world_manager.set(key, config[key])

func _on_generate_pressed():
	update_status("🚀 Gerando mundo...", Color.YELLOW)
	
	if world_manager and world_manager.has_method("generate_complete_world"):
		world_manager.generate_complete_world()
	else:
		print("❌ WorldManager não encontrado ou método não existe")

func _on_show_shader_pressed():
	if shader_controller:
		shader_visible = not shader_visible
		shader_controller.visible = shader_visible

func _on_show_tiles_pressed():
	tiles_visible = not tiles_visible
	if terrain_generator:
		terrain_generator.visible = tiles_visible
	if resource_generator:
		resource_generator.visible = tiles_visible
	if object_generator:
		object_generator.visible = tiles_visible

func _on_debug_pressed():
	print("\n=== DEBUG ===")
	print("UI Nodes:")
	print("  - preset_dropdown: ", preset_dropdown != null)
	print("  - generate_button: ", generate_button != null)
	print("  - status_label: ", status_label != null)
	print("\nWorld Components:")
	print("  - world_manager: ", world_manager != null)
	print("  - terrain_generator: ", terrain_generator != null)
	print("  - shader_controller: ", shader_controller != null)
	print("==============\n")

func update_status(text: String, color: Color):
	if status_label:
		status_label.text = text
		status_label.modulate = color
	print("📢 ", text)
