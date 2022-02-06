--[[
    Copyright (c) 2022 Questionable Mark
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
    AnimUtil.InitializeAnimationUtil(self)
end

function VGun:server_onCreate()
    local _data = DatabaseLoader.getServerSettings(self.shape.uuid)
    self.cannon_settings = _data.cannon

    self.cannon_ammo = self.cannon_settings.magazine_capacity
end

function VGun:server_performDataCheck()
    if self.sv_anim_wait then return end

    local is_overheating = (self.cl_cannon_heat and self.cl_cannon_heat >= 1.0)
    local is_reloading   = (self.cannon_ammo and self.cannon_ammo == 0)

    if is_overheating or is_reloading then
        local data_table = {}

        if is_overheating then
            table.insert(data_table, "overheat")
        end

        if is_reloading then
            self.cannon_ammo = self.cannon_settings.magazine_capacity
            table.insert(data_table, "reload")
        end

        self.network:sendToClients("client_onShoot", data_table)
        self.sv_anim_wait = true
    end
end

function VGun:server_onFixedUpdate(dt)
    if not sm.exists(self.interactable) then return end

    self:server_performDataCheck()

    local sCannonSet = self.cannon_settings
    if not self.reload then
        local parent = self.interactable:getSingleParent()
        local active = parent and parent.active

        if active and not self.sv_anim_wait then
            self.reload = sCannonSet.reload_time
            self.network:sendToClients("client_onShoot", "shoot")

            if self.cannon_ammo ~= nil then
                self.cannon_ammo = self.cannon_ammo - 1
            end

            local _RandomForce = math.random(sCannonSet.fire_force.min, sCannonSet.fire_force.max)
            local _Direction = sm.noise.gunSpread(sm.vec3.new(0, 0, 1), sCannonSet.spread) * _RandomForce
            sm.projectile.shapeFire(self.shape, sCannonSet.projectile, sCannonSet.projectile_offset, _Direction)

            sm.physics.applyImpulse(self.shape, sCannonSet.recoil)
        end
    else
        local _AutoReload = (not sCannonSet.auto_reload and active)
        self.reload = (self.reload > 1 and self.reload - 1) or (_AutoReload and 1) or nil
    end
end

function VGun:client_onUpdate(dt)
    AnimUtil.UpdateAnimations(self, dt)
end

function VGun:client_onShoot(anim_state)
    AnimUtil.PushAnimationState(self, anim_state)
end

function VGun:client_onDestroy()
    AnimUtil.DestroyEffects(self)
end