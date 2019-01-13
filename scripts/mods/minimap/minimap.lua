local mod = get_mod("minimap")

mod.first = false
mod.viewport = nil
mod.camera = nil
mod.active = false
mod.offset_speed = 0.1
mod.currentProp = 1
mod.propsForToggle = {"height", "near", "far", "size", "area"}
mod.viewports = nil

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
	if not mod:get("debug_mode") then
		return
	end
	local viewport_name = "player_1"
	local world = Application.main_world()
	local o_viewport = ScriptWorld.viewport(world, viewport_name)
	local original_camera = ScriptViewport.camera(o_viewport)
	local origingal_camera_position = ScriptCamera.position(original_camera)
	mod:echo(origingal_camera_position)
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
	local origingal_camera_position = ScriptCamera.position(original_camera)
	mod:echo(origingal_camera_position)

	local oldRot = ScriptCamera.rotation(mod.camera)
	mod:echo(
		(mod.propsForToggle[mod.currentProp] == "near" and "*" or "") ..
			"near " .. mod:get("near") .. " " .. Camera.near_range(mod.camera)
	)

	mod:echo((mod.propsForToggle[mod.currentProp] == "far" and "*" or "") .. "far " .. Camera.far_range(mod.camera))
	mod:echo((mod.propsForToggle[mod.currentProp] == "size" and "*" or "") .. "size " .. mod:get("size") / 100)
	mod:echo((mod.propsForToggle[mod.currentProp] == "area" and "*" or "") .. "area " .. mod:get("area"))
	mod:echo("cameras " .. table.getn(mod.camera_positions))
	mod:dump(mod.camera_positions, "positions", 2)
end

mod.syncCam = function(dt)
	if not mod.camera then
		return
	end

	-- sync position with player character
	-- taking the camera position is easier but could get messy without "no wobble mod"
	local viewport_name = "player_1"
	local world = Application.main_world()
	local o_viewport = ScriptWorld.viewport(world, viewport_name)
	local original_camera = ScriptViewport.camera(o_viewport)
	local origingal_camera_position = ScriptCamera.position(original_camera)
	ScriptCamera.set_local_position(mod.camera, origingal_camera_position)

	local cameraHeight = mod:get("height")

	local camera_position_new = Vector3.zero()
	camera_position_new.x = origingal_camera_position.x
	camera_position_new.y = origingal_camera_position.y
	camera_position_new.z = cameraHeight
	local direction = Vector3.normalize(Vector3(0, 0, -1))
	local rotation = Quaternion.look(direction)

	ScriptCamera.set_local_position(mod.camera, camera_position_new)
	ScriptCamera.set_local_rotation(mod.camera, rotation)
	ScriptCamera.set_local_position(mod.shadow_cull_camera, camera_position_new)
	ScriptCamera.set_local_rotation(mod.shadow_cull_camera, rotation)

	Camera.set_projection_type(mod.camera, Camera.ORTHOGRAPHIC)
	Camera.set_projection_type(mod.shadow_cull_camera, Camera.ORTHOGRAPHIC)

	Camera.set_far_range(mod.camera, mod:get("far"))
	Camera.set_near_range(mod.camera, cameraHeight - origingal_camera_position.z - mod:get("near"))

	Camera.set_far_range(mod.shadow_cull_camera, mod:get("far"))
	Camera.set_near_range(mod.shadow_cull_camera, cameraHeight - origingal_camera_position.z - mod:get("near"))
	local min = mod:get("area") * -1
	local max = mod:get("area")
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

mod.createViewport = function()
	local world = Application.main_world()
	mod.viewport = mod._create_minimap_viewport(world, "minimap", "default", 2)
	ScriptWorld.activate_viewport(world, mod.viewport)
	mod.active = true
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
	Viewport.set_data(viewport, "avoid_shading_callback", true)
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

mod.saveCamera = function(name)
	local l = table.getn(mod.camera_positions)
	local local_player_unit = Managers.player:local_player().player_unit
	local player_position = Unit.local_position(local_player_unit, 0)
	local camera = {
		pos = Vector3Box(player_position),
		near = mod:get("near"),
		far = mod:get("far"),
		size = mod:get("size"),
		area = mod:get("area"),
		height = mod:get("height"),
		name = name
	}
	mod.camera_positions[l] = camera
end

mod.restoreCamera = function(camera)
	local local_player_unit = Managers.player:local_player().player_unit
	mod:dump(camera, "camera to rstore", 2)
	local position_new = Vector3.zero()
	position_new.x = camera.pos.x
	position_new.y = camera.pos.y
	position_new.z = camera.pos.z
	Unit.teleport_local_position(local_player_unit, 0, position_new)
	mod:set("near", camera.near)
	mod:set("far", camera.far)
	mod:set("size", camera.size)
	mod:set("area", camera.area)
	mod:set("height", camera.height)
end

mod.switchThroughCameras = function(i)
	local l = table.getn(mod.camera_positions)
	local cameraIndex = i or mod.current_camera_index or 0
	--[[ 	if not cameraIndex then
		mod:echo("no camera to jump to, please create one with m_addC")
		return
	end
 ]] local camera =
		mod.camera_positions[cameraIndex]
	mod:restoreCamera(camera)
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
	if
		key == "area" or key == "size" or key == "csize" or key == "near" or key == "far" or key == "offset" or
			key == "height"
	 then
		mod:set(key, value)
	elseif key == "pos" then
		mod:set("followPlayer", false)
		mod:saveCamera(value)
	else
		mod:echo(key .. " is not a supported")
	end
end

mod:command("m_debug", "Shows debug stuff for Minimap mod", mod.print_debug)
mod:command("m_set", "Sets specific values for Minimap", mod.setProps)
mod:command("m_create", "Saves current camera settings Minimap", mod.saveCamera)
mod:command("m_load", "Loads camera with given index Minimap", mod.switchThroughCameras)

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
