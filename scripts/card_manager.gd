@tool
@icon("res://assets/icons/card_manager_optimized.svg")
class_name CardManager
extends Node
## Tool script to make creating [Card]s easier.
## @experimental


#region Public Variables
var has_suggested_id: bool = false
#endregion


#region Internal Functions
func _process(delta: float) -> void:
	if not Engine.is_editor_hint():
		queue_free()
		return
	
	# TODO: The card manager isn't currently working. It updates the id of the main card scene.
	return
	
	var card: Node = Engine.get_main_loop().edited_scene_root
	if not card is Card:
		return
	
	# /////////////// Suggest ID ///////////////
	if has_suggested_id:
		return
	has_suggested_id = true
	
	var cards: Array = Card.get_all()
	cards.sort_custom(func(a: Card, b: Card) -> bool:
		if not a.id or not b.id:
			return true
		
		return a.id <= b.id
	)
	
	var current_id: int = 0
	for c: Card in cards:
		if c.id == 0:
			if c.card_name != card.card_name:
				push_error("[CARD MANAGER] '%s' does not to have an ID." % c.card_name)
			continue
		elif c.id == current_id:
			push_error("[CARD MANAGER] There are more than one card with an ID of: %d. One of them is '%s'. THE GAME WILL BREAK." % [c.id, c.card_name])
			continue
		
		current_id += 1
		
		if c.id != current_id:
			push_warning("[CARD MANAGER] A card with an ID of '%d' is missing." % current_id)
			
			# Increment the counter to account for the missing id.
			current_id += c.id - current_id
	
	if card.id == 0:
		push_warning("[CARD MANAGER] '%s' is missing an ID. Assigned it the following ID: '%d'." % [card.card_name if card.card_name else "Unnamed Card", current_id + 1])
		card.id = current_id + 1
		EditorInterface.save_scene()
	# # //////////////////////////////////////////
#endregion
