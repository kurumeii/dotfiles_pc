return {
	"folke/noice.nvim",
	enabled = vim.g.noice,
	dependencies = { "MunifTanjim/nui.nvim" },
	event = "DeferredUIEnter",
	after = function()
		require("noice").setup({
			cmdline = {
				view = "cmdline_popup",
			},
			lsp = {
				progress = { enabled = false },
				hover = { enabled = false },
				signature = { enabled = false },
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
	end,
}
