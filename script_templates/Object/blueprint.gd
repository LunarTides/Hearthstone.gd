# meta-name: Blueprint
# meta-description: Card script
# meta-default: true
extends Blueprint


# Called when the card is created
func setup() -> void:
	card.add_ability(Card.Ability.BATTLECRY, battlecry)


func battlecry() -> void:
	print_debug("Battlecry")
