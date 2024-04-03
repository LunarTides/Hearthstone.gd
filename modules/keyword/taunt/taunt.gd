extends Node


#region Internal Functions
func _ready() -> void:
	Modules.register(&"Taunt", [&"Keyword"], func() -> void:
		Modules.register_hooks(&"Taunt", self.handler)
		
		KeywordModule.register_keyword(&"Taunt")
	, func() -> void:
		KeywordModule.unregister_keyword(&"Taunt")
	)
#endregion


#region Public Functions
func handler(what: Modules.Hook, info: Array) -> bool:
	if what == Modules.Hook.ANTICHEAT:
		return anticheat_hook.callv(info)
	elif what == Modules.Hook.ATTACK:
		return attack_hook.callv(info)
	
	return true

func anticheat_attack(
	sender_peer_id: int,
	sender_player: Player,
	actor_player: Player,
	
	attack_mode: StringName,
	attacker_location: StringName,
	attacker_index: int,
	target_location: StringName,
	target_index: int,
	attacker_player_id: int,
	target_player_id: int,
) -> bool:
	var target_card: Card = Card.get_from_index(actor_player.opponent, target_location, target_index)
	
	return _check_for_taunt(target_card)


func attack_hook(attacker: Card, target: Variant, send_packet: bool) -> bool:
	return _check_for_taunt(target)


#region Hooks
func anticheat_hook(packet_type: StringName, sender_peer_id: int, sender_player: Player, actor_player: Player, info: Array) -> bool:
	if packet_type == &"Attack":
		return anticheat_attack.bindv(info).call(sender_peer_id, sender_player, actor_player)
	
	return true
#endregion
#endregion


#region Private Functions
func _check_for_taunt(target: Variant) -> bool:
	var target_owner: Player = target if target is Player else target.player
	
	if Card.get_all_owned_by(target_owner).any(func(card: Card) -> bool: return card.modules.has("keywords") and card.modules.keywords.has(&"Taunt") and card.location == &"Board"):
		if target is Card and target.modules.keywords and target.modules.keywords.has(&"Taunt"):
			return true
		
		Game.feedback("There is a minion with taunt in the way.", Game.FeedbackType.ERROR)
		return false
	
	return true
#endregion
