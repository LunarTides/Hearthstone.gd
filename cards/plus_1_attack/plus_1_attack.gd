extends Card


func do(card: Card) -> int:
	card.attack += 1
	
	return SUCCESS


func undo(card: Card) -> int:
	card.attack -= 1
	
	return SUCCESS
