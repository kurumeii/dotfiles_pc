---@module 'mini.deps'
MiniDeps.add({
	source = "folke/noice.nvim",
	depends = { "MunifTanjim/nui.nvim" },
})

require("noice").setup({
	cmdline = {
		view = "cmdline_popup",
	},
	lsp = {
		progress = { enabled = false },
	},
	notify = { enabled = false },
	routes = {
		{
			filter = { event = "lsp", kind = "progress" },
			opts = { skip = true },
		},
	},
	views = {
		cmdline_popup = {
			position = {
				row = "40%",
				col = "50%",
			},
			size = {
				width = 60,
				height = "auto",
			},
		},
	},
})
