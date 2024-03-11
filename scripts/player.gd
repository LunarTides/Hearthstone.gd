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

## How much health the player has.
var health: int = 30:
	set(new_health):
		health = new_health
		
		if health <= 0 and should_die:
			# TODO: Have an animation or something.
			print("Player %d won!" % (opponent.id + 1))
			
			# TODO: Wait until the animation is finished instead of 1 second.
			await Game.get_tree().create_timer(1.0).timeout
			Multiplayer.quit()

## The maximum number that [member health] can go to.
var max_health: int = 30

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
		return Player.get_from_id(1 - id)

## The player's deckcode.
var deckcode: String

## The player's peer id.
var peer_id: int

## The player's [HeroNode].
var hero: HeroNode:
	get:
		var main: Node3D = await Game.wait_for_node("/root/Main")
		
		if self == Game.player:
			return main.player_hero_node
		else:
			return main.opponent_hero_node

## Whether or not this player should die. Used for animations.
var should_die: bool = true:
	set(new_should_die):
		should_die = new_should_die
		
		# HACK: Trigger the setter function.
		health = health
#endregion


#region Static Functions
## Gets the [Player] with the specified [param id].
static func get_from_id(id: int) -> Player:
	if Multiplayer.is_server:
		if id == 0:
			return Game._player1_server
		else:
			return Game._player2_server
	
	if id == 0:
		return Game.player1
	else:
		return Game.player2


## Returns the [Player] from the [param peer_id].
static func get_from_peer_id(peer_id: int) -> Player:
	return Multiplayer.players.get(peer_id)
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
	
	Packet.send_if(send_packet, Packet.PacketType.PLAY, id, [card.location, card.index, board_index, Vector3i(card.position.round())], true)
	return true


## Sends a packet for the player to summon a card. Returns if a packet was sent / success.
func summon_card(card: Card, board_index: int, send_packet: bool = true, bypass_checks: bool = false) -> bool:
	if not bypass_checks:
		if board.size() >= Game.max_board_space:
			return false
	
	Packet.send_if(send_packet, Packet.PacketType.SUMMON, id, [card.location, card.index, board_index], true)
	return true


## Sends a packet to add a card to the player's hand. Returns if a packet was sent / success.
func add_to_hand(card: Card, hand_index: int, send_packet: bool = true) -> bool:
	if hand.size() >= Game.max_hand_size:
		return false
	
	Packet.send_if(send_packet, Packet.PacketType.CREATE_CARD, id, [
		card.id,
		Card.Location.HAND,
		hand_index,
	], true)
	return true


## Sends a packet to add a card to the player's deck. Returns if a packet was sent / success.
func add_to_deck(card: Card, deck_index: int, send_packet: bool = true) -> bool:
	Packet.send_if(send_packet, Packet.PacketType.CREATE_CARD, id, [
		card.id,
		Card.Location.DECK,
		deck_index,
	], true)
	return true


## Sends a packet for the player to draw a card. Returns if a packet was sent / success.
func draw_cards(amount: int, send_packet: bool = true) -> bool:
	Packet.send_if(send_packet, Packet.PacketType.DRAW_CARDS, id, [amount], true)
	return true
#endregion
