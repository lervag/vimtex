" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#dot2texi#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'dot2texi') | return | endif
  let b:vimtex_syntax.dot2texi = 1

  call vimtex#syntax#nested#include('dot')
  call vimtex#syntax#core#new_region_env(
        \ 'texRegionDot', 'dot2tex', '@vimtex_nested_dot')
endfunction

" }}}1
