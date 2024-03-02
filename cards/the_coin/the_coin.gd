extends Blueprint


# Called when the card is created
func _ready(player: Player, card: Card) -> void:
	#name = "The Coin"
	#text = "Gain 1 Mana Crystal this turn only."
	#cost = 0
	#texture = load("res://cards/the-coin/the-coin.png")
	#types = Array[Card.Type.SPELL]
	#classes = Array[Player.Class.NEUTRAL]
	#rarities = Array[Card.Rarity.FREE]
	#collectible = false
	#id = 2
	#
	#spell_schools = Array[Card.SpellSchool.NONE]
	
	
	card.add_ability(Card.Ability.CAST, cast)


func cast(player: Player, card: Card) -> void:
	# Gain 1 Mana Crystal this turn only.
	
	# We don't need to send a packet since this will get run on all clients and the server.
	player.mana += 1
