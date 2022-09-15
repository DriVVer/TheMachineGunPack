mgp_tool_anim_enum =
{
	bone_animation    = 1,
	effect            = 2,
	delay             = 3,
	debris            = 4,
	particle          = 5,
	toggle_renderable = 6
}

local mgp_tommy_shell = sm.uuid.new("553820fd-14a7-4276-a8eb-1f66d4caa775")

local mgp_aim_shoot_reset_table =
{
	fp = { { "Magnum44_aim_Shoot", 0.0 } },
	tp = { { "Magnum44_aim_Shoot", 0.0 } }
}

local mgp_shoot_reset_table =
{
	fp = { { "Magnum44_Shoot", 0.0 } },
	tp = { { "Magnum44_Shoot", 0.0 } }
}

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


	HandheldGrenadeBase =
	{
		required_effects = {
			shoot_tp = "Muzzle_Flash_SmallCal_fp",
			shoot_fp = "Muzzle_Flash_SmallCal_fp",
			reloadTG = "TommyReload",
			reloadETG = "TommyEReload"
		},
		on_unequip_action = {
			stop_effects = { "reloadTG", "reloadETG" }
		},
		renderables = {
			main_body = { path = "$CONTENT_DATA/Tools/Renderables/Grenade/s_grenade_base.rend"    , enabled_by_default = true }--,
			--anim_body = { path = "$CONTENT_DATA/Tools/Renderables/Grenade/s_grenade_screw.rend", enabled_by_default = true },
		},
		animation_reset = {
			cock_the_hammer = mgp_aim_shoot_reset_table,
			cock_the_hammer_aim = mgp_shoot_reset_table,
			no_ammo = mgp_aim_shoot_reset_table,
			no_ammo_aim = mgp_shoot_reset_table,
			shoot = mgp_aim_shoot_reset_table,
			shoot_aim = mgp_shoot_reset_table
		},
		animation = {
			Granade_activ =
			{
				[1] = {
					{				
						type = mgp_tool_anim_enum.toggle_renderable,
						name = "anim_body",
						enabled = true
					},
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Activation_unscrew", start_val = 0.0, end_val = 1.0 } },
						tp_anim = { { name = "Activation_unscrew", start_val = 0.0, end_val = 1.0 } },
						time = 1.0
					},
					{					
						type = mgp_tool_anim_enum.toggle_renderable,
						name = "anim_body",
						enabled = false
					}
				}
			},
			throw =
			{
				[1] = {
					{						
						type = mgp_tool_anim_enum.delay,
						time = 0.2
					},
					{						
						type = mgp_tool_anim_enum.toggle_renderable,
						name = "anim_body",
						enabled = false
					},
					{						
						type = mgp_tool_anim_enum.delay,
						time = 0.4
					},
					{						
						type = mgp_tool_anim_enum.toggle_renderable,
						name = "main_body",
						enabled = true
					}
				}
			},

		}
	},
	
	Magnum44 =
	{
		required_effects = {
			shoot_tp = "Muzzle_Flash_SmallCal_fp",
			shoot_fp = "Muzzle_Flash_SmallCal_fp",
			reloadTG = "TommyReload",
			reloadETG = "TommyEReload"
		},
		on_unequip_action = {
			stop_effects = { "reloadTG", "reloadETG" }
		},
		renderables = {
			main_body = { path = "$CONTENT_DATA/Tools/Renderables/Revolver/Magnum44_Model.rend"    , enabled_by_default = true },
			anim_body = { path = "$CONTENT_DATA/Tools/Renderables/Revolver/Magnum44_AnimModel.rend", enabled_by_default = true }
		},
		animation_reset = {
			cock_the_hammer = mgp_aim_shoot_reset_table,
			cock_the_hammer_aim = mgp_shoot_reset_table,
			no_ammo = mgp_aim_shoot_reset_table,
			no_ammo_aim = mgp_shoot_reset_table,
			shoot = mgp_aim_shoot_reset_table,
			shoot_aim = mgp_shoot_reset_table
		},
		animation = {
			cock_the_hammer =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Magnum44_Shoot", start_val = 0.0, end_val = 0.5 } },
						tp_anim = { { name = "Magnum44_aim_Shoot", start_val = 0.0, end_val = 0.5 } },
						time = 0.5
					}
				}
			},
			cock_the_hammer_aim =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Magnum44_aim_Shoot", start_val = 0.0, end_val = 0.5 } },
						tp_anim = { { name = "Magnum44_aim_Shoot", start_val = 0.0, end_val = 0.5 } },
						time = 0.5
					}
				}
			},
			no_ammo =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Magnum44_Shoot", start_val = 0.5, end_val = 1.0 } },
						tp_anim = { { name = "Magnum44_Shoot", start_val = 0.5, end_val = 1.0 } },
						time = 0.1
					}
				}
			},
			no_ammo_aim =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Magnum44_aim_Shoot", start_val = 0.5, end_val = 1.0 } },
						tp_anim = { { name = "Magnum44_aim_Shoot", start_val = 0.5, end_val = 1.0 } },
						time = 0.1
					}
				}
			},
			shoot =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "shoot_tp",
						name_fp = "shoot_fp",
						tp_offset = sm.vec3.new(0, 0.5, 0),
						fp_offset = sm.vec3.new(0.0, -0.04, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Magnum44_Shoot", start_val = 0.5, end_val = 1.0 } },
						tp_anim = { { name = "Magnum44_Shoot", start_val = 0.5, end_val = 1.0 } },
						time = 0.1
					}
				}
			},
			shoot_aim =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "shoot_tp",
						name_fp = "shoot_fp",
						tp_offset = sm.vec3.new(0, 0.5, 0),
						fp_offset = sm.vec3.new(0.0, -0.04, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Magnum44_aim_Shoot", start_val = 0.5, end_val = 1.0 } },
						tp_anim = { { name = "Magnum44_aim_Shoot", start_val = 0.5, end_val = 1.0 } },
						time = 0.1
					}
				}
			},
			equip =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Magnum44_Pickup", start_val = 0.0, end_val = 1.0 } },
						tp_anim = { { name = "Magnum44_Pickup", start_val = 0.9, end_val = 1.0 } },
						time = 1.0
					}
				}
				--[2] = {

					--{
						--type = mgp_tool_anim_enum.bone_animation,
						--fp_anim = { { name = "Magnum44_SL_Reload", start_val = 2.97, end_val = 2.97 } },
						--tp_anim = { { name = "Magnum44_SL_Reload", start_val = 2.97, end_val = 2.97 } },
						--time = 0.1
					--}
					--{
						--type = mgp_tool_anim_enum.bone_animation,
						--fp_anim = { { name = "Magnum44_SL_Reload", start_val = 2.8, end_val = 2.8 } },
						--tp_anim = { { name = "Magnum44_SL_Reload", start_val = 2.8, end_val = 2.8 } },
						--time = 0.1
					--},
				
			},
			reload5 =
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
						fp_anim = { { name = "Magnum44_5-6_Reload", start_val = 0.0, end_val = 5.0 } },
						tp_anim = { { name = "Magnum44_5-6_Reload", start_val = 0.0, end_val = 5.0 } },
						time = 5.0
					}
				}--,
				--[2] = { --second animation track
					--{
						--type = mgp_tool_anim_enum.delay,
						--time = 2.85
					--},
					--{
						--type = mgp_tool_anim_enum.bone_animation,
						--fp_anim = { { name = "Magnum44_SL_Reload", start_val = 2.8, end_val = 4.1 } },
						--tp_anim = { { name = "Magnum44_SL_Reload", start_val = 2.8, end_val = 4.1 } },
						--time = 1.2
					--},
				--}
			},
			reload4 =
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
						fp_anim = { { name = "Magnum44_4-6_Reload", start_val = 0.0, end_val = 5.0 } },
						tp_anim = { { name = "Magnum44_4-6_Reload", start_val = 0.0, end_val = 5.0 } },
						time = 5.0
					}
				}
			},
			reload3 =
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
						fp_anim = { { name = "Magnum44_3-6_Reload", start_val = 0.0, end_val = 5.0 } },
						tp_anim = { { name = "Magnum44_3-6_Reload", start_val = 0.0, end_val = 5.0 } },
						time = 5.0
					}
				}
			},
			reload2 =
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
						fp_anim = { { name = "Magnum44_2-6_Reload", start_val = 0.0, end_val = 5.0 } },
						tp_anim = { { name = "Magnum44_2-6_Reload", start_val = 0.0, end_val = 5.0 } },
						time = 5.0
					}
				}
			},
			reload1 =
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
						fp_anim = { { name = "Magnum44_1-6_Reload", start_val = 0.0, end_val = 5.0 } },
						tp_anim = { { name = "Magnum44_1-6_Reload", start_val = 0.0, end_val = 5.0 } },
						time = 5.0
					}
				}
			},
			reload0 =
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
						fp_anim = { { name = "Magnum44_E_Reload", start_val = 0.0, end_val = 3.0 } },
						tp_anim = { { name = "Magnum44_E_Reload", start_val = 0.0, end_val = 3.0 } },
						time = 3.0
					}
				}
			},
			ammo_check =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Magnum44_normal_ammo_check", start_val = 0.0, end_val = 2.0 } },
						tp_anim = { { name = "Magnum44_normal_ammo_check", start_val = 0.0, end_val = 2.0 } },
						time = 2.0
					}
				}
			}
		}
	},

	Mosin =
	{
		required_effects = {
			shoot_tp = "Muzzle_Flash_SmallCal_fp",
			shoot_fp = "Muzzle_Flash_SmallCal_fp",
			reloadTG = "TommyReload",
			reloadETG = "TommyEReload"
		},
		on_unequip_action = {
			stop_effects = { "reloadTG", "reloadETG" }
		},
		renderables = {
			main_body = { path = "$CONTENT_DATA/Tools/Renderables/Mosin/Mosin_Base.rend"    , enabled_by_default = true },
			anim_body = { path = "$CONTENT_DATA/Tools/Renderables/Mosin/Mosin_Anim.rend"	, enabled_by_default = true }
		},
		animation_reset = {
			cock_the_hammer = mgp_aim_shoot_reset_table,
			cock_the_hammer_aim = mgp_shoot_reset_table,
			no_ammo = mgp_aim_shoot_reset_table,
			no_ammo_aim = mgp_shoot_reset_table,
			shoot = mgp_aim_shoot_reset_table,
			shoot_aim = mgp_shoot_reset_table
		},
		animation = {
			cock_the_hammer =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.2
					},
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Mosin_Anim", start_val = 0.2, end_val = 0.4 } },
						tp_anim = { { name = "Mosin_Anim", start_val = 0.2, end_val = 0.4 } },
						time = 0.2
					},
					{
						type = mgp_tool_anim_enum.particle,
						fp_offset = sm.vec3.new(0, 0.0, 0),
						tp_offset = sm.vec3.new(0, 0, 0),
						name_tp = "TommyShell",
						name_fp = "TommyShellFP",
						bone_name = "jnt_ammo_1"
					},
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Mosin_Anim", start_val = 0.4, end_val = 0.6 } },
						tp_anim = { { name = "Mosin_Anim", start_val = 0.4, end_val = 0.6 } },
						time = 0.2
					},
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Mosin_Anim", start_val = 4.05, end_val = 4.75 } },
						tp_anim = { { name = "Mosin_Anim", start_val = 4.05, end_val = 4.75  } },
						time = 0.7
					}
				}
			},
			cock_the_hammer_aim =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.2
					},
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Mosin_Anim", start_val = 0.2, end_val = 0.4 } },
						tp_anim = { { name = "Mosin_Anim", start_val = 0.2, end_val = 0.4 } },
						time = 0.2
					},
					{
						type = mgp_tool_anim_enum.particle,
						fp_offset = sm.vec3.new(0, 0.0, 0),
						tp_offset = sm.vec3.new(0, 0, 0),
						name_tp = "TommyShell",
						name_fp = "TommyShellFP",
						bone_name = "jnt_ammo_1"
					},
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Mosin_Anim", start_val = 0.4, end_val = 0.6 } },
						tp_anim = { { name = "Mosin_Anim", start_val = 0.4, end_val = 0.6 } },
						time = 0.2
					},
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Mosin_Anim", start_val = 4.15, end_val = 4.75 } },
						tp_anim = { { name = "Mosin_Anim", start_val = 4.15, end_val = 4.75  } },
						time = 0.6
					}
				}
			},
			no_ammo =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Mosin_Anim", start_val = 0.0, end_val = 0.2 } },
						tp_anim = { { name = "Mosin_Anim", start_val = 0.0, end_val = 0.2 } },
						time = 0.2
					}, 
				}
			},
			no_ammo_aim =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Mosin_Anim", start_val = 0.0, end_val = 0.2 } },
						tp_anim = { { name = "Mosin_Anim", start_val = 0.0, end_val = 0.2 } },
						time = 0.2
					},
				}
			},
			shoot =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "shoot_tp",
						name_fp = "shoot_fp",
						tp_offset = sm.vec3.new(0, 0.5, 0),
						fp_offset = sm.vec3.new(0.0, -0.04, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Mosin_Anim", start_val = 0.0, end_val = 0.2 } },
						tp_anim = { { name = "Mosin_Anim", start_val = 0.0, end_val = 0.2 } },
						time = 0.2
					},
				}
			},
			shoot_aim =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "shoot_tp",
						name_fp = "shoot_fp",
						tp_offset = sm.vec3.new(0, 0.5, 0),
						fp_offset = sm.vec3.new(0.0, -0.04, 0),
						apply_velocity = false
					}
				}
			},
			reload4 =
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
						fp_anim = { { name = "Mosin_Anim", start_val = 0.0, end_val = 4.75 } },
						tp_anim = { { name = "Mosin_Anim", start_val = 0.0, end_val = 4.75 } },
						time = 4.75
					}
				}
			},
			reload3 =
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
						fp_anim = { { name = "Mosin_Anim", start_val = 0.0, end_val = 4.75 } },
						tp_anim = { { name = "Mosin_Anim", start_val = 0.0, end_val = 4.75 } },
						time = 4.75
					}
				}
			},
			reload2 =
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
						fp_anim = { { name = "Mosin_Anim", start_val = 0.0, end_val = 4.75 } },
						tp_anim = { { name = "Mosin_Anim", start_val = 0.0, end_val = 4.75 } },
						time = 4.75
					}
				}
			},
			reload1 =
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
						fp_anim = { { name = "Mosin_Anim", start_val = 0.0, end_val = 4.75 } },
						tp_anim = { { name = "Mosin_Anim", start_val = 0.0, end_val = 4.75 } },
						time = 4.75
					}
				}
			},
			reload0 =
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
						fp_anim = { { name = "Mosin_Anim", start_val = 0.0, end_val = 4.75 } },
						tp_anim = { { name = "Mosin_Anim", start_val = 0.0, end_val = 4.75 } },
						time = 4.75
					}
				}
			},
			ammo_check =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Mosin_Anim", start_val = 0.0, end_val = 4.75 } },
						tp_anim = { { name = "Mosin_Anim", start_val = 0.0, end_val = 4.75 } },
						time = 4.75
					}
				}
			}
		}
	}
}

function mgp_getToolData(tool_name)
	return mgp_tool_database[tool_name]
end