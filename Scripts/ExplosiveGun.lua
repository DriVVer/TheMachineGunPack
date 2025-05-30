--[[
	Copyright (c) 2022 Questionable Mark
]]

if ExplGun then return end

dofile("Databases/GunDatabase.lua")
dofile("Utils/AnimationUtil.lua")
dofile("Utils/BoneTracker.lua")

---@class ExplProj
---@field effect Effect
---@field hit Vec3
---@field explosionLevel integer
---@field explosionRadius integer
---@field explosionImpulseRadius integer
---@field explosionImpulseStrength integer
---@field explosionEffect string
---@field friction integer
---@field gravity integer
---@field pos Vec3
---@field dir Vec3

---@class ExplGun : ShapeClass
---@field sv_anim_wait boolean
---@field projectiles ExplProj[]
ExplGun = class()
ExplGun.maxParentCount = 1
ExplGun.maxChildCount  = 0
ExplGun.connectionInput  = sm.interactable.connectionType.logic
ExplGun.connectionOutput = sm.interactable.connectionType.none
ExplGun.colorNormal    = sm.color.new(0xcb0a00ff)
ExplGun.colorHighlight = sm.color.new(0xee0a00ff)
ExplGun.poseWeightCount = 3

function ExplGun:client_onCreate()
	self.projectiles = {}

	local _data = DatabaseLoader.getClientSettings(self.shape.uuid)
	AnimUtil_InitializeAnimationUtil(self, _data)
	BoneTracker_Initialize(self, _data.bone_tracker)

	if not self.sv_server_host then
		self.network:sendToServer("server_requestAnimData")
	end
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

	self.sv_server_host = true
end

function ExplGun:server_requestAnimData(data, player)
	AnimUtil_SendAnimationData(self, player)
end

function ExplGun:client_receiveAnimData(data)
	AnimUtil_ReceiveAnimationData(self, data)
end

function ExplGun:server_onFixedUpdate(dt)
	if not sm.exists(self.interactable) then return end

	AnimUtil_server_performDataCheck(self, "client_onOtherAnim")

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
				local _Rotation = sm.vec3.getRotation(sm.vec3.new(0, -1, 0), bullet.dir)
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
	AnimUtil_UpdateAnimations(self, dt)
end

function ExplGun:client_onOtherAnim(data)
	AnimUtil_SetAnimation(self, data)
end

local g_cannonEffects =
{
	["f0f14c15-4d9c-4dc3-8518-4ae65af491da"] = { uuid = sm.uuid.new("d7a0fd34-6a9c-4be8-be10-4e7016e05861"), scale = sm.vec3.new(0.25, 10.25, 0.25) }, --Hispano 20mm Gun
	["05f70a50-3bb4-4a00-b7fb-f1c931d585ca"] = { uuid = sm.uuid.new("d7a0fd34-6a9c-4be8-be10-4e7016e05861"), scale = sm.vec3.new(0.25, 10.25, 0.25) }, -- 12mm dszk
	["f9213740-d7ca-41ed-b1c8-23dd704c9063"] = { uuid = sm.uuid.new("d7a0fd34-6a9c-4be8-be10-4e7016e05861"), scale = sm.vec3.new(0.25, 10.25, 0.25) }, -- .50 air
	["de609e41-58d1-409a-b981-447be0257609"] = { uuid = sm.uuid.new("d7a0fd34-6a9c-4be8-be10-4e7016e05861"), scale = sm.vec3.new(0.25, 10.25, 0.25) }, -- .50 1x1
	["bdd9e357-35f7-4140-8b19-477abef20e0f"] = { uuid = sm.uuid.new("d7a0fd34-6a9c-4be8-be10-4e7016e05861"), scale = sm.vec3.new(0.25, 10.25, 0.25) }, -- .50 brow
	["9fec1f9f-9f39-4d95-95d3-c15c4389e095"] = { uuid = sm.uuid.new("d7a0fd34-6a9c-4be8-be10-4e7016e05861"), scale = sm.vec3.new(0.25, 10.25, 0.25) }, -- 20mm wz38
	["073d0f36-9bee-47e4-b4b6-c42568648e3b"] = { uuid = sm.uuid.new("d7a0fd34-6a9c-4be8-be10-4e7016e05861"), scale = sm.vec3.new(0.25, 10.25, 0.25) }, -- 20mm mg 151
	["28fbfaf6-3b42-4d72-94b1-5bf7b113b5dd"] = { uuid = sm.uuid.new("d7a0fd34-6a9c-4be8-be10-4e7016e05861"), scale = sm.vec3.new(0.25, 10.25, 0.25) }, -- PTRD bipod
	["b6d96e7c-80ad-4838-b9fb-364c8205c23a"] = { uuid = sm.uuid.new("d7a0fd34-6a9c-4be8-be10-4e7016e05861"), scale = sm.vec3.new(0.25, 10.25, 0.25) }, -- PTRD
}

function ExplGun:client_onShoot(data)
	if not BetterExists(self.shape) then
		print("Couldn't spawn explosive projectile")
		return
	end

	local v_shellEffect = sm.effect.createEffect(data.effect)
	local v_offsetPos = self.shape.worldPosition + self.shape.worldRotation * data.effectOffset --[[@as Vec3]]
	
	local v_projEffData = g_cannonEffects[tostring(self.shape.uuid)]
	if v_projEffData then
		v_shellEffect:setParameter("uuid", v_projEffData.uuid)
		v_shellEffect:setScale(v_projEffData.scale)

		v_offsetPos = v_offsetPos + (data.dir:normalize() * (v_projEffData.scale.y * 0.25)) --[[@as Vec3]]
	end
	
	v_shellEffect:setPosition(v_offsetPos)
	v_shellEffect:start()

	local _Bullet = {
		effect = v_shellEffect,
		pos = v_offsetPos,
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

	AnimUtil_SetAnimation(self, "shoot")
end

function ExplGun:client_onDestroy()
	AnimUtil_DestroyEffects(self)

	for k, bullet in pairs(self.projectiles) do
		if bullet and BetterExists(bullet.effect) then
			bullet.effect:setPosition(sm.vec3.new(0, 0, 10000))
			bullet.effect:stop()
			bullet.effect:destroy()
		end

		self.projectiles[k] = nil
	end
end