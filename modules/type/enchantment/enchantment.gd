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
	elif what == Modules.Hook.CARD_FIELD_CHANGE:
		card_field_change_hook.callv(info)
	elif what == Modules.Hook.CARD_FIELD_GET:
		card_field_get_hook.callv(info)
	
	return true


func add_enchantment(card: Card, enchantment: Card) -> bool:
	if not card.modules.has(&"_enchantments"):
		card.modules[&"_enchantments"] = []
	
	_apply_enchantments(card, true)
	card.modules[&"_enchantments"].append(enchantment)
	_apply_enchantments(card, false)
	
	return true


func remove_enchantment(card: Card, enchantment: Card) -> bool:
	if not card.modules.has(&"_enchantments"):
		card.modules[&"_enchantments"] = []
	
	_apply_enchantments(card, true)
	card.modules[&"_enchantments"].erase(enchantment)
	_apply_enchantments(card, false)
	
	return true


func is_enchantment(card: Card) -> bool:
	return TypeModule.is_card_type(card, &"Enchantment")


#region Hooks
func card_create_hook(card: Card) -> bool:
	if is_enchantment(card):
		card.add_ability(&"Do", card[&"do"])
		card.add_ability(&"Undo", card[&"undo"])
	
	return true


func card_field_change_hook(card: Card, field: StringName, value: Variant) -> bool:
	if card._initializing:
		return true
	
	if card.modules.has(&"_doing_enchantment"):
		if not card.modules.has(&"_enchantment_changes"):
			card.modules[&"_enchantment_changes"] = {}
		
		card.modules[&"_enchantment_changes"][field] = value
	else:
		push_error("Trying to manually change an exported card field (%s) to %s (%s). Please add an enchantment instead." % [field, value, type_string(typeof(value))])
		assert(false, "Trying to manually change an exported card field (%s) to %s (%s). Please add an enchantment instead." % [field, value, type_string(typeof(value))])
	
	return false


func card_field_get_hook(card: Card, field: StringName) -> bool:
	Modules.suppressed_hooks.push_back(Modules.Hook.CARD_FIELD_GET)
	
	if not card.modules.has(&"_enchantment_changes") or not card.modules[&"_enchantment_changes"].has(field):
		return true
	
	card.field_hook_changes[field] = card.modules[&"_enchantment_changes"][field]
	Modules.suppressed_hooks.erase(Modules.Hook.CARD_FIELD_GET)
	return false
#endregion
#endregion


#region Private Functions
func _apply_enchantments(card: Card, before: bool) -> void:
	var card_old_location: StringName = card.location
	var card_old_index: int = card.index
	
	if before:
		# The game can only find the card when it is in a valid location.
		# Remove when replacing `Card.find_from_index` to `Card.find_from_uuid`.
		if card.location == &"None":
			card.add_to_location(&"Deck", 0)
		
		for e: Card in card.modules[&"_enchantments"]:
			var old_location: StringName = e.location
			var old_index: int = e.index
			if old_index == -1:
				old_index = 0
			
			# The game can only find the card when it is in a valid location.
			# Remove when replacing `Card.find_from_index` to `Card.find_from_uuid`.
			if e.location == &"None":
				e.add_to_location(&"Deck", 0)
			
			card.modules[&"_doing_enchantment"] = true
			e.trigger_ability(&"Undo", [card], false)
			card.modules[&"_doing_enchantment"] = false
			
			e.add_to_location(old_location, old_index)
	else:
		# Sort by highest priority.
		card.modules[&"_enchantments"].sort_custom(func(a: Card, b: Card) -> bool:
			if not a.modules.has(&"enchantment"):
				a.modules[&"enchantment"] = {}
			if not b.modules.has(&"enchantment"):
				b.modules[&"enchantment"] = {}
			
			return a.modules[&"enchantment"][&"priority"] > b.modules[&"enchantment"][&"priority"]
		)
		
		for e: Card in card.modules[&"_enchantments"]:
			var old_location: StringName = e.location
			var old_index: int = e.index
			if old_index == -1:
				old_index = 0
			
			# The game can only find the card when it is in a valid location.
			# Remove when replacing `Card.find_from_index` to `Card.find_from_uuid`.
			if e.location == &"None":
				e.add_to_location(&"Deck", 0)
			
			card.modules[&"_doing_enchantment"] = true
			await e.trigger_ability(&"Do", [card], false)
			card.modules[&"_doing_enchantment"] = false
			
			e.add_to_location(old_location, old_index)
		
		card.add_to_location(card_old_location, card_old_index)
#endregion
