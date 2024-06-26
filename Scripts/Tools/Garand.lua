dofile( "$GAME_DATA/Scripts/game/AnimationUtil.lua" )
dofile( "$SURVIVAL_DATA/Scripts/util.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/survival_shapes.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/survival_projectiles.lua" )

dofile("ToolAnimator.lua")
dofile("ToolSwimUtil.lua")
dofile("$CONTENT_DATA/Scripts/Utils/ToolUtils.lua")

local Damage = 65

---@class Garand : ToolClass
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
---@field scope_hud GuiInterface
Garand = class()
Garand.mag_capacity = 8
Garand.maxRecoil = 30
Garand.recoilAmount = 10
Garand.aimRecoilAmount = 8
Garand.recoilRecoverySpeed = 1
Garand.aimFovTp = 15
Garand.aimFovFp = 20

local renderables =
{
	"$CONTENT_DATA/Tools/Renderables/Garand/Garand_Base.rend",
	"$CONTENT_DATA/Tools/Renderables/Garand/Garand_Anim.rend"
}

local renderablesTp =
{
	"$CONTENT_DATA/Tools/Renderables/Garand/char_male_tp_Garand.rend",
	"$CONTENT_DATA/Tools/Renderables/Garand/char_Garand_tp_offset.rend"
}

local renderablesFp =
{
	"$CONTENT_DATA/Tools/Renderables/Garand/char_male_fp_Garand.rend",
	"$CONTENT_DATA/Tools/Renderables/Garand/char_Garand_fp_offset.rend",
	"$CONTENT_DATA/Tools/Renderables/char_male_fp_recoil.rend"
}

sm.tool.preloadRenderables( renderables )
sm.tool.preloadRenderables( renderablesTp )
sm.tool.preloadRenderables( renderablesFp )

local garand_action_block_anims =
{
	["ammo_check" ] = true,
	["cock_hammer"] = true,

	["reload"] = true,
	["reload_gt"] = true,

	["equip"] = true,
	["aimExit"] = true,

	["sprintInto"] = true,
	["sprintIdle"] = true,
	["sprintExit"] = true
}

local garand_aim_block_anims =
{
	["ammo_check" ] = true,
	["cock_hammer"] = true,

	["reload"] = true,
	["reload_gt"] = true,

	["sprintInto"] = true,
	["sprintIdle"] = true,
	["sprintExit"] = true
}

local garand_sprint_block_anims =
{
	["ammo_check" ] = true,
	["cock_hammer"] = true,

	["reload"] = true,
	["reload_gt"] = true,
	["aimExit"] = true,
	["sprintExit"] = true
}

local garand_obstacle_block_anims =
{
	["ammo_check"] = true,
	["reload"    ] = true,
	["reload_gt" ] = true,
	["equip"     ] = true,
	["aimExit"   ] = true
}

function Garand:client_initAimVals()
	local cameraWeight, cameraFPWeight = self.tool:getCameraWeights()
	self.aimWeight = math.max( cameraWeight, cameraFPWeight )
	self.aimWeightFp = self.aimWeight
end

function Garand:server_onCreate()
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

function Garand:server_requestAmmo(data, caller)
	self.network:sendToClient(caller, "client_receiveAmmo", self.sv_ammo_counter)
end

function Garand:server_updateAmmoCounter(data, caller)
	if data ~= nil or caller ~= nil then return end

	self.storage:save(self.sv_ammo_counter)
end

function Garand:client_receiveAmmo(ammo_count)
	self.ammo_in_mag = ammo_count
	self.waiting_for_ammo = nil
end

function Garand:client_onCreate()
	self.ammo_in_mag = 0

	self:client_initAimVals()
	self.aimBlendSpeed = 3.0

	self.waiting_for_ammo = true

	mgp_toolAnimator_initialize(self, "Garand")

	self.network:sendToServer("server_requestAmmo")
end

function Garand:client_onDestroy()
	mgp_toolAnimator_destroy(self)
end

function Garand:client_onRefresh()
	self:loadAnimations()
end

