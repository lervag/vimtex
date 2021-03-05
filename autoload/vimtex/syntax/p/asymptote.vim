" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#asymptote#load(cfg) abort " {{{1
  let l:opts = empty(vimtex#syntax#nested#include('asy'))
        \ ? {}
        \ : {'contains': '@vimtex_nested_asy'}

  call vimtex#syntax#core#new_region_env('texAsymptoteZone', 'asy', l:opts)
  call vimtex#syntax#core#new_region_env('texAsymptoteZone', 'asydef', l:opts)

  if empty(l:opts)
    highlight def link texAsymptoteZone texZone
  endif
endfunction

" }}}1
