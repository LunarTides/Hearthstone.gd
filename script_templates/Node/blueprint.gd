# meta-name: Blueprint
# meta-description: Card script
# meta-default: true
extends Blueprint


# Called when the card is created
func setup() -> void:
	card.add_ability(&"Battlecry", battlecry)


func battlecry() -> int:
	print_debug("Battlecry")
	
	return SUCCESS
