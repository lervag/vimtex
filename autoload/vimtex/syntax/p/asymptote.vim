" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#asymptote#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'asymptote') | return | endif
  let b:vimtex_syntax.asymptote = 1

  if !empty(vimtex#syntax#nested#include('asy'))
    let l:opts = {'contains': '@vimtex_nested_asy'}
  else
    let l:opts = {'transparent': 0}
    highlight def link texAsymptoteRegion texRegion
  endif

  call vimtex#syntax#core#new_region_env('texAsymptoteRegion', 'asy', l:opts)
  call vimtex#syntax#core#new_region_env('texAsymptoteRegion', 'asydef', l:opts)
endfunction

" }}}1
