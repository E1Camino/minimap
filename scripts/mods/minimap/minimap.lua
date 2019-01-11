local mod = get_mod("minimap")

mod.first = false
mod.PX = nil
mod.viewport = nil
mod.proj = false
mod.pos = nil
mod.camera = nil
mod.cameraUnit = nil
mod.x = 0
mod.dx = -1
mod.active = false

local function my_function()
	return
end

mod.print_debug = function(dt)
	if not mod.camera then
		mod:destroyViewport()
		mod:createViewport()
	end

	local local_player_unit = Managers.player:local_player().player_unit
	local player_position = Unit.local_position(local_player_unit, 0)
	mod:echo(player_position)

	local oldRot = ScriptCamera.rotation(mod.camera)
	mod:echo("near " .. Camera.near_range(mod.camera))
	mod:echo("far " .. Camera.far_range(mod.camera))
	mod:echo(mod:get("minx") .. " " .. mod:get("maxx"))
	mod:echo(mod:get("minz") .. " " .. mod:get("maxz"))

	--	mod:echo(player_position)
	--	mod:dump(mod.camera, "mod cam", 2)
	--mod:dump(Managers.state.camera._camera_nodes.player_1, "camera", 4)
end

mod.syncCam = function(dt)
	if not mod.camera then
		return
	end
	-- sync position with player character
	local follow = mod:get("followPlayer")
	if follow then
		local local_player_unit = Managers.player:local_player().player_unit
		local player_position = Unit.local_position(local_player_unit, 0)
		--ScriptCamera.set_local_position(mod.camera, player_position)

		local camera_position_new = Vector3.zero()
		camera_position_new.x = player_position.x
		camera_position_new.y = player_position.y
		camera_position_new.z = player_position.z + mod:get("offset")
		local lookat_target = Vector3(0, camera_position_new.z, 0)
		local direction = Vector3.normalize(player_position - camera_position_new)
		local rotation = Quaternion.look(direction)

		ScriptCamera.set_local_position(mod.camera, camera_position_new)
		ScriptCamera.set_local_rotation(mod.camera, rotation)
	end

	Camera.set_projection_type(mod.camera, Camera.ORTHOGRAPHIC)
	Camera.set_far_range(mod.camera, mod:get("far"))
	Camera.set_near_range(mod.camera, mod:get("near"))
	local min = mod:get("size") * -1
	local max = mod:get("size")
	Camera.set_orthographic_view(mod.camera, min, max, min, max)

	--ScriptCamera.set_local_rotation(mod.camera, top)
end

mod.createViewport = function()
	local world = Application.main_world()
	mod.viewport = mod._create_minimap_viewport(world, "minimap", "default", 2)
	mod.active = true
	--CameraManager:add_viewport(mod.viewport, "minimap")
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

	Viewport.set_data(viewport, "layer", layer or 1)
	Viewport.set_data(viewport, "active", true)
	Viewport.set_data(viewport, "name", name)

	viewports[name] = viewport

	if force_no_scaling then
		Viewport.set_data(viewport, "no_scaling", true)
	end

	local splitscreen = Managers.splitscreen and Managers.splitscreen:active()

	Viewport.set_data(
		viewport,
		"rect",
		{
			0,
			0,
			1,
			1
		}
	)

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
	mod:echo(camera)
	Camera.set_data(camera, "unit", camera_unit)
	mod.camera = camera
	mod.cameraUnit = camera_unit
	Viewport.set_data(viewport, "camera", camera)

	if add_shadow_cull_camera then
		local shadow_cull_camera = Unit.camera(camera_unit, "shadow_cull_camera")

		Camera.set_data(shadow_cull_camera, "unit", camera_unit)
		Viewport.set_data(viewport, "shadow_cull_camera", shadow_cull_camera)
	end

	ScriptWorld._update_render_queue(world)
	return viewport
end

