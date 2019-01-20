local randomGreenBlueishColor = function()
    return Color(255, math.random(1, 40), math.random(1, 255), math.random(1, 255))
end

local level_data = {
    inn_level = {
        --[[ farm = {
            points = {
                {
                    2,
                    1,
                    12
                },
                {
                    4,
                    2,
                    12
                },
                {
                    3,
                    4,
                    12
                },
                {
                    1,
                    3,
                    12
                }
            }
        }, ]]
        farm = {
            points = {
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
            },
            near = 4,
            area = 8,
            color = randomGreenBlueishColor
        },
        ammo = {
            points = {
                {
                    -24.7287,
                    36.3511,
                    13.64
                },
                {
                    -21.8878,
                    37.6266,
                    13.64
                },
                {
                    -22.1356,
                    40.6763,
                    13.64
                },
                {
                    -24.5011,
                    37.9419,
                    13.64
                }
            },
            near = 8,
            color = randomGreenBlueishColor
        },
        near = 200,
        far = 10000,
        height = 2000,
        area = 12
    }
}
return level_data
