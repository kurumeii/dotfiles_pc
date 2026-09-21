require("mini.deps").add("neovim/nvim-lspconfig")
local utils = require("config.utils")
-- LspAttach
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
  callback = function(args)
    ---@type lsp.ClientCapabilities
    local capabilities = vim.tbl_extend(
      "force",
      vim.lsp.protocol.make_client_capabilities(),
      vim.g.mini.completion and require("mini.completion").get_lsp_capabilities() or {},
      {
        textDocument = {
          completion = {
            completionItem = {
              snippetSupport = true,
            },
          },
          foldingRange = {
            dynamicRegistration = false,
            lineFoldingOnly = true,
          },
        },
        workspace = {
          fileOperations = {
            didRename = true,
            willRename = true,
          },
          didChangeWatchedFiles = {
            dynamicRegistration = true,
          },
        },
      }
    )

    utils.setup_lsp({
      capabilities = capabilities,
    })

    vim.diagnostic.config({
      severity_sort = true,
      float = { border = "rounded", source = "if_many" },
      underline = { severity = vim.diagnostic.severity.ERROR },
      signs = {
        text = {
          [vim.diagnostic.severity.ERROR] = mininvim.icons.error,
          [vim.diagnostic.severity.WARN] = mininvim.icons.warn,
          [vim.diagnostic.severity.INFO] = mininvim.icons.info,
          [vim.diagnostic.severity.HINT] = mininvim.icons.hint,
        },
      },
      virtual_text = {
        source = "if_many",
        spacing = 2,
        format = function(diagnostic)
          local diagnostic_message = {
            [vim.diagnostic.severity.ERROR] = diagnostic.message,
            [vim.diagnostic.severity.WARN] = diagnostic.message,
            [vim.diagnostic.severity.INFO] = diagnostic.message,
            [vim.diagnostic.severity.HINT] = diagnostic.message,
          }
          return diagnostic_message[diagnostic.severity]
        end,
      },
    })

    utils.map("n", utils.L("ca"), vim.lsp.buf.code_action, "Code action")
    utils.map("n", utils.L("cd"), vim.diagnostic.open_float, "Code show diagnostic")
    utils.map("n", utils.L("cr"), vim.lsp.buf.rename, "LSP: rename")
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client.name == "vtsls" then
      utils.map("n", utils.L("co"), utils.action("source.organizeImports"), "[TS] Organize imports")
      utils.map("n", utils.L("cv"), utils.command("typescript.selectTypeScriptVersion"), "[TS] Select ts version")
    end
    if client and client.name == "tailwindcss" then
      vim.api.nvim_create_autocmd("BufWritePre", {
        group = vim.api.nvim_create_augroup("tailwind-canonical-" .. args.buf, { clear = true }),
        buffer = args.buf,
        callback = function()
          local bufnr = vim.api.nvim_get_current_buf()
          local diags = vim.diagnostic.get(bufnr)
          local edits = {}

          for _, diag in ipairs(diags) do
            if diag.code == "suggestCanonicalClasses"
              or (diag.message and diag.message:match("can be written as"))
            then
              local old_class, new_class =
                diag.message:match("The class `([^`]+)` can be written as `([^`]+)`")
              if old_class and new_class then
                table.insert(edits, {
                  lnum = diag.lnum,
                  col = diag.col,
                  end_lnum = diag.end_lnum or diag.lnum,
                  end_col = diag.end_col or (diag.col + #old_class),
                  new_class = new_class,
                })
              end
            end
          end

          if #edits == 0 then return end

          table.sort(edits, function(a, b)
            if a.lnum ~= b.lnum then return a.lnum > b.lnum end
            return a.col > b.col
          end)

          for _, edit in ipairs(edits) do
            vim.api.nvim_buf_set_text(
              bufnr, edit.lnum, edit.col, edit.end_lnum, edit.end_col,
              { edit.new_class }
            )
          end
        end,
      })
    end
    utils.map("n", "<s-k>", vim.lsp.buf.hover)
    utils.map("i", "<c-/", vim.lsp.buf.signature_help)

    -- Select an active LSP client, then restart or disable it
    local function select_lsp(action, cmd)
      return function()
        local clients = vim.lsp.get_clients({ bufnr = 0 })
        if #clients == 0 then
          utils.notify("No active LSP clients", "WARN")
          return
        end
        vim.ui.select(clients, {
          prompt = action .. " LSP:",
          format_item = function(item)
            return item.name
          end,
        }, function(choice)
          if not choice then
            return
          end
          vim.cmd(cmd .. " " .. choice.name)
        end)
      end
    end

    utils.map("n", utils.L("cR"), select_lsp("Restart", "lsp restart"), "LSP: restart")
    utils.map("n", utils.L("cD"), select_lsp("Disable", "lsp disable"), "LSP: disable")
  end,
})

vim.api.nvim_create_autocmd({ "BufReadPre" }, {
  once = true,
  callback = function()
    vim.cmd([[MasonToolsInstallSync]])
  end,
})
