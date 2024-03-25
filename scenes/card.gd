@icon("res://assets/icons/card_optimized.svg")
class_name Card
extends Area3D
## The physical representation of a card.
## @experimental


#region Signals
## Emits when the node is released from a drag.
signal released(position: Vector3)
#endregion


#region Exported Variables
## The texture / image of the card.
@export var texture_sprite: Sprite3D

## The cover of the card.
@export var cover: MeshInstance3D

## Particles to emit when the card gets attacked.
@export var attack_particles: GPUParticles3D

## A timer used to update the card every 0.1 seconds.
@export var update_timer: Timer

@export_category("Common")
## The name label of the card.
@export var name_label: Label3D

## The cost label of the card.
@export var cost_label: Label3D

## The text label of the card.
@export var text_label: Label3D

@export_category("Minion / Weapon")

## The attack label of the card.
@export var attack_label: Label3D

## The health label of the card.
@export var health_label: Label3D

@export_category("Minion")

## The tribe label of the card.
@export var tribe_label: Label3D

@export_category("Spell")

## The spell school label of the card.
@export var spell_school_label: Label3D

@export_category("Hero")

## The armor label of the card.
@export var armor_label: Label3D
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

## The card's abiltiies. Looks like this: [code]{Ability: Array[Callable]}[/code]
var abilities: Dictionary

## Where the card is in it's [member location].
var index: int:
	get:
		return location_array.find(self)

## Where the card is. E.g. Hand, Board, Deck, ...
var location: StringName = &"None":
	set(new_location):
		remove_from_location()
		location = new_location

## Returns the array where the card is stored according to it's [member location].
var location_array: Array[Card]:
	get:
		match location:
			&"Hand":
				return player.hand
			&"Deck":
				return player.deck
			&"Board":
				return player.board
			&"Graveyard":
				return player.graveyard
			&"Hero":
				return [self]
			&"Hero Power":
				return [self]
			&"None":
				return []
			_:
				push_error("Invalid Location")
				assert(false, "Invalid Location")
				return []

## Overrides [member is_hidden] if not set to [code]NULL[/code].
var override_is_hidden: Game.NullableBool = Game.NullableBool.NULL

## Whether or not [member cover] should be forced to be visible.
var force_cover_visible: bool = false

## Whether or not the card is hidden. If it is, it will be covered. Cannot be set, set [member override_is_hidden] instead.
var is_hidden: bool:
	get:
		if override_is_hidden == Game.NullableBool.FALSE:
			return false
		if override_is_hidden == Game.NullableBool.TRUE:
			return true
		
		if location == &"Board" or location == &"Hero" or location == &"Hero Power":
			return false
		
		if player != Game.player and not Multiplayer.is_server:
			return true
		
		if location == &"Hand":
			return false
		
		return true
	set(new_is_hidden):
		is_hidden = new_is_hidden
		
		# Only change the essentials.
		if not force_cover_visible:
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
			armor_label.hide()

## Whether or not this card has attacked this turn. Gets set to true every [signal Game.turn_ended] emission.
var has_attacked_this_turn: bool = false

## If this is [code]false[/code], the card cannot attack. Gets set to [code]true[/code] when the card is played. Gets set to [code]false[/code] when the turn ends.[br]
## You probably shouldn't set this.
var exhausted: bool = false

## Whether or not this card should do any effects in [method do_effects].
## [codeblock]
## # Trigger a card's battlecry.
## # We don't want the card's battlecry effects to be triggered here.
## card.should_do_effects = false
## card.trigger_ability(Card.Ability.BATTLECRY, false)
## card.should_do_effects = true
## [/codeblock]
var should_do_effects: bool = true

## Whether or not this card is currently being killed (In the process of being moved to the graveyard).[br]
## Set this to [code]false[/code] in [signal Game.card_killed] to prevent the card from being killed.
var is_dying: bool = false

## Whether or not this card should die. Used for animations.
var should_die: bool = true

## The card's hero power. Only set if this card is a [code]Hero[/code] and the [member hero_power_id] is set.
var hero_power: Card

## Whether or not the card has been refunded. Don't set manually.
var refunded: bool = false

## The target requested from the [code]DRAG_TO_PLAY[/code] tag. Use this in an ability.
var drag_to_play_target: Variant

