class_name Target
extends Area3D


#region Signals
signal card_selected(card: Card)
signal player_selected(player: Player)

signal target_selected(target: Variant)
#endregion


#region Constants
const TARGET: PackedScene = preload("res://scenes/target.tscn")

enum {
	CAN_SELECT_CARDS = 1,
	CAN_SELECT_HEROES = 2,
	CAN_SELECT_FRIENDLY_TARGETS = 4,
	CAN_SELECT_ENEMY_TARGETS = 8,
}
#endregion


#region Public Variables
var is_moving: bool = true

var flags: int
#endregion


#region Internal Functions
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$CollisionShape3D.shape.radius = 10.0


func _input_event(camera: Camera3D, event: InputEvent, pos: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseMotion and is_moving:
		global_position = Vector3(pos.x, global_position.y, pos.z)
		return
	
	if not event is InputEventMouseButton or event.is_pressed():
		return
	
	if event.button_index == MOUSE_BUTTON_RIGHT:
		target_selected.emit(null)
		return _remove()
	elif event.button_index != MOUSE_BUTTON_LEFT:
		return
	
	# Pressed lmb
	$CollisionShape3D.shape.radius = 0.5
	$CollisionShape3D.shape.height = 10
	is_moving = false
	
	await get_tree().physics_frame
	
	var collisions: Array[Area3D] = get_overlapping_areas()
	
	if collisions.size() > 0:
		var collider: Area3D = collisions[0]
		
		if not collider is Card:
			target_selected.emit(null)
			return _remove()
		
		var player: Player = collider.player
		
		if player == Game.player and not flags & CAN_SELECT_FRIENDLY_TARGETS:
			Game.feedback("You cannot select friendly cards here.", Game.FeedbackType.ERROR)
			target_selected.emit(null)
			return _remove()
		if player == Game.opponent and not flags & CAN_SELECT_ENEMY_TARGETS:
			Game.feedback("You cannot select enemy cards here.", Game.FeedbackType.ERROR)
			target_selected.emit(null)
			return _remove()
		
		if collider.location == &"Hero":
			if not flags & CAN_SELECT_HEROES:
				Game.feedback("You cannot select heroes here.", Game.FeedbackType.ERROR)
				target_selected.emit(null)
				return _remove()
			
			player_selected.emit(player)
			target_selected.emit(player)
		else:
			if not flags & CAN_SELECT_CARDS:
				Game.feedback("You cannot select cards here.", Game.FeedbackType.ERROR)
				target_selected.emit(null)
				return _remove()
			
			card_selected.emit(collider)
			target_selected.emit(collider)
	
	return _remove()
#endregion


#region Static Functions
static func prompt(start_position: Vector3, prompter: Node3D, flags: int) -> Variant:
	var target: Target = TARGET.instantiate()
	target.position = start_position
	target.flags = flags
	
	var tree: SceneTree = Engine.get_main_loop()
	tree.root.add_child(target)
	
	var target_node: Variant = await target.target_selected
	return target_node


static func prompt_card(start_position: Vector3, prompter: Node3D, flags: int) -> Card:
	return await prompt(start_position, prompter, flags | CAN_SELECT_CARDS) as Card


static func prompt_player(start_position: Vector3, prompter: Node3D) -> Player:
	return await prompt(start_position, prompter, CAN_SELECT_HEROES | CAN_SELECT_FRIENDLY_TARGETS | CAN_SELECT_ENEMY_TARGETS) as Player
#endregion


#region Private Functions
func _remove() -> void:
	# For some reason, not resetting the shape's height breaks future targets
	$CollisionShape3D.shape.height = 0.1
	queue_free()
#endregion
