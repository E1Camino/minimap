local mod = get_mod("minimap")
--

mod:dofile("scripts/mods/minimap/app/Map")
local text_definitions = local_require("scripts/ui/views/area_indicator_ui_definitions")
--mod:dofile("scripts/mods/DebugMenu/Class/List")

local scenegraph_definition = {
    sg_root = {
        size = {1920, 1080},
        position = {0, 0, UILayer.default + 10},
        is_root = true
    }
}

Minimap = class(Minimap)

Minimap._get_default_settings = function(self)
    return {
        height = mod:get("height"),
        near = mod:get("near"),
        far = mod:get("far"),
        area = mod:get("area")
    }
end

Minimap.init = function(self, ingame_ui_context)
    self.map = Map:new(self)
    self.suspended = true

    self.first = false
    self.viewport = nil
    self.camera = nil
    self.active = false
    self.offset_speed = 0.1
    self.currentProp = 1
    self.propsForToggle = {"near", "far", "area"}
    self.viewports_widget = nil

    self._interactive_mask_mode = false
    self._interactive_mask_multi_triangle = false

    self._current_settings = self:_get_default_settings()
    self._set_props = {}
    self._current_location_inside = nil
    self._prev_location_inside = nil
    self._highlighted_location_inside = nil

    self._current_debug_text = ""
    self._printed_debug_text = ""

    self.camera_positions = {}
    self.current_camera_index = nil
    self._mask_triangles = {}
    self._new_triangles = {}
    self._new_triangle = {}
    self._ref_point = nil
    self._current_location = ""
    self._scroll_factor = 1
    self._pickup_overlay_hooked = false

    self._area_from = nil
    self._area_to = nil
    self._area_t = nil
    self._progressed_time = 0
    self._duration = 0.4
    self._cursor = false
end

Minimap.setIngameUI = function(self, ingame_ui_context)
    self.definitions = {}
    self.definitions.scenegraph = scenegraph_definition
    self.definitions.widgets = {}

    -- get necessary things for the rendering
    self.render_settings = {snap_pixel_positions = true}
    self.world = ingame_ui_context.world
    self.player_manager = ingame_ui_context.player_manager
    self.ui_renderer = ingame_ui_context.ui_renderer
    self.ui_top_renderer = ingame_ui_context.ui_top_renderer
    self.ingame_ui = ingame_ui_context.ingame_ui
    self.world_manager = ingame_ui_context.world_manager

    -- create the input service
    self.input_manager = ingame_ui_context.input_manager
    self.input_manager:create_input_service("mod_minimap", "IngameMenuKeymaps", "IngameMenuFilters")
    self.input_manager:map_device_to_service("mod_minimap", "keyboard")
    self.input_manager:map_device_to_service("mod_minimap", "mouse")
    self.input_manager:map_device_to_service("mod_minimap", "gamepad")

    -- wwise_world is used for making sounds (for opening menu, closing menu, etc.)
    local world = ingame_ui_context.world_manager:world("level_world")
    self.wwise_world = Managers.world:wwise_world(world)

    self:create_ui_elements()
end

Minimap.updateScreneGraph = function(self, name)
    if self[name] then
        for key, value in pairs(self[name].definitions.scenegraph) do
            self.definitions.scenegraph[key] = value
        end
    end
end

Minimap.updateWidgets = function(self, object_name)
    -- Patch definitions
    if self[object_name] then
        for key, value in pairs(self[object_name].definitions.widgets) do
            self.definitions.widgets[key] = value
        end
    end
end

Minimap.create_ui_elements = function(self)
    self.definitions = {}
    self.definitions.scenegraph = scenegraph_definition
    self.definitions.widgets = {}

    self.map:patch()
    --self.list:patch()

    -- Create screnegraph
    self.ui_scenegraph = UISceneGraph.init_scenegraph(self.definitions.scenegraph)

    -- Create widgets
    self.widgets = {}
    for name, definition in pairs(self.definitions.widgets) do
        mod:echo(name)
        self.widgets[name] = UIWidget.init(definition)
    end
    self.widgets.title_text.content.text = "jo"
