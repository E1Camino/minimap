local randomGreenBlueishColor = function()
    return Color(255, math.random(1, 40), math.random(1, 255), math.random(1, 255))
end

local inn_default = {
    near = 100,
    far = 10000,
    height = 2000,
    area = 12
}

local keep_masks = {
    {
        triangles = {},
        color = {
            255,
            255,
            0,
            0
        }
    }
}

local level_data = {
    inn_level = {
        name = "inn_level",
        children = {
            farm = {
                name = "farm",
                check = {
                    type = "polygon",
                    features = {
                        {
                            -14.1387,
                            28.1612,
                            12
                        },
                        {
                            -18.8,
                            41.6764,
                            12
                        },
                        {
                            -11.9466,
                            44.2933,
                            12
                        },
                        {
                            -6.77303,
                            31.1788,
                            12
                        }
                    }
                },
                settings = {
                    area = 8,
                    near = 13.52
                },
                children = {
                    farm_top_of_roof = {
                        name = "farm_top_of_roof",
                        check = {
                            type = "above",
                            height = 13
                        },
                        settings = inn_default
                    }
                }
            },
            bridge = {
                name = "bridge",
                check = {
                    type = "polygon",
                    features = {
                        {
                            13.446,
                            6.814,
                            12
                        },
                        {
                            7.772,
                            12.532,
                            12
                        },
                        {
                            17.528,
                            22.060,
                            12
                        },
                        {
                            23.668,
                            16.671,
                            12
                        }
                    }
                },
                children = {
                    under_the_bridge = {
                        name = "under_the_bridge",
                        check = {
                            type = "below",
                            height = 10
                        },
                        masks = {
                            {
                                triangles = {
                                    {
                                        {
                                            20.0928,
                                            15.1687,
                                            4.04
                                        },
                                        {
                                            20.2095,
                                            16.945,
                                            4.04
                                        },
                                        {
                                            20.15,
                                            16.945,
                                            4.04
                                        }
                                    }
                                },
                                color = {
                                    255,
                                    10,
                                    10,
                                    10
                                }
                            }
                        },
                        settings = {
                            near = 9
                        }
                    },
                    on_bridge_roof = {
                        name = "on_bridge_roof",
                        check = {
                            type = "above",
                            height = 15
                        },
                        settings = {
                            near = inn_default.near
                        }
                    }
                },
                settings = {
                    near = 15.6
                }
            },
            ammo = {
                name = "ammo",
                check = {
                    type = "polygon",
                    features = {
                        {
                            -24.1287,
                            35.05,
                            13.64
                        },
                        {
                            -25.76,
                            39.03,
                            13.64
                        },
                        {
                            -22.65,
                            40.21,
                            13.64
                        },
                        {
                            -20.92,
                            36.562,
                            13.64
                        }
                    }
                },
                settings = {
                    near = 13.0,
                    area = 4
                }
            },
            keep = {
                name = "keep",
                check = {
                    type = "polygon",
                    features = {
                        {
                            -24.156,
                            -3.377,
                            0
                        },
                        {
                            -24.247,
                            3.5,
                            0
                        },
                        {
                            -22.819,
                            3.63,
                            6
                        },
                        {
                            -19.29,
                            7.08,
                            0
                        },
                        {
                            -12.7208,
                            6.97,
                            0
                        },
                        {
                            -11.648,
                            9.667,
                            0
                        },
                        {
                            -8.312,
                            12.8,
                            0
                        },
                        {
                            -14.423,
                            27.596,
                            0
                        },
                        {
                            0.833,
                            33.636,
                            0
                        },
                        {
                            4.217,
                            34.227,
                            0
                        },
                        {
                            7.944,
                            16.525,
                            0
                        },
                        {
                            4.666,
                            15.191,
                            0
                        },
                        {
                            6.295,
                            15.165,
                            0
                        },
                        {
                            14.207,
                            7.384,
                            0
                        },
                        {
                            22.029,
                            8.895,
                            0
                        },
                        {
                            27.141,
                            7.63,
                            0
                        },
                        {
                            30.34,
                            4.541,
                            0
                        },
                        {
                            30.742,
                            -8.488,
                            0
                        },
                        {
                            15.6,
                            -23.559,
                            0
                        },
                        {
                            9.496,
                            -28.773,
                            0
                        },
                        {
                            -3.023,
                            -28.754,
                            0
                        },
                        {
                            -4.233,
                            -25.306,
                            0
                        },
                        {
                            -2.974,
                            -23.639,
                            0
                        },
                        {
                            -3.122,
                            -21.343,
                            0
                        },
                        {
                            -13.93,
                            -19.68,
                            0
                        },
                        {
                            -19.37,
                            -14.277,
                            0
                        },
                        {
                            -20.119,
                            -6.387,
                            0
                        }
                    }
                },
                masks = keep_masks,
                settings = {
                    near = 15.6,
                    area = 8
                },
                children = {
                    lohner = {
                        name = "lohner",
                        check = {
                            type = "polygon",
                            features = {
                                {
                                    8.85047,
                                    -3.24998,
                                    10
                                },
                                {
                                    3.65326,
                                    -7.06038,
                                    10
                                },
                                {
                                    0.03,
                                    -8.284,
                                    12
                                },
                                {
                                    -6.276,
                                    -4.723,
                                    12
                                },
                                {
                                    -9.04664,
                                    -1.16898,
                                    10
                                },
                                {
                                    -9.1019,
                                    3.87,
                                    10
                                },
                                {
                                    5.44146,
                                    4.16039,
                                    10
                                },
                                {
                                    6.28618,
                                    -0.387159,
                                    10
                                }
                            }
                        },
                        masks = keep_masks,
                        settings = {
                            near = 21
                        }
                    },
                    keep_level_1 = {
                        name = "keep_level_1",
                        check = {
                            type = "below",
                            height = 7.6
                        },
                        masks = keep_masks,
                        settings = {
                            near = 9
                        },
                        children = {
                            keep_ground_floor = {
                                name = "keep_ground_floor",
                                check = {
                                    type = "below",
                                    height = 4.5
                                },
                                children = {
                                    armoury = {
                                        name = "armoury",
                                        check = {
                                            type = "polygon",
                                            features = {
                                                {
                                                    -21.351,
                                                    -7.934,
                                                    4.5
                                                },
                                                {
                                                    -0.833,
                                                    -3.38,
                                                    4.5
                                                },
                                                {
                                                    8.945,
                                                    -21.1563,
                                                    4.5
                                                },
                                                {
                                                    -17.76,
                                                    -32.37,
                                                    4.5
                                                }
                                            }
                                        },
                                        pois = {
                                            {
                                                label = "down",
                                                pos = {
                                                    -5.973,
                                                    -10.711,
                                                    0.67
                                                }
                                            },
                                            {
                                                label = "down",
                                                pos = {
                                                    8.264,
                                                    -12.058,
                                                    0.67
                                                }
                                            }
                                        },
                                        settings = {
                                            near = 5.7
                                        }
                                    },
                                    saltz = {
                                        name = "saltz",
                                        check = {
                                            type = "below",
                                            height = 0.48
                                        },
                                        masks = dofile("scripts/mods/minimap/inn_level_saltz_masks"),
                                        pois = {
                                            {
                                                label = "up",
                                                pos = {
                                                    -7.098,
                                                    -10.36,
                                                    -0.7
                                                }
                                            },
                                            {
                                                label = "up",
                                                pos = {
                                                    7.628,
                                                    -11.752,
                                                    -0.7
                                                }
                                            },
                                            {
                                                label = "up",
                                                pos = {
                                                    -4.484,
                                                    12.854,
                                                    0.02
                                                }
                                            }
                                        },
                                        settings = {
                                            near = 0.48,
                                            far = 5000
                                        }
                                    }
                                },
                                settings = {
                                    near = 5.7
                                }
                            },
                            forge = {
                                name = "forge",
                                check = {
                                    type = "polygon",
                                    features = {
                                        {
                                            -21.351,
                                            -7.934,
                                            4.5
                                        },
                                        {
                                            -0.833,
                                            -3.38,
                                            4.5
                                        },
                                        {
                                            8.945,
                                            -21.1563,
                                            4.5
                                        },
                                        {
                                            -17.76,
                                            -32.37,
                                            4.5
                                        }
                                    }
                                },
                                pois = {
                                    {
                                        label = "down",
                                        pos = {
                                            -5.973,
                                            -10.711,
                                            0.67
                                        }
                                    },
                                    {
                                        label = "down",
                                        pos = {
                                            8.264,
                                            -12.058,
                                            0.67
                                        }
                                    }
                                },
                                settings = {
                                    near = 9.1
                                }
                            },
                            bridge = {
                                name = "bridge",
                                check = {
                                    type = "polygon",
                                    features = {
                                        {
                                            10.593,
                                            9.931,
                                            0
                                        },
                                        {
                                            32.445,
                                            10.227,
                                            0
                                        },
                                        {
                                            34.223,
                                            -20.402,
                                            0
                                        },
                                        {
                                            7.852,
                                            -18.328,
                                            0
                                        }
                                    }
                                },
                                settings = {
                                    near = 6
                                }
                            }
                        }
                    },
                    above_olesya = {
                        name = "above_olesya",
                        check = {
                            type = "above",
                            height = 7.6
                        },
                        settings = {
                            near = 9.2
                        }
                    },
                    sienna = {
                        name = "sienna",
                        check = {
                            type = "above",
                            height = 10
                        },
                        settings = {
                            near = 14
                        },
                        children = {
                            trophy_level = {
                                name = "trophy_level",
                                check = {
                                    type = "above",
                                    height = 12
                                },
                                children = {
                                    trophy_room = {
                                        name = "trophy_room",
                                        check = {
                                            type = "polygon",
                                            features = {
                                                {
                                                    18.474,
                                                    -13.288,
                                                    0
                                                },
                                                {
                                                    21.569,
                                                    -10.719,
                                                    0
                                                },
                                                {
                                                    28.069,
                                                    -8.579,
                                                    0
                                                },
                                                {
                                                    28.014,
                                                    3.28,
                                                    0
                                                },
                                                {
                                                    13.514,
                                                    3.087,
                                                    0
                                                },
                                                {
                                                    13.45,
                                                    -8.57,
                                                    0
                                                }
                                            }
                                        },
                                        settings = {
                                            near = 15.5
                                        }
                                    }
                                }
                            },
                            toilet = {
                                name = "toilet",
                                check = {
                                    type = "above",
                                    height = 18
                                },
                                settings = {
                                    near = 23
                                }
                            }
                        }
                    }
                }
            },
            kerrilian = {
                name = "kerrilian",
                check = {
                    type = "polygon",
                    features = {
                        {
                            -31.7,
                            15.44,
                            13.64
                        },
                        {
                            -33,
                            18.4088,
                            13.64
                        },
                        {
                            -30.74,
                            19.8321,
                            13.64
                        },
                        {
                            -29.1,
                            18.44,
                            13.64
                        },
                        {
                            -28.366,
                            17.47,
                            13.64
                        },
                        {
                            -28.8,
                            16.3,
                            13.64
                        },
                        {
                            -31.1,
                            15.42,
                            13.64
                        }
                    }
                },
                settings = {
                    area = 4,
                    near = 14.6
                }
            }
        },
        settings = inn_default
    },
    fort = {
        name = "fort",
        children = {
            start = {
                name = "start",
                check = {
                    type = "polygon",
                    features = {
                        {
                            -14.1387,
                            28.1612,
                            12
                        },
                        {
                            -18.8,
                            41.6764,
                            12
                        },
                        {
                            -11.9466,
                            44.2933,
                            12
                        },
                        {
                            -6.77303,
                            31.1788,
                            12
                        }
                    }
                },
                settings = {
                    area = 8,
                    near = 13.52
                },
                children = {
                    farm_top_of_roof = {
                        name = "farm_top_of_roof",
                        check = {
                            type = "above",
                            height = 13
                        },
                        settings = inn_default
                    }
                }
            }
        },
        settings = {
            area = 14,
            near = 2,
            far = 400,
            height = 400
        }
    },
    farmlands = {
        name = "farmlands",
        children = {
            open = {
                name = "open",
                check = {
                    type = "above",
                    height = 0
                },
                settings = {
                    area = 12,
                    near = 17,
                    far = 400,
                    height = 400
                }
            },
            mill_knopfelspiel = {
                name = "mill_knopfelspiel",
                check = {
                    type = "polygon",
                    features = {
                        {
                            176.259,
                            -179.312,
                            0
                        },
                        {
                            176.259,
                            -174.405,
                            0
                        },
                        {
                            180.751,
                            -166.477,
                            0
                        },
                        {
                            183.513,
                            -161.789,
                            0
                        },
                        {
                            189.159,
                            -149.393,
                            0
                        },
                        {
                            208.215,
                            -137.004,
                            0
                        },
                        {
                            230.008,
                            -166.358,
                            0
                        },
                        {
                            219.813,
                            -184.887,
                            0
                        },
                        {
                            206.554,
                            -194.951,
                            0
                        },
                        {
                            202.81,
                            -198.746,
                            0
                        },
                        {
                            178.238,
                            -188.466,
                            0
                        }
                    }
                },
                settings = {
                    near = 15
                },
                children = {
                    tome = {
                        name = "tome",
                        check = {
                            type = "above",
                            height = 6.5
                        },
                        settings = {
                            near = 20
                        }
                    },
                    cheese = {
                        name = "cheese",
                        check = {
                            type = "polygon",
                            features = {
                                {
                                    195.342,
                                    -145.257,
                                    0
                                },
                                {
                                    212.509,
                                    -148.979,
                                    0
                                },
                                {
                                    205.731,
                                    -136.923,
                                    0
                                }
                            }
                        },
                        masks = dofile("scripts/mods/minimap/farmlands_cheese_masks"),
                        settings = {
                            near = 7.8,
                            area = 5
                        }

                    },
                    stable = {
                        name = "stable",
                        check = {
                            type = "polygon",
                            features = {
                                {
                                    212.222,
                                    -180.316,
                                    0
                                },
                                {
                                    218.957,
                                    -169.426,
                                    0
                                },
                                {
                                    194.202,
                                    -155.593,
                                    0
                                },
                                {
                                    187.813,
                                    -166.482,
                                    0
                                }
                            }
                        },
                        masks = dofile("scripts/mods/minimap/farmlands_mill_knopfelspiel_masks"),
                        settings = {
                            near = 8.5,
                            area = 8
                        }

                    },
                    waggon = {
                        name = "waggon",
                        check = {
                            type = "polygon",
                            features = {
                                {
                                    180.787,
                                    -178.082,
                                    0
                                },
                                {
                                    180.916,
                                    -174.238,
                                    0
                                },
                                {
                                    176.128,
                                    -174.438,
                                    0
                                },
                                {
                                    176.136,
                                    -177.966,
                                    0
                                }
                            }
                        },
                        settings = {
                            near = 12,
                            area = 10
                        }
                    }
                }
            }
        },
        settings = {
            area = 12,
            near = 17,
            far = 400,
            height = 400
        }
    }
}
return level_data
