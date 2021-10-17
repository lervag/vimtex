" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#nameref#load(cfg) abort " {{{1
  syntax match texCmdNameref '\\[nN]ameref\>' nextgroup=texRefOpt,texRefArg

  highlight def link texCmdNameref texCmd
endfunction

" }}}1
