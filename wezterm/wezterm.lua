---@type Wezterm
local wez = require("wezterm")
local mux = wez.mux
local config = wez.config_builder()
local padding = 3

config = {
	font = wez.font("CaskaydiaCove Nerd Font", { weight = "Regular" }),
	adjust_window_size_when_changing_font_size = false,
	font_size = 12,
	front_end = "OpenGL",
	freetype_load_target = "Light",
	line_height = 1,
	win32_system_backdrop = "Acrylic",
	window_background_opacity = 1,
	macos_window_background_blur = 1,
	default_prog = { "{{shell}}" },
	default_cursor_style = "BlinkingBlock",
	cursor_blink_rate = 500,
	enable_tab_bar = false,

	color_scheme = "Catppuccin Macchiato (Gogh)",
	enable_scroll_bar = true,
	window_decorations = wez.target_triple:find("windows") and "RESIZE" or "NONE",
	window_padding = {
		bottom = padding,
		right = padding,
		left = padding,
		top = padding,
	},
	allow_win32_input_mode = false,
}

wez.on("gui-startup", function(cmd)
	local _, _, window = mux.spawn_window(cmd or {})
	local gui_window = window:gui_window()
	-- gui_window:perform_action(wez.action.ToggleFullScreen, pane) -- Like full ass screen
	gui_window:maximize()
end)

return config
