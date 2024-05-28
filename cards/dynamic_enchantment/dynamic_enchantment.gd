class_name DynamicEnchantment
extends Card


var field: StringName
var do_value: Variant
var undo_value: Variant


func do(card: Card) -> bool:
	card[field] = do_value
	return true


func undo(card: Card) -> bool:
	card[field] = undo_value
	return true
