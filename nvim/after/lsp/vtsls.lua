local shared = {
	updateImportsOnFileMove = { enabled = "always" },
	suggest = {
		completeFunctionCalls = true,
	},
	inlayHints = {
		enumMemberValues = { enabled = true },
		functionLikeReturnTypes = { enabled = true },
		parameterNames = { enabled = "literals" },
		parameterTypes = { enabled = true },
		propertyDeclarationTypes = { enabled = true },
		variableTypes = { enabled = false },
	},
	preferences = {
		importModuleSpecifier = "non-relative",
		preferTypeOnlyAutoImports = true,
	},
	preferGoToSourceDefinition = true,
	format = { enable = false },
	tsserver = { maxTsServerMemory = 8192 },
	surveys = { enabled = false },
}

return {
	settings = {
		vtsls = {
			enableMoveToFileCodeAction = true,
			autoUseWorkspaceTsdk = true,
			experimental = {
				maxInlayHintLength = 30,
				completion = {
					enableServerSideFuzzyMatch = true,
				},
			},
		},
		typescript = vim.tbl_deep_extend("force", vim.deepcopy(shared), {
			tsdk = vim.uv.fs_stat(vim.uv.cwd() .. "/.yarn/sdks/typescript/lib") and "./.yarn/sdks/typescript/lib" or nil,
		}),
		javascript = vim.deepcopy(shared),
	},
}
