local mod = get_mod("minimap")

mod.first = false
mod.viewport = nil
mod.camera = nil
mod.active = false
mod.offset_speed = 0.1
mod.currentProp = 1
mod.propsForToggle = {"near", "far", "area"}
mod.viewports = nil
mod._get_default_settings = function(self)
	return {
		height = mod:get("height"),
		near = mod:get("near"),
		far = mod:get("far"),
		area = mod:get("area")
	}
end
mod._current_settings = mod:_get_default_settings()
mod._set_props = {}
mod._current_location_inside = nil

mod._current_debug_text = ""
mod._printed_debug_text = ""

mod.camera_positions = {}
mod.current_camera_index = nil

mod.increaseProp = function()
	local prop_key = mod.propsForToggle[mod.currentProp]
	local old_value = mod._current_settings[prop_key]
	mod._set_props[prop_key] = old_value + mod.offset_speed
end
mod.decreaseProp = function()
	local prop_key = mod.propsForToggle[mod.currentProp]
	local old_value = mod._current_settings[prop_key]
	mod._set_props[prop_key] = old_value - mod.offset_speed
end
mod.increasePropSpeed = function()
	mod.offset_speed = mod.offset_speed + 0.1
end
mod.decreasePropSpeed = function()
	mod.offset_speed = mod.offset_speed - 0.1
end
mod.toggleProp = function(propKey)
	if propKey == true then
		mod.currentProp = mod.currentProp + 1 % table.getn(mod.propsForToggle)
		return
	else
		local index = {}
		for k, v in pairs(mod.propsForToggle) do
			index[v] = k
		end
		mod.currentProp = index[propKey]
		return
	end
	mod.currentProp = 1
end

mod.print_live = function()
	local d = mod:get("debug_mode")

	if d then
		local local_player_unit = Managers.player:local_player().player_unit
		local player_position = Unit.local_position(local_player_unit, 0)
		local w, h = Application.resolution()
		local pos = Vector3(100, h - 100, 999)
		pos =
			mod.ingame_ui:_show_text("pos: " .. player_position.x .. ", " .. player_position.y .. ", " .. player_position.z, pos)
		if not mod._current_debug_text == nil then
			pos = mod.ingame_ui:_show_text("debug:" .. mod._current_debug_text)
		end
	end
end

mod.print_debug = function(dt)
	if not mod.camera then
		mod:destroyViewport()
		mod:createViewport()
	end

	mod._should_redraw_debug_lines = d == true
	local local_player_unit = Managers.player:local_player().player_unit
	local player_position = Unit.local_position(local_player_unit, 0)
	mod:echo(player_position)

	local oldRot = ScriptCamera.rotation(mod.camera)
	mod:echo(
		(mod.propsForToggle[mod.currentProp] == "near" and "*" or "") ..
			"nearsad " .. mod:get("near") .. " " .. mod._current_settings.near
	)

	mod:echo(
		(mod.propsForToggle[mod.currentProp] == "far" and "*" or "") ..
			"far " .. mod:get("far") .. " " .. mod._current_settings.far
	)
	mod:echo(
		(mod.propsForToggle[mod.currentProp] == "height" and "*" or "") ..
			"height " .. mod:get("height") .. " " .. mod._current_settings.height
	)
	mod:echo(
		(mod.propsForToggle[mod.currentProp] == "area" and "*" or "") ..
			"area " .. mod:get("area") .. " " .. mod._current_settings.area
	)
end

mod.create_debug_lines = function()
	local world = mod.world
	if not world or not Managers.player or not mod._debug_lines == nil then
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

	-- paint level setting locations
	mod._create_debug_points()
	LineObject.dispatch(world, mod._debug_lines)
