class_name CardNode
extends Area3D
## This is the physical represantation of a card.
## @experimental


#region Signals
## Emits when the node is released from a drag.
signal released(position: Vector3)
#endregion


#region Constant Variables
const MinionMesh: Resource = preload("res://assets/models/minion/minion.blend")
const SpellMesh: Resource = preload("res://assets/models/spell/spell.blend")

# There should be a better way of doing this.
const CARD_BOUNDS_X: float = 9.05
const CARD_BOUNDS_Y: float = -0.5
const CARD_BOUNDS_Z: float = 13
const CARD_ROTATION_Y_MULTIPLIER: float = 10.0
const CARD_DISTANCE_X: float = 1.81
const CARD_OFFSET_X: float = 6.0
#endregion


#region Exported Variables
## The card that the model is using.
@export var card: Card:
	set(new_card):
		card = new_card
		card._ready()

## The texture / image of the card.
@export var texture: Sprite3D

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
#endregion


#region Public Variables
## Whether or not the player is hovering over this card.
var is_hovering: bool = false

## Whether or not the player is dragging this card.
var is_dragging: bool = false

## Whether or not the card is being covered (hidden).
var covered: bool:
	set(new_covered):
		covered = new_covered
		
		# Only change the essentials.
		cover.visible = covered
		mesh.visible = not covered
		texture.visible = not covered
		name_label.visible = not covered
		cost_label.visible = not covered
		text_label.visible = not covered
		
		if covered:
			# Hide all the non-essentials in here.
			attack_label.hide()
			health_label.hide()
			tribe_label.hide()
			spell_school_label.hide()
#endregion


#region Private Variables
var _tween: Tween
var _should_layout: bool = true
#endregion


#region Onready Variables
## The mesh of the card.
@onready var mesh: Node3D = $Mesh

@onready var _old_position: Vector3 = position
@onready var _old_rotation: Vector3 = rotation
@onready var _old_scale: Vector3 = scale
#endregion


#region Internal Functions
func _ready() -> void:
	mesh.queue_free()
	
	if card.types.has(Card.Type.MINION):
		mesh = MinionMesh.instantiate()
	if card.types.has(Card.Type.SPELL):
		mesh = SpellMesh.instantiate()
	
	add_child(mesh)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	_update()
#endregion


#region Public Functions
## Change the position / rotation of the card to be correct.
func layout() -> void:
	if is_hovering or not _should_layout:
		return
	
	position = Vector3.ONE
	rotation = Vector3.ZERO
	scale = Vector3.ONE
	
	match card.location:
		Card.Location.HAND:
			_layout_hand()
		
		Card.Location.BOARD:
			_layout_board()
		
		Card.Location.NONE:
			pass
		
		_:
			assert(false, "Can't layout the card in this location.")
	
	_old_position = position
	_old_rotation = rotation
	_old_scale = scale
#endregion


#region Static Functions
## Gets all [CardNode]s for the specified player.
static func get_all_owned_by(player: Player) -> Array[CardNode]:
	var array: Array[CardNode] = []
	
	array.assign(get_all().filter(func(card_node: CardNode) -> bool:
		if not card_node.card:
			return false
		
		return card_node.card.player == player
	))
	
	return array


## Gets all [CardNode]s currently in the game scene.
static func get_all() -> Array[CardNode]:
	var array: Array[CardNode] = []
	var tree: SceneTree = Engine.get_main_loop()
	
	array.assign(tree.get_nodes_in_group("Cards").filter(func(card_node: CardNode) -> bool:
		return not card_node.is_queued_for_deletion()
	))
	return array


## Lays out all the cards. Only works client side.
static func layout_all() -> void:
	for card: CardNode in get_all():
		card.layout()


## Lays out all the cards for the specified player. Only works client side.
static func layout_all_owned_by(player: Player) -> void:
	for card: CardNode in get_all_owned_by(player):
		card.layout()
#endregion


