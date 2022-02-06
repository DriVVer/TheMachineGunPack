--[[
    Copyright (c) 2022 Questionable Mark
]]

if AnimUtil then return end
AnimUtil = class()

function AnimUtil.getAnimMethod(info_table)
    if info_table.pose_animation then
        return 1
    elseif info_table.bone_animation then
        return 2
    end
end

function AnimUtil.PrepareAnimation(self)
    local sAnim = self.anim

    if sAnim.method == 2 and sAnim.required_animations then
        local sInteractable = self.interactable

        for i, anim in pairs(sAnim.required_animations) do
            sInteractable:setAnimEnabled(anim, true)
        end
    end
end

function AnimUtil.GetAnimVariables(self)
    self.anim = {}
    self.anim.active = false
    self.anim.step = 0
    self.anim.timer = nil

    self.anim.data = {}
    self.anim.method = nil

    self.anim.cur_data = nil
    self.anim.cur_state = nil

    self.anim.required_animations = {}
    self.anim.state_queue = {}

    self.anim.type = AnimUtil.animation_types.anim_selector
end

function AnimUtil.DestroyEffects(self)
    for k, mEffect in pairs(self.effects) do
        if sm.exists(mEffect) then
            mEffect:stop()
            mEffect:destroy()
        end
    end
end

function AnimUtil.InitializeEffects(self, effect_data)
    self.effects = {}

    for k, eData in pairs(effect_data) do
        local new_effect = sm.effect.createEffect(eData.name, self.interactable, eData.bone_name)
        new_effect:setOffsetPosition(eData.offset)

        self.effects[k] = new_effect
    end
end

function AnimUtil.ResetAnimations(self)
    local sInteractable = self.interactable

    local sAnim = self.anim
    if sAnim.method == 2 then
        for k, v in pairs(sAnim.required_animations) do
            sInteractable:setAnimProgress(v, 0)
        end
    else
        sInteractable:setPoseWeight(0, 0)
        sInteractable:setPoseWeight(1, 0)
        sInteractable:setPoseWeight(2, 0)
    end
end

local function AnimUtil_PushAnimationStateInternal(self, state)
    self.anim.cur_data = self.anim.data[state]
    self.anim.cur_state = state

    AnimUtil.ResetAnimations(self)

    self.anim.active = true
    self.anim.step = 0
    self.anim.timer = nil

    if state == "shoot" and self.cl_heat_per_shot then
        self.cl_cannon_heat = (self.cl_cannon_heat or 0.0) + self.cl_heat_per_shot
    end
end

function AnimUtil.UpdateAnimations(self, dt)
    if self.anim then
        local anim_method = self.anim.method

        if anim_method then
            AnimUtil.anim_method[anim_method](self, dt)
        end
    end

    if self.cl_cannon_heat then
        if self.cl_cannon_heat > 0 then
            self.cl_cannon_heat = self.cl_cannon_heat - (self.cl_cooling_speed * dt)
        else
            self.cl_cannon_heat = nil
        end
    end

    if self.cl_overheat_anim_max then
        local clamped_heat = math.min(math.max(self.cl_cannon_heat or 0, 0), 1)
        self.cl_uv_heat_value = sm.util.lerp(self.cl_uv_heat_value or 0, clamped_heat, dt)

        self.interactable:setUvFrameIndex(self.cl_uv_heat_value * self.cl_overheat_anim_max)
    end
end

function AnimUtil.PushAnimationState(self, state)
    self.anim.push_method(self, state)
end

local AnimUtil_AnimPushFunctions = {
    [1] = function(self, state)
        AnimUtil.ResetAnimations(self)

        self.anim.active = true
        self.anim.step = 0
        self.anim.timer = nil
    end;
    [2] = function(self, state)
        local is_state_string = (type(state) == "string")
    
        local can_skip_anim = not self.anim.cur_state or (self.anim.cur_state == "shoot" and state == "shoot")
        if can_skip_anim then
            local cur_state = state
            if not is_state_string then
                cur_state = state[1]
                table.remove(state, 1)

                for k, v in pairs(state) do
                    table.insert(self.anim.state_queue, v)
                end
            end

            AnimUtil_PushAnimationStateInternal(self, cur_state)
        else
            if is_state_string then
                table.insert(self.anim.state_queue, state)
            else --is table
                for k, v in pairs(state) do
                    table.insert(self.anim.state_queue, v)
                end
            end
        end
    end
}

