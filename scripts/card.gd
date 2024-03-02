class_name Card
extends Resource
# TODO: Make more descriptive.
## The main card resource.
## @experimental


#region Signals
## Emitted when the [member blueprint] gets changed.
signal blueprint_updated(old_blueprint: Blueprint, new_blueprint: Blueprint)
#endregion


#region Enums
enum Type {
	NONE,
	MINION,
	SPELL,
	WEAPON,
	HERO,
	LOCATION,
	HEROPOWER,
}

enum Tribe {
	NONE,
	BEAST,
	DEMON,
	DRAGON,
	ELEMENTAL,
	MECH,
	MURLOC,
	NAGA,
	PIRATE,
	QUILBOAR,
	TOTEM,
	UNDEAD,
	ALL,
}

enum SpellSchool {
	NONE,
	ARCANE,
	FEL,
	FIRE,
	FROST,
	HOLY,
	NATURE,
	SHADOW,
}

enum Rarity {
	FREE,
	COMMON,
	RARE,
	EPIC,
	LEGENDARY,
}

enum Keyword {
	DIVINE_SHIELD,
	DORMANT,
	LIFESTEAL,
	POISONOUS,
	REBORN,
	RUSH,
	STEALTH,
	TAUNT,
	TRADEABLE,
	FORGE,
	WINDFURY,
	OUTCAST,
	CAST_ON_DRAW,
	SUMMON_ON_DRAW,
	UNBREAKABLE,
	UNLIMITED_ATTACKS,
	CHARGE,
	MEGA_WINDFURY,
	ECHO,
	MAGNETIC,
	TWINSPELL,
	ELUSIVE,
	FROZEN,
	IMMUNE,
	CORRUPT,
	COLOSSAL,
	INFUSE,
	CLEAVE,
	TITAN,
	FORGETFUL,
	CANT_ATTACK,
}

enum Ability {
	ADAPT,
	BATTLECRY,
	CAST,
	COMBO,
	DEATHRATTLE,
	FINALE,
	FRENZY,
	HONORABLE_KILL,
	INFUSE,
	INSPIRE,
	INVOKE,
	OUTCAST,
	OVERHEAL,
	OVERKILL,
	PASSIVE,
	SPELLBURST,
	START_OF_GAME,
	HERO_POWER,
	USE,
	PLACEHOLDER,
	CONDITION,
	REMOVE,
	TICK,
	TEST,
}

enum CostType {
	MANA,
	ARMOR,
	HEALTH,
}

enum Location {
	NONE,
	HAND,
	DECK,
	BOARD,
	GRAVEYARD,
}
#endregion


#region Constants
const RARITY_COLOR: Dictionary = {
	Rarity.FREE: Color.WHITE,
	Rarity.COMMON: Color.GRAY,
	Rarity.RARE: Color.BLUE,
	Rarity.EPIC: Color.PURPLE,
	Rarity.LEGENDARY: Color.GOLD,
}
#endregion


#region Exported Variables
## The player that owns this card.
@export var player: Player

## The blueprint of this card.
@export var blueprint: Blueprint:
	set(new_blueprint):
		blueprint_updated.emit(blueprint, new_blueprint)
		blueprint = new_blueprint
		update_blueprint()
#endregion


#region Public Variables
#region Blueprint Fields
#region Common
var name: String
var text: String
var cost: int
var texture: Texture2D
var types: Array[Type]
var classes: Array[Player.Class]
var rarities: Array[Rarity]
var collectible: bool
var id: int
#endregion


#region Minion
var tribes: Array[Tribe]
#endregion


#region Minion / Weapon
var attack: int
var health: int
#endregion


#region Spell
var spell_schools: Array[SpellSchool]
#endregion


#region Hero
var armor: int
var heropower_id: int
#endregion


#region Location
var durability: int
var cooldown: int
#endregion
#endregion


## The card's keywords. Looks like this: [code]{Keyword: "Any additional info", Keyword.DORMANT: 2}[/code]
var keywords: Dictionary

