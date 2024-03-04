# meta-name: Blueprint
# meta-description: Card script
# meta-default: true
extends Blueprint


# Called when the card is created
func setup(player: Player, card: Card) -> void:
	card.add_ability(Card.Ability.BATTLECRY, battlecry)


func battlecry(player: Player, card: Card) -> void:
	print_debug("Battlecry")
