--[[
    Copyright (c) 2022 Questionable Mark
]]

--if ExplGun then return end
dofile("./AnimationUtil.lua")
dofile("./GunDatabase.lua")
ExplGun = class()
ExplGun.maxParentCount = 1
ExplGun.maxChildCount = 0
ExplGun.connectionInput = sm.interactable.connectionType.logic
ExplGun.connectionOutput = sm.interactable.connectionType.none
ExplGun.colorNormal = sm.color.new(0xcb0a00ff)
ExplGun.colorHighlight = sm.color.new(0xee0a00ff)
ExplGun.poseWeightCount = 3

function ExplGun:client_onCreate()
    AnimUtil.InitializeAnimationUtil(self)

    self.projectiles = {}
end

function ExplGun:server_onCreate()
    local _data = DatabaseLoader.getServerSettings(self.shape.uuid)
    self.projectileConfig = {
        effect = _data.projectile.effect,
        explosionEffect = _data.projectile.explosionEffect,
        effectOffset = _data.projectile.effectOffset,
        lifetime = _data.projectile.lifetime,
        gravity = _data.projectile.gravity,
        friction = _data.projectile.friction,
        explosionLevel = _data.projectile.explosionLevel,
        explosionRadius = _data.projectile.explosionRadius,
        explosionImpulseStrength = _data.projectile.explosionImpulseStrength,
        explosionImpulseRadius = _data.projectile.explosionImpulseRadius,
        dir = sm.vec3.zero()
    }
    self.cannon_settings = _data.cannon
    self.cannon_ammo = self.cannon_settings.magazine_capacity
end

function ExplGun:server_performDataCheck()
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

        self.network:sendToClients("client_onOtherAnim", data_table)
        self.sv_anim_wait = true
    end
end

function ExplGun:server_onFixedUpdate(dt)
    if not sm.exists(self.interactable) then return end

    self:server_performDataCheck()

    local sCannonSet = self.cannon_settings
    if not self.reload then
        local parent = self.interactable:getSingleParent()
        local active = parent and parent.active

        if active and not self.sv_anim_wait then
            self.reload = sCannonSet.reload_time

            if self.cannon_ammo ~= nil then
                self.cannon_ammo = self.cannon_ammo - 1
            end

            local _RandomForce = math.random(sCannonSet.fire_force.min, sCannonSet.fire_force.max)
            local _Direction = sm.noise.gunSpread(self.shape.up, sCannonSet.spread) * _RandomForce
            self.projectileConfig.dir = _Direction
            self.network:sendToClients("client_onShoot", self.projectileConfig)

            sm.physics.applyImpulse(self.shape, sCannonSet.recoil)
        end
    else
        local _AutoReload = (not sCannonSet.auto_reload and active)
        self.reload = (self.reload > 1 and self.reload - 1) or (_AutoReload and 1) or nil
    end

    for k, bullet in pairs(self.projectiles) do
        if bullet and bullet.hit then
            sm.physics.explode(bullet.hit, bullet.explosionLevel, bullet.explosionRadius, bullet.explosionImpulseRadius, bullet.explosionImpulseStrength, bullet.explosionEffect)
        end
    end
end

function ExplGun:client_onFixedUpdate(dt)
    for k, bullet in pairs(self.projectiles) do
        if bullet and bullet.hit then
            self.projectiles[k] = nil
            bullet.effect:stop()
            bullet.effect:destroy()
        end
        if bullet and not bullet.hit then
            bullet.lifetime = bullet.lifetime - dt
            bullet.dir = bullet.dir * (1 - bullet.friction) - sm.vec3.new(0, 0, bullet.gravity * dt)

            local right = sm.vec3.new(0,0,1):cross(bullet.dir)
            if right:length()<0.001 then right = sm.vec3.new(1,0,0) else right = right:normalize() end
            local up = self.shape.up:cross(right)

            local hit, result = sm.physics.raycast( bullet.pos, bullet.pos + bullet.dir * dt*1.1 )
            if not hit then 
                hit, result = sm.physics.raycast( bullet.pos, bullet.pos + bullet.dir * dt*1.1 + up/8 + right/8)
                if not hit then 
                    hit, result = sm.physics.raycast( bullet.pos, bullet.pos + bullet.dir * dt*1.1 + up/8 - right/8)
                    if not hit then 
                        hit, result = sm.physics.raycast( bullet.pos, bullet.pos + bullet.dir * dt*1.1 - up/8 - right/8)
                        if not hit then 
                            hit, result = sm.physics.raycast( bullet.pos, bullet.pos + bullet.dir * dt*1.1 - up/8 + right/8)
                        end
                    end
                end
            end
            
            if hit or bullet.lifetime <= 0.0 then
                bullet.hit = (hit and result.pointWorld or bullet.pos)
                bullet.effect:setPosition(sm.vec3.new(0, 0, 10000))
            end

            if bullet.dir:length() > 0.0001 then
                local _Rotation = sm.vec3.getRotation(sm.vec3.new(0, 0, 1), bullet.dir)
                bullet.effect:setRotation(_Rotation)
            end

            bullet.effect:setPosition(bullet.pos)
            bullet.pos = bullet.pos + bullet.dir * dt
        end
	end
end

local function BetterExists(object)
    if object == nil then return false end

    local success, error = pcall(sm.exists, object)
    return (success and error == true)
end

function ExplGun:client_onUpdate(dt)
    AnimUtil.UpdateAnimations(self, dt)
end

function ExplGun:client_onOtherAnim(data)
    AnimUtil.PushAnimationState(self, data)
end

function ExplGun:client_onShoot(data)
    if not BetterExists(self.shape) then
        print("Couldn't spawn explosive projectile")
        return
    end

    local _ShellEffect = sm.effect.createEffect(data.effect)
    local _OffsetPosition = self.shape.worldPosition + self.shape.worldRotation * data.effectOffset
    _ShellEffect:setPosition(_OffsetPosition)
    _ShellEffect:start()

    local _Bullet = {
        effect = _ShellEffect,
        pos = _OffsetPosition,
        dir = data.dir,
        gravity = data.gravity,
        friction = data.friction,
        lifetime = data.lifetime,
        explosionEffect = data.explosionEffect,
        explosionLevel = data.explosionLevel,
        explosionRadius = data.explosionRadius,
        explosionImpulseRadius = data.explosionImpulseRadius,
        explosionImpulseStrength = data.explosionImpulseStrength
    }

    self.projectiles[#self.projectiles + 1] = _Bullet

    AnimUtil.PushAnimationState(self, "shoot")
end

function ExplGun:client_onDestroy()
    AnimUtil.DestroyEffects(self)

    for k, bullet in pairs(self.projectiles) do
        if bullet and BetterExists(bullet.effect) then
            bullet.effect:setPosition(sm.vec3.new(0, 0, 10000))
            bullet.effect:stop()
            bullet.effect:destroy()
        end
        
        self.projectiles[k] = nil
    end
end