dofile( "$GAME_DATA/Scripts/game/AnimationUtil.lua" )
dofile( "$SURVIVAL_DATA/Scripts/util.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/survival_shapes.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/survival_projectiles.lua" )

---@class HandheldGrenadeBase : ToolClass
---@field fpAnimations table
---@field tpAnimations table
---@field aiming boolean
---@field aimFireMode table
---@field normalFireMode table
---@field blendTime integer
---@field aimBlendSpeed integer
---@field mgp_tool_config table
---@field mgp_renderables_tp table
---@field mgp_renderables_fp table
---@field mgp_renderables table
HandheldGrenadeBase = class()

function HandheldGrenadeBase:client_onCreate()
	self.grenade_active = false
end

function HandheldGrenadeBase:client_onRefresh()
	self:loadAnimations()
end

function HandheldGrenadeBase.loadAnimations( self )

	self.tpAnimations = createTpAnimations(
		self.tool,
		{
			shoot = { "glowstick_use", { crouch = "glowstick_crouch_idle" } },
			aim = { "glowstick_idle", { crouch = "glowstick_crouch_idle" } },
			aimShoot = { "glowstick_use", { crouch = "glowstick_crouch_idle" } },
			idle = { "glowstick_use" },
			pickup = { "glowstick_pickup", { nextAnimation = "idle" } },
			putdown = { "glowstick_putdown" }
		}
	)
	local movementAnimations = {
		idle = "glowstick_idle",
		idleRelaxed = "glowstick_idle",

		sprint = "glowstick_sprint",
		runFwd = "glowstick_run_fwd",
		runBwd = "glowstick_run_bwd",

		jump = "glowstick_jump",
		jumpUp = "glowstick_jump_up",
		jumpDown = "glowstick_jump_down",

		land = "glowstick_idle",
		landFwd = "glowstick_idle",
		landBwd = "glowstick_idle",

		crouchIdle = "glowstick_crouch_idle",
		crouchFwd = "glowstick_crouch_fwd",
		crouchBwd = "glowstick_crouch_bwd"
	}

	for name, animation in pairs( movementAnimations ) do
		self.tool:setMovementAnimation( name, animation )
	end

	setTpAnimation( self.tpAnimations, "idle", 5.0 )

	if self.tool:isLocal() then
		self.fpAnimations = createFpAnimations(
			self.tool,
			{
				equip = { "glowstick_pickup", { nextAnimation = "idle" } },
				unequip = { "glowstick_putdown" },

				idle = { "glowstick_idle", { looping = true } },
				shoot = { "glowstick_throw", { nextAnimation = "idle" } },

				activate = { "glowstick_activ", { nextAnimation = "idle" } },

				aimInto = { "glowstick_aim_into", { nextAnimation = "aimIdle" } },
				aimExit = { "glowstick_aim_exit", { nextAnimation = "idle", blendNext = 0 } },
				aimIdle = { "glowstick_aim_idle", { looping = true } },
				aimShoot = { "glowstick_aim_shoot", { nextAnimation = "aimIdle"} },

				sprintInto = { "glowstick_sprint_into", { nextAnimation = "sprintIdle",  blendNext = 0.2 } },
				sprintExit = { "glowstick_sprint_exit", { nextAnimation = "idle",  blendNext = 0 } },
				sprintIdle = { "glowstick_sprint_idle", { looping = true } }
			}
		)
	end

	self.normalFireMode = {
		fireCooldown = 0.20,
		spreadCooldown = 0.18,
		spreadIncrement = 2.6,
		spreadMinAngle = 40.25,
		spreadMaxAngle = 90,
		fireVelocity = 80.0,

		minDispersionStanding = 0.1,
		minDispersionCrouching = 0.04,

		maxMovementDispersion = 0.4,
		jumpDispersionMultiplier = 2
	}

	self.aimFireMode = {
		fireCooldown = 0.20,
		spreadCooldown = 0.18,
		spreadIncrement = 1.3,
		spreadMinAngle = 0,
		spreadMaxAngle = 8,
		fireVelocity =  130.0,

		minDispersionStanding = 0.01,
		minDispersionCrouching = 0.01,

		maxMovementDispersion = 0.4,
		jumpDispersionMultiplier = 2
	}

	self.fireCooldownTimer = 0.0
	self.spreadCooldownTimer = 0.0

	self.movementDispersion = 0.0

	self.sprintCooldownTimer = 0.0
	self.sprintCooldown = 0.3

	self.aimBlendSpeed = 3.0
	self.blendTime = 0.2

	self.jointWeight = 0.0
	self.spineWeight = 0.0
	local cameraWeight, cameraFPWeight = self.tool:getCameraWeights()
	self.aimWeight = math.max( cameraWeight, cameraFPWeight )

