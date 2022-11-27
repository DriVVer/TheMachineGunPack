--[[
	Copyright (c) 2022 Questionable Mark
]]

--if VGun then return end

dofile("Databases/GunDatabase.lua")
dofile("Utils/AnimationUtil.lua")
dofile("Utils/BoneTracker.lua")

---@class VGun : ShapeClass
---@field sv_anim_wait boolean
VGun = class()
VGun.maxParentCount = 1
VGun.maxChildCount = 0
VGun.connectionInput = sm.interactable.connectionType.logic
VGun.connectionOutput = sm.interactable.connectionType.none
VGun.colorNormal = sm.color.new(0xcb0a00ff)
VGun.colorHighlight = sm.color.new(0xee0a00ff)
VGun.poseWeightCount = 3

function VGun:client_onCreate()
	AnimUtil_InitializeAnimationUtil(self)

	local _data = DatabaseLoader.getClientSettings(self.shape.uuid)
	self.debris_settings = _data.debris

	if not self.sv_server_host then
		self.network:sendToServer("server_requestAnimData")
	end

	BoneTracker_Initialize(self, _data.bone_tracker)
end

function VGun:server_onCreate()
	local _data = DatabaseLoader.getServerSettings(self.shape.uuid)
	self.cannon_settings = _data.cannon

	self.cannon_ammo = self.cannon_settings.magazine_capacity

	self.sv_server_host = true
end

function VGun:server_requestAnimData(data, player)
	AnimUtil_SendAnimationData(self, player)
end

function VGun:client_receiveAnimData(data)
	AnimUtil_ReceiveAnimationData(self, data)
end

function VGun:server_onFixedUpdate(dt)
	if not sm.exists(self.interactable) then return end

	AnimUtil_server_performDataCheck(self, "client_onShoot")

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
			local v_projDamage = sCannonSet.proj_damage or 10
			sm.projectile.shapeProjectileAttack(sCannonSet.projectile, v_projDamage, sCannonSet.projectile_offset, _Direction, self.shape)

			sm.physics.applyImpulse(self.shape, sCannonSet.recoil)
		end
	else
		local _AutoReload = (not sCannonSet.auto_reload and active)
		self.reload = (self.reload > 1 and self.reload - 1) or (_AutoReload and 1) or nil
	end
end

function VGun:client_onUpdate(dt)
	AnimUtil_UpdateAnimations(self, dt)
	self.cl_dt = dt

	self.interactable:setSubMeshVisible("1", false)
end

local v_deb_color = sm.color.new(0xffffffff)
local v_deb_rotation = sm.quat.identity()
function VGun:client_onShoot(anim_state)
	AnimUtil_SetAnimation(self, anim_state)

	local v_deb_set = self.debris_settings
	if v_deb_set then
		local s_shape = self.shape
		local v_position = s_shape.worldPosition + s_shape.worldRotation * v_deb_set.position
		local v_final_pos = v_position + (s_shape.velocity * self.cl_dt) * 1.9

		local v_dir = sm.noise.gunSpread(s_shape.worldRotation * v_deb_set.direction, v_deb_set.spread) * v_deb_set.velocity
		local v_deb_lifetime = math.random(2, 10)
		local v_ang_velocity = sm.vec3.new(
			math.random(1, 500) / 10,
			math.random(1, 500) / 10,
			math.random(1, 500) / 10
		)

		sm.debris.createDebris(v_deb_set.uuid, v_final_pos, v_deb_rotation, v_dir + s_shape.velocity, v_ang_velocity, v_deb_color, v_deb_lifetime)
	end
end

function VGun:client_onDestroy()
	AnimUtil_DestroyEffects(self)
end