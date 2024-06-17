local mgp_tool_anim_enum =
{
	bone_animation    = 1,
	effect            = 2,
	delay             = 3,
	debris            = 4,
	particle          = 5,
	toggle_renderable = 6,
	event			  = 7,
	nextAnimation	  = 8
}

local mgp_magnum_aim_shoot_reset_table =
{
	fp = { { "Magnum44_aim_Shoot", 0.0 } },
	tp = { { "Magnum44_aim_Shoot", 0.0 } }
}

local mgp_magnum_shoot_reset_table =
{
	fp = { { "Magnum44_Shoot", 0.0 } },
	tp = { { "Magnum44_Shoot", 0.0 } }
}

local function ReloadLoop(self, loopAnim, exitAnim, ammoUUID, forceExit)
	if forceExit then
		goto exit
	end

	if sm.container.totalQuantity(self.tool:getOwner():getInventory(), ammoUUID) == 0 then
		return exitAnim
	end

	self.ammo_in_mag = self.ammo_in_mag + 1
	if self.ammo_in_mag < self.mag_capacity then
		if self.cl_isLocal then
			self.network:sendToServer("sv_reloadSingle")
		end

		return loopAnim
	end

	::exit::
	if self.cl_isLocal then
		self.network:sendToServer("sv_reloadExit")
	end

	return exitAnim
end

