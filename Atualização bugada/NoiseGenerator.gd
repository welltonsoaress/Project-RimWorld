@tool
class_name NoiseGenerator
extends RefCounted

var height_noise: FastNoiseLite
var temperature_noise: FastNoiseLite
var humidity_noise: FastNoiseLite
var biome_manager: BiomeManager

func _init(seed_value: int = 0):
	biome_manager = BiomeManager.get_instance()
	setup_noise_generators(seed_value)

func setup_noise_generators(seed_value: int):
	"""Configura os geradores de ruído baseado na configuração"""
	
	# Configura ruído de altura
	height_noise = FastNoiseLite.new()
	var height_config = biome_manager.get_noise_config("height")
	configure_noise(height_noise, height_config, seed_value)
	
	# Configura ruído de temperatura
	temperature_noise = FastNoiseLite.new()
	var temp_config = biome_manager.get_noise_config("temperature")
	configure_noise(temperature_noise, temp_config, seed_value + 1000)
	
	# Configura ruído de umidade
	humidity_noise = FastNoiseLite.new()
	var humidity_config = biome_manager.get_noise_config("humidity")
	configure_noise(humidity_noise, humidity_config, seed_value + 2000)
	
	print("🌀 Geradores de ruído configurados com semente: ", seed_value)

func configure_noise(noise: FastNoiseLite, config: Dictionary, seed_value: int):
	"""Aplica configuração a um gerador de ruído"""
	noise.seed = seed_value
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	
	# Aplica configurações do arquivo JSON
	noise.frequency = config.get("frequency", 0.03)
	
	# Para ruído fractal (múltiplas oitavas) - Godot 4 usa fractal_type
	if "octaves" in config:
		noise.fractal_type = FastNoiseLite.FRACTAL_FBM  # Corrigido para Godot 4
		noise.fractal_octaves = config.get("octaves", 4)
		noise.fractal_lacunarity = config.get("lacunarity", 2.0)
		noise.fractal_gain = config.get("gain", 0.5)

func get_height_at(x: int, y: int, terrain_type: String = "auto", map_width: int = 128, map_height: int = 128) -> float:
	"""Gera altura em uma posição considerando o tipo de terreno"""
	var height = height_noise.get_noise_2d(x, y)
	height = (height + 1.0) / 2.0  # Normaliza para 0-1
	
	# Aplica modificadores baseados no tipo de terreno
	var terrain_config = biome_manager.get_terrain_type_config(terrain_type.to_lower())
	
	if terrain_type.to_lower() == "island" or (terrain_type == "auto" and should_be_island()):
		height = apply_island_falloff(height, x, y, map_width, map_height, terrain_config)
	elif terrain_type.to_lower() == "archipelago":
		height = apply_archipelago_pattern(height, x, y, map_width, map_height, terrain_config)
	elif terrain_type.to_lower() == "continent":
		height = apply_continent_pattern(height, x, y, map_width, map_height, terrain_config)
	
	return clamp(height, 0.0, 1.0)

func get_temperature_at(x: int, y: int, map_height: int = 128) -> float:
	"""Gera temperatura baseada na latitude e ruído"""
	var base_temp = temperature_noise.get_noise_2d(x, y)
	base_temp = (base_temp + 1.0) / 2.0
	
	# Modificador de latitude (mais frio nos polos)
	var latitude_factor = abs(float(y) / float(map_height) - 0.5) * 2.0
	var latitude_modifier = 1.0 - (latitude_factor * 0.6)
	
	return clamp(base_temp * latitude_modifier, 0.0, 1.0)

func get_humidity_at(x: int, y: int, height: float) -> float:
	"""Gera umidade baseada em ruído e altura"""
	var humidity = humidity_noise.get_noise_2d(x, y)
	humidity = (humidity + 1.0) / 2.0
	
	# Maior umidade em altitudes menores
	var altitude_modifier = 1.0 - (height * 0.3)
	
	return clamp(humidity * altitude_modifier, 0.0, 1.0)

