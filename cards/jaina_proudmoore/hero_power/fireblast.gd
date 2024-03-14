extends Blueprint


# Called when the card is created
func setup() -> void:
	card.add_ability(&"Hero Power", hero_power)


func hero_power() -> int:
	# Deal 1 damage.
	var target: Variant = card.drag_to_play_target
	
	if target is Card:
		target.health -= 1
	elif target is Player:
		target.damage(1)
	
	return SUCCESS
