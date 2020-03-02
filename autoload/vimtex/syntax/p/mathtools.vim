" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

scriptencoding utf-8

function! vimtex#syntax#p#mathtools#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'mathtools') | return | endif
  let b:vimtex_syntax.mathtools = 1

  " Load amsmath
  call vimtex#syntax#p#amsmath#load()
endfunction

" }}}1
