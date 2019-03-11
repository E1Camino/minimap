local mod = get_mod("minimap")
local SIZE_X = 1920
local SIZE_Y = 1080
local scenegraph_definition = {
    screen = {
        scale = "fit",
        position = {
            0,
            0,
            UILayer.hud
        },
        size = {
            SIZE_X,
            SIZE_Y
        },
        is_root = true
    },
    viewport = {
        scale = "fit",
        size = {
            500,
            500
        },
        position = {
            20,
            20,
            20
        }
    },
    title_text = {
        vertical_alignment = "center",
        parent = "viewport",
        horizontal_alignment = "center",
        position = {
            0,
            200,
            UILayer.hud + 1
        },
        size = {
            SIZE_X,
            50
        }
    }
}
local text_style = {
    word_wrap = false,
    font_size = 52,
    localize = true,
    use_shadow = true,
    horizontal_alignment = "center",
    vertical_alignment = "top",
    font_type = "hell_shark_header",
    text_color = Colors.get_color_table_with_alpha("white", 0),
    default_text_color = Colors.get_color_table_with_alpha("white", 0),
    offset = {
        0,
        0,
        1
    }
}

local title_text_style = {
    vertical_alignment = "center",
    font_size = 36,
    localize = false,
    horizontal_alignment = "center",
    word_wrap = true,
    font_type = "hell_shark_header",
    text_color = Colors.get_color_table_with_alpha("white", 255),
    offset = {
        0,
        0,
        2
    }
}
local widgets_definitions = {
    viewport = {
        scenegraph_id = "viewport",
        element = {
            passes = {
                {
                    style_id = "map_viewport",
                    pass_type = "map_viewport",
                    content_id = "map_viewport"
                }
            }
        },
        style = {
            map_viewport = {
                scenegraph_id = "viewport",
                viewport_name = "minimap_viewport",
                level_name = "levels/ui_character_selection/world",
                enable_sub_gui = true,
                fov = 50,
                world_name = "minimap_world",
                world_flags = {
                    Application.DISABLE_SOUND,
                    Application.DISABLE_ESRAM,
                    Application.ENABLE_VOLUMETRICS
                },
                no_scaling = "true",
                avoid_shading_callback = "true",
                layer = UILayer.default + 10,
                camera_position = {
                    0,
                    0,
                    0
                },
                camera_lookat = {
                    0,
                    0,
                    -1
                }
            },
            shading_environment = {
                fog_enabled = 0,
                dof_enabled = 0,
                motion_blur_enabled = 0,
                outline_enabled = 0,
                ssm_enabled = 1,
                ssm_constant_update_enabled = 1
            }
        },
        content = {}
    },
    title_text = UIWidgets.create_simple_text("n/a", "title_text", nil, nil, title_text_style)
}

Map = class(Map)
Map.init = function(self, app)
    self.app = app

    self.definitions = {}
    self.definitions.scenegraph = table.clone(scenegraph_definition)
    self.definitions.widgets = table.clone(widgets_definitions)

    self.width = 500
    self.height = 1056
    self.min_width = 300
    self.min_height = 500
    self.border = 12
    self.align = "right"

    self._current_settings = {
        height = mod:get("height"),
        near = mod:get("near"),
        far = mod:get("far"),
        area = mod:get("area")
    }

    self._scroll_factor = 1
end

Map.update = function(self, dt)
    self:update_keybindings(dt)
    if self.camera then
        self:syncCam()
    end
end

Map.syncCam = function(self, dt)
    local local_player_unit = Managers.player:local_player().player_unit
    if not local_player_unit then
        return
    end
    local player_position = Unit.local_position(local_player_unit, 0)

    local camera_position_new = Vector3.zero()
    camera_position_new.x = player_position.x
    camera_position_new.y = player_position.y -- sync position with player character

    local viewport_name = "player_1"
    local original_camera = self:_get_viewport_cam(viewport_name)
    if not original_camera then
        return
    end
    local original_camera_position = ScriptCamera.position(original_camera)
    ScriptCamera.set_local_position(self.camera, original_camera_position)

    local cameraHeight = self._current_settings.height
    local far = self._current_settings.far
    local near = self._current_settings.near

    camera_position_new.z = cameraHeight
    local direction = Vector3.normalize(Vector3(0, 0, -1))
    local rotation = Quaternion.look(direction)

    ScriptCamera.set_local_position(self.camera, camera_position_new)
    ScriptCamera.set_local_rotation(self.camera, rotation)
    -- ScriptCamera.set_local_position(self.shadow_cull_camera, camera_position_new)
    -- ScriptCamera.set_local_rotation(self.shadow_cull_camera, rotation)

    Camera.set_projection_type(self.camera, Camera.ORTHOGRAPHIC)
    --    Camera.set_projection_type(self.shadow_cull_camera, Camera.ORTHOGRAPHIC)

    local cfar = cameraHeight + far
    local cnear = cameraHeight - near
    Camera.set_far_range(self.camera, cfar)
    Camera.set_near_range(self.camera, cnear)
    -- Camera.set_far_range(self.shadow_cull_camera, cfar)
    -- Camera.set_near_range(self.shadow_cull_camera, cnear)

    local scroll = math.min(math.max(0.2, self._scroll_factor), 10.0) -- at least 1/5 of setting and max 10x setting
    local min = self._current_settings.area * -1 * scroll
    local max = self._current_settings.area * scroll
    Camera.set_orthographic_view(self.camera, min, max, min, max)
    -- Camera.set_orthographic_view(self.shadow_cull_camera, min, max, min, max)

    local s = mod:get("size") / 100
    local xmin = 1 - s
    Viewport.set_data(
        self.viewport,
        "rect",
        {
            xmin,
            0,
            s,
            s
        }
    )
    Viewport.set_rect(self.viewport, unpack(Viewport.get_data(self.viewport, "rect")))

    local shading_env = World.get_data(self.world, "shading_environment")
    ShadingEnvironment.set_scalar(shading_env, "fog_enabled", 0)
    ShadingEnvironment.set_scalar(shading_env, "dof_enabled", 0)
    ShadingEnvironment.set_scalar(shading_env, "motion_bur_enabled", 0)
    ShadingEnvironment.set_scalar(shading_env, "outline_enabled", 0)
    --		ShadingEnvironment.set_scalar(shading_env, "sun_shadows_enabled", 0)
    ShadingEnvironment.set_scalar(shading_env, "ssm_enabled", 1)
    ShadingEnvironment.set_scalar(shading_env, "ssm_constant_update_enabled", 1)
    ShadingEnvironment.apply(shading_env)
