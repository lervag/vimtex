" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

scriptencoding utf-8

function! vimtex#syntax#p#glossaries_extra#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'glossaries_extra') | return | endif
  let b:vimtex_syntax.glossaries_extra = 1

  " Load amsmath
  call vimtex#syntax#p#glossaries#load()
endfunction

" }}}1
