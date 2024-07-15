dofile("$SURVIVAL_DATA/Scripts/game/survival_loot.lua")

---@class GunModOption
---@field minSpendAmount? number
---@field getReturnAmount? function
---@field renderable? string ID of renderable in ToolDB
---@field Sv_OnUnEquip? function
---@field Sv_OnEquip? function
---@field Cl_OnUnEquip? function
---@field Cl_OnEquip? function

---@alias GunMod { [string]: GunModOption } Options for the mod

---@class GunModData
---@field layout string Path to the layout of the mod UI
---@field mods { [string]: GunMod } The mods of the gun

---@class BaseGun : ToolClass
---@field reload_anims table
---@field fpAnimations table
---@field tpAnimations table
---@field cl_isLocal boolean
---@field aiming boolean
---@field aimBlendSpeed number
---@field maxRecoil number
---@field recoilAmount number
---@field aimRecoilAmount number
---@field recoilRecoverySpeed number
---@field aimFovTp number
---@field aimFovFp number
---@field cl_recoilAngle number
---@field mag_capacity number
---@field defaultSelectedMods table?
---@field modificationData GunModData
---@field selectedMods { [string]: string } slot -> uuid
BaseGun = class()

local emptyModSlot = sm.uuid.new("068a89ca-504e-4782-9ede-48f710aeea73")

function BaseGun:sv_init()
    local v_saved_data = self.storage:load()
	if type(v_saved_data) == "number" then
        self.sv_ammo_counter = v_saved_data
        self.sv_selectedMods = shallowcopy(self.defaultSelectedMods or {})
    elseif v_saved_data ~= nil then
		self.sv_ammo_counter = v_saved_data.ammo
        self.sv_selectedMods = v_saved_data.mods
	else
		if not sm.game.getEnableAmmoConsumption() or not sm.game.getLimitedInventory() then
			self.sv_ammo_counter = self.mag_capacity
		end

        self.sv_selectedMods = shallowcopy(self.defaultSelectedMods or {})

		self:server_updateStorage()
	end

    self.network:setClientData({ ammo = self.sv_ammo_counter, mods = self.sv_selectedMods })
end

function BaseGun:server_updateStorage(data, caller)
	if data ~= nil or caller ~= nil then return end

	self.storage:save({ ammo = self.sv_ammo_counter, mods = self.sv_selectedMods })
end

function BaseGun:sv_chooseSlotOption(data, caller)
    local slot, uuid = data.slot, data.uuid
    local modData = self.modificationData.mods[slot]
    local prevEquipped = self.sv_selectedMods[slot]
    local container = self.tool:getOwner():getInventory()
    if prevEquipped then
        local prevModSelf = modData[prevEquipped]
        if prevModSelf.Sv_OnUnEquip then
            prevModSelf:Sv_OnUnEquip(self)
        end

        local prevUuid = sm.uuid.new(prevEquipped)
        local amount = 1
        if prevModSelf.getReturnAmount then
            amount = prevModSelf:getReturnAmount(self)
        end

        if container:canCollect(prevUuid, amount) then
            sm.container.beginTransaction()
            sm.container.collect(container, prevUuid, amount)
            sm.container.endTransaction()
        else
            SpawnLoot(self.tool:getOwner(), { { uuid = prevUuid, quantity = amount } })
        end
    end

    local nextUuid = sm.uuid.new(uuid)
    if nextUuid == emptyModSlot then
        self.sv_selectedMods[slot] = nil
    else
        self.sv_selectedMods[slot] = uuid

        local nextMod = modData[uuid]
        if nextMod.Sv_OnEquip then
            nextMod:Sv_OnEquip(self)
        end

        sm.container.beginTransaction()
        sm.container.spend(container, nextUuid, nextMod.minSpendAmount or 1)
        sm.container.endTransaction()
    end

	self:server_updateStorage()
    self.network:sendToClients("cl_OnChooseSlotOption", data)
end



function BaseGun:cl_init()
    self.selectedMods = {}
end

function BaseGun:client_onToggle()
    if self:client_isGunReloading() then return true end

    self.dontReOpen = false

    local modData = self.modificationData
    if not modData then return true end

    if not self.modGui then
        self.modGui = sm.gui.createGuiFromLayout(modData.layout)
        self.modGui:setOnCloseCallback("cl_closeModGui")

        for k, v in pairs(modData.mods) do
            self.modGui:setButtonCallback("slot_"..k, "cl_openSlotOptions")
        end
    end

    self:cl_updateGuiSlots()

    swapFpAnimation( self.fpAnimations, "modExit", "modInto", 0.0 )

    self.modGui:open()

    return true
end

function BaseGun:cl_updateGuiSlots()
    for k, v in pairs(self.modificationData.mods) do
        local selected = self.selectedMods[k]
        if selected then
            self.modGui:setIconImage("slot_"..k.."_icon", sm.uuid.new(selected))
        else
            self.modGui:setIconImage("slot_"..k.."_icon", emptyModSlot)
        end
    end
