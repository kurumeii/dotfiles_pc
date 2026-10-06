require("config.deps").add({ source = "windwp/nvim-ts-autotag", lazy = true })

return {
	"nvim-ts-autotag",
	event = "InsertEnter",
	after = function()
		require("nvim-ts-autotag").setup({
			opts = {
				enable_close = true,
				enable_rename = true,
				enable_close_on_slash = false,
			},
		})
	end,
}
