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

function mgp_tool_createTpAnimations( tool, animationMap )
    local data = {}
    data.tool = tool
    data.animations = {}

    for name, pair in pairs(animationMap) do

        local animation = {
            info = tool:getAnimationInfo(pair[1]),
            time = 0.0,
            weight = 0.0,
            playRate = pair[2] and pair[2].playRate or 1.0,
            looping =  pair[2] and pair[2].looping or false,
            nextAnimation = pair[2] and pair[2].nextAnimation or nil,
            blendNext = pair[2] and pair[2].blendNext or 0.0
        }

        if pair[2] and pair[2].dirs then
            animation.dirs = {
                up = tool:getAnimationInfo(pair[2].dirs.up),
                fwd = tool:getAnimationInfo(pair[2].dirs.fwd),
                down = tool:getAnimationInfo(pair[2].dirs.down)
            }
        end

        if pair[2] and pair[2].crouch then
            animation.crouch = tool:getAnimationInfo(pair[2].crouch)
        end

        if animation.info == nil then
            print("Error: failed to get third person animation info for: ", pair[1])
            animation.info = {name = name, duration = 1.0, looping = false }
        end

        data.animations[name] = animation;
    end
    data.blendSpeed = 0.0
    data.currentAnimation = ""
    return data
end