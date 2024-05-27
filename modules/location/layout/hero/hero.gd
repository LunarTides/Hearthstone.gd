extends Module


#region Module Functions
func _name() -> StringName:
	return &"LayoutHero"


func _dependencies() -> Array[StringName]:
	return [
		&"Layout",
	]


func _load() -> void:
	register_hooks(handler)
	
	LayoutModule.register_layout(&"Hero", layout_hero)


func _unload() -> void:
	LayoutModule.unregister_layout(&"Hero")
#endregion


#region Public Functions
func handler(what: Modules.Hook, info: Array) -> bool:
	if what == Modules.Hook.CARD_UPDATE:
		return card_update_hook.callv(info)
	
	return true


func layout_hero(card: Card) -> Dictionary:
	var new_position: Vector3 = card.position
	
	if card.player == Game.player:
		new_position = (await Game.wait_for_node("/root/Main/PlayerHero")).position
	else:
		new_position = (await Game.wait_for_node("/root/Main/OpponentHero")).position
	
	if not is_instance_valid(card):
		return {
			"position": Vector3.ZERO,
			"rotation": Vector3.ZERO,
			"scale": Vector3.ZERO,
		}
	
	return {
		"position": new_position,
		"rotation": card.rotation,
		"scale": Vector3.ONE,
	}


#region Hooks
func card_update_hook(card: Card) -> bool:
	if not card.location == &"Hero" or not TypeHeroModule.is_hero(card):
		return true
	
	# TODO: Set the undo values to the non-enchantment version.
	_add_dynamic_enchantment(card, &"health", card.player.health, card.player.health)
	_add_dynamic_enchantment(card, &"armor", card.player.armor, card.player.armor)
	
	return true
#endregion
#endregion


#region Private Functions
func _add_dynamic_enchantment(card: Card, field: StringName, do_value: Variant, undo_value: Variant) -> void:
	if card.modules.has(&"_layout_hero_last_%s_dynamic_enchantment" % field):
		var dynamic_enchantment: DynamicEnchantment = card.modules[&"_layout_hero_last_%s_dynamic_enchantment" % field]
		
		TypeEnchantmentModule.remove_enchantment(card, dynamic_enchantment)
		dynamic_enchantment.destroy()
		dynamic_enchantment.queue_free()
	
	var dynamic_enchantment: DynamicEnchantment = Card.create_from_id(7, card.player)
	dynamic_enchantment.field = field
	dynamic_enchantment.do_value = do_value
	dynamic_enchantment.undo_value = undo_value
	
	TypeEnchantmentModule.add_enchantment(card, dynamic_enchantment)
	
	card.modules[&"_layout_hero_last_%s_dynamic_enchantment" % field] = dynamic_enchantment
#endregion
