extends Blueprint


# Called when the card is created
func setup() -> void:
	card.add_ability(Card.Ability.BATTLECRY, battlecry)


func battlecry() -> void:
	var callback: Callable = func(after: bool, played_card: Card, board_index: int, player_who_played: Player, sender_peer_id: int) -> void:
		if not after:
			# TODO: Implement better solution.
			played_card.should_do_effects = false
			# TODO: Change this to battlecry.
			played_card.trigger_ability(Card.Ability.CAST, false)
			played_card.should_do_effects = true
	
	Game.card_played.connect(callback)
	
	Game.card_killed.connect(func(after: bool, killed_card: Card, player: Player, sender_peer_id: int) -> void:
		if not after and killed_card == card:
			Game.card_played.disconnect(callback)
	)

