local g_ptrdProjectiles = {}
local g_ptrdActiveInstances = 0
local g_ptrdServerTick = 0
local g_ptrdClientTick = 0
local g_projectile_noconsume = sm.uuid.new("6c87e1c0-79a6-40dc-a26a-ef28916aff69")

local g_projectileDamage = 480
local g_projectileVelocity = 120
local g_maxPenetrationCount = 4
local g_killTypes = {
	terrainSurface = true,
	terrainAsset = true,
	limiter = true
}

function PTRDProjectile_clientInitialize()
	g_ptrdActiveInstances = g_ptrdActiveInstances + 1
	print("Active instances", g_ptrdActiveInstances)
end

local function PTRDProjectile_UpdateProjectileRotation(proj)
	proj[3]:setPosition(proj[1])

	if proj[2]:length() > 0.001 then
		proj[3]:setRotation(sm.vec3.getRotation(sm.vec3.new(0, 0, -1), proj[2]))
	end
end

local function calculateRightVector(vector)
	local yaw = math.atan2(vector.y, vector.x) - math.pi / 2
	return sm.vec3.new(math.cos(yaw), math.sin(yaw), 0)
end

local liquids = { water = true, chemical = true, oil = true }
local function IsLiquid(trigger)
	if not trigger or not sm.exists(trigger) then return false end

    local userdata = trigger:getUserData()
    if not userdata then return false end

    for k, v in pairs(userdata) do
        if liquids[k] == true and v == true then
            return true
        end
    end

    return false
end

---@param self PTRD
function PTRDProjectile_clientSpawnProjectile(self, dir, is_local)
	local s_tool = self.tool

	local v_proj_pos = nil
	if is_local and s_tool:isLocal() and s_tool:isInFirstPersonView() then
		v_proj_pos = s_tool:getFpBonePos("pejnt_barrel")

		local v_char_dir = s_tool:getOwner():getCharacter():getDirection()
		v_proj_pos = v_proj_pos + calculateRightVector(v_char_dir) * 0.1
	else
		v_proj_pos = s_tool:getTpBonePos("pejnt_barrel")
	end

	v_proj_pos = v_proj_pos + dir
	local v_proj_velocity = dir * g_projectileVelocity

	local v_proj_effect = sm.effect.createEffect("ShapeRenderable")
	v_proj_effect:setParameter("uuid", sm.uuid.new("d80e4edd-8823-42f6-9f17-1dc130ba51ce"))
	v_proj_effect:setScale(sm.vec3.one() * 0.25)

	local v_new_projectile =
	{
		[1] = v_proj_pos,
		[2] = v_proj_velocity,
		[3] = v_proj_effect,
		[4] = 10,               --projectile lifetime
		[5] = s_tool:getOwner(),
		[6] = g_maxPenetrationCount
	}

	g_ptrdProjectiles[#g_ptrdProjectiles + 1] = v_new_projectile
	PTRDProjectile_UpdateProjectileRotation(v_new_projectile)

	v_proj_effect:start()
end

local function PTRDProjectile_serverOnHit(proj_data)
	local hit = proj_data[7]
	local target = hit.target
	local hitPos = hit.pos

	print("hit", target)
	local _type = type(target)
	if _type == "Shape" then
		local effectRot = sm.vec3.getRotation( sm.vec3.new(0,0,1), hit.normal )
		local effectData = { Material = target.materialId, Color = target.color }

		if sm.item.isBlock(target.uuid) then
			target:destroyBlock(target:getClosestBlockLocalPosition(hitPos))
		else
			target:destroyShape()
		end

		sm.effect.playEffect( "Sledgehammer - Destroy", hitPos, sm.vec3.zero(), effectRot, sm.vec3.one(), effectData )

	elseif _type == "Character" then
		sm.projectile.projectileAttack(
			g_projectile_noconsume,
			g_projectileDamage,
			hitPos,
			(target.worldPosition - hitPos):normalize(),
			proj_data[5]
		)

		--sm.effect.playEffect("PotatoProjectile - Hit", hit.pos, sm.vec3.zero(), sm.vec3.getRotation(sm.vec3.new(0,0,1), hit.normal))
	end
end

function PTRDProjectile_serverOnFixedUpdate(dt)
	local v_newTick = sm.game.getCurrentTick()
	if g_ptrdServerTick ~= v_newTick then
		g_ptrdServerTick = v_newTick

		--Update the projectiles in here
		for k, proj in pairs(g_ptrdProjectiles) do
			if proj[7] then
				PTRDProjectile_serverOnHit(proj)
				proj[7] = nil
			end
		end
	end
end

function PTRDProjectile_clientOnFixedUpdate(dt)
	local v_newTick = sm.game.getCurrentTick()
	if g_ptrdClientTick ~= v_newTick then
		g_ptrdClientTick = v_newTick

		for k, proj in pairs(g_ptrdProjectiles) do
			if proj[6] <= 0 then
				g_ptrdProjectiles[k] = nil
				print"blehh ded"
			else
				proj[4] = proj[4] - dt

				local v_pos = proj[1]

				proj[2] = proj[2] * 0.997 - sm.vec3.new(0, 0, 10 * dt)
				local v_dir = proj[2]

				local hit, result = sm.physics.raycast(v_pos, v_pos + v_dir * dt * 1.2, nil, -1)
				local v_lifetime_over = (proj[4] <= 0)
				if hit or (proj[4] <= 0) then
					local hitPos = result.pointWorld
					proj[1] = (v_lifetime_over and proj[1] or hitPos)

					local _type = result.type
					if _type == "areaTrigger" and IsLiquid(result:getAreaTrigger()) then
						sm.effect.playEffect( "Projectile - HitWater", hitPos )
					else
						proj[7] = hit and {
							normal = result.normalWorld,
							pos = hitPos,
							target = result:getShape() or result:getCharacter()
						} or nil

						proj[6] = g_killTypes[_type] == true and 0 or proj[6] - 1
						if proj[6] <= 0 then
							local v_cur_proj = proj[3]
							v_cur_proj:setPosition(sm.vec3.new(0, 0, 10000))
							v_cur_proj:stop()
						end
					end
				else
					proj[1] = v_pos + v_dir * dt
					PTRDProjectile_UpdateProjectileRotation(proj)
				end
			end
		end
	end
end

function PTRDProjectile_clientDestroy()
	if g_ptrdActiveInstances > 0 then
		g_ptrdActiveInstances = g_ptrdActiveInstances - 1
		if g_ptrdActiveInstances == 0 then
			for k, proj in pairs(g_ptrdProjectiles) do
				if proj then
					local v_proj_eff = proj[3]

					if v_proj_eff ~= nil and sm.exists(v_proj_eff) then
						v_proj_eff:stopImmediate()
						v_proj_eff:destroy()
					end
				end
			end

			g_ptrdProjectiles = {}
		end
	end
end