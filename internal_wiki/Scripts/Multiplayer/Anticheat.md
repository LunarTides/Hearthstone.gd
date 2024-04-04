This scripts deals with the core anticheat and contains functions to help modules.

Here is the timeline of what happens:
- Server receives a packet.
- Server runs the packet through the anticheat.
	- The anticheat analyzes the packet.
		- The anticheat sees if it can handle the packet in core, if it can, it calls the appropriate function to handle that packet. *E.g. If it got the `Play` packet, it calls the `Anticheat._run_play_packet` function, which looks at the info in the packet.*
			- The amount of information must be correct. *E.g. The `Play` packet expects 4 pieces of information.*
			- All the pieces of information must be the correct types. *E.g. The `Play` packet expects, in this order, a `StringName`, `Int`, `Int`, then `Vector3i`.*
			- The packet now needs to pass some amount of checks, which are different depending on the packet. *E.g. The `Play` packet expects the card specified to exist, that the player should afford the card, that it should be the player's turn, that the player who would play the card should be the same player as the one who sent the packet (Not guaranteed), and that the card should be in the player's hand.*
		- The anticheat sends a request to the [[Modules Script]], and returns it's response.
- If the packet didn't pass the anticheat, punish the player who sent the packet based on `Server Settings -> Anticheat Consequence` ([[Settings]]). And don't proceed.
- Server forwards that packet to all clients to actually get the packet to be handled. (Clients + Server will now trust this packet completely and execute whatever it says.)

[[Modules]] extend the anticheat by listening to the `Modules.Hooks.ANTICHEAT` hook.