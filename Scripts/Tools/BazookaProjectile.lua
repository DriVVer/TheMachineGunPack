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

---@param self Bazooka
function BazookaProjectile_clientSpawnProjectile(self, data, is_local)
	local s_tool = self.tool

	local v_proj_pos = nil
	if is_local and s_tool:isLocal() and s_tool:isInFirstPersonView() then
		v_proj_pos = s_tool:getFpBonePos("pejnt_barrel")
	else
		v_proj_pos = s_tool:getTpBonePos("pejnt_barrel")
	end

	local v_proj_direction = (data[1] - v_proj_pos):normalize()
	v_proj_pos = v_proj_pos + v_proj_direction
	local v_proj_velocity = v_proj_direction * data[2]

	local v_proj_effect = sm.effect.createEffect("Bazooka - Projectile")

	local v_new_projectile =
	{
		[1] = v_proj_pos,
		[2] = v_proj_velocity,
		[3] = v_proj_effect,
		[4] = 10               --projectile lifetime
	}

	g_bazookaProjectiles[#g_bazookaProjectiles + 1] = v_new_projectile
	BazookaProjectile_UpdateProjectileRotation(v_new_projectile)

	v_proj_effect:start()
end

function BazookaProjectile_serverOnFixedUpdate(dt)
	local v_newTick = sm.game.getCurrentTick()
	if g_bazookaServerTick ~= v_newTick then
		g_bazookaServerTick = v_newTick

		--Update the projectiles in here
		for k, proj in pairs(g_bazookaProjectiles) do
			if proj[5] == true then
				sm.physics.explode(proj[1], 10, 1, 10, 100, "PropaneTank - ExplosionSmall")
			end
		end
	end
end

function BazookaProjectile_clientOnFixedUpdate(dt)
	local v_newTick = sm.game.getCurrentTick()
	if g_bazookaClientTick ~= v_newTick then
		g_bazookaClientTick = v_newTick

		for k, proj in pairs(g_bazookaProjectiles) do
			if proj[5] == true then
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

					proj[5] = true
					proj[3]:stopImmediate()
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