class_name Card
extends Area3D
## This is the physical represantation of a card.
## @experimental


#region Signals
## Emits when the node is released from a drag.
signal released(position: Vector3)
#endregion


#region Constant Variables
const RARITY_COLOR: Dictionary = {
	Rarity.FREE: Color.WHITE,
	Rarity.COMMON: Color.GRAY,
	Rarity.RARE: Color.BLUE,
	Rarity.EPIC: Color.PURPLE,
	Rarity.LEGENDARY: Color.GOLD,
}
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


#region Exported Variables
## The texture / image of the card.
@export var texture_sprite: Sprite3D

## The cover of the card.
@export var cover: MeshInstance3D

## The name label of the card.
@export var name_label: Label3D

## The cost label of the card.
@export var cost_label: Label3D

## The text label of the card.
@export var text_label: Label3D

## The attack label of the card.
@export var attack_label: Label3D

## The health label of the card.
@export var health_label: Label3D

## The tribe label of the card.
@export var tribe_label: Label3D

## The spell school label of the card.
@export var spell_school_label: Label3D

@export var attack_particles: GPUParticles3D
#endregion


#region Public Variables
## The player that owns this card.
var player: Player

## The blueprint of this card.
var blueprint: Blueprint:
	set(new_blueprint):
		blueprint = new_blueprint
		update_blueprint()

## Whether or not the player is hovering over this card.
var is_hovering: bool = false

## Whether or not the player is dragging this card.
var is_dragging: bool = false

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

## Overrides [member is_hidden] if not set to [code]NULL[/code].
var override_is_hidden: Game.NullableBool = Game.NullableBool.NULL

## Whether or not the card is hidden. If it is, it will be covered by the [CardNode]. Cannot be set, set [member override_is_hidden] instead.
var is_hidden: bool:
	get:
		if override_is_hidden == Game.NullableBool.FALSE:
			return false
		if override_is_hidden == Game.NullableBool.TRUE:
			return true
		
		if location == Location.BOARD:
			return false
		
		if player != Game.player and not Multiplayer.is_server:
			return true
		
		if location == Location.HAND:
			return false
		
		return true
	set(new_is_hidden):
		is_hidden = new_is_hidden
		
		# Only change the essentials.
		cover.visible = is_hidden
		mesh.visible = not is_hidden
		texture_sprite.visible = not is_hidden
		name_label.visible = not is_hidden
		cost_label.visible = not is_hidden
		text_label.visible = not is_hidden
		
		if is_hidden:
			# Hide all the non-essentials in here.
			attack_label.hide()
			health_label.hide()
			tribe_label.hide()
			spell_school_label.hide()

# Whether or not this card has attacked this turn. Gets set to true every [signal Game.turn_ended] emission.
var has_attacked_this_turn: bool = false

# If this is [code]false[/code], the card cannot attack. Gets set to [code]true[/code] when the card is played. Gets set to [code]false[/code] when the turn ends.[br]
# You probably shouldn't set this.
var exhausted: bool = false

#region Blueprint Fields
#region Common
var card_name: String
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
#endregion


#region Private Variables
var _hover_tween: Tween
var _should_hover: bool = true

var _layout_tween: Tween
var _should_layout: bool = true
#endregion


#region Onready Variables
## The mesh of the card.
@onready var mesh: Node3D = $Mesh

@onready var _old_position: Vector3 = position
#endregion


#region Internal Functions
func _ready() -> void:
	Game.turn_ended.connect(func(_player: Player, _sender_peer_id: int) -> void:
		has_attacked_this_turn = false
		
		if location == Location.BOARD:
			exhausted = false
	)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if not card_name and blueprint:
		update_blueprint()
	
	_update()


func _input(event: InputEvent) -> void:
	if not is_dragging:
		return
	
	# Release lmb
	if not event is InputEventMouseButton:
		return
	
	if not event.is_released():
		return
	
	if not event.button_index == MOUSE_BUTTON_LEFT and not event.button_index == MOUSE_BUTTON_RIGHT:
		return
	
	_stop_dragging(event.button_index == MOUSE_BUTTON_LEFT)


func _exit_tree() -> void:
	get_parent().queue_free()
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
	
	Packet.send_if(send_packet, Packet.PacketType.TRIGGER_ABILITY, player.id, [location, index, ability])
	
	return true


