extends Resource
class_name Blueprint


@export_category("Common")
@export var name: String
@export var text: String
@export var cost: int
@export var texture: Texture2D
@export var types: Array[Enums.TYPE]
@export var classes: Array[Enums.CLASS]
@export var rarities: Array[Enums.RARITY]
@export var collectible: bool
@export var id: int

@export_category("Minion")
@export var tribes: Array[Enums.TRIBE]

@export_category("Minion / Weapon")
@export var attack: int
@export var health: int

@export_category("Spell")
@export var spell_schools: Array[Enums.SPELL_SCHOOL]

@export_category("Hero")
@export var armor: int
@export var heropower_id: int

@export_category("Location")
@export var durability: int
@export var cooldown: int
