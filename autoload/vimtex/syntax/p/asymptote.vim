" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#asymptote#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'asymptote') | return | endif
  let b:vimtex_syntax.asymptote = 1

  if !empty(vimtex#syntax#nested#include('asy'))
    call vimtex#syntax#core#new_region_env('texRegionAsymptote', 'asy', '@vimtex_nested_asy')
    call vimtex#syntax#core#new_region_env('texRegionAsymptote', 'asydef', '@vimtex_nested_asy')
  else
    call vimtex#syntax#core#new_region_env('texRegionAsymptote', 'asy')
    call vimtex#syntax#core#new_region_env('texRegionAsymptote', 'asydef')
    highlight def link texRegionAsymptote texRegion
  endif
endfunction

" }}}1
