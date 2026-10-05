local utils = require("config.utils")
local MiniMap = require("mini.map")
MiniMap.setup({
	integrations = {
		MiniMap.gen_integration.builtin_search(),
		MiniMap.gen_integration.diff(),
		MiniMap.gen_integration.diagnostic(),
	},
	symbols = {
		scroll_line = "▶",
		scroll_view = "┃",
	},
})
utils.map("n", utils.L("mm"), MiniMap.toggle, "Toggle minimap")
