" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#varioref#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'varioref') | return | endif
  let b:vimtex_syntax.varioref = 1

  syntax match texCmdRef '\\Vref\>' nextgroup=texRefArg skipwhite skipnl
endfunction

" }}}1