end

Map._get_viewport_cam = function(self, viewport_name)
    local world = self.world
    local o_viewport = ScriptWorld.viewport(world, viewport_name)

    return ScriptViewport.camera(o_viewport)
end

Map._update_resize = function(self, dt)
    if self._resize then
        -- Get cursor position
        local cursor_id = Mouse.axis_id("cursor")
        local cursor_pos = Mouse.axis(cursor_id)

        -- calculate new size
        local change = self._resize.cursor:unbox() - cursor_pos
        local new_size = self._resize.window:unbox() - change

        -- Fix
        if self.align == "right" then
            new_size.x = new_size.x + change.x + change.x
        end

        -- Update
        self:setWidth(new_size.x)
        self:setHeight(new_size.y)
    end

    if Mouse.released(Mouse.button_id("left")) then
        self._resize = nil
    end
end

Map.update_keybindings = function(self, dt)
    local input_service = self.input_service
    if input_service then
        local left_mouse_hold = input_service:get("left_hold")
        local scroll_wheel = input_service:get("scroll_axis")
        local shift_hold = input_service:get("shift_hold")
        local s = Vector3.y(scroll_wheel)
        local mouse_wheel = tonumber(s)

        if shift_hold then
            local n = self._current_settings.near + mouse_wheel / 10 * -1
            self._current_settings.near = n
        else
            local n = self._scroll_factor + mouse_wheel / 100 * -1
            self._scroll_factor = math.min(math.max(0.2, n), 10.0) -- at least 1/5 of setting and max 10x setting
        end
    end
end

Map.setWidth = function(self, width)
    local max_width = 1920 - self.border - self.border
    if max_width >= width then
        if width >= self.min_width then
            self.width = width
        else
            self.width = self.min_width
        end
    else
        self.width = max_width
    end

    self.app:create_ui_elements()
end

Map.getWidth = function(self)
    return self.width
end

Map.setHeight = function(self, height)
    local max_height = 1080 - self.border - self.border
    if max_height >= height then
        if height >= self.min_height then
            self.height = height
        else
            self.height = self.min_height
        end
    else
        self.height = max_height
    end

    self.app:create_ui_elements()
end

Map.getHeight = function(self)
    return self.height
end

Map.getBorder = function(self)
    return self.border
end

Map.setAlign = function(self, option)
    -- Set new alignement
    if option then
        self.align = option
    else
        -- If no option was given do the inverse
        if self.align == "left" then
            self.align = "right"
        else
            self.align = "left"
        end
    end

    self.app:create_ui_elements()
end

Map.patch = function(self)
    self.definitions.scenegraph = table.clone(scenegraph_definition)
    self.definitions.widgets = table.clone(widgets_definitions)

    -- push changes to the app
    self.app:updateScreneGraph("map")
    self.app:updateWidgets("map")
end

Map.cb_local_offset = function(self, name, ui_scenegraph, style, content, ui_renderer) -- --if content.top_hotspot.on_release then
    -- Debug
    --[[
	for key, value in pairs(content.top_hotspot) do
		self:echo(tostring(key) .. " = " .. tostring(value))
	end
    ]]
    if content.top_hotspot.cursor_hover then
        if Mouse.pressed(Mouse.button_id("left")) then
            if self._resize == nil then
                local cursor_id = Mouse.axis_id("cursor")
                local cursor_pos = Mouse.axis(cursor_id)

                -- Save start state
                self._resize = {
                    cursor = Vector3Box(cursor_pos),
                    window = Vector3Box(self.width, self.height, 0)
                }
            end
        end
    end

    if content.top_hotspot.on_release then
        self._resize = nil
    end
end
