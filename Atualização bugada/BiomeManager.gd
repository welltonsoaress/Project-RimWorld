@tool
class_name BiomeManager
extends RefCounted

# Singleton pattern para acesso global
static var instance: BiomeManager = null

# Configurações carregadas
var biomes: Dictionary = {}
var resources_config: Dictionary = {}
var objects_config: Dictionary = {"type": "String"}
var generation_settings: Dictionary = {}

static func get_instance() -> BiomeManager:
	if not instance:
		instance = BiomeManager.new()
		instance.load_config()
	return instance

func load_config() -> void:
	"""Carrega configurações de biomas de um arquivo JSON ou usa padrão"""
	var config_path = "res://biome_config.json"
	if not FileAccess.file_exists(config_path):
		print("❌ Arquivo biome_config.json não encontrado!")
		load_default_config()
		return
	
	var file = FileAccess.open(config_path, FileAccess.READ)
	if not file:
		push_error("❌ Erro ao abrir biome_config.json!")
		load_default_config()
		return
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		push_error("❌ Erro ao parsear biome_config.json: ", json.get_error_message())
		load_default_config()
		return
	
	var config_data = json.data
	if not config_data is Dictionary:
		push_error("❌ Configuração inválida: JSON não é um dicionário")
		load_default_config()
		return
	
	# Carrega biomas
	if "biomes" in config_data:
		biomes = config_data["biomes"]
		print("✅ Carregados ", biomes.size(), " biomas")
	
	# Carrega recursos
	if "resources" in config_data:
		resources_config = config_data["resources"]
		print("✅ Carregados ", resources_config.size(), " tipos de recursos")
	
	# Carrega objetos
	if "objects" in config_data:
		objects_config = config_data["objects"]
		print("✅ Carregados ", objects_config.size(), " tipos de objetos")
	
	# Carrega configurações de geração
	if "generation_settings" in config_data:
		generation_settings = config_data["generation_settings"]
		print("✅ Configurações de geração carregadas")
	
	# Valida configuração após carregamento
	if not validate_config():
		push_warning("⚠️ Configuração inválida, usando padrão como fallback")
		load_default_config()

func load_default_config() -> void:
	"""Carrega configuração padrão caso o JSON falhe"""
	print("⚠️ Carregando configuração padrão...")
	
	biomes = {
		"ocean": {
			"id": 0,
			"height_range": [0.0, 0.25],
			"temperature_range": [0.0, 1.0],
			"humidity_range": [0.0, 1.0],
			"terrain_tile": {"atlas_coords": [0, 1], "tile_id": 4},
			"resources": {},
			"objects": {},
			"color": [0.0, 0.0, 0.5]  # Para debug previews
		},
		"grassland": {
			"id": 1,
			"height_range": [0.45, 0.55],
			"temperature_range": [0.4, 0.7],
			"humidity_range": [0.4, 0.7],
			"terrain_tile": {"atlas_coords": [0, 0], "tile_id": 0},
			"resources": {
				"stone": {"chance": 0.03, "cluster_size": 10, "atlas_coords": [2, 0]},
				"wood": {"chance": 0.02, "cluster_size": 8, "atlas_coords": [3, 0]}
			},
			"objects": {
				"grass": {"chance": 0.08, "atlas_coords": [0, 0]},
				"tree": {"chance": 0.03, "atlas_coords": [1, 0]}
			},
			"color": [0.0, 0.5, 0.0]
		},
		"forest": {
			"id": 2,
			"height_range": [0.55, 0.65],
			"temperature_range": [0.3, 0.6],
			"humidity_range": [0.6, 1.0],
			"terrain_tile": {"atlas_coords": [1, 0], "tile_id": 1},
			"resources": {
				"wood": {"chance": 0.1, "cluster_size": 12, "atlas_coords": [3, 0]},
				"stone": {"chance": 0.01, "cluster_size": 6, "atlas_coords": [2, 0]}
			},
			"objects": {
				"tree": {"chance": 0.15, "atlas_coords": [1, 0]},
				"bush": {"chance": 0.05, "atlas_coords": [2, 1]}
			},
			"color": [0.0, 0.3, 0.0]
		},
		"desert": {
			"id": 3,
			"height_range": [0.35, 0.45],
			"temperature_range": [0.7, 1.0],
			"humidity_range": [0.0, 0.3],
			"terrain_tile": {"atlas_coords": [2, 1], "tile_id": 3},
			"resources": {
				"stone": {"chance": 0.05, "cluster_size": 10, "atlas_coords": [2, 0]}
			},
			"objects": {},
			"color": [0.8, 0.8, 0.0]
		}
	}
	
	resources_config = {
		"stone": {"atlas_coords": [2, 0], "type": "resource"},
		"wood": {"atlas_coords": [3, 0], "type": "resource"}
	}
	
	objects_config = {
		"grass": {"atlas_coords": [0, 0], "type": "decoration"},
		"tree": {"atlas_coords": [1, 0], "type": "obstacle"},
		"bush": {"atlas_coords": [2, 1], "type": "decoration"}
	}
	
	generation_settings = {
		"noise": {
			"height": {"octaves": 4, "frequency": 0.01},
			"temperature": {"octaves": 3, "frequency": 0.005},
			"humidity": {"octaves": 3, "frequency": 0.008}
		},
		"terrain_types": {
			"island": {"height_scale": 0.8, "edge_falloff": 0.3},
			"continent": {"height_scale": 1.0, "edge_falloff": 0.1}
		}
	}
	
	validate_config()

