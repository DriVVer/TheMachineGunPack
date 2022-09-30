dofile( "$GAME_DATA/Scripts/game/AnimationUtil.lua" )
dofile( "$SURVIVAL_DATA/Scripts/util.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/survival_shapes.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/survival_projectiles.lua" )

dofile("ToolAnimator.lua")

local Damage = 90

---@class Mosin : ToolClass
---@field fpAnimations table
---@field tpAnimations table
---@field aiming boolean
---@field mag_capacity integer
---@field aimFireMode table
---@field normalFireMode table
---@field movementDispersion integer
---@field blendTime integer
---@field aimBlendSpeed integer
---@field sprintCooldown integer
---@field ammo_in_mag integer
---@field fireCooldownTimer integer
---@field aim_timer integer
---@field cl_hammer_cocked boolean
---@field scope_hud GuiInterface
Mosin = class()

local renderables =
{
	"$CONTENT_DATA/Tools/Renderables/Mosin/Mosin_Base.rend",
	"$CONTENT_DATA/Tools/Renderables/Mosin/Mosin_Anim.rend"
}

local renderablesTp =
{
	"$CONTENT_DATA/Tools/Renderables/Mosin/char_male_tp_Mosin.rend",
	"$CONTENT_DATA/Tools/Renderables/Mosin/char_Mosin_tp_offset.rend"
}

local renderablesFp =
{
	"$CONTENT_DATA/Tools/Renderables/Mosin/char_male_fp_Mosin.rend",
	"$CONTENT_DATA/Tools/Renderables/Mosin/char_Mosin_fp_offset.rend"
}

sm.tool.preloadRenderables( renderables )
sm.tool.preloadRenderables( renderablesTp )
sm.tool.preloadRenderables( renderablesFp )

function Mosin.client_onCreate( self )
	self.mag_capacity = 5
	self.ammo_in_mag = self.mag_capacity

	self.cl_hammer_cocked = true

	mgp_toolAnimator_initialize(self, "Mosin")

	self.scope_hud = sm.gui.createGuiFromLayout("$CONTENT_DATA/Gui/Layouts/MosinScope.layout", false, {
		isHud = true,
		isInteractive = false,
		needsCursor = false,
		hidesHotbar = true
	})
end

function Mosin.client_onDestroy(self)
	local v_scopeHud = self.scope_hud
	if v_scopeHud and sm.exists(v_scopeHud) then
		if v_scopeHud:isActive() then
			v_scopeHud:close()
		end

		v_scopeHud:destroy()
	end

	mgp_toolAnimator_destroy(self)
end

function Mosin.client_onRefresh( self )
	self:loadAnimations()
end

