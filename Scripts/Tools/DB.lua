dofile( "$GAME_DATA/Scripts/game/AnimationUtil.lua" )
dofile( "$SURVIVAL_DATA/Scripts/util.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/survival_shapes.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/survival_projectiles.lua" )

dofile("ToolAnimator.lua")
dofile("ToolSwimUtil.lua")

local Damage = 16

---@class DoubleBarrel : ToolClass
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
DB = class()
DB.mag_capacity = 2

local renderables =
{
	"$CONTENT_DATA/Tools/Renderables/DB/DB_Base.rend",
	"$CONTENT_DATA/Tools/Renderables/DB/DB_Anim.rend"
}

local renderablesTp =
{
	"$CONTENT_DATA/Tools/Renderables/DB/char_tp_DB_anim.rend",
	"$CONTENT_DATA/Tools/Renderables/DB/DB_tp_offset.rend"
}

local renderablesFp =
{
	"$CONTENT_DATA/Tools/Renderables/DB/char_fp_DB_anim.rend",
	"$CONTENT_DATA/Tools/Renderables/DB/DB_fp_offset.rend"
}

sm.tool.preloadRenderables( renderables )
sm.tool.preloadRenderables( renderablesTp )
sm.tool.preloadRenderables( renderablesFp )

function DB:client_initAimVals()
	local cameraWeight, cameraFPWeight = self.tool:getCameraWeights()
	self.aimWeight = math.max( cameraWeight, cameraFPWeight )
end

function DB:server_onCreate()
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

function DB:server_requestAmmo(data, caller)
	self.network:sendToClient(caller, "client_receiveAmmo", self.sv_ammo_counter)
end

function DB:server_updateAmmoCounter(data, caller)
	if data ~= nil or caller ~= nil then return end

	self.storage:save(self.sv_ammo_counter)
end

function DB:client_receiveAmmo(ammo_count)
	self.ammo_in_mag = ammo_count
	self.waiting_for_ammo = nil
end

function DB:client_onCreate()
	self.ammo_in_mag = 0

	self.waiting_for_ammo = true

	self.aimBlendSpeed = 3.0
	self:client_initAimVals()

	mgp_toolAnimator_initialize(self, "DB")

	self.network:sendToServer("server_requestAmmo")
end

function DB.client_onDestroy(self)
	mgp_toolAnimator_destroy(self)
end

function DB.client_onRefresh( self )
	self:loadAnimations()
end

function DB.loadAnimations( self )
	self.tpAnimations = createTpAnimations(
		self.tool,
		{
			shoot = { "spudgun_shoot1", { nextAnimation = "idle" } },
			shoot_2 = { "spudgun_shoot2", { nextAnimation = "idle" } },
			crouch_shoot = { "spudgun_crouch_shoot", { nextAnimation = "idle" } },

			idle = { "spudgun_idle" },
			pickup = { "spudgun_pickup", { nextAnimation = "idle" } },
			putdown = { "spudgun_putdown" },

			reload_empty = { "DB_tp_empty_reload", { nextAnimation = "idle", duration = 1.0 } },
			reload = { "DB_tp_reload", { nextAnimation = "idle", duration = 1.0 } },
			ammo_check = { "DB_tp_ammo_check", { nextAnimation = "idle", duration = 1.0 } }
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
				equip = { "DB_pickup", { nextAnimation = "idle" } },
				unequip = { "DB_putdown" },

				idle = { "DB_idle_1", { nextAnimation = "idle" } },
				inspect = { "DB_idle_2", { nextAnimation = "idle" } },

				shoot = { "DB_shoot_1", { nextAnimation = "idle" } },
				shoot_2 = { "DB_shoot_2", { nextAnimation = "idle" } },

				reload = { "DB_reload_1", { nextAnimation = "idle", duration = 1.0 } },
				reload_empty = { "DB_reload_0", { nextAnimation = "idle", duration = 1.0 } },

				ammo_check = { "DB_ammo_check", { nextAnimation = "idle", duration = 1.0 } },

				sprintInto = { "DB_sprint_into", { nextAnimation = "sprintIdle",  blendNext = 0.2 } },
				sprintExit = { "DB_sprint_exit", { nextAnimation = "idle",  blendNext = 0 } },
				sprintIdle = { "DB_sprint_idle", { looping = true } },
			}
		)
	end

	self.normalFireMode = {
		fireCooldown = 0.1,
		spreadCooldown = 0.2,
		spreadIncrement = 3,
		spreadMinAngle = 1,
		spreadMaxAngle = 2,
		fireVelocity = 180.0,

		minDispersionStanding = 0.1,
		minDispersionCrouching = 0.04,

		maxMovementDispersion = 0.4,
		jumpDispersionMultiplier = 2
	}

	self.aimFireMode = {
		fireCooldown = 0.2,
		spreadCooldown = 0.3,
		spreadIncrement = 3,
		spreadMinAngle = 1,
		spreadMaxAngle = 2,
		fireVelocity = 180.0,

		minDispersionStanding = 0.01,
		minDispersionCrouching = 0.01,

		maxMovementDispersion = 0.4,
		jumpDispersionMultiplier = 2
	}

	self.fireCooldownTimer = 1.0
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

