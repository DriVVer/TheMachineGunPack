--[[
    Copyright (c) 2021 Questionable Mark
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

function AnimUtil.PrepareAnimation(self, anim_data, method)
    if method == 2 then
        if anim_data.required_animations then
            for i, anim in pairs(anim_data.required_animations) do
                self.interactable:setAnimEnabled(anim, true)
            end
        end
    end
end

function AnimUtil.GetAnimVariables(self)
    self.anim = {}
    self.anim.active = false
    self.anim.step = 0
    self.anim.timer = nil
end

function AnimUtil.UnpackAnimation(anim, method)
    if method == 1 then
        return anim
    elseif method == 2 then
        return anim.animation
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

            for i, anim in pairs(_CurAnim.anims) do
                self.interactable:setAnimProgress(anim, _FinalValue)
            end

            self.anim.timer = (_PredictTime > 0 and self.anim.timer - dt) or nil
        end
    end;
}