function Mosin.loadAnimations( self )
	self.tpAnimations = createTpAnimations(
		self.tool,
		{
			shoot = { "spudgun_shoot", { crouch = "spudgun_crouch_shoot" } },
			aim = { "spudgun_aim", { crouch = "spudgun_crouch_aim" } },
			aimShoot = { "spudgun_aim_shoot", { crouch = "spudgun_crouch_aim_shoot" } },
			idle = { "spudgun_idle" },
			pickup = { "spudgun_pickup", { nextAnimation = "idle" } },
			putdown = { "spudgun_putdown" },

			bolt_action = { "Mosin_tp_bolt_action", { nextAnimation = "idle" } },
			bolt_action_aim = { "Mosin_tp_aim_bolt_action", { nextAnimation = "idle" } },

			reload_empty = { "Mosin_tp_empty_reload", { nextAnimation = "idle", duration = 1.0 } },
			reload = { "Mosin_tp_reload", { nextAnimation = "idle", duration = 1.0 } },
			ammo_check = { "Mosin_tp_ammo_check", { nextAnimation = "idle", duration = 1.0 } }
		}
	)
	local movementAnimations = {
		idle = "spudgun_idle",
		idleRelaxed = "spudgun_relax",

		sprint = "spudgun_sprint",
		runFwd = "spudgun_run_fwd",
		runBwd = "spudgun_run_bwd",

		jump = "spudgun_jump",
		jumpUp = "spudgun_jump_up",
		jumpDown = "spudgun_jump_down",

		land = "spudgun_jump_land",
		landFwd = "spudgun_jump_land_fwd",
		landBwd = "spudgun_jump_land_bwd",

		crouchIdle = "spudgun_crouch_idle",
		crouchFwd = "spudgun_crouch_fwd",
		crouchBwd = "spudgun_crouch_bwd"
	}

	for name, animation in pairs( movementAnimations ) do
		self.tool:setMovementAnimation( name, animation )
	end

	setTpAnimation( self.tpAnimations, "idle", 5.0 )

	if self.tool:isLocal() then
		self.fpAnimations = createFpAnimations(
			self.tool,
			{
				equip = { "Gun_pickup", { nextAnimation = "idle" } },
				unequip = { "Gun_putdown" },
				aim_anim = { "Gun_putdown" },

				idle = { "Gun_idle", { looping = true } },
				shoot = { "Gun_shoot", { nextAnimation = "idle" } },

				reload = { "Gun_reload", { nextAnimation = "idle", duration = 1.0 } },
				reload_empty = { "Gun_E_reload", { nextAnimation = "idle", duration = 1.0 } },
				cock_hammer = { "Gun_c_hammer", { nextAnimation = "idle" } },
				cock_hammer_aim = { "Gun_aim_c_hammer", { nextAnimation = "aimIdle" } },

				reload0 = { "Reload0", { nextAnimation = "idle" } },
				reload1 = { "Reload1", { nextAnimation = "idle" } },
				reload2 = { "Reload2", { nextAnimation = "idle" } },
				reload3 = { "Reload3", { nextAnimation = "idle" } },
				reload4 = { "Reload4", { nextAnimation = "idle" } },

				ammo_check = { "Gun_ammo_check", { nextAnimation = "idle", duration = 1.0 } },

				aimInto = { "Gun_aim_into", { nextAnimation = "aimIdle" } },
				aimExit = { "Gun_aim_exit", { nextAnimation = "idle", blendNext = 0 } },
				aimIdle = { "Gun_aim_idle", { looping = true } },
				aimShoot = { "Gun_aim_shoot", { nextAnimation = "aimIdle"} },

				sprintInto = { "Gun_sprint_into", { nextAnimation = "sprintIdle",  blendNext = 0.2 } },
				sprintExit = { "Gun_sprint_exit", { nextAnimation = "idle",  blendNext = 0 } },
				sprintIdle = { "Gun_sprint_idle", { looping = true } },
			}
		)
	end

	self.normalFireMode = {
		fireCooldown = 0.6,
		spreadCooldown = 0.3,
		spreadIncrement = 3,
		spreadMinAngle = 1,
		spreadMaxAngle = 3,
		fireVelocity = 500.0,

		minDispersionStanding = 0.1,
		minDispersionCrouching = 0.04,

		maxMovementDispersion = 0.4,
		jumpDispersionMultiplier = 2
	}

	self.aimFireMode = {
		fireCooldown = 0.6,
		spreadCooldown = 0.3,
		spreadIncrement = 3,
		spreadMinAngle = 1,
		spreadMaxAngle = 3,
		fireVelocity = 500.0,

		minDispersionStanding = 0.01,
		minDispersionCrouching = 0.01,

		maxMovementDispersion = 0.4,
		jumpDispersionMultiplier = 2
	}

	self.fireCooldownTimer = 1.2
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
	self.aimWeightFp = self.aimWeight
end

local actual_reload_anims =
{
	["reload0"] = true,
	["reload1"] = true,
	["reload2"] = true,
	["reload3"] = true,
	["reload4"] = true
}

local aim_animation_list01 =
{
	["aimInto"]         = true,
	["aimIdle"]         = true,
	["aimShoot"]        = true,
	["cock_hammer_aim"] = true
}

local aim_animation_list02 =
{
	["aimInto"]  = true,
	["aimIdle"]  = true,
	["aimShoot"] = true
}

