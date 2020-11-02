" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#gnuplottex#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'gnuplottex') | return | endif
  let b:vimtex_syntax.gnuplottex = 1

  call vimtex#syntax#nested#include('gnuplot')
  call vimtex#syntax#core#new_region_env(
        \ 'texRegionGnuplot', 'gnuplot', '@vimtex_nested_gnuplot')
endfunction

" }}}1
