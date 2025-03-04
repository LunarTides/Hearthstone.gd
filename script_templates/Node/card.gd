# meta-name: Card
# meta-description: Card script
# meta-default: true
extends Card


#region Internal Functions
# Called when the card is created.
func setup() -> void:
	add_ability(&"Battlecry", battlecry)
#endregion


#region Public Functions
func battlecry() -> int:
	print_debug("Battlecry")
	
	return SUCCESS
#endregion
