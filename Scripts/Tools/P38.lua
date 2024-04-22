dofile( "$GAME_DATA/Scripts/game/AnimationUtil.lua" )
dofile( "$SURVIVAL_DATA/Scripts/util.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/survival_shapes.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/survival_projectiles.lua" )

dofile("ToolAnimator.lua")
dofile("ToolSwimUtil.lua")

local Damage = 26

---@class P38 : ToolClass
---@field fpAnimations table
---@field tpAnimations table
---@field mag_capacity integer
---@field aiming boolean
---@field aimFireMode table
---@field normalFireMode table
---@field blendTime integer
---@field aimBlendSpeed integer
---@field movementDispersion integer
---@field sprintCooldown integer
---@field ammo_in_mag integer
---@field fireCooldownTimer integer
---@field spineWeight number
P38 = class()
P38.mag_capacity = 8
P38.maxRecoil = 20
P38.recoilAmount = 10
P38.aimRecoilAmount = 5
P38.recoilRecoverySpeed = 2

local renderables =
{
	"$CONTENT_DATA/Tools/Renderables/P38/P38_Base.rend",
	"$CONTENT_DATA/Tools/Renderables/P38/P38_Anim.rend"
}

local renderablesTp =
{
	"$CONTENT_DATA/Tools/Renderables/P38/char_P38_anims_tp.rend",
	"$CONTENT_DATA/Tools/Renderables/P38/char_P38_offset_tp.rend"
}

local renderablesFp =
{
	"$CONTENT_DATA/Tools/Renderables/P38/char_P38_anims_fp.rend",
	"$CONTENT_DATA/Tools/Renderables/P38/char_P38_offset_fp.rend"
}

sm.tool.preloadRenderables( renderables )
sm.tool.preloadRenderables( renderablesTp )
sm.tool.preloadRenderables( renderablesFp )

function P38:client_initAimVals()
	local cameraWeight, cameraFPWeight = self.tool:getCameraWeights()
	self.aimWeight = math.max( cameraWeight, cameraFPWeight )
end

function P38:server_onCreate()
	self.sv_ammo_counter = 0

	local v_saved_ammo = self.storage:load()
	if v_saved_ammo ~= nil then
		self.sv_ammo_counter = v_saved_ammo
	else
		if not sm.game.getEnableAmmoConsumption() or not sm.game.getLimitedInventory() then
			self.sv_ammo_counter = self.mag_capacity
		end

		self:server_updateAmmoCounter()
	end
end

function P38:server_requestAmmo(data, caller)
	self.network:sendToClient(caller, "client_receiveAmmo", self.sv_ammo_counter)
end

function P38:server_updateAmmoCounter(data, caller)
	if data ~= nil or caller ~= nil then return end

	self.storage:save(self.sv_ammo_counter)
end

function P38:client_receiveAmmo(ammo_count)
	self.ammo_in_mag = ammo_count
	self.waiting_for_ammo = nil
end

function P38:client_onCreate()
	self.ammo_in_mag = 0

	self.aimBlendSpeed = 10.0
	self:client_initAimVals()

	self.waiting_for_ammo = true

	mgp_toolAnimator_initialize(self, "p38")

	self.network:sendToServer("server_requestAmmo")
end

function P38.client_onDestroy(self)
	mgp_toolAnimator_destroy(self)
end

function P38.client_onRefresh( self )
	self:loadAnimations()
end

