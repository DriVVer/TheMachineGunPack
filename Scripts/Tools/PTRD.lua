dofile( "$GAME_DATA/Scripts/game/AnimationUtil.lua" )
dofile( "$SURVIVAL_DATA/Scripts/util.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/survival_shapes.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/survival_projectiles.lua" )

dofile("ToolAnimator.lua")
dofile("ToolSwimUtil.lua")
dofile("PTRDProjectile.lua")
dofile("$CONTENT_DATA/Scripts/Utils/ToolUtils.lua")

---@class PTRD : ToolClass
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
PTRD = class()
PTRD.mag_capacity = 1
PTRD.maxRecoil = 40
PTRD.recoilAmount = 30
PTRD.aimRecoilAmount = 20
PTRD.recoilRecoverySpeed = 0.6
PTRD.aimFovTp = 30
PTRD.aimFovFp = 30

local renderables =
{
	"$CONTENT_DATA/Tools/Renderables/PTRD/PTRD_Base.rend",
	"$CONTENT_DATA/Tools/Renderables/PTRD/PTRD_Anim.rend"
}

local renderablesTp =
{
	"$CONTENT_DATA/Tools/Renderables/PTRD/char_male_tp_PTRD.rend",
	"$CONTENT_DATA/Tools/Renderables/PTRD/char_PTRD_tp_offset.rend"
}

local renderablesFp =
{
	"$CONTENT_DATA/Tools/Renderables/PTRD/char_male_fp_PTRD.rend",
	"$CONTENT_DATA/Tools/Renderables/PTRD/char_PTRD_fp_offset.rend",
	"$CONTENT_DATA/Tools/Renderables/char_male_fp_recoil.rend"
}

sm.tool.preloadRenderables( renderables )
sm.tool.preloadRenderables( renderablesTp )
sm.tool.preloadRenderables( renderablesFp )

local PTRD_action_block_anims =
{
	["reload"] = true,
	["equip"] = true,

	["deploy_bipod"] = true,
	["hide_bipod"] = true,

	["sprintInto"] = true,
	["sprintIdle"] = true,
	["sprintExit"] = true,

	["aimInto"] = true,
	["aimExit"] = true
}

local PTRD_bipod_block_anims =
{
	["reload"] = true,
	["equip"] = true,

	["sprintInto"] = true,
	["sprintIdle"] = true,
	["sprintExit"] = true,

	["aimInto"]  = true,
	["aimIdle"]  = true,
	["aimExit"]  = true,
	["aimShoot"] = true,

	["bipodAimIdle"]  = true,
	["bipodAimShoot"] = true,

	["shoot"] = true,
	["shoot_bipod"] = true
}

local PTRD_aim_block_anims =
{
	["reload"] = true,

	["sprintInto"] = true,
	["sprintIdle"] = true,
	["sprintExit"] = true
}

local PTRD_smooth_aim_anims =
{
	["aimInto"] = true,
	["aimExit"] = true,
	["bipodAimInto"] = true,
	["bipodAimExit"] = true
}

local PTRD_bipod_aim_anims =
{
	["bipodAimInto"] = true,
	["bipodAimIdle"] = true,
	["bipodAimExit"] = true
}

local PTRD_sprint_block_anims =
{
	["reload"] = true,
	["aimExit"] = true,
	["sprintExit"] = true
}

local PTRD_obstacle_block_anims =
{
	["reload"    ] = true,
	["equip"     ] = true,
	["aimExit"   ] = true
}

function PTRD:client_initAimVals()
	local cameraWeight, cameraFPWeight = self.tool:getCameraWeights()
	self.aimWeight = math.max( cameraWeight, cameraFPWeight )
	self.aimWeightFp = self.aimWeight
end

function PTRD:server_onCreate()
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

function PTRD:server_requestAmmo(data, caller)
	self.network:sendToClient(caller, "client_receiveAmmo", self.sv_ammo_counter)
end

function PTRD:server_updateAmmoCounter(data, caller)
	if data ~= nil or caller ~= nil then return end

	self.storage:save(self.sv_ammo_counter)
