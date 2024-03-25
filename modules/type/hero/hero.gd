extends Node


#region Internal Functions
func _ready() -> void:
	Modules.register(&"Hero", [&"Type"], func() -> void:
		# Load module.
		Modules.register_hooks(&"Hero", self.handler)
		
		TypeModule.register_type(&"Hero", false)
	, func() -> void:
		# Unload module. No need to unregister hooks.
		TypeModule.unregister_type(&"Hero")
	)
#endregion


#region Public Functions
func handler(what: Modules.Hook, info: Array) -> bool:
	if what == Modules.Hook.CARD_PLAY:
		return await card_play_hook.callv(info)
	
	return true


func is_hero(card: Card) -> bool:
	return TypeModule.is_card_type(card, &"Hero")



#region Hooks
func card_play_hook(card: Card, board_index: int, position: Vector3i) -> bool:
	if not is_hero(card):
		return true
	
	card.trigger_ability(&"Battlecry", false)
	await card._wait_for_ability(&"Battlecry")
	
	if card.refunded:
		return false
	
	card.location = &"Hero"
	return true
#endregion
#endregion

