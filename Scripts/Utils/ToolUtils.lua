function mgp_tool_isAnimPlaying(self, anim_table)
    local fp_anims = self.fpAnimations
    if fp_anims ~= nil then
        return anim_table[fp_anims.currentAnimation] == true
    end

    return false
end

function mgp_tool_getToolDir(self)
    if g_TMGP_SETTINGS.recoilType == 0 then
        return sm.camera.getDirection()
    end

    return sm.camera.getDirection():rotate(self.cl_recoilAngle, sm.camera.getRight())
end

---@param self any
---@param slot string
---@return GunModOption
function mgp_tool_GetSelectedMod(self, slot)
    return self.modificationData.mods[slot][(self.sv_selectedMods or self.selectedMods)[slot]]
end

function mgp_tool_GetMods(self, slot)
    return self.modificationData.mods[slot]
end

---@param mod GunModOption
function mgp_tool_GetModReturnAmount(self, mod)
    if mod.getReturnAmount then
        return mod:getReturnAmount(self)
    end

    return 1
end