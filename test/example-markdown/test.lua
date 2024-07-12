vim.opt.runtimepath:prepend "~/.local/plugged/vimtex"
vim.opt.runtimepath:append "~/.local/plugged/vimtex/after"
-- vim.opt.runtimepath:prepend "."
vim.opt.runtimepath:append "./after"

vim.cmd [[filetype plugin indent on]]
vim.cmd [[syntax enable]]

vim.keymap.set("n", "q", "<cmd>qall!<cr>")

vim.g.vimtex_cache_root = "."
vim.g.vimtex_cache_persistent = false

vim.cmd.colorscheme "morning"

vim.api.nvim_set_hl(0, "Conceal", { bg = "NONE", fg = "blue" })
vim.api.nvim_set_hl(0, "texCmdRef", { fg = "cyan" })

local au_group = vim.api.nvim_create_augroup("init", {})
vim.api.nvim_create_autocmd("CursorMoved", {
  pattern = "*",
  group = au_group,
  command = [[echo join(vimtex#syntax#stack(), ' -> ')]],
})
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  group = au_group,
  command = [[call vimtex#init()]],
})

vim.cmd.edit "test.md"
