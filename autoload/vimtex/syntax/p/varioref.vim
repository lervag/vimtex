" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#varioref#load(cfg) abort " {{{1
  syntax match texCmdRef '\\Vref\>' nextgroup=texRefArg skipwhite skipnl
endfunction

" }}}1
