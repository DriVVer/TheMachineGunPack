dofile( "$GAME_DATA/Scripts/game/AnimationUtil.lua" )
dofile( "$SURVIVAL_DATA/Scripts/util.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/survival_shapes.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/survival_projectiles.lua" )

dofile("ToolAnimator.lua")
dofile("BazookaProjectile.lua")
dofile("$CONTENT_DATA/Scripts/Utils/ToolUtils.lua")

---@class Panzerfaust : ToolClass
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
---@field fireCooldownTimer integer
---@field equipped boolean
---@field cl_isLocal boolean
---@field cl_used boolean
---@field cl_usedTimer number
---@field sv_usedTimer number
---@field aimMode integer
Panzerfaust = class()

local renderables =
{
	"$CONTENT_DATA/Tools/Renderables/Panzerfaust/Panzerfaust_Base.rend",
	"$CONTENT_DATA/Tools/Renderables/Panzerfaust/Panzerfaust_Anim.rend"
}

local renderablesTp =
{
	"$CONTENT_DATA/Tools/Renderables/Panzerfaust/char_Panzerfaust_anims_tp.rend",
	"$CONTENT_DATA/Tools/Renderables/Panzerfaust/Panzerfaust_offset_tp.rend"
}

local renderablesFp =
{
	"$CONTENT_DATA/Tools/Renderables/Panzerfaust/char_Panzerfaust_anims_fp.rend",
	"$CONTENT_DATA/Tools/Renderables/Panzerfaust/Panzerfaust_offset_fp.rend"
}

sm.tool.preloadRenderables( renderables )
sm.tool.preloadRenderables( renderablesTp )
sm.tool.preloadRenderables( renderablesFp )

local g_close_anim_block =
{
	["reload"         ] = true,
	["reload_empty"   ] = true,
	["aimExit"        ] = true,
	["equip"          ] = true
}

local g_sprint_block_anims =
{
	["reload_empty"] = true,
	["reload"      ] = true,
	["sprintExit"  ] = true,
	["aimExit"     ] = true,
	["equip"       ] = true,
	["throwAway"   ] = true
}

local g_action_block_anims =
{
	["reload_empty"] = true,
	["reload"      ] = true,
	["sprintExit"  ] = true,
	["sprintIdle"  ] = true,
	["sprintInto"  ] = true,
	["aimExit"     ] = true,
	["equip_short" ] = true,
	["equip"       ] = true,
	["throwAway"   ] = true
}

function Panzerfaust:client_initAimVals()
	local cameraWeight, cameraFPWeight = self.tool:getCameraWeights()
	self.aimWeight = math.max( cameraWeight, cameraFPWeight )
end

function Panzerfaust:sv_updateAmmoCounter()
	self.storage:save(self.sv_Panzerfaust_loaded)
end

function Panzerfaust:server_onCreate()
	local v_bz_loaded = self.storage:load()
	if v_bz_loaded ~= nil then
		self.sv_Panzerfaust_loaded = v_bz_loaded
	else
		if not sm.game.getEnableAggro() or not sm.game.getLimitedInventory() then
			self.sv_Panzerfaust_loaded = true
		end

		self:sv_updateAmmoCounter()
	end
end

function Panzerfaust:cl_receivePanzerfaustState(state)
	self.cl_waiting_for_data = nil
	self.cl_is_loaded = state
end

function Panzerfaust:sv_requestPanzerfaustState(data, player)
	self.network:sendToClient(player, "cl_receivePanzerfaustState", self.sv_Panzerfaust_loaded)
end

local g_aim_mode_to_anim_name =
{
	[0] = "aim_idle30",
	[1] = "aim_idle60",
	[2] = "aim_idle90"
}

local g_aim_anim_table =
{
	["aim_idle30"] = true,
	["aim_idle60"] = true,
	["aim_idle90"] = true
}

