local mod = get_mod("minimap")

local text_definitions = local_require("scripts/ui/views/area_indicator_ui_definitions")

-- will not use procedural meshes or meshes at all until proper fatshark tools arrive
-- https://help.autodesk.com/view/Stingray/ENU/?guid=__lua_ref_exa_ex__snippets_proc__meshes_html
-- local proc_mesh_controller = dofile("scripts/mods/minimap/proc_mesh_controller")

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
mod._interactive_mask_mode = false
mod._interactive_mask_multi_triangle = false

mod._current_settings = mod:_get_default_settings()
mod._set_props = {}
mod._current_location_inside = nil
mod._highlighted_location_inside = nil

mod._current_debug_text = ""
mod._printed_debug_text = ""

mod.camera_positions = {}
mod.current_camera_index = nil
mod._mask_triangles = {}
mod._new_triangles = {}
mod._new_triangle = {}
mod._ref_point = nil
mod._current_location = ""
mod._scroll_factor = 1
mod._pickup_overlay_hooked = false

-- manipulating camera props/settings via chat command or some keybindings (a bit like the photopmod but less ambitious :P)
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

mod.toggle_debug_mode = function()
	local d = mod:get("debug_mode")
	mod:set("debug_mode", not d)
end

-- interactive mask mode where we can add or remove points from current mask
mod.toggle_mask_mode = function()
	local d = mod:get("debug_mode")
	if not d then
		return
	end
	-- toggle mode
	mod._interactive_mask_mode = not mod._interactive_mask_mode

	if not mod._interactive_mask_mode then
		mod._move_triangles_to_triangle_strip()
	end
end
mod.toggle_interactive_triangle_mode = function()
	mod._interactive_mask_multi_triangle = not mod._interactive_mask_multi_triangle
end
mod.add_point = function(self, use_ref)
	if use_ref then
		mod:echo(use_ref)
		mod:echo("add" .. (not use_ref == nil and " t "))
	end
	if not mod._interactive_mask_mode then
		return
	end
	if mod.input_manager then
		local cursor = Mouse.axis(Mouse.axis_id("cursor"))
		local world = Camera.screen_to_world(mod.camera, cursor, 10)

		-- round stuff so we have kind of a snap function :D
		local point = {
			tonumber(string.format("%.2f", world.x)),
			tonumber(string.format("%.2f", world.y)),
			tonumber(string.format("%.2f", mod._current_settings.near))
		}
		if use_ref and mod._ref_point then
			point = mod._ref_point
			mod._ref_point = nil
		end
		table.insert(mod._new_triangle, point)

		-- safe the second point of the first triangle for reference
		if #mod._new_triangle == 2 and not mod._ref_point then
			mod._ref_point = point
		end
		mod._move_points_to_triangle()
	end
end
mod._move_points_to_triangle = function()
	if #mod._new_triangle == 3 then
		local t = table.clone(mod._new_triangle)
		table.insert(mod._new_triangles, t)

		-- reset the new triangle
		local new_triangle = {}
		if mod._interactive_mask_multi_triangle then
			-- take the first point (shared corner of all triangles in the multi mode (e.g. corner of screen))
			table.insert(new_triangle, mod._new_triangle[1])
			-- take the last point of old (so new triangle will be modelled next to the last edge of old triangle)
			table.insert(new_triangle, mod._new_triangle[3])
		end
		mod._new_triangle = new_triangle
	end
end
mod._move_triangles_to_triangle_strip = function()
	table.insert(
		mod._mask_triangles,
		{
			triangles = mod._new_triangles
		}
	)
	mod._new_triangle = {}
	mod._new_triangles = {}
end
mod.add_last_point = function()
	if not mod._interactive_mask_multi_triangle or not mod._ref_point then
		return
	end
	table.insert(mod._new_triangle, mod._ref_point)
	mod._move_points_to_triangle()
	mod._move_triangles_to_triangle_strip()
	mod._ref_point = nil
