local biome = require("config.lint.biome")

-- The stock biome root_dir treats any package.json mentioning "biomejs"
-- (e.g. `@biomejs/biome` in devDependencies) as a Biome project, so the LSP
-- attached even without a biome.json and formatted/linted with defaults.
-- Require a real config file so Biome only starts where it's enabled.
return {
	root_dir = function(bufnr, on_dir)
		local filename = vim.api.nvim_buf_get_name(bufnr)
		if filename == "" then
			return
		end
		local config = biome.config_path(filename)
		if not config then
			return
		end
		-- Prefer the project root (lockfile/.git) like upstream, but never a
		-- directory below the config file itself.
		local config_dir = vim.fs.dirname(config)
		local root = vim.fs.root(filename, {
			"package-lock.json",
			"yarn.lock",
			"pnpm-lock.yaml",
			"bun.lockb",
			"bun.lock",
			"deno.lock",
			".git",
		})
		if not root or not vim.startswith(config_dir .. "/", root .. "/") then
			root = config_dir
		end
		on_dir(root)
	end,
}