mod.destroyViewport = function()
	local world = Application.main_world()
	ScriptWorld.destroy_viewport(world, "minimap")
	mod.viewport = nil
	mod.camera = nil
	mod.active = false
end

mod.updateCamera = function()
	-- try to change camera projection
	if not mod.PX then
		return
	end
	local world = Application.main_world()
	if not mod.camera then
		return
	end
	mod:echo("offset")
	mod.camera:set_offset(0, mod.PX * -0.15 + (10 * -1) / 100, mod:get("near") / 100)
end

mod.setProps = function(key, value, v2, v3, v4)
	if value == "" then
		mod:echo("no value given")
	end
	if key == "size" or key == "near" or key == "far" or key == "offset" then
		mod:set(key, value)
	else
		mod:echo(key)
		mod:echo(key .. " is not a supported")
	end
end

mod:command("m_update_camera", "Change camera params", mod.updateCamera)
mod:command("m_destroy", "Change camera params", mod.destroyViewport)
mod:command("m_create", "Creates a new freeflight viewport", mod.createViewport)
mod:command("m_debug", "Shows debug stuff for Minimap mod", mod.print_debug)
mod:command("m_s", "Sets specific values for Minimap", mod.setProps)

mod.update = function(dt)
	mod:syncCam(dt)

	--[[ 	mod:echo("player_position")
	mod:echo(player_position)
	
	local pose = mod.camera.local_pose
	mod:echo("cam")
	mod:echo(pose)
	local position = mod.camera.local_position
	mod:echo(position)
	local rotation = mod.camera.local_rotation
	mod:echo(rotation)
 ]]
	--[[ 	local ortho_data = data.orthographic_data
	ortho_data.yaw = (ortho_data.yaw or 0) - Vector3.x(mouse) * data.rotation_speed
	local q1 = Quaternion(Vector3(0, 0, 1), ortho_data.yaw)
	local q2 = Quaternion(Vector3.right(), -math.half_pi)
	local q = Quaternion.multiply(q1, q2)
	local x_trans = (input_service:get("move_right") - input_service:get("move_left")) * dt * 250
	local y_trans = (input_service:get("move_forward") - input_service:get("move_back")) * dt * 250
	local pos = trans + Quaternion.up(q) * y_trans + Quaternion.right(q) * x_trans
	cm = Matrix4x4.from_quaternion_position(q, pos)
	local size = ortho_data.size
	size = size - speed_change * size * dt
	ortho_data.size = size

	Camera.set_orthographic_view(mod.camera, -size, size, -size, size) ]]
	--ScriptCamera.set_local_position(mod.camera, player_position)
	return
end

