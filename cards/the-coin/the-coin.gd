extends Blueprint

func ability(name: Enums.ABILITY, plr: Player, card: Card):
	if name == Enums.ABILITY.CAST:
		print("Cast")
	else:
		print(name)
