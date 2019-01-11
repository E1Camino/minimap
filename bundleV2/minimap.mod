return {
	run = function()
		fassert(rawget(_G, "new_mod"), "minimap must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("minimap", {
			mod_script       = "scripts/mods/minimap/minimap",
			mod_data         = "scripts/mods/minimap/minimap_data",
			mod_localization = "scripts/mods/minimap/minimap_localization"
		})
	end,
	packages = {
		"resource_packages/minimap/minimap"
	}
}
