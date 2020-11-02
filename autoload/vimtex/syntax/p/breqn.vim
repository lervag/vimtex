" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

scriptencoding utf-8

function! vimtex#syntax#p#breqn#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'breqn') | return | endif
  let b:vimtex_syntax.breqn = 1

  call vimtex#syntax#core#new_region_math('dmath', 1)
  call vimtex#syntax#core#new_region_math('dseries', 1)
  call vimtex#syntax#core#new_region_math('dgroup', 1)
  call vimtex#syntax#core#new_region_math('darray', 1)
endfunction

" }}}1