#region Blueprint Fields
#region Common
var card_name: String
var text: String
var cost: int
var texture: Texture2D
var types: Array[StringName]
var classes: Array[StringName]
var tags: Array[StringName]
var modules: Dictionary
var collectible: bool
var id: int
#endregion


#region Minion
var tribes: Array[StringName]
#endregion


#region Minion / Weapon
var attack: int
var health: int
#endregion


#region Spell
var spell_schools: Array[StringName]
#endregion


#region Hero
var armor: int

# TODO: Show the texure of the hero power in the bottom left corner of the card.
var hero_power_id: int
#endregion


#region Location
## TODO: Add mesh for the durability: https://hearthstone.wiki.gg/wiki/Location
var durability: int
var cooldown: int
#endregion
#endregion
#endregion


#region Private Variables
var _hover_tween: Tween
var _should_hover: bool = true
#endregion


#region Onready Variables
## The mesh of the card.
@onready var mesh: Node3D = $Mesh

@onready var _old_position: Vector3 = position
#endregion


#region Internal Functions
func _ready() -> void:
	Game.turn_ended.connect(func(after: bool, _player: Player, _sender_peer_id: int) -> void:
		if not after:
			return
		
		has_attacked_this_turn = false
		
		if location == &"Board":
			exhausted = false
		
		player.has_used_hero_power_this_turn = false
	)
	
	# Use a timer to improve performance.
	update_timer.timeout.connect(func() -> void:
		if not card_name and blueprint:
			update_blueprint()
		
		_update()
	)


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
func add_to_location(new_location: StringName, index: int) -> void:
	remove_from_location()
	
	location = new_location
	location_array.insert(min(index, location_array.size()), self)


## Triggers an ability.
func trigger_ability(ability: StringName, send_packet: bool = true) -> bool:
	if not abilities.has(ability):
		return false
	
	if not await Modules.request(&"Trigger Ability", false, [self, ability, send_packet]):
		return false
	
	# Wait 1 frame so that `await wait_for_ability` can get called before the ability gets triggered.
	await get_tree().process_frame
	
	Packet.send_if(send_packet, &"Trigger Ability", player.id, [location, index, ability])
	
	return true


## Adds an ability to this card.
func add_ability(ability: StringName, callback: Callable) -> void:
	if not abilities.has(ability):
		abilities[ability] = []
	
	if not await Modules.request(&"Add Ability", false, [self, ability]):
		return
	
	abilities[ability].append(callback)


## Makes this card attack a [Card] or [Player].
func attack_target(target: Variant, send_packet: bool = true) -> bool:
	if not target:
		Game.feedback("That target is not valid.", Game.FeedbackType.ERROR)
		return false
	
	if not await Modules.request(&"Attack", false, [self, target, send_packet]):
		return false
	
	if target is Card:
		Packet.send_if(send_packet, &"Attack", player.id, [&"Card Vs Card", location, index, target.location, target.index, 0, 0])
	else:
		Packet.send_if(send_packet, &"Attack", player.id, [&"Card Vs Player", location, index, StringName(), 0, 0, target.id])
	
	return true


## Sets up the card to do an effect (particles, animations, etc...) in [param callback].[br]
## You should probably run this in [method LayoutModule.stabilize_layout_while].
func do_effects(callback: Callable) -> void:
	if not should_do_effects or not Settings.client.animations:
		scale = Vector3.ONE
		
		# Show the card, but don't do any effects.
		await get_tree().create_timer(1.0).timeout
		return
	
	# CRITICAL: Remove layout module dependancy. May move this into a seperate module.
	await LayoutModule.stabilize_layout_while(self, func() -> void:
		var tween: Tween = create_tween().set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "scale", Vector3.ONE, 0.1)
		await tween.finished
		
		await callback.call()
	)


## Tweens the card to the specified parameters over the course of [param duration] seconds.
func tween_to(duration: float, new_position: Vector3, new_rotation: Vector3 = rotation, new_scale: Vector3 = scale) -> void:
	if not Settings.client.animations:
		position = new_position
		rotation = new_rotation
		scale = new_scale
		return
	
	Modules.request(&"Card Starting Tweening To", true, [self, duration, new_position, new_rotation, new_scale])
	
	var tween: Tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE).set_parallel()
	tween.tween_property(self, "position", new_position, duration)
	tween.tween_property(self, "rotation", new_rotation, duration)
	tween.tween_property(self, "scale", new_scale, duration)
	await tween.finished
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


