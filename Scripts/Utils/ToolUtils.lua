function mgp_tool_isAnimPlaying(self, anim_table)
    local fp_anims = self.fpAnimations
    if fp_anims ~= nil then
        return anim_table[fp_anims.currentAnimation] == true
    end

    return false
end