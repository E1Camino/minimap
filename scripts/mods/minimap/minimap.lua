local mod = get_mod("minimap")

mod.first = false
mod.viewport = nil
mod.camera = nil
mod.active = false
mod.offset_speed = 0.1
mod.currentProp = 1
mod.propsForToggle = {"height", "near", "far", "size", "area"}
mod.viewports = nil
mod._get_default_settings = function(self)
	return {
		height = mod:get("height"),
		near = mod:get("near"),
		far = mod:get("far"),
		area = mod:get("area")
	}
end
mod._character_offset = 0
mod._current_settings = mod:_get_default_settings()
mod._current_poly_insight = nil

mod.camera_positions = {}
mod.current_camera_index = nil

mod.increaseProp = function()
	local p = mod.propsForToggle[mod.currentProp]
	local c = mod:get(p)
	mod:set(p, c + mod.offset_speed)
end
mod.decreaseProp = function()
	local p = mod.propsForToggle[mod.currentProp]
	local c = mod:get(p)
	mod:set(p, c - mod.offset_speed)
end
mod.increasePropSpeed = function()
	mod.offset_speed = mod.offset_speed + 0.1
end
mod.decreasePropSpeed = function()
	mod.offset_speed = mod.offset_speed - 0.1
end
mod.toggleProp = function()
	mod.currentProp = mod.currentProp + 1 % table.getn(mod.propsForToggle)
end

mod.print_live = function()
	mod.destroy_debug_lines()
	mod.create_debug_lines()
end

mod.print_debug = function(dt)
	if not mod.camera then
		mod:destroyViewport()
		mod:createViewport()
	end

	local viewport_name = "player_1"
	local world = Application.main_world()
	local o_viewport = ScriptWorld.viewport(world, viewport_name)
	local original_camera = ScriptViewport.camera(o_viewport)
	local original_camera_position = ScriptCamera.position(original_camera)
	mod:echo(original_camera_position)

	local oldRot = ScriptCamera.rotation(mod.camera)
	mod:echo(
		(mod.propsForToggle[mod.currentProp] == "near" and "*" or "") ..
			"near " .. mod:get("near") .. " " .. mod._current_settings.near
	)

	mod:echo(
		(mod.propsForToggle[mod.currentProp] == "far" and "*" or "") ..
			"far " .. mod:get("height") .. " " .. Camera.far_range(mod.camera)
	)
	mod:echo((mod.propsForToggle[mod.currentProp] == "height" and "*" or "") .. "height " .. mod:get("height"))
	mod:echo(
		(mod.propsForToggle[mod.currentProp] == "area" and "*" or "") ..
			"area " .. mod:get("area") .. " " .. mod._current_settings.area
	)
end

mod.create_debug_lines = function()
	local world = Application.main_world()
	if not world or not Managers.player then
		return
	end
	mod._debug_lines = World.create_line_object(world, true)

	-- player sphere
	local local_player_unit = Managers.player:local_player().player_unit
	local player_position = Unit.local_position(local_player_unit, 0)
	local z = player_position.z
	player_position.z = player_position.z + 2
	LineObject.add_sphere(mod._debug_lines, Color(255, 255, 255, 255), player_position, 0.05)

	-- player axes
	local player_pose = Unit.local_pose(local_player_unit, 0)
	LineObject.add_axes(mod._debug_lines, player_pose, 1)

	-- paint level setting polygons
	mod._create_debug_points()
	LineObject.dispatch(world, mod._debug_lines)
