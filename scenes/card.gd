class_name CardNode
extends Area3D
## This is the physical represantation of a card.
## @experimental


#region Signals
## Emits when the node is released from a drag.
signal released(position: Vector3)
#endregion

#region Exported Variables
## The card that the model is using.
@export var card: Card:
	set(new_card):
		card = new_card
		card._ready()
		
		# TODO: Remove
		card.trigger_ability(Enums.ABILITY.CAST)

## The texture / image of the card.
@export var texture: Sprite3D

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
#endregion

#region Public Variables
## Whether or not the player is hovering over this card.
var is_hovering: bool = false

## Whether or not the player is dragging this card.
var is_dragging: bool = false
#endregion

#region Private Variables
var _tween: Tween
#endregion

#region Onready Variables
## The mesh of the card.
@onready var mesh: Node3D = $Mesh

@onready var _old_position: Vector3 = position
@onready var _old_rotation: Vector3 = rotation
@onready var _old_scale: Vector3 = scale
#endregion


#region Internal Functions
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	_update()


func _update() -> void:
	texture.texture = card.texture
	name_label.text = card.name
	# TODO: Add back
	#cost_label.text = str(card.cost)
	text_label.text = card.text
	attack_label.text = str(card.attack)
	health_label.text = str(card.health)
	
	var tribe_keys: PackedStringArray = PackedStringArray(Enums.TRIBE.keys())
	tribe_label.text = " / ".join(card.tribes.map(func(tribe: Enums.TRIBE) -> String: return tribe_keys[tribe].capitalize()))
	
	mesh.rarity = card.rarities[0]
	
	# TODO: Remove.
	# For debugging, the cost text is equal to the card's index in it's hand.
	if card.location == Enums.LOCATION.HAND:
		cost_label.text = str(card.index)
	tribe_label.text = str(card.player.id)
#endregion


#region Public Functions
## Change the position / rotation of the card to be correct.
func layout() -> void:
	if is_hovering:
		return
	
	if multiplayer and multiplayer.is_server():
		return
	
	position = Vector3.ONE
	rotation = Vector3.ZERO
	scale = Vector3.ONE
	
	if card.location == Enums.LOCATION.HAND:
		_layout_hand()
	elif card.location == Enums.LOCATION.BOARD:
		_layout_board()
	else:
		assert(false, "Can't layout the card in this location.")
	
	_old_position = position
	_old_rotation = rotation
	_old_scale = scale
#endregion


#region Private Functions
func _layout_hand() -> void:
	# TODO: Dont hardcode this
	var player_weight: int = 1 if card.player == Game.player else -1
	
	var half_hand_size: int = Game.MAX_HAND_SIZE / 2
	
	# TODO: If fewer cards, be middle (real)
	position.x = -Game.CARD_BOUNDS_X + (card.index * Game.CARD_DISTANCE_X)
	position.y = Game.CARD_BOUNDS_Y * abs(half_hand_size - 1 - card.index)
	position.z = Game.CARD_BOUNDS_Z * player_weight
	
	# If index < max_hand_size / 2, -rotation
	if card.index != half_hand_size - 1:
		rotation.y = deg_to_rad((Game.CARD_BOUNDS_ROTATION_Y + position.x) * -sign((card.index - half_hand_size) + player_weight))
	
	# Rotate the card 180 degrees if it isn't already
	if card.player != Game.player and rotation.y - PI < 0:
		rotation.y += PI


func _layout_board() -> void:
	var player_weight: int = 1 if card.player == Game.player else -1
	
	rotation = Vector3.ZERO
	
	position.x = (card.index - 4) * 3.5 + Game.CARD_DISTANCE_X
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
	if is_dragging:
		# Release lmb
		if event is InputEventMouseButton:
			if event.is_released():
				is_dragging = false
				var pos: Vector3 = position
				position = _old_position
				released.emit(pos)


func _on_input_event(_camera: Node, event: InputEvent, position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if not is_hovering:
		return
	
	# Don't drag if this is an opposing card
	if Game.player != card.player:
		return
	
	if event is InputEventMouseButton:
		if event.is_released():
			# Handled by _input
			return
		
		is_dragging = true
	
	if is_dragging:
		global_position = Vector3(position.x, global_position.y, position.z)
#endregion
