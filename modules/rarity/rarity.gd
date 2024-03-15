extends Node


#region Public Variables
var rarities: Array[StringName] = []
var rarity_colors: Dictionary = {}
#endregion


#region Internal Functions
func _ready() -> void:
	Modules.register_hooks(handler)
	
	register_rarity(&"Free", Color.WHITE)
	register_rarity(&"Common", Color.GRAY)
	register_rarity(&"Rare", Color.BLUE)
	register_rarity(&"Epic", Color.PURPLE)
	register_rarity(&"Legendary", Color.GOLD)
#endregion


#region Public Functions
func handler(what: StringName, info: Array) -> bool:
	if what == &"Update Card":
		return update_card_hook.callv(info)
	
	return true


func update_card_hook(card: Card) -> bool:
	# Rarity Color
	var rarity_node: MeshInstance3D = card.get_node("Mesh/Rarity")
	
	if not card.modules.get("rarities"):
		assert(false, "'%s' (%d) doesn't have a rarity." % [card.name, card.id])
		return false
	
	rarity_node.visible = card.modules.rarities.size() > 0 and not card.modules.rarities.has(&"Free")
	
	var rarity_material: StandardMaterial3D = StandardMaterial3D.new()
	if card.modules.rarities.size() > 0:
		rarity_material.albedo_color = rarity_colors.get(card.modules.rarities[0], Color.WHITE)
	rarity_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	rarity_node.set_surface_override_material(0, rarity_material)
	
	return true


func register_rarity(rarity: StringName, color: Color) -> void:
	rarities.append(rarity)
	rarity_colors[rarity] = color
#endregion