function Garand:loadAnimations()
	self.tpAnimations = createTpAnimations(
		self.tool,
		{
			shoot = { "spudgun_shoot", { crouch = "spudgun_crouch_shoot" } },
			aim = { "spudgun_aim", { crouch = "spudgun_crouch_aim" } },
			aimShoot = { "spudgun_aim_shoot", { crouch = "spudgun_crouch_aim_shoot" } },
			idle = { "spudgun_idle" },
			pickup = { "spudgun_pickup", { nextAnimation = "idle" } },
			putdown = { "spudgun_putdown" },

			reload = { "Garand_reload", { nextAnimation = "idle" } },
			reload_gt = { "Garand_reload_GT", { nextAnimation = "idle" } },

			ammo_check = { "Garand_ammo_check", { nextAnimation = "idle", duration = 1.0 } }
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
				equip = { "Gun_pickup", { nextAnimation = "idle" } },
				unequip = { "Gun_putdown" },
				aim_anim = { "Gun_putdown" },

				idle = { "Gun_idle", { looping = true } },
				shoot = { "Gun_shoot", { nextAnimation = "idle" } },

				reload = { "Reload", { nextAnimation = "idle" } },
				reload_gt = { "ReloadGT", { nextAnimation = "idle" } },

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
		fireCooldown = 0.18,
		spreadCooldown = 0.05,
		spreadIncrement = 1,
		spreadMinAngle = 1.1,
		spreadMaxAngle = 3.6,
		fireVelocity = 550.0,

		minDispersionStanding = 0.1,
		minDispersionCrouching = 0.04,

		maxMovementDispersion = 0.4,
		jumpDispersionMultiplier = 2
	}

	self.aimFireMode = {
		fireCooldown = 0.18,
		spreadCooldown = 0.01,
		spreadIncrement = 1,
		spreadMinAngle = 0.1,
		spreadMaxAngle = 1.0,
		fireVelocity = 550.0,

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
	["reload_gt"] = true
}

local aim_animation_list01 =
{
	["aimInto"]         = true,
	["aimIdle"]         = true,
	["aimShoot"]        = true
}

local aim_animation_list02 =
{
	["aimInto"]  = true,
	["aimIdle"]  = true,
	["aimShoot"] = true
}

function Garand:client_updateAimWeights(dt)
	local weight_blend = 1 - math.pow( 1 - 1 / self.aimBlendSpeed, dt * 60 )

	-- Camera update
	local bobbingFp = 1
	if self.aiming then
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
	self.tool:updateFpCamera( 27.0, sm.vec3.new( 0.0, 0.0, 0.0 ), self.aimWeightFp, bobbingFp )
end

local mgp_sniper_ammo = sm.uuid.new("295481d0-910a-48d4-a04a-e1bf1290e510")
function Garand:server_spendAmmo(data, player)
	if data ~= nil or player ~= nil then return end

	local v_owner = self.tool:getOwner()
	if v_owner == nil then return end

	local v_inventory = v_owner:getInventory()
	if v_inventory == nil then return end

	local v_available_ammo = sm.container.totalQuantity(v_inventory, mgp_sniper_ammo)
	if v_available_ammo == 0 then return end

	local v_raw_spend_count = math.max(self.mag_capacity - self.sv_ammo_counter, 0)
	local v_spend_count = math.min(v_raw_spend_count, math.min(v_available_ammo, self.mag_capacity))

	sm.container.beginTransaction()
	sm.container.spend(v_inventory, mgp_sniper_ammo, v_spend_count)
	sm.container.endTransaction()

	self.sv_ammo_counter = self.sv_ammo_counter + v_spend_count
	self:server_updateAmmoCounter()
end

function Garand:sv_n_trySpendAmmo(data, player)
	local v_owner = self.tool:getOwner()
	if v_owner == nil or v_owner ~= player then return end

	self:server_spendAmmo()
	self.network:sendToClient(v_owner, "client_receiveAmmo", self.sv_ammo_counter)
end

function Garand:client_onUpdate(dt)
	mgp_toolAnimator_update(self, dt)

	if self.cl_show_ammo_timer then
		self.cl_show_ammo_timer = self.cl_show_ammo_timer - dt

		if self.cl_show_ammo_timer <= 0.0 then
			self.cl_show_ammo_timer = nil
			if self.tool:isEquipped() then
				sm.gui.displayAlertText(("Garand: Ammo #ffff00%s#ffffff/#ffff00%s#ffffff"):format(self.ammo_in_mag, self.mag_capacity), 2)
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
			local hit, result = sm.localPlayer.getRaycast(1.5)
			if hit and not self:client_isGunReloading(garand_obstacle_block_anims) then
				local v_cur_anim = self.fpAnimations.currentAnimation
				if v_cur_anim ~= "sprintInto" and v_cur_anim ~= "sprintExit" then
					if v_cur_anim == "sprintIdle" then
						self.fpAnimations.animations.sprintIdle.time = 0
					else
						swapFpAnimation(self.fpAnimations, "sprintExit", "sprintInto", 0.0)
					end
				end
			else
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

				if isSprinting and cur_anim_cache ~= "sprintInto" and cur_anim_cache ~= "sprintIdle" then
					swapFpAnimation( self.fpAnimations, "sprintExit", "sprintInto", 0.0 )
				elseif not isSprinting and ( cur_anim_cache == "sprintIdle" or cur_anim_cache == "sprintInto" ) then
					swapFpAnimation( self.fpAnimations, "sprintInto", "sprintExit", 0.0 )
				end

				if cur_anim_cache ~= "aim_anim" then
					if self.aiming and aim_animation_list01[cur_anim_cache] == nil then
						swapFpAnimation( self.fpAnimations, "aimExit", "aimInto", 0.0 )
					end
					if not self.aiming and aim_animation_list02[cur_anim_cache] == true then
						swapFpAnimation( self.fpAnimations, "aimInto", "aimExit", 0.0 )
					end
				end
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
	self.tool:setBlockSprint(self.aiming or self.sprintCooldownTimer > 0.0 or self:client_isGunReloading(garand_sprint_block_anims))

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
				elseif ( name == "reload" or name == "reload_gt" ) then
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

function Garand:client_onEquip(animate, is_custom)
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

	--Set tp and fp animations
	setTpAnimation( self.tpAnimations, "pickup", 0.0001 )
	if self.cl_isLocal then
		swapFpAnimation(self.fpAnimations, "unequip", "equip", 0.2)
	end

	if self.ammo_in_mag <= 0 then
		mgp_toolAnimator_setAnimation(self, "last_shot_equip")
	end
end

function Garand:client_onUnequip(animate, is_custom)
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
			setTpAnimation(self.tpAnimations, "putdown")
		end

		if s_tool:isLocal() then
			s_tool:setDispersionFraction(0.0)
			s_tool:setMovementSlowDown( false )
			s_tool:setBlockSprint( false )
			s_tool:setCrossHairAlpha( 1.0 )
			s_tool:setInteractionTextSuppressed( false )

			if self.fpAnimations.currentAnimation ~= "unequip" then
				swapFpAnimation( self.fpAnimations, "equip", "unequip", 0.2 )
			end
		end
	end
end

function Garand:sv_n_onAim(aiming)
	self.network:sendToClients( "cl_n_onAim", aiming )
end

function Garand:cl_n_onAim(aiming)
	if not self.cl_isLocal and self.tool:isEquipped() then
		self:onAim( aiming )
	end
end

function Garand:onAim(aiming)
	self.aiming = aiming
	if self.tpAnimations.currentAnimation == "idle" or self.tpAnimations.currentAnimation == "aim" or self.tpAnimations.currentAnimation == "relax" and self.aiming then
		setTpAnimation( self.tpAnimations, self.aiming and "aim" or "idle", 5.0 )
	end
end

function Garand:sv_n_onShoot(ammo_in_mag)
	self.network:sendToClients("cl_n_onShoot", ammo_in_mag)

	if ammo_in_mag ~= nil and self.sv_ammo_counter > 0 then
		self.sv_ammo_counter = self.sv_ammo_counter - 1
		self:server_updateAmmoCounter()
	end
end

function Garand:cl_n_onShoot(ammo_in_mag)
	if not self.cl_isLocal and self.tool:isEquipped() then
		self:onShoot(ammo_in_mag)
	end
end

function Garand:onShoot(ammo_in_mag)
	if ammo_in_mag ~= nil then
		self.tpAnimations.animations.idle.time     = 0
		self.tpAnimations.animations.shoot.time    = 0
		self.tpAnimations.animations.aimShoot.time = 0

		local anim = self.aiming and "aimShoot" or "shoot"
		setTpAnimation(self.tpAnimations, anim, 10.0)
		mgp_toolAnimator_setAnimation(self, ammo_in_mag == 0 and "last_shot" or anim)
	else
		mgp_toolAnimator_setAnimation(self, self.aiming and "no_ammo_aim" or "no_ammo")
	end
end

function Garand:cl_getFirePosition()
	local v_direction = mgp_tool_getToolDir(self)

	if not self.tool:isInFirstPersonView() then
		return self.tool:getTpBonePos("pejnt_barrel"), v_direction
	end

	return self.tool:getFpBonePos("pejnt_barrel"), v_direction
end

local mgp_projectile_potato = sm.uuid.new("033cea84-d6ad-4eb9-82dd-f576b60c1e70")
function Garand:cl_onPrimaryUse(state)
	if state ~= sm.tool.interactState.start then return end
	if self:client_isGunReloading(garand_action_block_anims) or not self.equipped then return end

	local v_toolOwner = self.tool:getOwner()
	if not v_toolOwner then
		return
	end

	local v_toolChar = v_toolOwner.character
	if not (v_toolChar and sm.exists(v_toolChar)) then
		return
	end

	if self.fireCooldownTimer > 0.0 or self.tool:isSprinting() then
		return
	end

	if self.ammo_in_mag > 0 then
		self.ammo_in_mag = self.ammo_in_mag - 1

		local fireMode = self.aiming and self.aimFireMode or self.normalFireMode
		local firePos, dir = self:cl_getFirePosition()

		-- Spread
		local recoilDispersion = 1.0 - ( math.max(fireMode.minDispersionCrouching, fireMode.minDispersionStanding ) + fireMode.maxMovementDispersion )

		local spreadFactor = fireMode.spreadCooldown > 0.0 and clamp( self.spreadCooldownTimer / fireMode.spreadCooldown, 0.0, 1.0 ) or 0.0
		spreadFactor = clamp( self.movementDispersion + spreadFactor * recoilDispersion, 0.0, 1.0 )
		local spreadDeg =  fireMode.spreadMinAngle + ( fireMode.spreadMaxAngle - fireMode.spreadMinAngle ) * spreadFactor

		dir = sm.noise.gunSpread( dir, spreadDeg )
		sm.projectile.projectileAttack( mgp_projectile_potato, Damage, firePos, dir * fireMode.fireVelocity, v_toolOwner )

		-- Timers
		self.fireCooldownTimer = fireMode.fireCooldown
		self.spreadCooldownTimer = math.min( self.spreadCooldownTimer + fireMode.spreadIncrement, fireMode.spreadCooldown )
		self.sprintCooldownTimer = self.sprintCooldown

		-- Send TP shoot over network and directly to self
		self:onShoot(self.ammo_in_mag)
		self.network:sendToServer("sv_n_onShoot", 1)

		sm.camera.setShake(0.025)

		-- Play FP shoot animation
		setFpAnimation( self.fpAnimations, self.aiming and "aimShoot" or "shoot", 0.0 )
	else
		self:onShoot()
		self.network:sendToServer("sv_n_onShoot")

		self.fireCooldownTimer = 0.3
		sm.audio.play( "event:/vehicle/triggers/trigger_toggle_off" )
	end
end

function Garand:sv_n_onReload(is_garand_thumb)
	self.network:sendToClients("cl_n_onReload", is_garand_thumb)
end

function Garand:cl_n_onReload(is_garand_thumb)
	if not self.cl_isLocal and self.tool:isEquipped() then
		self:cl_startReloadAnim(is_garand_thumb)
	end
end

local garand_ordinary_reload = "reload"
local garand_thumb_reload = "reload_gt"

function Garand:cl_startReloadAnim(is_garand_thumb)
	local v_cur_anim = is_garand_thumb and garand_thumb_reload or garand_ordinary_reload

	setTpAnimation(self.tpAnimations, v_cur_anim, 1.0)
	mgp_toolAnimator_setAnimation(self, v_cur_anim)
end

function Garand:client_isGunReloading(reload_table)
	if self.waiting_for_ammo then
		return true
	end

	return mgp_tool_isAnimPlaying(self, reload_table)
end

function Garand:cl_initReloadAnim()
	if sm.game.getEnableAmmoConsumption() then
		local v_available_ammo = sm.container.totalQuantity(sm.localPlayer.getInventory(), mgp_sniper_ammo)
		if v_available_ammo == 0 then
			sm.gui.displayAlertText("No Ammo", 3)
			return true
		end
	end

	self.waiting_for_ammo = true

	local has_garand_thumb = math.random(0, 100) > 80

	setFpAnimation(self.fpAnimations, has_garand_thumb and garand_thumb_reload or garand_ordinary_reload, 0.0)
	self:cl_startReloadAnim(has_garand_thumb)

	--Send the animation data to all the other clients
	self.network:sendToServer("sv_n_onReload", WIP_garand_thumb)
end

function Garand:client_onReload()
	if self.equipped and self.ammo_in_mag ~= self.mag_capacity then
		if not self:client_isGunReloading(garand_action_block_anims) and not self.aiming and not self.tool:isSprinting() and self.fireCooldownTimer == 0.0 then
			if self.ammo_in_mag ~= 0 then
				sm.gui.displayAlertText("Garand: can't reload while magazine is not empty")
				return true
			end

			self:cl_initReloadAnim()
		end
	end

	return true
end

function Garand:sv_n_checkMag()
	self.network:sendToClients("cl_n_checkMag")
end

function Garand:cl_n_checkMag()
	local s_tool = self.tool
	if not s_tool:isLocal() and s_tool:isEquipped() then
		self:cl_startCheckMagAnim()
	end
end

function Garand:cl_startCheckMagAnim()
	setTpAnimation(self.tpAnimations, "ammo_check", 1.0)
	mgp_toolAnimator_setAnimation(self, "ammo_check")
end

function Garand:client_onToggle()
	if not self:client_isGunReloading(garand_action_block_anims) and not self.aiming and not self.tool:isSprinting() and self.fireCooldownTimer == 0.0 and self.equipped then
		if self.ammo_in_mag > 0 then
			self.cl_show_ammo_timer = 1.2

			setFpAnimation(self.fpAnimations, "ammo_check", 0.0)

			self:cl_startCheckMagAnim()
			self.network:sendToServer("sv_n_checkMag")
		else
			sm.gui.displayAlertText("Garand: No Ammo. Reloading...", 3)
			self:cl_initReloadAnim()
		end
	end

	return true
end

local _intstate = sm.tool.interactState
function Garand:cl_onSecondaryUse(state)
	if not self.equipped then return end

	local is_reloading = self:client_isGunReloading(garand_aim_block_anims) or (self.aim_timer ~= nil)
	local new_state = (state == _intstate.start or state == _intstate.hold) and not is_reloading
	if self.aiming ~= new_state then
		self.aiming = new_state
		self.tpAnimations.animations.idle.time = 0

		self.tool:setMovementSlowDown(self.aiming)
		self:onAim(self.aiming)
		self.network:sendToServer("sv_n_onAim", self.aiming)
	end
end

function Garand:client_onEquippedUpdate(primaryState, secondaryState)
	if primaryState ~= self.prevPrimaryState then
		self:cl_onPrimaryUse(primaryState)
		self.prevPrimaryState = primaryState
	end

	self:cl_onSecondaryUse( secondaryState )

	return true, true
end
