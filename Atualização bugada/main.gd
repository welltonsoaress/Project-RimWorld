@tool
extends Node2D

const MAP_WIDTH = 128
const MAP_HEIGHT = 128

var is_generating := false

func _ready():
	if not Engine.is_editor_hint() and not is_generating:
		is_generating = true
		print("🎮 Iniciando geração do mapa procedural...")
		
		# PRIMEIRO: Verifica e corrige scripts se necessário
		ensure_scripts_are_loaded()
		
		setup_layers()
		# Aguarda um frame para garantir que tudo está inicializado
		await get_tree().process_frame
		generate_all()
		is_generating = false

func ensure_scripts_are_loaded():
	print("🔧 Verificando scripts dos TileMapLayers...")
	
	# Verifica TerrainMap
	var terrain = get_node_or_null("Terrain/TerrainMap")
	if terrain and terrain is TileMapLayer:
		var script = terrain.get_script()
		if not script or not script.resource_path.ends_with("layer1.gd"):
			print("🔄 Aplicando script layer1.gd ao TerrainMap...")
			var layer1_script = load("res://Terrain_map_improved.gd")
			if layer1_script:
				terrain.set_script(layer1_script)
				print("✅ Script terrain_map.gd aplicado")
			else:
				print("❌ Falha ao carregar layer1.gd")
	
	# Verifica ResourceMap
	var resource_map = get_node_or_null("Resource/ResourceMap")
	if resource_map and resource_map is TileMapLayer:
		var script = resource_map.get_script()
		if not script or not script.resource_path.ends_with("resource_map_improved.gd"):
			print("🔄 Aplicando script resource_map.gd...")
			var resource_script = load("res://resource_map_improved.gd")
			if resource_script:
				resource_map.set_script(resource_script)
				print("✅ Script resource_map.gd aplicado")
	
	# Verifica ObjectMap
	var object_map = get_node_or_null("Object/ObjectMap")
	if object_map and object_map is TileMapLayer:
		var script = object_map.get_script()
		if not script or not script.resource_path.ends_with("object_map.gd"):
			print("🔄 Aplicando script object_map.gd...")
			var object_script = load("res://object_map_improved.gd")
			if object_script:
				object_map.set_script(object_script)
				print("✅ Script object_map.gd aplicado")

func setup_layers():
	# Configura z-index das camadas para ordem correta de renderização
	if has_node("ShaderTerrain"):
		$ShaderTerrain.z_index = -1  # Shader por baixo de tudo
	if has_node("Resource/ResourceMap"):
		$Resource/ResourceMap.z_index = 1
	if has_node("Object/ObjectMap"):
		$Object/ObjectMap.z_index = 2
	
	# Garante que todos os TileMapLayers tenham a mesma configuração de tile_size
	sync_tilemap_settings()
	
	print("🔧 Camadas configuradas")

func sync_tilemap_settings():
	# Lista de todos os TileMapLayers que precisam ser sincronizados
	var tilemaps = []
	
	# Coleta todos os TileMapLayers usando busca mais robusta
	var terrain = find_terrain_map()
	var resources = find_resource_map()
	var objects = find_object_map()
	
	if terrain: tilemaps.append(terrain)
	if resources: tilemaps.append(resources)
	if objects: tilemaps.append(objects)
	
	# Sincroniza configurações entre todos os TileMapLayers
	var reference_tile_size = 32  # Tamanho padrão
	
	for tilemap in tilemaps:
		if tilemap is TileMapLayer and tilemap.tile_set:
			var tile_set = tilemap.tile_set
			if tile_set.get_source_count() > 0:
				var source = tile_set.get_source(0)
				if source is TileSetAtlasSource:
					var atlas_source = source as TileSetAtlasSource
					if atlas_source.texture_region_size.x > 0:
						reference_tile_size = int(atlas_source.texture_region_size.x)
						break
	
	print("🔄 Tile size de referência: ", reference_tile_size)
	
	# Atualiza o shader com o tamanho correto
	var shader_terrain = get_node_or_null("ShaderTerrain")
	if shader_terrain and shader_terrain.has_method("sync_with_tilemaps"):
		shader_terrain.tile_size = reference_tile_size
		shader_terrain.sync_with_tilemaps()