## The card's abiltiies. Looks like this: [code]{Ability: Array[Callable]}[/code]
var abilities: Dictionary

## Where the card is in it's [member location].
var index: int:
	get:
		return location_array.find(self)

## Where the card is. E.g. HAND, BOARD, DECK, ...
var location: Location = Location.NONE:
	set(new_location):
		remove_from_location()
		location = new_location

## Returns the array where the card is stored according to it's [member location].
var location_array: Array[Card]:
	get:
		match location:
			Location.HAND:
				return player.hand
			Location.DECK:
				return player.deck
			Location.BOARD:
				return player.board
			Location.GRAVEYARD:
				return player.graveyard
			Location.NONE:
				return []
			_:
				push_error("Invalid Location")
				assert(false, "Invalid Location")
				return []

## The [CardNode] of the card.
var card_node: CardNode:
	get:
		return CardNode.get_all().filter(func(card_node: CardNode) -> bool: return card_node.card == self)[0]

## Overrides [member is_hidden] if not set to [code]NULL[/code].
var override_is_hidden: Game.NullableBool = Game.NullableBool.NULL

## Whether or not the card is hidden. If it is, it will be covered by the [CardNode]. Cannot be set, set [member override_is_hidden] instead.
var is_hidden: bool:
	get:
		if Multiplayer.is_server:
			return false
		
		if override_is_hidden == Game.NullableBool.FALSE:
			return false
		if override_is_hidden == Game.NullableBool.TRUE:
			return true
		
		return player != Game.player and (location == Location.HAND or location == Location.DECK)
#endregion


#region Internal Functions
func _ready() -> void:
	if "_ready" in blueprint:
		blueprint._ready(player, self)
	
	update_blueprint()
#endregion


#region Static Functions
## Gets the [param player]'s [Card] in [param location] at [param index].
static func get_from_index(player: Player, location: Card.Location, index: int) -> Card:
	match location:
		Location.HAND:
			return player.hand[index]
		Location.DECK:
			return player.deck[index]
		Location.BOARD:
			return player.board[index]
		Location.GRAVEYARD:
			return player.graveyard[index]
		_:
			return null


## Gets all [Card]s for the specified player.
static func get_all_owned_by(player: Player) -> Array[Card]:
	return get_all().filter(func(card: Card) -> bool: return card.player == player)


## Gets all [Card]s currently in the game scene.
static func get_all() -> Array[Card]:
	var array: Array[Card] = []
	
	array.assign(CardNode.get_all().map(func(card_node: CardNode) -> Card:
		return card_node.card
	))
	
	return array



## Creates a card with the specified [param blueprint] with the specified [param player] as its owner.
static func get_from_blueprint(blueprint: Blueprint, player: Player) -> Card:
	var card: Card = Card.new()
	card.blueprint = blueprint
	card.player = player
	return card
#endregion


#region Public Functions
## Update the Blueprint fields like [member name] to the blueprint.
func update_blueprint() -> void:
	# Assign the blueprint properties to this card
	for prop: Dictionary in blueprint.get_property_list():
		if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE != 0 and prop.name in self:
			self[prop.name] = blueprint[prop.name]


## Removes the card from its [member location].
func remove_from_location() -> void:
	location_array.erase(self)


## Add the card to the correct [param index] in it's [member location].
func add_to_location(new_location: Location, index: int) -> void:
	remove_from_location()
	
	location = new_location
	location_array.insert(index, self)


## Triggers an ability.
func trigger_ability(ability: Ability, send_packet: bool = true) -> bool:
	if not abilities.has(ability):
		return false
	
	Game.send_packet_if(send_packet, Packet.PacketType.TRIGGER_ABILITY, player.id, [location, index, ability])
	
	return true


## Adds an ability to this card.
func add_ability(ability_name: Ability, callback: Callable) -> void:
	if not abilities.has(ability_name):
		abilities[ability_name] = []
	
	abilities[ability_name].append(callback)
#endregion
