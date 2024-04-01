dofile( "$GAME_DATA/Scripts/game/AnimationUtil.lua" )
dofile( "$SURVIVAL_DATA/Scripts/util.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/survival_shapes.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/survival_projectiles.lua" )

dofile("ToolAnimator.lua")
dofile("ToolSwimUtil.lua")

local Damage = 145

---@class Magnum : ToolClass
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
Magnum44 = class()
Magnum44.mag_capacity = 6
Magnum44.maxRecoil = 30
Magnum44.recoilAmount = 25
Magnum44.aimRecoilAmount = 15
Magnum44.recoilRecoverySpeed = 0.75

local renderables =
{
	"$CONTENT_DATA/Tools/Renderables/Revolver/Magnum44_Model.rend",
	"$CONTENT_DATA/Tools/Renderables/Revolver/Magnum44_AnimModel.rend"
}

local renderablesTp =
{
	"$CONTENT_DATA/Tools/Renderables/Revolver/char_male_tp_Magnum44.rend",
	"$CONTENT_DATA/Tools/Renderables/Revolver/char_Magnum44_tp_animlist.rend"
}

local renderablesFp =
{
	"$CONTENT_DATA/Tools/Renderables/Revolver/char_male_fp_Magnum44.rend",
	"$CONTENT_DATA/Tools/Renderables/Revolver/char_Magnum44_fp_animlist.rend"
}

sm.tool.preloadRenderables( renderables )
sm.tool.preloadRenderables( renderablesTp )
sm.tool.preloadRenderables( renderablesFp )

function Magnum44:client_initAimVals()
	local cameraWeight, cameraFPWeight = self.tool:getCameraWeights()
	self.aimWeight = math.max( cameraWeight, cameraFPWeight )
end

function Magnum44:server_onCreate()
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

function Magnum44:server_requestAmmo(data, caller)
	self.network:sendToClient(caller, "client_receiveAmmo", self.sv_ammo_counter)
end

function Magnum44:server_updateAmmoCounter(data, caller)
	if data ~= nil or caller ~= nil then return end

	self.storage:save(self.sv_ammo_counter)
end

function Magnum44:client_receiveAmmo(ammo_count)
	self.ammo_in_mag = ammo_count
	self.waiting_for_ammo = nil
end

function Magnum44:client_onCreate()
	self.ammo_in_mag = 0

	self.aimBlendSpeed = 8.0
	self:client_initAimVals()

	self.cl_hammer_cocked = false
	self.waiting_for_ammo = true

	mgp_toolAnimator_initialize(self, "Magnum44")

	self.network:sendToServer("server_requestAmmo")
end

function Magnum44.client_onDestroy(self)
	mgp_toolAnimator_destroy(self)
end

function Magnum44.client_onRefresh( self )
	self:loadAnimations()
end

