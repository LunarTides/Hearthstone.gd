extends Node


#region Internal Functions
func _ready() -> void:
	Modules.register(&"Minion", [&"Type"], func() -> void:
		# Load module.
		Modules.register_hooks(&"Minion", self.handler)
		
		TypeModule.register_type(&"Minion", true)
	, func() -> void:
		# Unload module. No need to unregister hooks.
		TypeModule.unregister_type(&"Minion")
	)
#endregion


#region Public Functions
func handler(what: Modules.Hook, info: Array) -> bool:
	if what == Modules.Hook.CARD_PLAY:
		return await card_play_hook.callv(info)
	
	return true


func is_minion(card: Card) -> bool:
	return TypeModule.is_card_type(card, &"Minion")



#region Hooks
func card_play_hook(card: Card, board_index: int, position: Vector3i) -> bool:
	if not is_minion(card):
		return true
	
	if card.abilities.has(&"Battlecry"):
		card.trigger_ability(&"Battlecry", false)
		await card._wait_for_ability(&"Battlecry")
		
		if card.refunded:
			return false
	
	# Summon after ability for refunding.
	# Kinda gross...
	card.player.summon_card(card, board_index, false, true)
	return true
#endregion
#endregion

