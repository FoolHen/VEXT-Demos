# Round Manager

A simple file that you can add to your mods to help with managing round logic.

## API

If you want to use this in your mods first add this to your client script:
```Lua
Events:Subscribe('Engine:Message', function(message)
	if message.type == MessageType.CoreEnteredIngameMessage then
		NetEvents:SendLocal('BoxGame:PlayerReady')
	end
end)
```

Then copy the `round.lua` script to your mod's server folder, and require the class in a server script with ``local Round = require('Round')``. Then create an instance, for example ``local m_Round = Round(number roundTime[, number minPlayers, number preRoundTime, number roundOverTime, boolean announceInChat])``. The constructor parameters are the following:

| Argument | Description |
| ------ | ----------- |
| `number roundTime` | Sets the round time. |
| `number minPlayers` | Optional. Sets the minimum players that have loaded in required to start the pre-round/round. Default is ``2``. |
| `number preRoundTime` | Optional. Sets the time of the pre-round state. Can be set to ``0`` (no pre-round) or ``-1`` (infinite, in case you want to start the round from your mod). Default is ``0``. |
| `number roundOverTime` | Optional. Sets the time of the round over state. Can be set to ``0`` (no pre-round) or ``-1`` (infinite). Default is ``-1``. |
| `boolean announceInChat` | Optional. If set to ``true`` round info will be sent in chat. Defaults to ``true``. |

| Method | Description |
| ------ | ----------- |
| `(Constructor) Round(number roundTime[, number minPlayers, number preRoundTime, number roundOverTime, boolean announceInChat])` | Instantiates the round. ``preRoundTime`` and ``roundOverTime`` can be set to ``0`` or ``-1`` to disable the round state or make its time infinite respectively. ``preRoundTime`` is ``0`` by default and ``roundOverTime`` is infinite.|
| `Guid[] getPlayersReady()` | Returns an array with the Guids of players that have loaded in. |
| `RoundState getRoundState()` | Returns the current state as an enum. You can find the enum in ``round.lua``. |
| `void startPreRound()` | Starts the pre-round. |
| `void startRound()` | Starts the round. |
| `void endRound()` | Ends the round. |

The script also exposes some custom events:

| Event | Description |
| ------ | ----------- |
| `"Round:Time" (number time)` | Called when the current round time updates. Has a param with the time. |
| `"Round:WaitingForPlayers"` | Called when the round state changes to waiting for players. |
| `"Round:PreRoundStart"` | Called when the round state changes to pre-round. |
| `"Round:RoundStart"` | Called when the round state changes to in-game. |
| `"Round:RoundOver"` | Called when the round state changes to round over. |

For an example on how to use this API refer to [BoxGame](https://github.com/Raikem/BoxGame) mod.
