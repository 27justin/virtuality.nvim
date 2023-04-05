local M = {}

local function retrieve_inlay_hints(bufnr, lsp)
	local params = {
		textDocument = vim.lsp.util.make_text_document_params(),
		range = {
			start = { line = 0, character = 0 },
			["end"] = { line = vim.api.nvim_buf_line_count(bufnr), character = 0 },
		},
	}

	-- Set character count for the end
	local end_char = 0
	local last_line = vim.api.nvim_buf_line_count(bufnr)
	local last_line_content = vim.api.nvim_buf_get_lines(bufnr, last_line - 1, last_line, false)[1]
	if last_line_content ~= nil then
		end_char = #last_line_content
	end

	lsp.request(
		"textDocument/inlayHint",
		params,
		function(err, response, ctx) 
			if err then
				return
			end
			if not response then
				return
			end
			-- Clear ext marks
			vim.api.nvim_buf_clear_namespace(bufnr, M.namespace, 0, -1)
			local lines_annotated = {}
			for _, hint in pairs(response) do
				-- As long as anticoncealing isn't supported, we'll only use type annotations,
				-- without this check, we'd also get parameter names annotated at EOL, which is not very readable.
				if hint.kind == 1 and lines_annotated[hint.position.line] ~= true then
					local position = hint.position
					local tooltip

					if type(hint.label) == "table" then
						tooltip = ": " .. hint.label[2].value
					else
						tooltip = hint.label
					end

					vim.api.nvim_buf_set_extmark(bufnr, M.namespace, position.line, position.character, {
						hl_group = "VirtualityInlayHint",
						virt_text = { { tooltip, { "VirtualityInlayHint" } } },
						-- TODO: change this once neovim supports IntelliJ similar anticoncealing: https://github.com/neovim/neovim/pull/9496
						virt_text_pos = "eol",
					})
					-- Another temporary fix until anticoncealing is implemented,
					-- to prevent cluttering of multiple type annotations in a single line, we only show one.
					lines_annotated[position.line] = true
				end
			end
		end)
end

M.update = function(bufnr)
	for i, v in ipairs(vim.lsp.buf_get_clients(bufnr)) do
		-- Call textDocument/inlayHint
		retrieve_inlay_hints(bufnr, v)
	end
end

return M
