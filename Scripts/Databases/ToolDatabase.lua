mgp_tool_anim_enum =
{
	bone_animation = 1,
	effect         = 2,
	delay          = 3,
	debris         = 4,
	particle       = 5
}

local mgp_tommy_shell = sm.uuid.new("553820fd-14a7-4276-a8eb-1f66d4caa775")

local mgp_tool_database =
{
	tommy_gun =
	{
		required_effects = {
			shoot_tp = "Muzzle_Flash_SmallCal_tp",
			shoot_fp = "Muzzle_Flash_SmallCal_fp",
			reloadTG = "TommyReload",
			reloadETG = "TommyEReload"
		},
		on_unequip_action = {
			stop_effects = { "reloadTG", "reloadETG" }
		},
		animation = {
			shoot =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "shoot_tp",
						name_fp = "shoot_fp",
						tp_offset = sm.vec3.new(0, 0.5, 0),
						fp_offset = sm.vec3.new(0.0, 0.07, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.particle,
						fp_offset = sm.vec3.new(0, -0.07, 0),
						tp_offset = sm.vec3.new(0, 0, 0),
						name_tp = "TommyShell",
						name_fp = "TommyShellFP",
						bone_name = "Shell"
					},
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "TommyGun_model_shoot", start_val = 0.0, end_val = 1.0 } },
						tp_anim = { { name = "TommyGun_model_shoot", start_val = 0.0, end_val = 1.0 } },
						time = 1.0
					},
					
				}
			},
			reload =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "reloadTG",
						name_fp = "reloadTG",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false,

					},
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "TommyGun_model_reload", start_val = 0.0, end_val = 5.0 } },
						tp_anim = { { name = "TommyGun_model_tp_reload", start_val = 0.0, end_val = 5.0 } },
						time = 5.0
					}
				}
			},
			reload_empty =
			{
				[1] = { --first animation track
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "reloadETG",
						name_fp = "reloadETG",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false,
		
					},
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "TommyGun_model_reload", start_val = 0.0, end_val = 5.0 } },
						tp_anim = { { name = "TommyGun_model_tp_reload", start_val = 0.0, end_val = 5.0 } },
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
	},
	
	Magnum44 =
	{
		required_effects = {
			shoot_tp = "Muzzle_Flash_SmallCal_tp",
			shoot_fp = "Muzzle_Flash_SmallCal_fp",
			reloadTG = "TommyReload",
			reloadETG = "TommyEReload"
		},
		on_unequip_action = {
			stop_effects = { "reloadTG", "reloadETG" }
		},
		animation = {
			shoot =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "shoot_tp",
						name_fp = "shoot_fp",
						tp_offset = sm.vec3.new(0, 0.5, 0),
						fp_offset = sm.vec3.new(0.0, 0.07, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.particle,
						fp_offset = sm.vec3.new(0, -0.07, 0),
						tp_offset = sm.vec3.new(0, 0, 0),
						name_tp = "TommyShell",
						name_fp = "TommyShellFP",
						bone_name = "pejnt_barrel"
					},
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Magnum44_Shoot", start_val = 0.0, end_val = 1.0 } },
						tp_anim = { { name = "Magnum44_Shoot", start_val = 0.0, end_val = 1.0 } },
						time = 1.0
					}
				}
			},
			reload =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "reloadTG",
						name_fp = "reloadTG",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false,

					},
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "TommyGun_model_reload", start_val = 0.0, end_val = 5.0 } },
						tp_anim = { { name = "TommyGun_model_tp_reload", start_val = 0.0, end_val = 5.0 } },
						time = 5.0
					}
				}
			},
			reload_empty =
			{
				[1] = { --first animation track
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "reloadETG",
						name_fp = "reloadETG",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false,
		
					},
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "TommyGun_model_reload", start_val = 0.0, end_val = 5.0 } },
						tp_anim = { { name = "TommyGun_model_tp_reload", start_val = 0.0, end_val = 5.0 } },
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