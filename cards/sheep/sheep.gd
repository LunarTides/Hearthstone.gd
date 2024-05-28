extends Card


func setup() -> void:
	var enchantment: Card = Card.create_from_id(6, player)
	
	await TypeEnchantmentModule.add_enchantment(self, enchantment)