## Adds an ability to this card.
func add_ability(ability_name: Ability, callback: Callable) -> void:
	if not abilities.has(ability_name):
		abilities[ability_name] = []
	
	abilities[ability_name].append(callback)


## Makes this card attack a [Card] or [Player].
func attack_target(target: Variant, send_packet: bool = true) -> bool:
	if not target:
		Game.feedback("That target is not valid.", Game.FeedbackType.ERROR)
		return false
	
	if target is Card:
		Packet.send_if(send_packet, Packet.PacketType.ATTACK, player.id, [Packet.AttackMode.CARD_VS_CARD, location, index, target.location, target.index])
	else:
		Packet.send_if(send_packet, Packet.PacketType.ATTACK, player.id, [Packet.AttackMode.CARD_VS_PLAYER, location, index, target.id, 0])
	
	return true


## Sets up the card to do an effect (particles, animations, etc...) in [param callback].
func do_effects(callback: Callable) -> void:
	_should_layout = false
	_should_hover = false
	
	var tween: Tween = create_tween().set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector3.ONE, 0.1)
	await tween.finished
	
	await callback.call()
	
	_should_layout = true
	_should_hover = true


## Tweens the card to the specified parameters over the course of [param duration] seconds.
func tween_to(duration: float, new_position: Vector3, new_rotation: Vector3 = rotation, new_scale: Vector3 = scale) -> void:
	_should_layout = false
	
	var tween: Tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE).set_parallel()
	tween.tween_property(self, "position", new_position, duration)
	tween.tween_property(self, "rotation", new_rotation, duration)
	tween.tween_property(self, "scale", new_scale, duration)
	await tween.finished


## Change the position / rotation of the card to be correct.
func layout(instant: bool = false) -> void:
	if not visible:
		return
	
	if is_hovering or not _should_layout:
		_layout_tween.kill()
		return
	
	var result: Dictionary = {}
	
	match location:
		Card.Location.HAND:
			result = _layout_hand()
		
		Card.Location.BOARD:
			result = _layout_board()
		
		Card.Location.DECK:
			result = _layout_deck()
		
		Card.Location.GRAVEYARD:
			result = _layout_graveyard()
		
		Card.Location.NONE:
			pass
		
		_:
			assert(false, "Can't layout the card in this location.")
	
	if not result:
		return
	
	var new_position: Vector3 = result.position
	var new_rotation: Vector3 = result.rotation
	var new_scale: Vector3 = result.scale
	
	if instant:
		position = new_position
		rotation = new_rotation
		scale = new_scale
	else:
		if _layout_tween:
			_layout_tween.kill()
		
		_layout_tween = create_tween().set_ease(Tween.EASE_OUT).set_parallel()
		_layout_tween.tween_property(self, "position", new_position, 0.5)
		_layout_tween.tween_property(self, "rotation", new_rotation, 0.5)
		_layout_tween.tween_property(self, "scale", new_scale, 0.5)
	
	_old_position = new_position
#endregion


#region Static Functions
## Gets all [CardNode]s for the specified player.
static func get_all_owned_by(player: Player) -> Array[Card]:
	var array: Array[Card] = []
	
	array.assign(get_all().filter(func(card: Card) -> bool:
		return card and card.player == player
	))
	
	return array


## Gets all [CardNode]s currently in the game scene.
static func get_all() -> Array[Card]:
	var array: Array[Card] = []
	var tree: SceneTree = Engine.get_main_loop()
	
	array.assign(tree.get_nodes_in_group("Cards").filter(func(card: Card) -> bool:
		return not card.is_queued_for_deletion()
	))
	return array


## Lays out all the cards. Only works client side.
static func layout_all() -> void:
	for card: Card in get_all():
		card.layout()


## Lays out all the cards for the specified player. Only works client side.
static func layout_all_owned_by(player: Player) -> void:
	for card: Card in get_all_owned_by(player):
		card.layout()


## Gets the [param player]'s [Card] in [param location] at [param index].
static func get_from_index(player: Player, location: Card.Location, index: int) -> Card:
	match location:
		Location.HAND:
			return Game.get_or_null(player.hand, index)
		Location.DECK:
			return Game.get_or_null(player.deck, index)
		Location.BOARD:
			return Game.get_or_null(player.board, index)
		Location.GRAVEYARD:
			return Game.get_or_null(player.graveyard, index)
		_:
			return null


