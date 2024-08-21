dofile( "$GAME_DATA/Scripts/game/AnimationUtil.lua" )
dofile( "$SURVIVAL_DATA/Scripts/util.lua" )
dofile( "$CONTENT_DATA/Scripts/Tools/Melee/survival_meleeattacks.lua" )

local Damage = 35
local maxCritDamage = 20
local minCritDamage = 5
local critChance = 35 -- %

---@class Knife : ToolClass
---@field isLocal boolean
---@field animationsLoaded boolean
---@field equipped boolean
---@field swingCooldowns table
---@field fpAnimations table
---@field tpAnimations table
Knife = class()

local renderables = {
	"$CONTENT_DATA/Tools/Renderables/Melee/Knife/Knife_Base.rend"
}

local renderablesTp = {"$CONTENT_DATA/Tools/Renderables/Melee/Knife/char_knife_tp.rend", "$CONTENT_DATA/Tools/Renderables/Melee/Knife/Knife_offset_tp.rend"}
local renderablesFp = {"$CONTENT_DATA/Tools/Renderables/Melee/Knife/char_knife_fp.rend", "$CONTENT_DATA/Tools/Renderables/Shotgun/Shotgun_offset_fp.rend"}

sm.tool.preloadRenderables( renderables )
sm.tool.preloadRenderables( renderablesTp )
sm.tool.preloadRenderables( renderablesFp )

local Range = 3.5
local SwingStaminaSpend = 1.5

Knife.swingCount = 2
Knife.mayaFrameDuration = 1.0/30.0
Knife.freezeDuration = 0.075

Knife.swings = { "melee_attack1", "melee_attack2" }
Knife.swingFrames = { 4.2 * Knife.mayaFrameDuration, 4.2 * Knife.mayaFrameDuration }
Knife.swingExits = { "melee_exit1", "melee_exit2" }

function Knife.client_onCreate( self )
	self.isLocal = self.tool:isLocal()
	self:init()
end

function Knife.client_onRefresh( self )
	self:init()
	self:loadAnimations()
end

function Knife.init( self )
	
	self.attackCooldownTimer = 0.0
	self.freezeTimer = 0.0
	self.pendingRaycastFlag = false
	self.nextAttackFlag = false
	self.currentSwing = 1
	
	self.swingCooldowns = {}
	for i = 1, self.swingCount do
		self.swingCooldowns[i] = 0.0
	end
	
	self.dispersionFraction = 0.001
	
	self.blendTime = 0.2
	self.blendSpeed = 10.0
	
	self.sharedCooldown = 0.0
	self.hitCooldown = 1.0
	self.blockCooldown = 0.5
	self.swing = false
	self.block = false
	
	self.wantBlockSprint = false
	
	if self.animationsLoaded == nil then
		self.animationsLoaded = false
	end
end

