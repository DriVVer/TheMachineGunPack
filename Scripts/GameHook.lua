---@class GameHook : ToolClass
GameHook = class()

function GameHook:server_onCreate()
    g_TMGP_GAMEHOOK = self.tool

    self.modSettings = self.storage:load() or { recoil = false }
    self.network:sendToClients("cl_syncSettings", self.modSettings)
end

function GameHook:sv_toggleSetting(args)
    local setting = args.setting
    local new = not self.modSettings[setting]
    if args.value ~= nil then
        new = args.value
    end
    self.modSettings[setting] = new

    self.storage:save(self.modSettings)
    self.network:sendToClients("cl_chatMsg", args.msg..(new and "#00ff00ON" or "#ff0000OFF"))
    self.network:sendToClients("cl_syncSettings", self.modSettings)
end



g_TMGP_SETTINGS = g_TMGP_SETTINGS or {} --Empty before load
function GameHook:cl_syncSettings(settings)
    g_TMGP_SETTINGS = settings
end

function GameHook:cl_chatMsg(msg)
    sm.gui.chatMessage(msg)
end



oldBind = oldBind or sm.game.bindChatCommand
function bindHook(command, params, callback, help)
    if not gameHooked then
        gameHooked = true

        if sm.isHost then
            oldBind(
                "/toggleRecoil",
                {
                    { "bool", "enable", true },
                },
                "cl_onChatCommand",
                "Toggles recoil"
            )
        end

        dofile("$CONTENT_3269e6ef-4d80-4f75-b8f6-dffb303e5243/Scripts/vanilla_override.lua")
    end

	return oldBind(command, params, callback, help)
end
sm.game.bindChatCommand = bindHook



oldWorldEvent = oldWorldEvent or sm.event.sendToWorld
function worldEventHook(world, callback, args)
    if callback == "sv_e_onChatCommand" then
        local command = args[1]
        if command == "/toggleRecoil" then
            sm.event.sendToTool(g_TMGP_GAMEHOOK, "sv_toggleSetting", { setting = "recoil", value = args[2], msg = "RECOIL: " })
        end
    end

    return oldWorldEvent(world, callback, args)
end
sm.event.sendToWorld = worldEventHook