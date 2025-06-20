@tool
extends Node2D

const MAP_WIDTH = 128
const MAP_HEIGHT = 128

var is_generating := false

func _ready():
	if not Engine.is_editor_hint() and not is_generating:
		is_generating = true
		print("🎮 Iniciando geração do mapa procedural...")
		setup_layers()
		# Aguarda um frame para garantir que tudo está inicializado
		await get_tree().process_frame
		generate_all()
		is_generating = false

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
	
	# Coleta todos os TileMapLayers
	var terrain = get_node_or_null("Terrain/TerrainMap")
	var resources = get_node_or_null("Resource/ResourceMap")
	var objects = get_node_or_null("Object/ObjectMap")
	
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
	var terrain = get_node_or_null("Terrain/TerrainMap")
	if terrain and terrain.has_method("GenerateTerrain"):
		print("🌍 Gerando terreno...")
		terrain.GenerateTerrain()
		# Aguarda mais tempo para garantir que o arquivo foi salvo
		await get_tree().create_timer(1.0).timeout
	else:
		print("❌ TerrainMap não encontrado!")
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
	var resources = get_node_or_null("Resource/ResourceMap")
	if resources and resources.has_method("generate"):
		print("🔧 Gerando recursos...")
		resources.generate()
		await get_tree().process_frame
	else:
		print("❌ ResourceMap não encontrado!")

	# 4. QUARTO: Gera objetos (agora alinhado com o shader)
	var objects = get_node_or_null("Object/ObjectMap")
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
		var material = shader_sprite.material
		if material and material is ShaderMaterial:
			var shader_mat = material as ShaderMaterial
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
	var terrain = get_node_or_null("Terrain/TerrainMap")
	if terrain and terrain is TileMapLayer:
		print("✅ TerrainMap encontrado")
		print("  - Position: ", terrain.position)
		print("  - Scale: ", terrain.scale)
		if terrain.tile_set:
			print("  - TileSet configurado: ", terrain.tile_set != null)
	
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