end

local function calculateRightVector(vector)
	local yaw = math.atan2(vector.y, vector.x) - math.pi / 2
	return sm.vec3.new(math.cos(yaw), math.sin(yaw), 0)
end

local function calculateUpVector(vector)
	return calculateRightVector(vector):cross(vector)
end

function HandheldGrenadeBase.client_onUpdate( self, dt )

	-- First person animation
	local isSprinting =  self.tool:isSprinting()
	local isCrouching =  self.tool:isCrouching()

	if self.tool:isLocal() then
		if self.equipped then
			local fp_anims = self.fpAnimations

			if isSprinting and fp_anims.currentAnimation ~= "sprintInto" and fp_anims.currentAnimation ~= "sprintIdle" then
				swapFpAnimation( fp_anims, "sprintExit", "sprintInto", 0.0 )
			elseif not self.tool:isSprinting() and ( fp_anims.currentAnimation == "sprintIdle" or fp_anims.currentAnimation == "sprintInto" ) then
				swapFpAnimation( fp_anims, "sprintInto", "sprintExit", 0.0 )
			end

			local cur_anim = fp_anims.currentAnimation
			if cur_anim == "activate" then
				local cur_anim_info = fp_anims.animations[cur_anim]
				local anim_duration = cur_anim_info.info.duration
				local anim_time = cur_anim_info.time + dt

				if anim_time >= anim_duration then
					self.grenade_active = true
					self.network:sendToServer("sv_n_startGrenadeTimer")
				end
			end
		end
		updateFpAnimations( self.fpAnimations, self.equipped, dt )
	end

	if not self.equipped then
		if self.wantEquipped then
			self.wantEquipped = false
			self.equipped = true
		end
		return
	end

	if self.grenade_spawn_timer then
		self.grenade_spawn_timer = self.grenade_spawn_timer - dt

		if self.grenade_spawn_timer <= 0.0 then
			self.grenade_spawn_timer = nil

			self.network:sendToServer("sv_n_spawnGrenade")
		end
	end

	-- Timers
	self.fireCooldownTimer = math.max( self.fireCooldownTimer - dt, 0.0 )
	self.spreadCooldownTimer = math.max( self.spreadCooldownTimer - dt, 0.0 )
	self.sprintCooldownTimer = math.max( self.sprintCooldownTimer - dt, 0.0 )


	if self.tool:isLocal() then
		local dispersion = 0.0
		local fireMode = self.normalFireMode
		local recoilDispersion = 1.0 - ( math.max( fireMode.minDispersionCrouching, fireMode.minDispersionStanding ) + fireMode.maxMovementDispersion )

		if isCrouching then
			dispersion = fireMode.minDispersionCrouching
		else
			dispersion = fireMode.minDispersionStanding
		end

		if self.tool:getRelativeMoveDirection():length() > 0 then
			dispersion = dispersion + fireMode.maxMovementDispersion * self.tool:getMovementSpeedFraction()
		end

		if not self.tool:isOnGround() then
			dispersion = dispersion * fireMode.jumpDispersionMultiplier
		end

		self.movementDispersion = dispersion

		self.spreadCooldownTimer = clamp( self.spreadCooldownTimer, 0.0, fireMode.spreadCooldown )
		local spreadFactor = fireMode.spreadCooldown > 0.0 and clamp( self.spreadCooldownTimer / fireMode.spreadCooldown, 0.0, 1.0 ) or 0.0

		self.tool:setDispersionFraction( clamp( self.movementDispersion + spreadFactor * recoilDispersion, 0.0, 1.0 ) )

		self.tool:setCrossHairAlpha( 1.0 )
		self.tool:setInteractionTextSuppressed( false )
	end

	-- Sprint block
	self.tool:setBlockSprint( self.sprintCooldownTimer > 0.0 or self:cl_shouldBlockSprint() )

	local playerDir = self.tool:getSmoothDirection()
	local angle = math.asin( playerDir:dot( sm.vec3.new( 0, 0, 1 ) ) ) / ( math.pi / 2 )

	down = clamp( -angle, 0.0, 1.0 )
	fwd = ( 1.0 - math.abs( angle ) )
	up = clamp( angle, 0.0, 1.0 )

	local crouchWeight = self.tool:isCrouching() and 1.0 or 0.0
	local normalWeight = 1.0 - crouchWeight

	local totalWeight = 0.0
	for name, animation in pairs( self.tpAnimations.animations ) do
		animation.time = animation.time + dt

		if name == self.tpAnimations.currentAnimation then
			animation.weight = math.min( animation.weight + ( self.tpAnimations.blendSpeed * dt ), 1.0 )

			if animation.time >= animation.info.duration - self.blendTime then
				if ( name == "shoot" or name == "aimShoot" ) then
					setTpAnimation( self.tpAnimations, self.aiming and "aim" or "idle", 10.0 )
				elseif name == "pickup" then
					setTpAnimation( self.tpAnimations, self.aiming and "aim" or "idle", 0.001 )
				elseif animation.nextAnimation ~= "" then
					setTpAnimation( self.tpAnimations, animation.nextAnimation, 0.001 )
				end
			end
		else
			animation.weight = math.max( animation.weight - ( self.tpAnimations.blendSpeed * dt ), 0.0 )
		end

		totalWeight = totalWeight + animation.weight
	end

	totalWeight = totalWeight == 0 and 1.0 or totalWeight
	for name, animation in pairs( self.tpAnimations.animations ) do
		local weight = animation.weight / totalWeight
		if name == "idle" then
			self.tool:updateMovementAnimation( animation.time, weight )
		elseif animation.crouch then
			self.tool:updateAnimation( animation.info.name, animation.time, weight * normalWeight )
			self.tool:updateAnimation( animation.crouch.name, animation.time, weight * crouchWeight )
		else
			self.tool:updateAnimation( animation.info.name, animation.time, weight )
		end
	end

	-- Third Person joint lock
	local relativeMoveDirection = self.tool:getRelativeMoveDirection()
	if ( ( ( isAnyOf( self.tpAnimations.currentAnimation, { "aimInto", "aim", "shoot" } ) and ( relativeMoveDirection:length() > 0 or isCrouching) ) or ( self.aiming and ( relativeMoveDirection:length() > 0 or isCrouching) ) ) and not isSprinting ) then
		self.jointWeight = math.min( self.jointWeight + ( 10.0 * dt ), 1.0 )
	else
		self.jointWeight = math.max( self.jointWeight - ( 6.0 * dt ), 0.0 )
	end

	if ( not isSprinting ) then
		self.spineWeight = math.min( self.spineWeight + ( 10.0 * dt ), 1.0 )
	else
		self.spineWeight = math.max( self.spineWeight - ( 10.0 * dt ), 0.0 )
	end

	local finalAngle = ( 0.5 + angle * 0.5 )
	self.tool:updateAnimation( "spudgun_spine_bend", finalAngle, self.spineWeight )

	local totalOffsetZ = lerp( -22.0, -26.0, crouchWeight )
	local totalOffsetY = lerp( 6.0, 12.0, crouchWeight )
	local crouchTotalOffsetX = clamp( ( angle * 60.0 ) -15.0, -60.0, 40.0 )
	local normalTotalOffsetX = clamp( ( angle * 50.0 ), -45.0, 50.0 )
	local totalOffsetX = lerp( normalTotalOffsetX, crouchTotalOffsetX , crouchWeight )

	local finalJointWeight = ( self.jointWeight )


	self.tool:updateJoint( "jnt_hips", sm.vec3.new( totalOffsetX, totalOffsetY, totalOffsetZ ), 0.35 * finalJointWeight * ( normalWeight ) )

	local crouchSpineWeight = ( 0.35 / 3 ) * crouchWeight

	self.tool:updateJoint( "jnt_spine1", sm.vec3.new( totalOffsetX, totalOffsetY, totalOffsetZ ), ( 0.10 + crouchSpineWeight )  * finalJointWeight )
	self.tool:updateJoint( "jnt_spine2", sm.vec3.new( totalOffsetX, totalOffsetY, totalOffsetZ ), ( 0.10 + crouchSpineWeight ) * finalJointWeight )
	self.tool:updateJoint( "jnt_spine3", sm.vec3.new( totalOffsetX, totalOffsetY, totalOffsetZ ), ( 0.45 + crouchSpineWeight ) * finalJointWeight )
	self.tool:updateJoint( "jnt_head", sm.vec3.new( totalOffsetX, totalOffsetY, totalOffsetZ ), 0.3 * finalJointWeight )
