local mod = get_mod("minimap")
mod:dofile("scripts/mods/minimap/app/App")

mod.update = function(dt)
end

mod.on_unload = function(exit_game)
    mod.app.destroy()
end

mod.on_game_state_changed = function(status, state)
end

mod.on_setting_changed = function(setting_name)
end

mod.on_disabled = function(is_first_call)
    mod.app.destroy()
end

mod.on_enabled = function(is_first_call)
end

mod.btn_active_mouse = function()
end

mod.app = Minimap:new()

-- just do it
UIPasses.map_viewport = {
    init = function(pass_definition, content, style)
        local style = style[pass_definition.style_id]
        local content = content[pass_definition.content_id]
        local world_flags = style.world_flags
        if not world_flags then
            world_flags = {
                Application.DISABLE_SOUND,
                Application.DISABLE_ESRAM
            }
        else
        end
        --        local world = Managers.world:world(style.world_name)
        local status, world = pcall(Managers.world:world("level_world"))
        if not status then
            world = Managers.world:world("level_world")
        else
            local shading_environment = style.shading_environment
            world =
                Managers.world:create_world(
                style.world_name,
                shading_environment,
                nil,
                style.layer,
                unpack(world_flags)
            )
        end

        local viewport_type = style.viewport_type or "default"
        local viewport = ScriptWorld.create_viewport(world, style.viewport_name, viewport_type, style.layer)
        local level_name = style.level_name
        local object_sets = style.object_sets
        local level = nil

        if style.clear_screen_on_create then
        else
            Viewport.set_data(viewport, "initialize", true)
        end

        local deactivated = true

        ScriptWorld.deactivate_viewport(world, viewport)

        local camera_pos = Vector3Aux.unbox(style.camera_position)
        local camera_lookat = Vector3Aux.unbox(style.camera_lookat)
        local camera_direction = Vector3.normalize(camera_lookat - camera_pos)
        local camera = ScriptViewport.camera(viewport)

        ScriptCamera.set_local_position(camera, camera_pos)
        ScriptCamera.set_local_rotation(camera, Quaternion.look(Vector3(0, 0, -1)))

        local ui_renderer = nil

        mod.app.map.world = world
        mod.app.map.camera = camera
        mod.app.map.viewport = viewport

        if style.enable_sub_gui then
            ui_renderer =
                UIRenderer.create(
                world,
                "material",
                "materials/ui/ui_1080p_hud_atlas_textures",
                "material",
                "materials/ui/ui_1080p_hud_single_textures",
                "material",
                "materials/ui/ui_1080p_menu_atlas_textures",
                "material",
                "materials/ui/ui_1080p_menu_single_textures",
                "material",
                "materials/ui/ui_1080p_common",
                "material",
                "materials/ui/ui_1080p_popup",
                "material",
                "materials/fonts/gw_fonts"
            )
        end

        return {
            deactivated = deactivated,
            world = world,
            world_name = style.world_name,
            level = level,
            viewport = viewport,
            viewport_name = style.viewport_name,
            ui_renderer = ui_renderer,
            camera = camera
        }
    end,
    destroy = function(ui_renderer, pass_data, pass_definition)
        if pass_data.ui_renderer then
            UIRenderer.destroy(pass_data.ui_renderer, pass_data.world)
        end

        ScriptWorld.destroy_viewport(pass_data.world, pass_data.viewport_name)
        mod.app.map.viewport = nil

        --Managers.world:destroy_world(pass_data.world)
        mod.app.map.world = nil
        mod.app.map.camera = nil
    end,
    draw = function(
        ui_renderer,
        pass_data,
        ui_scenegraph,
        pass_definition,
        ui_style,
        ui_content,
        position,
        size,
        input_service,
        dt)
        local scaled_position = UIScaleVectorToResolution(position)
        local scaled_size = UIScaleVectorToResolution(size)
        local resx = RESOLUTION_LOOKUP.res_w
        local resy = RESOLUTION_LOOKUP.res_h
        local viewport_size = Vector3.zero()
        viewport_size.x = math.clamp(scaled_size.x / resx, 0, 1)
        viewport_size.y = math.clamp(scaled_size.y / resy, 0, 1)
        local viewport_position = Vector3.zero()
        viewport_position.x = math.clamp(scaled_position.x / resx, 0, 1)
        viewport_position.y = math.clamp(1 - scaled_position.y / resy - viewport_size.y, 0, 1)
        local viewport = pass_data.viewport
        local world = pass_data.world

        if pass_data.deactivated then
            ScriptWorld.activate_viewport(world, viewport)

            pass_data.deactivated = false
        end

        if Viewport.get_data(viewport, "initialize") then
            Viewport.set_data(viewport, "initialize", false)
            Viewport.set_rect(viewport, 0, 0, 0.5, 0.5)
        else
            local splitscreen = false

            if Managers.splitscreen then
                splitscreen = Managers.splitscreen:active()
            end

            local size = mod:get("size") / 100
            local multiplier = 1 - size

            --Viewport.set_rect(viewport, size, size, multiplier, multiplier)
            --Viewport.set_rect(viewport, unpack(Viewport.get_data(viewport, "rect")))
            Viewport.set_rect(viewport, 0.05, 0.05, 0.9, 0.9)
            pass_data.viewport_rect_pos_x = viewport_position.x
            pass_data.viewport_rect_pos_y = viewport_position.y
            pass_data.viewport_rect_size_x = scaled_size.x
            pass_data.viewport_rect_size_y = scaled_size.y
            pass_data.size_scale_x = viewport_size.x
            pass_data.size_scale_y = viewport_size.y
        end
    end,
    raycast_at_screen_position = function(pass_data, screen_position, result_type, range, collision_filter)
        if pass_data.viewport_rect_pos_x == nil then
            return nil
        end

        local resx = RESOLUTION_LOOKUP.res_w
        local resy = RESOLUTION_LOOKUP.res_h
        local camera_space_position = Vector3.zero()
        local aspect_ratio = resx / resy
        local default_aspect = 1.7777777777777777

        if aspect_ratio < default_aspect then
            local scale_x = screen_position.x / resx
            local width = resy / 9 * 16
            camera_space_position.x = resx * 0.5 - width * 0.5 + width * scale_x
            local scale_y = screen_position.y / resy
            local height = pass_data.size_scale_x * resy
            camera_space_position.y = resy * 0.5 - height * 0.5 + height * scale_y
        elseif default_aspect < aspect_ratio then
            local scale_x = screen_position.x / resx
            local width = pass_data.size_scale_y * resx
            camera_space_position.x = resx * 0.5 - width * 0.5 + width * scale_x
            camera_space_position.y = screen_position.y
        else
            camera_space_position.x = screen_position.x
            camera_space_position.y = screen_position.y
        end

        local position = Camera.screen_to_world(pass_data.camera, camera_space_position, 0)
        local direction =
            Camera.screen_to_world(pass_data.camera, camera_space_position + Vector3(0, 0, 0), 1) - position
        local raycast_dir = Vector3.normalize(direction)
        local physics_world = World.get_data(pass_data.world, "physics_world")

        return PhysicsWorld.immediate_raycast(
            physics_world,
            position,
            raycast_dir,
            range,
            result_type,
            "collision_filter",
            collision_filter
        )
    end
}

mod:register_view(
    {
        view_name = "minimap_view",
        view_settings = {
            init_view_function = function(ingame_ui_context)
                mod.app:setIngameUI(ingame_ui_context)
                return mod.app
            end,
            active = {
                inn = true,
                ingame = true
            }
        },
        view_transitions = {
            minimap_view_open = function(self)
                self.current_view = "minimap_view"
                self.menu_active = true
            end,
            minimap_view_close = function(self)
                self.menu_active = false
                self.current_view = nil
            end
        }
    }
)

mod.setProps = function(key, value)
    local map = mod.app.map
    if not map then
        return
    end
    if value == "" then
        mod:echo("no value given")
        return
    end

    if key == "area" or key == "size" or key == "near" or key == "far" or key == "height" then
        map._current_settings[key] = value
        mod:set(key, value)
    else
        mod:echo(key .. " is not a supported")
    end
end

mod:command("map_set", "Sets specific values for Minimap", mod.setProps)
