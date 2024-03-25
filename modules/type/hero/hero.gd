extends Module


#region Module Functions
func _name() -> StringName:
	return &"Hero"


func _dependencies() -> Array[StringName]:
	return [
		&"Type",
		&"Armor",
		&"Attack",
		&"Health",
	]


func _load() -> void:
	register_hooks(handler)
		
	TypeModule.register_type(&"Hero", false)
	ArmorModule.register(_name())
	AttackModule.register(_name())
	HealthModule.register(_name())


func _unload() -> void:
	TypeModule.unregister_type(&"Hero")
#endregion


#region Public Functions
func handler(what: Modules.Hook, info: Array) -> bool:
	if what == Modules.Hook.ACCEPT_PACKET:
		return await accept_packet_hook.callv(info)
	
	return true


func is_hero(card: Card) -> bool:
	return TypeModule.is_card_type(card, &"Hero")


func accept_play_packet(
	player: Player,
	sender_peer_id: int,
	
	location: StringName,
	location_index: int,
	board_index: int,
	position: Vector3i,
) -> bool:
	var card: Card = Card.get_from_index(player, location, location_index)
	
	if not is_hero(card):
		return true
	
	card.trigger_ability(&"Battlecry", false)
	await card._wait_for_ability(&"Battlecry")
	
	if card.refunded:
		return false
	
	# TODO: Add an animation here of this hero replacing the last.
	
	# Destroy the previous hero.
	player.hero.destroy()
	
	card.location = &"Hero"
	return true


#region Hooks
func accept_packet_hook(packet_type: StringName, player: Player, sender_peer_id: int, info: Array) -> bool:
	if packet_type == &"Play":
		return await accept_play_packet.bindv(info).call(player, sender_peer_id)
	
	return true
#endregion
#endregion
