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
	
	return {
		"position": new_position,
		"rotation": card.rotation,
		"scale": Vector3.ONE,
	}


#region Hooks
func card_update_hook(card: Card) -> bool:
	if not card.location == &"Hero" or not TypeHeroModule.is_hero(card):
		return true
	
	# TODO: Figure out some other way to do this.
	#card.health = card.player.health
	#card.armor = card.player.armor
	
	return true
#endregion
#endregion
