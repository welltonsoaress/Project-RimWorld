@tool
extends Node2D

const MAP_WIDTH = 128
const MAP_HEIGHT = 128

var is_generating := false

func _ready():
	if not Engine.is_editor_hint() and not is_generating:
		is_generating = true
		print("🎮 Gerando mapa procedural...")
		setup_layers()
		generate_all()
		is_generating = false

func setup_layers():
	$ShaderTerrain.z_index = 0
	$Resource/ResourceMap.z_index = 1
	$Object/ObjectMap.z_index = 2
	print("🔧 Camadas configuradas: ShaderTerrain=0, Resource=1, Object=2")

func generate_all():
	if is_generating:
		print("⚠️ Geração já em progresso, reiniciando...")
		is_generating = false
	is_generating = true

	var terrain = $Terrain/TerrainMap
	if terrain and terrain.has_method("GenerateTerrain"):
		print("🌍 Gerando terreno...")
		terrain.generateTerrain = true
		await get_tree().create_timer(0.5).timeout
	else:
		print("❌ TerrainMap não encontrado ou sem GenerateTerrain!")

	var resources = $Resource/ResourceMap
	if resources and resources.has_method("generate"):
		print("🔧 Gerando recursos...")
		resources.generate()
		await get_tree().process_frame
	else:
		print("❌ ResourceMap não encontrado!")

	var objects = $Object/ObjectMap
	if objects and objects.has_method("generate"):
		print("📦 Gerando objetos...")
		objects.generate()
		await get_tree().process_frame
	else:
		print("❌ ObjectMap não encontrado!")

	var shader_sprite = $ShaderTerrain
	if shader_sprite and shader_sprite.has_method("update_texture"):
		print("🎨 Atualizando ShaderTerrain...")
		shader_sprite.update_texture()
	is_generating = false
	print("✅ Geração concluída!")

func _on_generate_button_pressed():
	if not is_generating:
		is_generating = true
		print("🔁 Regenerando tudo...")
		generate_all()
		is_generating = false
