extends Module


#region Constants
const HEALTH_MESH: PackedScene = preload("res://modules/health/health.blend")

const HEALTH_LABEL: PackedScene = preload("res://modules/health/health_label.tscn")
#endregion


#region Module Functions
func _name() -> StringName:
	return &"Health"


func _dependencies() -> Array[StringName]:
	return []


func _load() -> void:
	register_card_mesh(HEALTH_MESH)


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
	var health_label: Label3D = HEALTH_LABEL.instantiate()
	blueprint.card.add_child(health_label, true)
	
	return true


func card_change_hidden_hook(card: Card, value: bool) -> bool:
	# Hide Health
	var health_label: Label3D = card.get_node_or_null("HealthLabel")
	if not health_label:
		return true
	
	health_label.visible = not value
	return true


func card_update_hook(card: Card) -> bool:
	# Health
	var health_visible: bool = card.health > 0 or card.blueprint.health > 0
	
	var health_mesh: MeshInstance3D = card.get_node_or_null("Mesh/Health/Health")
	if health_mesh:
		health_mesh.visible = health_visible
		card.get_node("Mesh/Health/HealthFrame").visible = health_visible
	
	# Health Label
	var health_label: Label3D = card.get_node_or_null("HealthLabel")
	if health_label:
		health_label.text = str(card.health)
		health_label.visible = health_visible
	
	return true
#endregion
#endregion
