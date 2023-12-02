dofile( "$GAME_DATA/Scripts/game/AnimationUtil.lua" )
dofile( "$SURVIVAL_DATA/Scripts/util.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/survival_shapes.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/survival_projectiles.lua" )

---@class ShrapnelGrenadeBase : ToolClass
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
ShrapnelGrenadeBase = class()

function ShrapnelGrenadeBase:client_onCreate()
	self.grenade_active = true
end

function ShrapnelGrenadeBase:client_onRefresh()
	self:loadAnimations()
end

function ShrapnelGrenadeBase.loadAnimations( self )

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

	if self.cl_isLocal then
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

function ShrapnelGrenadeBase.client_onUpdate( self, dt )

	-- First person animation
	local isSprinting =  self.tool:isSprinting()
	local isCrouching =  self.tool:isCrouching()

	if self.cl_isLocal then
		if self.equipped then
			if isSprinting and self.fpAnimations.currentAnimation ~= "sprintInto" and self.fpAnimations.currentAnimation ~= "sprintIdle" then
				swapFpAnimation( self.fpAnimations, "sprintExit", "sprintInto", 0.0 )
			elseif not self.tool:isSprinting() and ( self.fpAnimations.currentAnimation == "sprintIdle" or self.fpAnimations.currentAnimation == "sprintInto" ) then
				swapFpAnimation( self.fpAnimations, "sprintInto", "sprintExit", 0.0 )
			end

			if self.aiming and not isAnyOf( self.fpAnimations.currentAnimation, { "aimInto", "aimIdle", "aimShoot" } ) then
				swapFpAnimation( self.fpAnimations, "aimExit", "aimInto", 0.0 )
			end
			if not self.aiming and isAnyOf( self.fpAnimations.currentAnimation, { "aimInto", "aimIdle", "aimShoot" } ) then
				swapFpAnimation( self.fpAnimations, "aimInto", "aimExit", 0.0 )
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


	if self.cl_isLocal then
		local dispersion = 0.0
		local fireMode = self.aiming and self.aimFireMode or self.normalFireMode
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

		if self.aiming then
			if self.tool:isInFirstPersonView() then
				self.tool:setCrossHairAlpha( 0.0 )
			else
				self.tool:setCrossHairAlpha( 1.0 )
			end
			self.tool:setInteractionTextSuppressed( true )
		else
			self.tool:setCrossHairAlpha( 1.0 )
			self.tool:setInteractionTextSuppressed( false )
		end
	end

	-- Sprint block
	local blockSprint = self.aiming or self.sprintCooldownTimer > 0.0
	self.tool:setBlockSprint( blockSprint )

	local playerDir = self.tool:getSmoothDirection()
	local angle = math.asin( playerDir:dot( sm.vec3.new( 0, 0, 1 ) ) ) / ( math.pi / 2 )
	local linareAngle = playerDir:dot( sm.vec3.new( 0, 0, 1 ) )

	local linareAngleDown = clamp( -linareAngle, 0.0, 1.0 )

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


	-- Camera update
	local bobbing = 1
	if self.aiming then
		local blend = 1 - math.pow( 1 - 1 / self.aimBlendSpeed, dt * 60 )
		self.aimWeight = sm.util.lerp( self.aimWeight, 1.0, blend )
		bobbing = 0.12
	else
		local blend = 1 - math.pow( 1 - 1 / self.aimBlendSpeed, dt * 60 )
		self.aimWeight = sm.util.lerp( self.aimWeight, 0.0, blend )
		bobbing = 1
	end

	self.tool:updateCamera( 2.8, 30.0, sm.vec3.new( 0.65, 0.0, 0.05 ), self.aimWeight )
	self.tool:updateFpCamera( 30.0, sm.vec3.new( 0.0, 0.0, 0.0 ), self.aimWeight, bobbing )
end

function ShrapnelGrenadeBase.client_onEquip( self, animate )

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

function ShrapnelGrenadeBase.client_onUnequip( self, animate )

	self.wantEquipped = false
	self.equipped = false
	self.aiming = false
	if sm.exists( self.tool ) then
		if animate then
			sm.audio.play( "PotatoRifle - Unequip", self.tool:getPosition() )
		end
		setTpAnimation( self.tpAnimations, "putdown" )
		if self.cl_isLocal then
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

function ShrapnelGrenadeBase.sv_n_onAim( self, aiming )
	self.network:sendToClients( "cl_n_onAim", aiming )
end

function ShrapnelGrenadeBase.cl_n_onAim( self, aiming )
	if not self.cl_isLocal and self.tool:isEquipped() then
		self:onAim( aiming )
	end
end

function ShrapnelGrenadeBase.onAim( self, aiming )
	self.aiming = aiming
	if self.tpAnimations.currentAnimation == "idle" or self.tpAnimations.currentAnimation == "aim" or self.tpAnimations.currentAnimation == "relax" and self.aiming then
		setTpAnimation( self.tpAnimations, self.aiming and "aim" or "idle", 5.0 )
	end
end

