@icon("res://assets/icons/blueprint_optimized.svg")
class_name Blueprint
extends Node3D
## A class that stores the default data for cards.
## @experimental


#region Enums
enum {
	REFUND,
	SUCCESS,
}
#endregion


#region Exported Variables
#region Common
# TODO: Remove in Godot 4.3 or maybe 4.2.2
## This variable is to work around a bug. Please ignore.[br]
## See [url]https://github.com/godotengine/godot/pull/88318[/url]
@export var ignore: int

@export_category("Common")

## The card's name. This can be anything and doesn't have to be unique.
@export var card_name: String

## The card's description. This will appear in the middle of the card and should describe what the card does.[br]
## Avoid going into too much detail. Use proper grammar, spelling, and punctuation.
## [codeblock]
## # Bad
## "every time someone play a minion triger it's battlecry abilty 2 times (actually only 1 additional time since the battlecry alredy happens when palying the card first) the exact interacions / combos with other cards are ..."
## 
## # Good
## "Your Battlecries trigger twice."
## [/codeblock]
@export_multiline var text: String

## How much the card should cost, usually in [code]mana[/code].
@export var cost: int

# TODO: Continue documenting
@export var texture: Texture2D
@export var types: Array[StringName]
@export var classes: Array[StringName]
@export var rarities: Array[StringName]
@export var keywords: Array[StringName]
@export var tags: Array[StringName]
@export var collectible: bool

## This HAS to be unique per blueprint.
@export var id: int
#endregion


#region Minion
@export_category("Minion")
@export var tribes: Array[StringName]
#endregion


#region Minion / Weapon
@export_category("Minion / Weapon")
@export var attack: int
@export var health: int
#endregion


#region Spell
@export_category("Spell")
@export var spell_schools: Array[StringName]
#endregion


#region Hero
@export_category("Hero")
@export var armor: int
@export var hero_power_id: int
#endregion


#region Location
@export_category("Location")
@export var durability: int
@export var cooldown: int
#endregion

@export_category("Other")
@export var card: Card
#endregion


#region Public Variables
#region Enum-likes
static var all_types: Array[StringName] = [
	&"None",
	&"Minion",
	&"Spell",
	&"Weapon",
	&"Hero",
	&"Location",
	&"Hero_power",
]

static var all_tribes: Array[StringName] = [
	&"None",
	&"Beast",
	&"Demon",
	&"Dragon",
	&"Elemental",
	&"Mech",
	&"Murloc",
	&"Naga",
	&"Pirate",
	&"Quilboar",
	&"Totem",
	&"Undead",
	&"All",
]

static var all_spell_schools: Array[StringName] = [
	&"None",
	&"Arcane",
	&"Fel",
	&"Fire",
	&"Frost",
	&"Holy",
	&"Nature",
	&"Shadow",
]

static var all_rarities: Array[StringName] = [
	&"Free",
	&"Common",
	&"Rare",
	&"Epic",
	&"Legendary",
]

static var all_rarity_colors: Dictionary = {
	&"Free": Color.WHITE,
	&"Common": Color.GRAY,
	&"Rare": Color.BLUE,
	&"Epic": Color.PURPLE,
	&"Legendary": Color.GOLD,
}

static var all_tags: Array[StringName] = [
	&"Drag To Play",
	&"Starting Hero",
]

static var all_keywords: Array[StringName] = []

static var all_abilities: Array[StringName] = [
	&"Adapt",
	&"Battlecry",
	&"Cast",
	&"Combo",
	&"Deathrattle",
	&"Finale",
	&"Frenzy",
	&"Honorable Kill",
	&"Infuse",
	&"Inspire",
	&"Invoke",
	&"Outcast",
	&"Overheal",
	&"Overkill",
	&"Passive",
	&"Spellburst",
	&"Start Of Game",
	&"Hero Power",
	&"Use",
	&"Placeholder",
	&"Condition",
	&"Remove",
	&"Tick",
	&"Test",
]

static var all_cost_types: Array[StringName] = [
	&"Mana",
	&"Armor",
	&"Health",
]

static var Location: Array[StringName] = [
	&"None",
	&"Hand",
	&"Deck",
	&"Board",
	&"Graveyard",
	&"Hero",
	&"Hero Power",
]
#endregion


var player: Player:
	get:
		if not card.player:
			return Game.player
		
		return card.player
#endregion


#region Internal Functions
func _ready() -> void:
	card.blueprint = self
	
	if "setup" in self:
		self["setup"].call()
#endregion


#region Public Functions
func setup_blueprint(player: Player) -> void:
	card.player = player
	
	var tree: SceneTree = Engine.get_main_loop()
	tree.root.add_child(self)
#endregion


#region Static Functions
## Returns all filenames from the specified [param path].
static func get_all_filenames_from_path(path: String) -> Array[String]:
	var file_paths: Array[String] = []  
	var dir: DirAccess = DirAccess.open(path)  
	
	dir.list_dir_begin()  
	var file_name: String = dir.get_next()  

	while file_name != "":  
		var file_path: String = path + "/" + file_name  
		if dir.current_is_dir():  
			file_paths += Blueprint.get_all_filenames_from_path(file_path)  
		else:
			if file_path.ends_with(".tscn.remap"):
				file_path = file_path.replace(".remap", "")
			file_paths.append(file_path)  
		
		file_name = dir.get_next()  
	
	return file_paths


static func get_all_filenames() -> Array[String]:
	return Blueprint.get_all_filenames_from_path("res://cards").filter(func(file_path: String) -> bool:
		return file_path.contains(".tscn")
	)


## Gets all [Blueprint]s registered in the game. This function is very slow, so don't use it often.
static func get_all() -> Array:
	var files: Array[String] = Blueprint.get_all_filenames()
	
	var blueprints: Array = files.map(func(file_path: String) -> Blueprint: return load(file_path).instantiate())
	return blueprints


## Creates a [Blueprint] from the specified [param id]. Returns [code]null[/code] if no such blueprint exists.
static func create_from_id(id: int, player: Player) -> Blueprint:
	# Don't use `get_all` since we can optimize it by returning when the blueprint has been found.
	var files: Array[String] = Blueprint.get_all_filenames()
	
	for file_path: String in files:
		var blueprint: Blueprint = load(file_path).instantiate()
		
		if blueprint.id == id:
			blueprint.setup_blueprint(player)
			return blueprint
	
	return null


## Creates a [Blueprint] from the specified [param path].
static func create_from_path(path: String, player: Player) -> Blueprint:
	return Blueprint.create_from_packed_scene(load(path), player)


## Creates a [Blueprint] from the specified [param packed_scene].
static func create_from_packed_scene(packed_scene: PackedScene, player: Player) -> Blueprint:
	var blueprint: Blueprint = packed_scene.instantiate()
	blueprint.setup_blueprint(player)
	return blueprint
#endregion
