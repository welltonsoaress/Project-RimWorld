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
	# Configura z-index das camadas
	if has_node("ShaderTerrain"):
		$ShaderTerrain.z_index = 0
	if has_node("Resource/ResourceMap"):
		$Resource/ResourceMap.z_index = 1
	if has_node("Object/ObjectMap"):
		$Object/ObjectMap.z_index = 2
	print("🔧 Camadas configuradas")

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

	# 2. SEGUNDO: Gera recursos (depende do terreno)
	var resources = get_node_or_null("Resource/ResourceMap")
	if resources and resources.has_method("generate"):
		print("🔧 Gerando recursos...")
		resources.generate()
		await get_tree().process_frame
	else:
		print("❌ ResourceMap não encontrado!")

	# 3. TERCEIRO: Gera objetos (depende de terreno e recursos)
	var objects = get_node_or_null("Object/ObjectMap")
	if objects and objects.has_method("generate"):
		print("📦 Gerando objetos...")
		objects.generate()
		await get_tree().process_frame
	else:
		print("❌ ObjectMap não encontrado!")

	# 4. QUARTO: Configura o shader (depende do mapData.png)
	var shader_sprite = get_node_or_null("ShaderTerrain")
	if shader_sprite:
		print("🎨 Configurando ShaderTerrain...")
		# Aguarda um pouco mais para garantir que o arquivo existe
		await get_tree().create_timer(0.5).timeout
		
		if shader_sprite.has_method("update_texture"):
			shader_sprite.update_texture()
		else:
			print("❌ ShaderTerrain sem método update_texture!")
	else:
		print("❌ ShaderTerrain não encontrado!")

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
			
			if shader_sprite.has_method("debug_shader_parameters"):
				shader_sprite.debug_shader_parameters()
		else:
			print("❌ ShaderMaterial não encontrado!")
	
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