end
mod._create_debug_points = function(z)
	if not mod._level_settings then
		return
	end

	-- polygon iteration
	for poly_name in pairs(mod._level_settings) do
		local polygon = mod._level_settings[poly_name]
		local c = Color(255, 255, 255, 255)
		if poly_name == "near" or poly_name == "far" or poly_name == "area" or poly_name == "height" then
		else
			if poly_name.color then
				c = poly_name.color
			end
			-- highlight polygon that we are in^
			-- check if camera is inside poly
			local s = mod._level_settings[poly_name]
			if s.points then
				local pre = mod._pre_calc(poly_name)
				local prev = polygon.points[#polygon.points]

				--point iteration
				for si, point in pairs(polygon.points) do
					--					mod:echo(si)
					local c_p = Vector3.zero()
					c_p.x = point[1]
					c_p.y = point[2]
					c_p.z = z or point[3]
					local p_p = Vector3.zero()
					p_p.x = prev[1]
					p_p.y = prev[2]
					p_p.z = z or prev[3]
					prev = point
					if poly_name == mod._current_poly_insight then
						LineObject.add_line(mod._debug_lines, Color(255, 255, 0, 0), p_p, c_p)
						LineObject.add_sphere(mod._debug_lines, Color(255, 255, 0, 0), c_p, 0.05)
					elseif si == 1 then
						LineObject.add_line(mod._debug_lines, Color(255, 255, 255, 0), p_p, c_p)
						LineObject.add_sphere(mod._debug_lines, Color(255, 255, 255, 0), c_p, 0.05)
					else
						LineObject.add_line(mod._debug_lines, c, p_p, c_p)
						LineObject.add_sphere(mod._debug_lines, c, c_p, 0.05)
					end
				end
			end
		end
	end
end

mod.destroy_debug_lines = function()
	local world = Application.main_world()
	if not mod._debug_lines or not world then
		return
	end
	LineObject.reset(mod._debug_lines)
	LineObject.dispatch(world, mod._debug_lines)
	mod._debug_lines = nil
end

mod._get_viewport_cam = function(viewport_name)
	local world = Application.main_world()
	local o_viewport = ScriptWorld.viewport(world, viewport_name)

	return ScriptViewport.camera(o_viewport)
end

mod.syncCam = function(dt)
	local local_player_unit = Managers.player:local_player().player_unit
	local player_position = Unit.local_position(local_player_unit, 0)

	--ScriptCamera.set_local_position(mod.camera, player_position)

	local camera_position_new = Vector3.zero()
	camera_position_new.x = player_position.x
	camera_position_new.y = player_position.y -- sync position with player character

	local viewport_name = "player_1"
	local original_camera = mod._get_viewport_cam(viewport_name)
	if not original_camera then
		return
	end
	local original_camera_position = ScriptCamera.position(original_camera)
	ScriptCamera.set_local_position(mod.camera, original_camera_position)

	local cameraHeight = mod._current_settings.height
	local far = mod._current_settings.far
	local near = mod._current_settings.near

	if mod._character_offset == 0 then
		mod._character_offset = original_camera_position.z - player_position.z
	end

	camera_position_new.z = cameraHeight
	local direction = Vector3.normalize(Vector3(0, 0, -1))
	local rotation = Quaternion.look(direction)

	ScriptCamera.set_local_position(mod.camera, camera_position_new)
	ScriptCamera.set_local_rotation(mod.camera, rotation)
	ScriptCamera.set_local_position(mod.shadow_cull_camera, camera_position_new)
	ScriptCamera.set_local_rotation(mod.shadow_cull_camera, rotation)

	Camera.set_projection_type(mod.camera, Camera.ORTHOGRAPHIC)
	Camera.set_projection_type(mod.shadow_cull_camera, Camera.ORTHOGRAPHIC)

	local cfar = cameraHeight - player_position.z + mod._character_offset + far
	local cnear = cameraHeight - player_position.z + mod._character_offset - near
	Camera.set_far_range(mod.camera, cfar)
	Camera.set_near_range(mod.camera, cnear)
	Camera.set_far_range(mod.shadow_cull_camera, cfar)
	Camera.set_near_range(mod.shadow_cull_camera, cnear)

	local min = mod._current_settings.area * -1
	local max = mod._current_settings.area
	Camera.set_orthographic_view(mod.camera, min, max, min, max)
	Camera.set_orthographic_view(mod.shadow_cull_camera, min, max, min, max)

	local s = mod:get("size") / 100
	local xmin = 1 - s
	Viewport.set_data(
		mod.viewport,
		"rect",
		{
			xmin,
			0,
			s,
			s
		}
	)
	Viewport.set_rect(mod.viewport, unpack(Viewport.get_data(mod.viewport, "rect")))
end

mod.check_polygons = function(dt)
	if not mod._level_settings then
		return
	end

	local settings = mod:_get_default_settings()
	local overwrite_settings = table.clone(settings)
	local local_player_unit = Managers.player:local_player().player_unit
	local player_position = Unit.local_position(local_player_unit, 0)

	local setting_keys = {"near", "far", "area", "height"}
	local new_insight = ""

	for poly_name in pairs(mod._level_settings) do
		local polygon = mod._level_settings[poly_name]
		if poly_name == "near" or poly_name == "far" or poly_name == "area" or poly_name == "height" then
			-- level default settings (instead of general default settings)
			local new_setting = mod._level_settings[poly_name]
			if new_setting then
				overwrite_settings[poly_name] = new_setting
			end
		else
			-- check if camera is inside poly
			local pre = mod._pre_calc(poly_name)
			local inside = mod:is_point_in_polygon(player_position, polygon.points, pre)
			if inside then
				new_insight = poly_name
				for si, setting_key in pairs(setting_keys) do
					local new_setting = mod._level_settings[poly_name][setting_key]
					--					mod:echo("n " .. setting_key .. " " .. new_setting)
					if new_setting then
						overwrite_settings[setting_key] = new_setting
					end
				end
			end
		end
	end
	mod._current_poly_insight = new_insight
	mod._current_settings = overwrite_settings
end

mod.is_point_in_polygon = function(self, point, vertices, pre)
	if not pre.corners then
		return false
	end
	mod:dump(vertices, "vertices", 2)
	-- http://alienryderflex.com/polygon/
	local previous = pre.corners
	local polyX = pre.polyX
	local polyY = pre.polyY
	local x = point.x
	local y = point.y
	local oddNodes = false

	for current = 1, pre.corners do
		local betweenY = (polyY[current] < y and polyY[previous] >= y) or (polyY[previous] < y and polyY[current] >= y)

		if (betweenY) then
			local calc =
				polyX[current] + (y - polyY[current]) / (polyY[previous] - polyY[current]) * (polyX[previous] - polyX[current])
			if calc < x then
				if not oddNodes then
					oddNodes = true
				else
					oddNodes = false
				end
			end
		end
		j = i
	end
	return oddNodes
end

mod._pre_calc = function(polygon_name)
	-- http://alienryderflex.com/polygon/
	local s = mod._level_settings[polygon_name]

	-- only precalc once
	if s._pre then
		return s._pre
	end
	-- we need points to pre calc
	if not s.points or s._pre then
		return
	end

	local corners = #s.points
	local polyX = {}
	local polyY = {}
	local polyZ = {}

	for i, c in pairs(s.points) do
		polyX[i] = c[1]
		polyY[i] = c[2]
		polyZ[i] = c[3]
	end
	local constant = {}
	local multiple = {}

	local j = corners
	for i = 1, corners do
		if (polyY[j] == polyY[i]) then
			constant[i] = polyX[i]
			multiple[i] = 0
		else
			constant[i] =
				polyX[i] - (polyY[i] * polyX[j]) / (polyY[j] - polyY[i]) + (polyY[i] * polyX[i]) / (polyY[j] - polyY[i])
			multiple[i] = (polyX[j] - polyX[i]) / (polyY[j] - polyY[i])
			j = i
		end
	end
	local pre = {
		corners = corners,
		polyX = polyX,
		polyY = polyY,
		multiple = multiple,
		constant = constant,
		polyX = polyX,
		polyY = polyY
	}
	mod._level_settings[polygon_name]._pre = pre
	return pre
end

mod._get_level_settings = function(self)
	local level_transition_handler = Managers.state.game_mode.level_transition_handler
	local level_key = level_transition_handler:get_current_level_keys()
	return dofile("scripts/mods/minimap/minimap_level_data")[level_key]
end

mod.createViewport = function()
	local world = Application.main_world()
	mod.viewport = mod._create_minimap_viewport(world, "minimap", "default", 2)
	ScriptWorld.activate_viewport(world, mod.viewport)
	mod.active = true
end

mod.destroyViewport = function()
	local world = Application.main_world()
	ScriptWorld.destroy_viewport(world, "minimap")
	mod.viewport = nil
	mod.camera = nil
	mod.active = false
	mod._character_offset = 0
end

mod._create_minimap_viewport = function(
	world,
	name,
	template,
	layer,
	position,
	rotation,
	add_shadow_cull_camera,
	force_no_scaling)
	local viewports = World.get_data(world, "viewports")
	mod.world = world

	fassert(viewports[name] == nil, "Viewport %q already exists", name)

	local viewport = Application.create_viewport(world, template)

	Viewport.set_data(viewport, "layer", layer or 2)
	Viewport.set_data(viewport, "active", true)
	Viewport.set_data(viewport, "name", name)

	viewports[name] = viewport

	local splitscreen = Managers.splitscreen and Managers.splitscreen:active()

	Viewport.set_data(
		viewport,
		"rect",
		{
			0.5,
			0,
			0.5,
			0.5
		}
	)
	Viewport.set_data(viewport, "avoid_shading_callback", false)
	Viewport.set_data(viewport, "no_scaling", true)
	Viewport.set_rect(viewport, unpack(Viewport.get_data(viewport, "rect")))

	local camera_unit = nil

	if position and rotation then
		camera_unit = World.spawn_unit(world, "core/units/camera", position, rotation)
	elseif position then
		camera_unit = World.spawn_unit(world, "core/units/camera", position)
	else
		camera_unit = World.spawn_unit(world, "core/units/camera")
	end

	local camera = Unit.camera(camera_unit, "camera")
	Camera.set_data(camera, "unit", camera_unit)
	mod.camera = camera
	Viewport.set_data(viewport, "camera", camera)

	local shadow_cull_camera = Unit.camera(camera_unit, "shadow_cull_camera")
	mod.shadow_cull_camera = shadow_cull_camera

	Camera.set_data(shadow_cull_camera, "unit", camera_unit)
	Viewport.set_data(viewport, "shadow_cull_camera", shadow_cull_camera)
	ScriptWorld._update_render_queue(world)
	return viewport
end

mod.toggleMap = function()
	if mod.active then
		mod:destroyViewport()
	else
		mod:createViewport()
	end
end

-- got this from DarknessSystem.is_in_darkness_volume
mod.is_in_volume = function(self, position, volume)
	local is_inside = false

	if not bottom and not top then
		Level.is_point_inside_volume(level, "room_volume", volume)
	end

	return false
end

mod.setProps = function(key, value, v2, v3, v4)
	if value == "" then
		mod:echo("no value given")
	end
	if key == "a" then
		Viewport.set_data(mod.viewport, "active", true)
		ScriptWorld._update_render_queue(mod.world)
		return
	end
	if key == "d" then
		Viewport.set_data(mod.viewport, "active", false)
		ScriptWorld._update_render_queue(mod.world)
		return
	end
	if key == "area" or key == "size" or key == "near" or key == "far" or key == "height" then
		mod:set(key, value)
		mod._current_settings[key] = value
	elseif key == "pos" then
		mod:set("followPlayer", false)
		mod:saveCamera(value)
	else
		mod:echo(key .. " is not a supported")
	end
end

mod:command("m_debug", "Shows debug stuff for Minimap mod", mod.print_debug)
mod:command("m_set", "Sets specific values for Minimap", mod.setProps)

-- hook I stole from Streaming Info
mod:hook_safe(
	IngameUI,
	"update",
	function(self, dt, t, disable_ingame_ui, end_of_level_ui) -- luacheck: no unused
		mod.ingameUI = self
		--[[ 		local level_transition_handler = Managers.state.game_mode.level_transition_handler
		local level_key = level_transition_handler:get_current_level_keys()
		local is_in_inn = level_key == "inn_level"

		local in_score_screen = end_of_level_ui ~= nil
		local end_screen_active = self:end_screen_active()

		local game_mode_manager = Managers.state.game_mode
		local round_started = game_mode_manager:is_round_started()

		if not (is_in_inn or in_score_screen or end_screen_active) then
			if round_started then
				return
			end
		end

		mod.draw_info(self) ]]
	end
)
mod:hook_safe(
	IngameUI,
	"init",
	function(...) -- luacheck: no unused
		mod:echo("init ingame ui")
	end
)
mod:hook_safe(
	IngameUI,
	"setup_views",
	function(...) -- luacheck: no unused
		mod:echo("setup views")
	end
)
mod:hook_safe(
	OverchargeBarUI,
	"init",
	function(...) -- luacheck: no unused
		mod:echo("init overcharge bar")
	end
)
mod:hook_safe(
	CameraSystem,
	"update",
	function(self, context)
		local dt = context.dt
		local t = context.t
		local camera_manager = Managers.state.camera

		for player, camera_unit in pairs(self.camera_units) do
			local viewport_name = player.viewport_name
		end
	end
)

mod:hook(
	IngameUI,
	"_update_hud_visibility",
	function(func, self, disable_ingame_ui, in_score_screen)
		--[[ 		local player = Managers.player:local_player(1)
		local vp_name = player and player.viewport_name
		if mod.camera then
			mod:echo(vp_name)
		end
 ]]
		local current_view = self.current_view
		local cutscene_system = self.cutscene_system
		local mission_vote_in_progress = self.mission_voting_ui:is_active()
		local is_enter_game = self.countdown_ui:is_enter_game()
		local end_screen_active = self:end_screen_active()
		local menu_active = self.menu_active
		local draw_hud = nil

		if
			not disable_ingame_ui and not menu_active and not current_view and not is_enter_game and not mission_vote_in_progress and
				not in_score_screen and
				not end_screen_active and
				not self:unavailable_hero_popup_active()
		 then
			draw_hud = true
		else
			draw_hud = false
		end

		-- additional condition for map
		if mod.camera then
			draw_hud = false
		end
		-- end of additional condition

		local hud_visible = self.hud_visible

		if draw_hud ~= hud_visible then
			self.hud_visible = draw_hud

			self.ingame_hud:set_visible(draw_hud)
		end
	end
)
mod.update = function(dt)
	if not mod.camera then
		return
	end

	if not mod._level_settings then
		local s = mod:_get_level_settings()
		mod._level_settings = s
	end

	mod:syncCam(dt)
	mod:check_polygons(dt)
	if mod:get("debug_mode") then
		mod.print_live()
	end
end

mod.on_unload = function(exit_game)
	if mod.active then
		mod:destroyViewport()
	end
	return
end

mod.on_game_state_changed = function(status, state)
	return
end

mod.on_setting_changed = function(setting_name)
	return
end

mod.on_disabled = function(is_first_call)
	if mod.active then
		mod:destroyViewport()
	end
end
