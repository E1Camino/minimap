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
			setting_name = "offsetplus",
			widget_type = "keybind",
			text = "increase offset",
			default_value = {},
			action = "increaseOffset"
		},
		{
			setting_name = "offsetminus",
			widget_type = "keybind",
			text = "decrease offset",
			default_value = {},
			action = "decreaseOffset"
		},
		{
			setting_name = "offsetspeedPlus",
			widget_type = "keybind",
			text = "speed for offset changes",
			default_value = {},
			action = "increaseOffsetSpeed"
		},
		{
			setting_name = "offsetspeedPlus",
			widget_type = "keybind",
			text = "speed for offset changes",
			default_value = {},
			action = "decreaseOffsetSpeed"
		},
		{
			setting_name = "followPlayer",
			widget_type = "checkbox",
			text = "follow the player",
			unit_text = "",
			default_value = true
		},
		{
			setting_name = "offset",
			widget_type = "numeric",
			text = "offset above player",
			unit_text = "",
			range = {0, 200},
			default_value = 1
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
			setting_name = "size",
			widget_type = "numeric",
			text = "min x rect",
			unit_text = "",
			range = {1, 100},
			default_value = 10
		}
	}
}
