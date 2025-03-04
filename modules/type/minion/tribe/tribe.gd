extends Module


#region Constants
const TRIBE_MESH: PackedScene = preload("res://modules/type/minion/tribe/tribe.blend")
const TRIBE_LABEL: PackedScene = preload("res://modules/type/minion/tribe/tribe_label.tscn")
#endregion


#region Public Variables
var tribes: Array[StringName] = []
#endregion


#region Module Functions
func _name() -> StringName:
	return &"Tribe"


func _dependencies() -> Array[StringName]:
	return [
		&"Minion",
	]


func _load() -> void:
	register_hooks(handler)
	register_card_mesh(TRIBE_MESH)
	
	register_tribe(&"None")
	register_tribe(&"Beast")
	register_tribe(&"Demon")
	register_tribe(&"Dragon")
	register_tribe(&"Elemental")
	register_tribe(&"Mech")
	register_tribe(&"Murloc")
	register_tribe(&"Naga")
	register_tribe(&"Pirate")
	register_tribe(&"Quilboar")
	register_tribe(&"Totem")
	register_tribe(&"Undead")
	register_tribe(&"All")


func _unload() -> void:
	unregister_tribe(&"None")
	unregister_tribe(&"Beast")
	unregister_tribe(&"Demon")
	unregister_tribe(&"Dragon")
	unregister_tribe(&"Elemental")
	unregister_tribe(&"Mech")
	unregister_tribe(&"Murloc")
	unregister_tribe(&"Naga")
	unregister_tribe(&"Pirate")
	unregister_tribe(&"Quilboar")
	unregister_tribe(&"Totem")
	unregister_tribe(&"Undead")
	unregister_tribe(&"All")
#endregion


#region Public Functions
func handler(what: Modules.Hook, info: Array) -> bool:
	if what == Modules.Hook.CARD_CREATE:
		return card_create_hook.callv(info)
	elif what == Modules.Hook.CARD_CHANGE_HIDDEN:
		return card_change_hidden_hook.callv(info)
	elif what == Modules.Hook.CARD_UPDATE:
		return card_update_hook.callv(info)
	
	return true


# TODO: Return Array[StringName] in 4.3
func get_tribes_from_card(card: Card) -> Array:
	if not card.modules.has("tribes"):
		return []
	
	return card.modules.tribes


func register_tribe(tribe: StringName) -> void:
	tribes.append(tribe)


func unregister_tribe(tribe: StringName) -> void:
	tribes.erase(tribe)



#region Hooks
func card_create_hook(card: Card) -> bool:
	var tribe_label: Label3D = TRIBE_LABEL.instantiate()
	card.add_child(tribe_label, true)
	
	return true


func card_change_hidden_hook(card: Card, value: bool) -> bool:
	var tribe_label: Label3D = card.get_node_or_null("TribeLabel")
	if not tribe_label:
		return true
	
	tribe_label.visible = not value
	return true


func card_update_hook(card: Card) -> bool:
	var tribe_label: Label3D = card.get_node_or_null("TribeLabel")
	if not tribe_label:
		return true
	
	var tribe_visible: bool = TypeMinionModule.is_minion(card)
	
	card.get_node("Mesh/Tribe/Tribe").visible = tribe_visible
	
	tribe_label.text = " / ".join(get_tribes_from_card(card))
	tribe_label.visible = tribe_visible
	
	return true
#endregion
#endregion

