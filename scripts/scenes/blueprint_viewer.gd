@tool
@icon("res://assets/icons/blueprint_viewer_optimized.svg")
extends Node
## Shows a preview of how the card looks in-game in the editor.


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
