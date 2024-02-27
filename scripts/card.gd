class_name Card
extends Resource
# TODO: Make more descriptive.
## The main card resource.
## @experimental


#region Signals
## Emitted when the [member blueprint] gets changed.
signal blueprint_updated(old_blueprint: Blueprint, new_blueprint: Blueprint)
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
var types: Array[Enums.TYPE]
var classes: Array[Enums.CLASS]
var rarities: Array[Enums.RARITY]
var collectible: bool
var id: int
#endregion

#region Minion
var tribes: Array[Enums.TRIBE]
#endregion

#region Minion / Weapon
var attack: int
var health: int
#endregion

#region Spell
var spell_schools: Array[Enums.SPELL_SCHOOL]
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


## The card's keywords. Looks like this: [code]{Enums.KEYWORD: "Any additional info", Enums.KEYWORD.DORMANT: 2}[/code]
var keywords: Dictionary

## The card's abiltiies. Looks like this: [code]{Enums.ABILITY: Array[Callable]}[/code]
var abilities: Dictionary

## Where the card is in it's [member location].
var index: int:
	get:
		return location_array.find(self)

## Where the card is. E.g. HAND, BOARD, DECK, ...
var location: Enums.LOCATION = Enums.LOCATION.NONE:
	set(new_location):
		location = new_location
		
		Game.layout_cards(player)

## Returns the array where the card is stored according to it's [member location].
var location_array: Array[Card]:
	get:
		match location:
			Enums.LOCATION.HAND:
				return player.hand
			Enums.LOCATION.DECK:
				return player.deck
			Enums.LOCATION.BOARD:
				return player.board
			Enums.LOCATION.GRAVEYARD:
				return player.graveyard
			Enums.LOCATION.NONE:
				return []
			_:
				push_error("Invalid Location")
				assert(false, "Invalid Location")
				return []

## The [CardNode] of the card.
var card_node: CardNode:
	get:
		return Game.get_all_card_nodes().filter(func(card_node: CardNode) -> bool: return card_node.card == self)[0]

## Overrides [member is_hidden] if not set to [code]NULL[/code].
var override_is_hidden: Enums.NULLABLE_BOOL = Enums.NULLABLE_BOOL.NULL

## Whether or not the card is hidden. If it is, it will be covered by the [CardNode]. Cannot be set, set [member override_is_hidden] instead.
var is_hidden: bool:
	get:
		if Multiplayer.is_server:
			return false
		
		if override_is_hidden == Enums.NULLABLE_BOOL.FALSE:
			return false
		if override_is_hidden == Enums.NULLABLE_BOOL.TRUE:
			return true
		
		return player != Game.player and (location == Enums.LOCATION.HAND or location == Enums.LOCATION.DECK)
#endregion


#region Internal Functions
func _ready() -> void:
	if "_ready" in blueprint:
		blueprint._ready(player, self)
	
	update_blueprint()
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
func add_to_location(new_location: Enums.LOCATION, index: int) -> void:
	remove_from_location()
	
	location = new_location
	location_array.insert(index, self)


## Triggers an ability.
func trigger_ability(ability: Enums.ABILITY) -> bool:
	if not abilities.has(ability):
		return false
	
	Game.send_packet(Enums.PACKET_TYPE.TRIGGER_ABILITY, player.id, [location, index, ability])
	
	return true


## Adds an ability to this card.
func add_ability(ability_name: Enums.ABILITY, callback: Callable) -> void:
	if not abilities.has(ability_name):
		abilities[ability_name] = []
	
	abilities[ability_name].append(callback)
#endregion
