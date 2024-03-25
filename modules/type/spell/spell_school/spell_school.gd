extends Node


#region Constants
const SPELL_SCHOOL_MESH: PackedScene = preload("res://modules/type/spell/spell_school/spell_school.blend")
const SPELL_SCHOOL_LABEL_SCENE: PackedScene = preload("res://modules/type/spell/spell_school/spell_school_label.tscn")
#endregion


#region Public Variables
var spell_schools: Array[StringName] = []
#endregion


#region Internal Functions
func _ready() -> void:
	Modules.register(&"Spell School", [&"Spell"], func() -> void:
		# Load module.
		Modules.register_hooks(&"Spell School", self.handler)
		Modules.register_card_mesh(&"Spell School", SPELL_SCHOOL_MESH, Vector3(0, 0.2, 2))
		
		register_spell_school(&"None")
		register_spell_school(&"Arcane")
		register_spell_school(&"Fel")
		register_spell_school(&"Fire")
		register_spell_school(&"Frost")
		register_spell_school(&"Holy")
		register_spell_school(&"Nature")
		register_spell_school(&"Shadow")
	, func() -> void:
		# Unload module. No need to unregister hooks.
		Modules.unregister_card_mesh(&"Spell School")
		
		unregister_spell_school(&"None")
		unregister_spell_school(&"Arcane")
		unregister_spell_school(&"Fel")
		unregister_spell_school(&"Fire")
		unregister_spell_school(&"Frost")
		unregister_spell_school(&"Holy")
		unregister_spell_school(&"Nature")
		unregister_spell_school(&"Shadow")
	)
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
	var spell_school_label: Label3D = SPELL_SCHOOL_LABEL_SCENE.instantiate()
	blueprint.card.add_child(spell_school_label, true)
	
	return true


func card_change_hidden_hook(card: Card, value: bool) -> bool:
	var spell_school_label: Label3D = card.get_node_or_null("SpellSchoolLabel")
	if not spell_school_label:
		return true
	
	spell_school_label.hide()
	return true


func card_update_hook(card: Card) -> bool:
	var spell_school_label: Label3D = card.get_node_or_null("SpellSchoolLabel")
	if not spell_school_label:
		return true
	
	var spell_school_visible: bool = TypeSpellModule.is_spell(card)
	
	card.get_node("Mesh/SpellSchool").visible = spell_school_visible
	
	spell_school_label.text = " / ".join(get_spell_schools_from_card(card))
	spell_school_label.visible = spell_school_visible
	
	return true
#endregion
#endregion

