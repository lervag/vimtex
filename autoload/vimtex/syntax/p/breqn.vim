" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

scriptencoding utf-8

function! vimtex#syntax#p#breqn#load(cfg) abort " {{{1
  call vimtex#syntax#core#new_region_math('dmath')
  call vimtex#syntax#core#new_region_math('dseries')
  call vimtex#syntax#core#new_region_math('dgroup')
  call vimtex#syntax#core#new_region_math('darray')
endfunction

" }}}1
