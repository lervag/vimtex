" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#gnuplottex#load(cfg) abort " {{{1
  call vimtex#syntax#nested#include('gnuplot')
  call vimtex#syntax#core#new_region_env('texGnuplotZone', 'gnuplot',
        \ {'contains': '@vimtex_nested_gnuplot'})
endfunction

" }}}1
