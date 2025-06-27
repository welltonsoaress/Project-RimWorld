@tool
extends Control

# CRIE MANUALMENTE ESTES NÓS COMO FILHOS:
# - MainPanel (Panel)
#   - VBox (VBoxContainer) 
#     - PresetDropdown (OptionButton)
#     - GenerateButton (Button)
#     - StatusLabel (Label)

# Referências (configure no Inspector)
@export var main_panel: Panel
@export var preset_dropdown: OptionButton  
@export var generate_button: Button
@export var status_label: Label

var world_manager: Node
var current_preset: String = ""

var simple_presets = {
	"balanced": {
		"name": "🏰 Balanced Empire",
		"terrain_quality": 0.7,
		"resource_abundance": 0.6,
		"vegetation_density": 0.4
	},
	"survival": {
		"name": "🗡️ Harsh Survival",
		"terrain_quality": 0.9,
		"resource_abundance": 0.25,
		"vegetation_density": 0.7
	},
	"explorer": {
		"name": "🌿 Peaceful Explorer", 
		"terrain_quality": 0.8,
		"resource_abundance": 0.7,
		"vegetation_density": 0.8
	}
}

func _ready():
	print("🎨 Interface simples iniciada")
	setup_interface()
	find_world_manager()
	populate_presets()

func setup_interface():
	"""Configura interface básica"""
	if main_panel:
		main_panel.position = Vector2(get_viewport().get_visible_rect().size.x - 300, 20)
		main_panel.size = Vector2(280, 200)
	
	if preset_dropdown:
		preset_dropdown.item_selected.connect(_on_preset_selected)
	
	if generate_button:
		generate_button.pressed.connect(_on_generate_pressed)
	
	if status_label:
		status_label.text = "✅ Pronto"

func find_world_manager():
	"""Encontra WorldManager"""
	var world_nodes = get_tree().get_nodes_in_group("world_manager")
	if world_nodes.size() > 0:
		world_manager = world_nodes[0]
		print("✅ WorldManager encontrado")
	else:
		world_manager = get_tree().root.get_node_or_null("Main")
		print("✅ Main encontrado como WorldManager")

func populate_presets():
	"""Popula dropdown de presets"""
	if not preset_dropdown:
		return
		
	preset_dropdown.clear()
	preset_dropdown.add_item("Selecione um preset...")
	
	for preset_key in simple_presets:
		var preset = simple_presets[preset_key]
		preset_dropdown.add_item(preset["name"])

func _on_preset_selected(index: int):
	"""Quando preset é selecionado"""
	if index == 0:
		return
		
	var preset_keys = simple_presets.keys()
	var selected_key = preset_keys[index - 1]
	var preset = simple_presets[selected_key]
	
	current_preset = selected_key
	print("🎯 Preset selecionado: ", preset["name"])
	
	apply_preset(preset)
	update_status("Preset aplicado: " + preset["name"])

func apply_preset(preset: Dictionary):
	"""Aplica preset ao WorldManager"""
	if not world_manager:
		return
		
	# Aplica configurações
	set_property_safe(world_manager, "terrain_quality", preset.get("terrain_quality", 0.8))
	set_property_safe(world_manager, "resource_abundance", preset.get("resource_abundance", 0.4))
	set_property_safe(world_manager, "vegetation_density", preset.get("vegetation_density", 0.5))

func set_property_safe(node: Node, property: String, value):
	"""Define propriedade de forma segura"""
	if node and property in node:
		node.set(property, value)
		print("✅ ", property, " = ", value)

func _on_generate_pressed():
	"""Gera mundo"""
	update_status("🚀 Gerando...")
	
	if world_manager:
		if world_manager.has_method("generate_complete_world"):
			world_manager.generate_complete_world()
		elif world_manager.has_method("generate_world"):
			world_manager.set("generate_world", true)
		else:
			print("❌ Método de geração não encontrado")
	
	await get_tree().create_timer(3.0).timeout
	update_status("✅ Gerado!")

func update_status(message: String):
	"""Atualiza status"""
	if status_label:
		status_label.text = message
	print("📢 ", message)
