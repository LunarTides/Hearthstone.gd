# meta-name: Blueprint
# meta-description: Card script
# meta-default: true

func _ready(player: Player, card: Card) -> void:
	card.add_ability(Enums.ABILITY.BATTLECRY, battlecry)


func battlecry(player: Player, card: Card) -> void:
	print_debug("Battlecry")
