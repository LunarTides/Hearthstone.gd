extends Module


#region Module Functions
func _name() -> StringName:
	return &"Enchantment"


func _dependencies() -> Array[StringName]:
	return [
		&"Type",
	]


func _load() -> void:
	register_hooks(handler)
	
	TypeModule.register_type(_name(), false)


func _unload() -> void:
	TypeModule.unregister_type(_name())
#endregion


#region Public Functions
func handler(what: Modules.Hook, info: Array) -> bool:
	if what == Modules.Hook.CARD_CREATE:
		card_create_hook.callv(info)
	
	return true


func add_enchantment(card: Card, enchantment: Card) -> bool:
	if not card.modules.has(&"_enchantments"):
		card.modules[&"_enchantments"] = []
	
	for e: Card in card.modules[&"_enchantments"]:
		e.trigger_ability(&"Undo")
	
	card.modules[&"_enchantments"].append(enchantment)
	
	# Sort by highest priority.
	card.modules[&"_enchantments"].sort_custom(func(a: Card, b: Card) -> bool:
		return a.enchantment_priority > b.enchantment_priority
	)
	
	for e: Card in card.modules[&"_enchantments"]:
		e.trigger_ability(&"Do")
	
	return true


func is_enchantment(card: Card) -> bool:
	return TypeModule.is_card_type(card, &"Enchantment")


#region Hooks
func card_create_hook(card: Card) -> bool:
	if is_enchantment(card):
		card.add_ability(&"Do", card[&"do"])
		card.add_ability(&"Undo", card[&"undo"])
	
	return true
#endregion
#endregion
