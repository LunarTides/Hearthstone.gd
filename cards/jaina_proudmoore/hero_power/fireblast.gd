extends Blueprint


# Called when the card is created
func setup() -> void:
	card.add_ability(Card.Ability.HERO_POWER, hero_power)


func hero_power() -> void:
	print_debug("Hero Power")
