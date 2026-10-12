local M = {}

local config_files = { "biome.json", "biome.jsonc" }

--- Find nearest biome config walking up from the file.
---@param filename string
---@return string|nil
function M.config_path(filename)
	return vim.fs.find(config_files, { path = filename, upward = true })[1]
end

--- nvim-lint ships "biomejs", not "biome". Alias it and only run when the repo has a biome config.
---@return table
function M.linter()
	return vim.tbl_deep_extend("force", vim.deepcopy(require("lint.linters.biomejs")), {
		condition = function(ctx)
			return M.config_path(ctx.filename) ~= nil
		end,
	})
end

return M
