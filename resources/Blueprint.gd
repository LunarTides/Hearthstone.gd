extends Resource
class_name Blueprint

const ENUMS = preload("res://scripts/Enums.gd")

@export_category("Common")
@export var name: String
@export var text: String
@export var cost: int
@export var type: ENUMS.TYPE
@export var classes: Array[ENUMS.CLASS]
@export var rarities: Array[ENUMS.RARITY]
@export var collectible: bool
@export var id: int
@export var abilities: Array[Ability]

@export_category("Minion")
@export var tribes: Array[ENUMS.TRIBE]

@export_category("Minion / Weapon")
@export var attack: int
@export var health: int

@export_category("Weapon")
@export var durability: int

@export_category("Spell")
@export var spell_schools: Array[ENUMS.SPELL_SCHOOL]

@export_category("Hero")
@export var heropower_id: int

@export_category("Location")
@export var cooldown: int
