extends Node


#region Internal Functions
func _ready() -> void:
	Modules.register(&"Spell", [&"Type"], func() -> void:
		# Load module.
		Modules.register_hooks(&"Spell", self.handler)
		
		TypeModule.register_type(&"Spell", false)
	, func() -> void:
		# Unload module. No need to unregister hooks.
		TypeModule.unregister_type(&"Spell")
	)
#endregion


#region Public Functions
func handler(what: Modules.Hook, info: Array) -> bool:
	if what == Modules.Hook.CARD_PLAY:
		return await card_play_hook.callv(info)
	
	return true


func is_spell(card: Card) -> bool:
	return TypeModule.is_card_type(card, &"Spell")



#region Hooks
func card_play_hook(card: Card, board_index: int, position: Vector3i) -> bool:
	if not is_spell(card):
		return true
	
	card.trigger_ability(&"Cast", false)
	await card._wait_for_ability(&"Cast")
	
	if card.refunded:
		return false
	
	card.location = &"None"
	return true
#endregion
#endregion

