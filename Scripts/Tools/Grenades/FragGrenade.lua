dofile( "$GAME_DATA/Scripts/game/AnimationUtil.lua" )
dofile( "$SURVIVAL_DATA/Scripts/util.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/survival_shapes.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/survival_projectiles.lua" )

dofile("HandheldGrenadeBase.lua")

---@class FragGrenade : HandheldGrenadeBase
FragGrenade = class(HandheldGrenadeBase)

FragGrenade.mgp_tool_animator_type = "Frag"
FragGrenade.mgp_renderables =
{
	"$CONTENT_DATA/Tools/Renderables/Frag/Frag_Base.rend",
	"$CONTENT_DATA/Tools/Renderables/Frag/Frag_Anim.rend"
}

FragGrenade.mgp_renderables_tp =
{
	"$CONTENT_DATA/Tools/Renderables/Frag/Frag_tp_animlist.rend",
	"$CONTENT_DATA/Tools/Renderables/Frag/Frag_tp_offset.rend"
}

FragGrenade.mgp_renderables_fp =
{
	"$CONTENT_DATA/Tools/Renderables/Frag/Frag_fp_animlist.rend",
	"$CONTENT_DATA/Tools/Renderables/Frag/Frag_fp_offset.rend"
}

FragGrenade.mgp_tp_animation_list =
{
	idle = { "glowstick_idle" },
	pickup = { "glowstick_pickup", { nextAnimation = "idle" } },
	putdown = { "glowstick_putdown" },

	throw = { "glowstick_use", { nextAnimation = "idle", blendNext = 0 } },
	activate = { "glowstick_activ", { nextAnimation = "idle" } }
}

FragGrenade.mgp_fp_animation_list =
{
	equip = { "Frag_pickup", { nextAnimation = "idle" } },
	unequip = { "Frag_putdown" },

	idle = { "Frag_idle", { looping = true } },

	activate = { "Frag_activ", { nextAnimation = "idle" } },
	throw = { "Frag_throw", { nextAnimation = "idle" } },

	aimInto = { "Frag_aim_into", { nextAnimation = "aimIdle" } },
	aimExit = { "Frag_aim_exit", { nextAnimation = "idle", blendNext = 0 } },
	aimIdle = { "Frag_aim_idle", { looping = true } },
	aimShoot = { "Frag_aim_shoot", { nextAnimation = "aimIdle"} },

	sprintInto = { "Frag_sprint_into", { nextAnimation = "sprintIdle",  blendNext = 0.2 } },
	sprintExit = { "Frag_sprint_exit", { nextAnimation = "idle",  blendNext = 0 } },
	sprintIdle = { "Frag_sprint_idle", { looping = true } }
}

FragGrenade.mgp_movement_animations =
{
	idle = "glowstick_idle",
	idleRelaxed = "glowstick_idle",

	sprint = "glowstick_sprint",
	runFwd = "glowstick_run_fwd",
	runBwd = "glowstick_run_bwd",

	jump = "glowstick_jump",
	jumpUp = "glowstick_jump_up",
	jumpDown = "glowstick_jump_down",

	land = "glowstick_idle",
	landFwd = "glowstick_idle",
	landBwd = "glowstick_idle",

	crouchIdle = "glowstick_crouch_idle",
	crouchFwd = "glowstick_crouch_fwd",
	crouchBwd = "glowstick_crouch_bwd"
}

FragGrenade.mgp_tool_config =
{
	grenade_tool_uuid = sm.uuid.new("0c27e043-0cff-492b-9bcf-091520a99764"),
	grenade_uuid = sm.uuid.new("63f18d12-41eb-4de7-9ce3-54f5b3a25a14"),
	grenade_settings =
	{
		timer = 3,
		expl_lvl = 1,
		expl_rad = 3,
		expl_effect = "PropaneTank - ExplosionSmall",
		shrapnel_data = {
			min_count = 200, max_count = 320,
			min_speed = 80, max_speed = 120,
			min_damage = 50, max_damage = 90,
			proj_uuid = sm.uuid.new("7a3887dd-0fd2-489c-ac04-7306a672ae35")
		},
		spin_force = 5
	}
}

FragGrenade.sv_activation_timer = 1.0

sm.tool.preloadRenderables(FragGrenade.mgp_renderables)
sm.tool.preloadRenderables(FragGrenade.mgp_renderables_tp)
sm.tool.preloadRenderables(FragGrenade.mgp_renderables_fp)

function FragGrenade:client_onEquip(animate)
	HandheldGrenadeBase.client_onEquip(self, animate)
	self.ready_to_throw = false
end

function FragGrenade:sv_n_startGrenadeTimer()
	self.sv_grenade_can_spawn = true
end

function FragGrenade:sv_getGrenadeTimer()
	if not self.sv_grenade_can_spawn then
		return nil
	end

	return self.mgp_tool_config.grenade_settings.timer
end

function FragGrenade:client_onGrenadeUpdate(dt)
	if self.ready_to_throw and self.grenade_active and not self.is_holding_grenade then
		self.ready_to_throw = false
		self.grenade_active = false

		if sm.game.getEnableAmmoConsumption() and sm.game.getLimitedInventory() then
			self.cl_remove_timer = 1.0
			self.grenade_used = true
		end

		self.grenade_spawn_timer = 0.35
		self.fireCooldownTimer = 2.0
		self.cl_grenade_timer = nil

		self:onThrowGrenade()
		self.network:sendToServer("sv_n_throwGrenade")

		setFpAnimation(self.fpAnimations, "throw", 0.0)
		mgp_toolAnimator_setAnimation(self, "throw")
	end
end

function FragGrenade:cl_onPrimaryUse(state)
	if state ~= sm.tool.interactState.start and state ~= sm.tool.interactState.stop then
		return
	end

	local v_owner = self.tool:getOwner()
	if not v_owner then return end

	if self.grenade_used or not v_owner.character then
		return
	end

	local is_start_state = state == sm.tool.interactState.start
	if (is_start_state and self:cl_shouldBlockSprint()) or self.fireCooldownTimer > 0.0 then
		return
	end

	if state == sm.tool.interactState.start then
		if not self.tool:isSprinting() and not self.grenade_active and not self.ready_to_throw then
			self.is_holding_grenade = true
			self.ready_to_throw = true

			setFpAnimation(self.fpAnimations, "activate", 0.0)
			mgp_toolAnimator_setAnimation(self, "activate")

			self:onActivateGrenade()
			self.network:sendToServer("sv_n_activateGrenade")
		end
	else
		self.is_holding_grenade = false
	end
end