function P38.loadAnimations( self )
	self.tpAnimations = createTpAnimations(
		self.tool,
		{
			shoot = { "spudgun_shoot", { crouch = "spudgun_crouch_shoot" } },
			aim = { "spudgun_aim", { crouch = "spudgun_crouch_aim" } },
			aimShoot = { "spudgun_aim_shoot", { crouch = "spudgun_crouch_aim_shoot" } },
			idle = { "spudgun_idle" },
			pickup = { "spudgun_pickup", { nextAnimation = "idle" } },
			putdown = { "spudgun_putdown" },

			reload_empty = { "P38_tp_empty_reload", { nextAnimation = "idle", duration = 1.0 } },
			reload = { "P38_tp_reload", { nextAnimation = "idle", duration = 1.0 } },
			ammo_check = { "P38_tp_ammo_check", {nextAnimation = "idle", duration = 1.0}}
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

	if self.cl_isLocal then
		self.fpAnimations = createFpAnimations(
			self.tool,
			{
				equip = { "P38_pickup", { nextAnimation = "idle" } },
				unequip = { "P38_putdown" },

				idle = { "P38_idle", { looping = true } },
				shoot = { "P38_shoot", { nextAnimation = "idle" } },

				reload = { "P38_reload", { nextAnimation = "idle", duration = 1.0 } },
				reload_empty = { "P38_reload_empty", { nextAnimation = "idle", duration = 1.0 } },

				ammo_check = { "P38_ammo_check", { nextAnimation = "idle", duration = 1.0 } },

				aimInto = { "P38_aim_into", { nextAnimation = "aimIdle" } },
				aimExit = { "P38_aim_exit", { nextAnimation = "idle", blendNext = 0 } },
				aimIdle = { "P38_aim_idle", { looping = true } },
				aimShoot = { "P38_aim_shoot", { nextAnimation = "aimIdle"} },

				sprintInto = { "P38_sprint_into", { nextAnimation = "sprintIdle",  blendNext = 0.2 } },
				sprintExit = { "P38_sprint_exit", { nextAnimation = "idle",  blendNext = 0 } },
				sprintIdle = { "P38_sprint_idle", { looping = true } },
				sprintShoot = { "P38_sprint_shoot", { nextAnimation = "sprintIdle",  blendNext = 0.2 } }
			}
		)
	end

	self.normalFireMode = {
		fireCooldown = 0.15,
		spreadCooldown = 0.18,
		spreadIncrement = 2.6,
		spreadMinAngle = 4.25,
		spreadMaxAngle = 16,
		fireVelocity = 350.0,

		minDispersionStanding = 0.1,
		minDispersionCrouching = 0.04,

		maxMovementDispersion = 0.4,
		jumpDispersionMultiplier = 2
	}

	self.aimFireMode = {
		fireCooldown = 0.15,
		spreadCooldown = 0.18,
		spreadIncrement = 1.5,
		spreadMinAngle = 1,
		spreadMaxAngle = 3,
		fireVelocity =  350.0,

		minDispersionStanding = 0.01,
		minDispersionCrouching = 0.01,

		maxMovementDispersion = 0.4,
		jumpDispersionMultiplier = 2
	}

	self.fireCooldownTimer = 0.8
	self.spreadCooldownTimer = 0.0

	self.movementDispersion = 0.0

	self.sprintCooldownTimer = 0.0
	self.sprintCooldown = 0.3

	self.blendTime = 0.2

	self.jointWeight = 0.0
	self.spineWeight = 0.0

	self:client_initAimVals()
end

local actual_reload_anims =
{
	["reload"] = true,
	["reload_empty"] = true
}

local aim_animations =
{
	["aimInto"]         = true,
	["aimIdle"]         = true,
	["aimShoot"]        = true
}

function P38:client_updateAimWeights(dt)
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

local mgp_pistol_ammo = sm.uuid.new("af84d5d9-00b1-4bab-9c5a-102c11e14a13")
function P38:server_spendAmmo(data, player)
	if data ~= nil or player ~= nil then return end

	local v_owner = self.tool:getOwner()
	if v_owner == nil then return end

	local v_inventory = v_owner:getInventory()
	if v_inventory == nil then return end

	local v_available_ammo = sm.container.totalQuantity(v_inventory, mgp_pistol_ammo)
	if v_available_ammo == 0 then return end

	local v_capacity_adder = (self.sv_ammo_counter > 0) and 1 or 0

	local v_raw_spend_count = math.max(self.mag_capacity - self.sv_ammo_counter, 0)
	local v_spend_count = math.min(v_raw_spend_count, math.min(v_available_ammo, self.mag_capacity))

	sm.container.beginTransaction()
	sm.container.spend(v_inventory, mgp_pistol_ammo, v_spend_count)
	sm.container.endTransaction()

	self.sv_ammo_counter = self.sv_ammo_counter + v_spend_count + v_capacity_adder
	self:server_updateAmmoCounter()
end

function P38:sv_n_trySpendAmmo(data, player)
	local v_owner = self.tool:getOwner()
	if v_owner == nil or v_owner ~= player then return end

	self:server_spendAmmo()
	self.network:sendToClient(v_owner, "client_receiveAmmo", self.sv_ammo_counter)
end

function P38.client_onUpdate( self, dt )
	mgp_toolAnimator_update(self, dt)

	-- First person animation
	local isSprinting = self.tool:isSprinting()
	local isCrouching = self.tool:isCrouching()

	if self.cl_isLocal then
		if self.equipped then
			local fp_anim = self.fpAnimations
			local cur_anim_cache = fp_anim.currentAnimation
			local anim_data = fp_anim.animations[cur_anim_cache]
			local is_reload_anim = (actual_reload_anims[cur_anim_cache] == true)
			if anim_data and is_reload_anim then
				local time_predict = anim_data.time + anim_data.playRate * dt
				local info_duration = anim_data.info.duration

				if time_predict >= info_duration then
					self.network:sendToServer("sv_n_trySpendAmmo")
				end
			end

			if cur_anim_cache ~= "sprintShoot" then
				if isSprinting and cur_anim_cache ~= "sprintInto" and cur_anim_cache ~= "sprintIdle" then
					swapFpAnimation( self.fpAnimations, "sprintExit", "sprintInto", 0.0 )
				elseif not isSprinting and ( cur_anim_cache == "sprintIdle" or cur_anim_cache == "sprintInto" ) then
					swapFpAnimation( self.fpAnimations, "sprintInto", "sprintExit", 0.0 )
				end
			end

			local isAimAnim = aim_animations[cur_anim_cache] == true
			if self.aiming and not isAimAnim then
				swapFpAnimation( self.fpAnimations, "aimExit", "aimInto", 0.0 )
			end
			if not self.aiming and isAimAnim then
				swapFpAnimation( self.fpAnimations, "aimInto", "aimExit", 0.0 )
			end
		end
		updateFpAnimations( self.fpAnimations, self.equipped, dt )
	end

	TSU_OnUpdate(self)

	self:client_updateAimWeights(dt)

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
	local blockSprint = self.aiming or self:client_isGunReloading()
	self.tool:setBlockSprint( blockSprint )

	local playerDir = self.tool:getSmoothDirection()
	local angle = math.asin( playerDir:dot( sm.vec3.new( 0, 0, 1 ) ) ) / ( math.pi / 2 ) + self.cl_recoilAngle

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
	if ( ( ( isAnyOf( self.tpAnimations.currentAnimation, { "aimInto", "aim", "shoot" } ) and ( relativeMoveDirection:length() > 0 or isCrouching) ) or ( self.aiming and ( relativeMoveDirection:length() > 0 or isCrouching) ) ) ) then
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

function P38:client_onEquip(animate, is_custom)
	if not is_custom and TSU_IsOwnerSwimming(self) then
		return
	end

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

	for k,v in pairs( renderablesTp ) do currentRenderablesTp[#currentRenderablesTp+1] = v end
	for k,v in pairs( renderablesFp ) do currentRenderablesFp[#currentRenderablesFp+1] = v end
	for k,v in pairs( renderables ) do currentRenderablesTp[#currentRenderablesTp+1] = v end
	for k,v in pairs( renderables ) do currentRenderablesFp[#currentRenderablesFp+1] = v end
	
	--Set the tp and fp renderables before actually loading animations
	self.tool:setTpRenderables( currentRenderablesTp )
	if self.cl_isLocal then
		self.tool:setFpRenderables(currentRenderablesFp)
	end

	--Load animations before setting them
	self:loadAnimations()

	local v_gun_color = sm.color.new("c4b68d")
	self.tool:setTpColor(v_gun_color)
	self.tool:setFpColor(v_gun_color)

	--Set tp and fp animations
	setTpAnimation( self.tpAnimations, "pickup", 0.0001 )
	if self.cl_isLocal then
		swapFpAnimation(self.fpAnimations, "unequip", "equip", 0.2)
	end

	mgp_toolAnimator_setAnimation(self, (self.ammo_in_mag <= 0) and "last_shot_equip" or "equip")
end

function P38:client_onUnequip(animate, is_custom)
	if not is_custom and TSU_IsOwnerSwimming(self) then
		return
	end

	self.waiting_for_ammo = nil
	self.wantEquipped = false
	self.equipped = false
	self.aiming = false
	mgp_toolAnimator_reset(self)

	local s_tool = self.tool
	if sm.exists(s_tool) then
		if animate then
			sm.audio.play( "PotatoRifle - Unequip", s_tool:getPosition() )
		end

		if is_custom then
			s_tool:setTpRenderables({})
		else
			setTpAnimation( self.tpAnimations, "putdown" )
		end

		if s_tool:isLocal() then
			s_tool:setMovementSlowDown(false)
			s_tool:setBlockSprint(false)
			s_tool:setCrossHairAlpha(1.0)
			s_tool:setInteractionTextSuppressed(false)
			s_tool:setDispersionFraction(0.0)

			if self.fpAnimations.currentAnimation ~= "unequip" then
				swapFpAnimation( self.fpAnimations, "equip", "unequip", 0.2 )
			end
		end
	end
end

function P38:sv_n_onAim(aiming)
	self.network:sendToClients( "cl_n_onAim", aiming )
end

function P38:cl_n_onAim(aiming)
	if not self.cl_isLocal and self.tool:isEquipped() then
		self:onAim(aiming)
	end
end

function P38:onAim(aiming)
	self.aiming = aiming
	if self.tpAnimations.currentAnimation == "idle" or self.tpAnimations.currentAnimation == "aim" or self.tpAnimations.currentAnimation == "relax" and self.aiming then
		setTpAnimation( self.tpAnimations, self.aiming and "aim" or "idle", 5.0 )
	end
end

function P38:sv_n_onShoot(is_last_shot)
	self.network:sendToClients("cl_n_onShoot", is_last_shot)

	if is_last_shot ~= nil and self.sv_ammo_counter > 0 then
		self.sv_ammo_counter = self.sv_ammo_counter - 1
		self:server_updateAmmoCounter()
	end
end

function P38:cl_n_onShoot(is_last_shot)
	if not self.cl_isLocal and self.tool:isEquipped() then
		self:onShoot(is_last_shot)
	end
end

function P38:onShoot(is_last_shot)
	self.tpAnimations.animations.idle.time = 0
	self.tpAnimations.animations.shoot.time = 0
	self.tpAnimations.animations.aimShoot.time = 0

	local anim = self.aiming and "aimShoot" or "shoot"
	setTpAnimation( self.tpAnimations, anim, 10.0 )
	mgp_toolAnimator_setAnimation(self, is_last_shot and "last_shot" or anim)
end

function P38:calculateFirePosition()
	local crouching = self.tool:isCrouching()
	local firstPerson = self.tool:isInFirstPersonView()
	local dir = sm.localPlayer.getDirection()
	local pitch = math.asin( dir.z )
	local right = sm.localPlayer.getRight()

	local fireOffset = sm.vec3.new( 0.0, 0.0, 0.0 )

	if crouching then
		fireOffset.z = 0.15
	else
		fireOffset.z = 0.45
	end

	if firstPerson then
		if not self.aiming then
			fireOffset = fireOffset + right * 0.05
		end
	else
		fireOffset = fireOffset + right * 0.25
		fireOffset = fireOffset:rotate( math.rad( pitch ), right )
	end
	local firePosition = GetOwnerPosition( self.tool ) + fireOffset
	return firePosition
end

function P38:calculateTpMuzzlePos()
	local crouching = self.tool:isCrouching()
	local dir = sm.localPlayer.getDirection()
	local pitch = math.asin( dir.z )
	local right = sm.localPlayer.getRight()
	local up = right:cross(dir)

	local fakeOffset = sm.vec3.new( 0.0, 0.0, 0.0 )

	--General offset
	fakeOffset = fakeOffset + right * 0.25
	fakeOffset = fakeOffset + dir * 0.5
	fakeOffset = fakeOffset + up * 0.25

	--Action offset
	local pitchFraction = pitch / ( math.pi * 0.5 )
	if crouching then
		fakeOffset = fakeOffset + dir * 0.2
		fakeOffset = fakeOffset + up * 0.1 --[[@as Vec3]]
		fakeOffset = fakeOffset - right * 0.05

		if pitchFraction > 0.0 then
			fakeOffset = fakeOffset - up * 0.2 * pitchFraction
		else
			fakeOffset = fakeOffset + up * 0.1 * math.abs( pitchFraction )
		end
	else
		fakeOffset = fakeOffset + up * 0.1 *  math.abs( pitchFraction )
	end

	local fakePosition = fakeOffset + GetOwnerPosition( self.tool )
	return fakePosition
end

function P38:calculateFpMuzzlePos()
	local fovScale = ( sm.camera.getFov() - 45 ) / 45

	local up = sm.localPlayer.getUp()
	local dir = sm.localPlayer.getDirection()
	local right = sm.localPlayer.getRight()

	local muzzlePos45 = sm.vec3.new( 0.0, 0.0, 0.0 )
	local muzzlePos90 = sm.vec3.new( 0.0, 0.0, 0.0 )

	if self.aiming then
		muzzlePos45 = muzzlePos45 - up * 0.2
		muzzlePos45 = muzzlePos45 + dir * 0.5 --[[@as Vec3]]

		muzzlePos90 = muzzlePos90 - up * 0.5
		muzzlePos90 = muzzlePos90 - dir * 0.6 --[[@as Vec3]]
	else
		muzzlePos45 = muzzlePos45 - up * 0.15
		muzzlePos45 = muzzlePos45 + right * 0.2
		muzzlePos45 = muzzlePos45 + dir * 1.25

		muzzlePos90 = muzzlePos90 - up * 0.15
		muzzlePos90 = muzzlePos90 + right * 0.2
		muzzlePos90 = muzzlePos90 + dir * 0.25
	end

	return self.tool:getFpBonePos( "pejnt_barrel" ) + sm.vec3.lerp( muzzlePos45, muzzlePos90, fovScale )
end

local mgp_projectile_potato = sm.uuid.new("6c87e1c0-79a6-40dc-a26a-ef28916aff69")
function P38:cl_onPrimaryUse(is_shooting)
	if not is_shooting or not self.equipped then return end
	if self:client_isGunReloading() then return end

	local v_toolOwner = self.tool:getOwner()
	if not (v_toolOwner and sm.exists(v_toolOwner)) then
		return
	end

	local v_ownerChar = v_toolOwner.character
	if not (v_ownerChar and sm.exists(v_ownerChar)) then
		return
	end

	if self.fireCooldownTimer > 0.0 then
		return
	end

	if self.ammo_in_mag > 0 then
		self.ammo_in_mag = self.ammo_in_mag - 1
		local firstPerson = self.tool:isInFirstPersonView()

		local dir = sm.localPlayer.getDirection()

		local firePos = self:calculateFirePosition()
		local fakePosition = self:calculateTpMuzzlePos()
		local fakePositionSelf = fakePosition
		if firstPerson then
			fakePositionSelf = self:calculateFpMuzzlePos()
		end

		-- Aim assist
		if not firstPerson then
			local raycastPos = sm.camera.getPosition() + sm.camera.getDirection() * sm.camera.getDirection():dot( GetOwnerPosition( self.tool ) - sm.camera.getPosition() )
			local hit, result = sm.localPlayer.getRaycast( 250, raycastPos, sm.camera.getDirection() )
			if hit then
				local norDir = sm.vec3.normalize( result.pointWorld - firePos )
				local dirDot = norDir:dot( dir )

				if dirDot > 0.96592583 then -- max 15 degrees off
					dir = norDir
				else
					local radsOff = math.asin( dirDot )
					dir = sm.vec3.lerp( dir, norDir, math.tan( radsOff ) / 3.7320508 ) -- if more than 15, make it 15
				end
			end
		end

		dir = dir:rotate( math.rad( 0.4 ), sm.camera.getRight() ) -- 25 m sight calibration

		-- Spread
		local fireMode = self.aiming and self.aimFireMode or self.normalFireMode
		local recoilDispersion = 1.0 - ( math.max(fireMode.minDispersionCrouching, fireMode.minDispersionStanding ) + fireMode.maxMovementDispersion )

		local spreadFactor = fireMode.spreadCooldown > 0.0 and clamp( self.spreadCooldownTimer / fireMode.spreadCooldown, 0.0, 1.0 ) or 0.0
		spreadFactor = clamp( self.movementDispersion + spreadFactor * recoilDispersion, 0.0, 1.0 )
		local spreadDeg =  fireMode.spreadMinAngle + ( fireMode.spreadMaxAngle - fireMode.spreadMinAngle ) * spreadFactor

		dir = sm.noise.gunSpread( dir, spreadDeg )

		sm.projectile.projectileAttack( mgp_projectile_potato, Damage, firePos, dir * fireMode.fireVelocity, v_toolOwner, fakePosition, fakePositionSelf )

		-- Timers
		self.fireCooldownTimer = fireMode.fireCooldown
		self.spreadCooldownTimer = math.min( self.spreadCooldownTimer + fireMode.spreadIncrement, fireMode.spreadCooldown )
		self.sprintCooldownTimer = self.sprintCooldown

		local is_last_shot = self.ammo_in_mag == 0

		-- Send TP shoot over network and dircly to self
		self:onShoot(is_last_shot)
		self.network:sendToServer("sv_n_onShoot", is_last_shot)

		-- Play FP shoot animation
		setFpAnimation( self.fpAnimations, self.tool:isSprinting() and "sprintShoot" or (self.aiming and "aimShoot" or "shoot"), 0.0 )
	else
		local fireMode = self.aiming and self.aimFireMode or self.normalFireMode
		self.fireCooldownTimer = fireMode.fireCooldown
		sm.audio.play( "PotatoRifle - NoAmmo" )
	end
end

local reload_anims =
{
	["reload"] = true,
	["reload_empty"] = true,
	["ammo_check"] = true
}

local anim_name_to_id =
{
	["reload"] = 1,
	["reload_empty"] = 2
}

local id_to_anim_name =
{
	[1] = "reload",
	[2] = "reload_empty"
}

function P38:sv_n_onReload(anim_id)
	self.network:sendToClients("cl_n_onReload", anim_id)
end

function P38:cl_n_onReload(anim_id)
	if not self.cl_isLocal and self.tool:isEquipped() then
		self:cl_startReloadAnim(id_to_anim_name[anim_id])
	end
end

function P38:cl_startReloadAnim(anim_name)
	setTpAnimation(self.tpAnimations, anim_name, 1.0)
	mgp_toolAnimator_setAnimation(self, anim_name)
end

function P38:client_isGunReloading()
	if self.waiting_for_ammo then
		return true
	end

	local fp_anims = self.fpAnimations
	if fp_anims ~= nil then
		return (reload_anims[fp_anims.currentAnimation] == true)
	end

	return false
end

function P38:cl_initReloadAnim(anim_name)
	if sm.game.getEnableAmmoConsumption() then
		local v_available_ammo = sm.container.totalQuantity(sm.localPlayer.getInventory(), mgp_pistol_ammo)
		if v_available_ammo == 0 then
			sm.gui.displayAlertText("No Ammo", 3)
			return true
		end
	end

	self.waiting_for_ammo = true

	--Start fp and tp animations locally
	setFpAnimation(self.fpAnimations, anim_name, 0.0)
	self:cl_startReloadAnim(anim_name)

	--Send the animation data to all the other clients
	self.network:sendToServer("sv_n_onReload", anim_name_to_id[anim_name])
end

function P38:client_onReload()
	if self.equipped then
		local is_mag_full = (self.ammo_in_mag >= self.mag_capacity)
		if not is_mag_full then
			if not self:client_isGunReloading() and not self.aiming and not self.tool:isSprinting() and self.fireCooldownTimer == 0.0 then
				local cur_anim_name = "reload"
				if self.ammo_in_mag == 0 then
					cur_anim_name = "reload_empty"
				end

				self:cl_initReloadAnim(cur_anim_name)
			end
		end
	end

	return true
end

function P38:sv_n_checkMag()
	self.network:sendToClients("cl_n_checkMag")
end

function P38:cl_n_checkMag()
	local s_tool = self.tool
	if not s_tool:isLocal() and s_tool:isEquipped() then
		self:cl_startCheckMagAnim()
	end
end

function P38:cl_startCheckMagAnim()
	setTpAnimation(self.tpAnimations, "ammo_check", 1.0)
end

function P38:client_onToggle()
	if not self:client_isGunReloading() and not self.aiming and not self.tool:isSprinting() and self.fireCooldownTimer == 0.0 and self.equipped then
		if self.ammo_in_mag > 0 then
			sm.gui.displayAlertText(("P38: Ammo #ffff00%s#ffffff/#ffff00%s#ffffff"):format(self.ammo_in_mag, self.mag_capacity), 2)
			setFpAnimation(self.fpAnimations, "ammo_check", 0.0)

			self:cl_startCheckMagAnim()
			self.network:sendToServer("sv_n_checkMag")

			mgp_toolAnimator_setAnimation(self, "ammo_check")
		else
			sm.gui.displayAlertText("P38: No Ammo. Reloading...", 3)

			self:cl_initReloadAnim("reload_empty")
		end
	end

	return true
end

local _intstate = sm.tool.interactState
function P38.cl_onSecondaryUse( self, state )
	if not self.equipped then return end

	local is_reloading = self:client_isGunReloading()
	local new_state = (state == _intstate.start or state == _intstate.hold) and not is_reloading
	if self.aiming ~= new_state then
		self.aiming = new_state
		self.tpAnimations.animations.idle.time = 0

		self.tool:setMovementSlowDown(self.aiming)
		self:onAim(self.aiming)
		self.network:sendToServer("sv_n_onAim", self.aiming)
	end
end

function P38.client_onEquippedUpdate( self, primaryState, secondaryState )
	mgp_toolAnimator_checkForRecoil(self, primaryState)

	self:cl_onPrimaryUse(primaryState == _intstate.start)

	if secondaryState ~= self.prevSecondaryState then
		self:cl_onSecondaryUse( secondaryState )
		self.prevSecondaryState = secondaryState
	end

	return true, true
end