end
mod._create_debug_points = function(z)
	if not mod._level_settings then
		return
	end

	function paint_all_children(parent)
		if parent.children then
			-- location iteration
			for location_name, location in pairs(parent.children) do
				local c = Color(255, 255, 255, 255)

				-- paint
				if location.check.type == "polygon" then
					if location.settings.color then
						c = location.settings.color
					end
					-- highlight location that we are inside
					-- check if camera is inside location
					local points = location.check.features
					if points then
						local pre = mod._pre_calc(location)
						local prev = points[#points]

						--polygon point iterationw
						for si, point in pairs(points) do
							local c_p = Vector3.zero()
							c_p.x = point[1]
							c_p.y = point[2]
							c_p.z = z or point[3]
							local p_p = Vector3.zero()
							p_p.x = prev[1]
							p_p.y = prev[2]
							p_p.z = z or prev[3]
							prev = point
							if location_name == mod._current_location_inside then
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

				-- paint children of child current location
				paint_all_children(location)
			end
		end
	end

	paint_all_children(mod._level_settings)
end

mod.destroy_debug_lines = function()
	local world = mod.world
	if not mod._debug_lines or not world then
		return
	end
	LineObject.reset(mod._debug_lines)
	LineObject.dispatch(world, mod._debug_lines)
end

mod._get_viewport_cam = function(viewport_name)
	local world = mod.world
	local o_viewport = ScriptWorld.viewport(world, viewport_name)

	return ScriptViewport.camera(o_viewport)
end

mod.syncCam = function(dt)
	local local_player_unit = Managers.player:local_player().player_unit
	local player_position = Unit.local_position(local_player_unit, 0)

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

	camera_position_new.z = cameraHeight
	local direction = Vector3.normalize(Vector3(0, 0, -1))
	local rotation = Quaternion.look(direction)

	ScriptCamera.set_local_position(mod.camera, camera_position_new)
	ScriptCamera.set_local_rotation(mod.camera, rotation)
	ScriptCamera.set_local_position(mod.shadow_cull_camera, camera_position_new)
	ScriptCamera.set_local_rotation(mod.shadow_cull_camera, rotation)

	Camera.set_projection_type(mod.camera, Camera.ORTHOGRAPHIC)
	Camera.set_projection_type(mod.shadow_cull_camera, Camera.ORTHOGRAPHIC)

	local cfar = cameraHeight + far
	local cnear = cameraHeight - near
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

mod.check_locations = function(dt)
	if not mod._level_settings then
		return
	end

	local new_settings = table.clone(mod._current_settings)
	local new_inside = ""

	-- player position
	local local_player_unit = Managers.player:local_player().player_unit
	local position = Unit.local_position(local_player_unit, 0)

	-- local overwrite function
	local overwrite = function(location)
		if not location.settings then
			return
		end
		for setting_key, setting in pairs(location.settings) do
			local set_prop = mod._set_props[setting_key]
			if set_prop then
				new_settings[setting_key] = set_prop
			else
				new_settings[setting_key] = setting
			end
		end
	end

	overwrite(mod._level_settings)
	local hasChildren = true
	local location_list = mod._level_settings.children
	while (hasChildren) do
		hasChildren = false
		for location_name, location in pairs(location_list) do
			if location_name == "name" or location_name == "settings" then -- ignore the name attribute
			else
				local inside = mod.check_location(location, position)
				if inside then
					-- remember this location
					new_inside = location.name

					-- get the settings declared with this location
					overwrite(location)

					-- check if this location has child locations and proceed with them
					if location.children then
						hasChildren = true
						location_list = location.children
					end
				end
			end
		end
	end

	mod._current_location_inside = new_inside
	mod._current_settings = new_settings
end

mod.check_location = function(location, point)
	if location == nil then
		return false
	end
	if location.name == nil then
		mod:dump(location, "loc", 3)
	else
		-- check if player is inside polygon
		local type = location.check.type
		if type == "polygon" then
			local pre = mod._pre_calc(location)
			return mod:is_point_in_polygon(point, location.check.features, pre)
		end
		-- check if players is above given height
		if type == "above" then
			return point.z > location.check.height
		end
		-- check if players is above given height
		if type == "below" then
			return point.z < location.check.height
		end
	end

	return false
end

mod.is_point_in_polygon = function(self, point, vertices, pre)
	if not pre.corners then
		return false
	end
	-- http://alienryderflex.com/polygon/
	local corners = pre.corners
	local polyX = pre.polyX
	local polyY = pre.polyY
	local multiple = pre.multiple
	local constant = pre.constant
	local x = point.x
	local y = point.y
	local oddNodes = false

	local j = corners
	for i = 1, corners do
		local c1 = (polyY[i] < y and polyY[j] >= y)
		local c2 = (polyY[j] < y and polyY[i] >= y)
		local betweenY = c1 or c2
		if (c1 or c2) then
			local c3 = (y * multiple[i] + constant[i] < x)
			oddNodes = oddNodes ~= c3
		end
		j = i
	end
	return oddNodes
end

mod._pre_calc = function(location)
	-- http://alienryderflex.com/polygon/
	-- only precalc once
	if location._pre then
		return location._pre
	end
	-- we need points to pre calc
	if not location.check.type == "polygon" then
		return
	end
	local points = location.check.features

	--bbox for fast forward checks
	local minX = 10000
	local maxX = -10000
	local minY = 10000
	local maxY = -10000

	-- more advanced preps
	local corners = #points
	local polyX = {}
	local polyY = {}
	local polyZ = {}

	for i, p in pairs(points) do
		polyX[i] = p[1]
		polyY[i] = p[2]
		polyZ[i] = p[3]

		-- bbox
		maxX = math.max(maxX, p[1])
		minX = math.min(minX, p[1])
		maxY = math.max(maxY, p[2])
		minY = math.min(minY, p[2])
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
		polyY = polyY,
		bbox = {
			maxX = maxX,
			minX = minX,
			maxY = maxY,
			minY = minY
		}
	}
	location._pre = pre
	return pre