local mgp_shotgun_ammo = sm.uuid.new("a2fc1d9c-7c00-4d29-917b-6b9e26ea32a2")
function DB:server_spendAmmo(data, player)
	if data ~= nil or player ~= nil then return end

	local v_owner = self.tool:getOwner()
	if v_owner == nil then return end

	local v_inventory = v_owner:getInventory()
	if v_inventory == nil then return end

	local v_available_ammo = sm.container.totalQuantity(v_inventory, mgp_shotgun_ammo)
	if v_available_ammo == 0 then return end

	local v_raw_spend_count = math.max(self.mag_capacity - self.sv_ammo_counter, 0)
	local v_spend_count = math.min(v_raw_spend_count, math.min(v_available_ammo, self.mag_capacity))

	sm.container.beginTransaction()
	sm.container.spend(v_inventory, mgp_shotgun_ammo, v_spend_count)
	sm.container.endTransaction()

	self.sv_ammo_counter = self.sv_ammo_counter + v_spend_count
	self:server_updateAmmoCounter()
end

function DB:sv_n_trySpendAmmo(data, player)
	local v_owner = self.tool:getOwner()
	if v_owner == nil or v_owner ~= player then return end

	self:server_spendAmmo()
	self.network:sendToClient(v_owner, "client_receiveAmmo", self.sv_ammo_counter)
end

function DB:client_onUpdate(dt)
	mgp_toolAnimator_update(self, dt)

	if self.cl_show_ammo_timer then
		self.cl_show_ammo_timer = self.cl_show_ammo_timer - dt

		if self.cl_show_ammo_timer <= 0.0 then
			self.cl_show_ammo_timer = nil
			if self.tool:isEquipped() then
				sm.gui.displayAlertText(("DB: Ammo #ffff00%s#ffffff/#ffff00%s#ffffff"):format(self.ammo_in_mag, self.mag_capacity), 2)
			end
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
					self.network:sendToServer("sv_n_trySpendAmmo")
				end
			end

			if isSprinting and self.fpAnimations.currentAnimation ~= "sprintInto" and self.fpAnimations.currentAnimation ~= "sprintIdle" then
				swapFpAnimation( self.fpAnimations, "sprintExit", "sprintInto", 0.0 )
			elseif not isSprinting and ( self.fpAnimations.currentAnimation == "sprintIdle" or self.fpAnimations.currentAnimation == "sprintInto" ) then
				swapFpAnimation( self.fpAnimations, "sprintInto", "sprintExit", 0.0 )
			end
		end

		updateFpAnimations( self.fpAnimations, self.equipped, dt )
	end

	TSU_OnUpdate(self)

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
	self.tool:setBlockSprint(self.sprintCooldownTimer > 0.0 or self:client_isGunReloading())

	local playerDir = self.tool:getSmoothDirection()
	local angle = math.asin( playerDir:dot( sm.vec3.new( 0, 0, 1 ) ) ) / ( math.pi / 2 )

	local crouchWeight = self.tool:isCrouching() and 1.0 or 0.0
	local normalWeight = 1.0 - crouchWeight

	local totalWeight = 0.0
	for name, animation in pairs( self.tpAnimations.animations ) do
		animation.time = animation.time + dt

		if name == self.tpAnimations.currentAnimation then
			animation.weight = math.min( animation.weight + ( self.tpAnimations.blendSpeed * dt ), 1.0 )

			if animation.time >= animation.info.duration - self.blendTime then
				if ( name == "shoot1" or name == "crouch_shoot" ) then
					setTpAnimation( self.tpAnimations, "idle", 0.1 )
				elseif name == "pickup" then
					setTpAnimation( self.tpAnimations, "idle", 0.001 )
				elseif ( name == "reload" or name == "reload_empty" ) then
					setTpAnimation( self.tpAnimations, "idle", 2 )
				elseif  name == "ammo_check" then
					setTpAnimation( self.tpAnimations, "idle", 3 )
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
	if ( ( ( isAnyOf( self.tpAnimations.currentAnimation, { "aimInto", "aim", "shoot" } ) and ( relativeMoveDirection:length() > 0 or isCrouching) ) ) and not isSprinting ) then
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

