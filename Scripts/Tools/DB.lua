dofile( "$GAME_DATA/Scripts/game/AnimationUtil.lua" )
dofile( "$SURVIVAL_DATA/Scripts/util.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/survival_shapes.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/survival_projectiles.lua" )

dofile("ToolAnimator.lua")
dofile("ToolSwimUtil.lua")
dofile("BaseGun.lua")

---@class DoubleBarrel : BaseGun
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
DB = class(BaseGun)
DB.reimburseAmmo = false
DB.mag_capacity = 2
DB.defaultSelectedMods = {
	ammo = "a2fc1d9c-7c00-4d29-917b-6b9e26ea32a2"
}
DB.modificationData = {
	layout = "$CONTENT_DATA/Gui/Layouts/DB_mods.layout",
	mods = {
		ammo = {
			CanBeUnEquipped = false,
			["a2fc1d9c-7c00-4d29-917b-6b9e26ea32a2"] = {
				minSpendAmount = 2,
				getReturnAmount = function(self, toolSelf)
					return toolSelf.sv_ammo_counter
				end,
				Sv_OnEquip = function(self, toolSelf)
					toolSelf.sv_ammo_counter = toolSelf.mag_capacity --math.min(sm.container.totalQuantity(toolSelf.tool:getOwner():getInventory(), self.shells), toolSelf.mag_capacity)
					toolSelf.network:setClientData({ ammo = toolSelf.sv_ammo_counter, mods = toolSelf.sv_selectedMods })
				end,
				Cl_OnEquip = function(self, toolSelf)
					setTpAnimation(toolSelf.tpAnimations, "reload_type", 10)
					mgp_toolAnimator_setAnimation(toolSelf, "reload_type")

					if toolSelf.cl_isLocal then
						setFpAnimation(toolSelf.fpAnimations, "reload_type", 0.001)
					end

					return true
				end,
				projectile = sm.uuid.new("228fb03c-9b81-4460-b841-5fdc2eea3596"),
				shells = sm.uuid.new("a2fc1d9c-7c00-4d29-917b-6b9e26ea32a2"),
				damage = 14,
				colour = sm.color.new("#7b3030ff"),
				name = "Birdshot"
			},
			["a2a1b12e-8045-4ab0-9577-8b63c06a55c2"] = {
				minSpendAmount = 2,
				getReturnAmount = function(self, toolSelf)
					return toolSelf.sv_ammo_counter
				end,
				Sv_OnEquip = function(self, toolSelf)
					toolSelf.sv_ammo_counter = toolSelf.mag_capacity
					toolSelf.network:setClientData({ ammo = toolSelf.sv_ammo_counter, mods = toolSelf.sv_selectedMods })
				end,
				Cl_OnEquip = function(self, toolSelf)
					setTpAnimation(toolSelf.tpAnimations, "reload_type", 10)
					mgp_toolAnimator_setAnimation(toolSelf, "reload_type")

					if toolSelf.cl_isLocal then
						setFpAnimation(toolSelf.fpAnimations, "reload_type", 0.001)
					end

					return true
				end,
				projectile = sm.uuid.new("35588452-1e08-46e8-aaf1-e8abb0cf7692"),
				shells = sm.uuid.new("a2a1b12e-8045-4ab0-9577-8b63c06a55c2"),
				damage = 80,
				colour = sm.color.new("#307326ff"),
				name = "Sabot"
			}
		}
	}
}
DB.reload_anims =
{
	["ammo_check"   ] = true,
	["reload"		] = true,
	["reload_empty"	] = true,
	["reload_type"	] = true
}
DB.maxRecoil = 30
DB.recoilAmount = 20
DB.aimRecoilAmount = 12
DB.recoilRecoverySpeed = 0.85
DB.aimFovTp = 40
DB.aimFovFp = 40

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
	"$CONTENT_DATA/Tools/Renderables/DB/DB_fp_offset.rend",
	"$CONTENT_DATA/Tools/Renderables/char_male_fp_recoil.rend"
}

