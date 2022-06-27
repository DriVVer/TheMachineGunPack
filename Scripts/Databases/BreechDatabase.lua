mgp_anim_enum =
{
	bone_animation = 1,
	wait_timer     = 2,
	effect         = 3,
	delay          = 4
}

local breech_database =
{
	["3d410289-0079-4989-ba21-b211562147d5"] =
	{
		required_effects = {
			--test = { name = "BombSmall", offset = sm.vec3.new(0, 0, 0), bone = nil } --that's how you define an effect that can be referenced by the animation
		},
		required_animations = { "Shot", "Reload" },
		animation = {
			--{ type = mgp_anim_enum.bone_animation, anim = { "Shot" }, start_val = 0.0, end_val = 1.0, time = 1.0 } --that's how you define your animation
			--{ type = mgp_anim_enum.wait_timer } --that's how you define a custom wait timer that allows any cannon to specify its reload time
			--{ type = mgp_anim_enum.effect, effects = { "test" } } --that's how you define effects
			--{ type = mgp_anim_enum.delay, time = 2.0 } --a simple delay in which you can specify any time you want

			{ type = mgp_anim_enum.bone_animation, anim = { "Shot" }  , start_val = 0.0, end_val = 1.0, time = 1.0 },
			{ type = mgp_anim_enum.bone_animation, anim = { "Reload" }, start_val = 0.0, end_val = 0.57, time = 3.0 },
			{ type = mgp_anim_enum.wait_timer },
			{ type = mgp_anim_enum.bone_animation, anim = { "Reload" }, start_val = 0.57, end_val = 1.0, time = 2.0 }
		}
	},
	["379449f7-27ca-4aea-b723-f841406bbacc"] =
	{
		required_effects = {
			--test = { name = "BombSmall", offset = sm.vec3.new(0, 0, 0), bone = nil } --that's how you define an effect that can be referenced by the animation
		},
		required_animations = { "Shot", "Reload1", "Reload2" },
		animation = {
			--{ type = mgp_anim_enum.bone_animation, anim = { "Shot" }, start_val = 0.0, end_val = 1.0, time = 1.0 } --that's how you define your animation
			--{ type = mgp_anim_enum.wait_timer } --that's how you define a custom wait timer that allows any cannon to specify its reload time
			--{ type = mgp_anim_enum.effect, effects = { "test" } } --that's how you define effects
			--{ type = mgp_anim_enum.delay, time = 2.0 } --a simple delay in which you can specify any time you want
			{ type = mgp_anim_enum.bone_animation, anim = { "Shot" }  , start_val = 0.0, end_val = 1.0, time = 1.0 },
			{ type = mgp_anim_enum.bone_animation, anim = { "Reload1" }, start_val = 0.0, end_val = 1.0, time = 2.0 },
			{ type = mgp_anim_enum.wait_timer },
			{ type = mgp_anim_enum.bone_animation, anim = { "Reload2" }, start_val = 0.0, end_val = 1.0, time = 2.0 }
		
		}
	}
}

function mgp_getBreechData(self)
	return breech_database[tostring(self.shape.uuid)]
end