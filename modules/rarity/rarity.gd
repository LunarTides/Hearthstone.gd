extends Node


#region Constants
const RARITY_MESH: PackedScene = preload("res://modules/rarity/rarity.blend")
#endregion


#region Public Variables
var rarities: Array[StringName] = []
var rarity_colors: Dictionary = {}
#endregion


#region Internal Functions
func _ready() -> void:
	Modules.register(&"Rarity", [], func() -> void:
		Modules.register_hooks(&"Rarity", self.handler)
		
		register_rarity(&"Free", Color.WHITE)
		register_rarity(&"Common", Color.GRAY)
		register_rarity(&"Rare", Color.BLUE)
		register_rarity(&"Epic", Color.PURPLE)
		register_rarity(&"Legendary", Color.GOLD)
	, func() -> void:
		unregister_rarity(&"Free")
		unregister_rarity(&"Common")
		unregister_rarity(&"Rare")
		unregister_rarity(&"Epic")
		unregister_rarity(&"Legendary")
	)
#endregion


#region Public Functions
func handler(what: Modules.Hook, info: Array) -> bool:
	if what == Modules.Hook.CARD_UPDATE:
		return update_card_hook.callv(info)
	
	return true


func update_card_hook(card: Card) -> bool:
	# FIXME: For some reason, this hook doesn't get called on all cards.
	#print(card.player.id, card.location, card.index)
	
	# Rarity Color
	if not card.modules.get("rarities"):
		assert(false, "'%s' (%d) doesn't have a rarity." % [card.name, card.id])
		return false
	
	var rarity_node: MeshInstance3D = card.mesh.get_node_or_null("Rarity")
	
	if not rarity_node:
		var root_node: Node3D = RARITY_MESH.instantiate()
		card.mesh.add_child(root_node)
		
		rarity_node = root_node.get_child(0)
		rarity_node.reparent(card.mesh)
		rarity_node.position = Vector3(0, 0.2, 0.6)
		
		root_node.queue_free()
	
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


func unregister_rarity(rarity: StringName) -> void:
	rarities.erase(rarity)
	rarity_colors.erase(rarity)
#endregion

