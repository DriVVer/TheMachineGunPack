---@type ShapeClass
Grenade = class()

function Grenade:server_onCreate()
	local s_inter = self.interactable
	if s_inter then
		local inter_data = s_inter.publicData
		if inter_data then
			self.timer = inter_data.timer
			self.expl_lvl = inter_data.expl_lvl
			self.expl_rad = inter_data.expl_rad
			self.expl_effect = inter_data.expl_effect
			self.shrapnel_data = inter_data.shrapnel_data
		end
	end
	if self.interactable and self.interactable.publicData then
		self.timer = self.interactable.publicData.timer
		self.explosion_level = self.interactable
	end
end

function Grenade:server_onProjectile()
	self.timer = 0
end

function Grenade:server_onCollision(object, position)
	if type(object) ~= "Shape" or not sm.exists(object) then
		return
	end

	local obj_uuid = object.uuid
	if sm.item.isBlock(obj_uuid) and sm.item.getQualityLevel(obj_uuid) == 1 then
		local loc_pos = object:getClosestBlockLocalPosition(position)
		object:destroyBlock(loc_pos, sm.vec3.new(3, 3, 3), 1)

		sm.effect.playEffect("Sledgehammer - Destroy", position, sm.vec3.zero(), sm.quat.identity(), sm.vec3.one(), { Material = object:getMaterialId() })
	end
end

function Grenade:server_onMelee()
	self.timer = 0
end

local _math_random = math.random
local _vec3_new = sm.vec3.new
local _sm_noise_gunSpread = sm.noise.gunSpread
local _sm_projectile_shapeProjectileAttack = sm.projectile.shapeProjectileAttack
function Grenade:server_onFixedUpdate(dt)
	if self.timer then
		self.timer = self.timer - dt

		if self.timer <= 0.0 then
			local shr_data = self.shrapnel_data
			if shr_data ~= nil then
				local sharpnel_pos = sm.vec3.zero()
				local sharpnel_count = _math_random(shr_data.min_count, shr_data.max_count)

				local shrapnel_min_speed = shr_data.min_speed
				local shrapnel_max_speed = shr_data.max_speed

				local shrapnel_min_damage = shr_data.min_damage
				local shrapnel_max_damage = shr_data.max_damage

				local shrapnel_projectile_uuid = shr_data.proj_uuid

				for i = 1, sharpnel_count do
					local s_speed = _math_random(shrapnel_min_speed, shrapnel_max_speed)
					local s_damage = _math_random(shrapnel_min_damage, shrapnel_max_damage)

					local shoot_dir = _vec3_new(_math_random(0, 100) / 100, _math_random(0, 100) / 100, _math_random(0, 100) / 100):normalize()
					local dir = _sm_noise_gunSpread(shoot_dir, 360) * s_speed

					_sm_projectile_shapeProjectileAttack(shrapnel_projectile_uuid, s_damage, sharpnel_pos, dir, self.shape)
				end
			end

			sm.physics.explode(self.shape.worldPosition, self.expl_lvl, self.expl_rad, 5, 4, "PropaneTank - ExplosionSmall", self.shape)
			self.shape:destroyShape(0)

			self.timer = nil
		end
	end
end