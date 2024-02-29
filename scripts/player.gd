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

## The player's class.
var hero_class: Enums.CLASS

## How much mana the player currently has.
var mana: int = 0

## How many empty mana crystals the player has. Increases every turn until it reaches [member max_mana].
var empty_mana: int = 0

## The maximum number that [member empty_mana] can go to.
var max_mana: int = 10

## The player's hand.
var hand: Array[Card]

## The player's deck.
var deck: Array[Card]

## The player's board.
var board: Array[Card]

## The player's graveyard.
var graveyard: Array[Card]

## The player's opponent.
var opponent: Player:
	get:
		return Game.get_player_from_id(1 - id)

## The player's deckcode.
var deckcode: String

## The player's peer id.
var peer_id: int
#endregion


#region Public Functions
## Sends a packet for the player to play a card. Returns if a packet was sent / success.
func play_card(card: Card, board_index: int, send_packet: bool = true) -> bool:
	if card.types.has(Enums.TYPE.MINION) and board.size() >= Game.max_board_space:
		Game.error_text = "You don't have enough space on the board."
		return false
	
	if not Game.is_players_turn:
		Game.error_text = "It is not your turn."
		return false
	
	if mana < card.cost:
		Game.error_text = "You don't have enough mana."
		return false
	
	Game.send_packet_if(send_packet, Enums.PACKET_TYPE.PLAY, id, [card.location, card.index, board_index], true)
	return true


## Sends a packet for the player to summon a card. Returns if a packet was sent / success.
func summon_card(card: Card, board_index: int, send_packet: bool = true) -> bool:
	if board.size() >= Game.max_board_space:
		return false
	
	Game.send_packet_if(send_packet, Enums.PACKET_TYPE.SUMMON, id, [card.location, card.index, board_index], true)
	return true


## Sends a packet to add a card to the player's hand. Returns if a packet was sent / success.
func add_to_hand(card: Card, hand_index: int, send_packet: bool = true) -> bool:
	if hand.size() >= Game.max_hand_size:
		return false
	
	Game.send_packet_if(send_packet, Enums.PACKET_TYPE.CREATE_CARD, id, [
		card.blueprint.resource_path,
		Enums.LOCATION.HAND,
		hand_index,
	], true)
	return true


## Sends a packet to add a card to the player's deck. Returns if a packet was sent / success.
func add_to_deck(card: Card, deck_index: int, send_packet: bool = true) -> bool:
	Game.send_packet_if(send_packet, Enums.PACKET_TYPE.CREATE_CARD, id, [
		card.blueprint.resource_path,
		Enums.LOCATION.DECK,
		deck_index,
	], true)
	return true


## Sends a packet for the player to draw a card. Returns if a packet was sent / success.
func draw_cards(amount: int, send_packet: bool = true) -> bool:
	Game.send_packet_if(send_packet, Enums.PACKET_TYPE.DRAW_CARDS, id, [amount], true)
	return true
#endregion
