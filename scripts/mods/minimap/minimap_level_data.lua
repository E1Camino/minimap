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
                            -6.074,
                            14.904,
                            0
                        },
                        {
                            6.295,
                            15.165,
                            0
                        },
                        {
                            15.056,
                            6.571,
                            0
                        },
                        {
                            18.428,
                            6.627,
                            0
                        },
                        {
                            18.46,
                            4.897,
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
                            near = 10.8
                        }
                    },
                    saltz = {
                        name = "saltz",
                        check = {
                            type = "below",
                            height = 2
                        },
                        masks = dofile("scripts/mods/minimap/inn_level_saltz_masks"),
                        settings = {
                            near = 0.48,
                            far = 5000
                        }
                    },
                    sienna = {
                        name = "sienna",
                        check = {
                            type = "polygon",
                            features = {
                                {
                                    8.85047,
                                    -3.24998,
                                    10
                                }
                            }
                        },
                        settings = {
                            near = 20
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
    }
}
return level_data
