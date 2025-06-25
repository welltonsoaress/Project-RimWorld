@tool
extends TileMapLayer

# Ações do editor
@export var generateTerrain: bool = false:
	set(value):
		generateTerrain = false
		if value:
			GenerateTerrain()

@export var clearTerrain: bool = false:
	set(value):
		clearTerrain = false
		if value:
			clear()
			print("🧹 Terreno limpo!")

# Tamanho do mapa
@export var mapWidth: int = 128
@export var mapHeight: int = 128

# Semente para ruído (0 para aleatória)
@export var terrainSeed: int = 0

# Tipo de terreno
@export_enum("Auto", "Ilha", "Continente", "Arquipélago", "Península", "Desertão")
var terrainType: String = "Auto"

# Thresholds de altitude
@export var oceanThreshold := 0.25
@export var beachThreshold := 0.35
@export var desertThreshold := 0.45
@export var grassThreshold := 0.55
@export var darkGrassThreshold := 0.7
@export var mountainThreshold := 0.85

var noise: FastNoiseLite = null
var isIsland: bool = false  # Variável de instância

func _ready():
	print("🌍 TerrainMap _ready() chamado")
	
	if not tile_set:
		print("⚠️ TileSet não atribuído, criando automaticamente...")
		create_automatic_tileset()
	
	# Define a posição inicial como (0, 0)
	position = Vector2(0, 0)
	print("✅ TileMapLayer pronto: ", name, " | Posição inicial: ", position)
	
	if not Engine.is_editor_hint():
		# Aguarda um frame para garantir inicialização
		await get_tree().process_frame
		GenerateTerrain()

# Criar TileSet automaticamente se não existir
func create_automatic_tileset():
	var new_tileset = TileSet.new()
	var atlas_source = TileSetAtlasSource.new()
	
	# Carrega a textura do atlas
	var texture_atlas = load("res://TileSets/textureAtlas.png")
	if not texture_atlas:
		print("❌ Falha ao carregar textureAtlas.png")
		return
	
	atlas_source.texture = texture_atlas
	atlas_source.texture_region_size = Vector2i(32, 32)
	
	print("✅ Textura carregada: ", texture_atlas.resource_path, " - Tamanho: ", texture_atlas.get_size())
	
	# Atlas 4x4 (128x128 pixels, tiles de 32x32)
	var tiles_per_row = 4
	var tiles_per_col = 4
	
	print("📊 Atlas: ", tiles_per_row, "x", tiles_per_col, " tiles (", tiles_per_row * tiles_per_col, " total)")
	
	# Cria tiles automaticamente
	for y in range(tiles_per_col):
		for x in range(tiles_per_row):
			if y >= 2:  # Só cria 2 linhas (8 tiles)
				break
			
			var atlas_coords = Vector2i(x, y)
			atlas_source.create_tile(atlas_coords)
			
			# Cria região de textura para cada tile
			var tile_data = atlas_source.get_tile_data(atlas_coords, 0)
			if tile_data:
				# Define propriedades básicas do tile se necessário
				pass
			
			print("🌍 Tile terrain criado: ", atlas_coords)
	
	new_tileset.add_source(atlas_source, 0)
	tile_set = new_tileset
	print("✅ TileSet criado automaticamente para terrain")

