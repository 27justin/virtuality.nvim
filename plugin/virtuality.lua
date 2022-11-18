

vim.api.nvim_exec([[
augroup virtuality
  autocmd!
  autocmd BufReadPost,BufWritePost,BufEnter,BufWinEnter,LspAttach * lua require'virtuality'.update()
augroup END
]], false)

-- Create the color group for the virtual text
vim.cmd("highlight default link VirtualityInlayHint Comment")