function AnimUtil.InitializeAnimationUtil(self)
    local _data = DatabaseLoader.getClientSettings(self.shape.uuid)

    local overheat_eff = _data.overheat_effect
    if overheat_eff then
        self.cl_heat_per_shot = overheat_eff.heat_per_shot
        self.cl_cooling_speed = overheat_eff.cooling_speed

        self.cl_overheat_anim_max = overheat_eff.uv_overheat_anim_max
    end

    AnimUtil.InitializeEffects(self, _data.effects)
    AnimUtil.GetAnimVariables(self)

    self.anim.method = AnimUtil.getAnimMethod(_data)
    if self.anim.method then
        local mAnimData = _data[AnimUtil.anim_method_t[self.anim.method]]
        self.anim.required_animations = mAnimData.required_animations

        AnimUtil.PrepareAnimation(self)
        self.anim.push_method = AnimUtil_AnimPushFunctions[self.anim.method]

        self.anim.data = AnimUtil.UnpackAnimation(mAnimData, self.anim.method)
        if self.anim.method == 1 then
            self.anim.cur_data = self.anim.data
        end
    end
end

function AnimUtil.UnpackAnimation(anim, method)
    if method == 1 then
        return anim
    elseif method == 2 then
        return anim.animation_states
    end
end

AnimUtil.anim_method_t = {
    [1] = "pose_animation",
    [2] = "bone_animation"
}

local AnimUtil_AnimationFunctions = {
    [1] = function(self, dt) --pose animation
        local _CurAnim = self.anim.data[self.anim.step]
        local _PredictTime = (self.anim.timer - dt)

        local _AnimProg = (_CurAnim.time - math.max(_PredictTime, 0)) / _CurAnim.time
        local _NormalizedValue = math.min(math.max(_AnimProg, 0), 1)
        local _FinalValue = sm.util.lerp(_CurAnim.start_value, _CurAnim.end_value, _NormalizedValue)

        self.interactable:setPoseWeight(_CurAnim.pose, _FinalValue)
        self.anim.timer = (_PredictTime > 0 and self.anim.timer - dt) or nil
    end;
    [2] = function(self, dt) --bone animation
        local mCurAnim = self.anim.cur_data[self.anim.step]
        local _PredictTime = (self.anim.timer - dt)

        local _AnimProg = (mCurAnim.time - math.max(_PredictTime, 0)) / mCurAnim.time
        local _NormalizedValue = math.min(math.max(_AnimProg, 0), 1)
        local _FinalValue = sm.util.lerp(mCurAnim.start_value, mCurAnim.end_value, _NormalizedValue)

        local sInteractable = self.interactable
        for i, anim in pairs(mCurAnim.anims) do
            sInteractable:setAnimProgress(anim, _FinalValue)
        end

        self.anim.timer = (_PredictTime > 0 and self.anim.timer - dt) or nil
    end
}

AnimUtil.animation_types = {
    anim_selector = function(self, dt)
        local cur_anim_data = self.anim.cur_data
        local mCurAnim = cur_anim_data[self.anim.step]

        if mCurAnim.particles then
            self.anim.type = AnimUtil.animation_types.particle
        else
            self.anim.type = AnimUtil_AnimationFunctions[self.anim.method]
        end

        self.anim.type(self, dt)
    end;
    particle = function(self, dt)
        local mCurAnim = self.anim.cur_data[self.anim.step]

        for k, mParticle in pairs(mCurAnim.particles) do
            self.effects[mParticle]:start()
        end

        self.anim.timer = nil
    end
}

AnimUtil.anim_method = {
    [1] = function(self, dt)
        if not self.anim.active then return end

        if not self.anim.timer then
            local cur_anim_data = self.anim.data

            if self.anim.step < #cur_anim_data then
                self.anim.step = self.anim.step + 1
                self.anim.timer = cur_anim_data[self.anim.step].time

                self.anim.type = AnimUtil.animation_types.anim_selector
            else
                self.anim.active = false
                self.anim.step = 0

                return
            end
        end

        self.anim.type(self, dt)
    end;
    [2] = function(self, dt)
        if not self.anim.active then return end

        if not self.anim.timer then
            local cur_anim_data = self.anim.cur_data

            if self.anim.step < #cur_anim_data then
                self.anim.step = self.anim.step + 1
                self.anim.timer = cur_anim_data[self.anim.step].time or 0

                self.anim.type = AnimUtil.animation_types.anim_selector
            else
                self.anim.step = 0

                if #self.anim.state_queue > 0 then
                    local cur_state = self.anim.state_queue[1]
                    if cur_state == "overheat" then
                        self.cl_cannon_heat = 0
                    end

                    self.anim.cur_data = self.anim.data[cur_state]

                    table.remove(self.anim.state_queue, 1)
                else
                    self.anim.active = false
                    self.anim.cur_state = nil
                    self.sv_anim_wait = false
                end

                return
            end
        end

        self.anim.type(self, dt)
    end;
}