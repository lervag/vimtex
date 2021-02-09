" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#pdfpages#load(cfg) abort " {{{1
  syntax match texCmdInput "\\includepdf\>" nextgroup=texFileOpt,texFileArg skipwhite skipnl
endfunction

" }}}1
