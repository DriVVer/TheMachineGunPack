dofile("$GAME_DATA/Scripts/game/AnimationUtil.lua")
dofile("$SURVIVAL_DATA/Scripts/util.lua")
dofile("$SURVIVAL_DATA/Scripts/game/survival_shapes.lua")
dofile("$SURVIVAL_DATA/Scripts/game/survival_projectiles.lua")

dofile("ToolAnimator.lua")
dofile("ToolSwimUtil.lua")
dofile("$CONTENT_DATA/Scripts/MedkitProgressbar.lua")

local renderables =
{
	"$CONTENT_DATA/Tools/Renderables/Medkit/Medkit_Base.rend",
	"$CONTENT_DATA/Tools/Renderables/Medkit/Medkit_Bag.rend",
	"$CONTENT_DATA/Tools/Renderables/Medkit/Medkit_Syr.rend"
}

local renderablesTp = {
	"$CONTENT_DATA/Tools/Renderables/Medkit/char_male_tp_Medkit.rend",
	"$CONTENT_DATA/Tools/Renderables/Medkit/char_Medkit_tp_offset.rend"
}

local renderablesFp = {
	"$CONTENT_DATA/Tools/Renderables/Medkit/char_male_fp_Medkit.rend",
	"$CONTENT_DATA/Tools/Renderables/Medkit/char_Medkit_fp_offset.rend"
}

sm.tool.preloadRenderables(renderables)
sm.tool.preloadRenderables(renderablesTp)
sm.tool.preloadRenderables(renderablesFp)

---@class Medkit : ToolClass
---@field fpAnimations table
---@field tpAnimations table
---@field cl_isLocal boolean
Medkit = class()
Medkit.healTime = 3.75
Medkit.restoredStats = { hpGain = 75 }
Medkit.itemUuid = sm.uuid.new("4664a470-275f-4799-a54f-6a4a2111f436")

function Medkit:server_onCreate()
	self.sv_using = false
	self.sv_useProgress = 0
end

function Medkit:server_onFixedUpdate(dt)
	if self.sv_using then
		if self.sv_targetChar then
			local char = self.tool:getOwner().character
			local start = char.worldPosition + (char:isCrouching() and sm.vec3.new(0,0,0.3) or sm.vec3.new(0,0,0.575))
			local hit, result = sm.physics.raycast(start, start + char.direction * 7.5)
			local targetChar = result:getCharacter()
			if self.sv_targetChar ~= targetChar then
				self:sv_updateUse()
				return
			end
		end

		self.sv_useProgress = self.sv_useProgress + dt
		if self.sv_useProgress >= self.healTime then
			local owner = self.tool:getOwner()
			local container = owner:getInventory()
			if self.sv_targetChar then
				sm.event.sendToPlayer(self.sv_targetChar:getPlayer(), "sv_e_feed", { foodUuid = self.itemUuid, playerInventory = container })
			else
				sm.event.sendToPlayer(owner, "sv_e_eat", self.restoredStats)

				sm.container.beginTransaction()
				sm.container.spendFromSlot(container, self.sv_selectedSlot, self.itemUuid, 1)
				sm.container.endTransaction()
			end

			self:sv_updateUse()
		end
	end
end

function Medkit:sv_updateUse(slot)
	local player
	if type(slot) == "table" then
		slot, player = slot[1], slot[2]
	end

	local state = slot ~= nil
	if state == self.sv_using then return end

	self.sv_using = state
	self.sv_targetChar = player
	self.sv_useProgress = 0
	self.sv_selectedSlot = slot

	self.network:sendToClients("cl_updateUse", state)
end



function Medkit:client_onCreate()
	mgp_toolAnimator_initialize(self, "Medkit")

	self.cl_using = false
	self.cl_useProgress = 0

	if self.cl_isLocal then
		self.progressbar = MedkitProgressbar():init(100, 1/self.healTime)
	end
end

