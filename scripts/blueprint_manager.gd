@tool
@icon("res://assets/icons/blueprint_manager_optimized.svg")
class_name BlueprintManager
extends Node
## Tool script to make creating [Blueprint]s easier.
## @experimental


#region Public Variables
var has_suggested_id: bool = false
#endregion


#region Internal Functions
func _process(delta: float) -> void:
	if not Engine.is_editor_hint():
		queue_free()
		return
	
	var root: Node = Engine.get_main_loop().edited_scene_root
	if not root is Blueprint:
		return
	
	var blueprint: Blueprint = root
	var card: Card = blueprint.get_node("Card")
	
	if not card is Card:
		return
	
	Card._update_card(card, blueprint)
	
	# /////////////// Suggest ID ///////////////
	if has_suggested_id:
		return
	has_suggested_id = true
	
	var blueprints: Array = Blueprint.get_all()
	blueprints.sort_custom(func(a: Blueprint, b: Blueprint) -> bool:
		if not a.id or not b.id:
			return true
		
		return a.id <= b.id
	)
	
	var current_id: int = 0
	for bp: Blueprint in blueprints:
		if bp.id == 0:
			if (bp.texture != blueprint.texture or bp.card_name != blueprint.card_name):
				push_error("[BLUEPRINT MANAGER] '%s' does not to have an ID." % bp.card_name)
			continue
		elif bp.id == current_id:
			push_error("[BLUEPRINT MANAGER] There are more than one Blueprint with an ID of: %d. One of them is '%s'. THE GAME WILL BREAK." % [bp.id, bp.card_name])
			continue
		
		current_id += 1
		
		if bp.id != current_id:
			push_warning("[BLUEPRINT MANAGER] A Blueprint with an ID of '%d' is missing." % current_id)
			
			# Increment the counter to account for the missing id.
			current_id += bp.id - current_id
	
	if blueprint.id == 0:
		push_warning("[BLUEPRINT MANAGER] '%s' is missing an ID. Assigned it the following ID: '%d'." % [blueprint.card_name if blueprint.card_name else "Unnamed Blueprint", current_id + 1])
		blueprint.id = current_id + 1
		EditorInterface.save_scene()
	# # //////////////////////////////////////////
#endregion
