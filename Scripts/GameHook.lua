---@class GameHook : ToolClass
GameHook = class()

local defaultSettings = {
    recoil = false,
    recoilType = 0
}

function GameHook:server_onCreate()
    if g_TMGP_GAMEHOOK then return end --avoid multiple loads

    g_TMGP_GAMEHOOK = self.tool

    self.modSettings = self.storage:load() or defaultSettings
    if self.modSettings.recoilType == nil then
        self.modSettings.recoilType = 0
    end

    self.network:sendToClients("cl_syncSettings", self.modSettings)
end

function GameHook:sv_toggleSetting(args)
    local setting = args.setting
    local new = not self.modSettings[setting]
    if args.value ~= nil then
        new = args.value
    end

    self:sv_setSetting({ setting = setting, value = new, msg = args.msg..(new and "#00ff00ON" or "#ff0000OFF") })
end

function GameHook:sv_setSetting(args)
    local new = args.value
    local client = args.client
    if client then
        self.network:sendToClient(client, "cl_chatMsg", args.msg)

        local settings = shallowcopy(self.modSettings)
        settings[args.setting] = new
        self.network:sendToClient(client, "cl_syncSettings", settings)

        return
    end

    self.modSettings[args.setting] = new
    self.storage:save(self.modSettings)
    self.network:sendToClients("cl_chatMsg", args.msg)
    self.network:sendToClients("cl_syncSettings", self.modSettings)
end



g_TMGP_SETTINGS = g_TMGP_SETTINGS or defaultSettings --Empty before load
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

        oldBind(
            "/setRecoilType",
            {
                { "int", "recoil type", false },
            },
            "cl_onChatCommand",
            "Recoil types: 0 - Camera | 1 - Gun"
        )

        dofile("$CONTENT_3269e6ef-4d80-4f75-b8f6-dffb303e5243/Scripts/vanilla_override.lua")
    end

	return oldBind(command, params, callback, help)
end
sm.game.bindChatCommand = bindHook



local recoilToName = {
    [0] = "CAMERA",
    [1] = "GUN"
}

oldWorldEvent = oldWorldEvent or sm.event.sendToWorld
function worldEventHook(world, callback, args)
    if callback == "sv_e_onChatCommand" then
        local command = args[1]
        if command == "/toggleRecoil" then
            sm.event.sendToTool(g_TMGP_GAMEHOOK, "sv_toggleSetting", { setting = "recoil", value = args[2], msg = "RECOIL: " })
        elseif command == "/setRecoilType" then
            local value = args[2]
            sm.event.sendToTool(g_TMGP_GAMEHOOK, "sv_setSetting", { setting = "recoilType", value = value, msg = "RECOIL TYPE: #df7f00"..recoilToName[value], client = args.player })
        end
    end

    return oldWorldEvent(world, callback, args)
end
sm.event.sendToWorld = worldEventHook