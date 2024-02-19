class_name CardNode
extends Area3D


@export var card: Card:
	set(new_card):
		card = new_card
		card._ready()
		
		# TODO: Remove
		card.trigger_ability(Enums.ABILITY.CAST)

@export var mesh: Node3D
@export var texture: Sprite3D
@export var name_label: Label3D
@export var cost_label: Label3D
@export var text_label: Label3D
@export var attack_label: Label3D
@export var health_label: Label3D
@export var tribe_label: Label3D

var is_hovering: bool = false

var _old_position: Vector3
var _old_rotation: Vector3
var _tween: Tween


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	_update()


func _update() -> void:
	if not card:
		return
	
	texture.texture = card.texture
	name_label.text = card.name
	cost_label.text = str(card.cost)
	text_label.text = card.text
	attack_label.text = str(card.attack)
	health_label.text = str(card.health)
	
	# TODO: Remove
	text_label.text = str(card.player.id)
	
	var tribe_keys: PackedStringArray = PackedStringArray(Enums.TRIBE.keys())
	tribe_label.text = " / ".join(card.tribes.map(func(tribe: Enums.TRIBE) -> String: return tribe_keys[tribe].capitalize()))
	
	mesh.rarity = card.rarities[0]


func layout() -> void:
	# TODO: Dont hardcode this
	var max_hand_size: int = 10
	var player_weight: int = 1 if card.player == Game.player else -1
	
	var half_hand_size: int = max_hand_size / 2
	
	position.x = -Game.CARD_BOUNDS_X + (card.index * Game.CARD_DISTANCE_X)
	position.y = Game.CARD_BOUNDS_Y * abs(half_hand_size - 1 - card.index)
	position.z = Game.CARD_BOUNDS_Z * player_weight
	
	# If index < max_hand_size / 2, -rotation
	if card.index != half_hand_size - 1:
		rotation.y = deg_to_rad((Game.CARD_BOUNDS_ROTATION_Y + position.x) * -sign((card.index - half_hand_size) + player_weight))
	
	rotation.y += deg_to_rad(0 if card.player == Game.player else 180)


func _on_mouse_entered() -> void:
	is_hovering = true
	
	_old_rotation = rotation
	_old_position = position
	
	# Animate
	_tween = create_tween()
	_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_tween.parallel().tween_property(self, "position:y", position.y + 1, 0.1)
	_tween.parallel().tween_property(self, "position:z", position.z - 2, 0.1)
	_tween.parallel().tween_property(self, "rotation:y", 0, 0.1)


func _on_mouse_exited() -> void:
	_tween.kill()
	position = _old_position
	rotation = _old_rotation
	
	is_hovering = false