local g_aim_mode_to_notification_text =
{
	[0] = "30m",
	[1] = "60m",
	[2] = "90m"
}

function Panzerfaust:client_setAimMode(mode, showNotif)
	self.aimMode = mode

	local fpAnims = self.fpAnimations
	local animToPlay = g_aim_mode_to_anim_name[mode]

	local aimInto = fpAnims.animations.aimInto
	aimInto.nextAnimation = animToPlay

	if showNotif then
		sm.gui.displayAlertText(("Sight calibrated for #ffff00%s#ffffff"):format(g_aim_mode_to_notification_text[mode]), 3)
	end

	if g_aim_anim_table[fpAnims.currentAnimation] == true then
		setFpAnimation(self.fpAnimations, animToPlay, 0.0)
	end
end

function Panzerfaust:client_onCreate()
	self.cl_is_loaded = true

	self.cl_waiting_for_data = true
	self.network:sendToServer("sv_requestPanzerfaustState")

	self:client_initAimVals()
	self.aimBlendSpeed = 10.0

	self.cl_sight_hud = sm.gui.createGuiFromLayout("$CONTENT_DATA/Gui/Layouts/PanzerfaustSight.layout", false, {
		isHud = true,
		isInteractive = false,
		needsCursor = false,
		hidesHotbar = false
	})

	BazookaProjectile_clientInitialize()
	mgp_toolAnimator_initialize(self, "Panzerfaust")

	self.cl_barrel_exhaust = sm.effect.createEffect("Bazooka - BarrelExhaust")
end

function Panzerfaust:client_onDestroy()
	local v_sight_hud = self.cl_sight_hud
	if v_sight_hud and sm.exists(v_sight_hud) then
		if v_sight_hud:isActive() then
			v_sight_hud:close()
		end

		v_sight_hud:destroy()
	end

	local v_exhaust_effect = self.cl_barrel_exhaust
	if v_exhaust_effect and sm.exists(v_exhaust_effect) then
		v_exhaust_effect:stopImmediate()
		v_exhaust_effect:destroy()
	end

	BazookaProjectile_clientDestroy()
	mgp_toolAnimator_destroy(self)
end

function Panzerfaust.client_onRefresh( self )
	self:loadAnimations()
end

function Panzerfaust.loadAnimations( self )
	self.tpAnimations = createTpAnimations(
		self.tool,
		{
			shoot = { "spudgun_shoot", { crouch = "spudgun_crouch_shoot" } },

			aim = { "spudgun_aim", { crouch = "spudgun_crouch_aim" } },
			aimShoot = { "spudgun_aim_shoot", { crouch = "spudgun_crouch_aim_shoot" } },

			idle = { "spudgun_idle" },
			pickup = { "spudgun_pickup", { nextAnimation = "idle" } },
			putdown = { "spudgun_putdown" },

			reload_empty = { "Panzerfaust_tp_reload", { nextAnimation = "idle", duration = 1.0 } }
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
				equip = { "Panzerfaust_pickup", { nextAnimation = "idle" } },
				equip_short = { "Panzerfaust_pickup_short", { nextAnimation = "idle" } },
				unequip = { "Panzerfaust_putdown" },

				idle = { "Panzerfaust_idle", { nextAnimation = "idle" } },

				shoot = { "Panzerfaust_shoot", { nextAnimation = "idle" } },

				reload_empty = { "Panzerfaust_reload", { nextAnimation = "idle", duration = 1.0 } },

				aim_idle30 = { "Panzerfaust_aim_idle_30", { looping = true, duration = 1.0 } },
				aim_idle60 = { "Panzerfaust_aim_idle_60", { looping = true, duration = 1.0 } },
				aim_idle90 = { "Panzerfaust_aim_idle_90", { looping = true, duration = 1.0 } },
				throwAway = { "Panzerfaust_throwaway" },

				aimInto = { "Panzerfaust_aim_into", { nextAnimation = "aim_idle90" } },
				aimExit = { "Panzerfaust_aim_exit", { nextAnimation = "idle", blendNext = 0 } },
				aimIdle = { "Panzerfaust_aim_idle", { looping = true } },
				aimShoot = { "Panzerfaust_aim_shoot", { nextAnimation = "aim_idle30" } },

				sprintInto = { "Panzerfaust_sprint_into", { nextAnimation = "sprintIdle",  blendNext = 0.2 } },
				sprintExit = { "Panzerfaust_sprint_exit", { nextAnimation = "idle",  blendNext = 0 } },
				sprintIdle = { "Panzerfaust_sprint_idle", { looping = true } },
			}
		)

		self:client_setAimMode(0)
	end

	self.normalFireMode = {
		fireCooldown = 0.1,
		spreadCooldown = 0.3,
		spreadIncrement = 3,
		spreadMinAngle = 1,
		spreadMaxAngle = 3,
		fireVelocity = 200.0,

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
		spreadMaxAngle = 3,
		fireVelocity = 500.0,

		minDispersionStanding = 0.01,
		minDispersionCrouching = 0.01,

		maxMovementDispersion = 0.4,
		jumpDispersionMultiplier = 2
	}

	self.spreadCooldownTimer = 0.0

	self.movementDispersion = 0.0

	self.sprintCooldownTimer = 1.5
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
	["aim_idle30"]      = true,
	["aim_idle60"]      = true,
	["aim_idle90"]      = true,
	["aimShoot"]        = true,
	["cock_hammer_aim"] = true
}

