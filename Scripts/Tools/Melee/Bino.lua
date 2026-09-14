dofile( "$GAME_DATA/Scripts/game/AnimationUtil.lua" )
dofile( "$SURVIVAL_DATA/Scripts/util.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/survival_shapes.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/survival_projectiles.lua" )

dofile("$CONTENT_DATA/Scripts/Utils/ScopeRenderer.lua")
dofile("ToolAnimator.lua")
dofile("ToolSwimUtil.lua")

---@class Bino : ToolClass
---@field fpAnimations table
---@field tpAnimations table
---@field aiming boolean
---@field blendTime integer
---@field aimBlendSpeed integer
---@field sprintCooldown integer
---@field aim_timer integer
---@field scope_hud JsonGui
Bino = class()

local renderables = {
	"$CONTENT_DATA/Tools/Renderables/Melee/Bino/Bino_Base.rend",
	"$CONTENT_DATA/Tools/Renderables/Melee/Bino/Bino_Anim.rend"
}

local renderablesTp =
{
	"$CONTENT_DATA/Tools/Renderables/Melee/Bino/char_Bino_tp.rend",
	"$CONTENT_DATA/Tools/Renderables/Melee/Bino/Bino_offset_tp.rend"
}

local renderablesFp =
{
	"$CONTENT_DATA/Tools/Renderables/Melee/Bino/char_Bino_fp.rend",
	"$CONTENT_DATA/Tools/Renderables/Melee/Bino/Bino_offset_fp.rend",
	"$CONTENT_DATA/Tools/Renderables/char_male_fp_recoil.rend"
}

sm.tool.preloadRenderables( renderables )
sm.tool.preloadRenderables( renderablesTp )
sm.tool.preloadRenderables( renderablesFp )

function Bino:client_initAimVals()
	local cameraWeight, cameraFPWeight = self.tool:getCameraWeights()
	self.aimWeight = math.max( cameraWeight, cameraFPWeight )
	self.aimWeightFp = self.aimWeight
end

function Bino:client_onCreate()
	self:client_initAimVals()
	self.aimBlendSpeed = 3.0
	self.targetFov = 10.0
	self.currentFov = self.targetFov

	mgp_toolAnimator_initialize(self, "Bino")

	self.scope_hud = sm.jsonGui.createGui({
		isHud = true,
		isInteractive = false,
		needsCursor = false,
		hidesHotbar = true
	})
end

function Bino:client_onDestroy()
	local v_scopeHud = self.scope_hud
	if v_scopeHud and sm.exists(v_scopeHud) then
		if v_scopeHud:isActive() then
			v_scopeHud:close()
		end
	end

	mgp_toolAnimator_destroy(self)
end

function Bino:client_onRefresh()
	self:loadAnimations()
end

