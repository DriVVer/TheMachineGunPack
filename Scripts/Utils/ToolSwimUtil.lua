---@class TSUTool : ToolClass
---@field equipped boolean
---@field wantEquipped boolean
TSUTool = {} --added to make the lua preprocessor finally shut up
function TSUTool:client_onUnequip(self, data) end
function TSUTool:client_onEquip(self, data) end

---@param self TSUTool|ToolClass
function TSU_IsOwnerSwimming(self)
	local v_owner = self.tool:getOwner()
	if v_owner and sm.exists(v_owner) then
		local v_ownerChar = v_owner.character
		if v_ownerChar and sm.exists(v_ownerChar) then
			return v_ownerChar:isSwimming() or v_ownerChar:isDiving()
		end
	end

	return true
end

---@param self TSUTool|ToolClass
function TSU_OnUpdate(self)
	if self.tool:isEquipped() then
		if TSU_IsOwnerSwimming(self) then
			if self.equipped then
				self:client_onUnequip(false, true)
			end
		else
			if not self.equipped and not self.wantEquipped then
				self:client_onEquip(false, true)
			end
		end
	end
end