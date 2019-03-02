local mod = get_mod("minimap")
mod:dofile("scripts/mods/minimap/app/App")

mod.update = function(dt)
end

mod.on_unload = function(exit_game)
end

mod.on_game_state_changed = function(status, state)
end

mod.on_setting_changed = function(setting_name)
end

mod.on_disabled = function(is_first_call)
end

mod.on_enabled = function(is_first_call)
end

mod.btn_active_mouse = function()
end

mod.app = Minimap:new()

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
