" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#dot2texi#load(cfg) abort " {{{1
  call vimtex#syntax#core#new_env({
        \ 'name': 'dot2tex',
        \ 'region': 'texDotZone',
        \ 'nested': 'dot'
        \})
endfunction

" }}}1
