dofile( "$GAME_DATA/Scripts/game/AnimationUtil.lua" )
dofile( "$SURVIVAL_DATA/Scripts/util.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/survival_shapes.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/survival_projectiles.lua" )

dofile("HandheldGrenadeBase.lua")

---@class HandheldGrenadeSingle : HandheldGrenadeBase
HandheldGrenadeSingle = class(HandheldGrenadeBase)

HandheldGrenadeSingle.mgp_tool_animator_type = "HandheldGrenadeSingle"
HandheldGrenadeSingle.mgp_renderables =
{
	"$CONTENT_DATA/Tools/Renderables/Grenade/SingleGrenade_Base.rend"
}

HandheldGrenadeSingle.mgp_renderables_tp =
{
	"$CONTENT_DATA/Tools/Renderables/Grenade/s_granade_tp_animlist.rend",
	"$CONTENT_DATA/Tools/Renderables/Grenade/s_grenade_tp_offset.rend"
}

HandheldGrenadeSingle.mgp_renderables_fp =
{
	"$CONTENT_DATA/Tools/Renderables/Grenade/s_granade_fp_animlist.rend",
	"$CONTENT_DATA/Tools/Renderables/Grenade/s_grenade_fp_offset.rend"
}

HandheldGrenadeSingle.mgp_tp_animation_list =
{
	idle = { "glowstick_idle" },
	pickup = { "glowstick_pickup", { nextAnimation = "idle" } },
	putdown = { "glowstick_putdown" },

	throw = { "glowstick_use", { nextAnimation = "idle", blendNext = 0 } },
	activate = { "glowstick_activ", { nextAnimation = "idle" } }
}

HandheldGrenadeSingle.mgp_fp_animation_list =
{
	equip = { "glowstick_pickup", { nextAnimation = "idle" } },
	unequip = { "glowstick_putdown" },

	idle = { "glowstick_idle", { looping = true } },

	activate = { "glowstick_activ", { nextAnimation = "idle" } },
	throw = { "glowstick_throw", { nextAnimation = "idle" } },

	aimInto = { "glowstick_aim_into", { nextAnimation = "aimIdle" } },
	aimExit = { "glowstick_aim_exit", { nextAnimation = "idle", blendNext = 0 } },
	aimIdle = { "glowstick_aim_idle", { looping = true } },
	aimShoot = { "glowstick_aim_shoot", { nextAnimation = "aimIdle"} },

	sprintInto = { "glowstick_sprint_into", { nextAnimation = "sprintIdle",  blendNext = 0.2 } },
	sprintExit = { "glowstick_sprint_exit", { nextAnimation = "idle",  blendNext = 0 } },
	sprintIdle = { "glowstick_sprint_idle", { looping = true } }
}

HandheldGrenadeSingle.mgp_movement_animations =
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

HandheldGrenadeSingle.mgp_tool_config =
{
	grenade_tool_uuid = sm.uuid.new("c3e4dc43-a841-4c0f-82a6-7225d1bf210e"),
	grenade_uuid = sm.uuid.new("32e38ac2-e34b-4617-805f-358a8699af65"),
	grenade_fuse_time = 4,
	grenade_settings =
	{
		timer = 4,
		expl_lvl = 2,
		expl_rad = 2,
		expl_effect = "PropaneTank - ExplosionBig",
		shrapnel_data = {
			min_count = 40, max_count = 100,
			min_speed = 80, max_speed = 100,
			min_damage = 30, max_damage = 60,
			proj_uuid = sm.uuid.new("7a3887dd-0fd2-489c-ac04-7306a672ae35")
		},
		spin_force = 30
	}
}

HandheldGrenadeSingle.sv_activation_timer = 1.4

sm.tool.preloadRenderables(HandheldGrenadeSingle.mgp_renderables)
sm.tool.preloadRenderables(HandheldGrenadeSingle.mgp_renderables_tp)
sm.tool.preloadRenderables(HandheldGrenadeSingle.mgp_renderables_fp)