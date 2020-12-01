" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#asymptote#load(cfg) abort " {{{1
  let l:opts = empty(vimtex#syntax#nested#include('asy'))
        \ ? {}
        \ : {'contains': '@vimtex_nested_asy'}

  call vimtex#syntax#core#new_region_env('texAsymptoteRegion', 'asy', l:opts)
  call vimtex#syntax#core#new_region_env('texAsymptoteRegion', 'asydef', l:opts)

  highlight def link texAsymptoteRegion texRegion
endfunction

" }}}1
