" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#booktabs#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'booktabs') | return | endif
  let b:vimtex_syntax.booktabs = 1

  syntax match texCmdBooktabs "\\\%(top\|mid\|bottom\)rule\>"

  highlight def link texCmdBooktabs texMathDelim
endfunction

" }}}1

