extends Node

func import(deckcode: String, player: Player) -> Dictionary:
	# Reference:
	# 1/30/1 - 30 Sheeps, Mage
	# 1/20,/1,2,3,4,5,6,7,8,9,a,b,c,d,e,f,10,11,12,13,14,15,16,17,18 - 1 copy of 20 cards, 2 copies of 5, Mage
	var split: PackedStringArray = deckcode.split("/")
	
	var hero_class: Enums.CLASS = split[0].to_int() as Enums.CLASS
	var copy_definition: String = split[1]
	var cards_string: String = split[2]
	
	var copy_definitions: PackedStringArray = copy_definition.split(",")
	
	var cards: Array[Card] = []
	
	var card_num: int = 0
	for card_id: String in cards_string.split(","):
		card_num += 1
		
		var id: int = card_id.hex_to_int()
		var copies: int = 1
		
		for def: String in copy_definitions:
			var i: int = copy_definitions.find(def)
			if card_num <= def.to_int():
				copies = i + 1
				break
		
		for _i: int in copies:
			cards.append(Game.get_card_from_blueprint(Game.get_blueprint_from_id(id), player))
		
		# If there are cards left over, add a copy of the last card until there are no cards left over.
		var remaining: int = copy_definitions[-1].to_int() - card_num
		while remaining > 0:
			cards.append(Game.get_card_from_blueprint(Game.get_blueprint_from_id(id), player))
			remaining -= 1
		
		assert(cards.size() == 30)
		
	
	return {"class": hero_class, "cards": cards}
