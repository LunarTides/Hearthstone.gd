extends Resource
class_name Card


signal blueprint_updated(old_blueprint: Blueprint, new_blueprint: Blueprint)

@export var player: Player
@export var blueprint: Blueprint:
	set(new_blueprint):
		blueprint_updated.emit(blueprint, new_blueprint)
		blueprint = new_blueprint
		update_blueprint()

@export var scene: PackedScene

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


func _ready() -> void:
	if "_ready" in blueprint:
		blueprint._ready(player, self)
	
	update_blueprint()


func update_blueprint() -> void:
	# Assign the blueprint properties to this card
	for prop: Dictionary in blueprint.get_property_list():
		if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE != 0 and prop.name in self:
			self[prop.name] = blueprint[prop.name]


func trigger_ability(name: Enums.ABILITY) -> bool:
	if not abilities.has(name):
		return false
	
	for ability: Callable in abilities[name]:
		ability.call(player, self)
	
	return true


func add_ability(name: Enums.ABILITY, callback: Callable) -> void:
	if not abilities.has(name):
		abilities[name] = []
	
	abilities[name].append(callback)
