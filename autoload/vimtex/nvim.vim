" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#nvim#check_treesitter(buf, ...) abort " {{{1
  if empty(getbufvar(a:buf, '&syntax')) && luaeval('require("vim.treesitter.highlighter").active[_A[1]] ~= nil', [a:buf])
    call vimtex#log#error('Syntax highlighting is controlled by Tree-sitter!')
  endif
endfunction

" }}}1
