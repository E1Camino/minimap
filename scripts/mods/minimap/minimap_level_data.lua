local randomGreenBlueishColor = function()
    return Color(255, math.random(1, 40), math.random(1, 255), math.random(1, 255))
end

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
                            6.2
                        },
                        {
                            -24.247,
                            3.5,
                            6.2
                        },
                        {
                            -13.6,
                            4.6,
                            6.2
                        },
                        {
                            -11.648,
                            9.667,
                            6.2
                        },
                        {
                            -6.074,
                            14.904,
                            6.2
                        },
                        {
                            6.295,
                            15.165,
                            6.2
                        },
                        {
                            15.056,
                            6.571,
                            6.2
                        },
                        {
                            18.428,
                            6.627,
                            6.2
                        },
                        {
                            18.46,
                            4.897,
                            6.2
                        },
                        {
                            30.34,
                            4.541,
                            6.2
                        },
                        {
                            30.742,
                            -8.488,
                            6.2
                        },
                        {
                            15.6,
                            -23.559,
                            6.2
                        },
                        {
                            6.247,
                            -14.257,
                            6.2
                        }
                    }
                },
                settings = {
                    near = 10,
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
                        settings = {
                            near = 21,
                            area = 11
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
        settings = {
            near = 100,
            far = 10000,
            height = 2000,
            area = 12
        }
    }
}
return level_data