sm.tool.preloadRenderables( renderables )
sm.tool.preloadRenderables( renderablesTp )
sm.tool.preloadRenderables( renderablesFp )

function DB:client_initAimVals()
	local cameraWeight, cameraFPWeight = self.tool:getCameraWeights()
	self.aimWeight = math.max( cameraWeight, cameraFPWeight )
end

function DB:server_onCreate()
	self:sv_init()
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

	self:cl_init()
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
			shoot = { "spudgun_shoot", { nextAnimation = "idle" } },
			aim = { "spudgun_aim", { crouch = "spudgun_crouch_aim" } },
			aimShoot = { "spudgun_aim_shoot", { crouch = "spudgun_crouch_aim_shoot" } },

			idle = { "spudgun_idle" },
			pickup = { "spudgun_pickup", { nextAnimation = "idle" } },
			putdown = { "spudgun_putdown" },

			reload_empty = { "DB_tp_empty_reload", { nextAnimation = "idle", duration = 1.0 } },
			reload_type = { "DB_tp_type", { nextAnimation = "idle", duration = 1.0 } },
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

	if self.cl_isLocal then
		self.fpAnimations = createFpAnimations(
			self.tool,
			{
				equip = { "DB_pickup", { nextAnimation = "idle" } },
				unequip = { "DB_putdown" },

				idle = { "DB_idle_1", { nextAnimation = "idle" } },

				shoot = { "DB_shoot_1", { nextAnimation = "idle" } },
				reload = { "DB_reload_1", { nextAnimation = "idle", duration = 1.0 } },
				reload_empty = { "DB_reload_0", { nextAnimation = "idle", duration = 1.0 } },
				reload_type = { "DB_reload_type", { nextAnimation = "idle", duration = 1.0 } },
				ammo_check = { "DB_ammo_check", { nextAnimation = "idle", duration = 1.0 } },

				aimInto = { "DB_aim_into", { nextAnimation = "aimIdle" } },
				aimExit = { "DB_aim_exit", { nextAnimation = "idle", blendNext = 0 } },
				aimIdle = { "DB_aim_idle", { looping = true } },
				aimShoot = { "DB_aim_shoot", { nextAnimation = "aimIdle"} },

				sprintInto = { "DB_sprint_into", { nextAnimation = "sprintIdle",  blendNext = 0.2 } },
				sprintExit = { "DB_sprint_exit", { nextAnimation = "idle",  blendNext = 0 } },
				sprintIdle = { "DB_sprint_idle", { looping = true } },

				modInto = { "DB_modSelect_into", { nextAnimation = "modIdle" } },
				modExit = { "DB_modSelect_exit", { nextAnimation = "idle", blendNext = 0 } },
				modIdle = { "DB_modSelect_idle", { looping = true } },
			}
		)
	end

	self.normalFireMode = {
		fireCooldown = 0.25,
		spreadCooldown = 0.2,
		spreadIncrement = 3,
		spreadMinAngle = 1,
		spreadMaxAngle = 2,
		fireVelocity = 150.0,

		minDispersionStanding = 0.1,
		minDispersionCrouching = 0.04,

		maxMovementDispersion = 0.4,
		jumpDispersionMultiplier = 2
	}

	self.aimFireMode = {
		fireCooldown = 0.25,
		spreadCooldown = 0.3,
		spreadIncrement = 3,
		spreadMinAngle = 1,
		spreadMaxAngle = 2,
		fireVelocity = 150.0,

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
	["reload_empty"] = true,
	["reload_type"] = true
}

local aim_animations =
{
	["aimInto"]         = true,
	["aimIdle"]         = true,
	["aimShoot"]        = true
}

