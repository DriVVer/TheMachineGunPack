--[[
    Copyright (c) 2022 Questionable Mark
]]

dofile("Databases/BreechDatabase.lua")

Breech = class()
Breech.maxParentCount = 1
Breech.maxChildCount  = 0
Breech.connectionInput  = sm.interactable.connectionType.logic
Breech.connectionOutput = sm.interactable.connectionType.none
Breech.colorNormal    = sm.color.new(0x000080ff)
Breech.colorHighlight = sm.color.new(0x0000edff)

function Breech:client_onCreate()

end

function Breech:client_onUpdate(dt)
	
end

function Breech:client_onDestroy()

end

function Breech:server_onCreate()

end

function Breech:server_onFixedUpdate()
	
end