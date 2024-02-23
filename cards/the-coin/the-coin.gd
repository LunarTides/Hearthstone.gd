extends Blueprint


# Called when the card is created
func _ready(player: Player, card: Card) -> void:
	#name = "The Coin"
	#text = "Gain 1 Mana Crystal this turn only."
	#cost = 0
	#texture = load("res://cards/the-coin/the-coin.png")
	#types = Array[Enums.TYPE.SPELL]
	#classes = Array[Enums.CLASS.NEUTRAL]
	#rarities = Array[Enums.RARITY.FREE]
	#collectible = false
	#id = 2
	#
	#spell_schools = Array[Enums.SPELL_SCHOOL.NONE]
	
	
	card.add_ability(Enums.ABILITY.CAST, cast)


func cast(player: Player, card: Card) -> void:
	# Reveal a random enemy card.
	if Multiplayer.is_server:
		var random_cards: Array[Card] = Game.get_cards_for_player(player.opponent).filter(func(card: Card) -> bool: return card.override_is_hidden == Enums.NULLABLE_BOOL.NULL)
		if random_cards.size() <= 0:
			return
		
		var random_card: Card = random_cards.pick_random()
		
		Game.send_packet(Enums.PACKET_TYPE.REVEAL, player.opponent.id, [random_card.location, random_card.index], true)
