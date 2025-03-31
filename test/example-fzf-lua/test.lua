local fzf_lua_path = "./fzf-lua"
if not vim.uv.fs_stat(fzf_lua_path) then
  vim.fn.system {
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/ibhagwan/fzf-lua/",
    fzf_lua_path,
  }
end
vim.opt.rtp:prepend(fzf_lua_path)

vim.opt.runtimepath:prepend "../.."
vim.opt.runtimepath:append "../../after"
vim.cmd [[filetype plugin indent on]]

vim.keymap.set("n", "q", "<cmd>qall!<cr>")
vim.keymap.set("n", "<localleader>lt", function()
  return require("vimtex.fzf-lua").run()
end)

vim.g.vimtex_cache_persistent = false

vim.cmd.edit "main.tex"
