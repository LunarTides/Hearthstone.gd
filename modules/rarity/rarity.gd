extends Module


#region Constants
const RARITY_MESH: PackedScene = preload("res://modules/rarity/rarity.blend")
#endregion


#region Public Variables
var rarities: Array[StringName] = []
var rarity_colors: Dictionary = {}
#endregion


#region Module Functions
func _name() -> StringName:
	return &"Rarity"


func _dependencies() -> Array[StringName]:
	return []


func _load() -> void:
	register_hooks(handler)
	register_card_mesh(RARITY_MESH)
		
	register_rarity(&"Free", Color.WHITE)
	register_rarity(&"Common", Color.GRAY)
	register_rarity(&"Rare", Color.BLUE)
	register_rarity(&"Epic", Color.PURPLE)
	register_rarity(&"Legendary", Color.GOLD)


func _unload() -> void:
	unregister_rarity(&"Free")
	unregister_rarity(&"Common")
	unregister_rarity(&"Rare")
	unregister_rarity(&"Epic")
	unregister_rarity(&"Legendary")
#endregion


#region Public Functions
func register_rarity(rarity: StringName, color: Color) -> void:
	rarities.append(rarity)
	rarity_colors[rarity] = color


func unregister_rarity(rarity: StringName) -> void:
	rarities.erase(rarity)
	rarity_colors.erase(rarity)


func handler(what: Modules.Hook, info: Array) -> bool:
	if what == Modules.Hook.CARD_UPDATE:
		return update_card_hook.callv(info)
	
	return true


#region Hooks
func update_card_hook(card: Card) -> bool:
	# Rarity Color
	if not card.modules.has("rarities"):
		assert(false, "'%s' (%d) doesn't have a rarity." % [card.name, card.id])
		return false
	
	var rarity_node: MeshInstance3D = card.mesh.get_node_or_null("Rarity/Rarity")
	if not rarity_node:
		return true
	
	rarity_node.visible = card.modules.rarities.size() > 0 and not card.modules.rarities.has(&"Free")
	
	var rarity_material: StandardMaterial3D = StandardMaterial3D.new()
	if card.modules.rarities.size() > 0:
		rarity_material.albedo_color = rarity_colors.get(card.modules.rarities[0], Color.WHITE)
	rarity_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	rarity_node.set_surface_override_material(0, rarity_material)
	
	return true
#endregion
#endregion