local mgp_tool_database =
{
	tommy_gun =
	{
		dlm_required_effects = {
			shoot_tp = "DLM_Muzzle_Flash_SmallCal_tp",
			shoot_fp = "DLM_Muzzle_Flash_SmallCal_fp",
			gunshot = "DLM_SMG_Shot_2",
			rack = "DLM_SMG_Rack_2",
			magin = "DLM_AR_MagIn",
			magout = "DLM_AR_MagOut"
		},
		required_effects = {
			shoot_tp = "Muzzle_Flash_SmallCal_tp",
			shoot_fp = "Muzzle_Flash_SmallCal_fp",
			reload = "TommyReload",
			reload_empty = "TommyEReload"
		},
		on_unequip_action = {
			stop_effects = { "reload", "reload_empty" }
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
						fp_offset = sm.vec3.new(0.0, 0.0, 0),
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
					}
				},
				[2] = {
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "gunshot",
						name_fp = "gunshot",
						tp_offset = sm.vec3.new(0, 0.5, 0),
						fp_offset = sm.vec3.new(0.0, -0.0, 0),
						apply_velocity = false
					},
				}
			},
			aimShoot =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "shoot_tp",
						name_fp = "shoot_fp",
						tp_offset = sm.vec3.new(0, 0.5, 0),
						fp_offset = sm.vec3.new(0.0, 0.5, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.particle,
						fp_offset = sm.vec3.new(0, 0.2, 0),
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
					}
				},
				[2] = {
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "gunshot",
						name_fp = "gunshot",
						tp_offset = sm.vec3.new(0, 0.5, 0),
						fp_offset = sm.vec3.new(0.0, -0.0, 0),
						apply_velocity = false
					},
				}
			},
			reload =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "TommyGun_model_reload", start_val = 0.0, end_val = 5.0 } },
						tp_anim = { { name = "TommyGun_model_tp_reload", start_val = 0.0, end_val = 5.0 } },
						time = 5.0
					}
				},
				[2] = {
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "reload",
						name_fp = "reload",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false,
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.03
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "magout",
						name_fp = "magout",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false,
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 1.15
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "magin",
						name_fp = "magin",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false,
					}
				}
			},
			reload_empty =
			{
				[1] = { --first animation track
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
				},
				[3] = {
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "reload_empty",
						name_fp = "reload_empty",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false,
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.03
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "magout",
						name_fp = "magout",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false,
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 1.15
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "magin",
						name_fp = "magin",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false,
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 1.15
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "rack",
						name_fp = "rack",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false,
					}
				}
			}
		}
	},

	ppsh =
	{
		dlm_required_effects = {
			shoot_tp = "DLM_Muzzle_Flash_SmallCal_tp",
			shoot_fp = "DLM_Muzzle_Flash_SmallCal_fp",
			gunshot = "DLM_SMG_Shot_1",
			rack = "DLM_SMG_Rack_3",
			magin = "DLM_AR_MagIn",
			magout = "DLM_AK_MagOut"
		},
		required_effects = {
			shoot_tp = "Muzzle_Flash_SmallCal_tp",
			shoot_fp = "Muzzle_Flash_SmallCal_fp",
			reload = "TommyReload",
			reload_empty = "TommyEReload"
		},
		animation = {
			equip =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Gun_anims", start_val = 0.15, end_val = 0.15 } },
						tp_anim = { { name = "Gun_anims", start_val = 0.15, end_val = 0.15 } },
						time = 0.0
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
						fp_offset = sm.vec3.new(0.0, -0.0, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.particle,
						fp_offset = sm.vec3.new(0.01, -0.025, -0.035),
						tp_offset = sm.vec3.new(0, 0, 0),
						name_tp = "TommyShell",
						name_fp = "TommyShellFP",
						bone_name = "jnt_reciever",
						offsetAngle = -90
					},
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Gun_anims", start_val = 0.0, end_val = 0.15 } },
						tp_anim = { { name = "Gun_anims", start_val = 0.0, end_val = 0.15 } },
						time = 0.4
					}
				},
				[2] = {
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "gunshot",
						name_fp = "gunshot",
						tp_offset = sm.vec3.new(0, 0.5, 0),
						fp_offset = sm.vec3.new(0.0, -0.0, 0),
						apply_velocity = false
					},
				}
			},
			aimShoot =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "shoot_tp",
						name_fp = "shoot_fp",
						tp_offset = sm.vec3.new(0, 0.5, 0),
						fp_offset = sm.vec3.new(0.0, 0.5, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.particle,
						fp_offset = sm.vec3.new(-0.01, 0.2, -0.025),
						tp_offset = sm.vec3.new(0, 0, 0),
						name_tp = "TommyShell",
						name_fp = "TommyShellFP",
						bone_name = "jnt_reciever",
						offsetAngle = -90
					},
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Gun_anims", start_val = 0.0, end_val = 0.15 } },
						tp_anim = { { name = "Gun_anims", start_val = 0.0, end_val = 0.15 } },
						time = 0.4
					}
				},
				[2] = {
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "gunshot",
						name_fp = "gunshot",
						tp_offset = sm.vec3.new(0, 0.5, 0),
						fp_offset = sm.vec3.new(0.0, -0.0, 0),
						apply_velocity = false
					},
				}
			},
			reload =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.2
					},
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Gun_anims", start_val = 0.2, end_val = 2.2 } },
						tp_anim = { { name = "Gun_anims", start_val = 0.2, end_val = 2.2 } },
						time = 2.0
					}
				},
				[2] = {
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "reload",
						name_fp = "reload",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false,
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.13
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "magout",
						name_fp = "magout",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false,
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 1.15
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "magin",
						name_fp = "magin",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false,
					}
				}
			},
			reload_empty =
			{
				[1] = { --first animation track
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.2
					},
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Gun_anims", start_val = 3.2, end_val = 6.0 } },
						tp_anim = { { name = "Gun_anims", start_val = 3.2, end_val = 6.0 } },
						time = 2.8
					}
				},
				[2] = {
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "reload_empty",
						name_fp = "reload_empty",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false,
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.03
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "magout",
						name_fp = "magout",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false,
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 1.15
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "magin",
						name_fp = "magin",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false,
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 1.35
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "rack",
						name_fp = "rack",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false,
					}
				}
			}
		}
	},

	ppsh_drum =
	{
		dlm_required_effects = {
			shoot_tp = "DLM_Muzzle_Flash_SmallCal_tp",
			shoot_fp = "DLM_Muzzle_Flash_SmallCal_fp",
			gunshot = "DLM_SMG_Shot_1",
			rack = "DLM_SMG_Rack_3",
			magin = "DLM_Drum_MagIn",
			magout = "DLM_Drum_MagOut"
		},
		required_effects = {
			shoot_tp = "Muzzle_Flash_SmallCal_tp",
			shoot_fp = "Muzzle_Flash_SmallCal_fp",
			reload = "TommyReload",
			reload_empty = "TommyEReload"
		},
		animation = {
			equip =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Gun_anims", start_val = 0.15, end_val = 0.15 } },
						tp_anim = { { name = "Gun_anims", start_val = 0.15, end_val = 0.15 } },
						time = 0.0
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
						fp_offset = sm.vec3.new(0.0, -0.0, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.particle,
						fp_offset = sm.vec3.new(0.01, -0.025, -0.035),
						tp_offset = sm.vec3.new(0, 0, 0),
						name_tp = "TommyShell",
						name_fp = "TommyShellFP",
						bone_name = "jnt_reciever",
						offsetAngle = -90
					},
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Gun_anims", start_val = 0.0, end_val = 0.15 } },
						tp_anim = { { name = "Gun_anims", start_val = 0.0, end_val = 0.15 } },
						time = 0.4
					}
				},
				[2] = {
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "gunshot",
						name_fp = "gunshot",
						tp_offset = sm.vec3.new(0, 0.5, 0),
						fp_offset = sm.vec3.new(0.0, -0.0, 0),
						apply_velocity = false
					},
				}
			},
			aimShoot =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "shoot_tp",
						name_fp = "shoot_fp",
						tp_offset = sm.vec3.new(0, 0.5, 0),
						fp_offset = sm.vec3.new(0.0, 0.5, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.particle,
						fp_offset = sm.vec3.new(-0.01, 0.2, -0.025),
						tp_offset = sm.vec3.new(0, 0, 0),
						name_tp = "TommyShell",
						name_fp = "TommyShellFP",
						bone_name = "jnt_reciever",
						offsetAngle = -90
					},
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Gun_anims", start_val = 0.0, end_val = 0.15 } },
						tp_anim = { { name = "Gun_anims", start_val = 0.0, end_val = 0.15 } },
						time = 0.4
					}
				},
				[2] = {
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "gunshot",
						name_fp = "gunshot",
						tp_offset = sm.vec3.new(0, 0.5, 0),
						fp_offset = sm.vec3.new(0.0, -0.0, 0),
						apply_velocity = false
					},
				}
			},
			reload =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.2
					},
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Gun_anims", start_val = 0.2, end_val = 2.2 } },
						tp_anim = { { name = "Gun_anims", start_val = 0.2, end_val = 2.2 } },
						time = 2.0
					}
				},
				[2] = {
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "reload",
						name_fp = "reload",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false,
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.25
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "magout",
						name_fp = "magout",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false,
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 1.15
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "magin",
						name_fp = "magin",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false,
					}
				}
			},
			reload_empty =
			{
				[1] = { --first animation track
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.2
					},
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Gun_anims", start_val = 3.2, end_val = 6.0 } },
						tp_anim = { { name = "Gun_anims", start_val = 3.2, end_val = 6.0 } },
						time = 2.8
					}
				},
				[2] = {
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "reload_empty",
						name_fp = "reload_empty",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false,
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.25
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "magout",
						name_fp = "magout",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false,
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 1.15
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "magin",
						name_fp = "magin",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false,
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 1.10
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "rack",
						name_fp = "rack",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false,
					}
				}
			}
		}
	},

	m1911 =
	{
		dlm_required_effects = {
			shoot_tp = "DLM_Muzzle_Flash_SmallCal_tp",
			shoot_fp = "DLM_Muzzle_Flash_SmallCal_fp",
			gunshot = "DLM_Pistol_Shot_3",
			slidedrop = "DLM_Pistol_SlideDrop",
			magin = "DLM_Pistol_MagIn",
			magout = "DLM_Pistol_MagOut",
			holster = "DLM_Pistol_Holster"
		},
		required_effects = {
			shoot_tp = "Muzzle_Flash_SmallCal_tp",
			shoot_fp = "Muzzle_Flash_SmallCal_fp",
			reload = "PistolReload",
			reload_empty = "PistolEReload"
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
						fp_offset = sm.vec3.new(0.0, -0.05, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.particle,
						fp_offset = sm.vec3.new(0, -0.07, 0),
						tp_offset = sm.vec3.new(0, 0, 0),
						name_tp = "TommyShell",
						name_fp = "TommyShellFP",
						bone_name = "jnt_slide"
					},
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "M1911_anims", start_val = 0.00, end_val = 0.2 } },
						tp_anim = { { name = "M1911_anims", start_val = 0.00, end_val = 0.2 } },
						time = 0.15
					}
				},
				[2] = {
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "gunshot",
						name_fp = "gunshot",
						tp_offset = sm.vec3.new(0, 0.5, 0),
						fp_offset = sm.vec3.new(0.0, -0.0, 0),
						apply_velocity = false
					}
				}
			},
			aimShoot =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "shoot_tp",
						name_fp = "shoot_fp",
						tp_offset = sm.vec3.new(0, 0.5, 0),
						fp_offset = sm.vec3.new(0.0, 0.25, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.particle,
						fp_offset = sm.vec3.new(-0.05, 0.15, 0),
						tp_offset = sm.vec3.new(0, 0, 0),
						name_tp = "TommyShell",
						name_fp = "TommyShellFP",
						bone_name = "jnt_slide"
					},
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "M1911_anims", start_val = 0.00, end_val = 0.2 } },
						tp_anim = { { name = "M1911_anims", start_val = 0.00, end_val = 0.2 } },
						time = 0.15
					}
				},
				[2] = {
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "gunshot",
						name_fp = "gunshot",
						tp_offset = sm.vec3.new(0, 0.5, 0),
						fp_offset = sm.vec3.new(0.0, -0.0, 0),
						apply_velocity = false
					}
				}
			},
			equip =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "M1911_anims", start_val = 0.2, end_val = 0.2 } },
						tp_anim = { { name = "M1911_anims", start_val = 0.2, end_val = 0.2 } },
						time = 0.0
					}
				}
			},
			last_shot_equip =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "M1911_anims", start_val = 2.1, end_val = 2.11 } },
						tp_anim = { { name = "M1911_anims", start_val = 2.1, end_val = 2.11 } },
						time = 0.1
					}
				}
			},
			last_shot =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "shoot_tp",
						name_fp = "shoot_fp",
						tp_offset = sm.vec3.new(0, 0.5, 0),
						fp_offset = sm.vec3.new(0.0, -0.05, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.particle,
						fp_offset = sm.vec3.new(0, -0.07, 0),
						tp_offset = sm.vec3.new(0, 0, 0),
						name_tp = "TommyShell",
						name_fp = "TommyShellFP",
						bone_name = "jnt_slide"
					},
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "M1911_anims", start_val = 2.0, end_val = 2.10 } },
						tp_anim = { { name = "M1911_anims", start_val = 2.0, end_val = 2.10 } },
						time = 0.1
					}
				},
				[2] = {
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "gunshot",
						name_fp = "gunshot",
						tp_offset = sm.vec3.new(0, 0.5, 0),
						fp_offset = sm.vec3.new(0.0, -0.0, 0),
						apply_velocity = false
					}
				}
			},
			reload =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.15
					},
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "M1911_anims", start_val = 0.15, end_val = 1.9 } },
						tp_anim = { { name = "M1911_anims", start_val = 0.15, end_val = 1.9 } },
						time = 1.75
					}
				},
				[2] = {
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "reload",
						name_fp = "reload",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false,
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.42
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "jnt_slide",
						name_tp = "magout",
						name_fp = "magout",
						tp_offset = sm.vec3.new(0, 0.5, 0),
						fp_offset = sm.vec3.new(0.0, -0.0, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.60
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "jnt_slide",
						name_tp = "magin",
						name_fp = "magin",
						tp_offset = sm.vec3.new(0, 0.5, 0),
						fp_offset = sm.vec3.new(0.0, -0.0, 0),
						apply_velocity = false
					}
				}
			},
			reload_empty =
			{
				[1] = { --first animation track

					{
						type = mgp_tool_anim_enum.delay,
						time = 0.10
					},
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "M1911_anims", start_val = 2.10, end_val = 3.75 } },
						tp_anim = { { name = "M1911_anims", start_val = 2.10, end_val = 3.75 } },
						time = 1.65
					}
				},
				[2] = {
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "reload_empty",
						name_fp = "reload_empty",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false,
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.35
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "jnt_slide",
						name_tp = "magout",
						name_fp = "magout",
						tp_offset = sm.vec3.new(0, 0.5, 0),
						fp_offset = sm.vec3.new(0.0, -0.0, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.5
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "jnt_slide",
						name_tp = "magin",
						name_fp = "magin",
						tp_offset = sm.vec3.new(0, 0.5, 0),
						fp_offset = sm.vec3.new(0.0, -0.0, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.5
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "jnt_slide",
						name_tp = "slidedrop",
						name_fp = "slidedrop",
						tp_offset = sm.vec3.new(0, 0.5, 0),
						fp_offset = sm.vec3.new(0.0, -0.0, 0),
						apply_velocity = false
					}
				}
			},
			ammo_check =
			{
				[1] = { --first animation track
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "M1911_anims", start_val = 3.75, end_val = 5.5 } },
						tp_anim = { { name = "M1911_anims", start_val = 3.75, end_val = 5.5 } },
						time = 1.75
					}
				},
				[2] = {
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.20
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "jnt_slide",
						name_tp = "magout",
						name_fp = "magout",
						tp_offset = sm.vec3.new(0, 0.5, 0),
						fp_offset = sm.vec3.new(0.0, -0.0, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.80
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "jnt_slide",
						name_tp = "magin",
						name_fp = "magin",
						tp_offset = sm.vec3.new(0, 0.5, 0),
						fp_offset = sm.vec3.new(0.0, -0.0, 0),
						apply_velocity = false
					}
				}
			}
		}
	},

	p38 =
	{
		dlm_required_effects = {
			shoot_tp = "DLM_Muzzle_Flash_SmallCal_tp",
			shoot_fp = "DLM_Muzzle_Flash_SmallCal_fp",
			gunshot = "DLM_Pistol_Shot_1",
			slidedrop = "DLM_Pistol_SlideDrop",
			magin = "DLM_Pistol_MagIn",
			magout = "DLM_Pistol_MagOut",
			holster = "DLM_Pistol_Holster"
		},
		required_effects = {
			shoot_tp = "Muzzle_Flash_SmallCal_tp",
			shoot_fp = "Muzzle_Flash_SmallCal_fp",
			reload = "PistolReload",
			reload_empty = "PistolEReload"
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
						fp_offset = sm.vec3.new(0.0, -0.05, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.particle,
						fp_offset = sm.vec3.new(0, -0.07, 0),
						tp_offset = sm.vec3.new(0, 0, 0),
						name_tp = "TommyShell",
						name_fp = "TommyShellFP",
						bone_name = "jnt_slide"
					},
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "P38_anims", start_val = 0.00, end_val = 0.2 } },
						tp_anim = { { name = "P38_anims", start_val = 0.00, end_val = 0.2 } },
						time = 0.15
					}
				},
				[2] = {
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "gunshot",
						name_fp = "gunshot",
						tp_offset = sm.vec3.new(0, 0.5, 0),
						fp_offset = sm.vec3.new(0.0, -0.0, 0),
						apply_velocity = false
					}
				}
			},
			aimShoot =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "shoot_tp",
						name_fp = "shoot_fp",
						tp_offset = sm.vec3.new(0, 0.5, 0),
						fp_offset = sm.vec3.new(0.0, 0.25, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.particle,
						fp_offset = sm.vec3.new(-0.05, 0.15, 0),
						tp_offset = sm.vec3.new(0, 0, 0),
						name_tp = "TommyShell",
						name_fp = "TommyShellFP",
						bone_name = "jnt_slide"
					},
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "P38_anims", start_val = 0.00, end_val = 0.2 } },
						tp_anim = { { name = "P38_anims", start_val = 0.00, end_val = 0.2 } },
						time = 0.15
					}
				},
				[2] = {
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "gunshot",
						name_fp = "gunshot",
						tp_offset = sm.vec3.new(0, 0.5, 0),
						fp_offset = sm.vec3.new(0.0, -0.0, 0),
						apply_velocity = false
					}
				}
			},
			equip =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "P38_anims", start_val = 0.2, end_val = 0.2 } },
						tp_anim = { { name = "P38_anims", start_val = 0.2, end_val = 0.2 } },
						time = 0.0
					}
				}
			},
			last_shot_equip =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "P38_anims", start_val = 2.1, end_val = 2.11 } },
						tp_anim = { { name = "P38_anims", start_val = 2.1, end_val = 2.11 } },
						time = 0.1
					}
				}
			},
			last_shot =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "shoot_tp",
						name_fp = "shoot_fp",
						tp_offset = sm.vec3.new(0, 0.5, 0),
						fp_offset = sm.vec3.new(0.0, -0.05, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.particle,
						fp_offset = sm.vec3.new(0, -0.07, 0),
						tp_offset = sm.vec3.new(0, 0, 0),
						name_tp = "TommyShell",
						name_fp = "TommyShellFP",
						bone_name = "jnt_slide"
					},
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "P38_anims", start_val = 2.0, end_val = 2.10 } },
						tp_anim = { { name = "P38_anims", start_val = 2.0, end_val = 2.10 } },
						time = 0.1
					}
				},
				[2] = {
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "gunshot",
						name_fp = "gunshot",
						tp_offset = sm.vec3.new(0, 0.5, 0),
						fp_offset = sm.vec3.new(0.0, -0.0, 0),
						apply_velocity = false
					}
				}
			},
			reload =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.15
					},
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "P38_anims", start_val = 0.15, end_val = 1.9 } },
						tp_anim = { { name = "P38_anims", start_val = 0.15, end_val = 1.9 } },
						time = 1.75
					}
				},
				[2] = {
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "reload",
						name_fp = "reload",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false,
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.42
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "jnt_slide",
						name_tp = "magout",
						name_fp = "magout",
						tp_offset = sm.vec3.new(0, 0.5, 0),
						fp_offset = sm.vec3.new(0.0, -0.0, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.60
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "jnt_slide",
						name_tp = "magin",
						name_fp = "magin",
						tp_offset = sm.vec3.new(0, 0.5, 0),
						fp_offset = sm.vec3.new(0.0, -0.0, 0),
						apply_velocity = false
					}
				}
			},
			reload_empty =
			{
				[1] = { --first animation track

					{
						type = mgp_tool_anim_enum.delay,
						time = 0.10
					},
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "P38_anims", start_val = 2.10, end_val = 3.75 } },
						tp_anim = { { name = "P38_anims", start_val = 2.10, end_val = 3.75 } },
						time = 1.65
					}
				},
				[2] = {
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "reload_empty",
						name_fp = "reload_empty",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false,
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.35
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "jnt_slide",
						name_tp = "magout",
						name_fp = "magout",
						tp_offset = sm.vec3.new(0, 0.5, 0),
						fp_offset = sm.vec3.new(0.0, -0.0, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.5
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "jnt_slide",
						name_tp = "magin",
						name_fp = "magin",
						tp_offset = sm.vec3.new(0, 0.5, 0),
						fp_offset = sm.vec3.new(0.0, -0.0, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.5
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "jnt_slide",
						name_tp = "slidedrop",
						name_fp = "slidedrop",
						tp_offset = sm.vec3.new(0, 0.5, 0),
						fp_offset = sm.vec3.new(0.0, -0.0, 0),
						apply_velocity = false
					}
				}
			},
			ammo_check =
			{
				[1] = { --first animation track
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "P38_anims", start_val = 3.75, end_val = 5.5 } },
						tp_anim = { { name = "P38_anims", start_val = 3.75, end_val = 5.5 } },
						time = 1.75
					}
				},
				[2] = {
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.20
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "jnt_slide",
						name_tp = "magout",
						name_fp = "magout",
						tp_offset = sm.vec3.new(0, 0.5, 0),
						fp_offset = sm.vec3.new(0.0, -0.0, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.80
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "jnt_slide",
						name_tp = "magin",
						name_fp = "magin",
						tp_offset = sm.vec3.new(0, 0.5, 0),
						fp_offset = sm.vec3.new(0.0, -0.0, 0),
						apply_velocity = false
					}
				}
			}
		}
	},

	Mp40 =
	{
		dlm_required_effects = {
			shoot_tp = "DLM_Muzzle_Flash_SmallCal_tp",
			shoot_fp = "DLM_Muzzle_Flash_SmallCal_fp",
			gunshot = "DLM_SMG_Shot_5",
			rack = "DLM_SMG_Rack_1",
			magin = "DLM_AR_MagIn",
			magout = "DLM_AR_MagOut"
		},
		required_effects = {
			shoot_tp = "Muzzle_Flash_SmallCal_tp",
			shoot_fp = "Muzzle_Flash_SmallCal_fp",
			reload = "MP40Reload"
		},
		on_unequip_action = {
			stop_effects = { "reload" }
		},
		animation = {
			equip =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Mp40_anims", start_val = 0.13, end_val = 0.13 } },
						tp_anim = { { name = "Mp40_anims", start_val = 0.13, end_val = 0.13 } },
						time = 0.0
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
						fp_offset = sm.vec3.new(0.0, -0.05, 0.0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.particle,
						fp_offset = sm.vec3.new(0, -0.07, 0),
						tp_offset = sm.vec3.new(0, 0, 0),
						name_tp = "TommyShell",
						name_fp = "TommyShellFP",
						bone_name = "jnt_ammo"
					},
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Mp40_anims", start_val = 0.0, end_val = 0.13 } },
						tp_anim = { { name = "Mp40_anims", start_val = 0.0, end_val = 0.13 } },
						time = 0.13
					}
				},
				[2] = {
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "gunshot",
						name_fp = "gunshot",
						tp_offset = sm.vec3.new(0, 0.5, 0),
						fp_offset = sm.vec3.new(0.0, -0.0, 0),
						apply_velocity = false
					},
				}
			},
			aimShoot =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "shoot_tp",
						name_fp = "shoot_fp",
						tp_offset = sm.vec3.new(0, 0.5, 0),
						fp_offset = sm.vec3.new(0.0, 0.5, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.particle,
						fp_offset = sm.vec3.new(0, 0.2, 0.015),
						tp_offset = sm.vec3.new(0, 0, 0),
						name_tp = "TommyShell",
						name_fp = "TommyShellFP",
						bone_name = "jnt_ammo"
					},
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Mp40_anims", start_val = 0.0, end_val = 0.13 } },
						tp_anim = { { name = "Mp40_anims", start_val = 0.0, end_val = 0.13 } },
						time = 0.13
					}
				},
				[2] = {
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "gunshot",
						name_fp = "gunshot",
						tp_offset = sm.vec3.new(0, 0.5, 0),
						fp_offset = sm.vec3.new(0.0, -0.0, 0),
						apply_velocity = false
					},
				}
			},
			reload =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "reload",
						name_fp = "reload",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false,

					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.13
					},
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Mp40_anims", start_val = 0.13, end_val = 4.5 } },
						tp_anim = { { name = "Mp40_anims", start_val = 0.13, end_val = 4.5 } },
						time = 4.37
					}
				},
				[2] = {
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.15
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "rack",
						name_fp = "rack",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false,

					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.85
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "magout",
						name_fp = "magout",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false,

					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 1.2
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "magin",
						name_fp = "magin",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false,

					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 1.10
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "rack",
						name_fp = "rack",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false,

					}
				}
			}
		}
	},

	Frag =
	{
		required_effects = {
			Clip = "GarandClip",
			ClipTake = "GarandClipTake",
		},
		animation = {
			activate =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Frag_anims", start_val = 0.0, end_val = 1.0 } },
						tp_anim = { { name = "Frag_anims", start_val = 0.0, end_val = 1.0 } },
						time = 1.0
					}
				},
				[2] = {

					{
						type = mgp_tool_anim_enum.delay,
						time = 0.5
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "jnt_lever",
						name_tp = "ClipTake",
						name_fp = "ClipTake",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
					},

				}
			},
			throw =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Frag_anims", start_val = 1.0, end_val = 1.25 } },
						tp_anim = { { name = "Frag_anims", start_val = 1.0, end_val = 1.25 } },
						time = 0.20
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.4
					},
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Frag_anims", start_val = 1.25, end_val = 0.0 } },
						tp_anim = { { name = "Frag_anims", start_val = 1.25, end_val = 0.0 } },
						time = 0.1
					}
				},

				[2] = {

					{
						type = mgp_tool_anim_enum.effect,
						bone = "jnt_lever",
						name_tp = "Clip",
						name_fp = "Clip",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
					}
				}
			}
		}
	},
	Magnum44 =
	{
		dlm_required_effects = {
			shoot_tp = "DLM_Muzzle_Flash_SmallCal_tp",
			shoot_fp = "DLM_Muzzle_Flash_SmallCal_fp",
			gunshot = "DLM_HighCal_Shot_1"
		},
		required_effects = {
			shoot_tp = "Muzzle_Flash_SmallCal_fp",
			shoot_fp = "Muzzle_Flash_SmallCal_fp",
			reload = "TommyReload"
		},
		on_unequip_action = {
			stop_effects = { "reload" }
		},
		animation_reset = {
			cock_the_hammer = mgp_magnum_aim_shoot_reset_table,
			cock_the_hammer_aim = mgp_magnum_shoot_reset_table,
			no_ammo = mgp_magnum_aim_shoot_reset_table,
			no_ammo_aim = mgp_magnum_shoot_reset_table,
			shoot = mgp_magnum_aim_shoot_reset_table,
			shoot_aim = mgp_magnum_shoot_reset_table
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
				},
				[2] = {
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "gunshot",
						name_fp = "gunshot",
						tp_offset = sm.vec3.new(0, 0.5, 0),
						fp_offset = sm.vec3.new(0.0, -0.0, 0),
						apply_velocity = false
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
						fp_offset = sm.vec3.new(0.0, 0.5, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Magnum44_aim_Shoot", start_val = 0.5, end_val = 1.0 } },
						tp_anim = { { name = "Magnum44_aim_Shoot", start_val = 0.5, end_val = 1.0 } },
						time = 0.1
					}
				},
				[2] = {
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "gunshot",
						name_fp = "gunshot",
						tp_offset = sm.vec3.new(0, 0.5, 0),
						fp_offset = sm.vec3.new(0.0, -0.0, 0),
						apply_velocity = false
					},
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
						name_tp = "reload",
						name_fp = "reload",
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
						name_tp = "reload",
						name_fp = "reload",
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
						name_tp = "reload",
						name_fp = "reload",
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
						name_tp = "reload",
						name_fp = "reload",
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
						name_tp = "reload",
						name_fp = "reload",
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
						name_tp = "reload",
						name_fp = "reload",
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
		dlm_required_effects = {
			shoot_tp = "DLM_Muzzle_Flash_SmallCal_tp",
			shoot_fp = "DLM_Muzzle_Flash_SmallCal_fp",
			gunshot = "DLM_BoltRifle_Shot_1",
			BoltOpen = "DLM_Rifle_Bolt_Open",
			BoltClose = "DLM_Rifle_Bolt_Close",
			BulletPut = "DLM_Gun_Ammo"
		},
		required_effects = {
			shoot_tp = "Muzzle_Flash_SmallCal_fp",
			shoot_fp = "Muzzle_Flash_SmallCal_fp",
			BoltOpen = "MosinBoltOpen",
			BoltClose = "MosinBoltClose",
			BulletPut = "MosinBulletPut"
		},
		on_unequip_action = {
			stop_effects = { "BoltOpen", "BoltClose", "BulletPut" }
		},
		animation = {
			cock_the_hammer_on_equip =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Mosin_Anim", start_val = 4.75, end_val = 4.75 } },
						tp_anim = { { name = "Mosin_Anim", start_val = 4.75, end_val = 4.75 } },
						time = 0.0
					}
				}
			},
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
						fp_anim = { { name = "Mosin_Anim", start_val = 4.0, end_val = 4.75 } },
						tp_anim = { { name = "Mosin_Anim", start_val = 4.0, end_val = 4.75 } },
						time = 0.75
					}
				},
				[2] = {
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.10
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "BoltOpen",
						name_fp = "BoltOpen",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.35
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "BoltClose",
						name_fp = "BoltClose",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
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
						fp_anim = { { name = "Mosin_Anim", start_val = 0.2, end_val = 0.3 } },
						tp_anim = { { name = "Mosin_Anim", start_val = 0.2, end_val = 0.3 } },
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
						fp_anim = { { name = "Mosin_Anim", start_val = 0.3, end_val = 0.6 } },
						tp_anim = { { name = "Mosin_Anim", start_val = 0.3, end_val = 0.6 } },
						time = 0.2
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.00
					},
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Mosin_Anim", start_val = 0.6, end_val = 0.4 } },
						tp_anim = { { name = "Mosin_Anim", start_val = 0.6, end_val = 0.3  } },
						time = 0.3
					},
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Mosin_Anim", start_val = 0.4, end_val = 0.2 } },
						tp_anim = { { name = "Mosin_Anim", start_val = 0.3, end_val = 0.2  } },
						time = 0.3
					}
				},
				[2] = {
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.15
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "BoltOpen",
						name_fp = "BoltOpen",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.5
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "BoltClose",
						name_fp = "BoltClose",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
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
					}
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
				},
				[2] = {
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "gunshot",
						name_fp = "gunshot",
						tp_offset = sm.vec3.new(0, 0.5, 0),
						fp_offset = sm.vec3.new(0.0, -0.0, 0),
						apply_velocity = false
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
						fp_anim = { { name = "Mosin_Anim", start_val = 0.0, end_val = 0.2 } },
						tp_anim = { { name = "Mosin_Anim", start_val = 0.0, end_val = 0.2 } },
						time = 0.2
					},
				},
				[2] = {
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "gunshot",
						name_fp = "gunshot",
						tp_offset = sm.vec3.new(0, 0.5, 0),
						fp_offset = sm.vec3.new(0.0, -0.0, 0),
						apply_velocity = false
					},
				}
			},
			reload4 =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Mosin_Anim", start_val = 0.0, end_val = 0.4 } },
						tp_anim = { { name = "Mosin_Anim", start_val = 0.0, end_val = 0.4 } },
						time = 0.4
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
						fp_anim = { { name = "Mosin_Anim", start_val = 0.8, end_val = 1.2 } },
						tp_anim = { { name = "Mosin_Anim", start_val = 0.8, end_val = 1.2 } },
						time = 0.8
					},
					{ type = mgp_tool_anim_enum.delay, time = 0.05 },
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Mosin_Anim", start_val = 1.2, end_val = 1.8 } },
						tp_anim = { { name = "Mosin_Anim", start_val = 1.2, end_val = 1.8 } },
						time = 0.5
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.2
					},
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Mosin_Anim", start_val = 4.0, end_val = 4.75 } },
						tp_anim = { { name = "Mosin_Anim", start_val = 4.0, end_val = 4.75 } },
						time = 1.0
					}
				},
				[2] = {
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.15
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "BoltOpen",
						name_fp = "BoltOpen",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 1.3
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "BulletPut",
						name_fp = "BulletPut",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.6
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "BoltClose",
						name_fp = "BoltClose",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
					}
				}
			},
			reload3 =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Mosin_Anim", start_val = 0.0, end_val = 0.4 } },
						tp_anim = { { name = "Mosin_Anim", start_val = 0.0, end_val = 0.4 } },
						time = 0.4
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
						fp_anim = { { name = "Mosin_Anim", start_val = 0.8, end_val = 1.2 } },
						tp_anim = { { name = "Mosin_Anim", start_val = 0.8, end_val = 1.2 } },
						time = 0.8
					},
					{ type = mgp_tool_anim_enum.delay, time = 0.05 },
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Mosin_Anim", start_val = 1.2, end_val = 2.4 } },
						tp_anim = { { name = "Mosin_Anim", start_val = 1.2, end_val = 2.4 } },
						time = 1.1
					},
					{ type = mgp_tool_anim_enum.delay, time = 0.1 },
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Mosin_Anim", start_val = 4.0, end_val = 4.75 } },
						tp_anim = { { name = "Mosin_Anim", start_val = 4.0, end_val = 4.75 } },
						time = 1.0
					}
				},
				[2] = {
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.15
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "BoltOpen",
						name_fp = "BoltOpen",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 1.3
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "BulletPut",
						name_fp = "BulletPut",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.6
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "BulletPut",
						name_fp = "BulletPut",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.4
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "BoltClose",
						name_fp = "BoltClose",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
					}
				}
			},
			reload2 =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Mosin_Anim", start_val = 0.0, end_val = 0.4 } },
						tp_anim = { { name = "Mosin_Anim", start_val = 0.0, end_val = 0.4 } },
						time = 0.4
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
						fp_anim = { { name = "Mosin_Anim", start_val = 0.8, end_val = 1.2 } },
						tp_anim = { { name = "Mosin_Anim", start_val = 0.8, end_val = 1.2 } },
						time = 0.8
					},
					{ type = mgp_tool_anim_enum.delay, time = 0.05 },
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Mosin_Anim", start_val = 1.2, end_val = 2.8 } },
						tp_anim = { { name = "Mosin_Anim", start_val = 1.2, end_val = 2.8 } },
						time = 1.5
					},
					{ type = mgp_tool_anim_enum.delay, time = 0.2 },
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Mosin_Anim", start_val = 4.0, end_val = 4.75 } },
						tp_anim = { { name = "Mosin_Anim", start_val = 4.0, end_val = 4.75 } },
						time = 1.0
					}
				},
				[2] = {
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.15
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "BoltOpen",
						name_fp = "BoltOpen",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 1.3
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "BulletPut",
						name_fp = "BulletPut",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.6
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "BulletPut",
						name_fp = "BulletPut",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.6
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "BulletPut",
						name_fp = "BulletPut",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.4
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "BoltClose",
						name_fp = "BoltClose",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
					}
				}
			},
			reload1 =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Mosin_Anim", start_val = 0.0, end_val = 0.4 } },
						tp_anim = { { name = "Mosin_Anim", start_val = 0.0, end_val = 0.4 } },
						time = 0.4
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
						fp_anim = { { name = "Mosin_Anim", start_val = 0.8, end_val = 1.2 } },
						tp_anim = { { name = "Mosin_Anim", start_val = 0.8, end_val = 1.2 } },
						time = 0.8
					},
					{ type = mgp_tool_anim_enum.delay, time = 0.05 },
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Mosin_Anim", start_val = 1.2, end_val = 3.3 } },
						tp_anim = { { name = "Mosin_Anim", start_val = 1.2, end_val = 3.3 } },
						time = 2.0
					},
					{ type = mgp_tool_anim_enum.delay, time = 0.2 },
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Mosin_Anim", start_val = 4.0, end_val = 4.75 } },
						tp_anim = { { name = "Mosin_Anim", start_val = 4.0, end_val = 4.75 } },
						time = 1.0
					}
				},
				[2] = {
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.15
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "BoltOpen",
						name_fp = "BoltOpen",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 1.3
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "BulletPut",
						name_fp = "BulletPut",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.6
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "BulletPut",
						name_fp = "BulletPut",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.6
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "BulletPut",
						name_fp = "BulletPut",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.5
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "BulletPut",
						name_fp = "BulletPut",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.4
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "BoltClose",
						name_fp = "BoltClose",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
					}
				}
			},
			reload0 =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Mosin_Anim", start_val = 0.0, end_val = 0.4 } },
						tp_anim = { { name = "Mosin_Anim", start_val = 0.0, end_val = 0.4 } },
						time = 0.4
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
						fp_anim = { { name = "Mosin_Anim", start_val = 0.8, end_val = 1.2 } },
						tp_anim = { { name = "Mosin_Anim", start_val = 0.8, end_val = 1.2 } },
						time = 0.77
					},
					{ type = mgp_tool_anim_enum.delay, time = 0.0 },
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Mosin_Anim", start_val = 1.2, end_val = 3.8 } },
						tp_anim = { { name = "Mosin_Anim", start_val = 1.2, end_val = 3.8 } },
						time = 2.7
					},
					{ type = mgp_tool_anim_enum.delay, time = 0.06 },
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Mosin_Anim", start_val = 4.0, end_val = 4.75 } },
						tp_anim = { { name = "Mosin_Anim", start_val = 4.0, end_val = 4.75 } },
						time = 1.0
					}
				},
				[2] = {
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.15
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "BoltOpen",
						name_fp = "BoltOpen",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 1.3
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "BulletPut",
						name_fp = "BulletPut",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.6
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "BulletPut",
						name_fp = "BulletPut",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.6
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "BulletPut",
						name_fp = "BulletPut",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.5
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "BulletPut",
						name_fp = "BulletPut",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.5
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "BulletPut",
						name_fp = "BulletPut",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.4
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "BoltClose",
						name_fp = "BoltClose",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
					}
				}
			},
			ammo_check =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.001
					},
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Mosin_Anim", start_val = 4.75, end_val = 4.27 } },
						tp_anim = { { name = "Mosin_Anim", start_val = 4.75, end_val = 4.27 } },
						time = 0.4
					},
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Mosin_Anim", start_val = 4.27, end_val = 4.25 } },
						tp_anim = { { name = "Mosin_Anim", start_val = 4.27, end_val = 4.25 } },
						time = 0.05
					},
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Mosin_Anim", start_val = 4.25, end_val = 4.19 } },
						tp_anim = { { name = "Mosin_Anim", start_val = 4.25, end_val = 4.19 } },
						time = 0.4
					},
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Mosin_Anim", start_val = 4.19, end_val = 4.17 } },
						tp_anim = { { name = "Mosin_Anim", start_val = 4.19, end_val = 4.17 } },
						time = 0.2
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.20
					},
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Mosin_Anim", start_val = 4.05, end_val = 4.75 } },
						tp_anim = { { name = "Mosin_Anim", start_val = 4.05, end_val = 4.75 } },
						time = 0.6
					}
				},
				[2] = {

					{
						type = mgp_tool_anim_enum.delay,
						time = 0.25
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "BoltOpen",
						name_fp = "BoltOpen",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.9
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "BoltClose",
						name_fp = "BoltClose",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
					}
				}
			}
		}
	},

	MosinNS =
	{
		dlm_required_effects = {
			shoot_tp = 		"DLM_Muzzle_Flash_SmallCal_tp",
			shoot_fp = 		"DLM_Muzzle_Flash_SmallCal_fp",
			gunshot = 		"DLM_BoltRifle_Shot_2",
			BoltOpen = 		"DLM_Rifle_Bolt2_Open",
			BoltClose = 	"DLM_Rifle_Bolt2_Close",
			BulletPut = 	"DLM_Gun_Ammo",
			Clip = 			"DLM_Rifle_Clip",
			ClipRemove = 	"DLM_Rifle_Clip_Remove",
			ClipHit = 		"DLM_Rifle_Clip_Hit"
		},
		required_effects = {
			shoot_tp = "Muzzle_Flash_SmallCal_fp",
			shoot_fp = "Muzzle_Flash_SmallCal_fp",
			BoltOpen = "MosinBoltOpen",
			BoltClose = "MosinBoltClose",
			BulletPut = "MosinBulletPut"
		},
		on_unequip_action = {
			stop_effects = { "BoltOpen", "BoltClose", "BulletPut" }
		},
		animation = {
			cock_the_hammer_on_equip =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "MosinNS_Anim", start_val = 1.5, end_val = 1.70 } },
						tp_anim = { { name = "MosinNS_Anim", start_val = 1.5, end_val = 1.70 } },
						time = 0.01
					}
				},
				[2] = {
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "MosinNS_Prop", start_val = 0.25, end_val = 0.5 } },
						tp_anim = { { name = "MosinNS_Prop", start_val = 0.25, end_val = 0.5 } },
						time = 0.25
					}
				}
			},
			cock_the_hammer =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "MosinNS_Anim", start_val = 0.0, end_val = 1.5 } },
						tp_anim = { { name = "MosinNS_Anim", start_val = 0.0, end_val = 1.5 } },
						time = 1.5
					}
				},
				[2] = {
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.20
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "BoltOpen",
						name_fp = "BoltOpen",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.35
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "BoltClose",
						name_fp = "BoltClose",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
					}
				}
			},
			cock_the_hammer_aim =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "MosinNS_Anim", start_val = 0.0, end_val = 1.5 } },
						tp_anim = { { name = "MosinNS_Anim", start_val = 0.0, end_val = 1.5 } },
						time = 1.5
					}
				},
				[2] = {
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.20
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "BoltOpen",
						name_fp = "BoltOpen",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.35
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "BoltClose",
						name_fp = "BoltClose",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
					}
				}
			},
			no_ammo =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "MosinNS_Anim", start_val = 0.0, end_val = 0.2 } },
						tp_anim = { { name = "MosinNS_Anim", start_val = 0.0, end_val = 0.2 } },
						time = 0.2
					}
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
				},
				[2] = {
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "gunshot",
						name_fp = "gunshot",
						tp_offset = sm.vec3.new(0, 0.5, 0),
						fp_offset = sm.vec3.new(0.0, -0.0, 0),
						apply_velocity = false
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
						fp_anim = { { name = "MosinNS_Anim", start_val = 0.0, end_val = 0.2 } },
						tp_anim = { { name = "MosinNS_Anim", start_val = 0.0, end_val = 0.2 } },
						time = 0.2
					},
				},
				[2] = {
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "gunshot",
						name_fp = "gunshot",
						tp_offset = sm.vec3.new(0, 0.5, 0),
						fp_offset = sm.vec3.new(0.0, -0.0, 0),
						apply_velocity = false
					},
				}
			},
			reload_into =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "MosinNS_Anim", start_val = 1.75, end_val = 2.45 } },
						tp_anim = { { name = "MosinNS_Anim", start_val = 1.75, end_val = 2.45 } },
						time = 0.70
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 1.05
					},
					{
						type = mgp_tool_anim_enum.nextAnimation,
						blendTp = 1,
						blendFp = 0,
						blendFp = 0,
						animation = "reload_single",
					}
				},
				[2] = {
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.10
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "BoltOpen",
						name_fp = "BoltOpen",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
					}
				}
			},
			reload_into_empty =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "MosinNS_Anim", start_val = 1.75, end_val = 2.5 } },
						tp_anim = { { name = "MosinNS_Anim", start_val = 1.75, end_val = 2.5 } },
						time = 0.75
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 1.0
					},
					{
						type = mgp_tool_anim_enum.nextAnimation,
						blendTp = 1,
						blendFp = 0,
						animation = "reload_clip"
					}
				},
				[2] = {
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.10
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "BoltOpen",
						name_fp = "BoltOpen",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
					}
				}
			},
			reload_single =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.15
					},
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "MosinNS_Prop", start_val = 0.0, end_val = 0.30 } },
						tp_anim = { { name = "MosinNS_Prop", start_val = 0.0, end_val = 0.30 } },
						time = 0.60
					},
					{
						type = mgp_tool_anim_enum.nextAnimation,
						blendTp = 1,
						blendFp = 0,
						animation = function(self)
							return ReloadLoop(self, "reload_single", "reload_exit", sm.uuid.new("295481d0-910a-48d4-a04a-e1bf1290e510"))
						end,
					}
				},
				[2] = {
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.10
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "BulletPut",
						name_fp = "BulletPut",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
					}
				}
			},
			reload_clip =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "MosinNS_Anim", start_val = 2.5, end_val = 4.5 } },
						tp_anim = { { name = "MosinNS_Anim", start_val = 2.5, end_val = 4.5 } },
						time = 2.0
					},
					{
						type = mgp_tool_anim_enum.nextAnimation,
						blendTp = 1,
						blendFp = 0,
						animation = function(self)
							return ReloadLoop(self, nil, "reload_exit", nil, true)
						end,
					}
				},
				[2] = {
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.35
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "ClipHit",
						name_fp = "ClipHit",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.65
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "Clip",
						name_fp = "Clip",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.4
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "ClipRemove",
						name_fp = "ClipRemove",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
					},
				},
				[3] = {
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "MosinNS_Prop", start_val = 0.25, end_val = 0.5 } },
						tp_anim = { { name = "MosinNS_Prop", start_val = 0.25, end_val = 0.5 } },
						time = 0.25
					}
				}
			},
			reload_exit =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "MosinNS_Anim", start_val = 4.5, end_val = 5.25 } },
						tp_anim = { { name = "MosinNS_Anim", start_val = 4.5, end_val = 5.25 } },
						time = 0.75
					}
				},
				[2] = {
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.1
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "BoltClose",
						name_fp = "BoltClose",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
					}
				}
			},
			ammo_check = {}
		}
	},

	Garand =
	{
		dlm_required_effects = {
			shoot_tp = "DLM_Muzzle_Flash_SmallCal_tp",
			shoot_fp = "DLM_Muzzle_Flash_SmallCal_fp",
			gunshot = "DLM_SemiRifle_Shot_1",
			ping = "DLM_Rifle_Ping",
			ammocheck = "DLM_Gun_AmmoCheck",
			slidedrop = "DLM_Pistol_SlideDrop"
			
		},
		required_effects = {
			shoot_tp = "Muzzle_Flash_SmallCal_fp",
			shoot_fp = "Muzzle_Flash_SmallCal_fp",
			Clip = "GarandClip",
			Check = "GarandRecieverMove",
			Reciever = "GarandReciever",
			ping = "GarandPing",
			ClipTake = "GarandClipTake",
			BulletPut = "MosinBulletPut",
			GarandThumb = "GarandThumb"
		},
		on_unequip_action = {
			stop_effects = { "ping", "GarandThumb", "BulletPut" }
		},
		animation = {
			no_ammo =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Mosin_Anim", start_val = 0.6, end_val = 0.7 } },
						tp_anim = { { name = "Mosin_Anim", start_val = 0.6, end_val = 0.7 } },
						time = 0.2
					}
				}
			},
			no_ammo_aim =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Mosin_Anim", start_val = 0.6, end_val = 0.7 } },
						tp_anim = { { name = "Mosin_Anim", start_val = 0.6, end_val = 0.7 } },
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
						type = mgp_tool_anim_enum.particle,
						fp_offset = sm.vec3.new(0, 0, 0),
						tp_offset = sm.vec3.new(0, 0, 0),
						name_tp = "TommyShell",
						name_fp = "TommyShellFP",
						bone_name = "Clip"
					},
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Mosin_Anim", start_val = 0.0, end_val = 0.15 } },
						tp_anim = { { name = "Mosin_Anim", start_val = 0.0, end_val = 0.15 } },
						time = 0.01
					},
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Mosin_Anim", start_val = 0.15, end_val = 0.0 } },
						tp_anim = { { name = "Mosin_Anim", start_val = 0.15, end_val = 0.0 } },
						time = 0.1
					}
				},
				[2] = {
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "gunshot",
						name_fp = "gunshot",
						tp_offset = sm.vec3.new(0, 0.5, 0),
						fp_offset = sm.vec3.new(0.0, -0.0, 0),
						apply_velocity = false
					},
				}
			},
			aimShoot =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "shoot_tp",
						name_fp = "shoot_fp",
						tp_offset = sm.vec3.new(0, 0.5, 0),
						fp_offset = sm.vec3.new(0.0, 0.5, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.particle,
						fp_offset = sm.vec3.new(0, 0.25, 0),
						tp_offset = sm.vec3.new(0, 0, 0),
						name_tp = "TommyShell",
						name_fp = "TommyShellFP",
						bone_name = "Clip"
					},
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Mosin_Anim", start_val = 0.0, end_val = 0.15 } },
						tp_anim = { { name = "Mosin_Anim", start_val = 0.0, end_val = 0.15 } },
						time = 0.01
					},
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Mosin_Anim", start_val = 0.15, end_val = 0.0 } },
						tp_anim = { { name = "Mosin_Anim", start_val = 0.15, end_val = 0.0 } },
						time = 0.1
					}
				},
				[2] = {
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "gunshot",
						name_fp = "gunshot",
						tp_offset = sm.vec3.new(0, 0.5, 0),
						fp_offset = sm.vec3.new(0.0, -0.0, 0),
						apply_velocity = false
					},
				}
			},
			last_shot_equip =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Mosin_Anim", start_val = 0.7, end_val = 0.7 } },
						tp_anim = { { name = "Mosin_Anim", start_val = 0.7, end_val = 0.7 } },
						time = 0.0
					}
				}
			},
			last_shot =
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
						type = mgp_tool_anim_enum.particle,
						fp_offset = sm.vec3.new(0, 0, 0),
						tp_offset = sm.vec3.new(0, 0, 0),
						name_tp = "TommyShell",
						name_fp = "TommyShellFP",
						bone_name = "Clip"
					},
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Mosin_Anim", start_val = 0.0, end_val = 0.7 } },
						tp_anim = { { name = "Mosin_Anim", start_val = 0.0, end_val = 0.7 } },
						time = 0.35
					}
				},
				[2] = {
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.11
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "ping",
						name_fp = "ping",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
					}
				},
				[3] = {
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "gunshot",
						name_fp = "gunshot",
						tp_offset = sm.vec3.new(0, 0.5, 0),
						fp_offset = sm.vec3.new(0.0, -0.0, 0),
						apply_velocity = false
					},
				}
			},
			reload_gt =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.7
					},
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Mosin_Anim", start_val = 0.7, end_val = 2.33 } },
						tp_anim = { { name = "Mosin_Anim", start_val = 0.7, end_val = 2.33 } },
						time = 1.63
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 1.1
					},
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Mosin_Anim", start_val = 2.33, end_val = 2.50 } },
						tp_anim = { { name = "Mosin_Anim", start_val = 2.33, end_val = 2.50 } },
						time = 0.17
					}
				},
				[2] = {
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.8
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "ClipTake",
						name_fp = "ClipTake",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.95
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "Clip",
						name_fp = "Clip",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.4
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "GarandThumb",
						name_fp = "GarandThumb",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 1.0
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "slidedrop",
						name_fp = "slidedrop",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
					}
				}
			},
			reload =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.7
					},
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Mosin_Anim", start_val = 0.7, end_val = 2.5 } },
						tp_anim = { { name = "Mosin_Anim", start_val = 0.7, end_val = 2.5 } },
						time = 1.80
					}
				},
				[2] = {
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.8
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "ClipTake",
						name_fp = "ClipTake",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.95
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "Clip",
						name_fp = "Clip",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.4
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "slidedrop",
						name_fp = "slidedrop",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
					}
				}
			},
			ammo_check =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.4
					},
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Mosin_Anim", start_val = 2.40, end_val = 2.30 } },
						tp_anim = { { name = "Mosin_Anim", start_val = 2.40, end_val = 2.30 } },
						time = 0.9
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.35
					},
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Mosin_Anim", start_val = 2.30, end_val = 2.40 } },
						tp_anim = { { name = "Mosin_Anim", start_val = 2.30, end_val = 2.40 } },
						time = 0.15
					}
				},
				[2] = {
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.7
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "ammocheck",
						name_fp = "ammocheck",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
					}
				}
			}
		}
	},

	PTRD =
	{
		dlm_required_effects = {
			shoot_tp = "DLM_Muzzle_Flash_SmallCal_tp",
			shoot_fp = "DLM_Muzzle_Flash_SmallCal_fp",
			gunshot = "DLM_BoltRifle_Shot_1",
			BoltOpen = "DLM_AT_Bolt_Open",
			BoltClose = "DLM_AT_Bolt_Close",
			BulletPut = "DLM_AT_Ammo",
			BipodDeploy = "DLM_Bipod_Deploy",
			BipodHide = "DLM_Bipod_Hide"
		},
		required_effects = {
			shoot_tp = "Muzzle_Flash_SmallCal_fp",
			shoot_fp = "Muzzle_Flash_SmallCal_fp",
			BoltOpen = "MosinBoltOpen",
			BoltClose = "MosinBoltClose",
			BulletPut = "MosinBulletPut"
		},
		animation = {

			hide_bipod =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Gun_Anim", start_val = 0.0, end_val = 0.5 } },
						tp_anim = { { name = "Gun_Anim", start_val = 0.0, end_val = 0.5 } },
						time = 0.3
					}
				},
				[2] = {
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.1
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "BipodHide",
						name_fp = "BipodHide",
						tp_offset = sm.vec3.new(0, 0.5, 0),
						fp_offset = sm.vec3.new(0.0, -0.0, 0),
						apply_velocity = false
					}
				}
			},
			deploy_bipod =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Gun_Anim", start_val = 1.0, end_val = 1.5 } },
						tp_anim = { { name = "Gun_Anim", start_val = 1.0, end_val = 1.5 } },
						time = 0.3
					}
				},
				[2] = {
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.5
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "BipodDeploy",
						name_fp = "BipodDeploy",
						tp_offset = sm.vec3.new(0, 0.5, 0),
						fp_offset = sm.vec3.new(0.0, -0.0, 0),
						apply_velocity = false
					}
				}	
			},
			shoot =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.effect,
						bone = "jnt_muzzle",
						name_tp = "shoot_tp",
						name_fp = "shoot_fp",
						tp_offset = sm.vec3.new(0, 0.5, 0),
						fp_offset = sm.vec3.new(0.0, -0.04, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Gun_Anim", start_val = 0.5, end_val = 1.0 } },
						tp_anim = { { name = "Gun_Anim", start_val = 0.5, end_val = 1.0 } },
						time = 0.5
					}
				},
				[2] = {
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "gunshot",
						name_fp = "gunshot",
						tp_offset = sm.vec3.new(0, 0.5, 0),
						fp_offset = sm.vec3.new(0.0, -0.0, 0),
						apply_velocity = false
					}
				}
			},
			aimShoot =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.effect,
						bone = "jnt_muzzle",
						name_tp = "shoot_tp",
						name_fp = "shoot_fp",
						tp_offset = sm.vec3.new(0, 0.5, 0),
						fp_offset = sm.vec3.new(0.0, 0.5, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Gun_Anim", start_val = 0.5, end_val = 1.0 } },
						tp_anim = { { name = "Gun_Anim", start_val = 0.5, end_val = 1.0 } },
						time = 0.5
					}
				},
				[2] = {
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "gunshot",
						name_fp = "gunshot",
						tp_offset = sm.vec3.new(0, 0.5, 0),
						fp_offset = sm.vec3.new(0.0, -0.0, 0),
						apply_velocity = false
					}
				}
			},
			shoot_bipod =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.effect,
						bone = "jnt_muzzle",
						name_tp = "shoot_tp",
						name_fp = "shoot_fp",
						tp_offset = sm.vec3.new(0, 0.5, 0),
						fp_offset = sm.vec3.new(0.0, -0.04, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Gun_Anim", start_val = 1.5, end_val = 2.0 } },
						tp_anim = { { name = "Gun_Anim", start_val = 1.5, end_val = 2.0 } },
						time = 0.5
					}
				},
				[2] = {
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "gunshot",
						name_fp = "gunshot",
						tp_offset = sm.vec3.new(0, 0.5, 0),
						fp_offset = sm.vec3.new(0.0, -0.0, 0),
						apply_velocity = false
					}
				}
			},
			reload =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.5
					},
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Gun_Anim", start_val = 2.5, end_val = 5.5 } },
						tp_anim = { { name = "Gun_Anim", start_val = 2.5, end_val = 5.5 } },
						time = 3.0
					}
				},
				[2] = {
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.55
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "BoltOpen",
						name_fp = "BoltOpen",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 1.5
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "BulletPut",
						name_fp = "BulletPut",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.85
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "BoltClose",
						name_fp = "BoltClose",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
					}
				}
			},
			reload_bipod =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Gun_Anim", start_val = 2.0, end_val = 6.0 } },
						tp_anim = { { name = "Gun_Anim", start_val = 2.0, end_val = 6.0 } },
						time = 4.0
					}
				},
				[2] = {
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.55
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "BoltOpen",
						name_fp = "BoltOpen",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 1.5
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "BulletPut",
						name_fp = "BulletPut",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.85
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "BoltClose",
						name_fp = "BoltClose",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
					}
				}
			}
		}
	},

	DB =
	{
		dlm_required_effects = {
			shoot_tp = "DLM_Muzzle_Flash_SmallCal_tp",
			shoot_fp = "DLM_Muzzle_Flash_SmallCal_fp",
			shoot_single = "DLM_Shotgun_Shot_1",
			shoot_double = "DLM_Shotgun_Shot_2",
			Open = "DLM_Shotgun_Break",
			Open2 = "DLM_Shotgun_Open",
			Close = "DLM_Shotgun_Close",
			BulletPut = "DLM_Shotgun_AmmoIn",
			BulletTake = "DLM_Shotgun_AmmoOut"
		},
		required_effects = {
			shoot_tp = "Muzzle_Flash_SmallCal_tp",
			shoot_fp = "Muzzle_Flash_SmallCal_fp",
			MagOpen = "DBOpen",
			BoltClose = "MosinBoltClose",
			BulletPut = "MosinBulletPut"
		},
		on_unequip_action = {
			stop_effects = { "BulletPut", "MagOpen", "BoltClose" }
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
						fp_offset = sm.vec3.new(0.0, -0.04, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "shoot_single",
						name_fp = "shoot_single",
						tp_offset = sm.vec3.new(0, 0.5, 0),
						fp_offset = sm.vec3.new(0.0, -0.04, 0),
						apply_velocity = false
					}
				}
			},
			aimShoot =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "shoot_tp",
						name_fp = "shoot_fp",
						tp_offset = sm.vec3.new(0, 0.5, 0),
						fp_offset = sm.vec3.new(0.0, 0.5, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "shoot_single",
						name_fp = "shoot_single",
						tp_offset = sm.vec3.new(0, 0.5, 0),
						fp_offset = sm.vec3.new(0.0, 0.5, 0),
						apply_velocity = false
					}
				}
			},
			ammo_check =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "DB_anims_check", start_val = 0.0, end_val = 2.25 } },
						tp_anim = { { name = "DB_anims_check", start_val = 0.0, end_val = 2.25 } },
						time = 2.25
					}
				},
				[2] = {

					{
						type = mgp_tool_anim_enum.delay,
						time = 0.25
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "Open2",
						name_fp = "Open2",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.25
					},
					{
						type = mgp_tool_anim_enum.event,
						callback = "cl_n_displayMagInfo"
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.75
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "Close",
						name_fp = "Close",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
					}
				}
			},
			reload =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "DB_anims_1", start_val = 0.0, end_val = 3.5 } },
						tp_anim = { { name = "DB_anims_1", start_val = 0.0, end_val = 3.5 } },
						time = 3.5
					}
				},
				[2] = {
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.15
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "Open2",
						name_fp = "Open2",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.8
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "BulletTake",
						name_fp = "BulletTake",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 1.13
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "BulletPut",
						name_fp = "BulletPut",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.8
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "Close",
						name_fp = "Close",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.3
					},
					{
						type = mgp_tool_anim_enum.event,
						callback = "sv_n_trySpendAmmo",
						server = true
					}
				}
			},
			reload_empty =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "DB_anims_0", start_val = 0.0, end_val = 4.416 } },
						tp_anim = { { name = "DB_anims_0", start_val = 0.0, end_val = 4.416 } },
						time = 4.416
					}
				},
				[2] = {

					{
						type = mgp_tool_anim_enum.delay,
						time = 0.22
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "Open",
						name_fp = "Open",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 1.52
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "BulletPut",
						name_fp = "BulletPut",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 1.20
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "BulletPut",
						name_fp = "BulletPut",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.77
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "Close",
						name_fp = "Close",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.2
					},
					{
						type = mgp_tool_anim_enum.event,
						callback = "sv_n_trySpendAmmo",
						server = true
					}
				}
			},
			reload_type =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "DB_anims_T", start_val = 0.0, end_val = 4.75 } },
						tp_anim = { { name = "DB_anims_T", start_val = 0.0, end_val = 4.75 } },
						time = 4.75
					}
				},
				[2] = {

					{
						type = mgp_tool_anim_enum.delay,
						time = 0.15
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "Open2",
						name_fp = "Open2",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.8
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "BulletTake",
						name_fp = "BulletTake",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.82
					},
					{
						type = mgp_tool_anim_enum.event,
						callback = "cl_changeColour"
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.27
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "BulletPut",
						name_fp = "BulletPut",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 1.19
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "BulletPut",
						name_fp = "BulletPut",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
					},
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.85
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "Close",
						name_fp = "Close",
						tp_offset = sm.vec3.new(0, 0, 0),
						fp_offset = sm.vec3.new(0, 0, 0),
						apply_velocity = false
					}
				}
			}
		}
	},
	Bazooka =
	{
		dlm_required_effects = {
			shoot_tp = "DLM_Muzzle_Flash_SmallCal_tp",
			shoot_fp = "DLM_Muzzle_Flash_SmallCal_fp",
			gunshot = "DLM_AT_Shot_2",
			load = "DLM_Bazooka_Ammo"
		},
		required_effects = {
			shoot_tp = "Muzzle_Flash_SmallCal_tp",
			shoot_fp = "Muzzle_Flash_SmallCal_fp",
			MagOpen = "DBOpen",
			BoltClose = "MosinBoltClose",
			BulletPut = "MosinBulletPut"
		},
		on_unequip_action = {
			stop_effects = { "BulletPut", "MagOpen", "BoltClose" }
		},
		animation_reset = {
			on_equip = { fp = { { "BZ_Anim", 3.0 } }, tp = { { "BZ_Anim", 3.0 } } }
		},
		animation = {
			on_equip =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "BZ_Anim", start_val = 0.0, end_val = 3.50 } },
						tp_anim = { { name = "BZ_Anim", start_val = 0.0, end_val = 3.50 } },
						time = 3.5
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
						fp_offset = sm.vec3.new(0.0, 0.1, 0),
						apply_velocity = false
					}
				},
				[2] = {
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "BZ_Anim", start_val = 4.0, end_val = 4.30 } },
						tp_anim = { { name = "BZ_Anim", start_val = 4.0, end_val = 4.30 } },
						time = 0.1
					}
				},
				[3] = {
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "gunshot",
						name_fp = "gunshot",
						tp_offset = sm.vec3.new(0, 0.5, 0),
						fp_offset = sm.vec3.new(0.0, -0.0, 0),
						apply_velocity = false
					},
				}
			},
			aimShoot =
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
				},
				[2] = {
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "BZ_Anim", start_val = 4.0, end_val = 4.30 } },
						tp_anim = { { name = "BZ_Anim", start_val = 4.0, end_val = 4.30 } },
						time = 0.1
					}
				},
				[3] = {
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "gunshot",
						name_fp = "gunshot",
						tp_offset = sm.vec3.new(0, 0.5, 0),
						fp_offset = sm.vec3.new(0.0, -0.0, 0),
						apply_velocity = false
					},
				}

			},
			reload =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.delay,
						time = 1.0
					},
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "BZ_Anim", start_val = 4.4, end_val = 7.50 } },
						tp_anim = { { name = "BZ_Anim", start_val = 4.4, end_val = 7.50 } },
						time = 3.1
					}
				},
				[2] = {
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "load",
						name_fp = "load",
						tp_offset = sm.vec3.new(0, 0.5, 0),
						fp_offset = sm.vec3.new(0.0, -0.0, 0),
						apply_velocity = false
					},
				}
			},
			reload_empty =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.delay,
						time = 0.1
					},
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "BZ_Anim", start_val = 3.60, end_val = 6.25 } },
						tp_anim = { { name = "BZ_Anim", start_val = 3.60, end_val = 6.25 } },
						time = 3.2
					}
				},
				[2] = {
					{
						type = mgp_tool_anim_enum.delay,
						time = 2.15
					},
					{
						type = mgp_tool_anim_enum.effect,
						bone = "pejnt_barrel",
						name_tp = "load",
						name_fp = "load",
						tp_offset = sm.vec3.new(0, 0.5, 0),
						fp_offset = sm.vec3.new(0.0, -0.0, 0),
						apply_velocity = false
					},
				}
			}
		}
	},
	Medkit =
	{
		dlm_required_effects = {},
		required_effects = {},
		on_unequip_action = {},
		animation_reset = {},
		animation = {
			on_equip =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Medkit_Anim", start_val = 0.0, end_val = 2.0 } },
						tp_anim = { { name = "Medkit_Anim", start_val = 0.0, end_val = 2.0 } },
						time = 2.0
					}				
				},
				[2] = {
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Medkit_Syr", start_val = 0.0, end_val = 0.1 } },
						tp_anim = { { name = "Medkit_Syr", start_val = 0.0, end_val = 0.1 } },
						time = 0.01
					}
				}
			},
			use =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Medkit_Anim", start_val = 2.0, end_val = 6.0 } },
						tp_anim = { { name = "Medkit_Anim", start_val = 2.0, end_val = 6.0 } },
						time = 4.0
					}
				},
				[2] = {
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Medkit_Syr", start_val = 0.0, end_val = 0.1 } },
						tp_anim = { { name = "Medkit_Syr", start_val = 0.0, end_val = 0.1 } },
						time = 0.01
					}
				}
			},
			use2 =
			{
				[1] = {
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Medkit_Anim", start_val = 6.0, end_val = 10.0 } },
						tp_anim = { { name = "Medkit_Anim", start_val = 6.0, end_val = 10.0 } },
						time = 4.0
					}
				},
				[2] = {
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Medkit_Syr", start_val = 0.0, end_val = 3.9 } },
						tp_anim = { { name = "Medkit_Syr", start_val = 0.0, end_val = 3.9 } },
						time = 3.9
					},
					{
						type = mgp_tool_anim_enum.bone_animation,
						fp_anim = { { name = "Medkit_Syr", start_val = 0.0, end_val = 0.1 } },
						tp_anim = { { name = "Medkit_Syr", start_val = 0.0, end_val = 0.1 } },
						time = 0.1
					}
				}
			},
			run_into =
			{
				[1] = {

				}
			},
			run_idle =
			{
				[1] = {

				}
			},
			run_exit =
			{
				[1] = {

				}
			},
			putdown =
			{
				[1] = {

				}
			}
		}
	}
}

function mgp_getToolData(tool_name)
	return mgp_tool_database[tool_name]
end