function DB:server_spendAmmo(data, player)
	if data ~= nil or player ~= nil then return end

	local v_owner = self.tool:getOwner()
	if v_owner == nil then return end

	local v_inventory = v_owner:getInventory()
	if v_inventory == nil then return end

	local mgp_shotgun_ammo = mgp_tool_GetSelectedMod(self, "ammo").shells
	local v_available_ammo = sm.container.totalQuantity(v_inventory, mgp_shotgun_ammo)
	if v_available_ammo == 0 then return end

	local v_raw_spend_count = math.max(self.mag_capacity - self.sv_ammo_counter, 0)
	local v_spend_count = math.min(v_raw_spend_count, math.min(v_available_ammo, self.mag_capacity))

	sm.container.beginTransaction()
	sm.container.spend(v_inventory, mgp_shotgun_ammo, v_spend_count)
	sm.container.endTransaction()

	self.sv_ammo_counter = self.sv_ammo_counter + v_spend_count
	self:server_updateStorage()
end

function DB:sv_n_trySpendAmmo(data, player)
	local v_owner = self.tool:getOwner()
	if v_owner == nil or v_owner ~= player then return end

	self:server_spendAmmo()
	self.network:sendToClient(v_owner, "client_receiveAmmo", self.sv_ammo_counter)
end

function DB:client_onUpdate(dt)
	mgp_toolAnimator_update(self, dt)

	-- First person animation
	local isSprinting = self.tool:isSprinting()
	local isCrouching = self.tool:isCrouching()

	if self.cl_isLocal then
		if self.equipped then
			local cur_anim_cache = self.fpAnimations.currentAnimation
			if isSprinting and cur_anim_cache ~= "sprintInto" and cur_anim_cache ~= "sprintIdle" then
				swapFpAnimation( self.fpAnimations, "sprintExit", "sprintInto", 0.0 )
			elseif not isSprinting and ( cur_anim_cache == "sprintIdle" or cur_anim_cache == "sprintInto" ) then
				swapFpAnimation( self.fpAnimations, "sprintInto", "sprintExit", 0.0 )
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
	self.tool:setBlockSprint(self.sprintCooldownTimer > 0.0 or self:client_isGunReloading() or self.aiming)

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
					setTpAnimation( self.tpAnimations, self.aiming and "aim" or "idle", 10 )
				elseif name == "pickup" then
					setTpAnimation( self.tpAnimations, self.aiming and "aim" or "idle", 0.001 )
				elseif actual_reload_anims[name] == true then
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

