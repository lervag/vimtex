" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#biblatex_chicago#load(cfg) abort " {{{1
  call vimtex#syntax#packages#load('biblatex')

  syntax match texCmdRef "\\mancite\>"
  syntax match texCmdRef nextgroup=texRefOpts,texRefArgs skipwhite skipnl "\\[hH]eadlesscites\?\>"
endfunction

" }}}1
