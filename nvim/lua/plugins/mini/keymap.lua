require("mini.keymap").setup()
local map_combo = MiniKeymap.map_combo
local map_multistep = MiniKeymap.map_multistep
local mode = { "i", "t", "c", "s", "x" }
local utils = require("config.utils")

map_combo(mode, "jk", "<bs><bs><esc>")
map_combo(mode, "kj", "<bs><bs><esc>")
map_combo(mode, "qq", "<BS><BS><C-\\><C-n>")
map_combo(mode, "qk", "<BS><BS><C-\\><C-n>")
map_multistep("i", "<cr>", {
	"pmenu_accept",
	"minipairs_cr",
})

local deps = require("config.deps")
utils.map("n", utils.L("pu"), deps.update, "Deps: Package update")
utils.map("n", utils.L("pm"), utils.C("Mason"), "Mason: Package")
utils.map("n", utils.L("pc"), deps.clean, "Deps: Package Clean")
utils.map("n", utils.L("ps"), deps.snap_load, "Deps: Restore to lockfile")
