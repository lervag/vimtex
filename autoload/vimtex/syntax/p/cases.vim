" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

scriptencoding utf-8

function! vimtex#syntax#p#cases#load(cfg) abort " {{{1
  call vimtex#syntax#core#new_region_math('\(sub\)\?numcases', {'starred': 0})
endfunction

" }}}1