end

local function GetRealLength(table)
    local count = 0
    for k, v in pairs(table) do
        count = count + 1
    end

    return count
end

function BaseGun:cl_openSlotOptions(button)
    local slot = button:sub(6, #button)
    local options = self.modificationData.mods[slot]
    if options.CanBeUnEquipped then
        options[tostring(emptyModSlot)] = {}
    end

    self.modGuiContainer = sm.gui.createGuiFromLayout("$CONTENT_DATA/Gui/Layouts/GunModOptions.layout", true)
    self.modGuiContainer:createGridFromJson("UpperGrid", {
		type = "materialGrid",
		layout = "$CONTENT_DATA/Gui/Layouts/ModSlotGridItem.layout",
		itemWidth = 44,
		itemHeight = 60,
		itemCount = GetRealLength(options),
	})

    self.modGuiContainer:setText("UpperName", "GUN MOD OPTIONS")

    local container = sm.localPlayer.getInventory()
    local count = 0
    for k, v in pairs(options) do
        local success, uuid = pcall(sm.uuid.new, k)
        if not success then
            goto continue
        end

        local amount = v.minSpendAmount or 1
        if uuid == emptyModSlot or container:canSpend(uuid, amount) then
            self.modGuiContainer:setGridItem("UpperGrid", count, {
                itemId = k,
                quantity = amount,
                slot = slot
            })

            count = count + 1
        end

        ::continue::
    end

    self.modGuiContainer:setContainer("UpperGrid", container)

    self.modGuiContainer:setGridButtonCallback("Button", "cl_chooseSlotOption")
    self.modGuiContainer:setOnCloseCallback("cl_closeSlotOptions")

    self.modGuiContainer:open()
    self.modGui:close()
end

function BaseGun:cl_chooseSlotOption(button, id, data, grid)
    if not data then return end

    local slot, uuid = data.slot, data.itemId
    if self.sv_selectedMods[slot] == uuid then return end

    self.network:sendToServer("sv_chooseSlotOption", { slot = slot, uuid = uuid })
end

function BaseGun:cl_closeModGui()
    if sm.exists(self.modGuiContainer) and self.modGuiContainer:isActive() then return end

    swapFpAnimation( self.fpAnimations, "modInto", "modExit", 0.0 )
end

function BaseGun:cl_closeSlotOptions()
    if self.dontReOpen then return end

    self:cl_updateGuiSlots()
    self.modGui:open()
end

function BaseGun:cl_OnChooseSlotOption(data)
    local slot, uuid = data.slot, data.uuid
    local prevEquipped = self.selectedMods[slot]
    local modData = self.modificationData.mods[slot]
    if prevEquipped then
        local prevModSelf = modData[prevEquipped]
        if prevModSelf.Cl_OnUnEquip then
            prevModSelf:Cl_OnUnEquip(self)
        end

        if prevModSelf.renderable then
            mgp_updateRenderables(self, { name = prevModSelf.renderable, enbled = false }, uuid == tostring(emptyModSlot))
        end
    end

    if uuid == tostring(emptyModSlot) then
        self.selectedMods[slot] = nil
    else
        self.selectedMods[slot] = uuid

        local nextModSelf = modData[uuid]
        if nextModSelf.Cl_OnEquip then
            if nextModSelf:Cl_OnEquip(self) then
                self.dontReOpen = true
            end
        end

        if nextModSelf.renderable then
            mgp_updateRenderables(self, { name = nextModSelf.renderable, enabled = true }, true)
        end
    end

    self.modGuiContainer:close()
end

function BaseGun:client_onClientDataUpdate(data, channel)
    self.ammo_in_mag = data.ammo
    self.selectedMods = data.mods

    self.waiting_for_ammo = false
end

function BaseGun:client_updateAimWeights(dt)
	-- Camera update
	local bobbing = 1
	if self.aiming then
		local blend = 1 - math.pow( 1 - 1 / self.aimBlendSpeed, dt * 20 )
		self.aimWeight = sm.util.lerp( self.aimWeight, 1.0, blend )
		bobbing = 0.12
	else
		local blend = 1 - math.pow( 1 - 1 / self.aimBlendSpeed, dt * 60 )
		self.aimWeight = sm.util.lerp( self.aimWeight, 0.0, blend )
		bobbing = 1
	end

	self.tool:updateCamera( 2.8, self.aimFovTp, sm.vec3.new( 0.65, 0.0, 0.05 ), self.aimWeight )
	self.tool:updateFpCamera( self.aimFovFp, sm.vec3.new( 0.0, 0.0, 0.0 ), self.aimWeight, bobbing )
end

function BaseGun:client_isGunReloading(reload_anims)
	if self.waiting_for_ammo then
		return true
	end

	return mgp_tool_isAnimPlaying(self, reload_anims or self.reload_anims)
end