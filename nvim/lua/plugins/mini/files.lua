return {
	"mini-files",
	virtual = true,
	enabled = vim.g.mini.explorer,
	priority = 960,
	after = function()
		local utils = require("config.utils")

		-- Git status markers, drawn as virtual text on the right of each entry
		local git_file, git_dir = {}, {}
		local git_root, git_loaded = nil, false
		local ns = vim.api.nvim_create_namespace("mini.files.git")
		local rendered = {}

		local function git_mark(code)
			if code:find("U") or code == "AA" or code == "DD" then
				return mininvim.icons.error, "DiagnosticError"
			end
			if code:find("D") then
				return mininvim.icons.git_remove, "MiniIconsRed"
			end
			if code == "??" or code:find("A") then
				return mininvim.icons.git_add, "MiniIconsGreen"
			end
			return mininvim.icons.git_edit, "MiniIconsYellow"
		end

		local function git_render(buf_id)
			rendered[buf_id] = true
			vim.api.nvim_buf_clear_namespace(buf_id, ns, 0, -1)
			-- only directory buffers carry `/id/` lines; file previews have none
			local first_line = vim.api.nvim_buf_get_lines(buf_id, 0, 1, false)[1]
			if not first_line or not first_line:match("^/%d+") then
				return
			end
			for i = 1, vim.api.nvim_buf_line_count(buf_id) do
				local fs_entry = MiniFiles.get_fs_entry(buf_id, i)
				local code = fs_entry
					and (git_file[fs_entry.path] or (fs_entry.fs_type == "directory" and git_dir[fs_entry.path] and "M"))
				if code then
					local glyph, hl = git_mark(code)
					vim.api.nvim_buf_set_extmark(buf_id, ns, i - 1, 0, {
						virt_text = { { glyph, hl } },
						virt_text_pos = "right_align",
					})
				end
			end
		end

		local function git_rerender()
			for buf_id in pairs(rendered) do
				-- a buffer can be valid but no longer registered with mini.files
				if not vim.api.nvim_buf_is_valid(buf_id) or not pcall(git_render, buf_id) then
					rendered[buf_id] = nil
				end
			end
		end

		-- shortcut: renames and paths holding quotes or " -> " are misparsed, switch to `-z` output if that bites
		local function git_load(root, force)
			if not root or (root == git_root and git_loaded and not force) then
				return
			end
			git_root, git_loaded = root, true

			vim.system({ "git", "-C", root, "status", "--porcelain" }, { text = true }, function(obj)
				vim.schedule(function()
					-- a newer load for another root may have superseded this one
					if obj.code ~= 0 or root ~= git_root then
						return
					end
					local files, dirs, norm_root = {}, {}, root:gsub("\\", "/")
					for _, line in ipairs(vim.split(obj.stdout, "\n", { trimempty = true })) do
						local rel = line:match(" %-> (.*)$") or line:sub(4)
						if rel:sub(1, 1) == '"' then
							local ok, decoded = pcall(vim.json.decode, rel)
							rel = ok and decoded or rel:gsub('^"(.*)"$', "%1")
						end
						rel = rel:gsub("/+$", "")
						if rel ~= "" then
							local abs = norm_root .. "/" .. rel
							files[abs] = line:sub(1, 2)
							local parent = abs:match("(.+)/[^/]+$")
							while parent and #parent > #norm_root do
								dirs[parent] = true
								parent = parent:match("(.+)/[^/]*$")
							end
						end
					end
					git_file, git_dir = files, dirs
					git_rerender()
				end)
			end)
		end

		local function entry_filter(fs_entry)
			return utils.toggle_dotfiles(vim.g.mini.show_dotfiles, fs_entry)
		end

		require("mini.files").setup({
			windows = {
				preview = true,
				width_focus = 30,
				width_preview = 30,
			},
			mappings = {
				go_out_plus = "h",
				synchronize = "<c-s>",
				show_help = "?",
			},
			content = {
				filter = entry_filter,
			},
		})

		utils.map("n", utils.L("e"), function()
			local ok = pcall(MiniFiles.open, vim.api.nvim_buf_get_name(0), false)
			if not ok then
				MiniFiles.open(nil, false)
			end
		end, "Open explore")

		utils.map("n", utils.L("E"), function()
			local ok = pcall(MiniFiles.open, nil, false)
			if not ok then
				MiniFiles.open(nil, false)
			end
		end, "Open explore (home)")

		-- Mini Files
		vim.api.nvim_create_autocmd("User", {
			pattern = "MiniFilesBufferCreate",
			callback = function(args)
				local buf_id = args.data.buf_id
				utils.map("n", ".", function()
					vim.g.mini.show_dotfiles = not vim.g.mini.show_dotfiles
					MiniFiles.refresh({ content = { filter = entry_filter } })
				end, "Toggle hidden files", { buffer = buf_id })
				utils.map_split(buf_id, "<C-w>s", "horizontal", false)
				utils.map_split(buf_id, "<C-w>v", "vertical", false)

				local path = vim.api.nvim_buf_get_name(buf_id)
				git_load(path ~= "" and vim.fs.root(path, ".git") or nil, false)
			end,
		})

		vim.api.nvim_create_autocmd("User", {
			pattern = "MiniFilesBufferUpdate",
			callback = function(args)
				git_render(args.data.buf_id)
			end,
		})

		vim.api.nvim_create_autocmd("User", {
			pattern = "MiniFilesActionRename",
			callback = function(event)
				utils.rename_file(event.data.from, event.data.to)
			end,
		})

		vim.api.nvim_create_autocmd("User", {
			pattern = "MiniFilesAction*",
			callback = function()
				git_load(git_root, true)
			end,
		})

		vim.api.nvim_create_autocmd("BufWritePost", {
			callback = function()
				-- only pay for `git status` while the explorer is actually open
				if MiniFiles.get_explorer_state() then
					git_load(git_root, true)
				end
			end,
		})
	end,
}