function DB:client_onEquip(animate, is_custom)
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
	for k,v in pairs( renderables ) do
		currentRenderablesTp[#currentRenderablesTp+1] = v
		currentRenderablesFp[#currentRenderablesFp+1] = v
	end

	mgp_toolAnimator_onModdedToolEquip(self, currentRenderablesFp, currentRenderablesTp, {})

	--Set the tp and fp renderables before actually loading animations
	self.tool:setTpRenderables( currentRenderablesTp )
	if self.cl_isLocal then
		self.tool:setFpRenderables(currentRenderablesFp)
	end

	self:cl_updateColour()

	--Load animations before setting them
	self:loadAnimations()

	--Set tp and fp animations
	setTpAnimation( self.tpAnimations, "pickup", 0.0001 )
	if self.cl_isLocal then
		swapFpAnimation(self.fpAnimations, "unequip", "equip", 0.2)
	end
end

function DB:cl_updateColour()
	local colour = mgp_tool_GetSelectedMod(self, "ammo").colour
	self.tool:setTpColor(colour)
	if self.cl_isLocal then
		self.tool:setFpColor(colour)
	end
end

function DB:client_onUnequip(animate, is_custom)
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

function DB:sv_n_onAim(aiming)
	self.network:sendToClients( "cl_n_onAim", aiming )
end

function DB:cl_n_onAim(aiming)
	if not self.cl_isLocal and self.tool:isEquipped() then
		self:onAim(aiming)
	end
end

function DB:onAim(aiming)
	self.aiming = aiming
	if self.tpAnimations.currentAnimation == "idle" or self.tpAnimations.currentAnimation == "aim" or self.tpAnimations.currentAnimation == "relax" and self.aiming then
		setTpAnimation( self.tpAnimations, self.aiming and "aim" or "idle", 5.0 )
	end
end


function DB:sv_n_onShoot()
	self.network:sendToClients("cl_n_onShoot")

	if self.sv_ammo_counter > 0 then
		self.sv_ammo_counter = self.sv_ammo_counter - 1
		self:server_updateStorage()
	end
end

function DB:cl_n_onShoot()
	if not self.cl_isLocal and self.tool:isEquipped() then
		self:onShoot()
	end
end

function DB:onShoot()
	local v_anim_name = self.aiming and "aimShoot" or "shoot"
	mgp_toolAnimator_setAnimation(self, v_anim_name)
	setTpAnimation(self.tpAnimations, v_anim_name, 1.0)
end

function DB:cl_onPrimaryUse()
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

		if self.ammo_in_mag > 0 then
			self.ammo_in_mag = self.ammo_in_mag - 1

			local dir = mgp_tool_getToolDir(self)
			local firePos = nil
			if self.tool:isInFirstPersonView() then
				firePos = self.tool:getFpBonePos("pejnt_barrel")
			else
				firePos = self.tool:getTpBonePos("pejnt_barrel")
			end

			local fireMode = self.aiming and self.aimFireMode or self.normalFireMode
			local typeData = mgp_tool_GetSelectedMod(self, "ammo")
			sm.projectile.projectileAttack(typeData.projectile, typeData.damage, firePos, dir * fireMode.fireVelocity, v_toolOwner)

			-- Timers
			self.fireCooldownTimer = fireMode.fireCooldown
			self.spreadCooldownTimer = math.min( self.spreadCooldownTimer + fireMode.spreadIncrement, fireMode.spreadCooldown )
			self.sprintCooldownTimer = self.sprintCooldown

			-- Send TP shoot over network and dircly to self
			self:onShoot()
			self.network:sendToServer("sv_n_onShoot")

			-- Play FP shoot animation
			setFpAnimation( self.fpAnimations, self.aiming and "aimShoot" or "shoot", 0.0 )
		else
			local fireMode = self.aiming and self.aimFireMode or self.normalFireMode
			self.fireCooldownTimer = fireMode.fireCooldown
			sm.audio.play( "PotatoRifle - NoAmmo" )
		end
	end
end

local ammo_count_to_anim_name =
{
	[0] = "reload_empty",
	[1] = "reload"
}

function DB:sv_n_onReload(anim_id)
	self.network:sendToClients("cl_n_onReload", anim_id)
end

function DB:cl_n_onReload(anim_id)
	if not self.cl_isLocal and self.tool:isEquipped() then
		self:cl_startReloadAnim(ammo_count_to_anim_name[anim_id])
	end
end

function DB:cl_startReloadAnim(anim_name)
	setTpAnimation(self.tpAnimations, anim_name, 1.0)
	mgp_toolAnimator_setAnimation(self, anim_name)
end

function DB:cl_initReloadAnim(anim_id)
	if sm.game.getEnableAmmoConsumption() then
		if sm.container.totalQuantity(sm.localPlayer.getInventory(), mgp_tool_GetSelectedMod(self, "ammo").shells) < self.mag_capacity then
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
		if not self:client_isGunReloading() and not self.aiming and not self.tool:isSprinting() and self.fireCooldownTimer == 0.0 then
			self:cl_initReloadAnim(self.ammo_in_mag)
		end
	end

	return true
end

local _intstate = sm.tool.interactState
function DB.cl_onSecondaryUse( self, state )
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

function DB:client_onEquippedUpdate(primaryState, secondaryState, f)
	if primaryState == sm.tool.interactState.start then
		self:cl_onPrimaryUse()
	end

	if secondaryState ~= self.prevSecondaryState then
		self:cl_onSecondaryUse( secondaryState )
		self.prevSecondaryState = secondaryState
	end

	return true, true
end