func generate_all():
	if is_generating:
		print("⚠️ Geração já em progresso, aguardando...")
		return
	
	is_generating = true
	print("🚀 Iniciando geração completa...")

	# 1. PRIMEIRO: Gera o terreno e salva mapData.png
	var terrain = find_terrain_map()
	if terrain:
		print("🌍 TerrainMap encontrado: ", terrain.name, " | Script: ", terrain.get_script())
		
		# Debug dos métodos disponíveis
		print("🔍 Métodos disponíveis no TerrainMap:")
		if terrain.has_method("GenerateTerrain"):
			print("  ✅ GenerateTerrain() encontrado")
		else:
			print("  ❌ GenerateTerrain() NÃO encontrado")
			
		# Tenta outros nomes de métodos possíveis
		var method_alternatives = ["generate_terrain", "generate", "_generate_terrain", "regenerate"]
		for method_name in method_alternatives:
			if terrain.has_method(method_name):
				print("  ✅ Método alternativo encontrado: ", method_name)
		
		# Tenta chamar o método
		if terrain.has_method("GenerateTerrain"):
			print("🌍 Gerando terreno...")
			terrain.GenerateTerrain()
		elif terrain.has_method("generate_terrain"):
			print("🌍 Gerando terreno (método alternativo)...")
			terrain.generate_terrain()
		elif terrain.has_method("generate"):
			print("🌍 Gerando terreno (método generate)...")
			terrain.generate()
		else:
			print("❌ Nenhum método de geração encontrado! Tentando forçar...")
			# Tenta definir a propriedade generateTerrain se existir
			if "generateTerrain" in terrain:
				terrain.generateTerrain = true
				print("🔄 Propriedade generateTerrain definida")
			else:
				print("❌ Propriedade generateTerrain não encontrada")
		
		# Aguarda mais tempo para garantir que o arquivo foi salvo
		await get_tree().create_timer(1.0).timeout
	else:
		print("❌ TerrainMap não encontrado! Procurando alternativas...")
		debug_scene_structure()
		is_generating = false
		return

	# 2. SEGUNDO: Configura o shader ANTES dos recursos (para garantir alinhamento)
	var shader_sprite = get_node_or_null("ShaderTerrain")
	if shader_sprite:
		print("🎨 Configurando ShaderTerrain...")
		# Sincroniza com TileMapLayers primeiro
		if shader_sprite.has_method("sync_with_tilemaps"):
			shader_sprite.sync_with_tilemaps()
		
		# Aguarda um pouco mais para garantir que o arquivo existe
		await get_tree().create_timer(0.5).timeout
		
		if shader_sprite.has_method("update_texture"):
			shader_sprite.update_texture()
		else:
			print("❌ ShaderTerrain sem método update_texture!")
	else:
		print("❌ ShaderTerrain não encontrado!")

	# 3. TERCEIRO: Gera recursos (agora alinhado com o shader)
	var resources = find_resource_map()
	if resources and resources.has_method("generate"):
		print("🔧 Gerando recursos...")
		resources.generate()
		await get_tree().process_frame
	else:
		print("❌ ResourceMap não encontrado!")

	# 4. QUARTO: Gera objetos (agora alinhado com o shader)
	var objects = find_object_map()
	if objects and objects.has_method("generate"):
		print("📦 Gerando objetos...")
		objects.generate()
		await get_tree().process_frame
	else:
		print("❌ ObjectMap não encontrado!")

	is_generating = false
	print("✅ Geração completa finalizada!")
	
	# Debug final
	debug_final_state()

# Função robusta para encontrar o TerrainMap
func find_terrain_map() -> TileMapLayer:
	# Lista de possíveis caminhos para o TerrainMap
	var possible_paths = [
		"Terrain/TerrainMap",
		"TerrainMap",
		"Terrain/Layer1",
		"Layer1"
	]
	
	# Tenta caminhos diretos primeiro
	for path in possible_paths:
		var node = get_node_or_null(path)
		if node and node is TileMapLayer:
			print("✅ TerrainMap encontrado em: ", path)
			return node
	
	# Busca recursiva se não encontrou
	var terrain_by_name = find_tilemap_by_name("TerrainMap")
	if terrain_by_name:
		print("✅ TerrainMap encontrado via busca recursiva: ", terrain_by_name.get_path())
		return terrain_by_name
	
	# Busca por script específico
	var terrain_by_script = find_node_with_script("layer1.gd")
	if terrain_by_script and terrain_by_script is TileMapLayer:
		print("✅ TerrainMap encontrado via script: ", terrain_by_script.get_path())
		return terrain_by_script
	
	return null

# Função robusta para encontrar o ResourceMap
func find_resource_map() -> TileMapLayer:
	var possible_paths = [
		"Resource/ResourceMap",
		"ResourceMap",
		"Resources/ResourceMap"
	]
	
	for path in possible_paths:
		var node = get_node_or_null(path)
		if node and node is TileMapLayer:
			return node
	
	var resource_by_name = find_tilemap_by_name("ResourceMap")
	if resource_by_name:
		return resource_by_name
	
	return find_node_with_script("resource_map.gd")

# Função robusta para encontrar o ObjectMap
func find_object_map() -> TileMapLayer:
	var possible_paths = [
		"Object/ObjectMap",
		"ObjectMap",
		"Objects/ObjectMap"
	]
	
	for path in possible_paths:
		var node = get_node_or_null(path)
		if node and node is TileMapLayer:
			return node
	
	var object_by_name = find_tilemap_by_name("ObjectMap")
	if object_by_name:
		return object_by_name
	
	return find_node_with_script("object_map.gd")

