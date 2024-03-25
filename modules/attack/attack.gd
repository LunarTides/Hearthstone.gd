extends Module


#region Constants
const ATTACK_MESH: PackedScene = preload("res://modules/attack/attack.blend")

const ATTACK_LABEL: PackedScene = preload("res://modules/attack/attack_label.tscn")
#endregion


#region Module Functions
func _name() -> StringName:
	return &"Attack"


func _dependencies() -> Array[StringName]:
	return []


func _load() -> void:
	register_card_mesh(ATTACK_MESH)


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
	var attack_label: Label3D = ATTACK_LABEL.instantiate()
	blueprint.card.add_child(attack_label, true)
	
	return true


func card_change_hidden_hook(card: Card, value: bool) -> bool:
	# Hide Attack
	var attack_label: Label3D = card.get_node_or_null("AttackLabel")
	if not attack_label:
		return true
	
	attack_label.visible = not value
	return true


func card_update_hook(card: Card) -> bool:
	# Attack
	var attack_visible: bool = card.attack > 0 or card.blueprint.attack > 0
	
	var attack_mesh: MeshInstance3D = card.get_node_or_null("Mesh/Attack/Attack")
	if attack_mesh:
		attack_mesh.visible = attack_visible
	
	# Attack Label
	var attack_label: Label3D = card.get_node_or_null("AttackLabel")
	if attack_label:
		attack_label.text = str(card.attack)
		attack_label.visible = attack_visible
	
	return true
#endregion
#endregion