function Mosin.client_onUpdate( self, dt )
	mgp_toolAnimator_update(self, dt)

	if self.aim_timer then
		self.aim_timer = self.aim_timer - dt
		if self.aim_timer <= 0.0 then
			self.aim_timer = nil
		end
	end

	-- First person animation
	local isSprinting = self.tool:isSprinting()
	local isCrouching = self.tool:isCrouching()

	if self.tool:isLocal() then
		if self.equipped then
			local fp_anim = self.fpAnimations
			local cur_anim_cache = fp_anim.currentAnimation
			local anim_data = fp_anim.animations[cur_anim_cache]
			local is_reload_anim = (actual_reload_anims[cur_anim_cache] == true)
			if anim_data and is_reload_anim then
				local time_predict = anim_data.time + anim_data.playRate * dt
				local info_duration = anim_data.info.duration

				if time_predict >= info_duration then
					self.ammo_in_mag = self.mag_capacity
					self.cl_hammer_cocked = true
				end
			end

			if isSprinting and self.fpAnimations.currentAnimation ~= "sprintInto" and self.fpAnimations.currentAnimation ~= "sprintIdle" then
				swapFpAnimation( self.fpAnimations, "sprintExit", "sprintInto", 0.0 )
			elseif not isSprinting and ( self.fpAnimations.currentAnimation == "sprintIdle" or self.fpAnimations.currentAnimation == "sprintInto" ) then
				swapFpAnimation( self.fpAnimations, "sprintInto", "sprintExit", 0.0 )
			end

			if self.fpAnimations.currentAnimation ~= "aim_anim" then
				if self.aiming and aim_animation_list01[self.fpAnimations.currentAnimation] == nil then
					swapFpAnimation( self.fpAnimations, "aimExit", "aimInto", 0.0 )
				end
				if not self.aiming and aim_animation_list02[self.fpAnimations.currentAnimation] == true then
					swapFpAnimation( self.fpAnimations, "aimInto", "aimExit", 0.0 )
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

	-- Timers
	self.fireCooldownTimer = math.max( self.fireCooldownTimer - dt, 0.0 )
	self.spreadCooldownTimer = math.max( self.spreadCooldownTimer - dt, 0.0 )
	self.sprintCooldownTimer = math.max( self.sprintCooldownTimer - dt, 0.0 )

	if self.scope_timer then
		self.scope_timer = self.scope_timer - dt

		if self.scope_timer <= 0.0 then
			self.scope_timer = nil

			if self.aiming then
				self.scope_enabled = true
			end
		end
	end

	if self.scope_enabled then
		local v_isInFirstPerson = self.tool:isInFirstPersonView()
		local v_aimState = self.aiming
		if v_isInFirstPerson and v_aimState then
			if not self.scope_hud:isActive() then
				self.scope_hud:open()

				setFpAnimation(self.fpAnimations, "aim_anim", 0.0)
				self.fpAnimations.animations.aim_anim.time = 0.5

				sm.gui.startFadeToBlack(1.0, 0.5)
				sm.gui.endFadeToBlack(0.8)
			end
		else
			if not v_aimState then
				self.scope_enabled = false
			end

			setFpAnimation(self.fpAnimations, "aimExit", 0.0)

			if self.scope_hud:isActive() then
				self.scope_hud:close()

				sm.gui.startFadeToBlack(1.0, 0.5)
				sm.gui.endFadeToBlack(0.8)
			end
		end
	end


	if self.tool:isLocal() then
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
	self.tool:setBlockSprint(self.aiming or self.sprintCooldownTimer > 0.0 or self:client_isGunReloading())

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
				elseif ( name == "reload" or name == "reload_empty" ) then
					setTpAnimation( self.tpAnimations, self.aiming and "idle" or "idle", 2 )
				elseif  name == "ammo_check" then
					setTpAnimation( self.tpAnimations, self.aiming and "idle" or "idle", 3 )
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


	local weight_blend = 1 - math.pow( 1 - 1 / self.aimBlendSpeed, dt * 60 )

	-- Camera update
	local bobbingFp = 1
	if self.aiming and self.scope_enabled then
		self.aimWeightFp = sm.util.lerp( self.aimWeightFp, 1.0, weight_blend )
		bobbingFp = 0.12
	else
		self.aimWeightFp = sm.util.lerp( self.aimWeightFp, 0.0, weight_blend )
		bobbingFp = 1
	end

	if self.aiming then
		self.aimWeight = sm.util.lerp(self.aimWeight, 1.0, weight_blend)
	else
		self.aimWeight = sm.util.lerp(self.aimWeight, 0.0, weight_blend)
	end


	self.tool:updateCamera( 2.8, 15.0, sm.vec3.new( 0.65, 0.0, 0.05 ), self.aimWeight )
	self.tool:updateFpCamera( 10.0, sm.vec3.new( 0.0, 0.0, 0.0 ), self.aimWeightFp, bobbingFp )
end