func apply_island_falloff(height: float, x: int, y: int, map_width: int, map_height: int, config: Dictionary) -> float:
	"""Aplica falloff circular para criar ilhas"""
	var center_x = map_width / 2.0
	var center_y = map_height / 2.0
	
	var dx = (x - center_x) / center_x
	var dy = (y - center_y) / center_y
	var distance = sqrt(dx * dx + dy * dy)
	
	var falloff_strength = config.get("falloff_strength", 1.0)
	var center_boost = config.get("center_boost", 0.2)
	
	# Adiciona boost no centro
	height += center_boost * (1.0 - distance)
	
	# Aplica falloff
	var falloff = clamp(1.0 - distance, 0.0, 1.0)
	falloff = pow(falloff, falloff_strength)
	
	return height * falloff

func apply_archipelago_pattern(height: float, x: int, y: int, map_width: int, map_height: int, config: Dictionary) -> float:
	"""Cria padrão de arquipélago com múltiplas ilhas"""
	var island_count = config.get("island_count", 5)
	var falloff_strength = config.get("falloff_strength", 0.8)
	
	var max_height = 0.0
	
	# Cria múltiplas ilhas em posições semi-aleatórias
	for i in range(island_count):
		var island_x = float(i % 3) * (float(map_width) / 3.0) + (float(map_width) / 6.0)
		@warning_ignore("integer_division")
		var island_y = float(i / 3) * (float(map_height) / 3.0) + (float(map_height) / 6.0)
		
		# Adiciona variação baseada no índice da ilha
		island_x += sin(i * 2.5) * (float(map_width) * 0.1)
		island_y += cos(i * 1.8) * (float(map_height) * 0.1)
		
		var dx = (float(x) - island_x) / (float(map_width) * 0.3)
		var dy = (float(y) - island_y) / (float(map_height) * 0.3)
		var distance = sqrt(dx * dx + dy * dy)
		
		var falloff = clamp(1.0 - distance, 0.0, 1.0)
		falloff = pow(falloff, falloff_strength)
		
		max_height = max(max_height, height * falloff)
	
	return max_height

func apply_continent_pattern(height: float, x: int, y: int, map_width: int, map_height: int, config: Dictionary) -> float:
	"""Aplica padrão continental com falloff suave nas bordas"""
	var falloff_strength = config.get("falloff_strength", 0.3)
	
	# Distância normalizada da borda mais próxima
	var edge_distance = min(
		min(float(x), float(map_width - x)) / (float(map_width) * 0.5),
		min(float(y), float(map_height - y)) / (float(map_height) * 0.5)
	)
	
	var edge_falloff = pow(edge_distance, falloff_strength)
	
	return height * (0.7 + 0.3 * edge_falloff)

func should_be_island() -> bool:
	"""Determina aleatoriamente se deve ser ilha"""
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	return rng.randf() < 0.5

# Função para compatibilidade com o sistema atual
func get_legacy_height(x: int, y: int, is_island: bool, map_width: int, map_height: int) -> float:
	"""Mantém compatibilidade com o sistema atual"""
	var height = height_noise.get_noise_2d(x, y)
	height = (height + 1.0) / 2.0
	
	if is_island:
		var dx = float(x - map_width / 2.0) / (map_width / 2.0)
		var dy = float(y - map_height / 2.0) / (map_height / 2.0)
		var dist = sqrt(dx * dx + dy * dy)
		height *= clamp(1.0 - dist, 0.0, 1.0)
	
	return height

# Funções de debug
func debug_noise_values(x: int, y: int, map_width: int = 128, map_height: int = 128):
	"""Imprime valores de debug para uma posição"""
	print("🌀 Debug Ruído em (", x, ",", y, "):")
	print("  - Altura: ", get_height_at(x, y, "auto", map_width, map_height))
	print("  - Temperatura: ", get_temperature_at(x, y, map_height))
	print("  - Umidade: ", get_humidity_at(x, y, get_height_at(x, y, "auto", map_width, map_height)))

func generate_preview_image(width: int, height: int, noise_type: String = "height") -> Image:
	"""Gera uma imagem de preview do ruído para debug"""
	var image = Image.create(width, height, false, Image.FORMAT_RGB8)
	
	for x in range(width):
		for y in range(height):
			var value = 0.0
			
			match noise_type:
				"height":
					value = get_height_at(x, y, "auto", width, height)
				"temperature":
					value = get_temperature_at(x, y, height)
				"humidity":
					value = get_humidity_at(x, y, get_height_at(x, y, "auto", width, height))
			
			var color = Color(value, value, value)
			image.set_pixel(x, y, color)
	
	return image
