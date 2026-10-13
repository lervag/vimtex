local NuiTree = require "nui.tree"
----TODO: make this actually lua?
local entries = vim.cmd [[vim.eval ('vimtex#parser#toc()']]
local tree = NuiTree { bufnr = bufnr, nodes = entries }
tree:render()