end
mod.remove_point = function()
	if not mod._interactive_mask_mode then
		return
	end
	if #mod._new_triangle > 1 then
		local tri = mod._new_triangle
		mod._new_triangle[#mod._new_triangle] = nil
	end
end
-- debug methods (mainly for showing positions, camera settings and all location features (polygons and such))
mod.print_live = function()
	local d = mod:get("debug_mode")

	if d then
		-- show location polygons
		local same_location = mod._current_location_inside == mod._highlighted_location_inside
		if mod._debug_lines == nil or mod._should_redraw_debug_lines or not same_location then
			mod._highlighted_location_inside = mod._current_location_inside
			mod._should_redraw_debug_lines = false
			mod.destroy_debug_lines()
			mod.create_debug_lines()
		end

		-- on screen text
		local local_player_unit = Managers.player:local_player().player_unit
		local player_position = Unit.local_position(local_player_unit, 0)
		local w, h = Application.resolution()
		local pos = Vector3(20, h - 25, 5)
		if mod._level_key then
			pos = mod.ingame_ui:_show_text("level: " .. mod._level_key, pos)
		end
		pos =
			mod.ingame_ui:_show_text("pos: " .. player_position.x .. ", " .. player_position.y .. ", " .. player_position.z, pos)
		pos = mod.ingame_ui:_show_text("debug: " .. mod._current_debug_text or "", pos)
		if mod._current_location_inside then
			pos = mod.ingame_ui:_show_text("location: " .. mod._current_location_inside.name or "", pos)
		end

		-- print cursor
		if mod.input_manager then
			local cursor = Mouse.axis(Mouse.axis_id("cursor"))
			local world = Camera.screen_to_world(mod.camera, cursor, 10)
			pos = mod.ingame_ui:_show_text("cursor: " .. world.x .. ", " .. world.y .. ", " .. player_position.z, pos)
		end

		-- print if interactive debug mode
		if mod._interactive_mask_mode then
			local t_mode = "single"
			if mod._interactive_mask_multi_triangle then
				t_mode = "mulit"
			end
			pos = mod.ingame_ui:_show_text("mask_mode - " .. t_mode, pos)
		end

		-- debug stuff about painted mask triangles
		local loc = mod._current_location_inside
		if loc then
			if loc.mask then
				local point = loc.mask.triangles[1][1]
				local p = Vector2(point[1], point[2])
				local world = Camera.screen_to_world(mod.camera, p, 10)
				pos = mod.ingame_ui:_show_text("cursor: " .. world.x .. ", " .. world.y .. ", " .. player_position.z, pos)
			end
		end
	else
		mod.destroy_debug_lines()
	end
	-- test disabling fog
	local shading_env = World.get_data(mod.world, "shading_environment")
	ShadingEnvironment.set_scalar(shading_env, "fog_enabled", 0)
	ShadingEnvironment.set_scalar(shading_env, "dof_enabled", 0)
	ShadingEnvironment.set_scalar(shading_env, "motion_bur_enabled", 0)
	ShadingEnvironment.set_scalar(shading_env, "outline_enabled", 0)
	--		ShadingEnvironment.set_scalar(shading_env, "sun_shadows_enabled", 0)
	ShadingEnvironment.set_scalar(shading_env, "ssm_enabled", 1)
	ShadingEnvironment.set_scalar(shading_env, "ssm_constant_update_enabled", 1)
	ShadingEnvironment.apply(shading_env)
end
mod.print_debug = function(dt)
	if not mod.camera then
		mod:destroy_minimap()
		mod:create_minimap()
	end

	mod._should_redraw_debug_lines = true
	local local_player_unit = Managers.player:local_player().player_unit
	local player_position = Unit.local_position(local_player_unit, 0)
	mod:echo(player_position)

	local oldRot = ScriptCamera.rotation(mod.camera)
	mod:echo(
		(mod.propsForToggle[mod.currentProp] == "near" and "*" or "") ..
			"near " .. mod:get("near") .. " " .. mod._current_settings.near
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
			"area " ..
				mod:get("area") .. " " .. mod._current_settings.area .. " " .. mod._current_settings.area * mod._scroll_factor
	)

	local shading_env = World.get_data(mod.world, "shading_environment")
	local fog = ShadingEnvironment.scalar(shading_env, ("dense_fog"))
	local fog_enabled = ShadingEnvironment.scalar(shading_env, ("fog_enabled"))

	local addString = function(stack, s)
		table.insert(stack, s) -- push 's' into the the stack
		for i = table.getn(stack) - 1, 1, -1 do
			if string.len(stack[i]) > string.len(stack[i + 1]) then
				break
			end
			stack[i] = stack[i] .. table.remove(stack)
		end
	end
	local s = "masks = {" -- starts with an empty string
	for l, trianglestrip in pairs(mod._mask_triangles) do
		if trianglestrip then
			s = s .. "{triangles = {\n"
			for m, triangle in pairs(trianglestrip.triangles) do
				s = s .. "{"
				for j, point in pairs(triangle) do
					s = s .. "{"
					s = s .. "" .. point[1] .. ","
					s = s .. "" .. point[2] .. ","
					s = s .. "" .. point[3]
					if j == 3 then
						s = s .. "}"
					else
						s = s .. "},"
					end
				end
				if m == #trianglestrip.triangles then
					s = s .. "}\n"
				else
					s = s .. "},\n"
				end
				s = s .. ""
			end
			if l == #mod._mask_triangles then
				s = s .. "}}\n"
			else
				s = s .. "}},\n"
			end
		end
	end
	s = s .. "}\n"
	-- warn so we can dump it into the log file and copy paste it into our level settings
	mod:warning(s)
	mod:set("masks", s)
end
mod.create_debug_lines = function()
	local world = mod.world
	if not world or not Managers.player or not mod._debug_lines == nil then
		mod:echo("no lines")
		return
	end
	mod._debug_lines = World.create_line_object(world, true)

	-- paint level setting locations
	mod._create_debug_points()
	LineObject.dispatch(world, mod._debug_lines)
end
mod._create_debug_points = function(z)
	if not mod._level_settings then
		return
	end

	function paint_all_children(parent)
		if not parent then
			return
		end
		if parent.children then
			-- location iteration
			for location_name, location in pairs(parent.children) do
				local color = Color(255, 255, 255, 255)
				local color_first = Color(255, 255, 255, 0)
				local highlight_color = Color(255, 255, 0, 0)

				-- paint
				if location.check.type == "polygon" then
					-- highlight location that we are inside
					-- check if camera is inside location
					local points = location.check.features
					if points then
						local pre = mod._pre_calc(location)
						local prev = points[#points]

						--polygon point iteration
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

							if si == 1 then
								LineObject.add_line(mod._debug_lines, color_first, p_p, c_p)
								LineObject.add_sphere(mod._debug_lines, color_first, c_p, 0.05)
							else
								LineObject.add_line(mod._debug_lines, color, p_p, c_p)
								LineObject.add_sphere(mod._debug_lines, color, c_p, 0.05)
							end
							if mod._current_location_inside then
								if location_name == mod._current_location_inside.name then
									LineObject.add_line(mod._debug_lines, highlight_color, p_p, c_p)
									LineObject.add_sphere(mod._debug_lines, highlight_color, c_p, 0.05)
								end
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
	mod._debug_lines = nil
end

-- orthogonal top view as new viewport with own camera settings
mod._get_viewport_cam = function(viewport_name)
	local world = mod.world
	local o_viewport = ScriptWorld.viewport(world, viewport_name)

	return ScriptViewport.camera(o_viewport)
end
mod.syncCam = function(dt)
	local local_player_unit = Managers.player:local_player().player_unit
	if not local_player_unit then
		return
	end
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

	local scroll = math.min(math.max(0.2, mod._scroll_factor), 10.0) -- at least 1/5 of setting and max 10x setting
	local min = mod._current_settings.area * -1 * scroll
	local max = mod._current_settings.area * scroll
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

-- location checks (so we can apply camera settings based on the position of the player)
mod.check_locations = function(dt)
	if not mod._level_settings then
		return
	end

	local new_settings = table.clone(mod._current_settings)
	local new_inside = mod._level_settings

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
	local location_list = mod._level_settings.children
	local hasChildren = location_list
	while (hasChildren) do
		hasChildren = false
		for location_name, location in pairs(location_list) do
			if location_name == "name" or location_name == "settings" then -- ignore the name attribute
			else
				local inside = mod.check_location(location, position)
				if inside then
					-- remember this location
					new_inside = location

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
		-- mod:dump(location, "loc", 3)
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
	mod._level_key = level_key
	mod:echo(level_key)
	return dofile("scripts/mods/minimap/minimap_level_data")[level_key]
end

mod.create_viewport = function()
	local world = Managers.world:world("level_world")
	mod.world = world
	mod.viewport = mod._create_minimap_viewport(world, "minimap", "default", 2)
	ScriptWorld.activate_viewport(world, mod.viewport)
	mod.active = true
end

mod.destroy_viewport = function()
	if mod.camera then
		mod.destroy_debug_lines()
		local world = mod.world
		if world then
			ScriptWorld.destroy_viewport(world, "minimap")
		end
		mod.viewport = nil
		mod.camera = nil
		mod.active = false
		mod._character_offset = 0
	end
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

-- gui (masking the viewport / showing additional stuff like icons -> zaphio ;-)
-- base methods are taken somehow from LockedAndLoaded - tyvm
mod.create_gui = function()
	local top_world = Managers.world:world("top_ingame_view")
	if top_world then
		--proc_mesh_controller:start()
		--local sphere_points = proc_mesh_controller.make_sphere_points(300)

		-- Create a screen overla
		mod.minimap_gui = World.create_screen_gui(top_world, "immediate")
	end
	Window.set_show_cursor(true)
end
mod.destroy_gui = function()
	local top_world = Managers.world:world("top_ingame_view")
	if top_world and mod.minimap_gui then
		--proc_mesh_controller:shutdown()
		World.destroy_gui(top_world, mod.minimap_gui)
		mod.minimap_gui = nil
	end
	Window.set_show_cursor(false)
end
mod.print_game_location = function()
	local player_manager = Managers.player
	local local_player = player_manager:local_player()
	local player_unit = local_player.player_unit

	if Unit.alive(player_unit) then
		local player_hud_extension = ScriptUnit.extension(player_unit, "hud_system")
		local current_location = player_hud_extension.current_location
		if not current_location == mod.saved_location then
			-- play the sound that appears when location has changed
			local wwise_world = Managers.world:wwise_world(mod.world)
			WwiseWorld.trigger_event(wwise_world, "hud_area_indicator")
		end
		mod.saved_location = current_location
	end
end

mod:hook(
	IngameUI,
	"post_update",
	function(func, self, dt, t)
		if mod.minimap_gui and mod.active and mod.camera then
			if mod.player_input then
				local s = Vector3.y(Mouse.axis(Mouse.axis_index("wheel")))
				local mouse_wheel = tonumber(s)
				if mouse_wheel == 0 then
					--					mod:echo(mouse_wheel)
				else
					local n = mod._scroll_factor + mouse_wheel / 100
					mod._scroll_factor = math.min(math.max(0.2, n), 10.0) -- at least 1/5 of setting and max 10x setting
				end
			end
			--mod:syncCam(dt)
			mod:check_locations(dt)
			if mod:get("debug_mode") then
				if mod._interactive_mask_mode then
					mod.render_interactive_mask()
				end
			end
			mod.render_minimap_mask()
			mod.print_live()
			mod.print_game_location()
		end
		func(self, dt, t)
	end
)
mod:hook(
	MatchmakingManager,
	"update",
	function(func, self, dt, ...)
		if mod.minimap_gui and mod.active and mod.camera then
			mod:syncCam(dt)
		end
		func(self, dt, ...)
	end
)
mod.render_minimap_mask = function()
	local render_masks = function(masks)
		if not masks then
			return
		end
		local default_color = Color(255, 10, 10, 10)
		if mod:get("debug_mode") then
			default_color = Color(190, 10, 10, 10)
		end
		for i, mask in pairs(masks) do
			if mask then
				local color = default_color
				local c = mask.color
				if c then
					color = Color(c[1], c[2], c[3], c[4])
					if mod:get("debug_mode") then
						color = Color(c[1] - c[1] / 4, c[2], c[3], c[4])
					end
				end
				if mask.triangles then
					for j, triangle in pairs(mask.triangles) do
						if triangle then
							local label = ""
							if mod:get("debug_mode") then
								label = "" .. i .. "-" .. j
							end
							mod._render_mask_triangle(triangle, color, label)
						end
					end
				end
			end
		end
	end

	local render_pois = function(points_of_interest)
		if not points_of_interest then
			return
		end
		for i, poi in pairs(points_of_interest) do
			if poi then
				if poi.pos then
					local pos = Vector3(poi.pos[1], poi.pos[2], poi.pos[3])
					local screen_pos = mod._world_to_map(pos)
					local color = Color(255, 255, 255)
					local text = poi.label
					if poi.translated then
						text = Localize(poi.label)
					end
					local size = 18
					if poi.size then
						size = poi.size
					end
					if poi.location then
						size = 40
					end
					if mod.ingame_ui.ui_renderer.gui then
						Gui.text(
							mod.ingame_ui.ui_renderer.gui,
							text,
							"materials/fonts/gw_head_32",
							size,
							"gw_head_20",
							Vector2(screen_pos.x + 2, screen_pos.y - 2),
							Color(0, 0, 0)
						)
						Gui.text(mod.ingame_ui.ui_renderer.gui, text, "materials/fonts/gw_head_32", size, "gw_head_20", screen_pos, color)
					end
				end
			end
		end
	end

	if mod.minimap_gui and mod._current_location_inside then
		render_masks(mod._current_location_inside.masks)
		render_masks(mod._mask_triangles)
		render_pois(mod._current_location_inside.pois)
	end
end
mod.render_interactive_mask = function()
	if mod.minimap_gui and mod._interactive_mask_mode then
		-- all this triangle painting could  be way easier with proper procedural mesh generation or the actual mesh import from futur level editor from fatshark

		local color = Color(150, 10, 10, 10)
		local triangles = mod._new_triangles
		if triangles then
			for i, triangle in pairs(triangles) do
				mod._render_mask_triangle(triangle, color, "" .. i)
			end
		end
		local unfinished_triangle = mod._new_triangle
		if #mod._new_triangle == 2 then
			local preview_triangle = table.clone(mod._new_triangle)
			local cursor = Mouse.axis(Mouse.axis_id("cursor"))
			local world = Camera.screen_to_world(mod.camera, cursor, 10)

			-- round stuff so we have kind of a snap function :D
			local preview_point = {
				tonumber(string.format("%.2f", world.x)),
				tonumber(string.format("%.2f", world.y)),
				tonumber(string.format("%.2f", mod._current_settings.near))
			}
			table.insert(preview_triangle, preview_point)
			mod._render_mask_triangle(preview_triangle, Color(150, 10, 10, 10), "P")
		end
	end
end
mod._render_mask_triangle = function(triangle, color, label)
	if not color then
		local alpha = 255
		if mod:get("debug_mode") then
			alpha = alpha - alpha / 2
		end
		color = Color(alpha, 10, 10, 10)
	end
	if mod.minimap_gui then
		local p1 = Vector3(triangle[1][1], triangle[1][2], triangle[1][3])
		local p2 = Vector3(triangle[2][1], triangle[2][2], triangle[2][3])
		local p3 = Vector3(triangle[3][1], triangle[3][2], triangle[3][3])

		local mask_p1 = mod._world_to_map(p1)
		local mask_p2 = mod._world_to_map(p2)
		local mask_p3 = mod._world_to_map(p3)

		-- optional label at centroid of triangle
		Gui.triangle(mod.minimap_gui, mask_p1, mask_p2, mask_p3, 3, color)
		if label then
			local centroid = Vector2((p1.x + p2.x + p3.x) / 3, (p1.y + p2.y + p3.y) / 3)
			Gui.text(
				mod.ingame_ui.ui_renderer.gui,
				label,
				"materials/fonts/gw_head_32",
				14,
				"gw_head_20",
				mask_p3,
				Color(255, 255, 255)
			)
		end
	end
end
mod._world_to_map = function(world_position)
	return Camera.world_to_screen(mod.camera, world_position)
end
mod._map_to_world = function(point)
end
mod._screen_to_map = function(point)
end
mod._map_to_screen = function(point)
end
-- user stuff / chat commands and such
mod.register_input = function()
	local input_manager = Managers.input
	if input_manager then
		local player_input = input_manager.input_services.Player
		mod.input_manager = input_manager
		mod.player_input = player_input
		input_manager:device_unblock_all_services("keyboard")
		input_manager:device_unblock_all_services("mouse")
	end
end

mod.teleport = function()
	-- get the player
	local player_unit = Managers.player:local_player().player_unit
	local locomotion_extension = ScriptUnit.extension(player_unit, "locomotion_system")

	-- get the cursor position
	local cursor = Mouse.axis(Mouse.axis_id("cursor"))
	-- calculate clicked position in the world
	local world_pos = Camera.screen_to_world(mod.camera, Vector3(cursor.x, cursor.y, 0), 0.5)
	-- teleport the player to clicked position with current znear as height (so we drop into the place that is currently visible on the map)
	locomotion_extension:teleport_to(
		Vector3(world_pos.x, world_pos.y, mod._current_settings.near - 1), -- fixed offset of 1 so very narrow passages work a bit better
		Unit.world_rotation(player_unit, 0)
	)
end

mod.unregister_input = function()
	local input_manager = mod.input_manager
	if input_manager then
		input_manager:device_unblock_all_services("keyboard")
		input_manager:device_unblock_all_services("mouse")
	end
end

mod.create_minimap = function()
	mod:create_viewport()
	mod:create_gui()
	mod:register_input()
end
mod.destroy_minimap = function()
	mod:destroy_viewport()
	mod:destroy_gui()
	mod:unregister_input()
end
mod.toggleMap = function()
	if mod.active then
		mod.destroy_minimap()
	else
		mod.create_minimap()
	end
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
mod:hook(
	WorldManager,
	"create_world",
	function(func, self, name, shading_environment, shading_callback, layer, ...)
		-- every time a level world is created we want to reload level settings
		if mod.is_active and name == "level_world" then
			mod._level_settings = mod:_get_level_settings()
		end
		return func(self, name, shading_environment, shading_callback, layer, ...)
	end
)
mod:hook(
	WorldManager,
	"destroy_world",
	function(func, self, world_or_name)
		if world_or_name then
			local name = nil

			if type(world_or_name) == "string" then
				name = world_or_name
			else
				name = World.get_data(world_or_name, "name")
			end
			mod.destroy_minimap()
		end
		return func(self, world_or_name)
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
	PlayerHud,
	"set_current_location",
	function(func, self, location)
		mod:echo(location)
		return func(self, location)
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
local ItemOverlay = get_mod("item_overlay")
if ItemOverlay then
	mod:hook(
		ItemOverlay,
		"get_camera",
		function(orig_func, player)
			--mod:echo("c")
			if mod.camera then
				return mod.camera
			else
				return orig_func(player)
			end
		end
	)
	mod:hook_disable(ItemOverlay, "get_camera")
end

mod.update = function(dt)
	--mod.hook_pickup_overlay()
	if not mod.camera then
		return
	end

	if not mod._level_settings then
		mod._level_settings = mod:_get_level_settings()
	end
end

mod.on_unload = function(exit_game)
	if mod.active then
		mod:destroy_minimap()
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
		mod:destroy_minimap()
	end
end