#region Private Functions
func _update() -> void:
	if card.location == Card.Location.NONE:
		card.remove_from_location()
		queue_free()
		return
	
	if card.is_hidden:
		covered = true
		return
	
	covered = false
	
	texture.texture = card.texture
	name_label.text = card.name
	cost_label.text = str(card.cost)
	text_label.text = card.text
	attack_label.text = str(card.attack)
	health_label.text = str(card.health)
	
	# Tribes
	var tribe_keys: PackedStringArray = PackedStringArray(Card.Tribe.keys())
	tribe_label.text = " / ".join(card.tribes.map(func(tribe: Card.Tribe) -> String: return tribe_keys[tribe].capitalize()))
	
	# Spell schools
	var spell_schools: PackedStringArray = PackedStringArray(Card.SpellSchool.keys())
	spell_school_label.text = " / ".join(card.spell_schools.map(func(spell_school: Card.SpellSchool) -> String: return spell_schools[spell_school].capitalize()))
	
	# Rarity Color
	var rarity_node: MeshInstance3D = mesh.get_node("Rarity")
	rarity_node.mesh.surface_get_material(0).albedo_color = Card.RARITY_COLOR.get(card.rarities[0])
	
	# Show non-essential labels
	if card.types.has(Card.Type.MINION):
		attack_label.show()
		health_label.show()
		tribe_label.show()
	if card.types.has(Card.Type.SPELL):
		spell_school_label.show()


func _layout_hand() -> void:
	# TODO: Dont hardcode this
	var player_weight: int = 1 if card.player == Game.player else -1
	
	# Integer division, but it's not a problem.
	var half_hand_size: int = ceil(card.player.hand.size() / 2)
	
	position.x = (CARD_OFFSET_X - (half_hand_size * 2)) + -CARD_BOUNDS_X + (card.index * CARD_DISTANCE_X)
	position.y = CARD_BOUNDS_Y * abs(half_hand_size - card.index)
	position.z = CARD_BOUNDS_Z * player_weight
	
	if card.index != half_hand_size:
		# Tilt it to the left/right.
		rotation.y = deg_to_rad(CARD_ROTATION_Y_MULTIPLIER * player_weight * (half_hand_size - card.index))
	
	# Position it futher away the more rotated it is.
	# This makes it easier to select the right card.
	position.x -= rotation.y * player_weight
	
	# Rotate the card 180 degrees if it isn't already
	if card.player != Game.player and rotation.y - PI < 0:
		rotation.y += PI


func _layout_board() -> void:
	var player_weight: int = 1 if card.player == Game.player else -1
	
	rotation = Vector3.ZERO
	
	position.x = (card.index - 4) * 3.5 + CARD_DISTANCE_X
	position.y = 0
	position.z = Game.board_node.player.position.z + player_weight * (
		# I love hardcoded values
		3 if Game.is_player_1
		else -6 if card.player == Game.opponent
		else 11
	)
	
	if Game.is_player_1 and card.player == Game.opponent:
		position.z += 1


func _on_mouse_entered() -> void:
	if is_dragging:
		return
	
	is_hovering = true
	
	# Animate
	var player_weight: int = 1 if card.player == Game.player else -1
	
	_tween = create_tween()
	_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_tween.parallel().tween_property(self, "position:y", 1, 0.1)
	_tween.parallel().tween_property(self, "position:z", position.z - (4 * player_weight), 0.1)
	_tween.parallel().tween_property(self, "rotation:y", 0, 0.1)
	_tween.parallel().tween_property(self, "scale", Vector3(2, 2, 2), 0.1)


func _on_mouse_exited() -> void:
	if is_dragging:
		return
	
	_tween.kill()
	position = _old_position
	rotation = _old_rotation
	scale = _old_scale
	
	is_hovering = false


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
	
	var pos: Vector3 = global_position
	
	is_dragging = false
	_on_mouse_exited()
	position = _old_position
	_make_way()
	
	if event.button_index == MOUSE_BUTTON_LEFT:
		released.emit(pos)


func _on_input_event(_camera: Node, event: InputEvent, position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if not is_hovering:
		return
	
	# Don't drag if this is an opposing card
	if Game.player != card.player or Multiplayer.is_server:
		return
	
	if event is InputEventMouseButton:
		if event.is_released():
			# Handled by _input
			return
		
		is_dragging = true
	
	if is_dragging:
		global_position = Vector3(position.x, global_position.y, position.z)
	
	_make_way()


func _make_way(stop: bool = false) -> void:
	for card_node: CardNode in CardNode.get_all_owned_by(card.player).filter(func(card_node: CardNode) -> bool:
		return card_node != self and card_node.card.location == Card.Location.BOARD
	):
		if is_dragging:
			card_node._make_way_for(self)
		else:
			card_node._stop_making_way()


func _make_way_for(card_node: CardNode) -> void:
	var bias: int = 1 if global_position.x > card_node.global_position.x else -1
	
	var tween: Tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:x", _old_position.x + 2 * bias, 0.2)
	_should_layout = false


func _stop_making_way() -> void:
	_should_layout = true
#endregion
