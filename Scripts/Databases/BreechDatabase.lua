mgp_anim_enum =
{
	bone_animation = 1,
	wait_timer     = 2,
	effect         = 3,
	delay          = 4,
	debris         = 5
}

local mgp_shell_01 = sm.uuid.new("0d4d66a0-532a-49e4-83c5-8ec8bb95ea8e")
local mgp_shell_02 = sm.uuid.new("8f7a8365-d6b4-4f22-88c9-6951ac8ff8d5")

local breech_database =
{
	["3d410289-0079-4989-ba21-b211562147d5"] =
	{
		required_effects = {
			--test = { name = "BombSmall", offset = sm.vec3.new(0, 0, 0), bone = nil } --that's how you define an effect that can be referenced by the animation
		},
		required_animations = { "Shot", "Reload" },
		bone_tracker = { "Case" },
		animation = {
			--{ type = mgp_anim_enum.bone_animation, anim = { "Shot" }, start_val = 0.0, end_val = 1.0, time = 1.0 } --that's how you define your animation
			--{ type = mgp_anim_enum.wait_timer } --that's how you define a custom wait timer that allows any cannon to specify its reload time
			--{ type = mgp_anim_enum.effect, effects = { "test" } } --that's how you define effects
			--{ type = mgp_anim_enum.delay, time = 2.0 } --a simple delay in which you can specify any time you want

			{ type = mgp_anim_enum.bone_animation, anim = { "Shot" }  , start_val = 0.0, end_val = 1.0, time = 1.0 },
			{ type = mgp_anim_enum.bone_animation, anim = { "Reload" }, start_val = 0.0, end_val = 0.385, time = 2.0 },
			{ type = mgp_anim_enum.debris, uuid = mgp_shell_02, bone = "Case", offset = sm.vec3.new(0, 0.33, 0) },
			{ type = mgp_anim_enum.bone_animation, anim = { "Reload" }, start_val = 0.57, end_val = 0.57, time = 0.0 },
			{ type = mgp_anim_enum.wait_timer },
			{ type = mgp_anim_enum.bone_animation, anim = { "Reload" }, start_val = 0.57, end_val = 1.0, time = 2.0 }
		}
	},
	["54b7c549-4b12-4be1-b73d-4d62db371394"] =
	{
		required_effects = {},
		required_animations = { "Shot", "Reload" },
		animation = {
			{ type = mgp_anim_enum.bone_animation, anim = { "Shot" }  , start_val = 0.0, end_val = 1.0, time = 1.0 },
			{ type = mgp_anim_enum.bone_animation, anim = { "Reload" }, start_val = 0.0, end_val = 0.57, time = 3.5 },
			{ type = mgp_anim_enum.wait_timer },
			{ type = mgp_anim_enum.bone_animation, anim = { "Reload" }, start_val = 0.57, end_val = 1.0, time = 2.5 }
		}
	},
	["379449f7-27ca-4aea-b723-f841406bbacc"] =
	{
		required_effects = {},
		required_animations = { "Shot", "Reload" },
		bone_tracker = { "Shell" },
		animation = {
			{ type = mgp_anim_enum.bone_animation, anim = { "Shot" }  , start_val = 0.0, end_val = 1.0, time = 1.0 },
			{ type = mgp_anim_enum.bone_animation, anim = { "Reload" }, start_val = 0.0, end_val = 0.35, time = 1.3 },
			{ type = mgp_anim_enum.debris, uuid = mgp_shell_01, bone = "Shell", offset = sm.vec3.new(0, 0.07, 0) },
			{ type = mgp_anim_enum.bone_animation, anim = { "Reload" }, start_val = 0.5, end_val = 0.5, time = 0 },
			{ type = mgp_anim_enum.wait_timer },
			{ type = mgp_anim_enum.bone_animation, anim = { "Reload" }, start_val = 0.5, end_val = 1.0, time = 1.2 }
		}
	}
}

function mgp_getBreechData(self)
	return breech_database[tostring(self.shape.uuid)]
end