local aim_animation_list02 =
{
	["aimInto"]    = true,
	["aimIdle"]    = true,
	["aim_idle30"] = true,
	["aim_idle60"] = true,
	["aim_idle90"] = true,
	["aimShoot"]   = true
}

function Panzerfaust:client_onFixedUpdate(dt)
	BazookaProjectile_clientOnFixedUpdate(dt)
end

function Panzerfaust:server_onFixedUpdate(dt)
	BazookaProjectile_serverOnFixedUpdate(dt)

	if self.sv_shoot_timer then
		self.sv_shoot_timer = self.sv_shoot_timer - dt
		if self.sv_shoot_timer <= 0.0 then
			self.sv_shoot_timer = nil
		end
	end

	if self.sv_eraseTimer then
		self.sv_eraseTimer = self.sv_eraseTimer - dt

		if self.sv_eraseTimer <= 0.0 then
			self.sv_eraseTimer = nil

			local v_tool_owner = self.tool:getOwner()
			if not (v_tool_owner and sm.exists(v_tool_owner)) then
				return
			end

			local v_pl_inventory = nil
			if sm.game.getLimitedInventory() then
				v_pl_inventory = v_tool_owner:getInventory()
			else
				v_pl_inventory = v_tool_owner:getHotbar()
			end

			if not (v_pl_inventory and sm.exists(v_pl_inventory)) then
				return
			end

			local v_panzerfaust_uuid = "56b4204e-6a3b-4d6d-8858-924dc65fe6d9"
			for i = 0, v_pl_inventory:getSize() - 1 do
				local v_cur_item = v_pl_inventory:getItem(i)
				if tostring(v_cur_item.uuid) == v_panzerfaust_uuid then
					if v_cur_item.instance == self.tool.id then
						sm.container.beginTransaction()
						sm.container.spendFromSlot(v_pl_inventory, i, v_cur_item.uuid, 1, true)
						sm.container.endTransaction()

						break
					end
				end
			end
		end
	end
end

function Panzerfaust:client_updateAimWeights(dt)
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