function Magnum44.loadAnimations( self )
	self.tpAnimations = createTpAnimations(
		self.tool,
		{
			shoot = { "spudgun_shoot", { crouch = "spudgun_crouch_shoot" } },
			aim = { "spudgun_aim", { crouch = "spudgun_crouch_aim" } },
			aimShoot = { "spudgun_aim_shoot", { crouch = "spudgun_crouch_aim_shoot" } },
			idle = { "spudgun_idle" },
			pickup = { "spudgun_pickup", { nextAnimation = "idle" } },
			putdown = { "spudgun_putdown" },
			
			reload_empty = { "TommyGun_tp_empty_reload", { nextAnimation = "idle", duration = 1.0 } },
			reload = { "TommyGun_tp_reload", { nextAnimation = "idle", duration = 1.0 } },
			ammo_check = { "TommyGun_tp_ammo_check", { nextAnimation = "idle", duration = 1.0 } }
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
				equip = { "Magnum_pickup", { nextAnimation = "idle" } },
				unequip = { "Magnum_putdown" },

				idle = { "Magnum_idle", { looping = true } },
				shoot = { "Magnum_shoot", { nextAnimation = "idle" } },

				reload = { "Magnum_reload", { nextAnimation = "idle", duration = 1.0 } },
				reload_empty = { "Magnum_E_reload", { nextAnimation = "idle", duration = 1.0 } },
				cock_hammer = { "Magnum_c_hammer", { nextAnimation = "idle" } },
				cock_hammer_aim = { "Magnum_aim_c_hammer", { nextAnimation = "aimIdle" } },

				ammo_check = { "Magnum_ammo_check", { nextAnimation = "idle", duration = 1.0 } },

				aimInto = { "Magnum_aim_into", { nextAnimation = "aimIdle" } },
				aimExit = { "Magnum_aim_exit", { nextAnimation = "idle", blendNext = 0 } },
				aimIdle = { "Magnum_aim_idle", { looping = true } },
				aimShoot = { "Magnum_aim_shoot", { nextAnimation = "aimIdle"} },

				sprintInto = { "Magnum_sprint_into", { nextAnimation = "sprintIdle",  blendNext = 0.2 } },
				sprintExit = { "Magnum_sprint_exit", { nextAnimation = "idle",  blendNext = 0 } },
				sprintIdle = { "Magnum_sprint_idle", { looping = true } },
			}
		)
	end

	self.normalFireMode = {
		fireCooldown = 0.6,
		spreadCooldown = 1.2,
		spreadIncrement = 20,
		spreadMinAngle = 5,
		spreadMaxAngle = 15,
		fireVelocity = 400.0,

		minDispersionStanding = 0.1,
		minDispersionCrouching = 0.04,

		maxMovementDispersion = 0.4,
		jumpDispersionMultiplier = 2
	}

	self.aimFireMode = {
		fireCooldown = 0.2,
		spreadCooldown = 1.0,
		spreadIncrement = 1.3,
		spreadMinAngle = 0,
		spreadMaxAngle = 5,
		fireVelocity =  400.0,

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

function Magnum44:client_updateAimWeights(dt)
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
function Magnum44:server_spendAmmo(data, player)
	if data ~= nil or player ~= nil then return end

	local v_owner = self.tool:getOwner()
	if v_owner == nil then return end

	local v_inventory = v_owner:getInventory()
	if v_inventory == nil then return end

	local v_available_ammo = sm.container.totalQuantity(v_inventory, mgp_pistol_ammo)
	if v_available_ammo == 0 then return end

	local v_raw_spend_count = math.max(self.mag_capacity - self.sv_ammo_counter, 0)
	local v_spend_count = math.min(v_raw_spend_count, math.min(v_available_ammo, self.mag_capacity))

	sm.container.beginTransaction()
	sm.container.spend(v_inventory, mgp_pistol_ammo, v_spend_count)
	sm.container.endTransaction()

	self.sv_ammo_counter = self.sv_ammo_counter + v_spend_count
	self:server_updateAmmoCounter()
end

function Magnum44:sv_n_trySpendAmmo(data, player)
	local v_owner = self.tool:getOwner()
	if v_owner == nil or v_owner ~= player then return end

	self:server_spendAmmo()
	self.network:sendToClient(v_owner, "client_receiveAmmo", self.sv_ammo_counter)
end

function Magnum44:client_onUpdate(dt)
	mgp_toolAnimator_update(self, dt)

	if self.cl_show_ammo_timer then
		self.cl_show_ammo_timer = self.cl_show_ammo_timer - dt

		if self.cl_show_ammo_timer <= 0.0 then
			self.cl_show_ammo_timer = nil
			if self.tool:isEquipped() then
				sm.gui.displayAlertText(("Magnum44: Ammo #ffff00%s#ffffff/#ffff00%s#ffffff"):format(self.ammo_in_mag, self.mag_capacity), 2)
			end
		end
	end

	if self.aim_timer then
		self.aim_timer = self.aim_timer - dt
		if self.aim_timer <= 0.0 then
			self.aim_timer = nil
		end
	end

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

			if isSprinting and self.fpAnimations.currentAnimation ~= "sprintInto" and self.fpAnimations.currentAnimation ~= "sprintIdle" then
				swapFpAnimation( self.fpAnimations, "sprintExit", "sprintInto", 0.0 )
			elseif not isSprinting and ( self.fpAnimations.currentAnimation == "sprintIdle" or self.fpAnimations.currentAnimation == "sprintInto" ) then
				swapFpAnimation( self.fpAnimations, "sprintInto", "sprintExit", 0.0 )
			end

			if self.aiming and aim_animation_list01[self.fpAnimations.currentAnimation] == nil then
				swapFpAnimation( self.fpAnimations, "aimExit", "aimInto", 0.0 )
			end
			if not self.aiming and aim_animation_list02[self.fpAnimations.currentAnimation] == true then
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
	self.tool:setBlockSprint(self.aiming or self.sprintCooldownTimer > 0.0 or self:client_isGunReloading())

	local playerDir = self.tool:getSmoothDirection()
	local angle = math.asin( playerDir:dot( sm.vec3.new( 0, 0, 1 ) ) ) / ( math.pi / 2 ) + self.cl_recoilAngle
	local linareAngle = playerDir:dot( sm.vec3.new( 0, 0, 1 ) )

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
end

function Magnum44:client_onEquip(animate, is_custom)
	if not is_custom and TSU_IsOwnerSwimming(self) then
		return
	end

	if animate then
		sm.audio.play( "PotatoRifle - Equip", self.tool:getPosition() )
	end

	self.cl_hammer_cocked = false
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
	if self.cl_isLocal then
		self.tool:setFpRenderables(currentRenderablesFp)
	end

	--Load animations before setting them
	self:loadAnimations()

	if not self.tool:isSprinting() then
		mgp_toolAnimator_setAnimation(self, "equip")
	end

	--Set tp and fp animations
	setTpAnimation( self.tpAnimations, "pickup", 0.0001 )
	if self.cl_isLocal then
		swapFpAnimation(self.fpAnimations, "unequip", "equip", 0.2)
	end
end

function Magnum44:client_onUnequip(animate, is_custom)
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
			s_tool:setMovementSlowDown( false )
			s_tool:setBlockSprint( false )
			s_tool:setCrossHairAlpha( 1.0 )
			s_tool:setInteractionTextSuppressed( false )
			s_tool:setDispersionFraction(0.0)

			if self.fpAnimations.currentAnimation ~= "unequip" then
				swapFpAnimation( self.fpAnimations, "equip", "unequip", 0.2 )
			end
		end
	end
end

function Magnum44:sv_n_onAim(aiming)
	self.network:sendToClients( "cl_n_onAim", aiming )
end

function Magnum44:cl_n_onAim(aiming)
	if not self.cl_isLocal and self.tool:isEquipped() then
		self:onAim( aiming )
	end
end

function Magnum44:onAim(aiming)
	self.aiming = aiming
	if self.tpAnimations.currentAnimation == "idle" or self.tpAnimations.currentAnimation == "aim" or self.tpAnimations.currentAnimation == "relax" and self.aiming then
		setTpAnimation( self.tpAnimations, self.aiming and "aim" or "idle", 5.0 )
	end
end

function Magnum44:sv_n_onShoot(dir)
	self.network:sendToClients( "cl_n_onShoot", dir )

	if dir ~= nil and self.sv_ammo_counter > 0 then
		self.sv_ammo_counter = self.sv_ammo_counter - 1
		self:server_updateAmmoCounter()
	end
end

function Magnum44:cl_n_onShoot(dir)
	if not self.cl_isLocal and self.tool:isEquipped() then
		self:onShoot( dir )
	end
end

function Magnum44:onShoot(dir)
	self.tpAnimations.animations.idle.time     = 0
	self.tpAnimations.animations.shoot.time    = 0
	self.tpAnimations.animations.aimShoot.time = 0

	if dir ~= nil then
		setTpAnimation(self.tpAnimations, self.aiming and "aimShoot" or "shoot", 10.0)
		mgp_toolAnimator_setAnimation(self, self.aiming and "shoot_aim" or "shoot")
	else
		mgp_toolAnimator_setAnimation(self, self.aiming and "no_ammo_aim" or "no_ammo")
	end
end

---@return Vec3
function Magnum44:calculateFirePosition()
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

	return GetOwnerPosition(self.tool) + fireOffset
end

function Magnum44:calculateTpMuzzlePos()
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

function Magnum44:calculateFpMuzzlePos()
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

function Magnum44:sv_n_cockHammer()
	self.network:sendToClients("cl_n_cockHammer")
end

function Magnum44:cl_n_cockHammer()
	if not self.cl_isLocal and self.tool:isEquipped() then
		mgp_toolAnimator_setAnimation(self, "cock_the_hammer")
	end
end

local mgp_projectile_potato = sm.uuid.new("bef985da-1271-489f-9c5a-99c08642f982")
function Magnum44.cl_onPrimaryUse(self, state)
	if state ~= sm.tool.interactState.start then return end
	if self:client_isGunReloading() or not self.equipped then return end

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

	if self.cl_hammer_cocked then
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

			dir = dir:rotate( math.rad( 0.6 ), sm.camera.getRight() ) -- 25 m sight calibration

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

			-- Send TP shoot over network and dircly to self
			self:onShoot(1)
			self.network:sendToServer("sv_n_onShoot", 1)

			-- Play FP shoot animation
			setFpAnimation( self.fpAnimations, self.aiming and "aimShoot" or "shoot", 0.0 )
		else
			self:onShoot(nil)
			self.network:sendToServer("sv_n_onShoot", nil)

			self.fireCooldownTimer = 0.3
			sm.audio.play( "PotatoRifle - NoAmmo" )
		end
	else
		self.fireCooldownTimer = 0.4
		self.network:sendToServer("sv_n_cockHammer")

		if self.aiming then
			setFpAnimation(self.fpAnimations, "cock_hammer_aim", 0.0)
			mgp_toolAnimator_setAnimation(self, "cock_the_hammer_aim")
		else
			setFpAnimation(self.fpAnimations, "cock_hammer", 0.0)
			mgp_toolAnimator_setAnimation(self, "cock_the_hammer")
		end
	end

	self.cl_hammer_cocked = not self.cl_hammer_cocked
end

local reload_anims =
{
	["reload"]       = true,
	["reload_empty"] = true,
	["ammo_check"]   = true
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

function Magnum44:sv_n_onReload(anim_id)
	self.network:sendToClients("cl_n_onReload", anim_id)
end

function Magnum44:cl_n_onReload(anim_id)
	if not self.cl_isLocal and self.tool:isEquipped() then
		self:cl_startReloadAnim(anim_id)
	end
end

function Magnum44:cl_startReloadAnim(anim_name)
	setTpAnimation(self.tpAnimations, "reload", 1.0)
	mgp_toolAnimator_setAnimation(self, anim_name)
end

function Magnum44:client_isGunReloading()
	if self.waiting_for_ammo then
		return true
	end

	local fp_anims = self.fpAnimations
	if fp_anims ~= nil then
		return (reload_anims[fp_anims.currentAnimation] == true)
	end

	return false
end

function Magnum44:cl_initReloadAnim(anim_id)
	if sm.game.getEnableAmmoConsumption() then
		local v_available_ammo = sm.container.totalQuantity(sm.localPlayer.getInventory(), mgp_pistol_ammo)
		if v_available_ammo == 0 then
			sm.gui.displayAlertText("No Ammo", 3)
			return true
		end
	end

	self.waiting_for_ammo = true

	local anim_name = ammo_count_to_anim_name[anim_id]

	setFpAnimation(self.fpAnimations, (anim_id == 0) and "reload_empty" or "reload", 0.0)
	self:cl_startReloadAnim(anim_name)

	--Send the animation data to all the other clients
	self.network:sendToServer("sv_n_onReload", anim_name)
end

function Magnum44:client_onReload()
	if self.equipped then
		local is_mag_full = (self.ammo_in_mag == self.mag_capacity)
		if not is_mag_full then
			if not self:client_isGunReloading() and not self.aiming and not self.tool:isSprinting() and self.fireCooldownTimer == 0.0 then
				self:cl_initReloadAnim(self.ammo_in_mag)
			end
		end
	end

	return true
end

function Magnum44:sv_n_checkMag()
	self.network:sendToClients("cl_n_checkMag")
end

function Magnum44:cl_n_checkMag()
	local s_tool = self.tool
	if not s_tool:isLocal() and s_tool:isEquipped() then
		self:cl_startCheckMagAnim()
	end
end

function Magnum44:cl_startCheckMagAnim()
	setTpAnimation(self.tpAnimations, "ammo_check", 1.0)
	mgp_toolAnimator_setAnimation(self, "ammo_check")
end

function Magnum44:client_onToggle()
	if not self:client_isGunReloading() and not self.aiming and not self.tool:isSprinting() and self.fireCooldownTimer == 0.0 and self.equipped then
		if self.ammo_in_mag > 0 then
			self.cl_show_ammo_timer = 0.5

			setFpAnimation(self.fpAnimations, "ammo_check", 0.0)

			self:cl_startCheckMagAnim()
			self.network:sendToServer("sv_n_checkMag")
		else
			sm.gui.displayAlertText("Magnum44: No Ammo. Reloading...", 3)
			self:cl_initReloadAnim(0)
		end
	end

	return true
end

local _intstate = sm.tool.interactState
function Magnum44:cl_onSecondaryUse(state)
	if not self.equipped then return end

	local is_reloading = self:client_isGunReloading() or (self.aim_timer ~= nil)
	local new_state = (state == _intstate.start or state == _intstate.hold) and not is_reloading
	if self.aiming ~= new_state then
		self.aiming = new_state
		self.tpAnimations.animations.idle.time = 0

		self.tool:setMovementSlowDown(self.aiming)
		self:onAim(self.aiming)
		self.network:sendToServer("sv_n_onAim", self.aiming)
	end
end

function Magnum44:client_onEquippedUpdate(primaryState, secondaryState)
	mgp_toolAnimator_checkForRecoil(self, primaryState)

	if primaryState ~= self.prevPrimaryState then
		self:cl_onPrimaryUse(primaryState)
		self.prevPrimaryState = primaryState
	end

	if secondaryState ~= self.prevSecondaryState then
		self:cl_onSecondaryUse( secondaryState )
		self.prevSecondaryState = secondaryState
	end

	return true, true
end
