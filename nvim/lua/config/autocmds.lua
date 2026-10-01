local utils = require("config.utils")

-- Startup time
vim.api.nvim_create_autocmd("VimEnter", {
	callback = function()
		vim.g.start_time_finish = vim.uv.hrtime()
	end,
})

-- Lualine doesn't redraw on its own when macro recording starts/stops.
vim.api.nvim_create_autocmd({ "RecordingEnter", "RecordingLeave" }, {
	callback = function()
		-- RecordingLeave fires before reg_recording() is cleared, so defer the refresh.
		vim.schedule(function()
			local ok, lualine = pcall(require, "lualine")
			if ok then
				lualine.refresh()
			end
		end)
	end,
})

utils.set_ft("tmpl", "bash")

vim.api.nvim_create_autocmd("FileType", {
	pattern = "json,jsonc",
	callback = function()
		vim.bo.commentstring = "// %s"
	end,
})