local mgp_Bazooka_ammo = sm.uuid.new("903b737a-42b9-459d-a169-c4171016cfab")
function Panzerfaust:server_spendAmmo(data, player)
	if self.sv_Panzerfaust_loaded then return end

	if data ~= nil or player ~= nil then return end

	local v_owner = self.tool:getOwner()
	if v_owner == nil then return end

	local v_inventory = v_owner:getInventory()
	if v_inventory == nil then return end

	if not v_inventory:canSpend(mgp_Bazooka_ammo, 1) then return end

	sm.container.beginTransaction()
	sm.container.spend(v_inventory, mgp_Bazookat_ammo, 1)
	sm.container.endTransaction()

	self.sv_Panzerfaust_loaded = true
	self:sv_updateAmmoCounter()
end

function Panzerfaust:sv_n_trySpendAmmo(data, player)
	local v_owner = self.tool:getOwner()
	if v_owner == nil or v_owner ~= player then return end

	self:server_spendAmmo()
	self.network:sendToClient(v_owner, "cl_receivePanzerfaustState", self.sv_Panzerfaust_loaded)
end

local function predict_animation_end(anim_data, dt)
	if anim_data == nil then
		return false
	end

	local time_predict = anim_data.time + anim_data.playRate * dt
	local info_duration = anim_data.info.duration

	return time_predict >= info_duration
end



function Panzerfaust:client_onUpdate(dt)
	if not sm.exists(self.tool) then
		return
	end

	mgp_toolAnimator_update(self, dt)

	if self.cl_usedTimer then
		self.cl_usedTimer = self.cl_usedTimer - dt

		if self.cl_usedTimer <= 0.0 then
			self.cl_usedTimer = nil

			if sm.game.getEnableAmmoConsumption() and sm.game.getLimitedInventory() then
				self.tool:setFpRenderables({})
			else
				self.cl_used = nil
				self.cl_is_loaded = true
				if self.tool:isEquipped() then
					self:client_onEquip(true)
				end
			end
		end
	end

	-- First person animation
	local isSprinting = self.tool:isSprinting()
	local isCrouching = self.tool:isCrouching()

	if self.cl_isLocal then
		if self.equipped and not self.cl_usedTimer then
			local hit, result = sm.localPlayer.getRaycast(1.5)
			if hit and not mgp_tool_isAnimPlaying(self, g_close_anim_block) then
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
				if actual_reload_anims[cur_anim_cache] and predict_animation_end(anim_data, dt) then
					--self.cl_is_loaded = true
					self.network:sendToServer("sv_n_trySpendAmmo")
				end

				if cur_anim_cache ~= "equip" then
					if isSprinting and cur_anim_cache ~= "sprintInto" and cur_anim_cache ~= "sprintIdle" then
						swapFpAnimation( self.fpAnimations, "sprintExit", "sprintInto", 0.0 )
					elseif not isSprinting and ( cur_anim_cache == "sprintIdle" or cur_anim_cache == "sprintInto" ) then
						swapFpAnimation( self.fpAnimations, "sprintInto", "sprintExit", 0.0 )
					end
				else
					if predict_animation_end(anim_data, dt) then
						self.cl_barrel_attached = true
					end
				end

				if self.aiming and aim_animation_list01[cur_anim_cache] == nil then
					swapFpAnimation( self.fpAnimations, "aimExit", "aimInto", 0.0 )
				end
				if not self.aiming and aim_animation_list02[cur_anim_cache] == true then
					swapFpAnimation( self.fpAnimations, "aimInto", "aimExit", 0.0 )
				end
			end
		end

		if self.cl_sight_timer then
			self.cl_sight_timer = self.cl_sight_timer - dt
			if self.cl_sight_timer <= 0.0 then
				self.cl_sight_timer = nil
			end
		end

		if self.aiming and self.cl_sight_timer == nil then
			if not self.cl_sight_hud:isActive() then
				self.cl_sight_hud:open()
			end
		else
			if self.cl_sight_hud:isActive() then
				self.cl_sight_hud:close()
			end
		end

		updateFpAnimations( self.fpAnimations, self.equipped, dt )
	end

	if self.equipped then
		local v_fumes_dir = self.tool:getTpBoneDir("pejnt_barrel")
		local v_fumes_pos = self.tool:getTpBonePos("pejnt_barrel") - (v_fumes_dir * 0.8)

		self.cl_barrel_exhaust:setPosition(v_fumes_pos)
		self.cl_barrel_exhaust:setRotation(sm.vec3.getRotation(sm.vec3.new(0, 0, -1), v_fumes_dir))
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
	self.tool:setBlockSprint(self.aiming or self.sprintCooldownTimer > 0.0 or mgp_tool_isAnimPlaying(self, g_sprint_block_anims) )

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
				if ( name == "shoot" or name == "aimShoot" ) then
					setTpAnimation( self.tpAnimations, self.aiming and "aim" or "idle", 10.0 )
				elseif name == "pickup" then
					setTpAnimation( self.tpAnimations, self.aiming and "idle" or "idle", 0.001 )
				elseif ( name == "reload" or name == "reload_empty" ) then
					setTpAnimation( self.tpAnimations, self.aiming and "idle" or "idle", 2 )
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

