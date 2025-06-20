extends Sprite2D

@export var tile_size := 32
@export var map_width := 128
@export var map_height := 128

@onready var shader_sprite := self
@onready var material_instance := material as ShaderMaterial if material and material is ShaderMaterial else ShaderMaterial.new()
var map_data_texture: ImageTexture = null

func _ready():
	if not Engine.is_editor_hint():
		setup_shader_material()
		# Aguarda a geração do terreno antes de atualizar
		await get_tree().create_timer(0.1).timeout
		update_texture()

func setup_shader_material():
	# Sempre cria um novo material para garantir que o shader seja carregado
	material = ShaderMaterial.new()
	var shader = load("res://Main.gdshader")
	
	if not shader:
		print("❌ Falha ao carregar shader Main.gdshader")
		return
		
	material.shader = shader
	material_instance = material as ShaderMaterial
	
	# Configura textureAtlas OBRIGATÓRIA
	var texture_atlas = load("res://TileSets/textureAtlas.png")
	if not texture_atlas:
		print("❌ Falha ao carregar textureAtlas.png")
		return
	
	material_instance.set_shader_parameter("textureAtlas", texture_atlas)
	print("✅ Shader e textureAtlas carregados com sucesso")
	
	# Configura parâmetros fixos
	material_instance.set_shader_parameter("tileSizeInPixels", float(tile_size))
	material_instance.set_shader_parameter("textureAtlasTextureSizeInPixels", 128.0)
	material_instance.set_shader_parameter("textureAtlasTexturesWidth", 4.0)
	material_instance.set_shader_parameter("mapTilesCountX", float(map_width))
	material_instance.set_shader_parameter("mapTilesCountY", float(map_height))
	material_instance.set_shader_parameter("blendTextureTiles", 4.0)
	
	# Carrega blendTexture se existir
	var blend_texture = load("res://blendTexture.png")
	if blend_texture:
		material_instance.set_shader_parameter("blendTexture", blend_texture)

func update_texture():
	if not material_instance:
		print("❌ Material não inicializado!")
		return
		
	# Aguarda um pouco mais para garantir que o arquivo foi salvo
	await get_tree().create_timer(0.8).timeout
	
	# Método mais seguro para carregar a imagem gerada
	var map_data_image = await load_map_data_safely()
	if not map_data_image:
		print("❌ Falha ao carregar mapData")
		return

	# Cria nova ImageTexture
	if not map_data_texture:
		map_data_texture = ImageTexture.new()
	
	map_data_texture.set_image(map_data_image)
	print("📷 Textura criada, tamanho: ", map_data_image.get_size())
	
	# Remove parâmetro antigo e define novo
	material_instance.set_shader_parameter("mapData", null)
	await get_tree().process_frame
	material_instance.set_shader_parameter("mapData", map_data_texture)
	
	print("🎨 mapData atualizado no shader")
	
	# Força atualização visual
	texture = load("res://TileSets/blank_1x1_white.png") # Imagem base para o sprite
	if texture:
		# Calcula o tamanho correto baseado no mapa
		scale = Vector2(
			float(map_width * tile_size) / texture.get_width(),
			float(map_height * tile_size) / texture.get_height()
		)
		print("🔄 Sprite redimensionado para: ", scale)
	
	queue_redraw()

func load_map_data_safely() -> Image:
	var image = Image.new()
	
	# Tenta carregar o arquivo várias vezes se necessário
	for attempt in range(5):
		var err = image.load("res://mapData.png")
		if err == OK:
			print("✅ mapData.png carregado na tentativa ", attempt + 1)
			return image
		else:
			print("⚠️ Tentativa ", attempt + 1, " falhou, erro: ", err)
			await get_tree().create_timer(0.2).timeout
	
	# Se ainda falhou, cria uma imagem de fallback
	print("❌ Criando mapData de fallback")
	image = Image.create(map_width, map_height, false, Image.FORMAT_RGB8)
	
	# Preenche com padrão de teste (água = tile 3)
	for x in range(map_width):
		for y in range(map_height):
			image.set_pixel(x, y, Color(3.0/7.0, 0, 0)) # Tile ID 3 (água)
	
	return image

# Função de debug para verificar parâmetros do shader
func debug_shader_parameters():
	if not material_instance:
		print("❌ Sem material para debug")
		return
		
	print("🔍 DEBUG - Parâmetros do Shader:")
	print("  - textureAtlas: ", material_instance.get_shader_parameter("textureAtlas"))
	print("  - mapData: ", material_instance.get_shader_parameter("mapData"))
	print("  - tileSizeInPixels: ", material_instance.get_shader_parameter("tileSizeInPixels"))
	print("  - mapTilesCountX: ", material_instance.get_shader_parameter("mapTilesCountX"))
	print("  - mapTilesCountY: ", material_instance.get_shader_parameter("mapTilesCountY"))

# Chama debug após updates (útil para testar)
func _input(event):
	if event.is_action_pressed("ui_accept"): # Enter
		debug_shader_parameters()
