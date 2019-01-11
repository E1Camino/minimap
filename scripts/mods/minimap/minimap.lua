local mod = get_mod("minimap")

mod.first = false
mod.viewport = nil
mod.camera = nil
mod.active = false

mod.offsetSpeed = 0.1

mod.increaseOffset = function()
	local c = mod:get("offset")
	mod:set("offset", c + mod.offsetSpeed)
end
mod.decreaseOffset = function()
	local c = mod:get("offset")
	mod:set("offset", c - mod.offsetSpeed)
end
mod.increaseOffsetSpeed = function()
	mod.offsetSpeed = mod.offsetSpeed + 0.1
end
mod.decreaseOffsetSpeed = function()
	mod.offsetSpeed = mod.offsetSpeed - 0.1
end

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
	mod:echo(mod:get("minx") .. " " .. mod:get("maxx") .. " " .. mod:get("minz") .. " " .. mod:get("maxz"))
	mod:echo("offset " .. mod:get("offset"))
	mod:echo("offsets " .. mod.offsetSpeed)

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
	Camera.set_data(camera, "unit", camera_unit)
	mod.camera = camera
	Viewport.set_data(viewport, "camera", camera)

	local shadow_cull_camera = Unit.camera(camera_unit, "shadow_cull_camera")

	Camera.set_data(shadow_cull_camera, "unit", camera_unit)
	Viewport.set_data(viewport, "shadow_cull_camera", shadow_cull_camera)

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

mod.toggleMap = function()
	if mod.active then
		mod:destroyViewport()
	else
		mod:createViewport()
	end
end

mod.setProps = function(key, value, v2, v3, v4)
	if value == "" then
		mod:warn("no value given")
	end
	if key == "size" or key == "near" or key == "far" or key == "offset" then
		mod:set(key, value)
	else
		mod:warn(key .. " is not a supported")
	end
end

mod:command("m_destroy", "Change camera params", mod.destroyViewport)
mod:command("m_create", "Creates a new freeflight viewport", mod.createViewport)
mod:command("m_debug", "Shows debug stuff for Minimap mod", mod.print_debug)
mod:command("m_s", "Sets specific values for Minimap", mod.setProps)

mod.update = function(dt)
	mod:syncCam(dt)
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
