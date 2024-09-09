class_name DynamicEnchantment
extends Card


var field: StringName
var do_value: Variant
var undo_value: Variant


static func create(player: Player, field: StringName, do_value: Variant, undo_value: Variant) -> DynamicEnchantment:
	var dynamic_enchantment: DynamicEnchantment = Card.create_from_id(7, player)
	dynamic_enchantment.field = field
	dynamic_enchantment.do_value = do_value
	dynamic_enchantment.undo_value = undo_value
	return dynamic_enchantment


func do(card: Card) -> bool:
	card[field] = do_value
	return true


func undo(card: Card) -> bool:
	card[field] = undo_value
	return true
