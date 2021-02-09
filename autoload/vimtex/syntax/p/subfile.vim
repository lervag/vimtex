" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#subfile#load(cfg) abort " {{{1
  syntax match texCmdInput nextgroup=texFileArg skipwhite skipnl "\\subfile\>"
  syntax match texCmdInput nextgroup=texFileArg skipwhite skipnl "\\subfileinclude\>"
endfunction

" }}}1
