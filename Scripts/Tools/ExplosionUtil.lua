local g_explosion_mask = sm.physics.filter.staticBody + sm.physics.filter.joints +
	sm.physics.filter.terrainAsset + sm.physics.filter.character +
	sm.physics.filter.harvestable + sm.physics.filter.areaTrigger +
	sm.physics.filter.voxelTerrain + sm.physics.filter.dynamicBody

---@param player Player
---@param expl_damage number
---@param expl_radius number
---@param expl_position Vec3
function mgp_explosion_damage_player(player, expl_radius, expl_damage, expl_position, exception)
	local v_pl_char = player.character
	if not (v_pl_char and sm.exists(v_pl_char)) then
		return
	end

	local distance_to_explosion = (v_pl_char.worldPosition - expl_position):length()
	if distance_to_explosion >= expl_radius then
		return
	end

	local hit, result = sm.physics.raycast(expl_position, v_pl_char.worldPosition, exception, g_explosion_mask)
	if not (hit and result.type == "character") then
		return
	end

	local v_char = result:getCharacter()
	if v_char ~= v_pl_char then
		return
	end

	local explosion_damage = math.floor((1 - (distance_to_explosion / expl_radius)) * expl_damage)
	sm.event.sendToPlayer(player, "sv_e_receiveDamage", { damage = explosion_damage })
end

---@param unit Unit
---@param expl_radius number
---@param expl_damage number
---@param expl_position Vec3
function mgp_explosion_damage_unit(unit, expl_radius, expl_damage, expl_position)
	local v_unit_char = unit.character
	if not (v_unit_char and sm.exists(v_unit_char)) then
		return
	end

	local distance_to_explosion = (v_unit_char.worldPosition - expl_position):length()
	if distance_to_explosion >= expl_radius then
		return
	end

	local hit, result = sm.physics.raycast(expl_position, v_unit_char.worldPosition, nil, g_explosion_mask)
	if not (hit and result.type == "character") then
		return
	end

	local v_char = result:getCharacter()
	if v_char ~= v_unit_char then
		return
	end

	local explosion_damage = math.floor((1 - (distance_to_explosion / expl_radius)) * expl_damage)
	sm.event.sendToUnit(unit, "sv_takeDamage", explosion_damage)
	print("test", explosion_damage)
end

function mgp_apply_damage_in_sphere(position, radius, player_damage, unit_damage)
	for k, player in pairs(sm.player.getAllPlayers()) do
		mgp_explosion_damage_player(player, radius, player_damage, position)
	end

	for k, unit in pairs(sm.unit.getAllUnits()) do
		mgp_explosion_damage_unit(unit, radius, unit_damage, position)
	end
end

function mgp_apply_damage_in_sphere_exc(position, radius, player_damage, unit_damage, player_exception)
	for k, player in pairs(sm.player.getAllPlayers()) do
		if player ~= player_exception then
			mgp_explosion_damage_player(player, radius, player_damage, position, player_exception)
		end
	end

	for k, unit in pairs(sm.unit.getAllUnits()) do
		mgp_explosion_damage_unit(unit, radius, unit_damage, position)
	end
end

function mgp_better_explosion(position, lvl, rad, impRad, impStr, eff, ignore_shape)
	mgp_apply_damage_in_sphere(position, impRad, 100, 200)
	sm.physics.explode(position, lvl, rad, impRad, impStr, eff, ignore_shape)
end

function mgp_better_explosion_exc(position, lvl, rad, impRad, impStr, eff, ignore_shape, ignore_player)
	mgp_apply_damage_in_sphere_exc(position, impRad, 100, 200, ignore_player)
	sm.physics.explode(position, lvl, rad, impRad, impStr, eff, ignore_shape)
end