function Panzerfaust:client_onEquip(animate, is_custom)
	if not is_custom and TSU_IsOwnerSwimming(self) then
		return
	end

	if animate and not is_custom then
		sm.audio.play("PotatoRifle - Equip", self.tool:getPosition())
	end

	if self.cl_used then
		self.tool:setFpRenderables({})
		return
	end

	local cameraWeight, cameraFPWeight = self.tool:getCameraWeights()
	self.aimWeight = math.max( cameraWeight, cameraFPWeight )
	self.wantEquipped = true
	self.jointWeight = 0.0
	self.aiming = false

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

	if not self.cl_is_loaded then
		self.tool:updateAnimation("Panzerfaust_anims", 4.3, 1.0)
		self.fireCooldownTimer = 1.0
	else
		self.fireCooldownTimer = 1.25
	end

	if (is_custom and self.cl_barrel_attached) or not self.cl_is_loaded then
		if self.cl_isLocal then
			self.tool:updateFpAnimation("Panzerfaust_anims", 3.5, 1.0)
			swapFpAnimation(self.fpAnimations, "unequip", "equip_short", 0.2)
		end
	else
		mgp_toolAnimator_setAnimation(self, "on_equip")

		--Set tp and fp animations
		setTpAnimation(self.tpAnimations, "pickup", 0.0001)
		if self.cl_isLocal then
			swapFpAnimation(self.fpAnimations, "unequip", "equip", 0.2)
		end
	end
end

function Panzerfaust:client_onUnequip(animate, is_custom)
	if not is_custom and TSU_IsOwnerSwimming(self) then
		return
	end

	self.wantEquipped = false
	self.equipped = false
	self.aiming = false
	self.cl_sight_timer = nil
	self.cl_waiting_for_data = nil
	self.sprintCooldownTimer = 0.0
	mgp_toolAnimator_reset(self)

	local s_tool = self.tool
	if sm.exists(s_tool) then
		if animate then
			sm.audio.play("PotatoRifle - Unequip", s_tool:getPosition())
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

			if self.fpAnimations.currentAnimation == "equip" then
				s_tool:updateFpAnimation("Panzerfaust_anims", 0.0, 1.0)
			end

			setFpAnimation(self.fpAnimations, "unequip", 0.2)
		end
	end
end

function Panzerfaust:sv_n_onAim(aiming)
	self.network:sendToClients( "cl_n_onAim", aiming )
end

function Panzerfaust:cl_n_onAim(aiming)
	if not self.cl_isLocal and self.tool:isEquipped() then
		self:onAim( aiming )
	end
end

function Panzerfaust:onAim(aiming)
	self.aiming = aiming
	if self.tpAnimations.currentAnimation == "idle" or self.tpAnimations.currentAnimation == "aim" or self.tpAnimations.currentAnimation == "relax" and self.aiming then
		setTpAnimation( self.tpAnimations, self.aiming and "aim" or "idle", 5.0 )
	end