# This is in a static function to work in editor scripts.
static func _update_card(card: Card, blueprint: Blueprint) -> void:
	var lookup: Variant = card
	
	if Engine.is_editor_hint():
		lookup = blueprint
	
	card.texture_sprite.texture = lookup.texture
	card.name_label.text = lookup.card_name
	card.cost_label.text = str(lookup.cost)
	card.text_label.text = lookup.text
	card.attack_label.text = str(lookup.attack)
	card.health_label.text = str(lookup.health)
	
	# Tribes
	var tribe_keys: PackedStringArray = PackedStringArray(Card.Tribe.keys())
	card.tribe_label.text = " / ".join(lookup.tribes.map(func(tribe: Card.Tribe) -> String: return tribe_keys[tribe].capitalize()))
	
	# Spell schools
	var spell_school_keys: PackedStringArray = PackedStringArray(Card.SpellSchool.keys())
	card.spell_school_label.text = " / ".join(lookup.spell_schools.map(func(spell_school: Card.SpellSchool) -> String: return spell_school_keys[spell_school].capitalize()))
	
	# Rarity Color
	var rarity_node: MeshInstance3D = card.get_node("Mesh/Rarity")
	
	var rarity_material: StandardMaterial3D = StandardMaterial3D.new()
	rarity_material.albedo_color = Card.RARITY_COLOR.get(lookup.rarities[0])
	rarity_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	rarity_node.set_surface_override_material(0, rarity_material)
	
	# Show non-essential labels
	if lookup.types.has(Card.Type.MINION):
		card.tribe_label.show()
	if lookup.types.has(Card.Type.SPELL):
		card.spell_school_label.show()
	
	
	card.get_node("Mesh/Attack").visible = blueprint.attack > 0
	card.attack_label.visible = blueprint.attack > 0
	
	card.get_node("Mesh/Health").visible = blueprint.health > 0
	card.get_node("Mesh/HealthFrame").visible = blueprint.health > 0
	card.health_label.visible = blueprint.health > 0
#endregion


#region Private Functions
func _wait_for_ability(target_ability: Ability) -> void:
	while true:
		var info: Array = await Game.card_ability_triggered
		
		var card: Card = info[0]
		var ability: Ability = info[1]
		
		if card == self and ability == target_ability:
			break


func _update() -> void:
	if location == Card.Location.NONE:
		remove_from_location()
		queue_free()
		return
	
	layout()
	
	is_hidden = is_hidden
	if is_hidden and location != Location.HAND and location != Location.BOARD:
		hide()
		return
	
	# TODO: Should this be done here?
	if health <= 0 and location == Location.BOARD:
		var old_scale: Vector3 = scale
		
		var tween: Tween = create_tween()
		tween.tween_property(self, "scale", Vector3.ZERO, 0.5).set_ease(Tween.EASE_OUT)
		
		await tween.finished
		
		add_to_location(Location.GRAVEYARD, player.graveyard.size())
		override_is_hidden = Game.NullableBool.NULL
		# HACK: Disabling the collision so it doesn't interfere.
		$CollisionShape3D.disabled = true
		
		await get_tree().process_frame
		
		scale = old_scale
		return
	
	show()
	
	Card._update_card(self, blueprint)


func _layout_hand() -> Dictionary:
	var new_position: Vector3 = position
	var new_rotation: Vector3 = rotation
	var new_scale: Vector3 = scale
	
	# TODO: Dont hardcode this
	var player_weight: int = 1 if player == Game.player else -1
	
	# Integer division, but it's not a problem.
	@warning_ignore("integer_division")
	var half_hand_size: int = player.hand.size() / 2
	
	new_position.x = -(half_hand_size * 2) + Game.card_bounds_x + (index * Game.card_distance_x)
	new_position.y = Game.card_bounds_y * abs(half_hand_size - index)
	new_position.z = Game.card_bounds_z * player_weight
	
	new_rotation = Vector3.ZERO
	
	if index != half_hand_size:
		# Tilt it to the left/right.
		new_rotation.y = deg_to_rad(Game.card_rotation_y_multiplier * player_weight * (half_hand_size - index))
	
	# Position it futher away the more rotated it is.
	# This makes it easier to select the right card.
	new_position.x -= new_rotation.y * player_weight
	
	# Rotate the card 180 degrees if it isn't already
	if player != Game.player and new_rotation.y < PI:
		new_rotation.y += PI
	
	new_scale = Vector3.ONE
	
	return {
		"position": new_position,
		"rotation": new_rotation,
		"scale": new_scale,
	}


