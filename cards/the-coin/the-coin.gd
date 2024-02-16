extends Blueprint


# Called when the card is created
func _ready(player: Player, card: Card) -> void:
	card.add_ability(Enums.ABILITY.CAST, cast)


func cast(player: Player, card: Card) -> void:
	print_debug("Cast")