end

function Panzerfaust:sv_n_onShoot(v_proj_hit)
	if self.sv_shoot_timer ~= nil or not self.sv_Panzerfaust_loaded then
		return
	end

	self.sv_shoot_timer = 5.5
	self.network:sendToClients("cl_n_onShoot", v_proj_hit)

	self.sv_Panzerfaust_loaded = false
	self:sv_updateAmmoCounter()
end

function Panzerfaust:cl_n_onShoot(v_proj_hit)
	if not self.cl_isLocal and self.tool:isEquipped() then
		self:onShoot(v_proj_hit)
	end
end

function Panzerfaust:onShoot(v_proj_hit)
	local v_shoot_anim = (self.aiming and "aimShoot" or "shoot")

	mgp_toolAnimator_setAnimation(self, v_shoot_anim)
	setTpAnimation(self.tpAnimations, v_shoot_anim)
	BazookaProjectile_clientSpawnProjectile(self, v_proj_hit, 80, "Panzerfaust - Projectile", "DLM_PFRocket_Flyin")

	self.cl_barrel_exhaust:start()
end

---@param vector Vec3
---@return Vec3
local function calculateRightVector(vector)
	local yaw = math.atan2(vector.y, vector.x) - math.pi / 2
	return sm.vec3.new(math.cos(yaw), math.sin(yaw), 0)
end

---@param origin Vec3
---@param direction Vec3
---@param angle number
---@param ray_length number
---@return Vec3
local function calculateProjectileHit(origin, direction, angle, ray_length)
	local v_dir_norm = direction:normalize()

	if math.abs(v_dir_norm:dot(sm.vec3.new(0, 0, 1))) >= 0.97 then
		return origin + v_dir_norm * ray_length
	end

	local v_dir_right = calculateRightVector(v_dir_norm)
	local v_final_dir = v_dir_norm:rotate(math.rad(angle), v_dir_right)

	return origin + v_final_dir * ray_length
end

-- Measured in degrees
local g_angle_adjustment_table =
{
	[0] = 1.5, -- 30m adjustment
	[1] = 3.0, -- 60m adjustment
	[2] = 4.5  -- 90m adjustment
}

---@return number
function Panzerfaust:getAdjustmentAngle()
	if self.aiming then
		return g_angle_adjustment_table[self.aimMode]
	end

	return 0.0
end

function Panzerfaust.cl_onPrimaryUse(self)
	if mgp_tool_isAnimPlaying(self, g_action_block_anims) or self.cl_waiting_for_data then
		return
	end

	local v_toolOwner = self.tool:getOwner()
	if not v_toolOwner then
		return
	end

	local v_ownerChar = v_toolOwner.character
	if not (v_ownerChar and sm.exists(v_ownerChar)) then
		return
	end

	if self.fireCooldownTimer > 0.0 or self.tool:isSprinting() then
		return
	end

	if self.cl_is_loaded then
		self.cl_is_loaded = false

		local dir = sm.camera.getDirection()
		local firePos = nil
		if self.tool:isInFirstPersonView() then
			firePos = self.tool:getFpBonePos("pejnt_barrel")
		else
			firePos = self.tool:getTpBonePos("pejnt_barrel")
		end

		local v_proj_hit = nil
		local v_ray_length = 1000
		local v_adjustment_angle = self:getAdjustmentAngle()

		local hit, result = sm.localPlayer.getRaycast(v_ray_length)
		if hit then
			v_proj_hit = calculateProjectileHit(result.originWorld, result.directionWorld, v_adjustment_angle, v_ray_length)
		else
			v_proj_hit = calculateProjectileHit(firePos, dir, v_adjustment_angle, v_ray_length)
		end

		-- Timers
		self.fireCooldownTimer = 1.3
		local fireMode = self.normalFireMode
		self.spreadCooldownTimer = math.min( self.spreadCooldownTimer + fireMode.spreadIncrement, fireMode.spreadCooldown )
		self.sprintCooldownTimer = self.sprintCooldown

		-- Send TP shoot over network and directly to self
		self:onShoot(v_proj_hit)
		self.network:sendToServer("sv_n_onShoot", v_proj_hit)

		sm.camera.setShake(0.2)

		-- Play FP shoot animation
		setFpAnimation( self.fpAnimations, self.aiming and "aimShoot" or "shoot", 0.0 )
	else
		self.cl_usedTimer = 1.5
		self.cl_used = true
		self.network:sendToServer("sv_n_throwAway")
		setFpAnimation( self.fpAnimations, "throwAway", 0.0 )
	end