function Bino:loadAnimations()
	self.tpAnimations = createTpAnimations(
		self.tool,
		{
			aim = { "melee_aim", { crouch = "melee_crouch_aim" } },
			idle = { "melee_idle" },
			pickup = { "melee_pickup", { nextAnimation = "idle" } },
			putdown = { "melee_putdown" }
		}
	)
	local movementAnimations = {
		idle = "melee_idle",
		idleRelaxed = "melee_relax",

		sprint = "melee_sprint",
		runFwd = "melee_run_fwd",
		runBwd = "melee_run_bwd",

		jump = "melee_jump",
		jumpUp = "melee_jump_up",
		jumpDown = "melee_jump_down",

		land = "melee_jump_land",
		landFwd = "melee_jump_land_fwd",
		landBwd = "melee_jump_land_bwd",

		crouchIdle = "melee_crouch_idle",
		crouchFwd = "melee_crouch_fwd",
		crouchBwd = "melee_crouch_bwd"
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

	self.sprintCooldownTimer = 0.0
	self.sprintCooldown = 0.3

	self.blendTime = 0.2

	self.jointWeight = 0.0
	self.spineWeight = 0.0

	self:client_initAimVals()
end

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

local aim_animation_blacklist =
{
	["aim_anim"] = true
}

function Bino:client_updateAimWeights(dt)
	local weight_blend = 1 - math.pow( 1 - 1 / self.aimBlendSpeed, dt * 20 )

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

	self.tool:updateCamera( 2.8, self.currentFov + 5.0, sm.vec3.new( 0.65, 0.0, 0.05 ), self.aimWeight )
	self.tool:updateFpCamera( self.currentFov, sm.vec3.new( 0.0, 0.0, 0.0 ), self.aimWeightFp, bobbingFp )
end

function Bino:client_onUpdate(dt)
	mgp_toolAnimator_update(self, dt)
	self.currentFov = sm.util.lerp(self.currentFov, self.targetFov, dt * 5.0)

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
			if isSprinting and self.fpAnimations.currentAnimation ~= "sprintInto" and self.fpAnimations.currentAnimation ~= "sprintIdle" then
				swapFpAnimation( self.fpAnimations, "sprintExit", "sprintInto", 0.0 )
			elseif not isSprinting and ( self.fpAnimations.currentAnimation == "sprintIdle" or self.fpAnimations.currentAnimation == "sprintInto" ) then
				swapFpAnimation( self.fpAnimations, "sprintInto", "sprintExit", 0.0 )
			end

			if aim_animation_blacklist[self.fpAnimations.currentAnimation] == nil then
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
				setFpAnimation(self.fpAnimations, "aim_anim", 0.0)
				self.fpAnimations.animations.aim_anim.time = 0.5

				sm.gui.startFadeToBlack(1.0, 0.5)
				sm.gui.endFadeToBlack(0.8)
			end

			local instructions = nil
			if not self.hide_instructions then
				instructions = {
					{
						Anchor = "Top Left",
						TextAlign = "Top Left",
						Caption = ("#ffff00INSTRUCTIONS:#ffffff\n#ffff00%s#ffffff to zoom in\n#ffff00%s#ffffff to zoom out\n#ffff00%s#ffffff to measure distance"):format(
							sm.gui.getKeyBinding("Reload"),
							sm.gui.getKeyBinding("NextCreateRotation"),
							sm.gui.getKeyBinding("ForceBuild")),
						Childs = {},
						FontName = "SM_Text",
						Name = "HelpText",
						Skin = "TextBox",
						Type = "TextBox",
						NeedKey = false,
						NeedMouse = false,
						height = 70,
						width = 380,
						x = 20,
						y = 20
					}
				}
			end

			ScopeRenderer_RenderScopeImage(self.scope_hud, "$CONTENT_3269e6ef-4d80-4f75-b8f6-dffb303e5243/Gui/Bino.png", 7680, 4320, instructions)
		else
			if not v_aimState then
				self.scope_enabled = false
				setFpAnimation(self.fpAnimations, "aimExit", 0.0)
			end

			if self.scope_hud:isActive() then
				self.hide_instructions = true
				self.scope_hud:close()

				sm.gui.startFadeToBlack(1.0, 0.5)
				sm.gui.endFadeToBlack(0.8)
			end
		end
	end


	if self.cl_isLocal then
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
	self.tool:setBlockSprint(self.aiming or self.sprintCooldownTimer > 0.0)

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
				if name == "pickup" then
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
	self.tool:updateAnimation( "melee_spine_bend", finalAngle, self.spineWeight )

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

function Bino:client_onEquip(animate, is_custom)
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
	self.aim_timer = 0.5

	local currentRenderablesTp = {}
	local currentRenderablesFp = {}
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
end

function Bino:client_onUnequip(animate, is_custom)
	if not is_custom and TSU_IsOwnerSwimming(self) then
		return
	end

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

			if self.fpAnimations.currentAnimation ~= "unequip" then
				swapFpAnimation( self.fpAnimations, "equip", "unequip", 0.2 )
			end
		end
	end
end

function Bino:sv_n_onAim(aiming)
	self.network:sendToClients( "cl_n_onAim", aiming )
end

function Bino:cl_n_onAim(aiming)
	if not self.cl_isLocal and self.tool:isEquipped() then
		self:onAim( aiming )
	end
end

function Bino:onAim(aiming)
	self.aiming = aiming
	if self.tpAnimations.currentAnimation == "idle" or self.tpAnimations.currentAnimation == "aim" or self.tpAnimations.currentAnimation == "relax" and self.aiming then
		setTpAnimation( self.tpAnimations, self.aiming and "aim" or "idle", 5.0 )
	end
end

function Bino:cl_showRange()
	if not self.scope_hud:isActive() then
		return
	end

	local v_output_text = "#ffff00Range Estimation#ffffff: %s meters"

	local hit, result = sm.localPlayer.getRaycast(600)
	if hit then
		local v_distance = (result.pointWorld - result.originWorld):length()
		local v_range_text = ("#ff2d03%0.0f#ffffff"):format(v_distance)
		v_output_text = v_output_text:format(v_range_text)
	else
		v_output_text = v_output_text:format("More than #ff2d03600#ffffff")
	end

	sm.gui.displayAlertText(v_output_text, 2)
end

function Bino:client_onReload()
	if self.scope_enabled then
		self.targetFov = math.max(self.targetFov - 10.0, 10.0)
	end
	return true
end

function Bino:client_onToggle()
	if self.scope_enabled then
		self.targetFov = math.min(self.targetFov + 10.0, 30.0)
	end
	return true
end

local g_bino_aim_block_anims = {
	["aimInto"] = true,
	["aimExit"] = true,
	["equip"] = true
}

local _intstate = sm.tool.interactState
function Bino:client_onEquippedUpdate(primaryState, secondaryState, f)
	if self.scope_timer == nil and self.equipped then
		local newState = (
			primaryState == _intstate.start or
			primaryState == _intstate.hold or
			secondaryState == _intstate.start or
			secondaryState == _intstate.hold
		) and self.aim_timer == nil

		if self.aiming ~= newState and not mgp_tool_isAnimPlaying(self, g_bino_aim_block_anims) then
			self.aiming = newState
			self.tpAnimations.animations.idle.time = 0

			if self.aiming then
				self.scope_timer = 0.3
			else
				self.scope_timer = 0.5
			end

			self.tool:setMovementSlowDown(self.aiming)
			self:onAim(self.aiming)
			self.network:sendToServer("sv_n_onAim", self.aiming)
		end
	end

	if f ~= self.prevFState then
		self.prevFState = f
		if f then
			self:cl_showRange()
		end
	end

	return true, true
end