# Busca recursiva por nome
func find_tilemap_by_name(target_name: String) -> TileMapLayer:
	return find_tilemap_recursive(self, target_name)

func find_tilemap_recursive(node: Node, target_name: String) -> TileMapLayer:
	if node is TileMapLayer and node.name == target_name:
		return node
	
	for child in node.get_children():
		var child_result = find_tilemap_recursive(child, target_name)
		if child_result:
			return child_result
	
	return null

# Busca por script específico
func find_node_with_script(script_name: String) -> Node:
	return find_script_recursive(self, script_name)

func find_script_recursive(node: Node, script_name: String) -> Node:
	if node.get_script() and node.get_script().resource_path.ends_with(script_name):
		return node
	
	for child in node.get_children():
		var script_result = find_script_recursive(child, script_name)
		if script_result:
			return script_result
	
	return null

func debug_scene_structure():
	print("\n🔍 === ESTRUTURA DA CENA ===")
	print_tree_structure(self, 0)
	print("=== FIM ESTRUTURA ===\n")

func print_tree_structure(node: Node, level: int):
	var indent = ""
	for i in range(level):
		indent += "  "
	
	var info = indent + "📁 " + node.name + " (" + node.get_class() + ")"
	if node is TileMapLayer:
		info += " [TileMapLayer]"
	if node.get_script():
		info += " [Script: " + node.get_script().resource_path.get_file() + "]"
	
	print(info)
	
	for child in node.get_children():
		print_tree_structure(child, level + 1)

func debug_final_state():
	print("\n🔍 === DEBUG FINAL ===")
	
	# Verifica se mapData.png existe
	var file = FileAccess.open("res://mapData.png", FileAccess.READ)
	if file:
		print("✅ mapData.png existe, tamanho: ", file.get_length(), " bytes")
		file.close()
	else:
		print("❌ mapData.png não encontrado!")
	
	# Verifica shader
	var shader_sprite = get_node_or_null("ShaderTerrain")
	if shader_sprite:
		var shader_mat = shader_sprite.material
		if shader_mat and shader_mat is ShaderMaterial:
			print("✅ ShaderMaterial encontrado")
			print("  - Shader: ", shader_mat.shader != null)
			print("  - textureAtlas: ", shader_mat.get_shader_parameter("textureAtlas") != null)
			print("  - mapData: ", shader_mat.get_shader_parameter("mapData") != null)
			print("  - Sprite position: ", shader_sprite.position)
			print("  - Sprite scale: ", shader_sprite.scale)
			
			if shader_sprite.has_method("debug_shader_parameters"):
				shader_sprite.debug_shader_parameters()
		else:
			print("❌ ShaderMaterial não encontrado!")
	
	# Verifica TileMapLayers
	var terrain = find_terrain_map()
	if terrain and terrain is TileMapLayer:
		print("✅ TerrainMap encontrado")
		print("  - Position: ", terrain.position)
		print("  - Scale: ", terrain.scale)
		if terrain.tile_set:
			print("  - TileSet configurado: ", terrain.tile_set != null)
			var tile_source = terrain.tile_set.get_source(0) if terrain.tile_set.get_source_count() > 0 else null
			if tile_source and tile_source is TileSetAtlasSource:
				var atlas_source = tile_source as TileSetAtlasSource
				print("  - Tile size (TileSet): ", atlas_source.texture_region_size)
			else:
				print("  - TileSet source não encontrada!")
		else:
			print("  - TileSet NÃO configurado!")
	
	print("=== FIM DEBUG ===\n")

func _on_generate_button_pressed():
	if not is_generating:
		print("🔁 Regenerando tudo via botão...")
		generate_all()
	else:
		print("⚠️ Geração em progresso, aguarde...")

# Função para regenerar manualmente (útil para debug)
func force_regenerate():
	is_generating = false
	generate_all()

# Função para forçar realinhamento (útil para debug)
func force_realign():
	print("🔄 Forçando realinhamento...")
	sync_tilemap_settings()
	var shader_sprite = get_node_or_null("ShaderTerrain")
	if shader_sprite and shader_sprite.has_method("setup_sprite_transform"):
		shader_sprite.setup_sprite_transform()

# Função para debug rápido via Input
func _input(event):
	if not Engine.is_editor_hint():
		if event.is_action_pressed("ui_cancel"): # ESC
			debug_final_state()
		elif event.is_action_pressed("ui_focus_next"): # Tab
			force_realign()
		elif event.is_action_pressed("ui_text_clear_carets_and_selection"): # Ctrl+D (ou outra tecla)
			debug_scene_structure()
