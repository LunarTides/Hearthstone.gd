class_name Blueprint
extends Node3D
## @experimental


#region Exported Variables
#region Common
@export_category("Common")
@export var card_name: String
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

@export_category("Other")
@export var card: Card
#endregion


#region Public Variables
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
	
	if Engine.get_main_loop().current_scene == self:
		assert(false, "Playing blueprints scenes directly is not implemented yet. See https://github.com/LunarTides/Hearthstone.gd/issues/2")
#endregion


#region Public Functions
func setup_blueprint(player: Player) -> void:
	card.player = player
	
	var tree: SceneTree = Engine.get_main_loop()
	tree.root.add_child(self)
#endregion


#region Static Functions
## Creates a [Blueprint] from the specified [param id]. Returns [code]null[/code] if no such blueprint exists.
static func create_from_id(id: int, player: Player) -> Blueprint:
	var files: Array[String] = Game.get_all_files_from_path("res://cards")
	
	for file_path: String in files:
		if not file_path.contains(".tscn"):
			continue
		
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