function ShrapnelGrenadeBase:onShoot()
	self.tpAnimations.animations.idle.time = 0
	self.tpAnimations.animations.shoot.time = 0
	self.tpAnimations.animations.aimShoot.time = 0

	setTpAnimation( self.tpAnimations, "shoot", 10.0 )
end

function ShrapnelGrenadeBase:cl_n_throwGrenade()
	if not self.cl_isLocal and self.tool:isEquipped() then
		self:onShoot()
	end
end

function ShrapnelGrenadeBase:sv_n_throwGrenade()
	self.network:sendToClients("cl_n_throwGrenade")
end

function ShrapnelGrenadeBase:sv_n_spawnGrenade()
	local owner_player = self.tool:getOwner()
	local owner_char = owner_player.character

	if owner_char and sm.exists(owner_char) then
		local tool_config = self.mgp_tool_config

		local char_dir = owner_char.direction
		local grenade_pos = owner_char.worldPosition + char_dir * 0.5
		local grenade_rotation = sm.vec3.getRotation(char_dir, sm.vec3.new(0, 0, 1))

		local s_grenade = sm.shape.createPart(tool_config.grenade_uuid, grenade_pos, grenade_rotation, true, true)

		--Apply forward impulse
		sm.physics.applyImpulse(s_grenade, owner_char.direction * s_grenade:getMass() * 20, true)

		--Apply rotation
		sm.physics.applyImpulse(s_grenade, sm.vec3.new(0, 0, 30), false, sm.vec3.new(0, 0.1, 0))
		sm.physics.applyImpulse(s_grenade, sm.vec3.new(0, 0, -30), false, sm.vec3.new(0, -0.1, 0))

		local grenade_inter = s_grenade.interactable
		if grenade_inter then
			grenade_inter.publicData = tool_config.grenade_settings
		end
	end
end

function ShrapnelGrenadeBase:cl_onPrimaryUse(state)
	if self.tool:getOwner().character == nil then
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
			self.grenade_active = true
			setFpAnimation(self.fpAnimations, "activate", 0.0)

			self.fireCooldownTimer = 2.4
		end
	end
end

function ShrapnelGrenadeBase.cl_onSecondaryUse( self, state )
	if state == sm.tool.interactState.start and not self.aiming then
		self.aiming = true
		self.tpAnimations.animations.idle.time = 0

		self:onAim( self.aiming )
		self.tool:setMovementSlowDown( self.aiming )
		self.network:sendToServer( "sv_n_onAim", self.aiming )
	end

	if self.aiming and (state == sm.tool.interactState.stop or state == sm.tool.interactState.null) then
		self.aiming = false
		self.tpAnimations.animations.idle.time = 0

		self:onAim( self.aiming )
		self.tool:setMovementSlowDown( self.aiming )
		self.network:sendToServer( "sv_n_onAim", self.aiming )
	end
end

function ShrapnelGrenadeBase.client_onEquippedUpdate( self, primaryState, secondaryState )
	if primaryState ~= self.prevPrimaryState then
		self:cl_onPrimaryUse( primaryState )
		self.prevPrimaryState = primaryState
	end

	if secondaryState ~= self.prevSecondaryState then
		self:cl_onSecondaryUse( secondaryState )
		self.prevSecondaryState = secondaryState
	end

	return true, true
end

--Custom class definitions

---@type ShrapnelGrenadeBase
ShrapnelGrenade = class(ShrapnelGrenadeBase)

ShrapnelGrenade.mgp_renderables =
{
	"$CONTENT_DATA/Tools/Renderables/Shrapnel_Grenade/Shrapnel_grenade_Model.rend",
	"$CONTENT_DATA/Tools/Renderables/Shrapnel_Grenade/Shrapnel_grenade_AnimModel.rend"
}

ShrapnelGrenade.mgp_renderables_tp =
{
	"$CONTENT_DATA/Tools/Renderables/Shrapnel_Grenade/shrapnel_grenade_tp_animlist.rend",
	"$CONTENT_DATA/Tools/Renderables/Grenade/s_grenade_tp_offset.rend"
}

ShrapnelGrenade.mgp_renderables_fp =
{
	"$CONTENT_DATA/Tools/Renderables/Shrapnel_Grenade/shrapnel_grenade_fp_animlist.rend",
	"$CONTENT_DATA/Tools/Renderables/Grenade/s_grenade_fp_offset.rend"
}

ShrapnelGrenade.mgp_tool_config =
{
	grenade_uuid = sm.uuid.new("b4a6a717-f54b-4df7-a44c-bb5308a494a2"),
	grenade_settings =
	{
		timer = 4,
		expl_lvl = 6,
		expl_rad = 3,
		expl_effect = "PropaneTank - ExplosionSmall",
		shrapnel_data = {
			min_count = 10, max_count = 25,
			min_speed = 60, max_speed = 200,
			min_damage = 20, max_damage = 50,
			proj_uuid = sm.uuid.new("7a3887dd-0fd2-489c-ac04-7306a672ae35")
		}
	}
}

sm.tool.preloadRenderables(ShrapnelGrenade.mgp_renderables)
sm.tool.preloadRenderables(ShrapnelGrenade.mgp_renderables_tp)
sm.tool.preloadRenderables(ShrapnelGrenade.mgp_renderables_fp)