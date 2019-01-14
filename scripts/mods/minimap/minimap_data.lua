local mod = get_mod("minimap")

-- Everything here is optional. You can remove unused parts.
return {
	name = "minimap", -- Readable mod name
	description = mod:localize("mod_description"), -- Mod description
	is_togglable = true, -- If the mod can be enabled/disabled
	is_mutator = false, -- If the mod is mutator
	mutator_settings = {}, -- Extra settings, if it's mutator
	options_widgets = {
		-- Widget settings for the mod options menu
		{
			setting_name = "open_minimap_view",
			widget_type = "keybind",
			text = "toggle minimap",
			default_value = {},
			action = "toggleMap"
		},
		{
			setting_name = "toggleProps",
			widget_type = "keybind",
			text = "toggle which prop should be manipulated with keybindings",
			default_value = {},
			action = "toggleProp"
		},
		{
			setting_name = "debug",
			widget_type = "keybind",
			text = "print some debug stuff into the chat",
			default_value = {},
			action = "check_polygons"
		},
		{
			setting_name = "offsetplus",
			widget_type = "keybind",
			text = "increase offset",
			default_value = {},
			action = "increaseProp"
		},
		{
			setting_name = "offsetminus",
			widget_type = "keybind",
			text = "decrease offset",
			default_value = {},
			action = "decreaseProp"
		},
		{
			setting_name = "offsetspeedPlus",
			widget_type = "keybind",
			text = "increase speed for offset changes",
			default_value = {},
			action = "increasePropSpeed"
		},
		{
			setting_name = "offsetspeedMinus",
			widget_type = "keybind",
			text = "decrease speed for offset changes",
			default_value = {},
			action = "decreasePropSpeed"
		},
		{
			setting_name = "near",
			widget_type = "numeric",
			text = "near",
			unit_text = "",
			range = {0, 100000},
			default_value = 12000
		},
		{
			setting_name = "far",
			widget_type = "numeric",
			text = "far",
			unit_text = "",
			range = {0, 5000},
			default_value = 1000
		},
		{
			setting_name = "area",
			widget_type = "numeric",
			text = "half the size of the area that should be rendered in the map",
			unit_text = "",
			range = {1, 100},
			default_value = 10
		},
		{
			setting_name = "size",
			widget_type = "numeric",
			text = "size of the map widget",
			unit_text = "%",
			range = {1, 100},
			default_value = 0.4
		},
		{
			setting_name = "height",
			widget_type = "numeric",
			text = "camera height",
			unit_text = "",
			range = {40, 200},
			default_value = 90
		}
	}
}
