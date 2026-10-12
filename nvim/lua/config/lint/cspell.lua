local utils = require("config.utils")
local valid_config_file = {
	".cspell.json",
	".cspell.yaml",
	".cspell.yml",
	".cspell.jsonc",
	".cspell.config.yaml",
	".cspell.config.yml",
	"cspell.json",
	"cspell.yaml",
	"cspell.yml",
	"cspell.jsonc",
	"cspell.config.yaml",
	"cspell.config.yml",
}

local H = {}

--- Find nearest cspell config walking up from the file (current buffer, else cwd).
---@param filename? string
---@return string|nil
function H.config_path(filename)
	if not filename or filename == "" then
		filename = vim.api.nvim_buf_get_name(0)
	end
	if filename == "" then
		filename = vim.uv.cwd() or "."
	end
	return vim.fs.find(valid_config_file, { path = filename, upward = true })[1]
end

--- nvim-lint "cspell" linter that only runs when a cspell config is found.
---@return table
function H.linter()
	local linter = vim.deepcopy(require("lint.linters.cspell"))
	linter.condition = function(ctx)
		return H.config_path(ctx.filename) ~= nil
	end
	linter.args = {
		"lint",
		"--no-color",
		"--no-progress",
		"--no-summary",
		function()
			return "--config=" .. H.config_path(vim.api.nvim_buf_get_name(0))
		end,
		function()
			return "stdin://" .. vim.api.nvim_buf_get_name(0)
		end,
	}
	return linter
end

---@return CspellConfig|nil
function H.read_config()
	local file = H.config_path()
	if not file then
		utils.notify("No cspell config file found", "WARN")
		return nil
	end
	local ext = vim.fn.fnamemodify(file, ":e")
	local json_str
	if ext == "json" or ext == "jsonc" then
		json_str = table.concat(vim.fn.readfile(file), "\n")
	elseif ext == "yaml" or ext == "yml" then
		local ok, res = pcall(function()
			return vim.system({ "yq", "eval", "-o=json", file }, { text = true }):wait()
		end)
		if not ok or res.code ~= 0 then
			utils.notify("Failed to run yq: " .. (ok and res.stderr or tostring(res)), "ERROR")
			return nil
		end
		json_str = res.stdout
	else
		utils.notify("Unsupported file type", "ERROR")
		return nil
	end
	local ok, decoded = pcall(vim.json.decode, json_str)
	if not ok then
		utils.notify("Failed to decode " .. file .. ": " .. decoded, "ERROR")
		return nil
	end
	return decoded
end

---@param content CspellConfig
function H.write_config(content)
	local file_path = H.config_path()
	if not file_path then
		return
	end
	local ext = vim.fn.fnamemodify(file_path, ":e")
	local json_encoded = vim.json.encode(content)
	local out = json_encoded
	local yq_args
	if ext == "yml" or ext == "yaml" then
		yq_args = { "yq", "eval", "-P", "-" }
	elseif (ext == "json" or ext == "jsonc") and vim.fn.executable("yq") == 1 then
		-- pretty-print instead of writing minified json
		yq_args = { "yq", "eval", "-o=json", "-" }
	elseif ext ~= "json" and ext ~= "jsonc" then
		utils.notify("Unsupported file type", "ERROR")
		return
	end
	if yq_args then
		local ok, res = pcall(function()
			return vim.system(yq_args, { stdin = json_encoded, text = true }):wait()
		end)
		if not ok or res.code ~= 0 then
			utils.notify("Failed to run yq: " .. (ok and res.stderr or tostring(res)), "ERROR")
			return
		end
		out = res.stdout
	end
	local fd, err = io.open(file_path, "w")
	if not fd then
		utils.notify("Failed to open file: " .. tostring(err), "ERROR")
		return
	end
	fd:write(out)
	fd:close()
end

---@param dict_path string
---@param word string
function H.append_word(dict_path, word)
	local fd = io.open(dict_path, "a+")
	if not fd then
		utils.notify("Failed to open dictionary: " .. dict_path, "ERROR")
		return
	end
	fd:write(word .. "\n")
	fd:close()
end

