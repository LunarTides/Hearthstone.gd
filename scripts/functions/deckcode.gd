extends Node


## Loads and decodes the specified [param deckcode]. Returns [code]{"class": Enums.CLASS, "cards": Array[Card]}[/code]
func import(deckcode: String, player: Player) -> Dictionary:
	# Reference:
	# 1/1:30/1 - 30 Sheeps, Mage
	# 1/1:20,2:5,3/1,2,3,4,5,6,7,8,9,a,b,c,d,e,f,10,11,12,13,14,15,16,17,18 - 1 copy of 20 cards, 2 copies of 5, Mage
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
		
		var i: int = 0
		for def: String in copy_definitions:
			# def = 1:30 or 1
			var def_split: PackedStringArray = def.split(":")
			
			if def_split.size() < 2:
				copies = def.to_int()
				break
			
			var amount: int = def_split[0].to_int()
			var cps: int = def_split[1].to_int()
			
			var target: int = amount
			if i > 0:
				# E.g. /20,5,/ Becomes /20,25,/
				target += copy_definitions[i - 1].split(":")[1].to_int()
			
			if card_num <= target:
				copies = cps
				break
			
			i += 1
		
		for _i: int in copies:
			cards.append(Game.get_card_from_blueprint(Game.get_blueprint_from_id(id), player))
	
	return {"class": hero_class, "cards": cards}
