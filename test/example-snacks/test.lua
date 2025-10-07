local snacks_path = "./snacks"
if not vim.uv.fs_stat(snacks_path) then
  vim.fn.system {
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/snacks.nvim/",
    snacks_path,
  }
end
vim.opt.rtp:prepend(snacks_path)

vim.opt.runtimepath:prepend "../.."
vim.opt.runtimepath:append "../../after"
vim.cmd [[filetype plugin indent on]]

vim.keymap.set("n", "q", "<cmd>qall!<cr>")
vim.keymap.set("n", "<localleader>lt", function()
  return require("vimtex.snacks").toc()
end)

vim.g.vimtex_cache_persistent = false

vim.cmd.edit "main.tex"
