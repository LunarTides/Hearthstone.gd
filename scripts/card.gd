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

var keywords: Dictionary
var abilities: Dictionary

var index: int:
	get:
		match location:
			Enums.LOCATION.HAND:
				return player.hand.find(self)
			Enums.LOCATION.DECK:
				return player.deck.find(self)
			Enums.LOCATION.BOARD:
				return player.board.find(self)
			Enums.LOCATION.GRAVEYARD:
				return player.graveyard.find(self)
			_:
				return -1

var location: Enums.LOCATION = Enums.LOCATION.NONE
var card_node: CardNode:
	get:
		return Game.get_all_card_nodes().filter(func(card_node: CardNode) -> bool: return card_node.card == self)[0]

var override_is_hidden: Enums.NULLABLE_BOOL = Enums.NULLABLE_BOOL.NULL
var is_hidden: bool:
	get:
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


## Add the card to the correct [param index] in it's [member location].
func add_to_location(index: int) -> void:
	player.hand.erase(self)
	player.deck.erase(self)
	player.board.erase(self)
	player.graveyard.erase(self)
	
	match location:
		Enums.LOCATION.HAND:
			player.hand.insert(index, self)
		Enums.LOCATION.DECK:
			player.deck.insert(index, self)
		Enums.LOCATION.BOARD:
			player.board.insert(index, self)
		Enums.LOCATION.GRAVEYARD:
			player.graveyard.insert(index, self)
		_:
			push_error("Invalid Location")
			assert(false, "Invalid Location")


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
