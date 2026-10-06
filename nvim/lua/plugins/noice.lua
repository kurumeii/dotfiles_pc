local enabled = vim.g.noice
if enabled then
	require("config.deps").add({
		{ source = "MunifTanjim/nui.nvim", lazy = true },
		{ source = "folke/noice.nvim", lazy = true },
	})
end

return {
	"noice.nvim",
	enabled = enabled,
	event = "DeferredUIEnter",
	before = function()
		vim.cmd.packadd("nui.nvim")
	end,
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
