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
        }
    },
    -- minimap_life_view = {
    --     scale = "fit",
    --     size = {
    --         1920,
    --         1080
    --     },
    --     position = {
    --         0,
    --         0,
    --         0
    --     }
    -- },
    title_text = {
        vertical_alignment = "center",
        parent = "screen",
        horizontal_alignment = "center",
        position = {
            0,
            200,
            100
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
-- local widget_definitions = {
--     area_text_box = UIWidgets.create_simple_text("placeholder_area_text", "area_text_box", nil, nil, text_style)
-- }
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
    minimap_life_view = {
        scenegraph_id = "minimap_life_view",
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
                scenegraph_id = "minimap_life_view",
                viewport_name = "minimap_viewport",
                level_name = "levels/ui_character_selection/world",
                enable_sub_gui = false,
                fov = 50,
                world_name = "minimap_world",
                world_flags = {
                    Application.DISABLE_SOUND,
                    Application.DISABLE_ESRAM,
                    Application.ENABLE_VOLUMETRICS
                },
                layer = UILayer.default - 10,
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
end

Map.update = function(self, dt)
    self:update_keybindings(dt)
    self:_update_resize(dt)
end

Map._get_viewport_cam = function(viewport_name)
    local world = mod.world
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
    local ctrl_id = Keyboard.button_id("left ctrl")
    if Keyboard.released(ctrl_id) then
        self.ctrl_pressed = false
    end
    if Keyboard.pressed(ctrl_id) then
        self.ctrl_pressed = true
    end

    if self.ctrl_pressed and Keyboard.pressed(Keyboard.button_id("a")) then
        self:setAlign()
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
		mod:echo(tostring(key) .. " = " .. tostring(value))
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
