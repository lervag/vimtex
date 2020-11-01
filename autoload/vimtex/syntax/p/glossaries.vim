" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

scriptencoding utf-8

function! vimtex#syntax#p#glossaries#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'glossaries') | return | endif
  let b:vimtex_syntax.glossaries = 1

  syntax match texCmd nextgroup=texGls skipwhite skipnl "\\gls\>"
  call vimtex#syntax#core#new_cmd_arg('texGls', '', '@NoSpell')
endfunction

" }}}1
