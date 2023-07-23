GameHook = class()

local gameHooked = false
local oldMsg = sm.game.setTimeOfDay
function msgHook(msg)
    if not gameHooked then
        dofile("$CONTENT_3269e6ef-4d80-4f75-b8f6-dffb303e5243/Scripts/vanilla_override.lua")
        gameHooked = true
    end

	return oldMsg(msg)
end
sm.game.setTimeOfDay = msgHook