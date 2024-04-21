class_name Player
extends Resource
# TODO: Make more descriptive
## Player.
## @experimental


#region Enum-likes
var Class: Array[StringName] = [
	&"Neutral",
	&"Mage",
	&"Druid",
	&"Hunter",
	&"Warrior",
	&"Priest",
	&"Shaman",
	&"Paladin",
	&"Warlock",
	&"Rogue",
	&"Demon Hunter",
	&"Death Knight",
]
#endregion


#region Public Variables
## The player's name.
var name: String

## The player's id.
var id: int

## The player's class.
var hero_class: StringName

## How much health the player has. DON'T SET MANUALLY.
var health: int = 30

## The maximum number that [member health] can go to.
var max_health: int = 30

## The amount of armor that the player currently has.
var armor: int = 0

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

## The player's hero [Card].
var hero: Card:
	get:
		return Card.get_all_owned_by(self).filter(func(card: Card) -> bool: return card.location == &"Hero")[0]

## Whether or not this player should die. Used for animations.
var should_die: bool = true:
	set(new_should_die):
		should_die = new_should_die
		
		# Check if the player should die.
		_die()

## Whether or not this player has already used their hero power this turn.
var has_used_hero_power_this_turn: bool = false
#endregion


#region Public Functions
## Sends a packet for the player to play a card. Returns if a packet was sent / success.
func play_card(card: Card, board_index: int, send_packet: bool = true) -> bool:
	if card.types.has(&"Minion") and board.size() >= Settings.server.max_board_space:
		Game.feedback("You don't have enough space on the board.", Game.FeedbackType.ERROR)
		return false
	
	if not Game.is_players_turn:
		Game.feedback("It is not your turn.", Game.FeedbackType.ERROR)
		return false
	
	if mana < card.cost:
		Game.feedback("You don't have enough mana.", Game.FeedbackType.ERROR)
		return false
	
	if not await Modules.request(Modules.Hook.CARD_PLAY_CHECK, [self, card, board_index, send_packet]):
		return false
	
	if card.location == &"Hero Power":
		if has_used_hero_power_this_turn:
			Game.feedback("You have already used your hero power this turn.", Game.FeedbackType.ERROR)
			return false
		
		Packet.send_if(send_packet, &"Hero Power", id, [], true)
		return true
	
	Packet.send_if(send_packet, &"Play", id, [card.location, card.index, board_index, Vector3i(card.position.round())], true)
	return true


## Sends a packet for the player to summon a card. Returns if a packet was sent / success.
func summon_card(card: Card, board_index: int, send_packet: bool = true) -> bool:
	if board.size() >= Settings.server.max_board_space:
		return false
	
	if not await Modules.request(Modules.Hook.CARD_SUMMON, [self, card, board_index, send_packet]):
		return false
		
	Packet.send_if(send_packet, &"Summon", id, [card.location, card.index, board_index], true)
	return true


## Sends a packet to add a card to the player's hand. Returns if a packet was sent / success.
func add_to_hand(card: Card, hand_index: int, send_packet: bool = true) -> bool:
	if hand.size() >= Settings.server.max_hand_size:
		return false
	
	if not await Modules.request(Modules.Hook.CARD_ADD_TO_HAND, [self, card, hand_index, send_packet]):
		return false
	
	Packet.send_if(send_packet, &"Create Card", id, [
		card.id,
		&"Hand",
		hand_index,
	], true)
	return true


## Sends a packet to add a card to the player's deck. Returns if a packet was sent / success.
func add_to_deck(card: Card, deck_index: int, send_packet: bool = true) -> bool:
	if not await Modules.request(Modules.Hook.CARD_ADD_TO_DECK, [self, card, deck_index, send_packet]):
		return false
	
	Packet.send_if(send_packet, &"Create Card", id, [
		card.id,
		&"Deck",
		deck_index,
	], true)
	return true


## Sends a packet for the player to draw a card. Returns if a packet was sent / success.
func draw_cards(amount: int, send_packet: bool = true) -> bool:
	if not await Modules.request(Modules.Hook.DRAW_CARDS, [self, amount, send_packet]):
		return false
	
	Packet.send_if(send_packet, &"Draw Cards", id, [amount], true)
	return true


## Deals [param amount] damage to this player. Does not send a packet.
func damage(amount: int) -> bool:
	if not await Modules.request(Modules.Hook.DAMAGE, [self, amount, absi(armor - amount)]):
		return false
	
	# Armor logic
	if armor > 0:
		var remaining_armor: int = armor - amount
		armor = maxi(remaining_armor, 0)
		
		# Armor blocks all damage.
		if remaining_armor >= 0:
			return true
		
		# The amount of damage to take is however much damage penetrated the armor.
		amount = absi(remaining_armor)
	
	health -= amount
	_die()
	
	return true
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


#region Private Functions
func _die() -> void:
	if not await Modules.request(Modules.Hook.PLAYER_DIE, [self]):
		return
	
	if health > 0 or not should_die:
		return
	
	# TODO: Have an animation or something.
	print("Player %d won!" % (opponent.id + 1))
	
	# TODO: Wait until the animation is finished instead of 1 second.
	Game.get_tree().paused = true
	await Game.get_tree().create_timer(1.0).timeout
	Multiplayer.quit()
	Game.get_tree().paused = false
#endregion