---@param word table<string> | string
function H.add_to_right_place(word)
	local config = H.read_config()
	if not config then
		return
	end
	local words = type(word) == "table" and word or { word }
	local dicts = config.dictionaryDefinitions or {}
	local adaptive_add = function(dict_path)
		-- dictionary paths are relative to the config file
		if not vim.startswith(dict_path, "/") and not dict_path:match("^%a:[/\\]") then
			dict_path = vim.fs.joinpath(vim.fs.dirname(H.config_path()), dict_path)
		end
		for _, w in ipairs(words) do
			H.append_word(dict_path, w)
		end
	end
	-- If there is no dictionary
	if #dicts == 0 then
		config.words = config.words or {}
		vim.list_extend(config.words, words)
		H.write_config(config)
	elseif #dicts == 1 then
		--  If there is only one dictionary
		adaptive_add(dicts[1].path)
	else
		-- Show ui select
		vim.ui.select(dicts, {
			prompt = "Select dictionary: ",
			format_item = function(item)
				return "Add to dictionary: " .. item.name
			end,
		}, function(d)
			if not d then
				utils.notify("Cancelled", "WARN")
				return
			end
			adaptive_add(d.path)
		end)
	end
end

---@param message string
---@return string|nil
local function word_from(message)
	-- E.g. "Unknown word (word)"
	return message:match("%((.-)%)")
end

utils.map("n", utils.L("csc"), function()
	vim.ui.select({ "yaml", "json" }, {
		prompt = "Choose a cspell config file",
		format_item = function(item)
			return "Create cspell." .. item
		end,
	}, function(choice)
		if not choice then
			return utils.notify("Cancelled!", "INFO")
		end
		local ok, res = pcall(function()
			return vim.system({ "cspell", "init", "--format", choice, "--locale", "en,vi" }, { text = true }):wait()
		end)
		if ok and res.code == 0 then
			utils.notify("Created config file", "INFO")
		else
			utils.notify("Failed to create " .. choice .. " config: " .. (ok and res.stderr or tostring(res)), "ERROR")
		end
	end)
end, "Code create a config file")
utils.map("n", utils.L("csw"), function()
	vim.ui.input({ prompt = "Enter the word to add to the dictionary: " }, function(word)
		if not word or word == "" then
			return utils.notify("Cancelled input", "WARN")
		end
		H.add_to_right_place(word)
		vim.cmd("redraw")
	end)
end, "Code add word to dictionary")
utils.map("n", utils.L("csW"), function()
	local bufnr = vim.api.nvim_get_current_buf()
	local cursor = vim.api.nvim_win_get_cursor(vim.api.nvim_get_current_win())
	local diagnostics = vim.diagnostic.get(bufnr, {
		lnum = cursor[1] - 1,
		severity = "INFO",
	})
	local word ---@type string?
	for _, diagnostic in ipairs(diagnostics) do
		if diagnostic.source == "cspell" then
			word = word_from(diagnostic.message)
			if word then
				break
			end
		end
	end
	if not word then
		return utils.notify("No cspell word on this line", "INFO")
	end
	local result = vim.fn.confirm("Add " .. word .. " to dictionary ?", "&Yes\n&No", 1, "Question")
	if result ~= 1 then
		utils.notify("Cancelled", "WARN")
		return
	end
	H.add_to_right_place(word)
	vim.cmd("redraw")
end, "Code add diagnostic word to dictionary")
utils.map("n", utils.L("csa"), function()
	local bufnr = vim.api.nvim_get_current_buf()
	local diagnostics = vim.diagnostic.get(bufnr)
	local word_to_add = {} ---@type string[]
	for _, diagnostic in pairs(diagnostics) do
		if diagnostic.source == "cspell" then
			local word = word_from(diagnostic.message)
			if word then
				table.insert(word_to_add, word)
			end
		end
	end
	if #word_to_add == 0 then
		utils.notify("No word to add", "INFO")
		return
	end
	word_to_add = utils.uniq(word_to_add)
	local result = vim.fn.confirm("Add " .. #word_to_add .. " word to dictionary ?", "&Yes\n&No", 1, "Question")
	if result ~= 1 then
		utils.notify("Cancelled", "WARN")
		return
	end
	H.add_to_right_place(word_to_add)
	vim.cmd("redraw")
end, "Code add all diagnostic words to dictionary")

return H
