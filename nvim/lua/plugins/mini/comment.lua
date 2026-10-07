return {
	"JoosepAlviste/nvim-ts-context-commentstring",
	event = "DeferredUIEnter",
	after = function()
		require("ts_context_commentstring").setup({
			enable_autocmd = false,
		})
		require("mini.comment").setup({
			options = {
				custom_commentstring = function()
					return require("ts_context_commentstring").calculate_commentstring() or vim.bo.commentstring
				end,
			},
		})

		-- Commentstring: JSON has none, so use `//` for mini.comment
		vim.api.nvim_create_autocmd("FileType", {
			pattern = { "json", "jsonc" },
			callback = function()
				vim.bo.commentstring = "// %s"
			end,
		})
	end,
}