func _layout_board() -> Dictionary:
	var new_position: Vector3 = position
	var new_rotation: Vector3 = rotation
	var new_scale: Vector3 = scale
	
	var player_weight: int = 1 if player == Game.player else -1
	
	new_rotation = Vector3.ZERO
	
	new_position.x = (index - 4) * 3.5 + Game.card_distance_x
	new_position.y = 0
	new_position.z = Game.board_node.player.position.z + player_weight * (
		# I love hardcoded values
		3 if Game.is_player_1
		else -6 if player == Game.opponent
		else 11
	)
	
	if Game.is_player_1 and player == Game.opponent:
		new_position.z += 1
	
	new_scale = Vector3.ONE
	
	return {
		"position": new_position,
		"rotation": new_rotation,
		"scale": new_scale,
	}


func _layout_deck() -> Dictionary:
	return {
		"position": Vector3(10, 0, -10),
		"rotation": rotation,
		"scale": scale,
	}


func _layout_graveyard() -> Dictionary:
	return {
		"position": Vector3(get_window().size.x, 0, get_window().size.y),
		"rotation": rotation,
		"scale": scale,
	}


func _on_input_event(_camera: Node, event: InputEvent, pos: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	# Don't drag if this is an opposing card
	if Game.player != player or Multiplayer.is_server:
		return
	
	if event is InputEventMouseButton and event.is_pressed():
		_start_dragging()
	elif event is InputEventMouseMotion:
		_process_dragging(pos)


func _start_hover() -> void:
	if is_dragging or not _should_hover or not visible:
		return
	
	is_hovering = true
	if _layout_tween:
		_layout_tween.kill()
	
	# Animate
	var player_weight: int = 1 if player == Game.player else -1
	var time: float = 0.1
	
	_hover_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO).set_parallel()
	_hover_tween.tween_property(self, "position:y", 1, time)
	_hover_tween.tween_property(self, "position:z", position.z - (4 * player_weight), time)
	_hover_tween.tween_property(self, "rotation:y", 0, time)
	_hover_tween.tween_property(self, "scale", Vector3(2, 2, 2), time)


func _stop_hover() -> void:
	if is_dragging or not _should_hover or not visible:
		return
	
	if _hover_tween:
		_hover_tween.kill()
	
	is_hovering = false
	layout()


func _start_dragging() -> void:
	if not is_hovering or not visible:
		return
	
	# Don't drag if this is an opposing card
	if Game.player != player or Multiplayer.is_server:
		return
	
	if location == Location.BOARD:
		_start_attacking()
		return
	
	is_dragging = true


func _stop_dragging(released_lmb: bool) -> void:
	if not visible:
		return
	
	var pos: Vector3 = global_position
	
	is_dragging = false
	_stop_hover()
	_make_way()
	
	if released_lmb:
		released.emit(pos)


func _process_dragging(pos: Vector3) -> void:
	if not is_dragging or not visible:
		return
	
	global_position = Vector3(pos.x, global_position.y, pos.z)
	_make_way()


func _start_attacking() -> void:
	if not Game.is_players_turn:
		Game.feedback("You cannot attack on your opponent's turn.", Game.FeedbackType.ERROR)
		return
	
	if exhausted:
		Game.feedback("Wait one turn before attacking with this card.", Game.FeedbackType.ERROR)
		return
	
	if has_attacked_this_turn:
		Game.feedback("This card has already attacked this turn.", Game.FeedbackType.ERROR)
		return
	
	var target: Variant = await Target.prompt(position, self, Target.CAN_SELECT_CARDS | Target.CAN_SELECT_HEROES | Target.CAN_SELECT_ENEMY_TARGETS)
	
	if target is Card:
		if target.location != Location.BOARD:
			return
	
	attack_target(target) 


func _make_way(stop: bool = false) -> void:
	for card: Card in Card.get_all_owned_by(player).filter(func(card: Card) -> bool:
		return card != self and card.location == Card.Location.BOARD
	):
		if is_dragging:
			card._make_way_for(self)
		else:
			card._stop_making_way()


func _make_way_for(card: Card) -> void:
	if not visible:
		return
	
	var bias: int = 1 if global_position.x > card.global_position.x else -1
	
	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:x", _old_position.x + 2 * bias, 0.2)
	_should_layout = false


func _stop_making_way() -> void:
	_should_layout = true
	layout()
#endregion
