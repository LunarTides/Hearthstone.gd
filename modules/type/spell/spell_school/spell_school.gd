extends Module


#region Constants
const SPELL_SCHOOL_MESH: PackedScene = preload("res://modules/type/spell/spell_school/spell_school.blend")
const SPELL_SCHOOL_LABEL: PackedScene = preload("res://modules/type/spell/spell_school/spell_school_label.tscn")
#endregion


#region Public Variables
var spell_schools: Array[StringName] = []
#endregion


#region Module Functions
func _name() -> StringName:
	return &"SpellSchool"


func _dependencies() -> Array[StringName]:
	return [
		&"Spell",
	]


func _load() -> void:
	register_hooks(handler)
	register_card_mesh(SPELL_SCHOOL_MESH)
	
	register_spell_school(&"None")
	register_spell_school(&"Arcane")
	register_spell_school(&"Fel")
	register_spell_school(&"Fire")
	register_spell_school(&"Frost")
	register_spell_school(&"Holy")
	register_spell_school(&"Nature")
	register_spell_school(&"Shadow")


func _unload() -> void:
	unregister_spell_school(&"None")
	unregister_spell_school(&"Arcane")
	unregister_spell_school(&"Fel")
	unregister_spell_school(&"Fire")
	unregister_spell_school(&"Frost")
	unregister_spell_school(&"Holy")
	unregister_spell_school(&"Nature")
	unregister_spell_school(&"Shadow")
#endregion


#region Public Functions
func handler(what: Modules.Hook, info: Array) -> bool:
	if what == Modules.Hook.BLUEPRINT_CREATE:
		return blueprint_create_hook.callv(info)
	elif what == Modules.Hook.CARD_CHANGE_HIDDEN:
		return card_change_hidden_hook.callv(info)
	elif what == Modules.Hook.CARD_UPDATE:
		return card_update_hook.callv(info)
	
	return true


# TODO: Return Array[StringName] in 4.3
func get_spell_schools_from_card(card: Card) -> Array:
	if not card.modules.has("spell_schools"):
		return []
	
	return card.modules.spell_schools


func register_spell_school(spell_school: StringName) -> void:
	spell_schools.append(spell_school)


func unregister_spell_school(spell_school: StringName) -> void:
	spell_schools.erase(spell_school)



#region Hooks
func blueprint_create_hook(blueprint: Blueprint) -> bool:
	var spell_school_label: Label3D = SPELL_SCHOOL_LABEL.instantiate()
	blueprint.card.add_child(spell_school_label, true)
	
	return true


func card_change_hidden_hook(card: Card, value: bool) -> bool:
	var spell_school_label: Label3D = card.get_node_or_null("SpellSchoolLabel")
	if not spell_school_label:
		return true
	
	spell_school_label.visible = not value
	return true


func card_update_hook(card: Card) -> bool:
	var spell_school_label: Label3D = card.get_node_or_null("SpellSchoolLabel")
	var spell_school_mesh: MeshInstance3D = card.get_node_or_null("Mesh/SpellSchool/SpellSchool")
	
	if not spell_school_label or not spell_school_mesh:
		return true
	
	var spell_school_visible: bool = TypeSpellModule.is_spell(card)
	
	spell_school_mesh.visible = spell_school_visible
	
	spell_school_label.text = " / ".join(get_spell_schools_from_card(card))
	spell_school_label.visible = spell_school_visible
	
	return true
#endregion
#endregion