end

Minimap.update = function(self, dt)
    if self.suspended or self.waiting_for_post_update_enter then
        return
    end

    self.map:update(dt)
    self:draw_widgets(dt)
end

Minimap.draw_widgets = function(self, dt)
    local ui_renderer = self.ui_renderer
    local ui_scenegraph = self.ui_scenegraph
    local input_service = self:input_service()

    UIRenderer.begin_pass(ui_renderer, ui_scenegraph, input_service, dt, nil, self.render_settings)

    for _, widget in pairs(self.widgets) do
        UIRenderer.draw_widget(ui_renderer, widget)
    end

    UIRenderer.end_pass(ui_renderer)
end

Minimap.on_enter = function(self)
    ShowCursorStack.push()
    local input_manager = self.input_manager
    input_manager:device_unblock_service("keyboard", 1, "mod_minimap")
    input_manager:device_unblock_service("mouse", 1, "mod_minimap")
    input_manager:device_unblock_service("gamepad", 1, "mod_minimap")

    WwiseWorld.trigger_event(self.wwise_world, "Play_hud_button_open")
    self.waiting_for_post_update_enter = true
end

Minimap.on_exit = function(self)
    WwiseWorld.trigger_event(self.wwise_world, "Play_hud_button_close")

    if ShowCursorStack.stack_depth > 0 then
        ShowCursorStack.pop()
    end

    local input_manager = self.input_manager
    input_manager:device_unblock_all_services("keyboard", 1)
    input_manager:device_unblock_all_services("mouse", 1)
    input_manager:device_unblock_all_services("gamepad", 1)
end

Minimap.post_update_on_enter = function(self)
    assert(self.viewport_widget == nil)
    --self.viewport_widget = UIWidget.init(self.definitions.widgets.viewport)
    self.waiting_for_post_update_enter = nil
end

Minimap.post_update_on_exit = function(self)
    if self.viewport_widget then
    --UIWidget.destroy(self.ui_renderer, self.viewport_widget)
    --self.viewport_widget = nil
    end
end

Minimap.suspend = function(self)
    self.input_manager:device_unblock_all_services("keyboard", 1)
    self.input_manager:device_unblock_all_services("mouse", 1)
    self.input_manager:device_unblock_all_services("gamepad", 1)

    self.suspended = true
    local viewport_name = "player_1"
    local world = Managers.world:world("level_world")
    local viewport = ScriptWorld.viewport(world, viewport_name)

    ScriptWorld.activate_viewport(world, viewport)

    local previewer_pass_data = self.viewport_widget.element.pass_data[1]
    local viewport = previewer_pass_data.viewport
    local world = previewer_pass_data.world

    ScriptWorld.deactivate_viewport(world, viewport)
end

Minimap.unsuspend = function(self)
    self.input_manager:block_device_except_service("character_selection_view", "keyboard", 1)
    self.input_manager:block_device_except_service("character_selection_view", "mouse", 1)
    self.input_manager:block_device_except_service("character_selection_view", "gamepad", 1)

    self.suspended = nil

    if self.viewport_widget then
        local viewport_name = "player_1"
        local world = Managers.world:world("level_world")
        local viewport = ScriptWorld.viewport(world, viewport_name)

        ScriptWorld.deactivate_viewport(world, viewport)

        local previewer_pass_data = self.viewport_widget.element.pass_data[1]
        local viewport = previewer_pass_data.viewport
        local world = previewer_pass_data.world

        ScriptWorld.activate_viewport(world, viewport)
    end
end

Minimap.input_service = function(self)
    return self.input_manager:get_service("mod_minimap")
end

Minimap.destroy = function(self)
    if self.viewport_widget then
        UIWidget.destroy(self.ui_top_renderer, self.viewport_widget)

        self.viewport_widget = nil
    end

    self.ingame_ui_context = nil
    self.ui_animator = nil
    local viewport_name = "player_1"
    local world = Managers.world:world("level_world")
    local viewport = ScriptWorld.viewport(world, viewport_name)

    ScriptWorld.activate_viewport(world, viewport)
end
