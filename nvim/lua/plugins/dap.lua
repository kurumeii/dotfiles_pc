require("config.deps").add({
	{ source = "mfussenegger/nvim-dap", lazy = true },
	{ source = "nvim-neotest/nvim-nio", lazy = true },
	{ source = "rcarriga/nvim-dap-ui", lazy = true },
	{ source = "theHamsta/nvim-dap-virtual-text", lazy = true },
	{ source = "jay-babu/mason-nvim-dap.nvim", lazy = true },
})

return {
	"nvim-dap",
	cmd = { "DapContinue", "DapToggleBreakpoint", "DapShowLog" },
	keys = {
		{ "<F5>", desc = "Debug: Start/Continue" },
		{ "<F10>", desc = "Debug: Step Into" },
		{ "<F11>", desc = "Debug: Step Over" },
		{ "<F12>", desc = "Debug: Step Out" },
		{ "<leader>db", desc = "Debug: Toggle Breakpoint" },
		{ "<leader>dB", desc = "Debug: Set Breakpoint" },
		{ "<leader>du", desc = "Debug: Toggle UI" },
		{ "<leader>dl", desc = "Debug: Show log" },
		{ "<leader>dr", desc = "Debug: Toggle REPL" },
		{ "<leader>dt", desc = "Debug: Terminate" },
		{ "<leader>dh", mode = { "n", "v" }, desc = "Debug: widget hover" },
		{ "<leader>dp", mode = { "n", "v" }, desc = "Debug: widget preview" },
		{ "<leader>df", desc = "Debug: widget float frames" },
		{ "<leader>ds", desc = "Debug: widget float scopes" },
	},
	before = function()
		-- mason-nvim-dap needs mason, which the lspconfig spec sets up
		require("lz.n").trigger_load("nvim-lspconfig")
		vim.cmd.packadd("nvim-nio")
		vim.cmd.packadd("nvim-dap-ui")
		vim.cmd.packadd("nvim-dap-virtual-text")
		vim.cmd.packadd("mason-nvim-dap.nvim")
	end,
	after = function()
		local dap = require("dap")
		local dapui = require("dapui")
		local dap_widget = require("dap.ui.widgets")
		local utils = require("config.utils")
		dap.set_log_level("TRACE")

		-- Signs
		for name, icon in pairs(_G.mininvim.icons.dap) do
			local sign_name = "Dap" .. name
			vim.fn.sign_define(sign_name, { text = icon, texthl = sign_name, linehl = "", numhl = "" })
		end

		require("mason-nvim-dap").setup({
			ensure_installed = {},
			automatic_installation = false,
		})

		require("nvim-dap-virtual-text").setup({
			enabled = true,
		})
		dapui.setup()

		for _, adapter in ipairs({ "pwa-node", "pwa-chrome", "pwa-msedge", "node-terminal", "pwa-extensionHost" }) do
			dap.adapters[adapter] = {
				type = "server",
				host = "localhost",
				port = "${port}",
				executable = {
					command = "js-debug-adapter",
					args = {
						"${port}",
					},
				},
			}
		end

		-- VSCode-like configurations for JS/TS
		local js_languages = { "javascript", "typescript", "javascriptreact", "typescriptreact" }

		for _, language in ipairs(js_languages) do
			dap.configurations[language] = {
				{
					type = "pwa-node",
					request = "launch",
					name = "Launch file",
					program = "${file}",
					cwd = "${workspaceFolder}",
				},
				{
					type = "pwa-node",
					request = "attach",
					name = "Attach",
					processId = require("dap.utils").pick_process,
					cwd = "${workspaceFolder}",
				},
				{
					type = "pwa-chrome",
					request = "launch",
					name = 'Start Chrome with "localhost"',
					url = "http://localhost:3000",
					webRoot = "${workspaceFolder}",
					userDataDir = "${workspaceFolder}/.vscode/pwa-chrome-debug",
				},
			}
		end

		-- Keymaps
		utils.map("n", "<F5>", dap.continue, "Debug: Start/Continue")
		utils.map("n", "<F10>", dap.step_into, "Debug: Step Into")
		utils.map("n", "<F11>", dap.step_over, "Debug: Step Over")
		utils.map("n", "<F12>", dap.step_out, "Debug: Step Out")
		utils.map("n", "<leader>db", dap.toggle_breakpoint, "Debug: Toggle Breakpoint")
		utils.map("n", "<leader>dB", function()
			vim.ui.input({ prompt = "Breakpoint condition" }, function(condition)
				if condition then
					dap.set_breakpoint(condition)
				end
			end)
		end, "Debug: Set Breakpoint")
		utils.map("n", "<leader>du", dapui.toggle, "Debug: Toggle UI")
		utils.map("n", "<leader>dl", utils.C("DapShowLog"), "Debug: Toggle UI")

		utils.map("n", "<leader>dp", function()
			vim.ui.input({ prompt = "Log point message" }, function(message)
				if message then
					dap.set_breakpoint(nil, nil, message)
				end
			end)
		end, "Debug: Set Log Point")
		utils.map("n", "<leader>dr", dap.repl.toggle, "Debug: Toggle REPL")
		utils.map("n", "<leader>dt", dap.terminate, "Debug: Terminate")
		utils.map({ "n", "v" }, utils.L("dh"), dap_widget.hover, "Debug: widget hover")
		utils.map({ "n", "v" }, utils.L("dp"), dap_widget.preview, "Debug: widget preview")
		utils.map({ "n" }, utils.L("df"), function()
			dap_widget.centered_float(dap_widget.frames)
		end, "Debug: widget float frames")
		utils.map({ "n" }, utils.L("ds"), function()
			dap_widget.centered_float(dap_widget.scopes)
		end, "Debug: widget float scopes")

		-- Dap UI setup
		dap.listeners.after.event_initialized["dapui_config"] = dapui.open
		dap.listeners.before.event_terminated["dapui_config"] = dapui.close
		dap.listeners.before.event_exited["dapui_config"] = dapui.close
	end,
}
