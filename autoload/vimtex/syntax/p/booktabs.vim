" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#booktabs#load(cfg) abort " {{{1
  syntax match texCmdBooktabs "\\\%(top\|mid\|bottom\)rule\>"

  highlight def link texCmdBooktabs texMathDelim
endfunction

" }}}1