func get_biome_for_point(height: float, temperature: float = 0.5, humidity: float = 0.5) -> Dictionary:
	"""Determina o bioma baseado nos parâmetros do terreno"""
	for biome_name in biomes:
		var biome = biomes[biome_name]
		
		# Verifica altura
		var height_range = biome.get("height_range", [0.0, 1.0])
		if height < height_range[0] or height > height_range[1]:
			continue
		
		# Verifica temperatura
		var temp_range = biome.get("temperature_range", [0.0, 1.0])
		if temperature < temp_range[0] or temperature > temp_range[1]:
			continue
		
		# Verifica umidade
		var humidity_range = biome.get("humidity_range", [0.0, 1.0])
		if humidity < humidity_range[0] or humidity > humidity_range[1]:
			continue
		
		return biome
	
	# Fallback
	return biomes.get("grassland", {"name": "grassland", "id": 1, "resources": {}, "objects": {}})

func get_terrain_tile_for_biome(biome: Dictionary) -> Dictionary:
	"""Retorna as coordenadas do tile de terreno para um bioma"""
	return biome.get("terrain_tile", {"atlas_coords": [0, 0], "tile_id": 0})

func get_available_resource_types() -> Array[String]:
	"""Retorna uma lista de todos os tipos de recursos disponíveis"""
	var resource_types: Array[String] = []
	for biome in biomes.values():
		for resource_name in biome.get("resources", {}).keys():
			if not resource_name in resource_types:
				resource_types.append(resource_name)
	for resource_name in resources_config.keys():
		if not resource_name in resource_types:
			resource_types.append(resource_name)
	return resource_types

func get_resources_for_biome(biome_name: String) -> Dictionary:
	"""Retorna a configuração de recursos para um bioma"""
	return biomes.get(biome_name, {}).get("resources", {})

func get_objects_for_biome(biome_name: String) -> Dictionary:
	"""Retorna a configuração de objetos para um bioma"""
	return biomes.get(biome_name, {}).get("objects", {})

func get_resource_config(resource_name: String) -> Dictionary:
	"""Retorna a configuração de um recurso específico"""
	return resources_config.get(resource_name, {"atlas_coords": [2, 0], "type": "resource"})

func get_object_config(object_name: String) -> Dictionary:
	"""Retorna a configuração de um objeto específico"""
	return objects_config.get(object_name, {"atlas_coords": [0, 0], "type": "decoration"})

func get_noise_config(noise_type: String) -> Dictionary:
	"""Retorna configuração de ruído para um tipo específico"""
	return generation_settings.get("noise", {}).get(noise_type, {"octaves": 4, "frequency": 0.01})

func get_terrain_type_config(terrain_type: String) -> Dictionary:
	"""Retorna configuração para tipos de terreno (ilha, continente, etc.)"""
	return generation_settings.get("terrain_types", {}).get(terrain_type.to_lower(), {"height_scale": 1.0, "edge_falloff": 0.1})

func get_legacy_atlas_coords_for_height(height: float) -> Vector2i:
	"""Compatibilidade com sistema legado baseado em altura"""
	var biome = get_biome_for_point(height)
	var terrain_tile = get_terrain_tile_for_biome(biome)
	var coords = terrain_tile.get("atlas_coords", [0, 0])
	return Vector2i(coords[0], coords[1])

func get_legacy_tile_id_for_height(height: float) -> int:
	"""Compatibilidade com sistema de tile IDs legado"""
	var biome = get_biome_for_point(height)
	var terrain_tile = get_terrain_tile_for_biome(biome)
	return terrain_tile.get("tile_id", 0)

func print_biome_info() -> void:
	"""Imprime informações detalhadas dos biomas para debug"""
	print("\n🌍 === INFORMAÇÕES DOS BIOMAS ===")
	for biome_name in biomes:
		var biome = biomes[biome_name]
		print("🔹 ", biome_name.capitalize(), ":")
		print("  - ID: ", biome.get("id", "N/A"))
		print("  - Altura: ", biome.get("height_range", "N/A"))
		print("  - Temperatura: ", biome.get("temperature_range", "N/A"))
		print("  - Umidade: ", biome.get("humidity_range", "N/A"))
		print("  - Tile: ", biome.get("terrain_tile", "N/A"))
		print("  - Recursos: ", biome.get("resources", {}).keys())
		print("  - Objetos: ", biome.get("objects", {}).keys())
		print("  - Cor: ", biome.get("color", "N/A"))
	print("=== FIM INFO BIOMAS ===\n")

func validate_config() -> bool:
	"""Valida a configuração de biomas"""
	var is_valid = true
	
	if biomes.is_empty():
		push_error("❌ Nenhum bioma configurado!")
		is_valid = false
	
	for biome_name in biomes:
		var biome = biomes[biome_name]
		if not "height_range" in biome:
			push_error("❌ Bioma ", biome_name, " sem height_range!")
			is_valid = false
		if not "terrain_tile" in biome:
			push_error("❌ Bioma ", biome_name, " sem terrain_tile!")
			is_valid = false
		if not "resources" in biome:
			push_warning("⚠️ Bioma ", biome_name, " sem recursos configurados")
		if not "objects" in biome:
			push_warning("⚠️ Bioma ", biome_name, " sem objetos configurados")
		if not "id" in biome:
			push_warning("⚠️ Bioma ", biome_name, " sem ID")
		if not "color" in biome and Engine.is_editor_hint():
			push_warning("⚠️ Bioma ", biome_name, " sem cor para debug")
	
	if resources_config.is_empty():
		push_warning("⚠️ Nenhum recurso configurado globalmente")
	
	if objects_config.is_empty():
		push_warning("⚠️ Nenhum objeto configurado globalmente")
	
	if is_valid:
		print("✅ Configuração de biomas validada com sucesso")
	return is_valid