end

function PTRD:client_receiveAmmo(ammo_count)
	self.ammo_in_mag = ammo_count
	self.waiting_for_ammo = nil
end

function PTRD:client_onCreate()
	self.ammo_in_mag = 0

	self:client_initAimVals()
	self.aimBlendSpeed = 3.0

	self.bipod_equip_timer = 0.0
	self.bipod_unequip_timer = 0.0

	self.waiting_for_ammo = true

	mgp_toolAnimator_initialize(self, "PTRD")
	PTRDProjectile_clientInitialize()

	self.network:sendToServer("server_requestAmmo")
end

function PTRD:client_onDestroy()
	mgp_toolAnimator_destroy(self)
	PTRDProjectile_clientDestroy()
end

function PTRD:client_onRefresh()
	self:loadAnimations()
end

function PTRD:loadAnimations()
	self.tpAnimations = createTpAnimations(
		self.tool,
		{
			shoot = { "spudgun_shoot", { crouch = "spudgun_crouch_shoot" } },
			aim = { "spudgun_aim", { crouch = "spudgun_crouch_aim" } },
			aimShoot = { "spudgun_aim_shoot", { crouch = "spudgun_crouch_aim_shoot" } },
			idle = { "spudgun_idle" },
			pickup = { "spudgun_pickup", { nextAnimation = "idle" } },
			putdown = { "spudgun_putdown" },

			reload = { "PTRD_reload", { nextAnimation = "idle" } },
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
				equip = { "PTRD_pickup", { nextAnimation = "idle" } },
				unequip = { "PTRD_putdown" },
				aim_anim = { "PTRD_putdown" },

				deploy_bipod = { "PTRD_deploy_bipod", { nextAnimation = "idle" } },
				hide_bipod = { "PTRD_hide_bipod", { nextAnimation = "idle" } },

				idle = { "PTRD_idle", { looping = true } },
				shoot = { "PTRD_shoot", { nextAnimation = "idle" } },
				shoot_bipod = { "PTRD_shoot_bipod", { nextAnimation = "idle" } },

				reload = { "PTRD_reload", { nextAnimation = "idle" } },

				aimInto = { "PTRD_aim_into", { nextAnimation = "aimIdle" } },
				aimExit = { "PTRD_aim_exit", { nextAnimation = "idle", blendNext = 0 } },
				aimIdle = { "PTRD_aim_idle", { looping = true } },
				aimShoot = { "PTRD_aim_shoot", { nextAnimation = "aimIdle"} },

				bipodAimInto = { "PTRD_aim_bipod_into", { nextAnimation = "bipodAimIdle" } },
				bipodAimExit = { "PTRD_aim_bipod_exit", { nextAnimation = "idle", blendNext = 0 } },
				bipodAimIdle = { "PTRD_aim_bipod_idle", { looping = true } },
				bipodAimShoot = { "PTRD_aim_bipod_shoot", { nextAnimation = "bipodAimIdle" } },

				sprintInto = { "PTRD_sprint_into", { nextAnimation = "sprintIdle",  blendNext = 0.2 } },
				sprintExit = { "PTRD_sprint_exit", { nextAnimation = "idle",  blendNext = 0 } },
				sprintIdle = { "PTRD_sprint_idle", { looping = true } },
			}
		)
	end

	self.normalFireMode = {
		fireCooldown = 0.18,
		spreadCooldown = 0.5,
		spreadIncrement = 0.5,
		spreadMinAngle = 5.0,
		spreadMaxAngle = 16.0,
		fireVelocity = 550.0,

		minDispersionStanding = 0.8,
		minDispersionCrouching = 0.3,

		maxMovementDispersion = 0.99,
		jumpDispersionMultiplier = 2
	}

	self.aimFireMode = {
		fireCooldown = 0.18,
		spreadCooldown = 0.01,
		spreadIncrement = 0.5,
		spreadMinAngle = 2.0,
		spreadMaxAngle = 5.5,
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
	["reload"] = true
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

local bipod_aim_animation_list01 =
{
	["bipodAimInto"] = true,
	["bipodAimIdle"] = true,
	["bipodAimShoot"] = true
}

local aim_animation_blacklist =
{
	["aim_anim"] = true,
}

function PTRD:client_onFixedUpdate(dt)
	PTRDProjectile_clientOnFixedUpdate(self, dt)
end

function PTRD:sv_checkProjectile(id)
	PTRD_serverCheckProjecitle(self, id)
end

function PTRD:cl_updatePenetration(data)
	PTRD_clientUpdatePenetration(data)
end

function PTRD:client_updateAimWeights(dt)
	local weight_blend = 1 - math.pow( 1 - 1 / self.aimBlendSpeed, dt * 10 )

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

	self.tool:updateCamera( 2.8, 30.0, sm.vec3.new( 0.65, 0.0, 0.05 ), self.aimWeight )
	self.tool:updateFpCamera( 30.0, sm.vec3.new( 0.0, 0.0, 0.0 ), self.aimWeightFp, bobbingFp )
end

local mgp_antitank_ammo = sm.uuid.new("d80e4edd-8823-42f6-9f17-1dc130ba51ce")
function PTRD:server_spendAmmo(data, player)
	if data ~= nil or player ~= nil then return end

	local v_owner = self.tool:getOwner()
	if v_owner == nil then return end

	local v_inventory = v_owner:getInventory()
	if v_inventory == nil then return end

	local v_available_ammo = sm.container.totalQuantity(v_inventory, mgp_antitank_ammo)
	if v_available_ammo == 0 then return end

	local v_raw_spend_count = math.max(self.mag_capacity - self.sv_ammo_counter, 0)
	local v_spend_count = math.min(v_raw_spend_count, math.min(v_available_ammo, self.mag_capacity))

	sm.container.beginTransaction()
	sm.container.spend(v_inventory, mgp_antitank_ammo, v_spend_count)
	sm.container.endTransaction()

	self.sv_ammo_counter = self.sv_ammo_counter + v_spend_count
	self:server_updateAmmoCounter()
end

function PTRD:sv_n_trySpendAmmo(data, player)
	local v_owner = self.tool:getOwner()
	if v_owner == nil or v_owner ~= player then return end

	self:server_spendAmmo()
	self.network:sendToClient(v_owner, "client_receiveAmmo", self.sv_ammo_counter)
end

---@param self PTRD
local function ptrd_can_deploy_bipod(self)
	local v_owner = self.tool:getOwner()
	if not (v_owner and sm.exists(v_owner)) then
		return false
	end

	local v_owner_char = v_owner.character
	if not (v_owner_char and sm.exists(v_owner_char)) then
		return false
	end

	if v_owner_char:isCrouching() then
		return false
	end

	local v_char_pos = v_owner_char.worldPosition
	v_char_pos.z = v_char_pos.z + v_owner_char:getHeight() * 0.4

	local v_forward_check = v_char_pos + v_owner_char.direction * 0.5
	local hit, result = sm.physics.raycast(v_char_pos, v_forward_check, v_owner_char)
	if hit then
		return false
	end

	local v_cam_up = sm.camera.getUp()
	local v_final_check = v_forward_check - v_cam_up * 0.5
	local final_hit, final_result = sm.physics.raycast(v_forward_check, v_final_check, v_owner_char)
	if not final_hit then
		return false
	end

	local v_up_direction = sm.vec3.new(0, 0, 1)
	if final_result.fraction < 0.4 or final_result.normalWorld:dot(v_up_direction) < 0.97 or v_cam_up:dot(v_up_direction) < 0.98 then
		return false
	end

	return true
end

function PTRD:server_updateBipodAnim(is_deploy)
	self.network:sendToClients("client_receiveBipodAnim", is_deploy)
end

function PTRD:client_receiveBipodAnim(is_deploy)
	if not self.cl_isLocal and self.tool:isEquipped() then
		mgp_toolAnimator_setAnimation(self, is_deploy and "deploy_bipod" or "hide_bipod")
		self.bipod_deployed = is_deploy
	end
end

function PTRD:client_updateBipod(dt)
	if self:client_isGunReloading(PTRD_bipod_block_anims) then
		self.bipod_unequip_timer = 0.0
		self.bipod_equip_timer = 0.0
		return
	end

	if ptrd_can_deploy_bipod(self) then
		self.bipod_unequip_timer = 0.0

		if not self.bipod_deployed then
			self.bipod_equip_timer = self.bipod_equip_timer + dt
			if self.bipod_equip_timer >= 0.5 then
				self.network:sendToServer("server_updateBipodAnim", true)

				mgp_toolAnimator_setAnimation(self, "deploy_bipod")
				if not self.aiming then
					setFpAnimation(self.fpAnimations, "deploy_bipod", 0.0)
				end

				self.bipod_equip_timer = 0.0
				self.bipod_deployed = true
			end
		end
	else
		self.bipod_equip_timer = 0.0

		if self.bipod_deployed then
			self.bipod_unequip_timer = self.bipod_unequip_timer + dt
			if self.bipod_unequip_timer >= 0.5 then
				self.network:sendToServer("server_updateBipodAnim", false)

				mgp_toolAnimator_setAnimation(self, "hide_bipod")
				if not self.aiming then
					setFpAnimation(self.fpAnimations, "hide_bipod", 0.0)
				end

				self.bipod_unequip_timer = 0.0
				self.bipod_deployed = false
			end
		end
	end
end

function PTRD:client_onUpdate(dt)
	mgp_toolAnimator_update(self, dt)

	if self.cl_show_ammo_timer then
		self.cl_show_ammo_timer = self.cl_show_ammo_timer - dt

		if self.cl_show_ammo_timer <= 0.0 then
			self.cl_show_ammo_timer = nil
			if self.tool:isEquipped() then
				sm.gui.displayAlertText(("PTRD: Ammo #ffff00%s#ffffff/#ffff00%s#ffffff"):format(self.ammo_in_mag, self.mag_capacity), 2)
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
			if hit and not self:client_isGunReloading(PTRD_obstacle_block_anims) then
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

				if isSprinting and self.fpAnimations.currentAnimation ~= "sprintInto" and self.fpAnimations.currentAnimation ~= "sprintIdle" then
					swapFpAnimation( self.fpAnimations, "sprintExit", "sprintInto", 0.0 )
				elseif not isSprinting and ( self.fpAnimations.currentAnimation == "sprintIdle" or self.fpAnimations.currentAnimation == "sprintInto" ) then
					swapFpAnimation( self.fpAnimations, "sprintInto", "sprintExit", 0.0 )
				end

				if aim_animation_blacklist[self.fpAnimations.currentAnimation] == nil then
					if self.bipod_deployed then
						if self.aiming and bipod_aim_animation_list01[self.fpAnimations.currentAnimation] == nil then
							swapFpAnimation(self.fpAnimations, "bipodAimExit", "bipodAimInto", 0.0)
						end
						if not self.aiming and bipod_aim_animation_list01[self.fpAnimations.currentAnimation] == true then
							swapFpAnimation(self.fpAnimations, "bipodAimInto", "bipodAimExit", 0.0)
						end
					else
						if self.aiming and aim_animation_list01[self.fpAnimations.currentAnimation] == nil then
							swapFpAnimation( self.fpAnimations, "aimExit", "aimInto", 0.0 )
						end
						if not self.aiming and aim_animation_list02[self.fpAnimations.currentAnimation] == true then
							swapFpAnimation( self.fpAnimations, "aimInto", "aimExit", 0.0 )
						end
					end
				end

				self:client_updateBipod(dt)
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
	self.tool:setBlockSprint(self.aiming or self.sprintCooldownTimer > 0.0 or self:client_isGunReloading(PTRD_sprint_block_anims))

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
				elseif name == "reload" then
					setTpAnimation( self.tpAnimations, self.aiming and "idle" or "idle", 2 )
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

function PTRD:client_onEquip(animate, is_custom)
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

	mgp_toolAnimator_setAnimation(self, "hide_bipod")
	--if self.ammo_in_mag <= 0 then
--		mgp_toolAnimator_setAnimation(self, "last_shot_equip")
--	end
end

function PTRD:client_onUnequip(animate, is_custom)
	if not is_custom and TSU_IsOwnerSwimming(self) then
		return
	end

	self.bipod_equip_timer = 0.0
	self.bipod_unequip_timer = 0.0
	self.bipod_deployed = false

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

function PTRD:sv_n_onAim(aiming)
	self.network:sendToClients( "cl_n_onAim", aiming )
end

function PTRD:cl_n_onAim(aiming)
	if not self.cl_isLocal and self.tool:isEquipped() then
		self:onAim( aiming )
	end
end

function PTRD:onAim(aiming)
	self.aiming = aiming
	if self.tpAnimations.currentAnimation == "idle" or self.tpAnimations.currentAnimation == "aim" or self.tpAnimations.currentAnimation == "relax" and self.aiming then
		setTpAnimation( self.tpAnimations, self.aiming and "aim" or "idle", 5.0 )
	end
end

function PTRD:sv_n_onShoot(data)
	self.network:sendToClients("cl_n_onShoot", data.dir)

	if data.ammo_in_mag ~= nil and self.sv_ammo_counter > 0 then
		self.sv_ammo_counter = self.sv_ammo_counter - 1
		self:server_updateAmmoCounter()
	end
end

function PTRD:cl_n_onShoot(dir)
	if not self.cl_isLocal and self.tool:isEquipped() then
		self:onShoot(dir)
	end
end

function PTRD:cl_chooseShootAnim()
	if self.bipod_deployed then
		return self.aiming and "bipodAimShoot" or "shoot_bipod"
	end

	return self.aiming and "aimShoot" or "shoot"
end

function PTRD:onShoot(dir)
	self.tpAnimations.animations.idle.time     = 0
	self.tpAnimations.animations.shoot.time    = 0
	self.tpAnimations.animations.aimShoot.time = 0

	local anim = self.aiming and "aimShoot" or "shoot"
	setTpAnimation(self.tpAnimations, anim, 10.0)
	mgp_toolAnimator_setAnimation(self, self.bipod_deployed and "shoot_bipod" or anim)

	PTRDProjectile_clientSpawnProjectile(self, dir)
end

function PTRD:cl_getFirePosition()
	local v_direction = mgp_tool_getToolDir(self)

	if not self.tool:isInFirstPersonView() then
		return self.tool:getTpBonePos("pejnt_barrel"), v_direction
	end

	return self.tool:getFpBonePos("pejnt_barrel"), v_direction
end

function PTRD:cl_onPrimaryUse(state)
	if state ~= 1 then return end
	if self:client_isGunReloading(PTRD_action_block_anims) or not self.equipped then return end

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

		if not self.bipod_deployed then
			-- Spread
			local recoilDispersion = 1.0 - ( math.max(fireMode.minDispersionCrouching, fireMode.minDispersionStanding ) + fireMode.maxMovementDispersion )
			local spreadFactor = fireMode.spreadCooldown > 0.0 and clamp( self.spreadCooldownTimer / fireMode.spreadCooldown, 0.0, 1.0 ) or 0.0
			spreadFactor = clamp( self.movementDispersion + spreadFactor * recoilDispersion, 0.0, 1.0 )

			local spreadDeg =  fireMode.spreadMinAngle + ( fireMode.spreadMaxAngle - fireMode.spreadMinAngle ) * spreadFactor

			dir = sm.noise.gunSpread( dir, spreadDeg )
		end

		-- Timers
		self.fireCooldownTimer = fireMode.fireCooldown
		self.spreadCooldownTimer = math.min( self.spreadCooldownTimer + fireMode.spreadIncrement, fireMode.spreadCooldown )
		self.sprintCooldownTimer = self.sprintCooldown

		-- Send TP shoot over network and directly to self
		self:onShoot(dir)
		self.network:sendToServer("sv_n_onShoot", { ammo_in_mag = 1, dir = dir })

		sm.camera.setShake(0.5)

		-- Play FP shoot animation
		setFpAnimation( self.fpAnimations, self:cl_chooseShootAnim(), 0.0 )
	else
		--self:onShoot()
		--self.network:sendToServer("sv_n_onShoot")

		self.fireCooldownTimer = 0.3
		sm.audio.play( "event:/vehicle/triggers/trigger_toggle_off" )
	end
end

function PTRD:sv_n_onReload()
	self.network:sendToClients("cl_n_onReload")
end

function PTRD:cl_n_onReload(is_PTRD_thumb)
	if not self.cl_isLocal and self.tool:isEquipped() then
		self:cl_startReloadAnim()
	end
end

local PTRD_ordinary_reload = "reload"

function PTRD:cl_startReloadAnim()
	setTpAnimation(self.tpAnimations, PTRD_ordinary_reload, 1.0)
	mgp_toolAnimator_setAnimation(self, self.bipod_deployed and "reload_bipod" or PTRD_ordinary_reload)
end

function PTRD:client_isGunReloading(reload_table)
	if self.waiting_for_ammo then
		return true
	end

	return mgp_tool_isAnimPlaying(self, reload_table)
end

function PTRD:cl_initReloadAnim()
	if sm.game.getEnableAmmoConsumption() then
		local v_available_ammo = sm.container.totalQuantity(sm.localPlayer.getInventory(), mgp_antitank_ammo)
		if v_available_ammo == 0 then
			sm.gui.displayAlertText("No Ammo", 3)
			return true
		end
	end

	self.waiting_for_ammo = true

	setFpAnimation(self.fpAnimations, PTRD_ordinary_reload, 0.0)
	self:cl_startReloadAnim()

	--Send the animation data to all the other clients
	self.network:sendToServer("sv_n_onReload")
end

function PTRD:client_onReload()
	if self.equipped and self.ammo_in_mag ~= self.mag_capacity then
		if not self:client_isGunReloading(PTRD_action_block_anims) and not self.aiming and not self.tool:isSprinting() and self.fireCooldownTimer == 0.0 then
			if self.ammo_in_mag ~= 0 then
				sm.gui.displayAlertText("PTRD: can't reload while magazine is not empty")
				return true
			end

			self:cl_initReloadAnim()
		end
	end

	return true
end

local _intstate = sm.tool.interactState
function PTRD:cl_onSecondaryUse(state)
	if not self.equipped then return end

	local is_reloading = self:client_isGunReloading(PTRD_aim_block_anims) or (self.aim_timer ~= nil)
	local new_state = false
	if self.should_aim_again then
		if state == _intstate.stop then
			self.should_aim_again = nil
		end
	else
		new_state = (state == _intstate.start or state == _intstate.hold) and not is_reloading
	end

	local v_fp_anims = self.fpAnimations
	if v_fp_anims then
		if PTRD_smooth_aim_anims[v_fp_anims.currentAnimation] == true then
			return
		end

		if PTRD_bipod_aim_anims[v_fp_anims.currentAnimation] == true and not ptrd_can_deploy_bipod(self) then
			self.should_aim_again = true
			new_state = false
		end
	end

	if self.aiming ~= new_state then
		self.aiming = new_state
		self.tpAnimations.animations.idle.time = 0

		if not self.aiming then
			self.fireCooldownTimer = 0.4
		end

		self.tool:setMovementSlowDown(self.aiming)
		self:onAim(self.aiming)
		self.network:sendToServer("sv_n_onAim", self.aiming)
	end
end

function PTRD:client_onEquippedUpdate(primaryState, secondaryState)
	if primaryState ~= self.prevPrimaryState then
		self:cl_onPrimaryUse(primaryState)
		self.prevPrimaryState = primaryState
	end

	self:cl_onSecondaryUse( secondaryState )
	return true, true
end