function Mosin:client_onEquip(animate)
	if animate then
		sm.audio.play( "PotatoRifle - Equip", self.tool:getPosition() )
	end

	self.wantEquipped = true
	self.aiming = false
	local cameraWeight, cameraFPWeight = self.tool:getCameraWeights()
	self.aimWeight = math.max( cameraWeight, cameraFPWeight )
	self.jointWeight = 0.0
	self.aim_timer = 1.0

	currentRenderablesTp = {}
	currentRenderablesFp = {}

	for k,v in pairs( renderablesTp ) do currentRenderablesTp[#currentRenderablesTp+1] = v end
	for k,v in pairs( renderablesFp ) do currentRenderablesFp[#currentRenderablesFp+1] = v end
	
	mgp_toolAnimator_registerRenderables(self, currentRenderablesFp, currentRenderablesTp, renderables)

	--Set the tp and fp renderables before actually loading animations
	self.tool:setTpRenderables( currentRenderablesTp )
	local is_tool_local = self.tool:isLocal()
	if is_tool_local then
		self.tool:setFpRenderables(currentRenderablesFp)
	end

	--Load animations before setting them
	self:loadAnimations()

	--Set tp and fp animations
	setTpAnimation( self.tpAnimations, "pickup", 0.0001 )
	if is_tool_local then
		swapFpAnimation(self.fpAnimations, "unequip", "equip", 0.2)
	end

	if self.cl_hammer_cocked then
		mgp_toolAnimator_setAnimation(self, "cock_the_hammer_on_equip")
	end
end

function Mosin.client_onUnequip( self, animate )
	self.scope_enabled = false
	self.wantEquipped = false
	self.equipped = false
	self.aiming = false

	mgp_toolAnimator_reset(self)

	if self.scope_hud:isActive() then
		self.scope_hud:close()

		sm.gui.startFadeToBlack(1.0, 0.5)
		sm.gui.endFadeToBlack(0.8)
	end

	if sm.exists( self.tool ) then
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

function Mosin.sv_n_onAim( self, aiming )
	self.network:sendToClients( "cl_n_onAim", aiming )
end

function Mosin.cl_n_onAim( self, aiming )
	if not self.tool:isLocal() and self.tool:isEquipped() then
		self:onAim( aiming )
	end
end

function Mosin.onAim( self, aiming )
	self.aiming = aiming
	if self.tpAnimations.currentAnimation == "idle" or self.tpAnimations.currentAnimation == "aim" or self.tpAnimations.currentAnimation == "relax" and self.aiming then
		setTpAnimation( self.tpAnimations, self.aiming and "aim" or "idle", 5.0 )
	end
end

function Mosin.sv_n_onShoot( self, dir )
	self.network:sendToClients( "cl_n_onShoot", dir )
end

function Mosin.cl_n_onShoot( self, dir )
	if not self.tool:isLocal() and self.tool:isEquipped() then
		self:onShoot( dir )
	end
end

function Mosin.onShoot( self, dir )
	self.tpAnimations.animations.idle.time     = 0
	self.tpAnimations.animations.shoot.time    = 0
	self.tpAnimations.animations.aimShoot.time = 0

	if dir ~= nil then
		setTpAnimation(self.tpAnimations, self.aiming and "aimShoot" or "shoot", 10.0)
		mgp_toolAnimator_setAnimation(self, "shoot")
	else
		mgp_toolAnimator_setAnimation(self, self.aiming and "no_ammo_aim" or "no_ammo")
	end
end

function Mosin:sv_n_cockHammer(data)
	self.network:sendToClients("cl_n_cockHammer", data)
end

function Mosin:cl_n_cockHammer(aim_data)
	if not self.tool:isLocal() and self.tool:isEquipped() then
		mgp_toolAnimator_setAnimation(self, "cock_the_hammer")
		setTpAnimation(self.tpAnimations, aim_data and "bolt_action_aim" or "bolt_action", 1.0)
	end
end

local function calculateRightVector(vector)
	local yaw = math.atan2(vector.y, vector.x) - math.pi / 2
	return sm.vec3.new(math.cos(yaw), math.sin(yaw), 0)
end

local _math_sqrt = math.sqrt
local _math_asin = math.asin
local function SolveBalArcInternal(launchPos, hitPos, velocity)
	local g = 10

	local a = (launchPos.x - hitPos.x)^2
	local b = (launchPos.y - hitPos.y)^2
	local R = _math_sqrt(a + b)

	return _math_asin(g * R / velocity^2) / 2
end

local function SolveBallisticArc(start_pos, end_pos, velocity, direction)
	local angle = SolveBalArcInternal(start_pos, end_pos, velocity)
	if angle == angle then
		return direction:rotate(angle, calculateRightVector(direction))
	end

	return direction
end

local mgp_projectile_potato = sm.uuid.new("bef985da-1271-489f-9c5a-99c08642f982")
function Mosin.cl_onPrimaryUse(self, state)
	if state == sm.tool.interactState.start then
		if self:client_isGunReloading() then return end

		if self.tool:getOwner().character == nil then
			return
		end


		if self.fireCooldownTimer <= 0.0 then
			if self.tool:isSprinting() then
				return
			end

			if self.cl_hammer_cocked then
				if self.ammo_in_mag > 0 then
				--if not sm.game.getEnableAmmoConsumption() or (sm.container.canSpend( sm.localPlayer.getInventory(), obj_plantables_potato, 1 ) and self.ammo_in_mag > 0) then
					self.ammo_in_mag = self.ammo_in_mag - 1

					local fireMode = self.aiming and self.aimFireMode or self.normalFireMode

					local dir = nil
					local firePos = nil
					if self.tool:isInFirstPersonView() and self.aiming then
						firePos = sm.camera.getPosition() + sm.camera.getDirection() * 0.5

						local hit, result = sm.localPlayer.getRaycast(300)
						if hit then
							local v_resultPos = result.pointWorld

							local dir_calc = (v_resultPos - firePos):normalize()
							dir = SolveBallisticArc(firePos, v_resultPos, fireMode.fireVelocity, dir_calc)
						else
							dir = sm.camera.getDirection()
						end
					else
						dir = sm.camera.getDirection()
						firePos = self.tool:getTpBonePos("pejnt_barrel")
					end

					-- Spread
					local recoilDispersion = 1.0 - ( math.max(fireMode.minDispersionCrouching, fireMode.minDispersionStanding ) + fireMode.maxMovementDispersion )

					local spreadFactor = fireMode.spreadCooldown > 0.0 and clamp( self.spreadCooldownTimer / fireMode.spreadCooldown, 0.0, 1.0 ) or 0.0
					spreadFactor = clamp( self.movementDispersion + spreadFactor * recoilDispersion, 0.0, 1.0 )
					local spreadDeg =  fireMode.spreadMinAngle + ( fireMode.spreadMaxAngle - fireMode.spreadMinAngle ) * spreadFactor

					dir = sm.noise.gunSpread( dir, spreadDeg )

					local owner = self.tool:getOwner()
					if owner then
						sm.projectile.projectileAttack( mgp_projectile_potato, Damage, firePos, dir * fireMode.fireVelocity, owner )
					end

					-- Timers
					self.fireCooldownTimer = fireMode.fireCooldown
					self.spreadCooldownTimer = math.min( self.spreadCooldownTimer + fireMode.spreadIncrement, fireMode.spreadCooldown )
					self.sprintCooldownTimer = self.sprintCooldown

					-- Send TP shoot over network and directly to self
					self:onShoot(1)
					self.network:sendToServer("sv_n_onShoot", 1)

					if not self.aiming then
						-- Play FP shoot animation
						setFpAnimation( self.fpAnimations, self.aiming and "aimShoot" or "shoot", 0.0 )
					end
				else
					self:onShoot()
					self.network:sendToServer("sv_n_onShoot")

					self.fireCooldownTimer = 0.3
					sm.audio.play( "PotatoRifle - NoAmmo" )
				end
			else
				if self.aiming then
					sm.gui.displayAlertText("Can't reload while aiming")
					return
				end

				if self.ammo_in_mag == 0 then
					self:client_onReload()
					return
				else
					self.fireCooldownTimer = 1.0

					self.network:sendToServer("sv_n_cockHammer", self.aiming)

					if self.aiming then
						setFpAnimation(self.fpAnimations, "cock_hammer_aim", 0.0)
						setTpAnimation(self.tpAnimations, "bolt_action_aim", 1.0)
						mgp_toolAnimator_setAnimation(self, "cock_the_hammer_aim")
					else
						setFpAnimation(self.fpAnimations, "cock_hammer", 0.0)
						setTpAnimation(self.tpAnimations, "bolt_action", 1.0)
						mgp_toolAnimator_setAnimation(self, "cock_the_hammer")
					end
				end
			end

			self.cl_hammer_cocked = not self.cl_hammer_cocked
		end
	end
end

local reload_anims =
{
	["cock_hammer_aim"] = true,
	["ammo_check"     ] = true,
	["cock_hammer"    ] = true,
	["reload0"] = true,
	["reload1"] = true,
	["reload2"] = true,
	["reload3"] = true,
	["reload4"] = true
}

local ammo_count_to_anim_name =
{
	[0] = "reload0",
	[1] = "reload1",
	[2] = "reload2",
	[3] = "reload3",
	[4] = "reload4",
	[5] = "reload5"
}

function Mosin:sv_n_onReload(anim_id)
	self.network:sendToClients("cl_n_onReload", anim_id)
end

function Mosin:cl_n_onReload(anim_id)
	if not self.tool:isLocal() and self.tool:isEquipped() then
		self:cl_startReloadAnim(anim_id)
	end
end

function Mosin:cl_startReloadAnim(anim_name)
	setTpAnimation(self.tpAnimations, "reload", 1.0)
	mgp_toolAnimator_setAnimation(self, anim_name)
end

function Mosin:client_isGunReloading()
	local fp_anims = self.fpAnimations
	if fp_anims ~= nil then
		return (reload_anims[fp_anims.currentAnimation] == true)
	end

	return false
end

local mosin_fp_animation_names =
{
	[0] = "reload0",
	[1] = "reload1",
	[2] = "reload2",
	[3] = "reload3",
	[4] = "reload4"
}

function Mosin:cl_initReloadAnim(anim_id)
	local anim_name = ammo_count_to_anim_name[anim_id]

	setFpAnimation(self.fpAnimations, mosin_fp_animation_names[self.ammo_in_mag], 0.0)
	self:cl_startReloadAnim(anim_name)

	--Send the animation data to all the other clients
	self.network:sendToServer("sv_n_onReload", anim_id)
end

function Mosin:client_onReload()
	if self.ammo_in_mag ~= self.mag_capacity then
		if self.cl_hammer_cocked then
			sm.gui.displayAlertText("You can't reload while the hammer is cocked!", 3)
			return true
		end

		if not self:client_isGunReloading() and not self.aiming and not self.tool:isSprinting() and self.fireCooldownTimer == 0.0 then
			self:cl_initReloadAnim(self.ammo_in_mag)
		end
	end

	return true
end

function Mosin:sv_n_checkMag()
	self.network:sendToClients("cl_n_checkMag")
end

function Mosin:cl_n_checkMag()
	local s_tool = self.tool
	if not s_tool:isLocal() and s_tool:isEquipped() then
		self:cl_startCheckMagAnim()
	end
end

function Mosin:cl_startCheckMagAnim()
	setTpAnimation(self.tpAnimations, "ammo_check", 1.0)
	mgp_toolAnimator_setAnimation(self, "ammo_check")
end

function Mosin:client_onToggle()
	if not self:client_isGunReloading() and not self.aiming and not self.tool:isSprinting() and self.fireCooldownTimer == 0.0 then
		if self.ammo_in_mag > 0 then
			sm.gui.displayAlertText(("Mosin: Ammo #ffff00%s#ffffff/#ffff00%s#ffffff"):format(self.ammo_in_mag, self.mag_capacity), 2)

			setFpAnimation(self.fpAnimations, "ammo_check", 0.0)

			self:cl_startCheckMagAnim()
			self.network:sendToServer("sv_n_checkMag")
		else
			sm.gui.displayAlertText("Mosin: No Ammo. Reloading...", 3)
			self:cl_initReloadAnim(0)
		end
	end

	return true
end

local _intstate = sm.tool.interactState
function Mosin.cl_onSecondaryUse( self, state )
	if self.scope_timer then return end

	local is_reloading = self:client_isGunReloading() or (self.aim_timer ~= nil)
	local new_state = (state == _intstate.start or state == _intstate.hold) and not is_reloading
	if self.aiming ~= new_state then
		self.aiming = new_state
		self.tpAnimations.animations.idle.time = 0

		if self.aiming then
			self.scope_timer = 0.3
		else
			self.fireCooldownTimer = 0.4
			self.scope_timer = 0.5
		end

		self.tool:setMovementSlowDown(self.aiming)
		self:onAim(self.aiming)
		self.network:sendToServer("sv_n_onAim", self.aiming)
	end
end

function Mosin.client_onEquippedUpdate(self, primaryState, secondaryState)
	if primaryState ~= self.prevPrimaryState then
		self:cl_onPrimaryUse(primaryState)
		self.prevPrimaryState = primaryState
	end

	self:cl_onSecondaryUse( secondaryState )

	return true, true
end
