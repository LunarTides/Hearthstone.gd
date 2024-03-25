extends Module


#region Constants
const ARMOR_MESH: PackedScene = preload("res://modules/armor/armor.blend")

const ARMOR_LABEL: PackedScene = preload("res://modules/armor/armor_label.tscn")
#endregion


#region Module Functions
func _name() -> StringName:
	return &"Armor"


func _dependencies() -> Array[StringName]:
	return []


func _load() -> void:
	register_card_mesh(ARMOR_MESH)


func _unload() -> void:
	pass
#endregion


#region Public Functions
func register(module_name: StringName) -> void:
	Modules._register_hooks(module_name, handler)


func handler(what: Modules.Hook, info: Array) -> bool:
	if what == Modules.Hook.BLUEPRINT_CREATE:
		return blueprint_create_hook.callv(info)
	elif what == Modules.Hook.CARD_CHANGE_HIDDEN:
		return card_change_hidden_hook.callv(info)
	elif what == Modules.Hook.CARD_UPDATE:
		return card_update_hook.callv(info)
	
	return true



#region Hooks
func blueprint_create_hook(blueprint: Blueprint) -> bool:
	var armor_label: Label3D = ARMOR_LABEL.instantiate()
	blueprint.card.add_child(armor_label, true)
	
	return true


func card_change_hidden_hook(card: Card, value: bool) -> bool:
	# Hide Armor
	var armor_label: Label3D = card.get_node_or_null("ArmorLabel")
	if not armor_label:
		return true
	
	armor_label.visible = not value
	return true


func card_update_hook(card: Card) -> bool:
	# Armor
	var armor_visible: bool = card.armor > 0 or card.blueprint.armor > 0 or card.location == &"Hero"
	
	var armor_mesh: MeshInstance3D = card.get_node_or_null("Mesh/Armor/Armor")
	if armor_mesh:
		armor_mesh.visible = armor_visible
	
	var armor_label: Label3D = card.get_node_or_null("ArmorLabel")
	if not armor_label:
		return true
	
	# Armor Label exists.
	armor_label.visible = armor_visible
	armor_label.text = str(card.armor)
	
	if Modules.has_module(&"Health"):
		var health_visible: bool = card.health > 0 or card.blueprint.health > 0
		
		# Move armor to the other side if health is visible.
		if armor_mesh:
			armor_mesh.position.x = 0.0 if health_visible else 2.6
		if armor_label:
			armor_label.position.x = -1.3 if health_visible else 1.3
	
	return true
#endregion
#endregion