--[[ mod:hook_origin(
	FreeFlightManager,
	"_setup_data",
	function(self, data)
		data.global = {
			translation_speed = 0.05,
			rotation_speed = 0.003,
			mode = "paused",
			active = true,
			projection_type = Camera.ORTHOGRAPHIC,
			orthographic_data = {
				size = 1000
			}
		}
	end
) ]]
--[[ mod:hook(
	PlayerUnitFirstPerson,
	"calculate_look_rotation",
	function(func, self, current_rotation, look_delta, ...)
		local result = func(self, current_rotation, look_delta, ...)
		local pitch =
			Quaternion(
			Vector3.right(),
			math.clamp(Quaternion.pitch(current_rotation) + look_delta.y, -self.MAX_MIN_PITCH, self.MAX_MIN_PITCH)
		)
		local PX, PY, PZ, PW = Quaternion.to_elements(pitch)
		mod.Vector3 = Vector3
		mod.Vector4 = Vector4
		mod.Quaternion = Quaternion
		--Managers.state.camera:set_offset(0, PX * -0.15 + (mod:get("offset") * -1) / 100, 0)
		return result
	end
) ]]
--[[ 
mod:hook_safe(
	FreeFlightManager,
	"register_input_manager",
	function(self, input_manager)
		mod:echo("input")
		return
	end
)
mod:hook_origin(
	FreeFlightManager,
	"_update_global",
	function(self, dt)
		local data = self.data.global
		local input_service = self:_resolve_input_service()
		local button_pressed = input_service:get("global_free_flight_toggle")
		local frustum_modifier = input_service:get("frustum_freeze_toggle")

		if data.active and not Managers.world:has_world(data.viewport_world_name) then
			mod:echo("clear")
			self:_clear_global_free_flight(data)
		elseif data.active and frustum_modifier then
			mod:echo("toggle frustum freeze")
			local world = Managers.world:world(data.viewport_world_name)

			self:_toggle_frustum_freeze(dt, data, world, ScriptWorld.global_free_flight_viewport(world), true)
		elseif data.active and button_pressed then
			mod:echo("exit")
			self:_exit_global_free_flight(data)
		elseif button_pressed then
			mod:echo("enter")
			self:_enter_global_free_flight(data)
		elseif data.active then
			mod:echo("update")
			self:_update_global_free_flight(dt, data, input_service)
		end
	end
) ]]
--[[ mod:hook_origin(
	FreeFlightManager,
	"update",
	function(self, dt)
		mod:echo("update")

		if self._paused then
			Debug.text("FreeFlightManager: game is paused")
		end

		local player_manager = Managers.player

		for local_player_id, data in pairs(self.data) do
			if local_player_id ~= "global" then
				local player = player_manager:local_player(local_player_id)

				self:_update_player(dt, player, data)
			end
		end
		self:_update_global(dt)
	end
)

mod:hook_origin(
	ScriptWorld,
	"create_global_free_flight_viewport",
	function(world, template)
		fassert(
			not World.has_data(world, "global_free_flight_viewport"),
			"Trying to spawn global freeflight viewport when one already exists."
		)

		local viewports = World.get_data(world, "viewports")

		if table.is_empty(viewports) then
			return nil
		end

		local bottom_layer = 0
		local bottom_layer_vp = nil

		for key, vp in pairs(viewports) do
			local layer = Viewport.get_data(vp, "layer")

			if layer > bottom_layer then
				bottom_layer_vp = vp
				bottom_layer = layer
			end
		end
		mod:echo("bottom_layer", bottom_layer)
		mod:echo(bottom_layer)

		local free_flight_viewport = Application.create_viewport(world, template)

		Viewport.set_data(free_flight_viewport, "layer", Viewport.get_data(bottom_layer_vp, "layer"))
		World.set_data(world, "global_free_flight_viewport", free_flight_viewport)

		local camera_unit = World.spawn_unit(world, "core/units/camera")
		local camera = Unit.camera(camera_unit, "camera")

		Camera.set_data(camera, "unit", camera_unit)

		local bottom_layer_camera = ScriptViewport.camera(bottom_layer_vp)
		local pose = Camera.local_pose(bottom_layer_camera)

		ScriptCamera.set_local_pose(camera, pose)

		local vertical_fov = Camera.vertical_fov(bottom_layer_camera)

		Camera.set_vertical_fov(camera, vertical_fov)
		Viewport.set_data(free_flight_viewport, "camera", camera)

		return free_flight_viewport
	end
) ]]
--[[ 
mod:hook_origin(
	ScriptWorld,
	"create_viewport",
	function(world, name, template, layer, position, rotation, add_shadow_cull_camera, force_no_scaling)
		mod:echo(position)
		mod:echo(rotation)
		mod:echo(add_shadow_cull_camera)
		mod:echo(force_no_scaling)
		local viewports = World.get_data(world, "viewports")

		fassert(viewports[name] == nil, "Viewport %q already exists", name)

		local viewport = Application.create_viewport(world, template)

		Viewport.set_data(viewport, "layer", layer or 1)
		Viewport.set_data(viewport, "active", true)
		Viewport.set_data(viewport, "name", name)

		viewports[name] = viewport

		if force_no_scaling then
			Viewport.set_data(viewport, "no_scaling", true)
		end

		local splitscreen = Managers.splitscreen and Managers.splitscreen:active()

		if splitscreen and not force_no_scaling then
			Viewport.set_data(
				viewport,
				"rect",
				{
					SPLITSCREEN_OFFSET_X,
					SPLITSCREEN_OFFSET_Y,
					SPLITSCREEN_WIDTH,
					SPLITSCREEN_HEIGHT
				}
			)
		else
			Viewport.set_data(
				viewport,
				"rect",
				{
					0,
					0,
					1,
					1
				}
			)
		end

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
		Viewport.set_data(viewport, "camera", camera)

		if add_shadow_cull_camera then
			local shadow_cull_camera = Unit.camera(camera_unit, "shadow_cull_camera")

			Camera.set_data(shadow_cull_camera, "unit", camera_unit)
			Viewport.set_data(viewport, "shadow_cull_camera", shadow_cull_camera)
		end

		ScriptWorld._update_render_queue(world)

		return viewport
	end
)

mod:hook_origin(
	FreeFlightManager,
	"_update_global_free_flight",
	function(self, dt, data, input_service)
		mod:echo("update")
		local world = Managers.world:world(data.viewport_world_name)
		local viewport = ScriptWorld.global_free_flight_viewport(world)
		local cam = data.frustum_freeze_camera or ScriptViewport.camera(viewport)
		local projection_mode_swap = input_service:get("projection_mode")

		if projection_mode_swap and data.projection_type == Camera.PERSPECTIVE then
			data.projection_type = Camera.ORTHOGRAPHIC
		elseif projection_mode_swap and data.projection_type == Camera.ORTHOGRAPHIC then
			data.projection_type = Camera.ORTHOGRAPHIC
		end

		Camera.set_projection_type(cam, data.projection_type)

		local translation_change_speed = data.translation_speed * 0.5
		local speed_change = Vector3.y(input_service:get("speed_change"))
		data.translation_speed = data.translation_speed + speed_change * translation_change_speed

		if data.translation_speed < 0.001 then
			data.translation_speed = 0.001
		end

		local cm = Camera.local_pose(cam)
		local trans = Matrix4x4.translation(cm)
		local mouse = input_service:get("look")

		if data.projection_type == Camera.ORTHOGRAPHIC then
			local ortho_data = data.orthographic_data
			ortho_data.yaw = (ortho_data.yaw or 0) - Vector3.x(mouse) * data.rotation_speed
			local q1 = Quaternion(Vector3(0, 0, 1), ortho_data.yaw)
			local q2 = Quaternion(Vector3.right(), -math.half_pi)
			local q = Quaternion.multiply(q1, q2)
			local x_trans = (input_service:get("move_right") - input_service:get("move_left")) * dt * 250
			local y_trans = (input_service:get("move_forward") - input_service:get("move_back")) * dt * 250
			local pos = trans + Quaternion.up(q) * y_trans + Quaternion.right(q) * x_trans
			cm = Matrix4x4.from_quaternion_position(q, pos)
			local size = ortho_data.size
			size = size - speed_change * size * dt
			ortho_data.size = size

			Camera.set_orthographic_view(cam, -size, size, -size, size)
		else
			Matrix4x4.set_translation(cm, Vector3(0, 0, 0))

			local q1 = Quaternion(Vector3(0, 0, 1), -Vector3.x(mouse) * data.rotation_speed)
			local q2 = Quaternion(Matrix4x4.x(cm), -Vector3.y(mouse) * data.rotation_speed)
			local q = Quaternion.multiply(q1, q2)
			cm = Matrix4x4.multiply(cm, Matrix4x4.from_quaternion(q))
			local x_trans = input_service:get("move_right") - input_service:get("move_left")
			local y_trans = input_service:get("move_forward") - input_service:get("move_back")

			if PLATFORM == "xb1" then
				local move = input_service:get("move")
				x_trans = move.x * 2
				y_trans = move.y * 2
			end

			local z_trans = input_service:get("move_up") - input_service:get("move_down")
			local offset = Matrix4x4.transform(cm, Vector3(x_trans, y_trans, z_trans) * data.translation_speed)
			trans = Vector3.add(trans, offset)

			Matrix4x4.set_translation(cm, trans)
		end

		if self._frames_until_pause then
			self._frames_until_pause = self._frames_until_pause - 1

			if self._frames_until_pause <= 0 then
				self._frames_until_pause = nil

				self:_pause_game(true)
			end
		elseif input_service:get("step_frame") then
			self:_pause_game(false)

			self._frames_until_pause = self._frames_to_step
		end

		if input_service:get("play_pause") then
			self:_pause_game(not self._paused)
		end

		if input_service:get("decrease_frame_step") then
			self._frames_to_step = (self._frames_to_step > 1 and self._frames_to_step - 1) or 1

			print("Frame step:", self._frames_to_step)
		elseif input_service:get("increase_frame_step") then
			self._frames_to_step = self._frames_to_step + 1

			print("Frame step:", self._frames_to_step)
		end

		local rot = Matrix4x4.rotation(cm)
		local wwise_world = Managers.world:wwise_world(world)

		WwiseWorld.set_listener(wwise_world, 0, cm)

		if self._has_terrain then
			TerrainDecoration.move_observer(world, data.terrain_decoration_observer, trans)
		end

		ScatterSystem.move_observer(World.scatter_system(world), data.scatter_system_observer, trans, rot)

		if input_service:get("mark") then
			print("Camera at: " .. tostring(cm))
		end

		if input_service:get("toggle_control_points") then
			cm = FreeFlightControlPoints[self.current_control_point]:unbox()
			self.current_control_point = self.current_control_point % #FreeFlightControlPoints + 1

			print("Control Point: " .. tostring(self.current_control_point))
		end

		if input_service:get("set_drop_position") then
			self:drop_player_at_camera_pos(cam)
		end
	end
) ]]
mod.on_unload = function(exit_game)
	return
