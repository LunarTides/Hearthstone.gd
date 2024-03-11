extends Node


#region Public Functions
## Loads and decodes the specified [param deckcode]. Returns [code]{"class": Player.Class, "cards": Array[Card]}[/code]
func import(deckcode: String, player: Player, validate: bool = true) -> Dictionary:
	# Reference:
	# 1/1:30/1 - 30 Sheeps, Mage
	# 1/1:20,2:5,3/1,2,3,4,5,6,7,8,9,a,b,c,d,e,f,10,11,12,13,14,15,16,17,18 - 1 copy of 20 cards, 2 copies of 5, Mage
	var split: PackedStringArray = deckcode.split("/")
	
	var hero_class: Player.Class = split[0].to_int() as Player.Class
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
			var blueprint: Blueprint = Blueprint.create_from_id(id, player)
			
			if player:
				blueprint.card.add_to_location(Card.Location.DECK, player.deck.size())
			
			cards.append(blueprint.card)
	
	if validate and not _validate_deck(deckcode, hero_class, cards):
		return {}
	
	return {"class": hero_class, "cards": cards}


## Returns [code]true[/code] if [param deckcode] is a valid deckcode.
func validate(deckcode: String) -> bool:
	return import(deckcode, Game.player1).has("cards")
#endregion


#region Private Functions
func _validate_deck(deckcode: String, hero_class: Player.Class, cards: Array[Card]) -> bool:
	if deckcode == "1/1:30/1":
		# TODO: Uncomment
		#return OS.is_debug_build()
		return true
	
	# There should be no uncollectible cards.
	if cards.any(func(card: Card) -> bool: return not card.collectible):
		return false
	
	# The size of the deck shouldn't be more than the max_deck_size or less than min_deck_size.
	if cards.size() > Settings.server.max_deck_size or cards.size() < Settings.server.min_deck_size:
		return false
	
	# The hero class should exist.
	if not Player.Class.values().has(hero_class):
		return false
	
	return true
#endregion