func GenerateTerrain():
	print("🌍 Gerando terreno procedural...")
	
	# Verifica se tile_set existe
	if not tile_set:
		print("⚠️ TileSet não configurado, criando...")
		create_automatic_tileset()
		if not tile_set:
			print("❌ Falha ao criar TileSet!")
			return
	
	var rng = RandomNumberGenerator.new()
	terrainSeed = 0  # Reseta para aleatoriedade a cada geração
	if terrainSeed == 0:
		rng.randomize()
		terrainSeed = rng.randi()
		print("🌱 Nova semente gerada: ", terrainSeed)
	else:
		rng.set_seed(terrainSeed)
		print("🌱 Usando semente fixa: ", terrainSeed)
	
	# Usa a variável de instância diretamente
	match terrainType:
		"Ilha":
			isIsland = true
		"Continente":
			isIsland = false
		"Auto":
			isIsland = rng.randf() < 0.5
		"Arquipélago":
			isIsland = true
		"Península":
			isIsland = false
		"Desertão":
			isIsland = false
	print("🔀 Terreno: " + ("Ilha" if isIsland else "Continente"))
	
	noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.03
	noise.seed = terrainSeed
	print("📊 Ruído configurado com semente: ", noise.seed)
	
	clear()
	var image = Image.create(mapWidth, mapHeight, true, Image.FORMAT_RGB8)
	
	for x in range(mapWidth):
		for y in range(mapHeight):
			var height = noise.get_noise_2d(x, y)
			height = (height + 1.0) / 2.0
			
			if isIsland:
				var dx = float(x - mapWidth / 2.0) / (mapWidth / 2.0)
				var dy = float(y - mapHeight / 2.0) / (mapHeight / 2.0)
				var dist = sqrt(dx * dx + dy * dy)
				height *= clamp(1.0 - dist, 0.0, 1.0)
			
			var atlas_coord = Vector2i(0, 1)  # Água por padrão
			var tile_id = 4  # Água (índice 4 no atlas)
			
			if height < oceanThreshold:
				atlas_coord = Vector2i(0, 1)  # Água
				tile_id = 4
			elif height < beachThreshold:
				atlas_coord = Vector2i(1, 1)  # Areia de praia
				tile_id = 5
			elif height < desertThreshold:
				atlas_coord = Vector2i(2, 1)  # Areia do deserto
				tile_id = 6
			elif height < grassThreshold:
				atlas_coord = Vector2i(0, 0)  # Grama
				tile_id = 0
			elif height < darkGrassThreshold:
				atlas_coord = Vector2i(1, 0)  # Grama escura
				tile_id = 1
			elif height < mountainThreshold:
				atlas_coord = Vector2i(2, 0)  # Terra
				tile_id = 2
			else:
				atlas_coord = Vector2i(3, 0)  # Pedra
				tile_id = 3
			
			set_cell(Vector2i(x, y), 0, atlas_coord)
			image.set_pixel(x, y, Color(float(tile_id) / 7.0, 0, 0))
	
	# Garante a posição (0, 0)
	position = Vector2(0, 0)
	print("🔄 TerrainMap posicionado em: ", position)
	
	visible = true  # Garante que o TileMapLayer seja visível
	
	# Salva mapData.png
	var dir = DirAccess.open("res://")
	if dir and dir.file_exists("res://mapData.png"):
		dir.remove("res://mapData.png")
	var error = image.save_png("res://mapData.png")
	if error == OK:
		print("🗺️ mapData.png salvo com sucesso! - Primeiros pixels: ", image.get_pixel(0, 0), image.get_pixel(1, 0))
	else:
		print("❌ Falha ao salvar mapData.png, erro: ", error)
	
	# Atualiza label se existir
	var label = get_tree().root.get_node_or_null("Node2D/CanvasLayer/MapTypeLabel")
	if not label:
		label = get_tree().root.get_node_or_null("Main/UI/MapTypeLabel")
	if label:
		label.text = "Tipo: " + terrainType + " → " + ("Ilha" if isIsland else "Continente")
	
	# Notifica o shader para atualizar
	var shader_terrain = get_tree().root.get_node_or_null("Main/ShaderTerrain")
	if shader_terrain and shader_terrain.has_method("update_texture"):
		print("🎨 Notificando ShaderTerrain para atualizar...")
		# Aguarda um pouco para garantir que o arquivo foi salvo
		await get_tree().create_timer(0.5).timeout
		shader_terrain.update_texture()

# Métodos alternativos para compatibilidade
func generate_terrain():
	GenerateTerrain()

func generate():
	GenerateTerrain()

func regenerate():
	GenerateTerrain()
