mgp_tool_anim_enum =
{
	bone_animation = 1,
	wait_timer     = 2,
	effect         = 3,
	delay          = 4,
	debris         = 5
}

local mgp_tool_database =
{
	tommy_gun =
	{
		required_effects = {},
		animation = {
			shoot =
			{
				{
					type = mgp_tool_anim_enum.bone_animation,
					fp_anim = { "TommyGun_model_shoot" },
					tp_anim = { "TommyGun_model_shoot" },
					start_val = 0.0,
					end_val = 1.0,
					time = 1.0
				}
			},
			reload =
			{
				{
					type = mgp_tool_anim_enum.bone_animation,
					fp_anim = { "TommyGun_model_reload" },
					tp_anim = { "TommyGun_model_reload" },
					start_val = 0.0,
					end_val = 5.0,
					time = 5.0
				}
			},
			reload_empty =
			{
				{
					type = mgp_tool_anim_enum.bone_animation,
					fp_anim = { "TommyGun_model_reload" },
					tp_anim = { "TommyGun_model_reload" },
					start_val = 0.0,
					end_val = 5.0,
					time = 5.0
				}
			}
		}
	}
}

function mgp_getToolData(tool_name)
	return mgp_tool_database[tool_name]
end