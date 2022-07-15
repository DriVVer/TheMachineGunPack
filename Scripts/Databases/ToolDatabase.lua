mgp_tool_anim_enum =
{
	bone_animation = 1,
	effect         = 2,
	delay          = 3,
	debris         = 4
}

local mgp_tool_database =
{
	tommy_gun =
	{
		required_effects = {},
		animation = {
			shoot =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "TommyGun_model_shoot", start_val = 0.0, end_val = 1.0 } },
						tp_anim = { { name = "TommyGun_model_shoot", start_val = 0.0, end_val = 1.0 } },
						time = 1.0
					}
				}
			},
			reload =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "TommyGun_model_reload", start_val = 0.0, end_val = 5.0 } },
						tp_anim = { { name = "TommyGun_model_reload", start_val = 0.0, end_val = 5.0 } },
						time = 5.0
					}
				}
			},
			reload_empty =
			{
				[1] = { --first animation track
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "TommyGun_model_reload", start_val = 0.0, end_val = 5.0 } },
						tp_anim = { { name = "TommyGun_model_reload", start_val = 0.0, end_val = 5.0 } },
						time = 5.0
					}
				},
				[2] = { --second animation track
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "TommyGun_model_shoot", start_val = 0.0, end_val = 0.04 } },
						tp_anim = { { name = "TommyGun_model_shoot", start_val = 0.0, end_val = 0.04 } },
						time = 0.05
					},
					{ type = mgp_tool_anim_enum.delay, time = 2.45 },
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "TommyGun_model_shoot", start_val = 0.04, end_val = 1.0 } },
						tp_anim = { { name = "TommyGun_model_shoot", start_val = 0.04, end_val = 1.0 } },
						time = 2.0
					}
				}
			}
		}
	}
}

function mgp_getToolData(tool_name)
	return mgp_tool_database[tool_name]
end