@tool
extends Control

# BOTÃO PARA CRIAR A INTERFACE
@export var create_interface: bool = false:
	set(value):
		if value and Engine.is_editor_hint():
			create_interface = false
			create_full_scene()

func create_full_scene():
	print("🏗️ CRIANDO ESTRUTURA COMPLETA DA CENA...")
	
	# Limpa nós existentes (exceto este script)
	for child in get_children():
		child.queue_free()
	
	# Aguarda limpeza
	if Engine.is_editor_hint():
		await get_tree().process_frame
	
	# Configura nó raiz
	name = "PresetUI"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Background
	var background = ColorRect.new()
	background.name = "Background"
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0, 0, 0, 0.3)
	add_child(background)
	
	# MainPanel
	var main_panel = Panel.new()
	main_panel.name = "MainPanel"
	main_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	main_panel.position = Vector2(-420, 20)
	main_panel.size = Vector2(400, 660)
	
	# Estilo do painel
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.9)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.3, 0.3, 0.3, 1)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	main_panel.add_theme_stylebox_override("panel", style)
	
	add_child(main_panel)
	
	# ScrollContainer
	var scroll = ScrollContainer.new()
	scroll.name = "ScrollContainer"
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.add_theme_constant_override("margin_left", 10)
	scroll.add_theme_constant_override("margin_right", 10)
	scroll.add_theme_constant_override("margin_top", 10)
	scroll.add_theme_constant_override("margin_bottom", 10)
	main_panel.add_child(scroll)
	
	# VBoxContainer principal
	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.add_theme_constant_override("separation", 15)
	scroll.add_child(vbox)
	
	# === CRIANDO TODOS OS ELEMENTOS ===
	
	# Título
	var title = Label.new()
	title.name = "Title"
	title.text = "🌍 Gerador de Mundos Procedurais"
	title.add_theme_font_size_override("font_size", 20)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	# Seção Presets
	create_preset_section(vbox)
	
	# Separador 1
	var sep1 = HSeparator.new()
	sep1.name = "HSeparator1"
	vbox.add_child(sep1)
	
	# Configurações básicas
	create_basic_settings(vbox)
	
	# Separador 2
	var sep2 = HSeparator.new()
	sep2.name = "HSeparator2"
	vbox.add_child(sep2)
	
	# Controles de geração
	create_generation_controls(vbox)
	
	# Separador 3
	var sep3 = HSeparator.new()
	sep3.name = "HSeparator3"
	vbox.add_child(sep3)
	
	# Seção de valores
	create_values_section(vbox)
	
	# Seção avançada
	var sep4 = HSeparator.new()
	sep4.name = "HSeparator4"
	vbox.add_child(sep4)
	
	create_advanced_section(vbox)
	
	print("✅ ESTRUTURA CRIADA COM SUCESSO!")
	print("📋 Agora:")
	print("   1. Salve a cena como 'PresetUI.tscn'")
	print("   2. Remova este script")
	print("   3. Anexe o WorldPresetController.gd")

func create_preset_section(parent: VBoxContainer):
	var preset_section = VBoxContainer.new()
	preset_section.name = "PresetSection"
	preset_section.add_theme_constant_override("separation", 8)
	parent.add_child(preset_section)
	
	var preset_label = Label.new()
	preset_label.name = "PresetLabel"
	preset_label.text = "🎯 Estilo de Jogo"
	preset_label.add_theme_font_size_override("font_size", 16)
	preset_section.add_child(preset_label)
	
	var preset_dropdown = OptionButton.new()
	preset_dropdown.name = "PresetDropdown"
	preset_dropdown.text = "Selecione um estilo..."
	preset_dropdown.add_theme_font_size_override("font_size", 14)
	preset_dropdown.fit_to_longest_item = false
	preset_section.add_child(preset_dropdown)
	
	var preset_desc = Label.new()
	preset_desc.name = "PresetDescription"
	preset_desc.text = "Escolha um estilo para configurar automaticamente o mundo"
	preset_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preset_desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
	preset_section.add_child(preset_desc)

func create_basic_settings(parent: VBoxContainer):
	var basic_settings = VBoxContainer.new()
	basic_settings.name = "BasicSettings"
	basic_settings.add_theme_constant_override("separation", 8)
	parent.add_child(basic_settings)
	
	var settings_label = Label.new()
	settings_label.name = "SettingsLabel"
	settings_label.text = "⚙️ Configurações Básicas"
	settings_label.add_theme_font_size_override("font_size", 16)
	basic_settings.add_child(settings_label)
	
	# === SIZE CONTAINER ===
	var size_container = VBoxContainer.new()
	size_container.name = "SizeContainer"
	size_container.add_theme_constant_override("separation", 4)
	basic_settings.add_child(size_container)
	
	var size_label = Label.new()
	size_label.name = "SizeLabel"
	size_label.text = "Tamanho do Mapa:"
	size_container.add_child(size_label)
	
	var size_dropdown = OptionButton.new()
	size_dropdown.name = "SizeDropdown"
	size_dropdown.add_theme_font_size_override("font_size", 14)
	size_container.add_child(size_dropdown)
	
	# === TERRAIN CONTAINER ===
	var terrain_container = VBoxContainer.new()
	terrain_container.name = "TerrainContainer"
	terrain_container.add_theme_constant_override("separation", 4)
	basic_settings.add_child(terrain_container)
	
	var terrain_label = Label.new()
	terrain_label.name = "TerrainLabel"
	terrain_label.text = "Tipo de Terreno:"
	terrain_container.add_child(terrain_label)
	
	var terrain_dropdown = OptionButton.new()
	terrain_dropdown.name = "TerrainDropdown"
	terrain_dropdown.add_theme_font_size_override("font_size", 14)
	terrain_container.add_child(terrain_dropdown)
	
	# === SEED CONTAINER ===
	var seed_container = HBoxContainer.new()
	seed_container.name = "SeedContainer"
	seed_container.add_theme_constant_override("separation", 8)
	basic_settings.add_child(seed_container)
	
	var seed_label = Label.new()
	seed_label.name = "SeedLabel"
	seed_label.text = "Seed:"
	seed_label.custom_minimum_size = Vector2(80, 0)
	seed_container.add_child(seed_label)
	
	var seed_input = SpinBox.new()
	seed_input.name = "SeedInput"
	seed_input.max_value = 999999999
	seed_input.step = 1
	seed_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	seed_container.add_child(seed_input)
	
	var random_seed_btn = Button.new()
	random_seed_btn.name = "RandomSeedButton"
	random_seed_btn.text = "🎲"
	random_seed_btn.custom_minimum_size = Vector2(40, 0)
	random_seed_btn.tooltip_text = "Gerar seed aleatório"
	seed_container.add_child(random_seed_btn)

