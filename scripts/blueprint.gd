extends Resource
class_name Blueprint


#region Common
@export_category("Common")
@export var name: String
@export var text: String
@export var cost: int
@export var texture: Texture2D
@export var types: Array[Card.Type]
@export var classes: Array[Player.Class]
@export var rarities: Array[Card.Rarity]
@export var collectible: bool
@export var id: int
#endregion


#region Minion
@export_category("Minion")
@export var tribes: Array[Card.Tribe]
#endregion


#region Minion / Weapon
@export_category("Minion / Weapon")
@export var attack: int
@export var health: int
#endregion


#region Spell
@export_category("Spell")
@export var spell_schools: Array[Card.SpellSchool]
#endregion


#region Hero
@export_category("Hero")
@export var armor: int
@export var heropower_id: int
#endregion


#region Location
@export_category("Location")
@export var durability: int
@export var cooldown: int
#endregion
