" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#subfile#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'subfile') | return | endif
  let b:vimtex_syntax.subfile = 1

  syntax match texCmdInput nextgroup=texFileArg skipwhite skipnl "\\subfile\>"
  syntax match texCmdInput nextgroup=texFileArg skipwhite skipnl "\\subfileinclude\>"
endfunction

" }}}1