function Medkit:cl_updateUse(state)
	self.cl_using = state
	self.cl_useProgress = 0

	if not self.tool:isEquipped() then return end

	if state then
		local anim = math.random() > 0.5 and "use" or "use2"
		setTpAnimation(self.tpAnimations, anim, 10)
		if self.cl_isLocal then
			setFpAnimation(self.fpAnimations, anim,  0.2)
			self.progressbar:open()
		end

		mgp_toolAnimator_setAnimation(self, anim)
	else
		setTpAnimation(self.tpAnimations, "pickup", 10)
		if self.cl_isLocal then
			swapFpAnimation(self.fpAnimations, "unequip", "equip", 0.2)
			self.progressbar:update(0)
			self.progressbar:close()
		end

		mgp_toolAnimator_setAnimation(self, "on_equip")
	end
end

function Medkit:client_onDestroy()
	mgp_toolAnimator_destroy(self)

	if self.cl_isLocal then
		self.progressbar:destroy()
	end
end

function Medkit:client_onUpdate(dt)
	mgp_toolAnimator_update(self, dt)

	local isSprinting = self.tool:isSprinting()
	local isCrouching = self.tool:isCrouching()

	if self.cl_isLocal then
		if self.equipped then
			if self.cl_using then
				self.cl_useProgress = math.min(self.cl_useProgress + dt, self.healTime)
				self.progressbar:update(self.cl_useProgress/self.healTime)
			else
				if isSprinting and self.fpAnimations.currentAnimation ~= "sprintInto" and self.fpAnimations.currentAnimation ~= "sprintIdle" then
					swapFpAnimation(self.fpAnimations, "sprintExit", "sprintInto", 0.0)
				elseif not isSprinting and (self.fpAnimations.currentAnimation == "sprintIdle" or self.fpAnimations.currentAnimation == "sprintInto") then
					swapFpAnimation(self.fpAnimations, "sprintInto", "sprintExit", 0.0)
				end
			end
		end
		updateFpAnimations(self.fpAnimations, self.equipped, dt)
	end

	if not self.equipped then
		if self.wantEquipped then
			self.wantEquipped = false
			self.equipped = true
		end

		return
	end

	self.tool:setBlockSprint(self.cl_using)

	local crouchWeight = isCrouching and 1.0 or 0.0
	local normalWeight = 1.0 - crouchWeight

	local totalWeight = 0.0
	for name, animation in pairs(self.tpAnimations.animations) do
		animation.time = animation.time + dt

		if name == self.tpAnimations.currentAnimation then
			animation.weight = math.min(animation.weight + (self.tpAnimations.blendSpeed * dt), 1.0)

			if animation.time >= animation.info.duration - self.blendTime then
				if animation.nextAnimation ~= "" then
					setTpAnimation(self.tpAnimations, animation.nextAnimation, 0.001)
				end
			end
		else
			animation.weight = math.max(animation.weight - (self.tpAnimations.blendSpeed * dt), 0.0)
		end

		totalWeight = totalWeight + animation.weight
	end

	totalWeight = totalWeight == 0 and 1.0 or totalWeight
	for name, animation in pairs(self.tpAnimations.animations) do
		local weight = animation.weight / totalWeight
		if name == "idle" then
			self.tool:updateMovementAnimation(animation.time, weight)
		elseif animation.crouch then
			self.tool:updateAnimation(animation.info.name, animation.time, weight * normalWeight)
			self.tool:updateAnimation(animation.crouch.name, animation.time, weight * crouchWeight)
		else
			self.tool:updateAnimation(animation.info.name, animation.time, weight)
		end
	end
end

