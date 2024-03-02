class_name Player
extends Resource
# TODO: Make more descriptive
## Player.
## @experimental


#region Enums
enum Class {
	NEUTRAL,
	MAGE,
	DRUID,
	HUNTER,
	WARRIOR,
	PRIEST,
	SHAMAN,
	PALADIN,
	WARLOCK,
	ROGUE,
	DEMON_HUNTER,
	DEATH_KNIGHT,
}
#endregion


#region Public Variables
## The player's name.
var name: String

## The player's id.
var id: int

## The player's class.
var hero_class: Class

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
	if card.types.has(Card.Type.MINION) and board.size() >= Game.max_board_space:
		Game.feedback("You don't have enough space on the board.", Game.FeedbackType.ERROR)
		return false
	
	if not Game.is_players_turn:
		Game.feedback("It is not your turn.", Game.FeedbackType.ERROR)
		return false
	
	if mana < card.cost:
		Game.feedback("You don't have enough mana.", Game.FeedbackType.ERROR)
		return false
	
	Game.send_packet_if(send_packet, Packet.PacketType.PLAY, id, [card.location, card.index, board_index], true)
	return true


## Sends a packet for the player to summon a card. Returns if a packet was sent / success.
func summon_card(card: Card, board_index: int, send_packet: bool = true) -> bool:
	if board.size() >= Game.max_board_space:
		return false
	
	Game.send_packet_if(send_packet, Packet.PacketType.SUMMON, id, [card.location, card.index, board_index], true)
	return true


## Sends a packet to add a card to the player's hand. Returns if a packet was sent / success.
func add_to_hand(card: Card, hand_index: int, send_packet: bool = true) -> bool:
	if hand.size() >= Game.max_hand_size:
		return false
	
	Game.send_packet_if(send_packet, Packet.PacketType.CREATE_CARD, id, [
		card.blueprint.resource_path,
		Card.Location.HAND,
		hand_index,
	], true)
	return true


## Sends a packet to add a card to the player's deck. Returns if a packet was sent / success.
func add_to_deck(card: Card, deck_index: int, send_packet: bool = true) -> bool:
	Game.send_packet_if(send_packet, Packet.PacketType.CREATE_CARD, id, [
		card.blueprint.resource_path,
		Card.Location.DECK,
		deck_index,
	], true)
	return true


## Sends a packet for the player to draw a card. Returns if a packet was sent / success.
func draw_cards(amount: int, send_packet: bool = true) -> bool:
	Game.send_packet_if(send_packet, Packet.PacketType.DRAW_CARDS, id, [amount], true)
	return true
#endregion
