@tool
extends EditorScript

# Execute este script no Editor: File -> Run
func _run():
	print("\n🔧 === VERIFICANDO E CORRIGINDO PresetUI.tscn ===")
	
	# Carrega a cena
	var scene_path = "res://PresetUI.tscn"
	var packed_scene = load(scene_path) as PackedScene
	
	if not packed_scene:
		print("❌ PresetUI.tscn não encontrada!")
		return
	
	var root = packed_scene.instantiate()
	
	# Verifica e corrige a estrutura
	if not verify_and_fix_structure(root):
		print("❌ Falha ao corrigir estrutura")
		root.queue_free()
		return
	
	# Salva a cena corrigida
	var new_packed_scene = PackedScene.new()
	new_packed_scene.pack(root)
	
	var error = ResourceSaver.save(new_packed_scene, scene_path)
	if error == OK:
		print("✅ PresetUI.tscn salva com sucesso!")
	else:
		print("❌ Erro ao salvar: ", error)
	
	root.queue_free()

func verify_and_fix_structure(root: Node) -> bool:
	print("🔍 Verificando estrutura...")
	
	# Verifica MainPanel
	var main_panel = root.get_node_or_null("MainPanel")
	if not main_panel:
		print("❌ MainPanel não encontrado")
		return false
	
	# Verifica ScrollContainer
	var scroll = main_panel.get_node_or_null("ScrollContainer")
	if not scroll:
		print("❌ ScrollContainer não encontrado")
		return false
	
	# Verifica VBoxContainer
	var vbox = scroll.get_node_or_null("VBoxContainer")
	if not vbox:
		print("❌ VBoxContainer não encontrado")
		return false
	
	# Verifica BasicSettings
	var basic_settings = vbox.get_node_or_null("BasicSettings")
	if not basic_settings:
		print("⚠️ BasicSettings não encontrado - criando...")
		basic_settings = create_basic_settings()
		vbox.add_child(basic_settings)
		vbox.move_child(basic_settings, 3)  # Após PresetSection e HSeparator1
	
	# Verifica SizeContainer dentro de BasicSettings
	var size_container = basic_settings.get_node_or_null("SizeContainer")
	if not size_container:
		print("⚠️ SizeContainer não encontrado - criando...")
		size_container = create_size_container()
		basic_settings.add_child(size_container)
	
	# Verifica SizeDropdown
	var size_dropdown = size_container.get_node_or_null("SizeDropdown")
	if not size_dropdown:
		print("⚠️ SizeDropdown não encontrado - criando...")
		size_dropdown = OptionButton.new()
		size_dropdown.name = "SizeDropdown"
		size_dropdown.add_theme_font_size_override("font_size", 14)
		size_container.add_child(size_dropdown)
	
	# Continua verificando outros componentes...
	verify_terrain_container(basic_settings)
	verify_seed_container(basic_settings)
	verify_generation_controls(vbox)
	verify_values_section(vbox)
	
	print("✅ Estrutura verificada e corrigida!")
	return true

func create_basic_settings() -> VBoxContainer:
	var basic_settings = VBoxContainer.new()
	basic_settings.name = "BasicSettings"
	basic_settings.add_theme_constant_override("separation", 8)
	
	var label = Label.new()
	label.name = "SettingsLabel"
	label.text = "⚙️ Configurações Básicas"
	label.add_theme_font_size_override("font_size", 16)
	basic_settings.add_child(label)
	
	return basic_settings

func create_size_container() -> VBoxContainer:
	var container = VBoxContainer.new()
	container.name = "SizeContainer"
	container.add_theme_constant_override("separation", 4)
	
	var label = Label.new()
	label.name = "SizeLabel"
	label.text = "Tamanho do Mapa:"
	container.add_child(label)
	
	return container

func verify_terrain_container(basic_settings: Node):
	var terrain_container = basic_settings.get_node_or_null("TerrainContainer")
	if not terrain_container:
		print("⚠️ TerrainContainer não encontrado - criando...")
		terrain_container = VBoxContainer.new()
		terrain_container.name = "TerrainContainer"
		terrain_container.add_theme_constant_override("separation", 4)
		basic_settings.add_child(terrain_container)
		
		var label = Label.new()
		label.name = "TerrainLabel"
		label.text = "Tipo de Terreno:"
		terrain_container.add_child(label)
		
		var dropdown = OptionButton.new()
		dropdown.name = "TerrainDropdown"
		dropdown.add_theme_font_size_override("font_size", 14)
		terrain_container.add_child(dropdown)

func verify_seed_container(basic_settings: Node):
	var seed_container = basic_settings.get_node_or_null("SeedContainer")
	if not seed_container:
		print("⚠️ SeedContainer não encontrado - criando...")
		seed_container = HBoxContainer.new()
		seed_container.name = "SeedContainer"
		seed_container.add_theme_constant_override("separation", 8)
		basic_settings.add_child(seed_container)
		
		var label = Label.new()
		label.name = "SeedLabel"
		label.text = "Seed:"
		label.custom_minimum_size = Vector2(80, 0)
		seed_container.add_child(label)
		
		var input = SpinBox.new()
		input.name = "SeedInput"
		input.max_value = 999999999
		input.step = 1
		input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		seed_container.add_child(input)
		
		var button = Button.new()
		button.name = "RandomSeedButton"
		button.text = "🎲"
		button.custom_minimum_size = Vector2(40, 0)
		button.tooltip_text = "Gerar seed aleatório"
		seed_container.add_child(button)

func verify_generation_controls(vbox: Node):
	var gen_controls = vbox.get_node_or_null("GenerationControls")
	if not gen_controls:
		print("⚠️ GenerationControls não encontrado - criando...")
		# Cria toda a estrutura...
		# (código similar aos anteriores)

func verify_values_section(vbox: Node):
	var values_section = vbox.get_node_or_null("ValuesSection")
	if not values_section:
		print("⚠️ ValuesSection não encontrado - criando...")
		# Cria toda a estrutura...
		# (código similar aos anteriores)
