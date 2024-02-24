extends Resource
class_name Player
# TODO: Make more descriptive
## Player.
## @experimental


#region Public Variables
## The player's name.
var name: String

## The player's id.
var id: int

var hero_class: Enums.CLASS

## The player's hand.
var hand: Array[Card]

## The player's deck.
var deck: Array[Card]

## The player's board.
var board: Array[Card]

## The player's graveyard.
var graveyard: Array[Card]

var opponent: Player:
	get:
		return Game.get_player_from_id(1 - id)
#endregion


#region Public Functions
func play_card(card: Card, board_index: int) -> void:
	if card.types.has(Enums.TYPE.MINION) and board.size() >= Game.max_board_space:
		return
	
	Game.send_packet(Enums.PACKET_TYPE.PLAY, id, [card.location, card.index, board_index], true)


func summon_card(card: Card, board_index: int) -> void:
	if board.size() >= Game.max_board_space:
		return
	
	Game.send_packet(Enums.PACKET_TYPE.SUMMON, id, [card.location, card.index, board_index], true)


func add_to_hand(card: Card, hand_index: int) -> void:
	if hand.size() >= Game.max_hand_size:
		return
	
	Game.send_packet(Enums.PACKET_TYPE.CREATE_CARD, id, [
		card.blueprint.resource_path,
		Enums.LOCATION.HAND,
		hand_index,
	], true)


func add_to_deck(card: Card, deck_index: int) -> void:
	Game.send_packet(Enums.PACKET_TYPE.CREATE_CARD, id, [
		card.blueprint.resource_path,
		Enums.LOCATION.DECK,
		deck_index,
	], true)


func draw_card(amount: int) -> void:
	Game.send_packet(Enums.PACKET_TYPE.DRAW_CARDS, id, [amount], true)
#endregion
