" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#nvim#check_treesitter(...) abort " {{{1
lua <<EOF
  local highlighter = require "vim.treesitter.highlighter"
  local bufnr = vim.api.nvim_get_current_buf()
  if highlighter.active[bufnr] then
    vim.fn['vimtex#log#error'](
      'Syntax highlighting is controlled by Tree-sitter!'
    )
  end
EOF
endfunction

" }}}1