## Gets the [param player]'s [Card] in [param location] at [param index].
static func get_from_index(player: Player, location: StringName, index: int) -> Card:
	match location:
		&"Hand":
			return Game.get_or_null(player.hand, index)
		&"Deck":
			return Game.get_or_null(player.deck, index)
		&"Board":
			return Game.get_or_null(player.board, index)
		&"Graveyard":
			return Game.get_or_null(player.graveyard, index)
		&"Hero":
			return player.hero
		&"Hero Power":
			return player.hero.hero_power
		_:
			#assert(false, "The card doesn't exist at this location.")
			return null


# This is in a static function to work in editor scripts.
static func _update_card(card: Card, blueprint: Blueprint) -> void:
	var lookup: Variant = card
	
	if Engine.is_editor_hint():
		lookup = blueprint
	elif card.is_hidden:
		return
	
	card.texture_sprite.texture = lookup.texture
	card.name_label.text = lookup.card_name
	card.cost_label.text = str(lookup.cost)
	card.text_label.text = lookup.text
	card.attack_label.text = str(lookup.attack)
	card.health_label.text = str(lookup.health)
	card.armor_label.text = str(lookup.armor)
	
	# Tribes
	card.tribe_label.text = " / ".join(lookup.tribes)
	
	# Spell schools
	card.spell_school_label.text = " / ".join(lookup.spell_schools)
	
	# Show non-essential labels
	if lookup.types.has(&"Minion"):
		card.tribe_label.show()
	if lookup.types.has(&"Spell"):
		card.spell_school_label.show()
	
	# Cost
	#card.get_node("Mesh/Crystal").visible = lookup.cost > 0
	#card.cost_label.visible = lookup.cost > 0
	
	# Attack
	var attack_visible: bool = lookup.attack > 0 or blueprint.attack > 0
	card.get_node("Mesh/Attack").visible = attack_visible
	card.attack_label.visible = attack_visible
	
	# Health
	var health_visible: bool = lookup.health > 0 or blueprint.health > 0 or lookup.tags.has(&"Starting Hero")
	card.get_node("Mesh/Health").visible = health_visible
	card.get_node("Mesh/HealthFrame").visible = health_visible
	card.health_label.visible = health_visible
	
	# Armor
	var armor_visible: bool = lookup.armor > 0 or blueprint.armor > 0 or lookup.tags.has(&"Starting Hero")
	card.get_node("Mesh/Armor").visible = armor_visible
	card.armor_label.visible = armor_visible
	
	if health_visible:
		card.get_node("Mesh/Armor").position.x = 0
		card.armor_label.position.x = -1.3
	else:
		card.get_node("Mesh/Armor").position.x = 2.6
		card.armor_label.position.x = 1.3
	
	# Tribe / Spell School
	var tribe_visible: bool = (
		(lookup.tribes.size() > 0 and lookup.tribes[0] != &"None") or
		(lookup.spell_schools.size() > 0 and lookup.spell_schools[0] != &"None") 
	)
	
	card.get_node("Mesh/TribeOrSpellSchool").visible = tribe_visible
	card.tribe_label.visible = tribe_visible
	card.spell_school_label.visible = tribe_visible
#endregion


#region Private Functions
func _wait_for_ability(target_ability: StringName) -> void:
	while true:
		var info: Array = await Game.card_ability_triggered
		
		var after: bool = info[0]
		var card: Card = info[1]
		var ability: StringName = info[2]
		
		if after and card == self and ability == target_ability:
			break


