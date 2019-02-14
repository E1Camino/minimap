local mod = get_mod("minimap")

-- Everything here is optional. You can remove unused parts.
return {
	name = "minimap", -- Readable mod name
	description = mod:localize("mod_description"), -- Mod description
	is_togglable = true, -- If the mod can be enabled/disabled
	is_mutator = false, -- If the mod is mutator
	mutator_settings = {}, -- Extra settings, if it's mutator
	options = {
		widgets = {
			-- Widget settings for the mod options menu
			{
				setting_id = "open_minimap_view",
				type = "keybind",
				keybind_trigger = "pressed", -- "held" when ready
				keybind_type = "function_call",
				function_name = "toggleMap",
				default_value = {}
			},
			{
				setting_id = "toggle_debug_mode",
				type = "keybind",
				keybind_trigger = "pressed", -- "held" when ready
				keybind_type = "function_call",
				function_name = "toggle_debug_mode",
				default_value = {}
			},
			{
				setting_id = "debug_mode",
				type = "checkbox",
				text = "debug mode",
				default_value = false
			},
			{
				setting_id = "mask_group",
				type = "group",
				sub_widgets = {
					{
						setting_id = "maskMode",
						type = "keybind",
						keybind_trigger = "pressed",
						keybind_type = "function_call",
						function_name = "toggle_mask_mode",
						text = "toggle interactive mask mode",
						default_value = {}
					},
					{
						setting_id = "add_point",
						type = "keybind",
						keybind_trigger = "pressed",
						keybind_type = "function_call",
						function_name = "add_point",
						text = "add point to current mask",
						default_value = {}
					},
					{
						setting_id = "add_last_point",
						type = "keybind",
						keybind_trigger = "pressed",
						keybind_type = "function_call",
						function_name = "add_last_point",
						text = "add last point to current mask triangle strip",
						default_value = {}
					},
					{
						setting_id = "toggle_single_triangle_mode",
						type = "keybind",
						keybind_trigger = "pressed",
						keybind_type = "function_call",
						function_name = "toggle_interactive_triangle_mode",
						text = "toggle between single and multi triangle mode",
						default_value = {}
					},
					{
						setting_id = "remove_point",
						type = "keybind",
						keybind_trigger = "pressed",
						keybind_type = "function_call",
						function_name = "remove_point",
						text = "remove point from current mask",
						default_value = {}
					}
				}
			},
			{
				setting_id = "keys_group",
				type = "group",
				sub_widgets = {
					{
						setting_id = "debug",
						type = "keybind",
						keybind_trigger = "pressed",
						keybind_type = "function_call",
						function_name = "print_debug",
						text = "print some debug stuff into the chat",
						default_value = {}
					},
					{
						setting_id = "toggleProps",
						type = "keybind",
						keybind_trigger = "pressed",
						keybind_type = "function_call",
						function_name = "toggleProp",
						text = "toggle which prop should be manipulated with keybindings",
						default_value = {}
					},
					{
						setting_id = "offsetplus",
						type = "keybind",
						keybind_trigger = "pressed",
						keybind_type = "function_call",
						function_name = "increaseProp",
						text = "increase offset",
						default_value = {}
					},
					{
						setting_id = "offsetminus",
						type = "keybind",
						keybind_trigger = "pressed",
						keybind_type = "function_call",
						function_name = "decreaseProp",
						text = "decrease offset",
						default_value = {}
					},
					{
						setting_id = "offsetspeedPlus",
						type = "keybind",
						keybind_trigger = "pressed",
						keybind_type = "function_call",
						function_name = "increasePropSpeed",
						text = "increase speed for offset changes",
						default_value = {}
					},
					{
						setting_id = "offsetspeedMinus",
						type = "keybind",
						keybind_trigger = "pressed",
						keybind_type = "function_call",
						function_name = "decreasePropSpeed",
						text = "decrease speed for offset changes",
						default_value = {}
					}
				}
			},
			{
				setting_id = "map_group",
				type = "group",
				sub_widgets = {
					{
						setting_id = "near",
						type = "numeric",
						text = "near",
						unit_text = "",
						range = {0, 100000},
						default_value = 12000
					},
					{
						setting_id = "far",
						type = "numeric",
						text = "far",
						unit_text = "",
						range = {0, 5000},
						default_value = 1000
					},
					{
						setting_id = "area",
						type = "numeric",
						text = "half the size of the area that should be rendered in the map",
						unit_text = "",
						range = {1, 100},
						default_value = 10
					},
					{
						setting_id = "size",
						type = "numeric",
						text = "size of the map widget",
						unit_text = "%",
						range = {1, 100},
						default_value = 40
					},
					{
						setting_id = "height",
						type = "numeric",
						text = "camera height",
						unit_text = "",
						range = {40, 200},
						default_value = 90
					}
				}
			}
		}
	}
	-- 	custom_gui_textures = {
	-- 		textures = {
	-- 			"materials/mods/minimap/paper",
	-- 			"materials/mods/minimap/concrete"
	-- 		},
	-- 		ui_renderer_injections = {
	-- 			{
	-- 				"ingame_ui",
	-- 				"materials/mods/minimap/paper",
	-- 				"materials/mods/minimap/concrete"
	-- 			}
	-- 		}
	-- 	}
	-- }
}
