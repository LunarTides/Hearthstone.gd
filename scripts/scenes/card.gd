class_name CardNode
extends Area3D
## This is the physical represantation of a card.
## @experimental


#region Signals
## Emits when the node is released from a drag.
signal released(position: Vector3)
#endregion


#region Constant Variables
const CardMesh: Resource = preload("res://assets/models/card.blend")
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
var _hover_tween: Tween
var _layout_tween: Tween
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
	
	# FIXME: This doesn't work with rarity.
	mesh = CardMesh.instantiate()
	add_child(mesh)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
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
#endregion


#region Public Functions
## Change the position / rotation of the card to be correct.
func layout(instant: bool = false) -> void:
	if is_hovering or not _should_layout:
		return
	
	var result: Dictionary = {}
	
	match card.location:
		Card.Location.HAND:
			result = _layout_hand()
		
		Card.Location.BOARD:
			result = _layout_board()
		
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
	_old_rotation = new_rotation
	_old_scale = new_scale
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
	
	layout()
	
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
	
	
	if card.attack <= 0:
		mesh.get_node("Attack").hide()
	
	if card.health <= 0:
		mesh.get_node("Health").hide()
		mesh.get_node("HealthFrame").hide()


func _layout_hand() -> Dictionary:
	var new_position: Vector3 = position
	var new_rotation: Vector3 = rotation
	var new_scale: Vector3 = scale
	
	# TODO: Dont hardcode this
	var player_weight: int = 1 if card.player == Game.player else -1
	
	# Integer division, but it's not a problem.
	@warning_ignore("integer_division")
	var half_hand_size: int = card.player.hand.size() / 2
	
	new_position.x = -(half_hand_size * 2) + Game.card_bounds_x + (card.index * Game.card_distance_x)
	new_position.y = Game.card_bounds_y * abs(half_hand_size - card.index)
	new_position.z = Game.card_bounds_z * player_weight
	
	new_rotation = Vector3.ZERO
	
	if card.index != half_hand_size:
		# Tilt it to the left/right.
		new_rotation.y = deg_to_rad(Game.card_rotation_y_multiplier * player_weight * (half_hand_size - card.index))
	
	# Position it futher away the more rotated it is.
	# This makes it easier to select the right card.
	new_position.x -= new_rotation.y * player_weight
	
	# Rotate the card 180 degrees if it isn't already
	if card.player != Game.player and new_rotation.y < PI:
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
	
	var player_weight: int = 1 if card.player == Game.player else -1
	
	new_rotation = Vector3.ZERO
	
	new_position.x = (card.index - 4) * 3.5 + Game.card_distance_x
	new_position.y = 0
	new_position.z = Game.board_node.player.position.z + player_weight * (
		# I love hardcoded values
		3 if Game.is_player_1
		else -6 if card.player == Game.opponent
		else 11
	)
	
	if Game.is_player_1 and card.player == Game.opponent:
		new_position.z += 1
	
	new_scale = Vector3.ONE
	
	return {
		"position": new_position,
		"rotation": new_rotation,
		"scale": new_scale,
	}


func _on_input_event(_camera: Node, event: InputEvent, pos: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	# Don't drag if this is an opposing card
	if Game.player != card.player or Multiplayer.is_server:
		return
	
	if event is InputEventMouseButton:
		_start_dragging()
	elif event is InputEventMouseMotion:
		_process_dragging(pos)


func _start_hover() -> void:
	if is_dragging:
		return
	
	is_hovering = true
	if _layout_tween:
		_layout_tween.kill()
	
	# Animate
	var player_weight: int = 1 if card.player == Game.player else -1
	var time: float = 0.1
	
	_hover_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO).set_parallel()
	_hover_tween.tween_property(self, "position:y", 1, time)
	_hover_tween.tween_property(self, "position:z", position.z - (4 * player_weight), time)
	_hover_tween.tween_property(self, "rotation:y", 0, time)
	_hover_tween.tween_property(self, "scale", Vector3(2, 2, 2), time)


func _stop_hover() -> void:
	if is_dragging:
		return
	
	if _hover_tween:
		_hover_tween.kill()
	
	is_hovering = false
	layout()


func _start_dragging() -> void:
	if not is_hovering:
		return
	
	# Don't drag if this is an opposing card
	if Game.player != card.player or Multiplayer.is_server:
		return
	
	is_dragging = true


func _stop_dragging(released_lmb: bool) -> void:
	var pos: Vector3 = global_position
	
	is_dragging = false
	_stop_hover()
	#position = _old_position
	_make_way()
	
	if released_lmb:
		released.emit(pos)


func _process_dragging(pos: Vector3) -> void:
	if not is_dragging:
		return
	
	global_position = Vector3(pos.x, global_position.y, pos.z)
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
	
	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:x", _old_position.x + 2 * bias, 0.2)
	_should_layout = false


func _stop_making_way() -> void:
	_should_layout = true
	layout()
#endregion
