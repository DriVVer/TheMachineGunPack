--[[
    Copyright (c) 2021 Questionable Mark
]]

--if AnimUtil then return end
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

    for k, v in pairs(self.anim.required_animations) do
        sInteractable:setAnimProgress(v, 0)
    end
end

function AnimUtil.PushAnimationState(self, state)
    local is_shoot_state = self.anim.cur_state == "shoot"

    local state_type = type(state)
    if self.anim.cur_state == nil or is_shoot_state then
        local cur_state = nil
        if state_type == "string" then
            cur_state = state
        elseif state_type == "table" then
            cur_state = state[1]
            table.remove(state, 1)

            for k, v in pairs(state) do
                table.insert(self.anim.state_queue, v)
            end
        end

        self.anim.cur_data = self.anim.data[cur_state]
        self.anim.cur_state = cur_state

        if cur_state == "overheat" then
            self.cl_cannon_heat = 0
        end

        AnimUtil.ResetAnimations(self)

        self.anim.active = true
        self.anim.step = 0
        self.anim.timer = nil

        if cur_state == "shoot" then
            self.cl_cannon_heat = (self.cl_cannon_heat or 0.0) + self.cl_heat_per_shot
        end
    else
        if state_type == "string" then
            table.insert(self.anim.state_queue, state)
        elseif state_type == "table" then
            for k, v in pairs(state) do
                table.insert(self.anim.state_queue, v)
            end
        end
    end
end

function AnimUtil.InitializeAnimationUtil(self)
    local _data = DatabaseLoader.getClientSettings(self.shape.uuid)

    self.cl_cooling_speed = _data.cooling_speed
    self.cl_heat_per_shot = _data.heat_per_shot

    self.cl_overheat_anim_max = _data.uv_overheat_anim_max

    AnimUtil.InitializeEffects(self, _data.effects)
    AnimUtil.GetAnimVariables(self)

    self.anim.method = AnimUtil.getAnimMethod(_data)
    if self.anim.method then
        local mAnimData = _data[AnimUtil.anim_method_t[self.anim.method]]
        self.anim.required_animations = mAnimData.required_animations

        AnimUtil.PrepareAnimation(self)

        self.anim.data = AnimUtil.UnpackAnimation(mAnimData, self.anim.method)
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

AnimUtil.anim_method = {
    [1] = function(self, dt)
        if not self.anim.active then return end

        if not self.anim.timer then
            if self.anim.step < #self.anim_data then
                self.anim.step = self.anim.step + 1
                self.anim.timer = self.anim_data[self.anim.step].time
            else
                self.anim.active = false
                self.anim.step = 0
            end
        else
            local _PredictTime = (self.anim.timer - dt)
            local _CurAnim = self.anim_data[self.anim.step]

            local _AnimProg = (_CurAnim.time - math.max(_PredictTime, 0)) / _CurAnim.time
            local _NormalizedValue = math.min(math.max(_AnimProg, 0), 1)
            local _FinalValue = sm.util.lerp(_CurAnim.start_value, _CurAnim.end_value, _NormalizedValue)

            self.interactable:setPoseWeight(_CurAnim.pose, _FinalValue)
            self.anim.timer = (_PredictTime > 0 and self.anim.timer - dt) or nil
        end
    end;
    [2] = function(self, dt)
        if not self.anim.active then return end

        local cur_anim_data = self.anim.cur_data
        if not cur_anim_data then return end

        if not self.anim.timer then
            if self.anim.step < #cur_anim_data then
                self.anim.step = self.anim.step + 1
                self.anim.timer = cur_anim_data[self.anim.step].time or 0
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
            end
        else
            local mCurAnim = cur_anim_data[self.anim.step]
            if mCurAnim.particles then
                for k, mParticle in pairs(mCurAnim.particles) do
                    self.effects[mParticle]:start()
                end

                self.anim.timer = nil
            else
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
        end
    end;
}