end

mod._get_level_settings = function(self)
	local level_transition_handler = Managers.state.game_mode.level_transition_handler
	local level_key = level_transition_handler:get_current_level_keys()
	return dofile("scripts/mods/minimap/minimap_level_data")[level_key]
end

mod.createViewport = function()
	local world = Managers.world:world("level_world")
	mod.world = world
	mod.viewport = mod._create_minimap_viewport(world, "minimap", "default", 2)
	ScriptWorld.activate_viewport(world, mod.viewport)
	mod.active = true
end

mod.destroyViewport = function()
	mod.destroy_debug_lines()
	local world = mod.world
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

mod.setProps = function(key, value)
	if value == "" then
		mod:echo("no value given")
	end

	if key == "area" or key == "size" or key == "near" or key == "far" or key == "height" then
		mod.currentProp = mod.toggleProp(key)
		mod._set_props[key] = value
		mod._current_settings[key] = value
		mod:set(key, value)
	elseif key == "pos" then
		mod:set("followPlayer", false)
		mod:saveCamera(value)
	elseif key == "offset_speed" then
		mod.offset_speed = value
	else
		mod:echo(key .. " is not a supported")
	end
end

mod.unsetProps = function(key)
	if key == "area" or key == "size" or key == "near" or key == "far" or key == "height" then
		mod._set_props[key] = nil
	elseif key == "offset_speed" then
		mod.offset_speed = 0.1
	else
		mod:echo(key .. " is not a supported")
	end
end

mod:command("m_debug", "Shows debug stuff for Minimap mod", mod.print_debug)
mod:command("m_set", "Sets specific values for Minimap", mod.setProps)
mod:command("m_unset", "take default value for Minimap", mod.unsetProps)

-- hook I stole from Streaming Info
mod:hook_safe(
	IngameUI,
	"update",
	function(self, dt, t, disable_ingame_ui, end_of_level_ui) -- luacheck: no unused
		mod.ingame_ui = self
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

	local s = mod:_get_level_settings()
	mod._level_settings = s

	mod:syncCam(dt)
	mod:check_locations(dt)
	mod.print_live()
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
	if setting_name == "debug_mode" then
		if not mod:get("debug_mode") then
			mod:echo("destroy")
			mod.destroy_debug_lines()
		end
	end
	return
end

mod.on_disabled = function(is_first_call)
	if mod.active then
		mod:destroyViewport()
	end
end