function Knife.loadAnimations( self )

	self.tpAnimations = mgp_tool_createTpAnimations(
		self.tool,
		{
			equip = { "melee_pickup", { nextAnimation = "idle", blendNext = 0.2 } },
			unequip = { "melee_putdown" },
			idle = {"melee_idle", { looping = true } },
			idleRelaxed = {"melee_idle_relaxed", { looping = true } },

			melee_attack1 = { "melee_attack1", { nextAnimation = "melee_exit1", blendNext = 0.2 } },
			melee_attack2 = { "melee_attack2", { nextAnimation = "melee_exit2", blendNext = 0.2 } },
			melee_exit1 = { "melee_exit1", { nextAnimation = "idle", blendNext = 0.2 } },
			melee_exit2 = { "melee_exit2", { nextAnimation = "idle", blendNext = 0.2 } },
		}
	)
	local movementAnimations = {
		idle = "melee_idle",
		idleRelaxed = "melee_idle",

		runFwd = "melee_run_fwd",
		runBwd = "melee_run_bwd",

		sprint = "melee_sprint",

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

	if self.isLocal then
		self.fpAnimations = createFpAnimations(
			self.tool,
			{
				equip = { "melee_pickup", { nextAnimation = "idle", blendNext = 0.2 } },
				unequip = { "melee_putdown" },	
				idle = { "melee_idle",  { looping = true } },

				sprintInto = { "melee_sprint_into", { nextAnimation = "sprintIdle" } },
				sprintIdle = { "melee_sprint_idle", { looping = true } },
				sprintExit = { "melee_sprint_exit", { nextAnimation = "idle" } },

				melee_attack1 = { "melee_attack1", { nextAnimation = "melee_exit1", blendNext = 0.2 } },
				melee_attack2 = { "melee_attack2", { nextAnimation = "melee_exit2", blendNext = 0.2 } },
				melee_exit1 = { "melee_exit1", { nextAnimation = "idle", blendNext = 0.2 } },
				melee_exit2 = { "melee_exit2", { nextAnimation = "idle", blendNext = 0.2 } },
			}
		)
		setFpAnimation( self.fpAnimations, "idle", 0.0 )
	end
	--self.swingCooldowns[1] = self.fpAnimations.animations["melee_attack1"].info.duration
	self.swingCooldowns[1] = 0.5 --0.6
	--self.swingCooldowns[2] = self.fpAnimations.animations["melee_attack2"].info.duration
	self.swingCooldowns[2] = 0.5 --0.6
	
	self.animationsLoaded = true

end

function Knife.client_onUpdate( self, dt )
	if not self.animationsLoaded then
		return
	end

	--synchronized update
	self.attackCooldownTimer = math.max( self.attackCooldownTimer - dt, 0.0 )

	--standard third person updateAnimation
	updateTpAnimations( self.tpAnimations, self.equipped, dt )

	--update
	if self.isLocal then

		if self.fpAnimations.currentAnimation == self.swings[self.currentSwing] then
			self:updateFreezeFrame(self.swings[self.currentSwing], dt)
		end

		local preAnimation = self.fpAnimations.currentAnimation

		updateFpAnimations( self.fpAnimations, self.equipped, dt )

		if preAnimation ~= self.fpAnimations.currentAnimation then

			-- Ended animation - re-evaluate what next state is

			local keepBlockSprint = false
			local endedSwing = preAnimation == self.swings[self.currentSwing] and self.fpAnimations.currentAnimation == self.swingExits[self.currentSwing]
			if self.nextAttackFlag == true and endedSwing == true then
				-- Ended swing with next attack flag

				-- Next swing
				self.currentSwing = self.currentSwing + 1
				if self.currentSwing > self.swingCount then
					self.currentSwing = 1
				end
				local params = { name = self.swings[self.currentSwing] }
				self.network:sendToServer( "server_startEvent", params )
				sm.audio.play( "Sledgehammer - Swing" )
				self.pendingRaycastFlag = true
				self.nextAttackFlag = false
				self.attackCooldownTimer = self.swingCooldowns[self.currentSwing]
				keepBlockSprint = true

			elseif isAnyOf( self.fpAnimations.currentAnimation, { "guardInto", "guardIdle", "guardExit", "guardBreak", "guardHit" } )  then
				keepBlockSprint = true
			end

			--Stop sprint blocking
			self.tool:setBlockSprint(keepBlockSprint)
		end

		local isSprinting =  self.tool:isSprinting() 
		if isSprinting and self.fpAnimations.currentAnimation == "idle" and self.attackCooldownTimer <= 0 and not isAnyOf( self.fpAnimations.currentAnimation, { "sprintInto", "sprintIdle" } ) then
			local params = { name = "sprintInto" }
			self:client_startLocalEvent( params )
		end

		if ( not isSprinting and isAnyOf( self.fpAnimations.currentAnimation, { "sprintInto", "sprintIdle" } ) ) and self.fpAnimations.currentAnimation ~= "sprintExit" then
			local params = { name = "sprintExit" }
			self:client_startLocalEvent( params )
		end
	end
end

function Knife.updateFreezeFrame( self, state, dt )
	local p = 1 - math.max( math.min( self.freezeTimer / self.freezeDuration, 1.0 ), 0.0 )
	local playRate = p * p * p * p
	self.fpAnimations.animations[state].playRate = playRate
	self.freezeTimer = math.max( self.freezeTimer - dt, 0.0 )
end

function Knife.server_startEvent( self, params )
	local player = self.tool:getOwner()
	if player then
		sm.event.sendToPlayer( player, "sv_e_staminaSpend", SwingStaminaSpend )
	end
	self.network:sendToClients( "client_startLocalEvent", params )
end

function Knife.client_startLocalEvent( self, params )
	self:client_handleEvent( params )
end

function Knife.client_handleEvent( self, params )

	-- Setup animation data on equip
	if params.name == "equip" then
		self.equipped = true
		--self:loadAnimations()
	elseif params.name == "unequip" then
		self.equipped = false
	end

	if not self.animationsLoaded then
		return
	end

	--Maybe not needed
-------------------------------------------------------------------

	-- Third person animations
	local tpAnimation = self.tpAnimations.animations[params.name]
	if tpAnimation then
		local isSwing = false
		for i = 1, self.swingCount do
			if self.swings[i] == params.name then
				self.tpAnimations.animations[self.swings[i]].playRate = 1
				isSwing = true
			end
		end

		local blend = not isSwing
		setTpAnimation( self.tpAnimations, params.name, blend and 0.2 or 0.0 )
	end

	-- First person animations
	if self.isLocal then
		local isSwing = false

		for i = 1, self.swingCount do
			if self.swings[i] == params.name then
				self.fpAnimations.animations[self.swings[i]].playRate = 1
				isSwing = true
			end
		end

		if isSwing or isAnyOf( params.name, { "guardInto", "guardIdle", "guardExit", "guardBreak", "guardHit" } ) then
			self.tool:setBlockSprint( true )
		else
			self.tool:setBlockSprint( false )
		end

		if params.name == "guardInto" then
			swapFpAnimation( self.fpAnimations, "guardExit", "guardInto", 0.2 )
		elseif params.name == "guardExit" then
			swapFpAnimation( self.fpAnimations, "guardInto", "guardExit", 0.2 )
		elseif params.name == "sprintInto" then
			swapFpAnimation( self.fpAnimations, "sprintExit", "sprintInto", 0.2 )
		elseif params.name == "sprintExit" then
			swapFpAnimation( self.fpAnimations, "sprintInto", "sprintExit", 0.2 )
		else
			local blend = not ( isSwing or isAnyOf( params.name, { "equip", "unequip" } ) )
			setFpAnimation( self.fpAnimations, params.name, blend and 0.2 or 0.0 )
		end

	end
end

function Knife.client_onEquippedUpdate( self, primaryState, secondaryState )
	if self.pendingRaycastFlag then
		local time = 0.0
		local frameTime = 0.0
		if self.fpAnimations.currentAnimation == self.swings[self.currentSwing] then
			time = self.fpAnimations.animations[self.swings[self.currentSwing]].time
			frameTime = self.swingFrames[self.currentSwing]
		end
		if time >= frameTime and frameTime ~= 0 then
			self.pendingRaycastFlag = false
			local raycastStart = sm.localPlayer.getRaycastStart()
			local direction = sm.localPlayer.getDirection()
			sm.melee.meleeAttack( melee_sledgehammer, Damage, raycastStart, direction * Range, self.tool:getOwner() )

			local success, result = sm.localPlayer.getRaycast( Range, raycastStart, direction )
			if success then
				self.freezeTimer = self.freezeDuration
			end
		end
	end

	--Start attack?
	self.startedSwinging = ( self.startedSwinging or primaryState == sm.tool.interactState.start ) and primaryState ~= sm.tool.interactState.stop and primaryState ~= sm.tool.interactState.null
	if primaryState == sm.tool.interactState.start or ( primaryState == sm.tool.interactState.hold and self.startedSwinging ) then
		--Check if we are currently playing a swing
		if self.fpAnimations.currentAnimation == self.swings[self.currentSwing] then
			if self.attackCooldownTimer < 0.125 then
				self.nextAttackFlag = true
			end
		else
			--Not currently swinging
			--Is the prev attack done?
			if self.attackCooldownTimer <= 0 then
				self.currentSwing = 1
				--Not sprinting and not close to anything
				--Start swinging!
				local params = { name = self.swings[self.currentSwing] }
				self.network:sendToServer( "server_startEvent", params )
				sm.audio.play( "Sledgehammer - Swing" )
				self.pendingRaycastFlag = true
				self.nextAttackFlag = false
				self.attackCooldownTimer = self.swingCooldowns[self.currentSwing]
			end
		end
	end

	--Secondary destruction
	return true, false
end

function Knife.client_onEquip( self, animate )

	if animate then
		sm.audio.play( "Sledgehammer - Equip", self.tool:getPosition() )
	end

	self.equipped = true

	for k,v in pairs( renderables ) do renderablesTp[#renderablesTp+1] = v end
	for k,v in pairs( renderables ) do renderablesFp[#renderablesFp+1] = v end

	self.tool:setTpRenderables(renderablesTp)
	if self.isLocal then
		self.tool:setFpRenderables(renderablesFp)
	end

	self:init()
	self:loadAnimations()

	setTpAnimation( self.tpAnimations, "equip", 0.0001 )

	if self.isLocal then
		swapFpAnimation( self.fpAnimations, "unequip", "equip", 0.2 )
	end
end

function Knife.client_onUnequip( self, animate )

	self.equipped = false
	if sm.exists( self.tool ) then
		if animate then
			sm.audio.play( "Sledgehammer - Unequip", self.tool:getPosition() )
		end
		setTpAnimation( self.tpAnimations, "unequip" )
		if self.isLocal and self.fpAnimations.currentAnimation ~= "unequip" then
			swapFpAnimation( self.fpAnimations, "equip", "unequip", 0.2 )
		end
	end
end