end

mod.on_game_state_changed = function(status, state)
	return
end

mod.on_setting_changed = function(setting_name)
	return
end

mod.on_disabled = function(is_first_call)
	Managers.state.camera:set_offset(0, 0, 0)
end

mod.on_enabled = function(is_first_call)
	return
end

--[[ 

mod.minimap_ready = false
mod.minimap_gui = nil

-- stuff from lockedAndLoaded

-- Hook to perform updates to UI
mod:hook(
	MatchmakingManager,
	"update",
	function(func, self, dt, ...)
		if
			mod.minimap_ready and not Managers.player.network_manager.matchmaking_manager._ingame_ui.current_view and
				Managers.world:world("level_world")
		 then
			if not mod.minimap_gui and Managers.world:world("top_ingame_view") then
				mod:create_gui()
			end
		end

		func(self, dt, ...)
	end
)
mod.create_gui = function(self)
	if Managers.world:world("top_ingame_view") then
		local top_world = Managers.world:world("top_ingame_view")

		-- Create a screen overlay with specific materials we want to render
		--mod.minimap_gui = World.create_screen_gui(top_world, "immediate", "material", "materials/minimap/map")

		local icon_size = math.floor(32 * RESOLUTION_LOOKUP.scale)
		local icon_x =
			math.floor(RESOLUTION_LOOKUP.res_w - icon_size - (RESOLUTION_LOOKUP.res_w * RESOLUTION_LOOKUP.scale * 0.075))
		local icon_y = math.floor(icon_size + (RESOLUTION_LOOKUP.res_h * RESOLUTION_LOOKUP.scale * 0.1))
		Gui.bitmap(mod.minimap_gui, "example", Vector2(icon_x, icon_y), Vector2(icon_size, icon_size), Color(150, 0, 255, 0))
	end
end

mod.destroy_gui = function(self)
	if Managers.world:world("top_ingame_view") then
		local top_world = Managers.world:world("top_ingame_view")
		World.destroy_gui(top_world, mod.minimap_gui)
		mod.minimap_gui = nil
	end
end

mod:hook(
	StateInGameRunning,
	"on_exit",
	function(func, ...)
		func(...)

		mod.minimap_ready = false
	end
)

mod:hook(
	StateInGameRunning,
	"event_game_started",
	function(func, ...)
		func(...)

		mod.minimap_ready = true
	end
)

-- Call when all mods are being unloaded
mod.on_unload = function(exit_game)
	if mod.minimap_gui and Managers.world:world("top_ingame_view") then
		mod:destroy_gui()
	end
	return
end

-- Call when governing settings checkbox is unchecked
mod.on_disabled = function(is_first_call)
	mod.minimap_ready = true
	-- mod:disable_all_hooks()
end

-- Call when governing settings checkbox is checked
mod.on_enabled = function(is_first_call)
	-- mod:echo('LockedAndLoaded Initialized')
	mod.minimap_ready = true
	-- mod:enable_all_hooks()
end

-- stuff i copied from Bestiary - thx pal

--[[ mod:hook(
	HeroView,
	"init",
	function(orig_func, self, ingame_ui_context)
		local result = orig_func(self, ingame_ui_context)

		local minimap = {
			name = "minimap",
			state_name = "HeroViewStateBestiary",
			hotkey_disabled = true,
			draw_background_world = true,
			camera_position = {
				0,
				0,
				0
			},
			camera_rotation = {
				0,
				0,
				0
			},
			contains_new_content = function()
				return false
			end
		}
		local settings_by_screen = self._state_machine_params.settings_by_screen

		local found = false
		for index, screen in ipairs(settings_by_screen) do
			if screen.name == "mininmap" then
				found = true
				break
			end
		end
		if not found then
			table.insert(settings_by_screen, minimap)
		end

		mod.ingame_ui_context = ingame_ui_context

		return result
	end
)

mod:hook_safe(
	StateInGameRunning,
	"update",
	function(self)
		mod.ingame_ui_context = self.ingame_ui_context
		mod.stats_db = self.ingame_ui_context.statistics_db
		mod.stats_id = self.ingame_ui_context.stats_id
	end
)
mod.open_minimap = function()
	if not mod.ingame_ui_context or not mod.ingame_ui_context.is_in_inn then
		return
	else
		local ingame_ui = mod.ingame_ui_context.ingame_ui
		ingame_ui:transition_with_fade(
			"hero_view",
			{
				menu_state_name = "minimap_view"
			}
		)
	end
end

mod:hook_safe(
	ScriptWorld,
	"load_level",
	function(world, name, object_sets, position, rotation, shading_callback, mood_setting)
		mod:dump(Managers.state.camera, "camera", 4)
	end
)

mod:hook_safe(
	CameraManager,
	"post_update",
	function(self, dt, t_, viewport_name)
		-- ##### Get data #################################################################################################
		local viewport = ScriptWorld.viewport(self._world, viewport_name)
		local camera = ScriptViewport.camera(viewport)

		local o = mod:get("ortho")
		local p = Camera.PERSPECTIVE
		if o then
			p = Camera.ORTHOGRAPHIC
		end

		if not mod.p == p then
			local viewports = World.get_data(world, "viewports")
			mod:dump(viewports, "viewports", 4)
		end

		-- original code
		if self._frozen then
			return
		end

		local node_trees = self._node_trees[viewport_name]
		local data = self._variables[viewport_name]

		for tree_id, tree in pairs(node_trees) do
			self:_update_nodes(dt, viewport_name, tree_id, data)
		end

		self:_update_camera(dt, t, viewport_name)
		self:_update_sound_listener(viewport_name)
	end
)
 ]]