function Medkit:client_onEquip(animate)
	if animate then
		sm.audio.play("Sledgehammer - Equip", self.tool:getPosition())
	end

	self.wantEquipped = true

	local currentRenderablesTp = {}
	local currentRenderablesFp = {}

	for k, v in pairs(renderablesTp) do currentRenderablesTp[#currentRenderablesTp + 1] = v end
	for k, v in pairs(renderablesFp) do currentRenderablesFp[#currentRenderablesFp + 1] = v end
	for k, v in pairs(renderables) do
		currentRenderablesTp[#currentRenderablesTp+1] = v
		currentRenderablesFp[#currentRenderablesFp+1] = v
	end

	self.tool:setTpRenderables(currentRenderablesTp)
	if self.cl_isLocal then
		self.tool:setFpRenderables(currentRenderablesFp)
	end

	self:loadAnimations()

	setTpAnimation(self.tpAnimations, "pickup", 0.0001)
	if self.cl_isLocal then
		swapFpAnimation(self.fpAnimations, "unequip", "equip", 0.2)

		self.tool:setCrossHairAlpha(0.0)
	end

	mgp_toolAnimator_setAnimation(self, "on_equip")
end

function Medkit:client_onUnequip()
	self.wantEquipped = false
	self.equipped = false

	self:cl_updateUse(false)

	self.tool:setBlockSprint(false)

	setTpAnimation( self.tpAnimations, "putdown" )
	if self.cl_isLocal then
		self.network:sendToServer("sv_updateUse")

		self.progressbar:close()

		if self.fpAnimations.currentAnimation ~= "unequip" then
			swapFpAnimation( self.fpAnimations, "equip", "unequip", 0.2 )
		end
	end
end

function Medkit:client_onEquippedUpdate(lmb, rmb, f)
	if mgp_tool_isAnimPlaying(self, { equip = true }) then
		return true, false
	end

	if f then
		return false, false
	end

	if (lmb == 1 or lmb == 2) and not self.cl_using then
		local hit, result = sm.localPlayer.getRaycast(7.5)
		local char = result:getCharacter()
		if char and char:isPlayer() then
			self.network:sendToServer("sv_updateUse", { sm.localPlayer.getSelectedHotbarSlot(), char })
		else
			self.network:sendToServer("sv_updateUse", sm.localPlayer.getSelectedHotbarSlot())
		end
	elseif lmb == 3 then
		self.network:sendToServer("sv_updateUse")
	end

	sm.gui.setInteractionText( "", sm.gui.getKeyBinding( "Create", true ), "#{INTERACTION_USE}" )

	return true, false
end



function Medkit:loadAnimations()
	self.tpAnimations = createTpAnimations(
		self.tool,
		{
			idle = { "Medkit_idle" },
			use = { "Medkit_use_1", { nextAnimation = "pickup" } },
			use2 = { "Medkit_use_2", { nextAnimation = "pickup" } },
			pickup = { "Medkit_pickup", { nextAnimation = "idle" } },
			putdown = { "Medkit_putdown" }
		}
	)
	local movementAnimations = {
		idle = "Medkit_idle",

		runFwd = "Medkit_run_fwd",
		runBwd = "Medkit_run_bwd",

		sprint = "Medkit_sprint",

		jump = "Medkit_jump",
		jumpUp = "Medkit_jump_up",
		jumpDown = "Medkit_jump_down",

		land = "Medkit_jump_land",
		landFwd = "Medkit_jump_land_fwd",
		landBwd = "Medkit_jump_land_bwd",

		crouchIdle = "Medkit_crouch_idle",
		crouchFwd = "Medkit_crouch_fwd",
		crouchBwd = "Medkit_crouch_bwd"
	}

	for name, animation in pairs(movementAnimations) do
		self.tool:setMovementAnimation(name, animation)
	end

	if self.tool:isLocal() then
		self.fpAnimations = createFpAnimations(
			self.tool,
			{
				idle = 	{ "Medkit_fp_idle", { looping = true } },

				use = 	{ "Medkit_fp_use_1", { nextAnimation = "equip", blendNext = 0 } },
				use2 = 	{ "Medkit_fp_use_2", { nextAnimation = "equip", blendNext = 0 } },

				sprintInto = { "Medkit_fp_sprint_into", { nextAnimation = "sprintIdle", blendNext = 0.2 } },
				sprintIdle = { "Medkit_fp_sprint_idle", { looping = true } },
				sprintExit = { "Medkit_fp_sprint_exit", { nextAnimation = "idle", blendNext = 0 } },

				equip = 	{ "Medkit_fp_pickup", { nextAnimation = "idle" } },
				unequip = 	{ "Medkit_fp_putdown" }
			}
		)
	end

	self.blendTime = 0.2
end
