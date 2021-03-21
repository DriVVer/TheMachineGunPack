--[[
    Copyright (c) 2021 Questionable Mark
]]

if VGun then return end
dofile("./AnimationUtil.lua")
dofile("./GunDatabase.lua")
VGun = class()
VGun.maxParentCount = 1
VGun.maxChildCount = 0
VGun.connectionInput = sm.interactable.connectionType.logic
VGun.connectionOutput = sm.interactable.connectionType.none
VGun.colorNormal = sm.color.new(0xcb0a00ff)
VGun.colorHighlight = sm.color.new(0xee0a00ff)
VGun.poseWeightCount = 3

function VGun:client_onCreate()
    local _data = DatabaseLoader.getClientSettings(self.shape.uuid)
    self.shoot = sm.effect.createEffect(_data.effect, self.interactable)
    self.shoot:setOffsetPosition(_data.effect_offset)

    self.anim_method = AnimUtil.getAnimMethod(_data)
    if self.anim_method then
        local _AnimData = _data[AnimUtil.anim_method_t[self.anim_method]]

        AnimUtil.PrepareAnimation(self, _AnimData, self.anim_method)

        self.anim_data = AnimUtil.UnpackAnimation(_AnimData, self.anim_method)
    end

    AnimUtil.GetAnimVariables(self)
end

function VGun:server_onCreate()
    local _data = DatabaseLoader.getServerSettings(self.shape.uuid)
    self.cannon_settings = _data.cannon
end

function VGun:server_onFixedUpdate(dt)
    if not sm.exists(self.interactable) then return end
    local parent = self.interactable:getSingleParent()
    local active = parent and parent.active

    if active and not self.reload then
        self.reload = self.cannon_settings.reload_time
        self.network:sendToClients("client_onShoot")

        local _RandomForce = math.random(self.cannon_settings.fire_force.min, self.cannon_settings.fire_force.max)
        local _Direction = sm.noise.gunSpread(sm.vec3.new(0, 0, 1), self.cannon_settings.spread) * _RandomForce
        sm.projectile.shapeFire(self.shape, self.cannon_settings.projectile, self.cannon_settings.projectile_offset, _Direction)

        sm.physics.applyImpulse(self.shape, self.cannon_settings.recoil)
    end

    if self.reload then
        local _AutoReload = (not self.cannon_settings.auto_reload and active)
        self.reload = (self.reload > 1 and self.reload - 1) or (_AutoReload and 1) or nil
    end
end

function VGun:client_onUpdate(dt)
    if not self.anim_method then return end
    AnimUtil.anim_method[self.anim_method](self, dt)
end

function VGun:client_onShoot()
    self.shoot:start()

    if self.anim_data and #self.anim_data > 0 then
        self.anim.active = true
        self.anim.step = 0
        self.anim.timer = nil
    end
end

function VGun:client_onDestroy()
    self.shoot:stop()
    self.shoot:destroy()
end