func _update() -> void:
	if location == &"None":
		remove_from_location()
		queue_free()
		return
	
	is_hidden = is_hidden
	# TODO: Put this condition into a function.
	if is_hidden and location != &"Hand" and location != &"Board" and location != &"Hero" and location != &"Hero Power":
		hide()
		return
	
	show()
	
	Card._update_card(self, blueprint)
	
	if location == &"Hero":
		armor_label.text = str(player.armor)
		health_label.text = str(player.health)
	
	Modules.request(&"Update Card", true, [self])
	
	# TODO: Should this be done here?
	if health <= 0 and location == &"Board" and not is_dying and should_die:
		is_dying = true
		Game.card_killed.emit(false, self, player, multiplayer.get_unique_id())
		
		# Do this to allow preventing death by `Game.card_killed` setting `is_killed` to true.
		if not is_dying:
			return
		
		var old_scale: Vector3 = scale
		
		if Settings.client.animations:
			var tween: Tween = create_tween()
			
			# HACK: Don't set the scale to 0 to prevent https://github.com/godotengine/godot/issues/63012
			tween.tween_property(self, "scale", Vector3(0.01, 0.01, 0.01), 0.5).set_ease(Tween.EASE_OUT)
			
			await tween.finished
		
		add_to_location(&"Graveyard", player.graveyard.size())
		override_is_hidden = Game.NullableBool.NULL
		# HACK: Disabling the collision so it doesn't interfere.
		$CollisionShape3D.disabled = true
		
		# Update to hide the card.
		_update()
		
		await get_tree().process_frame
		
		scale = old_scale
		
		Game.card_killed.emit(true, self, player, multiplayer.get_unique_id())
		await Modules.request(&"Card Killed", false, [self])
		return


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
	
	Modules.request(&"Card Start Hover", true, [self])
	
	# Animate
	var player_weight: int = 1 if player == Game.player else -1
	
	var new_position: Vector3 = Vector3(position.x, 1.0, position.z - (4 * player_weight))
	var new_rotation_y: float = 0.0
	var new_scale: Vector3 = Vector3(2, 2, 2)
	
	if not Settings.client.animations:
		position = new_position
		rotation.y = new_rotation_y
		scale = new_scale
		return
	
	var time: float = 0.1
	
	_hover_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO).set_parallel()
	_hover_tween.tween_property(self, "position", new_position, time)
	_hover_tween.tween_property(self, "rotation:y", new_rotation_y, time)
	_hover_tween.tween_property(self, "scale", new_scale, time)


func _stop_hover() -> void:
	if is_dragging or not _should_hover or not visible:
		return
	
	if _hover_tween:
		_hover_tween.kill()
	
	is_hovering = false
	Modules.request(&"Card Stop Hover", true, [self])


func _start_dragging() -> void:
	if not is_hovering or not visible:
		return
	
	# Don't drag if this is an opposing card
	if Game.player != player or Multiplayer.is_server:
		return
	
	if location == &"Board":
		_start_attacking()
		return
	
	# Drag to play.
	if tags.has(&"Drag To Play"):
		var target: Variant = await Target.prompt(
			position,
			self,
			Target.CAN_SELECT_CARDS |
			Target.CAN_SELECT_HEROES |
			Target.CAN_SELECT_ENEMY_TARGETS |
			Target.CAN_SELECT_FRIENDLY_TARGETS
		)
		
		if not target:
			return
		
		if target is Card:
			if target.location == &"Hero Power":
				Game.feedback("Invalid Target.", Game.FeedbackType.ERROR)
				return
			
			Packet.send(&"Set Drag To Play Target", player.id, [
				&"Card",
				location,
				index,
				target.player.id,
				target.location,
				target.index,
			])
		else:
			Packet.send(&"Set Drag To Play Target", player.id, [
				&"Player",
				location,
				index,
				target.id,
				StringName(),
				0,
			])
		
		player.play_card(self, player.board.size())
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
	
	if not await Modules.request(&"Start Attacking", false, [self]):
		return
	
	var target: Variant = await Target.prompt(position, self, Target.CAN_SELECT_CARDS | Target.CAN_SELECT_HEROES | Target.CAN_SELECT_ENEMY_TARGETS)
	
	if target is Card:
		if target.location != &"Board":
			return
	
	attack_target(target) 


func _make_way(stop: bool = false) -> void:
	for card: Card in Card.get_all_owned_by(player).filter(func(card: Card) -> bool:
		return card != self and card.location == &"Board"
	):
		if is_dragging:
			card._make_way_for(self)
		else:
			card._stop_making_way()


func _make_way_for(card: Card) -> void:
	if not visible:
		return
	
	Modules.request(&"Card Start Making Way", true, [self, card])
	
	var bias: int = 1 if global_position.x > card.global_position.x else -1
	var new_position_x: float = _old_position.x + 2 * bias
	
	if not Settings.client.animations:
		position.x = new_position_x
		return
	
	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:x", new_position_x, 0.2)


func _stop_making_way() -> void:
	Modules.request(&"Card Stop Making Way", true, [self])


func _refund() -> void:
	player.mana += cost
#endregion
