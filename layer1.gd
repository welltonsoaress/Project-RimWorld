@tool
extends TileMapLayer

# Ações do editor
@export var generateTerrain: bool = false:
	set(value):
		generateTerrain = false
		if not Engine.is_editor_hint() or value:
			GenerateTerrain()

@export var clearTerrain: bool = false:
	set(value):
		clearTerrain = false
		if not Engine.is_editor_hint() or value:
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
	if not tile_set:
		print("❌ TileSet não atribuído à camada!")
		return
	print("✅ TileMapLayer pronto: ", name)
	if not Engine.is_editor_hint():
		GenerateTerrain()

func GenerateTerrain():
	print("🌍 Gerando terreno procedural...")
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
	var image = Image.create(mapWidth, mapHeight, false, Image.FORMAT_RGB8)

	for x in range(mapWidth):
		for y in range(mapHeight):
			var height = noise.get_noise_2d(x, y)
			height = (height + 1.0) / 2.0

			if isIsland:
				var dx = float(x - mapWidth / 2.0) / (mapWidth / 2.0)
				var dy = float(y - mapHeight / 2.0) / (mapHeight / 2.0)
				var dist = sqrt(dx * dx + dy * dy)
				height *= clamp(1.0 - dist, 0.0, 1.0)

			var atlas_coord = Vector2i(0, 1)  # Água
			var tile_id = 0

			if height < oceanThreshold:
				atlas_coord = Vector2i(0, 1)
				tile_id = 3
			elif height < beachThreshold:
				atlas_coord = Vector2i(1, 1)
				tile_id = 1
			elif height < desertThreshold:
				atlas_coord = Vector2i(2, 1)
				tile_id = 7
			elif height < grassThreshold:
				atlas_coord = Vector2i(2, 0)
				tile_id = 4
			elif height < darkGrassThreshold:
				atlas_coord = Vector2i(0, 0)
				tile_id = 0
			elif height < mountainThreshold:
				atlas_coord = Vector2i(1, 0)
				tile_id = 5
			else:
				atlas_coord = Vector2i(3, 0)
				tile_id = 2

			set_cell(Vector2i(x, y), 1, atlas_coord)
			image.set_pixel(x, y, Color(float(tile_id) / 7.0, 0, 0))

	var dir = DirAccess.open("res://")
	if dir and dir.file_exists("res://mapData.png"):
		dir.remove("res://mapData.png")
	var error = image.save_png("res://mapData.png")
	if error == OK:
		print("🗺️ mapData.png salvo com sucesso! - Primeiros pixels: ", image.get_pixel(0, 0), image.get_pixel(1, 0))
	else:
		print("❌ Falha ao salvar mapData.png, erro: ", error)

	var label = get_tree().root.get_node_or_null("Node2D/CanvasLayer/MapTypeLabel")
	if label:
		label.text = "Tipo: " + terrainType + " → " + ("Ilha" if isIsland else "Continente")

	var shader_terrain = get_tree().root.get_node_or_null("ShaderTerrain")
	if shader_terrain and shader_terrain.has_method("update_texture"):
		shader_terrain.update_texture()
