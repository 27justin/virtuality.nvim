-- main module file
local module = require("virtuality.module")

local namespace = vim.api.nvim_create_namespace("virtuality")
module.namespace = namespace

local M = {}

M.update = function(bufnr)
	if bufnr == nil then
		-- Get current buffer if not given
		bufnr = vim.api.nvim_get_current_buf()
	end
	-- Check if this buffer has a variable "virtuality" set to true
	local s, buffer_status = pcall(vim.api.nvim_buf_get_var, bufnr, "virtuality")
	if s == true and buffer_status == true then
		module.update(bufnr)
	else 
		if s == false or buffer_status == false then
			-- Update this buffer and set the virtuality variable to true
			module.update(bufnr)
			vim.api.nvim_buf_set_var(bufnr, "virtuality", true)
		else
			-- Buffer doesn't have a LSP that supports inlay hints
		end
	end
end


M.check = function()
	-- Check whether this buffer has a LSP that supports inlay hints
	local bufnr = vim.api.nvim_get_current_buf()
	print("Checking if the current buffer has a LSP that supports inlay hints...")
	-- Since the LSP.supports_method is useless:
	-- https://github.com/neovim/neovim/issues/18686
	-- (why even bother adding a function to "check" for support if it always returns true....)
	-- Thus we'll just call every LSP and ask for textDocument/inlayHint, if it returns an error, we'll assume it doesn't support it.
	for i, v in ipairs(vim.lsp.buf_get_clients(bufnr)) do
		local params = {
			textDocument = vim.lsp.util.make_text_document_params(),
			range = {
				start = { line = 0, character = 0 },
				["end"] = { line = vim.api.nvim_buf_line_count(bufnr), character = 0 },
			},
		}
		v.request(
			"textDocument/inlayHint",
			params,
			function(err, response, ctx) 
				if err then
					print("LSP " .. v.name .. " doesn't support inlay hints.")
					vim.notify("LSP " .. v.name .. " doesn't support inlay hints.", vim.log.levels.ERROR, { title = "Virtuality" })
				else
					print("LSP " .. v.name .. " supports inlay hints.")
					vim.notify("LSP " .. v.name .. " supports inlay hints.", vim.log.levels.INFO, { title = "Virtuality" })
				end
			end)
	end
end



return M