function DB:client_onEquip(animate, is_custom)
	if not is_custom and TSU_IsOwnerSwimming(self) then
		return
	end

	if animate then
		sm.audio.play( "PotatoRifle - Equip", self.tool:getPosition() )
	end

	self.wantEquipped = true
	local cameraWeight, cameraFPWeight = self.tool:getCameraWeights()
	self.aimWeight = math.max( cameraWeight, cameraFPWeight )
	self.jointWeight = 0.0

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
end

function DB:client_onUnequip(animate, is_custom)
	if not is_custom and TSU_IsOwnerSwimming(self) then
		return
	end

	self.waiting_for_ammo = nil
	self.wantEquipped = false
	self.equipped = false
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

function DB:sv_n_onShoot(doubleShot)
	self.network:sendToClients("cl_n_onShoot", doubleShot)

	if self.sv_ammo_counter > 0 then
		local v_to_spend = doubleShot and 2 or 1

		if self.sv_ammo_counter >= v_to_spend then
			self.sv_ammo_counter = self.sv_ammo_counter - v_to_spend
			self:server_updateAmmoCounter()
		end
	end
end

function DB:cl_n_onShoot(doubleShot)
	if not self.tool:isLocal() and self.tool:isEquipped() then
		self:onShoot(doubleShot)
	end
end

function DB:onShoot(doubleShot)
	local v_anim_name = doubleShot and "shoot_2" or "shoot"
	mgp_toolAnimator_setAnimation(self, v_anim_name)

	if self.tool:isCrouching() then
		setTpAnimation(self.tpAnimations, "crouch_shoot", 1.0)
	else
		setTpAnimation(self.tpAnimations, v_anim_name, 1.0)
	end
end

local mgp_projectile_potato = sm.uuid.new("228fb03c-9b81-4460-b841-5fdc2eea3596")
local mgp_projectile_powerful = sm.uuid.new("35588452-1e08-46e8-aaf1-e8abb0cf7692")
function DB:cl_onPrimaryUse(is_double_shot)
	if self:client_isGunReloading() then return end

	local v_toolOwner = self.tool:getOwner()
	if not v_toolOwner then
		return
	end

	local v_ownerChar = v_toolOwner.character
	if not (v_ownerChar and sm.exists(v_ownerChar)) then
		return
	end

	if self.fireCooldownTimer <= 0.0 then
		if self.tool:isSprinting() then
			return
		end

		local ammo_count = is_double_shot and 1 or 0
		local ammo_to_consume = ammo_count + 1

		if self.ammo_in_mag > ammo_count then
			self.ammo_in_mag = self.ammo_in_mag - ammo_to_consume

			local dir = sm.camera.getDirection()
			local firePos = nil
			if self.tool:isInFirstPersonView() then
				firePos = self.tool:getFpBonePos("pejnt_barrel")
			else
				firePos = self.tool:getTpBonePos("pejnt_barrel")
			end

			local fireMode = self.normalFireMode

			local proj_type = is_double_shot and mgp_projectile_powerful or mgp_projectile_potato
			sm.projectile.projectileAttack(proj_type, Damage, firePos, dir * fireMode.fireVelocity, v_toolOwner)

			-- Timers
			self.fireCooldownTimer = is_double_shot and 1.0 or 0.5
			self.spreadCooldownTimer = math.min( self.spreadCooldownTimer + fireMode.spreadIncrement, fireMode.spreadCooldown )
			self.sprintCooldownTimer = self.sprintCooldown

			-- Send TP shoot over network and dircly to self
			self:onShoot(is_double_shot)
			self.network:sendToServer("sv_n_onShoot", is_double_shot)

			-- Play FP shoot animation
			setFpAnimation( self.fpAnimations, is_double_shot and "shoot_2" or "shoot", 0.0 )
		else
			self.fireCooldownTimer = 0.3
			sm.audio.play( "PotatoRifle - NoAmmo" )
		end
	end
