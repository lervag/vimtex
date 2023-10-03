" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#nvim#check_treesitter(bufnr, ...) abort " {{{1
  if empty(getbufvar(a:bufnr, '&syntax')) && luaeval(
        \ 'require("vim.treesitter.highlighter").active[_A] ~= nil',
        \ a:bufnr
        \)
    call vimtex#log#error('Syntax highlighting is controlled by Treesitter!')
  endif
endfunction

" }}}1
