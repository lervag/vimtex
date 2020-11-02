" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#subfile#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'subfile') | return | endif
  let b:vimtex_syntax.subfile = 1

  syntax match texCmd "\\subfile\>" nextgroup=texArgFile skipwhite skipnl
  syntax match texCmd "\\subfileinclude\>" nextgroup=texArgFile skipwhite skipnl
endfunction

" }}}1
