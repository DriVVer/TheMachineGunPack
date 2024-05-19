function mgp_tool_isAnimPlaying(self, anim_table)
    local fp_anims = self.fpAnimations
    if fp_anims ~= nil then
        return anim_table[fp_anims.currentAnimation] == true
    end

    return false
end

function mgp_tool_getToolDir(self)
    if g_TMGP_SETTINGS.recoilType == 0 then
        return sm.localPlayer.getDirection()
    end

    return sm.localPlayer.getDirection():rotate(self.cl_recoilAngle, sm.localPlayer.getRight())
end