func create_generation_controls(parent: VBoxContainer):
	var gen_controls = VBoxContainer.new()
	gen_controls.name = "GenerationControls"
	gen_controls.add_theme_constant_override("separation", 10)
	parent.add_child(gen_controls)
	
	var controls_label = Label.new()
	controls_label.name = "ControlsLabel"
	controls_label.text = "🚀 Controles de Geração"
	controls_label.add_theme_font_size_override("font_size", 16)
	gen_controls.add_child(controls_label)
	
	var generate_btn = Button.new()
	generate_btn.name = "GenerateButton"
	generate_btn.text = "🌍 Gerar Mundo Completo"
	generate_btn.add_theme_font_size_override("font_size", 16)
	generate_btn.custom_minimum_size = Vector2(0, 50)
	gen_controls.add_child(generate_btn)
	
	# === ACTIONS CONTAINER ===
	var actions_container = HBoxContainer.new()
	actions_container.name = "ActionsContainer"
	actions_container.add_theme_constant_override("separation", 5)
	gen_controls.add_child(actions_container)
	
	var regen_btn = Button.new()
	regen_btn.name = "RegenerateObjectsBtn"
	regen_btn.text = "🌿 Só Objetos"
	regen_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	regen_btn.tooltip_text = "Regenera apenas vegetação"
	actions_container.add_child(regen_btn)
	
	var test_btn = Button.new()
	test_btn.name = "TestQualityBtn"
	test_btn.text = "🔍 Testar"
	test_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	test_btn.tooltip_text = "Verifica conflitos e qualidade"
	actions_container.add_child(test_btn)
	
	var clear_btn = Button.new()
	clear_btn.name = "ClearAllBtn"
	clear_btn.text = "🧹 Limpar"
	clear_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clear_btn.tooltip_text = "Remove todos os elementos"
	actions_container.add_child(clear_btn)
	
	var status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.text = "✅ Pronto para gerar"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_color_override("font_color", Color(0, 1, 0, 1))
	gen_controls.add_child(status_label)

func create_values_section(parent: VBoxContainer):
	var values_section = VBoxContainer.new()
	values_section.name = "ValuesSection"
	values_section.add_theme_constant_override("separation", 8)
	parent.add_child(values_section)
	
	var values_label = Label.new()
	values_label.name = "ValuesLabel"
	values_label.text = "📊 Valores Atuais"
	values_label.add_theme_font_size_override("font_size", 16)
	values_section.add_child(values_label)
	
	var values_display = RichTextLabel.new()
	values_display.name = "ValuesDisplay"
	values_display.custom_minimum_size = Vector2(0, 200)
	values_display.bbcode_enabled = true
	values_display.fit_content = true
	values_display.text = "[color=yellow]Carregando valores...[/color]"
	values_section.add_child(values_display)

func create_advanced_section(parent: VBoxContainer):
	var advanced_section = VBoxContainer.new()
	advanced_section.name = "AdvancedSection"
	advanced_section.add_theme_constant_override("separation", 8)
	parent.add_child(advanced_section)
	
	var advanced_label = Label.new()
	advanced_label.name = "AdvancedLabel"
	advanced_label.text = "🔧 Opções Avançadas"
	advanced_label.add_theme_font_size_override("font_size", 16)
	advanced_section.add_child(advanced_label)
	
	var advanced_container = GridContainer.new()
	advanced_container.name = "AdvancedContainer"
	advanced_container.columns = 2
	advanced_container.add_theme_constant_override("h_separation", 10)
	advanced_container.add_theme_constant_override("v_separation", 5)
	advanced_section.add_child(advanced_container)
	
	# Botões avançados
	var show_shader_btn = Button.new()
	show_shader_btn.name = "ShowShaderBtn"
	show_shader_btn.text = "🎨 Mostrar Shader"
	show_shader_btn.tooltip_text = "Ativa/desativa visualização do shader"
	advanced_container.add_child(show_shader_btn)
	
	var show_tiles_btn = Button.new()
	show_tiles_btn.name = "ShowTilesBtn"
	show_tiles_btn.text = "🗂️ Mostrar Tiles"
	show_tiles_btn.tooltip_text = "Ativa/desativa visualização dos tiles"
	advanced_container.add_child(show_tiles_btn)
	
	var debug_btn = Button.new()
	debug_btn.name = "DebugBtn"
	debug_btn.text = "🐛 Debug"
	debug_btn.tooltip_text = "Mostra informações de debug"
	advanced_container.add_child(debug_btn)
	
	var export_btn = Button.new()
	export_btn.name = "ExportBtn"
	export_btn.text = "💾 Exportar"
	export_btn.tooltip_text = "Exporta configuração atual"
	advanced_container.add_child(export_btn)
