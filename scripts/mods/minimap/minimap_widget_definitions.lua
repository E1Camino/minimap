local mod = get_mod("minimap")

local MinimapUIElement = {
    passes = {
        {
            style_id = "m_viewport",
            pass_type = "m_viewport",
            content_id = "m_viewport"
        },
        {
            pass_type = "hotspot",
            content_id = "button_hotspot"
        }
    }
}
