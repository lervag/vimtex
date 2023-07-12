" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#gnuplottex#load(cfg) abort " {{{1
  call vimtex#syntax#core#new_env({
        \ 'name': 'gnuplot',
        \ 'region': 'texGnuplotZone',
        \ 'nested': 'gnuplot'
        \})
endfunction

" }}}1
