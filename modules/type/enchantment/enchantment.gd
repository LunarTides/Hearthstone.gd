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
	
	var card_old_location: StringName = card.location
	var card_old_index: int = card.index
	
	# The game can only find the card when it is in a valid location.
	# Remove when replacing `Card.find_from_index` to `Card.find_from_uuid`.
	if card.location == &"None":
		card.add_to_location(&"Deck", 0)
	
	for e: Card in card.modules[&"_enchantments"]:
		var old_location: StringName = e.location
		var old_index: int = e.index
		
		# The game can only find the card when it is in a valid location.
		# Remove when replacing `Card.find_from_index` to `Card.find_from_uuid`.
		if e.location == &"None":
			e.add_to_location(&"Deck", 0)
		
		card._doing_enchantment = true
		e.trigger_ability(&"Undo", [card], false)
		card._doing_enchantment = false
		
		e.add_to_location(old_location, old_index)
	
	card.modules[&"_enchantments"].append(enchantment)
	
	# Sort by highest priority.
	card.modules[&"_enchantments"].sort_custom(func(a: Card, b: Card) -> bool:
		return a.enchantment_priority > b.enchantment_priority
	)
	
	for e: Card in card.modules[&"_enchantments"]:
		var old_location: StringName = e.location
		var old_index: int = e.index
		
		# The game can only find the card when it is in a valid location.
		# Remove when replacing `Card.find_from_index` to `Card.find_from_uuid`.
		if e.location == &"None":
			e.add_to_location(&"Deck", 0)
		
		card._doing_enchantment = true
		await e.trigger_ability(&"Do", [card], false)
		card._doing_enchantment = false
		
		e.add_to_location(old_location, old_index)
	
	card.add_to_location(card_old_location, card_old_index)
	
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
