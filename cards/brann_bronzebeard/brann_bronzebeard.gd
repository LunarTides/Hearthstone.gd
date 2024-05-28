extends Card


# Called when the card is created
# TODO: Add _ to all ability functions.
func setup() -> void:
	add_ability(&"Battlecry", battlecry)


func battlecry() -> int:
	var callback: Callable = func(after: bool, played_card: Card, board_index: int, player_who_played: Player, sender_peer_id: int) -> void:
		if not after:
			# TODO: Implement better solution.
			played_card.should_do_effects = false
			# TODO: Change this to battlecry.
			played_card.trigger_ability(&"Cast", [], false)
			played_card.should_do_effects = true
	
	Game.card_played.connect(callback)
	
	Game.card_killed.connect(func(after: bool, killed_card: Card, player: Player, sender_peer_id: int) -> void:
		if not after and killed_card == self:
			Game.card_played.disconnect(callback)
	)
	
	return SUCCESS
