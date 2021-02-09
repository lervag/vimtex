" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

scriptencoding utf-8

function! vimtex#syntax#p#glossaries#load(cfg) abort " {{{1
  syntax match texCmd nextgroup=texGlsArg skipwhite skipnl "\\gls\>"
  call vimtex#syntax#core#new_arg('texGlsArg', {'contains': '@NoSpell'})
endfunction

" }}}1
