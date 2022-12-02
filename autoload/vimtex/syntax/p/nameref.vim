" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#nameref#load(cfg) abort " {{{1
  syntax match texCmdNameref '\\nameref\>' nextgroup=texRefOpt,texRefArg

  highlight def link texCmdNameref texCmdRef
endfunction

" }}}1