end

function Panzerfaust:sv_n_throwAway()
	if sm.game.getEnableAmmoConsumption() and sm.game.getLimitedInventory() then
		self.sv_eraseTimer = 2.0
	end
end

function Panzerfaust:sv_n_onReload()
	self.network:sendToClients("cl_n_onReload")
end

function Panzerfaust:cl_n_onReload()
	if not self.cl_isLocal and self.tool:isEquipped() then
		self:cl_startReloadAnim()
	end
end

function Panzerfaust:cl_startReloadAnim()
	setTpAnimation(self.tpAnimations, "reload_empty", 1.0)
	mgp_toolAnimator_setAnimation(self, "reload_empty")
end

function Panzerfaust:cl_initReloadAnim(anim_id)
	setFpAnimation(self.fpAnimations, "reload_empty", 0.0)
	self:cl_startReloadAnim()

	--Send the animation data to all the other clients
	self.network:sendToServer("sv_n_onReload")
	self.cl_waiting_for_data = true
end

function Panzerfaust:client_onReload()
	if self.aiming and not mgp_tool_isAnimPlaying(self, g_action_block_anims) then
		self:client_setAimMode((self.aimMode + 1) % 3, true)
	end

	return true
end

function Panzerfaust:client_onToggle() return true end

local _intstate = sm.tool.interactState
function Panzerfaust:cl_onSecondaryUse(state)
	if not self.equipped then return end

	local is_reloading = mgp_tool_isAnimPlaying(self, g_action_block_anims) or self.cl_waiting_for_data ~= nil
	local new_state = (state == _intstate.start or state == _intstate.hold) and not is_reloading
	if self.aiming ~= new_state then
		self.aiming = new_state
		self.tpAnimations.animations.idle.time = 0

		if self.aiming then
			self.cl_sight_timer = 0.5
		end

		self.tool:setMovementSlowDown(self.aiming)
		self:onAim(self.aiming)
		self.network:sendToServer("sv_n_onAim", self.aiming)
	end
end

function Panzerfaust:cl_showRange()
	if not self.cl_sight_hud:isActive() then
		return
	end

	if mgp_tool_isAnimPlaying(self, g_action_block_anims) then
		return
	end

	local v_output_text = "#ffff00Range Estimation#ffffff: %s meters"

	local hit, result = sm.localPlayer.getRaycast(300)
	if hit then
		local v_distance = (result.pointWorld - result.originWorld):length()
		local v_range_text = ("#ff2d03%0.0f#ffffff"):format(v_distance)
		v_output_text = v_output_text:format(v_range_text)
	else
		v_output_text = v_output_text:format("More than #ff2d03300#ffffff")
	end

	sm.gui.displayAlertText(v_output_text, 2)
end

function Panzerfaust:client_onEquippedUpdate(primaryState, secondaryState, f)
	if primaryState == sm.tool.interactState.start then
		self:cl_onPrimaryUse()
	end

	self:cl_onSecondaryUse(secondaryState)

	if f ~= self.prevFState then
		self.prevFState = f
		if f then
			self:cl_showRange()
		end
	end

	return true, true
end