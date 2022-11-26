DatabaseLoader = {}

local _Database = {
    ["f0f14c15-4d9c-4dc3-8518-4ae65af491da"] = { --Hispano 20mm Gun
        server = {
            cannon = {
               spread = 1.5,
                fire_force = {
                    min = 400.0,
                    max = 400.0
                },
                recoil = sm.vec3.new(0, 0, -400),
                reload_time = 10,
                auto_reload = true
            },
            projectile = {
                effect = "boom",
                explosionEffect = "Boom20",
                effectOffset = sm.vec3.new(0, 0, 0.5),
                lifetime = 20.0,
                gravity = 10.0,
                friction = 0.003,
                explosionLevel = 4,
                explosionRadius = 0.5,
                explosionImpulseStrength = 4,
                explosionImpulseRadius = 2
            }
        },
        client = {
            effects = {
                shoot = {name = "BoomMuzlle20", offset = sm.vec3.new(0, 0, 0.5), bone_name = nil}
            },
            pose_animation = {
                {particles = {"shoot"}}
            }
        }
    },
    ["4825e551-b9c4-484e-8216-efec182957f5"] = { --Old Cannon
        server = {
            cannon = {
               spread = 2,
                fire_force = {
                    min = 120.0,
                    max = 120.0
                },
                recoil = sm.vec3.new(0, 0, -100),
                reload_time = 280,
                auto_reload = true
            },
            projectile = {
                effect = "boom",
                explosionEffect = "PropaneTank - ExplosionBig",
                effectOffset = sm.vec3.new(0, 0, 0.5),
                lifetime = 20.0,
                gravity = 10.0,
                friction = 0.01,
                explosionLevel = 4,
                explosionRadius = 1,
                explosionImpulseStrength = 2,
                explosionImpulseRadius = 2
            }
        },
        client = {
            effects = {
                shoot = {name = "BombSmall", offset = sm.vec3.new(0, 0, 0.5), bone_name = nil}
            },
            pose_animation = {
                {particles = {"shoot"}}
            }
        }
    },
    ["28fbfaf6-3b42-4d72-94b1-5bf7b113b5dd"] = { --PTRD bipod
        server = {
            cannon = {
                spread = 0.5,
                fire_force = {
                    min = 400.0,
                    max = 400.0
                },
                recoil = sm.vec3.new(0, 0, -200),
                reload_time = 120,
                auto_reload = true
            },
            projectile = {
                effect = "boom",
                explosionEffect = "Boom20",
                effectOffset = sm.vec3.new(0, 0, 0.9),
                lifetime = 20.0,
                gravity = 10.0,
                friction = 0.003,
                explosionLevel = 6,
                explosionRadius = 0.3,
                explosionImpulseStrength = 5,
                explosionImpulseRadius = 5
            }
        },
        client = {
            effects = {
                shoot = {name = "BoomRusznica", offset = sm.vec3.new(0, 0, 1.5), bone_name = nil}
            },
            bone_animation = {
                required_animations = {"PTRD"},
                animation_states = {
                    shoot = {
                        {particles = {"shoot"}},
                        {anims = {"PTRD"}, start_value = 0.0, end_value = 1.0, time = 3.0}
                    }
                }
            }
        }
    },
    ["b6d96e7c-80ad-4838-b9fb-364c8205c23a"] = { --PTRD
        server = {
            cannon = {
                spread = 0.5,
                fire_force = {
                    min = 400.0,
                    max = 400.0
                },
                recoil = sm.vec3.new(0, 0, -200),
                reload_time = 120,
                auto_reload = true
            },
            projectile = {
                effect = "boom",
                explosionEffect = "Boom20",
                effectOffset = sm.vec3.new(0, 0, 0.9),
                lifetime = 20.0,
                gravity = 10.0,
                friction = 0.003,
                explosionLevel = 6,
                explosionRadius = 0.3,
                explosionImpulseStrength = 5,
                explosionImpulseRadius = 5
            }
        },
        client = {
            effects = {
                shoot = {name = "BoomRusznica", offset = sm.vec3.new(0, 0, 1.5), bone_name = nil}
            },
            bone_animation = {
                required_animations = {"PTRD"},
                animation_states = {
                    shoot = {
                        {particles = {"shoot"}},
                        {anims = {"PTRD"}, start_value = 0.0, end_value = 1.0, time = 3.0}
                    }
                }
            }
        },
    },
    ["ba6c5d49-3792-4a2c-b3a4-acef3ab8a787"] = { --Cannon
        server = {
            cannon = {
                spread = 0.5,
                fire_force = {
                    min = 400.0,
                    max = 400.0
                },
                recoil = sm.vec3.new(0, 0, -200),
                reload_time = 160,
                auto_reload = true
            },
            projectile = {
                effect = "boom",
                explosionEffect = "PropaneTank - ExplosionBig",
                effectOffset = sm.vec3.new(0, 0, 1.3),
                lifetime = 20.0,
                gravity = 10.0,
                friction = 0.003,
                explosionLevel = 7,
                explosionRadius = 1,
                explosionImpulseStrength = 5,
                explosionImpulseRadius = 5
            }
        },
        client = {
            effects = {
                shoot = {name = "BombSmall", offset = sm.vec3.new(0, 0, 1.5), bone_name = nil}
            },
            bone_animation = {
                required_animations = {"reload"},
                animation_states = {
                    shoot = {
                        {particles = {"shoot"}},
                        {anims = {"reload"}, start_value = 0.0, end_value = 1.0, time = 4.0}
                    }
                }
            }
        }
    },
    ["9fec1f9f-9f39-4d95-95d3-c15c4389e095"] = { --WZ.38 20mm Gun
        server = {
            cannon = {
                spread = 1.0,
                fire_force = {
                    min = 400.0,
                    max = 400.0
                },
                recoil = sm.vec3.new(0, 0, -400),
                reload_time = 7,
                auto_reload = true
            },
            projectile = {
                effect = "boom",
                explosionEffect = "Boom20",
                effectOffset = sm.vec3.new(0, 0, 0.9),
                lifetime = 20.0,
                gravity = 10.0,
                friction = 0.003,
                explosionLevel = 4,
                explosionRadius = 0.5,
                explosionImpulseStrength = 4,
                explosionImpulseRadius = 2
            }
        },
        client = {
            effects = {
                shoot = {name = "BoomMuzlle20", offset = sm.vec3.new(0, 0, 1.0), bone_name = nil}
            },
            pose_animation = {
                {particles = {"shoot"}}
            }
        }
    },
    ["9664ed91-6917-43ce-8051-6dea8ac28e18"] = { --Bazooka M1A1
        server = {
            cannon = {
                spread = 1.0,
                fire_force = {
                    min = 200.0,
                    max = 225.0
                },
                recoil = sm.vec3.new(0, 0, -400),
                reload_time = 120,
                auto_reload = false
            },
            projectile = {
                effect = "boom",
                explosionEffect = "PropaneTank - ExplosionSmall",
                effectOffset = sm.vec3.new(0, 0, 1.4),
                lifetime = 20.0,
                gravity = 4.0,
                friction = 0.003,
                explosionLevel = 7,
                explosionRadius = 0.5,
                explosionImpulseStrength = 3,
                explosionImpulseRadius = 4
            }
        },
        client = {
            effects = {
                shoot = {name = "PropaneTank - ExplosionSmall", offset = sm.vec3.new(0, 0, 1.4), bone_name = nil}
            },
            pose_animation = {
                {particles = {"shoot"}}
            }
        }
    },
    ["073d0f36-9bee-47e4-b4b6-c42568648e3b"] = { --Mg 151/20
        server = {
            cannon = {
                spread = 1.5,
                fire_force = {
                    min = 400.0,
                    max = 450.0
                },
                recoil = sm.vec3.new(0, 0, -400),
                reload_time = 5,
                auto_reload = true
            },
            projectile = {
                effect = "boom",
                explosionEffect = "Boom20",
                effectOffset = sm.vec3.new(0, 0, 0.6),
                lifetime = 20.0,
                gravity = 10.0,
                friction = 0.003,
                explosionLevel = 4,
                explosionRadius = 0.5,
                explosionImpulseStrength = 4,
                explosionImpulseRadius = 2
            }
        },
        client = {
            effects = {
                shoot = {name = "BoomMuzlle20", offset = sm.vec3.new(0, 0, 0.62), bone_name = nil}
            },
            pose_animation = {
                {particles = {"shoot"}}
            }
        }
    },
    ["cd1b3309-7046-4b81-ac01-f7ba8f7a00d7"] = { --M61 Vulcan 20mm
        server = {
            cannon = {
                spread = 4,
                fire_force = {
                    min = 1000.0,
                    max = 1000.0
                },
                recoil = sm.vec3.new(0, 0, -1000),
                reload_time = 2,
                auto_reload = true
            },
            projectile = {
                effect = "boom",
                explosionEffect = "Boom20",
                effectOffset = sm.vec3.new(0, 0, 1.0),
                lifetime = 20.0,
                gravity = 10.0,
                friction = 0.003,
                explosionLevel = 5,
                explosionRadius = 0.5,
                explosionImpulseStrength = 4,
                explosionImpulseRadius = 2
            }
        },
        client = {
            effects = {
                shoot = {name = "BoomMuzzle12", offset = sm.vec3.new(0, 0.08, 1.0), bone_name = nil}
            },
            pose_animation = {
                {particles = {"shoot"}},
                {pose = 0, start_value = 0.0, end_value = 1.0, time = 0.00001},
                {pose = 0, start_value = 1.0, end_value = 0.0, time = 0.03}
            }
        }
    },
    ["bdd9e357-35f7-4140-8b19-477abef20e0f"] = { --Browning .50 HMG
        server = {
            cannon = {
                spread = 0.5,
                fire_force = {
                    min = 600.0,
                    max = 600.0
                },
                recoil = sm.vec3.new(0, 0, -100),
                reload_time = 4,
                auto_reload = true,
            },
            projectile = {
                effect = "boom",
                explosionEffect = "Boom12",
                effectOffset = sm.vec3.new(0, 0, 1.9),
                lifetime = 20.0,
                gravity = 10.0,
                friction = 0.001,
                explosionLevel = 1,
                explosionRadius = 0.3,
                explosionImpulseStrength = 4,
                explosionImpulseRadius = 2
            }
        },
        client = {
            effects = {
                shoot = {name = "BoomMuzzle12", offset = sm.vec3.new(0, 0, 0.75), bone_name = nil}
            },
            pose_animation = {
                {particles = {"shoot"}},
                {pose = 0, start_value = 0.0, end_value = 1.0, time = 0.001},
                {pose = 0, start_value = 1.0, end_value = 0.0, time = 0.1}
            }
        }
    },
    ["de609e41-58d1-409a-b981-447be0257609"] = { --Browning .50 1x1 HMG
        server = {
            cannon = {
                spread = 0.5,
                fire_force = {
                    min = 600.0,
                    max = 600.0
                },
                recoil = sm.vec3.new(0, 0, -100),
                reload_time = 4,
                auto_reload = true,
            },
            projectile = {
                effect = "boom",
                explosionEffect = "Boom12",
                effectOffset = sm.vec3.new(0, 0, 1.9),
                lifetime = 20.0,
                gravity = 10.0,
                friction = 0.001,
                explosionLevel = 1,
                explosionRadius = 0.3,
                explosionImpulseStrength = 4,
                explosionImpulseRadius = 2
            }
        },
        client = {
            effects = {
                shoot = {name = "BoomMuzzle12", offset = sm.vec3.new(0, 0, 0.25), bone_name = nil}
            },
            pose_animation = {
                {particles = {"shoot"}}
            }
        }
    },
    ["f9213740-d7ca-41ed-b1c8-23dd704c9063"] = { --Browning .50 HMG Aircraft
        server = {
            cannon = {
                spread = 0.5,
                fire_force = {
                    min = 600.0,
                    max = 600.0
                },
                recoil = sm.vec3.new(0, 0, -100),
                reload_time = 4,
                auto_reload = true,
                projectile_offset = sm.vec3.new(0, 0, 1.9),
            },
            projectile = {
                effect = "boom",
                explosionEffect = "Boom12",
                effectOffset = sm.vec3.new(0, 0, 1.9),
                lifetime = 20.0,
                gravity = 10.0,
                friction = 0.003,
                explosionLevel = 1,
                explosionRadius = 0.3,
                explosionImpulseStrength = 4,
                explosionImpulseRadius = 2
            }
        },
        client = {
            effects = {
                shoot = {name = "BoomMuzzle12", offset = sm.vec3.new(0, 0, 0.55), bone_name = nil}
            },
            pose_animation = {
                {particles = {"shoot"}},
                {pose = 0, start_value = 0.0, end_value = 1.0, time = 0.001},
                {pose = 0, start_value = 1.0, end_value = 0.0, time = 0.1}
            }
        }
    },
    ["05f70a50-3bb4-4a00-b7fb-f1c931d585ca"] = { --12mm DSzK Machine Gun
        server = {
            cannon = {
                spread = 0.5,
                fire_force = {
                    min = 600.0,
                    max = 600.0
                },
                recoil = sm.vec3.new(0, 0, -100),
                reload_time = 4,
                auto_reload = true,
                projectile_offset = sm.vec3.new(0, 0, 0.7),
            },
            projectile = {
                effect = "boom",
                explosionEffect = "Boom12",
                effectOffset = sm.vec3.new(0, 0, 0.73),
                lifetime = 20.0,
                gravity = 10.0,
                friction = 0.003,
                explosionLevel = 1,
                explosionRadius = 0.3,
                explosionImpulseStrength = 2,
                explosionImpulseRadius = 3
            }
        },
        client = {
            effects = {
                shoot = {name = "BoomMuzzle12", offset = sm.vec3.new(0, 0, 0.8), bone_name = nil}
            },
            pose_animation = {
                {particles = {"shoot"}}
            }
        }
    },

    --[[

        NON-EXPLOSIVE CANNONS

    ]]
    
    
    ["e33ed886-b55b-489a-b11d-7f590cea0be7"] = { --Maxim M1905
        server = {
            cannon = {
                spread = 1,
                fire_force = {
                    min = 500.0,
                    max = 500.0
                },
                recoil = sm.vec3.new(0, 0, -100),
                reload_time = 4,                                                        
                auto_reload = true,
                projectile_offset = sm.vec3.new(0, 0, 0.6),
                projectile = sm.uuid.new("18a2dffb-ea20-4ab1-9bb3-bb66a2571854")
            }
        },
        client = {
            effects = {
                shoot = {name = "BoomMuzzle7", offset = sm.vec3.new(0, -0.04, 0.48), bone_name = nil} 
            },
            pose_animation = {
                {particles = {"shoot"}},
                {pose = 0, start_value = 0.0, end_value = 1.0, time = 0.001},
                {pose = 0, start_value = 1.0, end_value = 0.0, time = 0.1}
            }
        }
    },
    ["8edb6045-f410-441c-b9a9-a55ab15a90c7"] = { --Maxim M1905 1x1
        server = {
            cannon = {
                spread = 1,
                fire_force = {
                    min = 500.0,
                    max = 500.0
                },
                recoil = sm.vec3.new(0, 0, -100),
                reload_time = 4,
                auto_reload = true,
                projectile_offset = sm.vec3.new(0, 0, 0.6),
                projectile = sm.uuid.new("18a2dffb-ea20-4ab1-9bb3-bb66a2571854")
            }
        },
        client = {
            effects = {
                shoot = {name = "BoomMuzzle7", offset = sm.vec3.new(0, -0.04, 0.27), bone_name = nil}                
            },
            pose_animation = {
                {particles = {"shoot"}}
            }
        }
    },
    ["690ce3fd-6f14-4d6d-9a47-8576fec4350d"] = { --Mac-31 LMG
    server = {
        cannon = {
            spread = 0.3,
            fire_force = {
                min = 800.0,
                max = 800.0
            },
            recoil = sm.vec3.new(0, 0, -100),
            reload_time = 3,
            auto_reload = true,
            projectile_offset = sm.vec3.new(0, 0, 1),
            projectile = sm.uuid.new("18a2dffb-ea20-4ab1-9bb3-bb66a2571854")
        }
    },
    client = {
        effects = {
            shoot = {name = "BoomMuzzle7", offset = sm.vec3.new(0, 0, 0.25), bone_name = nil}
        },
        pose_animation = {
            {particles = {"shoot"}}
        }
    }
},
    ["1e731dbe-d89e-4722-b955-d347f92eec62"] = { --Maschinegewher Mg-34 LMG
        server = {
            cannon = {
                spread = 0.5,
                fire_force = {
                    min = 800.0,
                    max = 800.0
                },
                recoil = sm.vec3.new(0, 0, -100),
                reload_time = 3,
                auto_reload = true,
                projectile_offset = sm.vec3.new(0, 0, 0.7),
                projectile = sm.uuid.new("18a2dffb-ea20-4ab1-9bb3-bb66a2571854")
            }
        },
        client = {
            effects = {
                shoot = {name = "BoomMuzzle7", offset = sm.vec3.new(0, 0, 0.6), bone_name = nil}
            },
            pose_animation = {
                {particles = {"shoot"}}
            }
        }
    },
    ["7ee6c514-3362-4fd1-b581-d8047b18801f"] = { --Maschinegewher Mg-15 LMG
        server = {
            cannon = {
                spread = 0.5,
                fire_force = {
                    min = 800.0,
                    max = 800.0
                },
                recoil = sm.vec3.new(0, 0, -100),
                reload_time = 3,
                auto_reload = true,
                projectile_offset = sm.vec3.new(0, 0, 1),
                projectile = sm.uuid.new("18a2dffb-ea20-4ab1-9bb3-bb66a2571854")
            }
        },
        client = {
            effects = {
                shoot = {name = "BoomMuzzle7", offset = sm.vec3.new(0, 0, 0.42), bone_name = nil}
            },
            pose_animation = {
                {particles = {"shoot"}},
                {pose = 0, start_value = 0.0, end_value = 1.0, time = 0.001},
                {pose = 0, start_value = 1.0, end_value = 0.0, time = 0.05}
            }
        }
    },
    ["6d98a168-f0c5-4774-a6ac-e0972fd9f1a4"] = { --Mosin-Nagant 1891 Rifle
    server = {
        cannon = {
            spread = 0.01,
            fire_force = {
                min = 1200.0,
                max = 1200.0
            },
            recoil = sm.vec3.new(0, 0, -100),
            reload_time = 100,
            auto_reload = true,
            projectile_offset = sm.vec3.new(0, 0, 0.7),
            projectile = sm.uuid.new("18a2dffb-ea20-4ab1-9bb3-bb66a2571854"),

            magazine_capacity = 5
        }
    },
    client = {
        effects = {
            shoot = {name = "MosinShot", offset = sm.vec3.new(0, 0, 0.7), bone_name = nil},
            reload = {name = "MosinReload", offset = sm.vec3.new(0, 0, 0.77)}

        },


        bone_animation = {
            required_animations = {"Shots", "Reload"},
            animation_states = {
                shoot = {
                    {particles = {"shoot"}}, --time can be removed if you need no delay
                    {anims = {"Shots"}, start_value = 0.0, end_value = 1.0, time = 2.2}
                },
                reload = { --will never get executed if magazine_capacity variable is 0 or missing
                    {particles = {"reload"}},
                    {anims = {"Reload"}, start_value = 0.0, end_value = 1.0, time = 3.3}
                }
            }
        }
    }
},
    ["dee496d2-a9a9-4708-9a2f-50910f59f8fa"] = { -- AK-47 Kalashnikov
        server = {
            cannon = {
                spread = 3.5,
                fire_force = {
                    min = 600.0,
                    max = 600.0
                },
                recoil = sm.vec3.new(0, 0, -400),
                reload_time = 4,
                auto_reload = true,
                projectile_offset = sm.vec3.new(0, 0, 0.65),
                projectile = sm.uuid.new("18a2dffb-ea20-4ab1-9bb3-bb66a2571854")
            }
        },
        client = {
            effects = {
                shoot = {name = "BoomMuzzle7", offset = sm.vec3.new(0, 0, 0.5), bone_name = nil}
            },
            pose_animation = {
                {particles = {"shoot"}},
                {pose = 0, start_value = 0.0, end_value = 1.0, time = 0.001},
                {pose = 0, start_value = 1.0, end_value = 0.0, time = 0.1}
            }
        }
    },
    ["7f25238c-0e9a-4910-b3ff-f63016fc9052"] = { -- Degytariev Dp-29
        server = {
            cannon = {
                spread = 0.5,
                fire_force = {
                    min = 800.0,
                    max = 800.0
                },
                recoil = sm.vec3.new(0, 0, -100),
                reload_time = 4,
                auto_reload = true,
                projectile_offset = sm.vec3.new(0, 0, 0.7),
                projectile = sm.uuid.new("18a2dffb-ea20-4ab1-9bb3-bb66a2571854")
            }
        },
        client = {
            effects = {
                shoot = {name = "BoomMuzzle7", offset = sm.vec3.new(0, 0, 0.63), bone_name = nil}
            },
            pose_animation = {
                {particles = {"shoot"}}
            }
        }
    },
    ["68337ca8-e957-4b3f-a6dd-c11ac61da064"] = { -- DGv03
        server = {
            cannon = {
                spread = 0.5,
                fire_force = {
                    min = 700.0,
                    max = 700.0
                },
                recoil = sm.vec3.new(0, 0, -100),
                reload_time = 4,
                auto_reload = true,
                projectile_offset = sm.vec3.new(0, 0, 0.9),
                projectile = sm.uuid.new("18a2dffb-ea20-4ab1-9bb3-bb66a2571854")
            }
        },
        client = {
            effects = {
                shoot = {name = "BoomMuzzle7", offset = sm.vec3.new(0, 0, 0.95), bone_name = nil}
            },
            pose_animation = {
                {particles = {"shoot"}}
            }
        }
    },
    ["b23027d0-0a69-4e82-a917-d43acce49057"] = { -- 1x8 7.7mm Gun Polygon
        server = {
            cannon = {
                spread = 0.5,
                fire_force = {
                    min = 600.0,
                    max = 600.0
                },
                recoil = sm.vec3.new(0, 0, -100),
                reload_time = 4,
                auto_reload = true,
                projectile_offset = sm.vec3.new(0, 0, 0.5),
                projectile = sm.uuid.new("18a2dffb-ea20-4ab1-9bb3-bb66a2571854")
            }
        },
        client = {
            effects = {
                shoot = {name = "BoomMuzzle7", offset = sm.vec3.new(0, 0, 0.55), bone_name = nil}
            },
            pose_animation = {
                {particles = {"shoot"}}
            }
        }
    },
    ["32e96b7d-a08a-483c-88c6-8a1616ea3123"] = { --Browning .30 LMG
        server = {
            cannon = {
                spread = 0.5,
                fire_force = {
                    min = 800.0,
                    max = 800.0
                },
                recoil = sm.vec3.new(0, 0, -100),
                reload_time = 3,
                auto_reload = true,
                projectile_offset = sm.vec3.new(0, 0, 0.4),
                projectile = sm.uuid.new("18a2dffb-ea20-4ab1-9bb3-bb66a2571854"),

               
            }
        },
        client = {

            effects = {
                shoot = {name = "BoomMuzzle7", offset = sm.vec3.new(0, 0, 0.32), bone_name = nil}         
            },


            bone_animation = {
                required_animations = {"Shots"},
                animation_states = {
                    shoot = {
                        {particles = {"shoot"}}, --time can be removed if you need no delay
                        {anims = {"Shots"}, start_value = 0.0, end_value = 1.0, time = 0.2}
                    }
                }
            }
        }
    },
    ["45c849b8-9417-446d-b703-75c582bd9b60"] = { --Browning .30 1x1
        server = {
            cannon = {
                spread = 0.5,
                fire_force = {
                    min = 800.0,
                    max = 800.0
                },
                recoil = sm.vec3.new(0, 0, -100),
                reload_time = 3,
                auto_reload = true,
                projectile_offset = sm.vec3.new(0, 0, 0.4),
                projectile = sm.uuid.new("18a2dffb-ea20-4ab1-9bb3-bb66a2571854"),

               
            }
        },
        client = {

            effects = {
                shoot = {name = "BoomMuzzle7", offset = sm.vec3.new(0, 0, 0.32), bone_name = nil}         
            },


            bone_animation = {
                required_animations = {"Shots"},
                animation_states = {
                    shoot = {
                        {particles = {"shoot"}}, --time can be removed if you need no delay
                        {anims = {"Shots"}, start_value = 0.0, end_value = 1.0, time = 0.2}
                    }
                }
            }
        }
    },
    ["2779083c-1ee2-4b52-9eb3-586a383c5d4e"] = { --Maschinegewehr MG-42 1x1 
        server = {
            cannon = {
                spread = 0.5,
                fire_force = {
                    min = 800.0,
                    max = 800.0
                },
                recoil = sm.vec3.new(0, 0, -100),
                reload_time = 2,
                auto_reload = true,
                projectile_offset = sm.vec3.new(0, 0, 0.5),
                projectile = sm.uuid.new("18a2dffb-ea20-4ab1-9bb3-bb66a2571854"),

               
            }
        },
        client = {

            effects = {
                shoot = {name = "BoomMuzzle7", offset = sm.vec3.new(0, 0, 0.28), bone_name = nil}         
            },


            bone_animation = {
                required_animations = {"Shots"},
                animation_states = {
                    shoot = {
                        {particles = {"shoot"}}, --time can be removed if you need no delay
                        {anims = {"Shots"}, start_value = 0.0, end_value = 1.0, time = 0.2}
                    },
                    overheat = { --will never get executed if heat_per_shot variable is 0 or not present
                        {anims = {"BarrelExchange"}, start_value = 0.0, end_value = 1.0, time = 4.0}
                    }
                }
            }
        }
    },
    ["b0384020-b6ac-45ae-9df3-045e51cc7e8a"] = { --Maschinegewehr MG-42 LMG
        server = {
            cannon = {
                spread = 0.5,
                fire_force = {
                    min = 800.0,
                    max = 800.0
                },
                recoil = sm.vec3.new(0, 0, -100),
                reload_time = 2,
                auto_reload = true,
                projectile_offset = sm.vec3.new(0, 0, 0.7),
                projectile = sm.uuid.new("18a2dffb-ea20-4ab1-9bb3-bb66a2571854"),

                magazine_capacity = 50
            }
        },
        client = {
            overheat_effect = {
                heat_per_shot = 0.02, --heating per shot (starts overheating animation at 1.0)
                cooling_speed = 0.05, --cooling per second
                uv_overheat_anim_max = 64.0
            },

            effects = {
                shoot = {name = "BoomMuzzle7", offset = sm.vec3.new(0, 0, 0.575), bone_name = nil},
                overheat = {name = "overheat", offset = sm.vec3.new(0, 0, 0.77)},
                reload = {name = "MG42reload", offset = sm.vec3.new(0, 0, 0.77)}

            },


            bone_animation = {
                required_animations = {"Shots", "BarrelExchange", "Reload"},
                animation_states = {
                    shoot = {
                        {particles = {"shoot"}}, --time can be removed if you need no delay
                        {anims = {"Shots"}, start_value = 0.0, end_value = 1.0, time = 0.2}
                    },
                    overheat = { --will never get executed if heat_per_shot variable is 0 or not present
                        {particles = {"overheat"}},
                        {anims = {"BarrelExchange"}, start_value = 0.0, end_value = 1.0, time = 4.0}
                    },
                    reload = { --will never get executed if magazine_capacity variable is 0 or missing
                        {particles = {"reload"}},
                        {anims = {"Reload"}, start_value = 0.0, end_value = 1.0, time = 6.0}
                    }
                }
            }
        }
    },
    ["0ccd6479-f1d8-46e6-acb1-02f9dc20f577"] = { --Degytariev Dp-29 1x1
        server = {
            cannon = {
                spread = 0.5,
                fire_force = {
                    min = 800.0,
                    max = 800.0
                },
                recoil = sm.vec3.new(0, 0, -100),
                reload_time = 4,
                auto_reload = true,
                projectile_offset = sm.vec3.new(0, 0, 0.6),
                projectile = sm.uuid.new("18a2dffb-ea20-4ab1-9bb3-bb66a2571854")
            }
        },
        client = {
            effects = {
                shoot = {name = "BoomMuzzle7", offset = sm.vec3.new(0, 0, 0.45), bone_name = nil}
            },
            pose_animation = {
                {particles = {"shoot"}}
            }
        }
    },
    ["c4b65002-2928-4829-8661-84a08a31a253"] = { --Lewis M1914 Machine Gun
        server = {
            cannon = {
                spread = 1.0,
                fire_force = {
                    min = 800.0,
                    max = 800.0
                },
                recoil = sm.vec3.new(0, 0, -100),
                reload_time = 4,
                auto_reload = true,
                projectile_offset = sm.vec3.new(0, 0, 0.45),
                projectile = sm.uuid.new("18a2dffb-ea20-4ab1-9bb3-bb66a2571854")
            }
        },
        client = {
            effects = {
                shoot = {name = "BoomMuzzle7", offset = sm.vec3.new(0, 0, 0.42), bone_name = nil}
            },

            debris = {
                position = sm.vec3.new(0.2, 0, -0.5),
                direction = sm.vec3.new(1, 0, 0),
                spread = 50,
                velocity = 5,
                uuid = sm.uuid.new("40a3242a-7416-47b2-847c-f23a759a26a0")
            },

            pose_animation = {
                {particles = {"shoot"}},
                {pose = 0, start_value = 0.0, end_value = 1.0, time = 0.001},
                {pose = 0, start_value = 1.0, end_value = 0.0, time = 0.05}
            }
        }
    }
}

function DatabaseLoader.getServerSettings(gun_uuid)
    local _CurGun = _Database[tostring(gun_uuid)]
    if _CurGun and _CurGun.server then
        return _CurGun.server
    else
        print("Couldn't find the specified gun uuid")
    end
end

function DatabaseLoader.getClientSettings(gun_uuid)
    local _CurGun = _Database[tostring(gun_uuid)]
    if _CurGun and _CurGun.client then
        return _CurGun.client
    else
        print("Couldn't find the specified gun uuid")
    end
end