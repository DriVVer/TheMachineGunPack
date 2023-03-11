dofile("ExplosionUtil.lua")

local g_bazookaProjectiles = {}
local g_bazookaActiveInstances = 0
local g_bazookaServerTick = 0
local g_bazookaClientTick = 0

function BazookaProjectile_clientInitialize()
	g_bazookaActiveInstances = g_bazookaActiveInstances + 1
	print("Active instances", g_bazookaActiveInstances)
end

local function BazookaProjectile_UpdateProjectileRotation(proj)
	proj[3]:setPosition(proj[1])

	if proj[2]:length() > 0.001 then
		proj[3]:setRotation(sm.vec3.getRotation(sm.vec3.new(0, 0, -1), proj[2]))
	end
end

local function calculateRightVector(vector)
	local yaw = math.atan2(vector.y, vector.x) - math.pi / 2
	return sm.vec3.new(math.cos(yaw), math.sin(yaw), 0)
end

---@param self Bazooka
function BazookaProjectile_clientSpawnProjectile(self, data, is_local)
	local s_tool = self.tool

	local v_proj_pos = nil
	if is_local and s_tool:isLocal() and s_tool:isInFirstPersonView() then
		v_proj_pos = s_tool:getFpBonePos("pejnt_barrel")

		local v_char_dir = s_tool:getOwner():getCharacter():getDirection()
		v_proj_pos = v_proj_pos + calculateRightVector(v_char_dir) * 0.1
	else
		v_proj_pos = s_tool:getTpBonePos("pejnt_barrel")
	end

	local v_proj_direction = (data[1] - v_proj_pos):normalize()
	v_proj_pos = v_proj_pos + v_proj_direction
	local v_proj_velocity = v_proj_direction * data[2]

	local v_proj_effect = sm.effect.createEffect("Bazooka - Projectile")
	v_proj_effect:setScale(sm.vec3.new(0.5, 0.5, 0.5))

	local v_new_projectile =
	{
		[1] = v_proj_pos,
		[2] = v_proj_velocity,
		[3] = v_proj_effect,
		[4] = 10,               --projectile lifetime
		[5] = s_tool:getOwner()
	}

	g_bazookaProjectiles[#g_bazookaProjectiles + 1] = v_new_projectile
	BazookaProjectile_UpdateProjectileRotation(v_new_projectile)

	v_proj_effect:start()
end

local g_bazooka_sharpnel = sm.uuid.new("9a151748-e5fa-4029-9a72-1d3264874b73")
local function BazookaProjectile_serverCreateExplosion(proj_data)
	local v_shape = proj_data[7] --[[@as Shape]]
	if v_shape ~= nil and sm.exists(v_shape) then
		local v_quality = sm.item.getQualityLevel(v_shape.uuid)
		if v_quality <= 6 then
			local v_proj_owner = proj_data[5]
			if v_proj_owner and sm.exists(v_proj_owner) then
				local v_spawn_dir = proj_data[2]
				local v_spawn_pos = proj_data[1] + v_spawn_dir:normalize() * 0.25 --[[@as Vec3]]

				mgp_better_explosion(proj_data[1], 7, 0.3, 5, 10, "PropaneTank - ExplosionSmall")

				for i = 1, math.random(5, 40) do
					local v_dir = sm.noise.gunSpread(v_spawn_dir, 80)
					local v_proj_delay = math.random(0, 8)

					sm.projectile.projectileAttack(g_bazooka_sharpnel, 50, v_spawn_pos, v_dir, v_proj_owner, nil, nil, v_proj_delay)
				end

				return
			end
		end

		local v_is_part = sm.item.isPart(v_shape.uuid)
		local v_is_shape = sm.item.isBlock(v_shape.uuid)

		if v_is_part or v_is_shape then
			sm.effect.playEffect("PropaneTank - ExplosionSmall", proj_data[1])
		end

		if v_is_part then
			v_shape:destroyShape()
			return
		elseif v_is_shape then
			local v_local_pos = v_shape:getClosestBlockLocalPosition(proj_data[1])
			v_shape:destroyBlock(v_local_pos, sm.vec3.one())
			return
		end
	end

	mgp_better_explosion(proj_data[1], 7, 0.3, 5, 1, "PropaneTank - ExplosionSmall")
end

function BazookaProjectile_serverOnFixedUpdate(dt)
	local v_newTick = sm.game.getCurrentTick()
	if g_bazookaServerTick ~= v_newTick then
		g_bazookaServerTick = v_newTick

		--Update the projectiles in here
		for k, proj in pairs(g_bazookaProjectiles) do
			if proj[6] == true then
				BazookaProjectile_serverCreateExplosion(proj)
			end
		end
	end
end

function BazookaProjectile_clientOnFixedUpdate(dt)
	local v_newTick = sm.game.getCurrentTick()
	if g_bazookaClientTick ~= v_newTick then
		g_bazookaClientTick = v_newTick

		for k, proj in pairs(g_bazookaProjectiles) do
			if proj[6] == true then
				g_bazookaProjectiles[k] = nil
			else
				proj[4] = proj[4] - dt

				local v_pos = proj[1]

				proj[2] = proj[2] * 0.997 - sm.vec3.new(0, 0, 10 * dt)
				local v_dir = proj[2]

				local hit, result = sm.physics.raycast(v_pos, v_pos + v_dir * dt * 1.2)
				local v_lifetime_over = (proj[4] <= 0)
				if hit or (proj[4] <= 0) then
					proj[1] = (v_lifetime_over and proj[1] or result.pointWorld)

					proj[6] = true
					if result.type == "body" then
						proj[7] = result:getShape()
					end

					local v_cur_proj = proj[3]
					v_cur_proj:setPosition(sm.vec3.new(0, 0, 10000))
					v_cur_proj:stop()
				else
					proj[1] = v_pos + v_dir * dt
					BazookaProjectile_UpdateProjectileRotation(proj)
				end
			end
		end
	end
end

function BazookaProjectile_clientDestroy()
	if g_bazookaActiveInstances > 0 then
		g_bazookaActiveInstances = g_bazookaActiveInstances - 1
		if g_bazookaActiveInstances == 0 then
			for k, proj in pairs(g_bazookaProjectiles) do
				if proj then
					local v_proj_eff = proj[3]
					
					if v_proj_eff ~= nil and sm.exists(v_proj_eff) then
						v_proj_eff:stopImmediate()
						v_proj_eff:destroy()
					end
				end
			end

			g_bazookaProjectiles = {}
		end
	end
end