end

function HandheldGrenadeBase.client_onEquip( self, animate )

	if animate then
		sm.audio.play( "PotatoRifle - Equip", self.tool:getPosition() )
	end

	self.wantEquipped = true
	self.aiming = false
	local cameraWeight, cameraFPWeight = self.tool:getCameraWeights()
	self.aimWeight = math.max( cameraWeight, cameraFPWeight )
	self.jointWeight = 0.0

	currentRenderablesTp = {}
	currentRenderablesFp = {}

	for k,v in pairs( self.mgp_renderables_tp ) do currentRenderablesTp[#currentRenderablesTp+1] = v end
	for k,v in pairs( self.mgp_renderables_fp ) do currentRenderablesFp[#currentRenderablesFp+1] = v end
	for k,v in pairs( self.mgp_renderables ) do currentRenderablesTp[#currentRenderablesTp+1] = v end
	for k,v in pairs( self.mgp_renderables ) do currentRenderablesFp[#currentRenderablesFp+1] = v end

	local s_tool = self.tool
	s_tool:setTpRenderables(currentRenderablesTp)
	local is_tool_local = s_tool:isLocal()
	if is_tool_local then
		s_tool:setFpRenderables(currentRenderablesFp)
	end

	self:loadAnimations()

	setTpAnimation( self.tpAnimations, "pickup", 0.0001 )
	if is_tool_local then
		swapFpAnimation( self.fpAnimations, "unequip", "equip", 0.2 )
	end
end

function HandheldGrenadeBase.client_onUnequip( self, animate )
	self.wantEquipped = false
	self.equipped = false
	self.aiming = false
	self.grenade_active = false

	if sm.exists( self.tool ) then
		self.network:sendToServer("sv_n_unequipGrenade")

		if animate then
			sm.audio.play( "PotatoRifle - Unequip", self.tool:getPosition() )
		end
		setTpAnimation( self.tpAnimations, "putdown" )
		if self.tool:isLocal() then
			self.tool:setMovementSlowDown( false )
			self.tool:setBlockSprint( false )
			self.tool:setCrossHairAlpha( 1.0 )
			self.tool:setInteractionTextSuppressed( false )
			if self.fpAnimations.currentAnimation ~= "unequip" then
				swapFpAnimation( self.fpAnimations, "equip", "unequip", 0.2 )
			end
		end
	end
end

function HandheldGrenadeBase.sv_n_onAim( self, aiming )
	self.network:sendToClients( "cl_n_onAim", aiming )
end

function HandheldGrenadeBase.cl_n_onAim( self, aiming )
	if not self.tool:isLocal() and self.tool:isEquipped() then
		self:onAim( aiming )
	end
end

function HandheldGrenadeBase.onAim( self, aiming )
	self.aiming = aiming
	if self.tpAnimations.currentAnimation == "idle" or self.tpAnimations.currentAnimation == "aim" or self.tpAnimations.currentAnimation == "relax" and self.aiming then
		setTpAnimation( self.tpAnimations, self.aiming and "aim" or "idle", 5.0 )
	end
end

function HandheldGrenadeBase:onShoot()
	self.tpAnimations.animations.idle.time = 0
	self.tpAnimations.animations.shoot.time = 0
	self.tpAnimations.animations.aimShoot.time = 0

	setTpAnimation( self.tpAnimations, "shoot", 10.0 )
end

function HandheldGrenadeBase:cl_n_throwGrenade()
	if not self.tool:isLocal() and self.tool:isEquipped() then
		self:onShoot()
	end
end

local _math_random = math.random
local _sm_vec3_new = sm.vec3.new
local _sm_noise_gunSpread = sm.noise.gunSpread
function HandheldGrenadeBase:server_onFixedUpdate(dt)
	--self.sv_grenade_timer
	if self.sv_grenade_timer then
		self.sv_grenade_timer = self.sv_grenade_timer - dt
		print(self.sv_grenade_timer)

		if self.sv_grenade_timer <= 0.0 then
			self.sv_grenade_timer = nil

			local grenade_owner = self.tool:getOwner()
			if not grenade_owner then
				return
			end

			local owner_char = grenade_owner.character
			if not (owner_char and sm.exists(owner_char)) then
				return
			end

			local grenade_settings = self.mgp_tool_config.grenade_settings
			local shr_data = grenade_settings.shrapnel_data
			if shr_data ~= nil then
				local sharpnel_pos = owner_char.worldPosition
				local shrapenl_count = _math_random(shr_data.min_count, shr_data.max_count)

				local shrapnel_min_speed = shr_data.min_speed
				local shrapnel_max_speed = shr_data.max_speed

				local shrapnel_min_damage = shr_data.min_damage
				local shrapnel_max_damage = shr_data.max_damage

				local shrapnel_projectile_uuid = shr_data.proj_uuid

				for i = 1, shrapenl_count do
					local s_speed = _math_random(shrapnel_min_speed, shrapnel_max_speed)
					local s_damage = _math_random(shrapnel_min_damage, shrapnel_max_damage)

					local shoot_dir = _sm_vec3_new(_math_random(0, 100) / 100, _math_random(0, 100) / 100, _math_random(0, 100) / 100):normalize()
					local dir = _sm_noise_gunSpread(shoot_dir, 360) * s_speed

					sm.projectile.projectileAttack(shrapnel_projectile_uuid, s_damage, sharpnel_pos, dir, grenade_owner)
				end
			end

			sm.physics.explode(owner_char.worldPosition, grenade_settings.expl_lvl, grenade_settings.expl_rad, 5, 4, "PropaneTank - ExplosionSmall")
			sm.event.sendToPlayer(grenade_owner, "sv_e_receiveDamage", { damage = 1000 })
		end
	end
end

function HandheldGrenadeBase:sv_n_startGrenadeTimer()
	self.sv_grenade_timer = 10
end

function HandheldGrenadeBase:sv_n_throwGrenade()
	self.network:sendToClients("cl_n_throwGrenade")
end

function HandheldGrenadeBase:sv_createGrenadeObject(data, caller)
	if caller ~= nil or self.sv_grenade_timer == nil then
		return nil
	end

	local grenade_timer_saved = self.sv_grenade_timer
	self.sv_grenade_timer = nil

	local tool_config = self.mgp_tool_config
	local s_grenade = sm.shape.createPart(tool_config.grenade_uuid, data.pos, data.rot, true, true)
	
	local g_inter = s_grenade.interactable
	if g_inter then
		local g_settings_copy = {}
		for k, v in pairs(tool_config.grenade_settings) do
			g_settings_copy[k] = v
		end

		g_settings_copy.timer = grenade_timer_saved
		g_inter.publicData = g_settings_copy
	end

	return s_grenade
end

function HandheldGrenadeBase:sv_n_unequipGrenade(data, caller)
	local grenade_owner = self.tool:getOwner()
	if not grenade_owner then
		return
	end

	local owner_char = grenade_owner.character
	if not (owner_char and sm.exists(owner_char)) then
		return
	end

	self:sv_createGrenadeObject({ pos = owner_char.worldPosition, rot = sm.quat.identity() })
end

function HandheldGrenadeBase:sv_n_spawnGrenade()
	local grenade_owner = self.tool:getOwner()
	if not grenade_owner then
		return
	end

	local owner_char = grenade_owner.character
	if not (owner_char and sm.exists(owner_char)) then
		return
	end

	local char_dir = owner_char.direction
	local grenade_pos = owner_char.worldPosition + char_dir * 0.5
	local grenade_rotation = sm.vec3.getRotation(char_dir, sm.vec3.new(0, 0, 1))

	local s_grenade = self:sv_createGrenadeObject({ pos = grenade_pos, rot = grenade_rotation })
	if s_grenade then
		--Apply forward impulse
		sm.physics.applyImpulse(s_grenade, owner_char.direction * s_grenade:getMass() * 20, true)

		--Apply rotation
		sm.physics.applyImpulse(s_grenade, sm.vec3.new(0, 0, 30), false, sm.vec3.new(0, 0.1, 0))
		sm.physics.applyImpulse(s_grenade, sm.vec3.new(0, 0, -30), false, sm.vec3.new(0, -0.1, 0))
	end
end

local blocking_animations =
{
	["activate"] = true
}

function HandheldGrenadeBase:cl_shouldBlockSprint()
	if self.tool:isLocal() and self.equipped then
		return (blocking_animations[self.fpAnimations.currentAnimation] == true)
	end

	return false
end

function HandheldGrenadeBase:cl_onPrimaryUse(state)
	if self.tool:getOwner().character == nil then
		return
	end

	if self:cl_shouldBlockSprint() then
		print("BLOCKING INPUT")
		return
	end

	if self.fireCooldownTimer <= 0.0 and state == sm.tool.interactState.start then
		if self.grenade_active then
			self.fireCooldownTimer = 2.0
			self.grenade_active = false

			self.grenade_spawn_timer = 0.35

			self:onShoot()
			self.network:sendToServer("sv_n_throwGrenade")

			setFpAnimation(self.fpAnimations, "shoot", 0.0)
		else
			setFpAnimation(self.fpAnimations, "activate", 0.0)
		end
		--[[if self.grenade_active then
			self.fireCooldownTimer = 2.0
			self.grenade_active = false

			self.grenade_spawn_timer = 0.35

			self:onShoot()
			self.network:sendToServer("sv_n_throwGrenade")

			setFpAnimation(self.fpAnimations, "shoot", 0.0)
		else
			self.grenade_active = true
			setFpAnimation(self.fpAnimations, "activate", 0.0)
			
			self.network:sendToServer("sv_n_startGrenadeTimer")

			self.fireCooldownTimer = 2.4
		end]]
	end
end

function HandheldGrenadeBase.client_onReload()
	return true
end

function HandheldGrenadeBase.client_onEquippedUpdate( self, primaryState, secondaryState )
	if primaryState ~= self.prevPrimaryState then
		self:cl_onPrimaryUse( primaryState )
		self.prevPrimaryState = primaryState
	end

	return true, true
end

--Custom class definitions

---@type HandheldGrenadeBase
HandheldGrenade = class(HandheldGrenadeBase)

HandheldGrenade.mgp_renderables =
{
	"$CONTENT_DATA/Tools/Renderables/Grenade/s_grenade_base.rend"--,
	--"$CONTENT_DATA/Tools/Renderables/Grenade/s_grenade_screw.rend"
}

HandheldGrenade.mgp_renderables_tp =
{
	"$CONTENT_DATA/Tools/Renderables/Grenade/s_granade_tp_animlist.rend",
	"$CONTENT_DATA/Tools/Renderables/Grenade/s_grenade_tp_offset.rend"
}

HandheldGrenade.mgp_renderables_fp =
{
	"$CONTENT_DATA/Tools/Renderables/Grenade/s_granade_fp_animlist.rend",
	"$CONTENT_DATA/Tools/Renderables/Grenade/s_grenade_fp_offset.rend"
}

HandheldGrenade.mgp_tool_config =
{
	grenade_uuid = sm.uuid.new("b4a6a717-f54b-4df7-a44c-bb5308a494a2"),
	grenade_settings =
	{
		timer = 4,
		expl_lvl = 6,
		expl_rad = 1,
		expl_effect = "PropaneTank - ExplosionSmall",
		shrapnel_data = {
			min_count = 10, max_count = 25,
			min_speed = 60, max_speed = 200,
			min_damage = 20, max_damage = 50,
			proj_uuid = sm.uuid.new("7a3887dd-0fd2-489c-ac04-7306a672ae35")
		}
	}
}

sm.tool.preloadRenderables(HandheldGrenade.mgp_renderables)
sm.tool.preloadRenderables(HandheldGrenade.mgp_renderables_tp)
sm.tool.preloadRenderables(HandheldGrenade.mgp_renderables_fp)