end

local reload_anims =
{
	["cock_hammer_aim"] = true,
	["ammo_check"     ] = true,
	["cock_hammer"    ] = true,
	["reload"         ] = true,
	["reload_empty"   ] = true
}

local ammo_count_to_anim_name =
{
	[0] = "reload_empty",
	[1] = "reload"
}

function DB:sv_n_onReload(anim_id)
	self.network:sendToClients("cl_n_onReload", anim_id)
end

function DB:cl_n_onReload(anim_id)
	if not self.tool:isLocal() and self.tool:isEquipped() then
		self:cl_startReloadAnim(ammo_count_to_anim_name[anim_id])
	end
end

function DB:cl_startReloadAnim(anim_name)
	setTpAnimation(self.tpAnimations, anim_name, 1.0)
	mgp_toolAnimator_setAnimation(self, anim_name)
end

function DB:client_isGunReloading()
	if self.waiting_for_ammo then
		return true
	end

	local fp_anims = self.fpAnimations
	if fp_anims ~= nil then
		return (reload_anims[fp_anims.currentAnimation] == true)
	end

	return false
end

function DB:cl_initReloadAnim(anim_id)
	if sm.game.getEnableAmmoConsumption() then
		local v_available_ammo = sm.container.totalQuantity(sm.localPlayer.getInventory(), mgp_shotgun_ammo)
		if v_available_ammo == 0 then
			sm.gui.displayAlertText("No Ammo", 3)
			return true
		end
	end

	self.waiting_for_ammo = true

	local anim_name = ammo_count_to_anim_name[anim_id]

	setFpAnimation(self.fpAnimations, anim_name, 0.0)
	self:cl_startReloadAnim(anim_name)

	--Send the animation data to all the other clients
	self.network:sendToServer("sv_n_onReload", anim_id)
end

function DB:client_onReload()
	if self.equipped and self.ammo_in_mag ~= self.mag_capacity then
		if not self:client_isGunReloading() and not self.tool:isSprinting() and self.fireCooldownTimer == 0.0 then
			self:cl_initReloadAnim(self.ammo_in_mag)
		end
	end

	return true
end

function DB:sv_n_checkMag()
	self.network:sendToClients("cl_n_checkMag")
end

function DB:cl_n_checkMag()
	local s_tool = self.tool
	if not s_tool:isLocal() and s_tool:isEquipped() then
		self:cl_startCheckMagAnim()
	end
end

function DB:cl_startCheckMagAnim()
	setTpAnimation(self.tpAnimations, "ammo_check", 1.0)
	mgp_toolAnimator_setAnimation(self, "ammo_check")
end

function DB:client_onToggle()
	if not self:client_isGunReloading() and not self.tool:isSprinting() and self.fireCooldownTimer == 0.0 and self.equipped then
		if self.ammo_in_mag > 0 then
			self.cl_show_ammo_timer = 0.3

			setFpAnimation(self.fpAnimations, "ammo_check", 0.0)

			self:cl_startCheckMagAnim()
			self.network:sendToServer("sv_n_checkMag")
		else
			sm.gui.displayAlertText("DB: No Ammo. Reloading...", 3)
			self:cl_initReloadAnim(0)
		end
	end

	return true
end

function DB:client_onEquippedUpdate(primaryState, secondaryState, f)
	if self.equipped then
		if primaryState == sm.tool.interactState.start then
			self:cl_onPrimaryUse(false)
		end

		if secondaryState == sm.tool.interactState.start then
			self:cl_onPrimaryUse(true)
		end

		if f and not self:client_isGunReloading() and not self.tool:isSprinting() and self.fpAnimations.currentAnimation ~= "inspect" then
			self.network:sendToServer("sv_onInspect")
		end
	end

	return true, true
end

function DB:sv_onInspect()
	self.network:sendToClients("cl_onInspect")
end

function DB:cl_onInspect()
	--setTpAnimation(self.tpAnimations, "inspect", 1)
	if self.tool:isLocal() then
		setFpAnimation(self.fpAnimations, "inspect", 0.0)
	end
end